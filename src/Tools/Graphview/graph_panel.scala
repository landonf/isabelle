/*  Title:      Tools/Graphview/graph_panel.scala
    Author:     Markus Kaiser, TU Muenchen
    Author:     Makarius

Graphview Java2D drawing panel.
*/

package isabelle.graphview


import isabelle._

import java.awt.{Dimension, Graphics2D, Point, Rectangle}
import java.awt.geom.{AffineTransform, Point2D}
import java.awt.image.BufferedImage
import javax.swing.{JScrollPane, JComponent, SwingUtilities}

import scala.swing.{Panel, ScrollPane}
import scala.swing.event.{Event, Key, KeyTyped, MousePressed, MouseDragged, MouseClicked, MouseEvent}


class Graph_Panel(val visualizer: Visualizer) extends ScrollPane
{
  panel =>

  override lazy val peer: JScrollPane = new JScrollPane with SuperMixin {
    override def getToolTipText(event: java.awt.event.MouseEvent): String =
      node(Transform.pane_to_graph_coordinates(event.getPoint)) match {
        case Some(name) =>
          visualizer.model.complete_graph.get_node(name).content match {
            case Nil => null
            case content => visualizer.make_tooltip(panel.peer, event.getX, event.getY, content)
          }
        case None => null
      }
  }

  focusable = true
  requestFocus()

  horizontalScrollBarPolicy = ScrollPane.BarPolicy.Always
  verticalScrollBarPolicy = ScrollPane.BarPolicy.Always

  peer.getVerticalScrollBar.setUnitIncrement(10)

  def node(at: Point2D): Option[String] =
  {
    val gfx = visualizer.graphics_context()
    visualizer.model.visible_nodes_iterator
      .find(name => visualizer.Drawer.shape(gfx, Some(name)).contains(at))
  }

  def refresh()
  {
    if (paint_panel != null) {
      paint_panel.set_preferred_size()
      paint_panel.repaint()
    }
  }

  def fit_to_window() = {
    Transform.fit_to_window()
    refresh()
  }

  val zoom = new GUI.Zoom_Box { def changed = rescale(0.01 * factor) }

  def rescale(s: Double)
  {
    Transform.scale = s
    if (zoom != null) zoom.set_item((Transform.scale_discrete * 100).round.toInt)
    refresh()
  }

  def apply_layout() = visualizer.Coordinates.update_layout()

  private class Paint_Panel extends Panel
  {
    def set_preferred_size()
    {
      val (minX, minY, maxX, maxY) = visualizer.Coordinates.bounds()
      val s = Transform.scale_discrete
      val (px, py) = Transform.padding

      preferredSize =
        new Dimension(
          (math.abs(maxX - minX + px) * s).toInt,
          (math.abs(maxY - minY + py) * s).toInt)

      revalidate()
    }

    override def paint(g: Graphics2D)
    {
      super.paintComponent(g)
      g.setColor(visualizer.background_color)
      g.fillRect(0, 0, peer.getWidth, peer.getHeight)
      g.transform(Transform())

      visualizer.Drawer.paint_all_visible(g, true)
    }
  }
  private val paint_panel = new Paint_Panel
  contents = paint_panel

  listenTo(keys)
  listenTo(mouse.moves)
  listenTo(mouse.clicks)
  reactions += Interaction.Mouse.react
  reactions += Interaction.Keyboard.react
  reactions +=
  {
    case KeyTyped(_, _, _, _) => repaint(); requestFocus()
    case MousePressed(_, _, _, _, _) => repaint(); requestFocus()
    case MouseDragged(_, _, _) => repaint(); requestFocus()
    case MouseClicked(_, _, _, _, _) => repaint(); requestFocus()
  }

  visualizer.model.Colors.events += { case _ => repaint() }
  visualizer.model.Mutators.events += { case _ => repaint() }

  apply_layout()
  rescale(1.0)

  private object Transform
  {
    val padding = (100, 40)

    private var _scale: Double = 1.0
    def scale: Double = _scale
    def scale_=(s: Double)
    {
      _scale = (s min 10) max 0.1
    }
    def scale_discrete: Double =
      (_scale * visualizer.font_size).round.toDouble / visualizer.font_size

    def apply() =
    {
      val (minX, minY, _, _) = visualizer.Coordinates.bounds()

      val at = AffineTransform.getScaleInstance(scale_discrete, scale_discrete)
      at.translate(-minX + padding._1 / 2, -minY + padding._2 / 2)
      at
    }

