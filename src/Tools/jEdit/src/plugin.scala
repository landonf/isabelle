/*  Title:      Tools/jEdit/src/plugin.scala
    Author:     Makarius

Main plumbing for PIDE infrastructure as jEdit plugin.
*/

package isabelle.jedit


import isabelle._

import javax.swing.JOptionPane

import scala.swing.{ListView, ScrollPane}

import org.gjt.sp.jedit.{jEdit, EBMessage, EBPlugin, Buffer, View, Debug, PerspectiveManager}
import org.gjt.sp.jedit.gui.AboutDialog
import org.gjt.sp.jedit.textarea.{JEditTextArea, TextArea}
import org.gjt.sp.jedit.buffer.JEditBuffer
import org.gjt.sp.jedit.syntax.ModeProvider
import org.gjt.sp.jedit.msg.{EditorStarted, BufferUpdate, EditPaneUpdate, PropertiesChanged}
import org.gjt.sp.util.SyntaxUtilities
import org.gjt.sp.util.Log


object PIDE
{
  /* plugin instance */

  val options = new JEdit_Options
  val completion_history = new Completion.History_Variable
  val spell_checker = new Spell_Checker_Variable

  @volatile var startup_failure: Option[Throwable] = None
  @volatile var startup_notified = false

  @volatile var plugin: Plugin = null
  @volatile var session: Session = new Session(JEdit_Resources.empty)

  def options_changed() { if (plugin != null) plugin.options_changed() }
  def deps_changed() { if (plugin != null) plugin.deps_changed() }

  def resources(): JEdit_Resources =
    session.resources.asInstanceOf[JEdit_Resources]

  lazy val editor = new JEdit_Editor


  /* popups */

  def dismissed_popups(view: View): Boolean =
  {
    var dismissed = false

    JEdit_Lib.jedit_text_areas(view).foreach(text_area =>
      if (Completion_Popup.Text_Area.dismissed(text_area)) dismissed = true)

    if (Pretty_Tooltip.dismissed_all()) dismissed = true

    dismissed
  }


  /* document model and view */

  def document_view(text_area: TextArea): Option[Document_View] = Document_View(text_area)

  def document_views(buffer: Buffer): List[Document_View] =
    for {
      text_area <- JEdit_Lib.jedit_text_areas(buffer).toList
      doc_view <- document_view(text_area)
    } yield doc_view

  def exit_models(buffers: List[Buffer])
  {
    GUI_Thread.now {
      buffers.foreach(buffer =>
        JEdit_Lib.buffer_lock(buffer) {
          JEdit_Lib.jedit_text_areas(buffer).foreach(Document_View.exit)
          Document_Model.exit(buffer)
        })
      }
  }

  def init_models()
  {
    GUI_Thread.now {
      PIDE.editor.flush()

      for {
        buffer <- JEdit_Lib.jedit_buffers()
        if buffer != null && !buffer.getBooleanProperty(Buffer.GZIPPED)
      } {
        if (buffer.isLoaded) {
          JEdit_Lib.buffer_lock(buffer) {
            val node_name = resources.node_name(buffer)
            val model = Document_Model.init(session, node_name, buffer)
            for {
              text_area <- JEdit_Lib.jedit_text_areas(buffer)
              if document_view(text_area).map(_.model) != Some(model)
            } Document_View.init(model, text_area)
          }
        }
        else if (plugin != null) plugin.delay_init.invoke()
      }

      PIDE.editor.invoke_generated()
    }
  }

  def init_view(buffer: Buffer, text_area: JEditTextArea): Unit =
    GUI_Thread.now {
      JEdit_Lib.buffer_lock(buffer) {
        Document_Model.get(buffer) match {
          case Some(model) => Document_View.init(model, text_area)
          case None =>
        }
      }
    }

  def exit_view(buffer: Buffer, text_area: JEditTextArea): Unit =
    GUI_Thread.now {
      JEdit_Lib.buffer_lock(buffer) {
        Document_View.exit(text_area)
      }
    }


  /* current document content */

  def snapshot(view: View): Document.Snapshot = GUI_Thread.now
  {
    Document_Model.get(view.getBuffer) match {
      case Some(model) => model.snapshot
      case None => error("No document model for current buffer")
    }
  }

  def rendering(view: View): JEdit_Rendering = GUI_Thread.now
  {
    val text_area = view.getTextArea
    document_view(text_area) match {
      case Some(doc_view) => doc_view.get_rendering()
      case None => error("No document view for current text area")
    }
  }
}


