/*  Title:      Tools/jEdit/src/jedit/plugin.scala
    Author:     Makarius

Main Isabelle/jEdit plugin setup.
*/

package isabelle.jedit


import isabelle._

import java.io.{FileInputStream, IOException}
import java.awt.Font

import scala.collection.mutable
import scala.swing.ComboBox

import org.gjt.sp.jedit.{jEdit, GUIUtilities, EBMessage, EBPlugin,
  Buffer, EditPane, ServiceManager, View}
import org.gjt.sp.jedit.buffer.JEditBuffer
import org.gjt.sp.jedit.textarea.{JEditTextArea, TextArea}
import org.gjt.sp.jedit.msg.{EditorStarted, BufferUpdate, EditPaneUpdate, PropertiesChanged}
import org.gjt.sp.jedit.gui.DockableWindowManager

import org.gjt.sp.util.Log

import scala.actors.Actor
import Actor._


object Isabelle
{
  /* plugin instance */

  var system: Isabelle_System = null
  var session: Session = null


  /* properties */

  val OPTION_PREFIX = "options.isabelle."

  object Property
  {
    def apply(name: String): String =
      jEdit.getProperty(OPTION_PREFIX + name)
    def apply(name: String, default: String): String =
      jEdit.getProperty(OPTION_PREFIX + name, default)
    def update(name: String, value: String) =
      jEdit.setProperty(OPTION_PREFIX + name, value)
  }

  object Boolean_Property
  {
    def apply(name: String): Boolean =
      jEdit.getBooleanProperty(OPTION_PREFIX + name)
    def apply(name: String, default: Boolean): Boolean =
      jEdit.getBooleanProperty(OPTION_PREFIX + name, default)
    def update(name: String, value: Boolean) =
      jEdit.setBooleanProperty(OPTION_PREFIX + name, value)
  }

  object Int_Property
  {
    def apply(name: String): Int =
      jEdit.getIntegerProperty(OPTION_PREFIX + name)
    def apply(name: String, default: Int): Int =
      jEdit.getIntegerProperty(OPTION_PREFIX + name, default)
    def update(name: String, value: Int) =
      jEdit.setIntegerProperty(OPTION_PREFIX + name, value)
  }


  /* font */

  def font_family(): String = jEdit.getProperty("view.font")

  def font_size(): Float =
    (jEdit.getIntegerProperty("view.fontsize", 16) *
      Int_Property("relative-font-size", 100)).toFloat / 100


  /* text area ranges */

  case class Gfx_Range(val x: Int, val y: Int, val length: Int)

  def gfx_range(text_area: TextArea, range: Text.Range): Option[Gfx_Range] =
  {
    val p = text_area.offsetToXY(range.start)
    val q = text_area.offsetToXY(range.stop)
    if (p != null && q != null && p.y == q.y) Some(new Gfx_Range(p.x, p.y, q.x - p.x))
    else None
  }


  /* tooltip markup */

  def tooltip(text: String): String =
    "<html><pre style=\"font-family: " + font_family() + "; font-size: " +
        Int_Property("tooltip-font-size", 10).toString + "px; \">" +  // FIXME proper scaling (!?)
      HTML.encode(text) + "</pre></html>"

  def tooltip_dismiss_delay(): Int =
    Int_Property("tooltip-dismiss-delay", 8000) max 500

  def setup_tooltips()
  {
    Swing_Thread.now {
      val manager = javax.swing.ToolTipManager.sharedInstance
      manager.setDismissDelay(tooltip_dismiss_delay())
    }
  }


  /* icons */

  def load_icon(name: String): javax.swing.Icon =
  {
    val icon = GUIUtilities.loadIcon(name)
    if (icon.getIconWidth < 0 || icon.getIconHeight < 0)
      Log.log(Log.ERROR, icon, "Bad icon: " + name)
    icon
  }


  /* main jEdit components */

  def jedit_buffers(): Iterator[Buffer] = jEdit.getBuffers().iterator

  def jedit_views(): Iterator[View] = jEdit.getViews().iterator

  def jedit_text_areas(view: View): Iterator[JEditTextArea] =
    view.getEditPanes().iterator.map(_.getTextArea)

  def jedit_text_areas(): Iterator[JEditTextArea] =
    jedit_views().flatMap(jedit_text_areas(_))

  def jedit_text_areas(buffer: JEditBuffer): Iterator[JEditTextArea] =
    jedit_text_areas().filter(_.getBuffer == buffer)

  def buffer_lock[A](buffer: JEditBuffer)(body: => A): A =
  {
    try { buffer.readLock(); body }
    finally { buffer.readUnlock() }
  }

  def swing_buffer_lock[A](buffer: JEditBuffer)(body: => A): A =
    Swing_Thread.now { buffer_lock(buffer) { body } }


  /* dockable windows */

  private def wm(view: View): DockableWindowManager = view.getDockableWindowManager

  def docked_session(view: View): Option[Session_Dockable] =
    wm(view).getDockableWindow("isabelle-session") match {
      case dockable: Session_Dockable => Some(dockable)
      case _ => None
    }

  def docked_output(view: View): Option[Output_Dockable] =
    wm(view).getDockableWindow("isabelle-output") match {
      case dockable: Output_Dockable => Some(dockable)
      case _ => None
    }

  def docked_raw_output(view: View): Option[Raw_Output_Dockable] =
    wm(view).getDockableWindow("isabelle-raw-output") match {
      case dockable: Raw_Output_Dockable => Some(dockable)
      case _ => None
    }

