/*  Title:      Tools/jEdit/src/document_view.scala
    Author:     Fabian Immler, TU Munich
    Author:     Makarius

Document view connected to jEdit text area.
*/

package isabelle.jedit


import isabelle._

import scala.actors.Actor._

import java.awt.{BorderLayout, Graphics, Color, Dimension, Graphics2D, Point}
import java.awt.event.{MouseAdapter, MouseMotionAdapter, MouseEvent,
  FocusAdapter, FocusEvent, WindowEvent, WindowAdapter}
import javax.swing.{JPanel, ToolTipManager, Popup, PopupFactory, SwingUtilities, BorderFactory}
import javax.swing.event.{CaretListener, CaretEvent}

import org.gjt.sp.jedit.{jEdit, OperatingSystem, Debug}
import org.gjt.sp.jedit.gui.RolloverButton
import org.gjt.sp.jedit.options.GutterOptionPane
import org.gjt.sp.jedit.textarea.{JEditTextArea, TextArea, TextAreaExtension, TextAreaPainter}
import org.gjt.sp.jedit.syntax.{SyntaxStyle}


object Document_View
{
  /* document view of text area */

  private val key = new Object

  def init(model: Document_Model, text_area: JEditTextArea): Document_View =
  {
    Swing_Thread.require()
    val doc_view = new Document_View(model, text_area)
    text_area.putClientProperty(key, doc_view)
    doc_view.activate()
    doc_view
  }

  def apply(text_area: JEditTextArea): Option[Document_View] =
  {
    Swing_Thread.require()
    text_area.getClientProperty(key) match {
      case doc_view: Document_View => Some(doc_view)
      case _ => None
    }
  }

  def exit(text_area: JEditTextArea)
  {
    Swing_Thread.require()
    apply(text_area) match {
      case None =>
      case Some(doc_view) =>
        doc_view.deactivate()
        text_area.putClientProperty(key, null)
    }
  }
}


class Document_View(val model: Document_Model, val text_area: JEditTextArea)
{
  private val session = model.session


  /** token handling **/

  /* extended token styles */

  private var styles: Array[SyntaxStyle] = null  // owned by Swing thread

  def extend_styles()
  {
    Swing_Thread.require()
    styles = Document_Model.Token_Markup.extend_styles(text_area.getPainter.getStyles)
  }
  extend_styles()

  def set_styles()
  {
    Swing_Thread.require()
    text_area.getPainter.setStyles(styles)
  }


  /* visible line ranges */

  // simplify slightly odd result of TextArea.getScreenLineEndOffset etc.
  // NB: jEdit already normalizes \r\n and \r to \n
  def proper_line_range(start: Text.Offset, end: Text.Offset): Text.Range =
  {
    val stop = if (start < end) end - 1 else end min model.buffer.getLength
    Text.Range(start, stop)
  }

  def screen_lines_range(): Text.Range =
  {
    val start = text_area.getScreenLineStartOffset(0)
    val raw_end = text_area.getScreenLineEndOffset(text_area.getVisibleLines - 1 max 0)
    proper_line_range(start, if (raw_end >= 0) raw_end else model.buffer.getLength)
  }

  def invalidate_line_range(range: Text.Range)
  {
    text_area.invalidateLineRange(
      model.buffer.getLineOfOffset(range.start),
      model.buffer.getLineOfOffset(range.stop))
  }


  /* HTML popups */

  private var html_popup: Option[Popup] = None

  private def exit_popup() { html_popup.map(_.hide) }

  private val html_panel =
    new HTML_Panel(Isabelle.system, Isabelle.font_family(), scala.math.round(Isabelle.font_size()))
  html_panel.setBorder(BorderFactory.createLineBorder(Color.black))

  private def html_panel_resize()
  {
    Swing_Thread.now {
      html_panel.resize(Isabelle.font_family(), scala.math.round(Isabelle.font_size()))
    }
  }

  private def init_popup(snapshot: Document.Snapshot, x: Int, y: Int)
  {
    exit_popup()
/* FIXME broken
    val offset = text_area.xyToOffset(x, y)
    val p = new Point(x, y); SwingUtilities.convertPointToScreen(p, text_area.getPainter)

    // FIXME snapshot.cumulate
    snapshot.select_markup(Text.Range(offset, offset + 1))(Isabelle_Markup.popup) match {
      case Text.Info(_, Some(msg)) #:: _ =>
        val popup = PopupFactory.getSharedInstance().getPopup(text_area, html_panel, p.x, p.y + 60)
        html_panel.render_sync(List(msg))
        Thread.sleep(10)  // FIXME !?
        popup.show
        html_popup = Some(popup)
      case _ =>
    }
*/
  }


