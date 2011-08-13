/*  Title:      Pure/General/yxml.scala
    Author:     Makarius

Efficient text representation of XML trees.
*/

package isabelle


import scala.collection.mutable


object YXML
{
  /* chunk markers */

  val X = '\5'
  val Y = '\6'
  val X_string = X.toString
  val Y_string = Y.toString

  def detect(s: String): Boolean = s.exists(c => c == X || c == Y)


  /* string representation */  // FIXME byte array version with pseudo-utf-8 (!?)

  def string_of_body(body: XML.Body): String =
  {
    val s = new StringBuilder
    def attrib(p: (String, String)) { s += Y; s ++= p._1; s += '='; s ++= p._2 }
    def tree(t: XML.Tree): Unit =
      t match {
        case XML.Elem(Markup(name, atts), ts) =>
          s += X; s += Y; s++= name; atts.foreach(attrib); s += X
          ts.foreach(tree)
          s += X; s += Y; s += X
        case XML.Text(text) => s ++= text
      }
    body.foreach(tree)
    s.toString
  }

  def string_of_tree(tree: XML.Tree): String = string_of_body(List(tree))


  /* parsing */

  private def err(msg: String) = error("Malformed YXML: " + msg)
  private def err_attribute() = err("bad attribute")
  private def err_element() = err("bad element")
  private def err_unbalanced(name: String) =
    if (name == "") err("unbalanced element")
    else err("unbalanced element " + quote(name))

  private def parse_attrib(source: CharSequence) = {
    val s = source.toString
    val i = s.indexOf('=')
    if (i <= 0) err_attribute()
    (s.substring(0, i), s.substring(i + 1))
  }


  def parse_body(source: CharSequence): XML.Body =
  {
    /* stack operations */

    def buffer(): mutable.ListBuffer[XML.Tree] = new mutable.ListBuffer[XML.Tree]
    var stack: List[(Markup, mutable.ListBuffer[XML.Tree])] = List((Markup.Empty, buffer()))

    def add(x: XML.Tree)
    {
      (stack: @unchecked) match { case ((_, body) :: _) => body += x }
    }

    def push(name: String, atts: XML.Attributes)
    {
      if (name == "") err_element()
      else stack = (Markup(name, atts), buffer()) :: stack
    }

    def pop()
    {
      (stack: @unchecked) match {
        case ((Markup.Empty, _) :: _) => err_unbalanced("")
        case ((markup, body) :: pending) =>
          stack = pending
          add(XML.Elem(markup, body.toList))
      }
    }


    /* parse chunks */

    for (chunk <- Library.chunks(source, X) if chunk.length != 0) {
      if (chunk.length == 1 && chunk.charAt(0) == Y) pop()
      else {
        Library.chunks(chunk, Y).toList match {
          case ch :: name :: atts if ch.length == 0 =>
            push(name.toString, atts.map(parse_attrib))
          case txts => for (txt <- txts) add(XML.Text(txt.toString))
        }
      }
    }
    (stack: @unchecked) match {
      case List((Markup.Empty, body)) => body.toList
      case (Markup(name, _), _) :: _ => err_unbalanced(name)
    }
  }

  def parse(source: CharSequence): XML.Tree =
    parse_body(source) match {
      case List(result) => result
      case Nil => XML.Text("")
      case _ => err("multiple results")
    }


  /* failsafe parsing */

  private def markup_malformed(source: CharSequence) =
    XML.elem(Markup.MALFORMED, List(XML.Text(source.toString)))

  def parse_body_failsafe(source: CharSequence): XML.Body =
  {
    try { parse_body(source) }
    catch { case ERROR(_) => List(markup_malformed(source)) }
  }

  def parse_failsafe(source: CharSequence): XML.Tree =
  {
    try { parse(source) }
    catch { case ERROR(_) => markup_malformed(source) }
  }
}