  def docked_protocol(view: View): Option[Protocol_Dockable] =
    wm(view).getDockableWindow("isabelle-protocol") match {
      case dockable: Protocol_Dockable => Some(dockable)
      case _ => None
    }


  /* logic image */

  def default_logic(): String =
  {
    val logic = system.getenv("JEDIT_LOGIC")
    if (logic != "") logic
    else system.getenv_strict("ISABELLE_LOGIC")
  }

  class Logic_Entry(val name: String, val description: String)
  {
    override def toString = description
  }

  def logic_selector(logic: String): ComboBox[Logic_Entry] =
  {
    val entries =
      new Logic_Entry("", "default (" + default_logic() + ")") ::
        system.find_logics().map(name => new Logic_Entry(name, name))
    val component = new ComboBox(entries)
    entries.find(_.name == logic) match {
      case None =>
      case Some(entry) => component.selection.item = entry
    }
    component
  }
}


class Plugin extends EBPlugin
{
  /* session management */

  private def start_session()
  {
    if (Isabelle.session.phase == Session.Inactive) {
      val timeout = Isabelle.Int_Property("startup-timeout") max 1000
      val modes = Isabelle.system.getenv("JEDIT_PRINT_MODE").split(",").toList.map("-m" + _)
      val logic = {
        val logic = Isabelle.Property("logic")
        if (logic != null && logic != "") logic
        else Isabelle.default_logic()
      }
      Isabelle.session.start(timeout, modes ::: List(logic))
    }
  }

  private def init_model(buffer: Buffer): Option[Document_Model] =
  {
    Thy_Header.split_thy_path(Isabelle.system.posix_path(buffer.getPath)) match {
      case Some((_, thy_name)) if Document_Model(buffer).isEmpty =>
        Some(Document_Model.init(Isabelle.session, buffer, thy_name))
      case _ => Document_Model(buffer)
    }
  }

  private def activate_buffer(buffer: Buffer)
  {
    Isabelle.swing_buffer_lock(buffer) {
      init_model(buffer) match {
        case None =>
        case Some(model) =>
          for (text_area <- Isabelle.jedit_text_areas(buffer)) {
            if (Document_View(text_area).isEmpty)
              Document_View.init(model, text_area)
          }
      }
    }
  }

  private def deactivate_buffer(buffer: Buffer)
  {
    Isabelle.swing_buffer_lock(buffer) {
      for (text_area <- Isabelle.jedit_text_areas(buffer)) {
        if (Document_View(text_area).isDefined)
          Document_View.exit(text_area)
      }
      if (Document_Model(buffer).isDefined)
        Document_Model.exit(buffer)
    }
  }

  private val session_manager = actor {
    loop {
      react {
        case (Session.Inactive, Session.Exit) =>
          val text = new scala.swing.TextArea(Isabelle.session.syslog())
          text.editable = false
          Library.error_dialog(jEdit.getActiveView, "Failed to start Isabelle process", text)

        case (_, Session.Ready) => Isabelle.jedit_buffers.foreach(activate_buffer)
        case (_, Session.Shutdown) => Isabelle.jedit_buffers.foreach(deactivate_buffer)

        case _ =>
      }
    }
  }


  /* main plugin plumbing */

  override def handleMessage(message: EBMessage)
  {
    message match {
      case msg: EditorStarted => start_session()

      case msg: BufferUpdate
      if Isabelle.session.phase == Session.Ready &&
        msg.getWhat == BufferUpdate.PROPERTIES_CHANGED =>

        val buffer = msg.getBuffer
        Isabelle.swing_buffer_lock(buffer) {
          init_model(buffer) match {
            case Some(model) => model.refresh()
            case None =>
          }
        }

      case msg: EditPaneUpdate
      if Isabelle.session.phase == Session.Ready &&
        (msg.getWhat == EditPaneUpdate.BUFFER_CHANGED ||
          msg.getWhat == EditPaneUpdate.CREATED ||
          msg.getWhat == EditPaneUpdate.DESTROYED) =>

        val edit_pane = msg.getEditPane
        val buffer = edit_pane.getBuffer
        val text_area = edit_pane.getTextArea

        def init_view()
        {
          Document_Model(buffer) match {
            case Some(model) => Document_View.init(model, text_area)
            case None =>
          }
        }
        def exit_view()
        {
          if (Document_View(text_area).isDefined)
            Document_View.exit(text_area)
        }

        Isabelle.swing_buffer_lock(buffer) {
          msg.getWhat match {
            case EditPaneUpdate.BUFFER_CHANGED => exit_view(); init_view()
            case EditPaneUpdate.CREATED => init_view()
            case EditPaneUpdate.DESTROYED => exit_view()
            case _ =>
          }
        }

      case msg: PropertiesChanged =>
        Swing_Thread.now {
          Isabelle.setup_tooltips()
          for (text_area <- Isabelle.jedit_text_areas if Document_View(text_area).isDefined)
            Document_View(text_area).get.extend_styles()
        }
        Isabelle.session.global_settings.event(Session.Global_Settings)

      case _ =>
    }
  }

  override def start()
  {
    Isabelle.setup_tooltips()
    Isabelle.system = new Isabelle_System
    Isabelle.system.install_fonts()
    Isabelle.session = new Session(Isabelle.system)
    Isabelle.session.phase_changed += session_manager
  }

  override def stop()
  {
    Isabelle.session.stop()
    Isabelle.session.phase_changed -= session_manager
  }
}
