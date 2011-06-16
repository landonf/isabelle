/*  Title:      Tools/jEdit/src/isabelle_markup.scala
    Author:     Makarius

Isabelle specific physical rendering and markup selection.
*/

package isabelle.jedit


import isabelle._

import java.awt.Color

import org.lobobrowser.util.gui.ColorFactory
import org.gjt.sp.jedit.syntax.{Token => JEditToken}


object Isabelle_Markup
{
  /* physical rendering */

  // see http://www.w3schools.com/css/css_colornames.asp

  def get_color(s: String): Color = ColorFactory.getInstance.getColor(s)

  val outdated_color = new Color(240, 240, 240)
  val unfinished_color = new Color(255, 228, 225)

  val light_color = new Color(240, 240, 240)
  val regular_color = new Color(192, 192, 192)
  val warning_color = new Color(255, 140, 0)
  val error_color = new Color(178, 34, 34)
  val bad_color = new Color(255, 106, 106, 100)
  val hilite_color = new Color(255, 204, 102, 100)

  val keyword1_color = get_color("#006699")
  val keyword2_color = get_color("#009966")

  class Icon(val priority: Int, val icon: javax.swing.Icon)
  {
    def >= (that: Icon): Boolean = this.priority >= that.priority
  }
  val warning_icon = new Icon(1, Isabelle.load_icon("16x16/status/dialog-warning.png"))
  val error_icon = new Icon(2, Isabelle.load_icon("16x16/status/dialog-error.png"))


  /* command status */

  def status_color(snapshot: Document.Snapshot, command: Command): Option[Color] =
  {
    val state = snapshot.state(command)
    if (snapshot.is_outdated) Some(outdated_color)
    else
      Isar_Document.command_status(state.status) match {
        case Isar_Document.Forked(i) if i > 0 => Some(unfinished_color)
        case Isar_Document.Unprocessed => Some(unfinished_color)
        case _ => None
      }
  }

  def overview_color(snapshot: Document.Snapshot, command: Command): Option[Color] =
  {
    val state = snapshot.state(command)
    if (snapshot.is_outdated) None
    else
      Isar_Document.command_status(state.status) match {
        case Isar_Document.Forked(i) => if (i > 0) Some(unfinished_color) else None
        case Isar_Document.Unprocessed => Some(unfinished_color)
        case Isar_Document.Failed => Some(error_color)
        case Isar_Document.Finished =>
          if (state.results.exists(r => Isar_Document.is_error(r._2))) Some(error_color)
          else if (state.results.exists(r => Isar_Document.is_warning(r._2))) Some(warning_color)
          else None
      }
  }


  /* markup selectors */

  val message: Markup_Tree.Select[Color] =
  {
    case Text.Info(_, XML.Elem(Markup(Markup.WRITELN, _), _)) => regular_color
    case Text.Info(_, XML.Elem(Markup(Markup.WARNING, _), _)) => warning_color
    case Text.Info(_, XML.Elem(Markup(Markup.ERROR, _), _)) => error_color
  }

  val popup: Markup_Tree.Select[String] =
  {
    case Text.Info(_, msg @ XML.Elem(Markup(markup, _), _))
    if markup == Markup.WRITELN || markup == Markup.WARNING || markup == Markup.ERROR =>
      Pretty.string_of(List(msg), margin = Isabelle.Int_Property("tooltip-margin"))
  }

  val gutter_message: Markup_Tree.Select[Icon] =
  {
    case Text.Info(_, XML.Elem(Markup(Markup.WARNING, _), _)) => warning_icon
    case Text.Info(_, XML.Elem(Markup(Markup.ERROR, _), _)) => error_icon
  }

  val background1: Markup_Tree.Select[Color] =
  {
    case Text.Info(_, XML.Elem(Markup(Markup.BAD, _), _)) => bad_color
    case Text.Info(_, XML.Elem(Markup(Markup.HILITE, _), _)) => hilite_color
  }

  val background2: Markup_Tree.Select[Color] =
  {
    case Text.Info(_, XML.Elem(Markup(Markup.TOKEN_RANGE, _), _)) => light_color
  }

  /* FIXME update
      Markup.ML_SOURCE -> COMMENT3,
      Markup.DOC_SOURCE -> COMMENT3,
      Markup.ANTIQ -> COMMENT4,
      Markup.ML_ANTIQ -> COMMENT4,
      Markup.DOC_ANTIQ -> COMMENT4,
  */