class Plugin extends EBPlugin
{
  /* global changes */

  def options_changed()
  {
    PIDE.session.global_options.post(Session.Global_Options(PIDE.options.value))
    delay_load.invoke()
  }

  def deps_changed()
  {
    delay_load.invoke()
  }


  /* theory files */

  lazy val delay_init =
    GUI_Thread.delay_last(PIDE.options.seconds("editor_load_delay"))
    {
      PIDE.init_models()
    }

  private val delay_load_active = Synchronized(false)
  private def delay_load_activated(): Boolean =
    delay_load_active.guarded_access(a => Some((!a, true)))
  private def delay_load_action()
  {
    if (Isabelle.continuous_checking && delay_load_activated() &&
        PerspectiveManager.isPerspectiveEnabled)
    {
      if (JEdit_Lib.jedit_buffers().exists(_.isLoading)) delay_load.invoke()
      else {
        val required_files =
        {
          val models = Document_Model.get_models()

          val thys =
            (for ((node_name, model) <- models.iterator if model.is_theory)
              yield (node_name, Position.none)).toList
          val thy_files = PIDE.resources.thy_info.dependencies("", thys).deps.map(_.name)

          val aux_files =
            if (PIDE.options.bool("jedit_auto_resolve")) {
              val stable_tip_version =
                if (models.forall(p => p._2.is_stable))
                  PIDE.session.current_state().stable_tip_version
                else None
              stable_tip_version match {
                case Some(version) => PIDE.resources.undefined_blobs(version.nodes)
                case None => delay_load.invoke(); Nil
              }
            }
            else Nil

          (thy_files ::: aux_files).filterNot(models.isDefinedAt(_))
        }
        if (required_files.nonEmpty) {
          try {
            Standard_Thread.fork("resolve_dependencies") {
              val loaded_files =
                for {
                  name <- required_files
                  text <- PIDE.resources.read_file_content(name)
                } yield (name, text)

              GUI_Thread.later {
                try {
                  Document_Model.provide_files(PIDE.session, loaded_files)
                  delay_init.invoke()
                }
                finally { delay_load_active.change(_ => false) }
              }
            }
          }
          catch { case _: Throwable => delay_load_active.change(_ => false) }
        }
        else delay_load_active.change(_ => false)
      }
    }
  }

  private lazy val delay_load =
    GUI_Thread.delay_last(PIDE.options.seconds("editor_load_delay")) { delay_load_action() }


  /* session phase */

  private val session_phase =
    Session.Consumer[Session.Phase](getClass.getName) {
      case Session.Inactive | Session.Failed =>
        GUI_Thread.later {
          GUI.error_dialog(jEdit.getActiveView, "Prover process terminated",
            "Isabelle Syslog", GUI.scrollable_text(PIDE.session.syslog_content()))
        }

      case Session.Ready =>
        Debugger.init_session(PIDE.session)
        PIDE.session.update_options(PIDE.options.value)
        PIDE.init_models()

        if (!Isabelle.continuous_checking) {
          GUI_Thread.later {
            val answer =
              GUI.confirm_dialog(jEdit.getActiveView,
                "Continuous checking of PIDE document",
                JOptionPane.YES_NO_OPTION,
                "Continuous checking is presently disabled:",
                "editor buffers will remain inactive!",
                "Enable continuous checking now?")
            if (answer == 0) Isabelle.continuous_checking = true
          }
        }

        delay_load.invoke()

      case Session.Shutdown =>
        GUI_Thread.later {
          delay_load.revoke()
          delay_init.revoke()
          PIDE.editor.flush()
          PIDE.exit_models(JEdit_Lib.jedit_buffers().toList)
        }

      case _ =>
    }


  /* main plugin plumbing */

