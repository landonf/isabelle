/*  Title:      Pure/General/pretty.scala
    Author:     Makarius

Generic pretty printing module.
*/

package isabelle


object Pretty
{
  /* XML constructors */

  val space: XML.Body = List(XML.Text(Symbol.space))
  def spaces(n: Int): XML.Body =
    if (n == 0) Nil
    else if (n == 1) space
    else List(XML.Text(Symbol.spaces(n)))

  def block(consistent: Boolean, indent: Int, body: XML.Body): XML.Tree =
    XML.Elem(Markup.Block(consistent, indent), body)
  def block(indent: Int, body: XML.Body): XML.Tree = block(false, indent, body)
  def block(body: XML.Body): XML.Tree = block(2, body)

  def brk(width: Int, indent: Int = 0): XML.Tree =
    XML.Elem(Markup.Break(width, indent), spaces(width))

  val fbrk: XML.Tree = XML.Text("\n")

  val Separator: XML.Body = List(XML.elem(Markup.SEPARATOR, space), fbrk)
  def separate(ts: List[XML.Tree]): XML.Body = Library.separate(Separator, ts.map(List(_))).flatten


  /* text metric -- standardized to width of space */

  abstract class Metric
  {
    val unit: Double
    def apply(s: String): Double
  }

  object Metric_Default extends Metric
  {
    val unit = 1.0
    def apply(s: String): Double = s.length.toDouble
  }


  /* markup trees with physical blocks and breaks */

  private sealed abstract class Tree { def length: Double }
  private case class Block(
    markup: Option[(Markup, Option[XML.Body])],
    consistent: Boolean, indent: Int, body: List[Tree], length: Double) extends Tree
  private case class Break(force: Boolean, width: Int, indent: Int) extends Tree
  { def length: Double = width.toDouble }
  private case class Str(string: String, length: Double) extends Tree

  private val FBreak = Break(true, 1, 0)

  private def make_block(
      markup: Option[(Markup, Option[XML.Body])],
      consistent: Boolean,
      indent: Int,
      body: List[Tree]): Tree =
    Block(markup, consistent, indent, body, (0.0 /: body) { case (n, t) => n + t.length })


  /* formatted output */

  private sealed case class Text(tx: XML.Body = Nil, pos: Double = 0.0, nl: Int = 0)
  {
    def newline: Text = copy(tx = fbrk :: tx, pos = 0.0, nl = nl + 1)
    def string(s: String, len: Double): Text =
      copy(tx = if (s == "") tx else XML.Text(s) :: tx, pos = pos + len)
    def blanks(wd: Int): Text = string(Symbol.spaces(wd), wd.toDouble)
    def content: XML.Body = tx.reverse
  }

  private def break_dist(trees: List[Tree], after: Double): Double =
    trees match {
      case (_: Break) :: _ => 0.0
      case t :: ts => t.length + break_dist(ts, after)
      case Nil => after
    }

  private def force_break(tree: Tree): Tree =
    tree match { case Break(false, wd, ind) => Break(true, wd, ind) case _ => tree }
  private def force_all(trees: List[Tree]): List[Tree] = trees.map(force_break(_))

  private def force_next(trees: List[Tree]): List[Tree] =
    trees match {
      case Nil => Nil
      case (t: Break) :: ts => force_break(t) :: ts
      case t :: ts => t :: force_next(ts)
    }

  private val margin_default = 76.0

  def formatted(input: XML.Body, margin: Double = margin_default,
    metric: Metric = Metric_Default): XML.Body =
  {
    val breakgain = margin / 20
    val emergencypos = (margin / 2).round.toInt

    def make_tree(inp: XML.Body): List[Tree] =
      inp flatMap {
        case XML.Wrapped_Elem(markup, body1, body2) =>
          List(make_block(Some(markup, Some(body1)), false, 0, make_tree(body2)))
        case XML.Elem(markup, body) =>
          markup match {
            case Markup.Block(consistent, indent) =>
              List(make_block(None, consistent, indent, make_tree(body)))
            case Markup.Break(width, indent) =>
              List(Break(false, width, indent))
            case Markup(Markup.ITEM, _) =>
              List(make_block(None, false, 2,
                make_tree(XML.elem(Markup.BULLET, space) :: space ::: body)))
            case _ =>
              List(make_block(Some((markup, None)), false, 0, make_tree(body)))
          }
        case XML.Text(text) =>
          Library.separate(FBreak, split_lines(text).map(s => Str(s, metric(s))))
      }

    def format(trees: List[Tree], blockin: Int, after: Double, text: Text): Text =
      trees match {
        case Nil => text

        case Block(markup, consistent, indent, body, blen) :: ts =>
          val pos1 = (text.pos + indent).ceil.toInt
          val pos2 = pos1 % emergencypos
          val blockin1 = if (pos1 < emergencypos) pos1 else pos2
          val d = break_dist(ts, after)
          val body1 = if (consistent && text.pos + blen > margin - d) force_all(body) else body
          val btext =
            markup match {
              case None => format(body1, blockin1, d, text)
              case Some((m, markup_body)) =>
                val btext0 = format(body1, blockin1, d, text.copy(tx = Nil))
                val elem =
                  markup_body match {
                    case None => XML.Elem(m, btext0.content)
                    case Some(b) => XML.Wrapped_Elem(m, b, btext0.content)
                  }
                btext0.copy(tx = elem :: text.tx)
            }
          val ts1 = if (text.nl < btext.nl) force_next(ts) else ts
          format(ts1, blockin, after, btext)

        case Break(force, wd, ind) :: ts =>
          if (!force &&
              text.pos + wd <= ((margin - break_dist(ts, after)) max (blockin + breakgain)))
            format(ts, blockin, after, text.blanks(wd))
          else format(ts, blockin, after, text.newline.blanks(blockin + ind))

        case Str(s, len) :: ts => format(ts, blockin, after, text.string(s, len))
      }
    format(make_tree(input), 0, 0.0, Text()).content
  }

  def string_of(input: XML.Body, margin: Double = margin_default,
      metric: Metric = Metric_Default): String =
    XML.content(formatted(input, margin, metric))


  /* unformatted output */

  def unformatted(input: XML.Body): XML.Body =
  {
    def fmt(tree: XML.Tree): XML.Body =
      tree match {
        case XML.Wrapped_Elem(markup, body1, body2) =>
          List(XML.Wrapped_Elem(markup, body1, body2.flatMap(fmt)))
        case XML.Elem(markup, body) =>
          markup match {
            case Markup.Block(_, _) => body.flatMap(fmt)
            case Markup.Break(wd, _) => spaces(wd)
            case _ => List(XML.Elem(markup, body.flatMap(fmt)))
          }
        case XML.Text(s) => List(XML.Text(s.replace('\n', ' ')))
      }
    input.flatMap(fmt)
  }

  def str_of(input: XML.Body): String = XML.content(unformatted(input))
}