    def fit_to_window()
    {
      if (visualizer.model.visible_nodes_iterator.isEmpty)
        rescale(1.0)
      else {
        val (minX, minY, maxX, maxY) = visualizer.Coordinates.bounds()

        val (dx, dy) = (maxX - minX + padding._1, maxY - minY + padding._2)
        val (sx, sy) = (1.0 * size.width / dx, 1.0 * size.height / dy)
        rescale(sx min sy)
      }
    }

    def pane_to_graph_coordinates(at: Point2D): Point2D =
    {
      val s = Transform.scale_discrete
      val p = Transform().inverseTransform(peer.getViewport.getViewPosition, null)

      p.setLocation(p.getX + at.getX / s, p.getY + at.getY / s)
      p
    }
  }

  object Interaction
  {
    object Keyboard
    {
      val react: PartialFunction[Event, Unit] =
      {
        case KeyTyped(_, c, m, _) => typed(c, m)
      }

      def typed(c: Char, m: Key.Modifiers) =
        c match {
          case '+' => rescale(Transform.scale * 5.0/4)
          case '-' => rescale(Transform.scale * 4.0/5)
          case '0' => Transform.fit_to_window()
          case '1' => apply_layout()
          case _ =>
        }
    }

    object Mouse
    {
      type Dummy = ((String, String), Int)

      private var draginfo: (Point, Iterable[String], Iterable[Dummy]) = null

      val react: PartialFunction[Event, Unit] =
      {
        case MousePressed(_, p, _, _, _) => pressed(p)
        case MouseDragged(_, to, _) =>
          drag(draginfo, to)
          val (_, p, d) = draginfo
          draginfo = (to, p, d)
        case e @ MouseClicked(_, p, m, n, _) => click(p, m, n, e)
      }

      def dummy(at: Point2D): Option[Dummy] =
      {
        val gfx = visualizer.graphics_context()
        visualizer.model.visible_edges_iterator.map(
          i => visualizer.Coordinates(i).zipWithIndex.map((i, _))).flatten.find({
            case (_, ((x, y), _)) =>
              visualizer.Drawer.shape(gfx, None).contains(at.getX() - x, at.getY() - y)
          }) match {
            case None => None
            case Some((name, (_, index))) => Some((name, index))
          }
      }

      def pressed(at: Point)
      {
        val c = Transform.pane_to_graph_coordinates(at)
        val l = node(c) match {
          case Some(l) =>
            if (visualizer.Selection(l)) visualizer.Selection() else List(l)
          case None => Nil
        }
        val d =
          l match {
            case Nil =>
              dummy(c) match {
                case Some(d) => List(d)
                case None => Nil
              }
            case _ => Nil
          }
        draginfo = (at, l, d)
      }

      def click(at: Point, m: Key.Modifiers, clicks: Int, e: MouseEvent)
      {
        val c = Transform.pane_to_graph_coordinates(at)
        val p = node(c)

        def left_click()
        {
          (p, m) match {
            case (Some(l), Key.Modifier.Control) => visualizer.Selection.add(l)
            case (None, Key.Modifier.Control) =>

            case (Some(l), Key.Modifier.Shift) => visualizer.Selection.add(l)
            case (None, Key.Modifier.Shift) =>

            case (Some(l), _) => visualizer.Selection.set(List(l))
            case (None, _) => visualizer.Selection.clear
          }
        }

        def right_click()
        {
          val menu = Popups(panel, p, visualizer.Selection())
          menu.show(panel.peer, at.x, at.y)
        }

        if (clicks < 2) {
          if (SwingUtilities.isRightMouseButton(e.peer)) right_click()
          else left_click()
        }
      }

      def drag(draginfo: (Point, Iterable[String], Iterable[Dummy]), to: Point)
      {
        val (from, p, d) = draginfo

        val s = Transform.scale_discrete
        val (dx, dy) = (to.x - from.x, to.y - from.y)
        (p, d) match {
          case (Nil, Nil) =>
            val r = panel.peer.getViewport.getViewRect
            r.translate(-dx, -dy)

            paint_panel.peer.scrollRectToVisible(r)

          case (Nil, ds) =>
            ds.foreach(d => visualizer.Coordinates.translate(d, (dx / s, dy / s)))

          case (ls, _) =>
            ls.foreach(l => visualizer.Coordinates.translate(l, (dx / s, dy / s)))
        }
      }
    }
  }
}