  override def handleMessage(message: EBMessage)
  {
    GUI_Thread.assert {}

    if (PIDE.startup_failure.isDefined && !PIDE.startup_notified) {
      message match {
        case msg: EditorStarted =>
          GUI.error_dialog(null, "Isabelle plugin startup failure",
            GUI.scrollable_text(Exn.message(PIDE.startup_failure.get)),
            "Prover IDE inactive!")
          PIDE.startup_notified = true
        case _ =>
      }
    }

    if (PIDE.startup_failure.isEmpty) {
      message match {
        case msg: EditorStarted =>
          if (Distribution.is_identified && !Distribution.is_official) {
            GUI.warning_dialog(jEdit.getActiveView, "Isabelle version for testing",
              "This is " + Distribution.version + ".",
              "It is for testing only, not for production use.")
          }

          val view = jEdit.getActiveView()

          Session_Build.session_build(view)

          Keymap_Merge.check_dialog(view)

          PIDE.editor.hyperlink_position(true, Document.Snapshot.init,
            JEdit_Sessions.session_info().open_root).foreach(_.follow(view))

        case msg: BufferUpdate
        if msg.getWhat == BufferUpdate.LOAD_STARTED || msg.getWhat == BufferUpdate.CLOSING =>
          if (msg.getBuffer != null) {
            PIDE.exit_models(List(msg.getBuffer))
            PIDE.editor.invoke_generated()
          }

        case msg: BufferUpdate
        if msg.getWhat == BufferUpdate.PROPERTIES_CHANGED || msg.getWhat == BufferUpdate.LOADED =>
          if (PIDE.session.is_ready) {
            delay_init.invoke()
            delay_load.invoke()
          }

        case msg: EditPaneUpdate
        if msg.getWhat == EditPaneUpdate.BUFFER_CHANGING ||
            msg.getWhat == EditPaneUpdate.BUFFER_CHANGED ||
            msg.getWhat == EditPaneUpdate.CREATED ||
            msg.getWhat == EditPaneUpdate.DESTROYED =>
          val edit_pane = msg.getEditPane
          val buffer = edit_pane.getBuffer
          val text_area = edit_pane.getTextArea

          if (buffer != null && text_area != null) {
            if (msg.getWhat == EditPaneUpdate.BUFFER_CHANGED ||
                msg.getWhat == EditPaneUpdate.CREATED) {
              if (PIDE.session.is_ready)
                PIDE.init_view(buffer, text_area)
            }
            else {
              PIDE.dismissed_popups(text_area.getView)
              PIDE.exit_view(buffer, text_area)
            }

            if (msg.getWhat == EditPaneUpdate.CREATED)
              Completion_Popup.Text_Area.init(text_area)

            if (msg.getWhat == EditPaneUpdate.DESTROYED)
              Completion_Popup.Text_Area.exit(text_area)
          }

        case msg: PropertiesChanged =>
          for {
            view <- JEdit_Lib.jedit_views
            edit_pane <- JEdit_Lib.jedit_edit_panes(view)
          } {
            val buffer = edit_pane.getBuffer
            val text_area = edit_pane.getTextArea
            if (buffer != null && text_area != null) PIDE.init_view(buffer, text_area)
          }

          PIDE.spell_checker.update(PIDE.options.value)
          PIDE.session.update_options(PIDE.options.value)

        case _ =>
      }
    }
  }

  override def start()
  {
    try {
      Debug.DISABLE_SEARCH_DIALOG_POOL = true

      PIDE.plugin = this
      PIDE.options.store(Options.init())
      PIDE.completion_history.load()
      PIDE.spell_checker.update(PIDE.options.value)

      SyntaxUtilities.setStyleExtender(new Token_Markup.Style_Extender)
      if (ModeProvider.instance.isInstanceOf[ModeProvider])
        ModeProvider.instance = new Token_Markup.Mode_Provider(ModeProvider.instance)

      JEdit_Lib.jedit_text_areas.foreach(Completion_Popup.Text_Area.init _)

      val content = JEdit_Sessions.session_content(false)
      val resources =
        new JEdit_Resources(content.loaded_theories, content.known_theories, content.syntax)

      PIDE.session.stop()
      PIDE.session = new Session(resources) {
        override def output_delay = PIDE.options.seconds("editor_output_delay")
        override def prune_delay = PIDE.options.seconds("editor_prune_delay")
        override def syslog_limit = PIDE.options.int("editor_syslog_limit")
        override def reparse_limit = PIDE.options.int("editor_reparse_limit")
      }

      PIDE.session.phase_changed += session_phase
      PIDE.startup_failure = None
    }
    catch {
      case exn: Throwable =>
        PIDE.startup_failure = Some(exn)
        PIDE.startup_notified = false
        Log.log(Log.ERROR, this, exn)
    }
  }

  override def stop()
  {
    JEdit_Lib.jedit_text_areas.foreach(Completion_Popup.Text_Area.exit _)

    if (PIDE.startup_failure.isEmpty) {
      PIDE.options.value.save_prefs()
      PIDE.completion_history.value.save()
    }

    PIDE.session.phase_changed -= session_phase
    PIDE.exit_models(JEdit_Lib.jedit_buffers().toList)
    PIDE.session.stop()
  }
}