  /* subexpression highlighting */

  private def subexp_range(snapshot: Document.Snapshot, x: Int, y: Int)
    : Option[(Text.Range, Color)] =
  {
    val offset = text_area.xyToOffset(x, y)
    snapshot.select_markup(Text.Range(offset, offset + 1))(Isabelle_Markup.subexp) match {
      case Text.Info(_, Some((range, color))) #:: _ => Some((snapshot.convert(range), color))
      case _ => None
    }
  }

  @volatile private var _highlight_range: Option[(Text.Range, Color)] = None
  def highlight_range(): Option[(Text.Range, Color)] = _highlight_range


  /* CONTROL-mouse management */

  private var control: Boolean = false

  private def exit_control()
  {
    exit_popup()
    _highlight_range = None
  }

  private val focus_listener = new FocusAdapter {
    override def focusLost(e: FocusEvent) {
      _highlight_range = None // FIXME exit_control !?
    }
  }

  private val window_listener = new WindowAdapter {
    override def windowIconified(e: WindowEvent) { exit_control() }
    override def windowDeactivated(e: WindowEvent) { exit_control() }
  }

  private val mouse_motion_listener = new MouseMotionAdapter {
    override def mouseMoved(e: MouseEvent) {
      control = if (OperatingSystem.isMacOS()) e.isMetaDown else e.isControlDown
      val x = e.getX()
      val y = e.getY()

      if (!model.buffer.isLoaded) exit_control()
      else
        Isabelle.swing_buffer_lock(model.buffer) {
          val snapshot = model.snapshot

          if (control) init_popup(snapshot, x, y)

          _highlight_range map { case (range, _) => invalidate_line_range(range) }
          _highlight_range = if (control) subexp_range(snapshot, x, y) else None
          _highlight_range map { case (range, _) => invalidate_line_range(range) }
        }
    }
  }


  /* text area painting */

  private val text_area_painter = new Text_Area_Painter(this)

  private val tooltip_painter = new TextAreaExtension
  {
    override def getToolTipText(x: Int, y: Int): String =
    {
      Isabelle.swing_buffer_lock(model.buffer) {
        val snapshot = model.snapshot()
        val offset = text_area.xyToOffset(x, y)
        if (control) {
          snapshot.select_markup(Text.Range(offset, offset + 1))(Isabelle_Markup.tooltip) match
          {
            case Text.Info(_, Some(text)) #:: _ => Isabelle.tooltip(text)
            case _ => null
          }
        }
        else {
          // FIXME snapshot.cumulate
          snapshot.select_markup(Text.Range(offset, offset + 1))(Isabelle_Markup.popup) match
          {
            case Text.Info(_, Some(text)) #:: _ => Isabelle.tooltip(text)
            case _ => null
          }
        }
      }
    }
  }

  private val gutter_painter = new TextAreaExtension
  {
    override def paintScreenLineRange(gfx: Graphics2D,
      first_line: Int, last_line: Int, physical_lines: Array[Int],
      start: Array[Int], end: Array[Int], y: Int, line_height: Int)
    {
      val gutter = text_area.getGutter
      val width = GutterOptionPane.getSelectionAreaWidth
      val border_width = jEdit.getIntegerProperty("view.gutter.borderWidth", 3)
      val FOLD_MARKER_SIZE = 12

      if (gutter.isSelectionAreaEnabled && !gutter.isExpanded && width >= 12 && line_height >= 12) {
        Isabelle.swing_buffer_lock(model.buffer) {
          val snapshot = model.snapshot()
          for (i <- 0 until physical_lines.length) {
            if (physical_lines(i) != -1) {
              val line_range = proper_line_range(start(i), end(i))

              // gutter icons
              val icons =
                (for (Text.Info(_, Some(icon)) <- // FIXME snapshot.cumulate
                  snapshot.select_markup(line_range)(Isabelle_Markup.gutter_message).iterator)
                yield icon).toList.sortWith(_ >= _)
              icons match {
                case icon :: _ =>
                  val icn = icon.icon
                  val x0 = (FOLD_MARKER_SIZE + width - border_width - icn.getIconWidth) max 10
                  val y0 = y + i * line_height + (((line_height - icn.getIconHeight) / 2) max 0)
                  icn.paintIcon(gutter, gfx, x0, y0)
                case Nil =>
              }
            }
          }
        }
      }
    }
  }


  /* caret handling */

  def selected_command(): Option[Command] =
  {
    Swing_Thread.require()
    model.snapshot().node.proper_command_at(text_area.getCaretPosition)
  }

  private val caret_listener = new CaretListener {
    private val delay = Swing_Thread.delay_last(session.input_delay) {
      session.perspective.event(Session.Perspective)
    }
    override def caretUpdate(e: CaretEvent) { delay() }
  }


