/*  Title:      Tools/jEdit/src/jedit/html_panel.scala
    Author:     Makarius

HTML panel based on Lobo/Cobra.
*/

package isabelle.jedit


import isabelle._

import java.io.StringReader
import java.awt.{BorderLayout, Dimension, GraphicsEnvironment, Toolkit}
import java.awt.event.MouseEvent

import javax.swing.{JButton, JPanel, JScrollPane}
import java.util.logging.{Logger, Level}

import org.w3c.dom.html2.HTMLElement

import org.lobobrowser.html.parser.{DocumentBuilderImpl, InputSourceImpl}
import org.lobobrowser.html.gui.HtmlPanel
import org.lobobrowser.html.domimpl.{HTMLDocumentImpl, HTMLStyleElementImpl, NodeImpl}
import org.lobobrowser.html.test.{SimpleHtmlRendererContext, SimpleUserAgentContext}

import scala.io.Source
import scala.actors.Actor._


object HTML_Panel
{
  sealed abstract class Event { val element: HTMLElement; val mouse: MouseEvent }
  case class Context_Menu(val element: HTMLElement, mouse: MouseEvent) extends Event
  case class Mouse_Click(val element: HTMLElement, mouse: MouseEvent) extends Event
  case class Double_Click(val element: HTMLElement, mouse: MouseEvent) extends Event
  case class Mouse_Over(val element: HTMLElement, mouse: MouseEvent) extends Event
  case class Mouse_Out(val element: HTMLElement, mouse: MouseEvent) extends Event
}


class HTML_Panel(
  sys: Isabelle_System,
  font_size0: Int, relative_margin0: Int,
  handler: PartialFunction[HTML_Panel.Event, Unit]) extends HtmlPanel
{
  // global logging
  Logger.getLogger("org.lobobrowser").setLevel(Level.WARNING)


  /* document template */

  private def try_file(name: String): String =
  {
    val file = sys.platform_file(name)
    if (file.isFile) Source.fromFile(file).mkString else ""
  }

  private def template(font_size: Int): String =
  {
    // re-adjustment according to org.lobobrowser.html.style.HtmlValues.getFontSize
    val dpi =
      if (GraphicsEnvironment.isHeadless()) 72
      else Toolkit.getDefaultToolkit().getScreenResolution()

    val size0 = font_size * dpi / 96
    val size = if (size0 * 96 / dpi == font_size) size0 else size0 + 1

    """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<style media="all" type="text/css">
""" +
  try_file("$ISABELLE_HOME/lib/html/isabelle.css") + "\n" +
  try_file("$ISABELLE_HOME_USER/etc/isabelle.css") + "\n" +
  "body { font-family: " + sys.font_family + "; font-size: " + size + "px }" +
"""
</style>
</head>
<body/>
</html>
"""
  }


  def panel_width(font_size: Int, relative_margin: Int): Int =
  {
    val font = sys.get_font(font_size)
    Swing_Thread.now {
      val char_width = (getFontMetrics(font).stringWidth("mix") / 3) max 1
      ((getWidth() * relative_margin) / (100 * char_width)) max 20
    }
  }


  /* actor with local state */

  private val ucontext = new SimpleUserAgentContext

  private val rcontext = new SimpleHtmlRendererContext(this, ucontext)
  {
    private def handle(event: HTML_Panel.Event): Boolean =
      if (handler != null && handler.isDefinedAt(event)) { handler(event); true }
      else false

    override def onContextMenu(elem: HTMLElement, event: MouseEvent): Boolean =
      handle(HTML_Panel.Context_Menu(elem, event))
    override def onMouseClick(elem: HTMLElement, event: MouseEvent): Boolean =
      handle(HTML_Panel.Mouse_Click(elem, event))
    override def onDoubleClick(elem: HTMLElement, event: MouseEvent): Boolean =
      handle(HTML_Panel.Double_Click(elem, event))
    override def onMouseOver(elem: HTMLElement, event: MouseEvent)
      { handle(HTML_Panel.Mouse_Over(elem, event)) }
    override def onMouseOut(elem: HTMLElement, event: MouseEvent)
      { handle(HTML_Panel.Mouse_Out(elem, event)) }
  }

  private val builder = new DocumentBuilderImpl(ucontext, rcontext)

  private case class Init(font_size: Int, relative_margin: Int)
  private case class Render(body: List[XML.Tree])

  private val main_actor = actor {
    // crude double buffering
    var doc1: org.w3c.dom.Document = null
    var doc2: org.w3c.dom.Document = null

    var current_font_size = 16
    var current_relative_margin = 90

    loop {
      react {
        case Init(font_size, relative_margin) =>
          current_font_size = font_size
          current_relative_margin = relative_margin

          val src = template(font_size)
          def parse() =
            builder.parse(new InputSourceImpl(new StringReader(src), "http://localhost"))
          doc1 = parse()
          doc2 = parse()
          Swing_Thread.now { setDocument(doc1, rcontext) }
          
        case Render(body) =>
          val doc = doc2
          val html_body =
            Pretty.formatted(body, panel_width(current_font_size, current_relative_margin))
              .map(t => XML.elem(HTML.PRE, HTML.spans(t)))
          val node = XML.document_node(doc, XML.elem(HTML.BODY, html_body))
          doc.removeChild(doc.getLastChild())
          doc.appendChild(node)
          doc2 = doc1
          doc1 = doc
          Swing_Thread.now { setDocument(doc1, rcontext) }

        case bad => System.err.println("main_actor: ignoring bad message " + bad)
      }
    }
  }


  /* main method wrappers */
  
  def init(font_size: Int, relative_margin: Int) { main_actor ! Init(font_size, relative_margin) }
  def render(body: List[XML.Tree]) { main_actor ! Render(body) }

  init(font_size0, relative_margin0)
}
