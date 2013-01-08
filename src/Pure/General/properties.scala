/*  Title:      Pure/General/properties.scala
    Module:     PIDE
    Author:     Makarius

Property lists.
*/

package isabelle


object Properties
{
  /* plain values */

  object Value
  {
    object Boolean
    {
      def apply(x: scala.Boolean): java.lang.String = x.toString
      def unapply(s: java.lang.String): Option[scala.Boolean] =
        s match {
          case "true" => Some(true)
          case "false" => Some(false)
          case _ => None
        }
    }

    object Int
    {
      def apply(x: scala.Int): java.lang.String = x.toString
      def unapply(s: java.lang.String): Option[scala.Int] =
        try { Some(Integer.parseInt(s)) }
        catch { case _: NumberFormatException => None }
    }

    object Long
    {
      def apply(x: scala.Long): java.lang.String = x.toString
      def unapply(s: java.lang.String): Option[scala.Long] =
        try { Some(java.lang.Long.parseLong(s)) }
        catch { case _: NumberFormatException => None }
    }

    object Double
    {
      def apply(x: scala.Double): java.lang.String = x.toString
      def unapply(s: java.lang.String): Option[scala.Double] =
        try { Some(java.lang.Double.parseDouble(s)) }
        catch { case _: NumberFormatException => None }
    }
  }


  /* named entries */

  type Entry = (java.lang.String, java.lang.String)
  type T = List[Entry]

  class String(val name: java.lang.String)
  {
    def apply(value: java.lang.String): T = List((name, value))
    def unapply(props: T): Option[java.lang.String] =
      props.find(_._1 == name).map(_._2)
  }

  class Boolean(val name: java.lang.String)
  {
    def apply(value: scala.Boolean): T = List((name, Value.Boolean(value)))
    def unapply(props: T): Option[scala.Boolean] =
      props.find(_._1 == name) match {
        case None => None
        case Some((_, value)) => Value.Boolean.unapply(value)
      }
  }

  class Int(val name: java.lang.String)
  {
    def apply(value: scala.Int): T = List((name, Value.Int(value)))
    def unapply(props: T): Option[scala.Int] =
      props.find(_._1 == name) match {
        case None => None
        case Some((_, value)) => Value.Int.unapply(value)
      }
  }

  class Long(val name: java.lang.String)
  {
    def apply(value: scala.Long): T = List((name, Value.Long(value)))
    def unapply(props: T): Option[scala.Long] =
      props.find(_._1 == name) match {
        case None => None
        case Some((_, value)) => Value.Long.unapply(value)
      }
  }

  class Double(val name: java.lang.String)
  {
    def apply(value: scala.Double): T = List((name, Value.Double(value)))
    def unapply(props: T): Option[scala.Double] =
      props.find(_._1 == name) match {
        case None => None
        case Some((_, value)) => Value.Double.unapply(value)
      }
  }


  /* concrete syntax -- similar to ML */

  private val syntax = Outer_Syntax.empty + "," + "(" + ")" + "[" + "]"

  private object Parser extends Parse.Parser
  {
    def prop: Parser[Entry] =
      keyword("(") ~ string ~ keyword(",") ~ string ~ keyword(")") ^^
      { case _ ~ x ~ _ ~ y ~ _ => (x, y) }
    def props: Parser[T] =
      keyword("[") ~> repsep(prop, keyword(",")) <~ keyword("]")
  }

  def parse(text: java.lang.String): Properties.T =
  {
    Parser.parse_all(Parser.props, Token.reader(syntax.scan(text))) match {
      case Parser.Success(result, _) => result
      case bad => error(bad.toString)
    }
  }

  def parse_lines(prefix: java.lang.String, lines: List[java.lang.String]): List[T] =
    for (line <- lines if line.startsWith(prefix))
      yield parse(line.substring(prefix.length))

  def find_parse_line(prefix: java.lang.String, lines: List[java.lang.String]): Option[T] =
    lines.find(_.startsWith(prefix)).map(line => parse(line.substring(prefix.length)))
}