  /* overview of command status left of scrollbar */

  private val overview = new JPanel(new BorderLayout)
  {
    private val WIDTH = 10
    private val HEIGHT = 2

    setPreferredSize(new Dimension(WIDTH, 0))

    setRequestFocusEnabled(false)

    addMouseListener(new MouseAdapter {
      override def mousePressed(event: MouseEvent) {
        val line = y_to_line(event.getY)
        if (line >= 0 && line < text_area.getLineCount)
          text_area.setCaretPosition(text_area.getLineStartOffset(line))
      }
    })

    override def addNotify() {
      super.addNotify()
      ToolTipManager.sharedInstance.registerComponent(this)
    }

    override def removeNotify() {
      ToolTipManager.sharedInstance.unregisterComponent(this)
      super.removeNotify
    }

    override def paintComponent(gfx: Graphics)
    {
      super.paintComponent(gfx)
      Swing_Thread.assert()

      val buffer = model.buffer
      Isabelle.buffer_lock(buffer) {
        val snapshot = model.snapshot()

        def line_range(command: Command, start: Text.Offset): Option[(Int, Int)] =
        {
          try {
            val line1 = buffer.getLineOfOffset(snapshot.convert(start))
            val line2 = buffer.getLineOfOffset(snapshot.convert(start + command.length)) + 1
            Some((line1, line2))
          }
          catch { case e: ArrayIndexOutOfBoundsException => None }
        }
        for {
          (command, start) <- snapshot.node.command_starts
          if !command.is_ignored
          (line1, line2) <- line_range(command, start)
          val y = line_to_y(line1)
          val height = HEIGHT * (line2 - line1)
          color <- Isabelle_Markup.overview_color(snapshot, command)
        } {
          gfx.setColor(color)
          gfx.fillRect(0, y, getWidth - 1, height)
        }
      }
    }

    private def line_to_y(line: Int): Int =
      (line * getHeight) / (text_area.getBuffer.getLineCount max text_area.getVisibleLines)

    private def y_to_line(y: Int): Int =
      (y * (text_area.getBuffer.getLineCount max text_area.getVisibleLines)) / getHeight
  }


  /* main actor */

  private val main_actor = actor {
    loop {
      react {
        case Session.Commands_Changed(changed) =>
          val buffer = model.buffer
          Isabelle.swing_buffer_lock(buffer) {
            val snapshot = model.snapshot()

            if (changed.exists(snapshot.node.commands.contains))
              overview.repaint()

            val visible_range = screen_lines_range()
            val visible_cmds = snapshot.node.command_range(snapshot.revert(visible_range)).map(_._1)
            if (visible_cmds.exists(changed)) {
              for {
                line <- 0 until text_area.getVisibleLines
                val start = text_area.getScreenLineStartOffset(line) if start >= 0
                val end = text_area.getScreenLineEndOffset(line) if end >= 0
                val range = proper_line_range(start, end)
                val line_cmds = snapshot.node.command_range(snapshot.revert(range)).map(_._1)
                if line_cmds.exists(changed)
              } text_area.invalidateScreenLineRange(line, line)

              // FIXME danger of deadlock!?
              // FIXME potentially slow!?
              model.buffer.propertiesChanged()
            }
          }

        case Session.Global_Settings => html_panel_resize()

        case bad => System.err.println("command_change_actor: ignoring bad message " + bad)
      }
    }
  }


  /* activation */

  private def activate()
  {
    val painter = text_area.getPainter
    painter.addExtension(TextAreaPainter.LINE_BACKGROUND_LAYER + 1, tooltip_painter)
    text_area_painter.activate()
    text_area.getGutter.addExtension(gutter_painter)
    text_area.addFocusListener(focus_listener)
    text_area.getView.addWindowListener(window_listener)
    painter.addMouseMotionListener(mouse_motion_listener)
    text_area.addCaretListener(caret_listener)
    text_area.addLeftOfScrollBar(overview)
    session.commands_changed += main_actor
    session.global_settings += main_actor
  }

  private def deactivate()
  {
    val painter = text_area.getPainter
    session.commands_changed -= main_actor
    session.global_settings -= main_actor
    text_area.removeFocusListener(focus_listener)
    text_area.getView.removeWindowListener(window_listener)
    painter.removeMouseMotionListener(mouse_motion_listener)
    text_area.removeCaretListener(caret_listener)
    text_area.removeLeftOfScrollBar(overview)
    text_area.getGutter.removeExtension(gutter_painter)
    text_area_painter.deactivate()
    painter.removeExtension(tooltip_painter)
    exit_popup()
  }
}
