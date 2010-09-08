/*  Title:      Tools/jEdit/src/jedit/document_view.scala
    Author:     Fabian Immler, TU Munich
    Author:     Makarius

Document view connected to jEdit text area.
*/

package isabelle.jedit


import isabelle._

import scala.actors.Actor._

import java.awt.event.{MouseAdapter, MouseMotionAdapter, MouseEvent, FocusAdapter, FocusEvent}
import java.awt.{BorderLayout, Graphics, Color, Dimension, Graphics2D}
import javax.swing.{JPanel, ToolTipManager}
import javax.swing.event.{CaretListener, CaretEvent}

import org.gjt.sp.jedit.{jEdit, OperatingSystem}
import org.gjt.sp.jedit.gui.RolloverButton
import org.gjt.sp.jedit.options.GutterOptionPane
import org.gjt.sp.jedit.textarea.{JEditTextArea, TextArea, TextAreaExtension, TextAreaPainter}
import org.gjt.sp.jedit.syntax.SyntaxStyle


object Document_View
{
  /* document view of text area */

  private val key = new Object

  def init(model: Document_Model, text_area: TextArea): Document_View =
  {
    Swing_Thread.require()
    val doc_view = new Document_View(model, text_area)
    text_area.putClientProperty(key, doc_view)
    doc_view.activate()
    doc_view
  }

  def apply(text_area: TextArea): Option[Document_View] =
  {
    Swing_Thread.require()
    text_area.getClientProperty(key) match {
      case doc_view: Document_View => Some(doc_view)
      case _ => None
    }
  }

  def exit(text_area: TextArea)
  {
    Swing_Thread.require()
    apply(text_area) match {
      case None => error("No document view for text area: " + text_area)
      case Some(doc_view) =>
        doc_view.deactivate()
        text_area.putClientProperty(key, null)
    }
  }
}


class Document_View(val model: Document_Model, text_area: TextArea)
{
  private val session = model.session


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


  /* commands_changed_actor */

  private val commands_changed_actor = actor {
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

        case bad => System.err.println("command_change_actor: ignoring bad message " + bad)
      }
    }
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

  private var highlight_range: Option[(Text.Range, Color)] = None

  private val focus_listener = new FocusAdapter {
    override def focusLost(e: FocusEvent) { highlight_range = None }
  }

  private val mouse_motion_listener = new MouseMotionAdapter {
    override def mouseMoved(e: MouseEvent) {
      val control = if (OperatingSystem.isMacOS()) e.isMetaDown else e.isControlDown
      if (!model.buffer.isLoaded) highlight_range = None
      else
        Isabelle.swing_buffer_lock(model.buffer) {
          highlight_range map { case (range, _) => invalidate_line_range(range) }
          highlight_range =
            if (control) subexp_range(model.snapshot(), e.getX(), e.getY()) else None
          highlight_range map { case (range, _) => invalidate_line_range(range) }
        }
    }
  }


  /* text_area_extension */

  private val text_area_extension = new TextAreaExtension
  {
    override def paintScreenLineRange(gfx: Graphics2D,
      first_line: Int, last_line: Int, physical_lines: Array[Int],
      start: Array[Int], end: Array[Int], y: Int, line_height: Int)
    {
      Isabelle.swing_buffer_lock(model.buffer) {
        val snapshot = model.snapshot()
        val saved_color = gfx.getColor
        val ascent = text_area.getPainter.getFontMetrics.getAscent

        for (i <- 0 until physical_lines.length) {
          if (physical_lines(i) != -1) {
            val line_range = proper_line_range(start(i), end(i))

            // background color: status
            val cmds = snapshot.node.command_range(snapshot.revert(line_range))
            for {
              (command, command_start) <- cmds if !command.is_ignored
              val range = line_range.restrict(snapshot.convert(command.range + command_start))
              r <- Isabelle.gfx_range(text_area, range)
              color <- Isabelle_Markup.status_color(snapshot, command)
            } {
              gfx.setColor(color)
              gfx.fillRect(r.x, y + i * line_height, r.length, line_height)
            }

            // background color: markup
            for {
              Text.Info(range, Some(color)) <-
                snapshot.select_markup(line_range)(Isabelle_Markup.background).iterator
              r <- Isabelle.gfx_range(text_area, range)
            } {
              gfx.setColor(color)
              gfx.fillRect(r.x, y + i * line_height, r.length, line_height)
            }

            // sub-expression highlighting -- potentially from other snapshot
            highlight_range match {
              case Some((range, color)) if line_range.overlaps(range) =>
                Isabelle.gfx_range(text_area, line_range.restrict(range)) match {
                  case None =>
                  case Some(r) =>
                    gfx.setColor(color)
                    gfx.drawRect(r.x, y + i * line_height, r.length, line_height - 1)
                }
              case _ =>
            }

            // boxed text
            for {
              Text.Info(range, Some(color)) <-
                snapshot.select_markup(line_range)(Isabelle_Markup.box).iterator
              r <- Isabelle.gfx_range(text_area, range)
            } {
              gfx.setColor(color)
              gfx.drawRect(r.x + 1, y + i * line_height + 1, r.length - 2, line_height - 3)
            }

            // squiggly underline
            for {
              Text.Info(range, Some(color)) <-
                snapshot.select_markup(line_range)(Isabelle_Markup.message).iterator
              r <- Isabelle.gfx_range(text_area, range)
            } {
              gfx.setColor(color)
              val x0 = (r.x / 2) * 2
              val y0 = r.y + ascent + 1
              for (x1 <- Range(x0, x0 + r.length, 2)) {
                val y1 = if (x1 % 4 < 2) y0 else y0 + 1
                gfx.drawLine(x1, y1, x1 + 1, y1)
              }
            }
          }
        }
      }
    }

    override def getToolTipText(x: Int, y: Int): String =
    {
      Isabelle.swing_buffer_lock(model.buffer) {
        val snapshot = model.snapshot()
        val offset = text_area.xyToOffset(x, y)
        snapshot.select_markup(Text.Range(offset, offset + 1))(Isabelle_Markup.tooltip) match
        {
          case Text.Info(_, Some(text)) #:: _ => Isabelle.tooltip(text)
          case _ => null
        }
      }
    }
  }


  /* gutter_extension */

  private val gutter_extension = new TextAreaExtension
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
                (for (Text.Info(_, Some(icon)) <-
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
        for {
          (command, start) <- snapshot.node.command_starts
          if !command.is_ignored
          val line1 = buffer.getLineOfOffset(snapshot.convert(start))
          val line2 = buffer.getLineOfOffset(snapshot.convert(start + command.length)) + 1
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


  /* activation */

  private def activate()
  {
    text_area.getPainter.
      addExtension(TextAreaPainter.LINE_BACKGROUND_LAYER + 1, text_area_extension)
    text_area.getGutter.addExtension(gutter_extension)
    text_area.addFocusListener(focus_listener)
    text_area.getPainter.addMouseMotionListener(mouse_motion_listener)
    text_area.addCaretListener(caret_listener)
    text_area.addLeftOfScrollBar(overview)
    session.commands_changed += commands_changed_actor
  }

  private def deactivate()
  {
    session.commands_changed -= commands_changed_actor
    text_area.removeFocusListener(focus_listener)
    text_area.getPainter.removeMouseMotionListener(mouse_motion_listener)
    text_area.removeCaretListener(caret_listener)
    text_area.removeLeftOfScrollBar(overview)
    text_area.getGutter.removeExtension(gutter_extension)
    text_area.getPainter.removeExtension(text_area_extension)
  }
}