/*  Title:      Tools/Graphview/layout.scala
    Author:     Markus Kaiser, TU Muenchen
    Author:     Makarius

DAG layout algorithm, according to:

  Georg Sander, "Graph Layout through the VCG Tool", in: Graph Drawing,
  DIMACS International Workshop (GD'94), Springer LNCS 894, 1995.

  http://dx.doi.org/10.1007/3-540-58950-3_371
  ftp://ftp.cs.uni-sb.de/pub/graphics/vcg/doc/tr-A03-94.ps.gz
*/

package isabelle.graphview


import isabelle._


object Layout
{
  object Point { val zero: Point = Point(0.0, 0.0) }
  case class Point(x: Double, y: Double)

  private type Key = Graph_Display.Node
  private type Coordinates = Map[Key, Point]
  private type Level = List[Key]
  private type Levels = List[Level]

  val empty = new Layout(Map.empty, Map.empty)

  val pendulum_iterations = 10
  val minimize_crossings_iterations = 40

  def make(metrics: Visualizer.Metrics, visible_graph: Graph_Display.Graph): Layout =
  {
    if (visible_graph.is_empty) empty
    else {
      def box_width(key: Key): Double =
        (metrics.string_bounds(key.toString).getWidth + metrics.pad).ceil

      val box_distance = (visible_graph.keys_iterator.map(box_width(_)).max + metrics.gap).ceil

      def box_height(level: Level): Double =
        (metrics.char_width * 1.5 * (5 max level.length)).ceil


      val initial_levels = level_map(visible_graph)

      val (dummy_graph, dummies, dummy_levels) =
        ((visible_graph, Map.empty[(Key, Key), List[Key]], initial_levels) /:
          visible_graph.edges_iterator) {
            case ((graph, dummies, levels), (from, to)) =>
              if (levels(to) - levels(from) <= 1) (graph, dummies, levels)
              else {
                val (graph1, ds, levels1) = add_dummies(graph, from, to, levels)
                (graph1, dummies + ((from, to) -> ds), levels1)
              }
          }

      val levels = minimize_crossings(dummy_graph, level_list(dummy_levels))

      val initial_coordinates: Coordinates =
        (((Map.empty[Key, Point], 0.0) /: levels) {
          case ((coords1, y), level) =>
            ((((coords1, 0.0) /: level) {
              case ((coords2, x), key) => (coords2 + (key -> Point(x, y)), x + box_distance)
            })._1, y + box_height(level))
        })._1

      val coords = pendulum(dummy_graph, box_distance, levels, initial_coordinates)

      val dummy_coords =
        (Map.empty[(Key, Key), List[Point]] /: dummies.keys) {
          case (map, key) => map + (key -> dummies(key).map(coords(_)))
        }

      new Layout(coords, dummy_coords)
    }
  }


  def add_dummies(graph: Graph_Display.Graph, from: Key, to: Key, levels: Map[Key, Int])
    : (Graph_Display.Graph, List[Key], Map[Key, Int]) =
  {
    val ds =
      ((levels(from) + 1) until levels(to)).map(l => {
          // FIXME !?
          val ident = "%s$%s$%d".format(from.ident, to.ident, l)
          Graph_Display.Node(ident, ident)
        }).toList

    val ls =
      (levels /: ((levels(from) + 1) until levels(to)).zip(ds)) {
        case (ls, (l, d)) => ls + (d -> l)
      }

    val graph1 = (graph /: ds)(_.new_node(_, Nil))
    val graph2 =
      (graph1.del_edge(from, to) /: (from :: ds ::: List(to)).sliding(2)) {
        case (g, List(x, y)) => g.add_edge(x, y)
      }
    (graph2, ds, ls)
  }

  def level_map(graph: Graph_Display.Graph): Map[Key, Int] =
    (Map.empty[Key, Int] /: graph.topological_order) {
      (levels, key) => {
        val lev = 1 + (-1 /: graph.imm_preds(key)) { case (m, key) => m max levels(key) }
        levels + (key -> lev)
      }
    }

  def level_list(map: Map[Key, Int]): Levels =
  {
    val max_lev = (-1 /: map) { case (m, (_, l)) => m max l }
    val buckets = new Array[Level](max_lev + 1)
    for (l <- 0 to max_lev) { buckets(l) = Nil }
    for ((key, l) <- map) { buckets(l) = key :: buckets(l) }
    buckets.iterator.map(_.sorted(Graph_Display.Node.Ordering)).toList
  }

  def count_crossings(graph: Graph_Display.Graph, levels: Levels): Int =
  {
    def in_level(ls: Levels): Int = ls match {
      case List(top, bot) =>
        top.iterator.zipWithIndex.map {
          case (outer_parent, outer_parent_index) =>
            graph.imm_succs(outer_parent).iterator.map(bot.indexOf(_))
            .map(outer_child =>
              (0 until outer_parent_index)
              .map(inner_parent =>
                graph.imm_succs(top(inner_parent)).iterator.map(bot.indexOf(_))
                .filter(inner_child => outer_child < inner_child)
                .size
              ).sum
            ).sum
        }.sum

      case _ => 0
    }

    levels.iterator.sliding(2).map(ls => in_level(ls.toList)).sum
  }