  private val foreground_colors: Map[String, Color] =
    Map(
      Markup.TCLASS -> get_color("red"),
      Markup.TFREE -> get_color("#A020F0"),
      Markup.TVAR -> get_color("#A020F0"),
      Markup.CONST -> get_color("dimgrey"),
      Markup.FREE -> get_color("blue"),
      Markup.SKOLEM -> get_color("#D2691E"),
      Markup.BOUND -> get_color("green"),
      Markup.VAR -> get_color("#00009B"),
      Markup.INNER_STRING -> get_color("#D2691E"),
      Markup.INNER_COMMENT -> get_color("#8B0000"),
      Markup.DYNAMIC_FACT -> get_color("yellowgreen"),
      Markup.LITERAL -> keyword1_color,
      Markup.ML_KEYWORD -> keyword1_color,
      Markup.ML_DELIMITER -> get_color("black"),
      Markup.ML_NUMERAL -> get_color("red"),
      Markup.ML_CHAR -> get_color("#D2691E"),
      Markup.ML_STRING -> get_color("#D2691E"),
      Markup.ML_COMMENT -> get_color("#8B0000"),
      Markup.ML_MALFORMED -> get_color("#FF6A6A")
    )

  val foreground: Markup_Tree.Select[Color] =
  {
    case Text.Info(_, XML.Elem(Markup(m, _), _))
    if foreground_colors.isDefinedAt(m) => foreground_colors(m)
  }

  val tooltip: Markup_Tree.Select[String] =
  {
    case Text.Info(_, XML.Elem(Markup.Entity(kind, name), _)) => kind + " \"" + name + "\""
    case Text.Info(_, XML.Elem(Markup(Markup.ML_TYPING, _), body)) =>
      Pretty.string_of(List(Pretty.block(XML.Text("ML:") :: Pretty.Break(1) :: body)),
        margin = Isabelle.Int_Property("tooltip-margin"))
    case Text.Info(_, XML.Elem(Markup(Markup.SORT, _), _)) => "sort"
    case Text.Info(_, XML.Elem(Markup(Markup.TYP, _), _)) => "type"
    case Text.Info(_, XML.Elem(Markup(Markup.TERM, _), _)) => "term"
    case Text.Info(_, XML.Elem(Markup(Markup.PROP, _), _)) => "proposition"
    case Text.Info(_, XML.Elem(Markup(Markup.TOKEN_RANGE, _), _)) => "inner syntax token"
    case Text.Info(_, XML.Elem(Markup(Markup.FREE, _), _)) => "free variable (globally fixed)"
    case Text.Info(_, XML.Elem(Markup(Markup.SKOLEM, _), _)) => "skolem variable (locally fixed)"
    case Text.Info(_, XML.Elem(Markup(Markup.BOUND, _), _)) => "bound variable (internally fixed)"
    case Text.Info(_, XML.Elem(Markup(Markup.VAR, _), _)) => "schematic variable"
    case Text.Info(_, XML.Elem(Markup(Markup.TFREE, _), _)) => "free type variable"
    case Text.Info(_, XML.Elem(Markup(Markup.TVAR, _), _)) => "schematic type variable"
  }

  private val subexp_include =
    Set(Markup.SORT, Markup.TYP, Markup.TERM, Markup.PROP, Markup.ML_TYPING, Markup.TOKEN_RANGE,
      Markup.ENTITY, Markup.FREE, Markup.SKOLEM, Markup.BOUND, Markup.VAR,
      Markup.TFREE, Markup.TVAR)

  val subexp: Markup_Tree.Select[(Text.Range, Color)] =
  {
    case Text.Info(range, XML.Elem(Markup(name, _), _)) if subexp_include(name) =>
      (range, Color.black)
  }


  /* token markup -- text styles */

  private val command_style: Map[String, Byte] =
  {
    import JEditToken._
    Map[String, Byte](
      Keyword.THY_END -> KEYWORD2,
      Keyword.THY_SCRIPT -> LABEL,
      Keyword.PRF_SCRIPT -> LABEL,
      Keyword.PRF_ASM -> KEYWORD3,
      Keyword.PRF_ASM_GOAL -> KEYWORD3
    ).withDefaultValue(KEYWORD1)
  }

  private val token_style: Map[Token.Kind.Value, Byte] =
  {
    import JEditToken._
    Map[Token.Kind.Value, Byte](
      Token.Kind.KEYWORD -> KEYWORD2,
      Token.Kind.IDENT -> NULL,
      Token.Kind.LONG_IDENT -> NULL,
      Token.Kind.SYM_IDENT -> NULL,
      Token.Kind.VAR -> NULL,
      Token.Kind.TYPE_IDENT -> NULL,
      Token.Kind.TYPE_VAR -> NULL,
      Token.Kind.NAT -> NULL,
      Token.Kind.FLOAT -> NULL,
      Token.Kind.STRING -> LITERAL3,
      Token.Kind.ALT_STRING -> LITERAL1,
      Token.Kind.VERBATIM -> COMMENT3,
      Token.Kind.SPACE -> NULL,
      Token.Kind.COMMENT -> COMMENT1,
      Token.Kind.UNPARSED -> INVALID
    ).withDefaultValue(NULL)
  }

  def token_markup(syntax: Outer_Syntax, token: Token): Byte =
    if (token.is_command)
      command_style(syntax.keyword_kind(token.content).getOrElse(""))
    else if (token.is_keyword && !Symbol.is_ascii_identifier(token.content))
      JEditToken.OPERATOR
    else token_style(token.kind)
}
