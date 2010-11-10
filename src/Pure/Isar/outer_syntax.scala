/*  Title:      Pure/Isar/outer_syntax.scala
    Author:     Makarius

Isabelle/Isar outer syntax.
*/

package isabelle


import scala.util.parsing.input.{Reader, CharSequenceReader}


class Outer_Syntax(symbols: Symbol.Interpretation)
{
  protected val keywords: Map[String, String] = Map((";" -> Keyword.DIAG))
  protected val lexicon: Scan.Lexicon = Scan.Lexicon.empty
  lazy val completion: Completion = new Completion + symbols  // FIXME !?

  def keyword_kind(name: String): Option[String] = keywords.get(name)

  def + (name: String, kind: String): Outer_Syntax =
  {
    val new_keywords = keywords + (name -> kind)
    val new_lexicon = lexicon + name
    val new_completion = completion + name
    new Outer_Syntax(symbols) {
      override val lexicon = new_lexicon
      override val keywords = new_keywords
      override lazy val completion = new_completion
    }
  }

  def + (name: String): Outer_Syntax = this + (name, Keyword.MINOR)

  def is_command(name: String): Boolean =
    keywords.get(name) match {
      case Some(kind) => kind != Keyword.MINOR
      case None => false
    }

  def is_heading(name: String): Boolean =
    keywords.get(name) match {
      case Some(kind) => Keyword.heading(kind)
      case None => false
    }

  def heading_level(name: String): Option[Int] =
    name match {
      // FIXME avoid hard-wired info
      case "header" => Some(1)
      case "chapter" => Some(2)
      case "section" | "sect" => Some(3)
      case "subsection" | "subsect" => Some(4)
      case "subsubsection" | "subsubsect" => Some(5)
      case _ => None
    }

  def heading_level(command: Command): Option[Int] =
    heading_level(command.name)


  /* tokenize */

  def scan(input: Reader[Char]): List[Token] =
  {
    import lexicon._

    parseAll(rep(token(symbols, is_command)), input) match {
      case Success(tokens, _) => tokens
      case _ => error("Unexpected failure of tokenizing input:\n" + input.source.toString)
    }
  }

  def scan(input: CharSequence): List[Token] =
    scan(new CharSequenceReader(input))
}