  def minimize_crossings(graph: Graph_Display.Graph, levels: Levels): Levels =
  {
    def resort_level(parent: Level, child: Level, top_down: Boolean): Level =
      child.map(k => {
          val ps = if (top_down) graph.imm_preds(k) else graph.imm_succs(k)
          val weight =
            (0.0 /: ps) { (w, p) => w + (0 max parent.indexOf(p)) } / (ps.size max 1)
          (k, weight)
      }).sortBy(_._2).map(_._1)

    def resort(levels: Levels, top_down: Boolean) =
      if (top_down)
        (List(levels.head) /: levels.tail)((tops, bot) =>
          resort_level(tops.head, bot, top_down) :: tops).reverse
      else {
        val rev_levels = levels.reverse
        (List(rev_levels.head) /: rev_levels.tail)((bots, top) =>
          resort_level(bots.head, top, top_down) :: bots)
      }

    ((levels, count_crossings(graph, levels), true) /: (1 to minimize_crossings_iterations)) {
      case ((old_levels, old_crossings, top_down), _) => {
          val new_levels = resort(old_levels, top_down)
          val new_crossings = count_crossings(graph, new_levels)
          if (new_crossings < old_crossings)
            (new_levels, new_crossings, !top_down)
          else
            (old_levels, old_crossings, !top_down)
      }
    }._1
  }

  def pendulum(graph: Graph_Display.Graph, box_distance: Double,
    levels: Levels, coords: Map[Key, Point]): Coordinates =
  {
    type Regions = List[List[Region]]

    def iteration(
      coords: Coordinates, regions: Regions, top_down: Boolean): (Coordinates, Regions, Boolean) =
    {
      val (coords1, regions1, moved) =
      ((coords, List.empty[List[Region]], false) /: (if (top_down) regions else regions.reverse)) {
        case ((coords, tops, moved), bot) =>
          val bot1 = collapse(coords, bot, top_down)
          val (coords1, moved1) = deflect(coords, bot1, top_down)
          (coords1, bot1 :: tops, moved || moved1)
      }
      (coords1, regions1.reverse, moved)
    }

    def collapse(coords: Coordinates, level: List[Region], top_down: Boolean): List[Region] =
    {
      if (level.size <= 1) level
      else {
        var next = level
        var regions_changed = true
        while (regions_changed) {
          regions_changed = false
          for (i <- (next.length to 1)) {
            val (r1, r2) = (next(i-1), next(i))
            val d1 = r1.deflection(coords, top_down)
            val d2 = r2.deflection(coords, top_down)

            if (// Do regions touch?
                r1.distance(coords, r2) <= box_distance &&
                // Do they influence each other?
                (d1 <= 0 && d2 < d1 || d2 > 0 && d1 > d2 || d1 > 0 && d2 < 0))
            {
              regions_changed = true
              r1.nodes = r1.nodes ::: r2.nodes
              next = next.filter(next.indexOf(_) != i)
            }
          }
        }
        next
      }
    }

    def deflect(
      coords: Coordinates, level: List[Region], top_down: Boolean): (Coordinates, Boolean) =
    {
      ((coords, false) /: (0 until level.length)) {
        case ((coords, moved), i) =>
          val r = level(i)
          val d = r.deflection(coords, top_down)
          val offset =
          {
            if (i == 0 && d <= 0) d
            else if (i == level.length - 1 && d >= 0) d
            else if (d < 0) {
              val prev = level(i - 1)
              (- (r.distance(coords, prev) - box_distance)) max d
            }
            else {
              val next = level(i + 1)
              (r.distance(coords, next) - box_distance) min d
            }
          }
          (r.move(coords, offset), moved || d != 0)
      }
    }

    val regions = levels.map(level => level.map(new Region(graph, _)))

    ((coords, regions, true, true) /: (1 to pendulum_iterations)) {
      case ((coords, regions, top_down, moved), _) =>
        if (moved) {
          val (coords1, regions1, m) = iteration(coords, regions, top_down)
          (coords1, regions1, !top_down, m)
        }
        else (coords, regions, !top_down, moved)
    }._1
  }

  /*This is an auxiliary class which is used by the layout algorithm when
    calculating coordinates with the "pendulum method". A "region" is a
    group of nodes which "stick together".*/
  private class Region(val graph: Graph_Display.Graph, node: Key)
  {
    var nodes: List[Key] = List(node)

    def left(coords: Coordinates): Double = nodes.iterator.map(coords(_).x).min
    def right(coords: Coordinates): Double = nodes.iterator.map(coords(_).x).max

    def distance(coords: Coordinates, to: Region): Double =
      math.abs(left(coords) - to.left(coords)) min
      math.abs(right(coords) - to.right(coords))

    def deflection(coords: Coordinates, top_down: Boolean): Double =
      (for (a <- nodes.iterator) yield {
        val x = coords(a).x
        val bs = if (top_down) graph.imm_preds(a) else graph.imm_succs(a)
        bs.iterator.map(coords(_).x - x).sum / (bs.size max 1)
      }).sum / nodes.length

    def move(coords: Coordinates, dx: Double): Coordinates =
      (coords /: nodes) {
        case (cs, node) =>
          val p = cs(node)
          cs + (node -> Point(p.x + dx, p.y))
      }
  }
}

final class Layout private(
  nodes: Map[Graph_Display.Node, Layout.Point],
  dummies: Map[Graph_Display.Edge, List[Layout.Point]])
{
  def get_node(node: Graph_Display.Node): Layout.Point =
    nodes.getOrElse(node, Layout.Point.zero)

  def map_node(node: Graph_Display.Node, f: Layout.Point => Layout.Point): Layout =
    nodes.get(node) match {
      case None => this
      case Some(p) => new Layout(nodes + (node -> f(p)), dummies)
    }


  def get_dummies(edge: Graph_Display.Edge): List[Layout.Point] =
    dummies.getOrElse(edge, Nil)

  def map_dummies(edge: Graph_Display.Edge, f: List[Layout.Point] => List[Layout.Point]): Layout =
    dummies.get(edge) match {
      case None => this
      case Some(ds) => new Layout(nodes, dummies + (edge -> f(ds)))
    }
}

