/*  Title:      Tools/jEdit/src/isabelle_rendering.scala
    Author:     Makarius

Isabelle specific physical rendering and markup selection.
*/

package isabelle.jedit


import isabelle._

import java.awt.Color

import org.lobobrowser.util.gui.ColorFactory
import org.gjt.sp.jedit.syntax.{Token => JEditToken}

import scala.collection.immutable.SortedMap


object Isabelle_Rendering
{
  /* physical rendering */

  // see http://www.w3schools.com/css/css_colornames.asp

  def get_color(s: String): Color = ColorFactory.getInstance.getColor(s)

  val outdated_color = new Color(238, 227, 227)
  val unprocessed_color = new Color(255, 160, 160)
  val unprocessed1_color = new Color(255, 160, 160, 50)
  val running_color = new Color(97, 0, 97)
  val running1_color = new Color(97, 0, 97, 100)

  val light_color = new Color(240, 240, 240)
  val regular_color = new Color(192, 192, 192)
  val warning_color = new Color(255, 140, 0)
  val error_color = new Color(178, 34, 34)
  val error1_color = new Color(178, 34, 34, 50)
  val bad_color = new Color(255, 106, 106, 100)
  val hilite_color = new Color(255, 204, 102, 100)

  val quoted_color = new Color(139, 139, 139, 25)
  val subexp_color = new Color(80, 80, 80, 50)

  val keyword1_color = get_color("#006699")
  val keyword2_color = get_color("#009966")

  class Icon(val priority: Int, val icon: javax.swing.Icon)
  {
    def >= (that: Icon): Boolean = this.priority >= that.priority
  }
  val warning_icon = new Icon(1, Isabelle.load_icon("16x16/status/dialog-information.png"))
  val legacy_icon = new Icon(2, Isabelle.load_icon("16x16/status/dialog-warning.png"))
  val error_icon = new Icon(3, Isabelle.load_icon("16x16/status/dialog-error.png"))


  /* command overview */

  def overview_color(snapshot: Document.Snapshot, command: Command): Option[Color] =
  {
    val state = snapshot.command_state(command)
    if (snapshot.is_outdated) None
    else {
      val status = Protocol.command_status(state.status)

      if (status.is_unprocessed) Some(unprocessed_color)
      else if (status.is_running) Some(running_color)
      else if (status.is_finished) {
        if (state.results.exists(r => Protocol.is_error(r._2))) Some(error_color)
        else if (state.results.exists(r => Protocol.is_warning(r._2))) Some(warning_color)
        else None
      }
      else if (status.is_failed) Some(error_color)
      else None
    }
  }


  /* markup selectors */

  def message_color(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
    for {
      Text.Info(r, Some(color)) <-
        snapshot.select_markup(range,
          Some(Set(Isabelle_Markup.WRITELN, Isabelle_Markup.WARNING, Isabelle_Markup.ERROR)),
          {
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.WRITELN, _), _)) => regular_color
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.WARNING, _), _)) => warning_color
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ERROR, _), _)) => error_color
          })
    } yield Text.Info(r, color)

  def tooltip_message(snapshot: Document.Snapshot, range: Text.Range): Option[String] =
    snapshot.cumulate_markup[SortedMap[Long, String]](range, SortedMap.empty,
      Some(Set(Isabelle_Markup.WRITELN, Isabelle_Markup.WARNING, Isabelle_Markup.ERROR)),
      {
        case (msgs, Text.Info(_, msg @ XML.Elem(Markup(markup, Isabelle_Markup.Serial(serial)), _)))
        if markup == Isabelle_Markup.WRITELN ||
            markup == Isabelle_Markup.WARNING ||
            markup == Isabelle_Markup.ERROR =>
          msgs + (serial ->
            Pretty.string_of(List(msg), margin = Isabelle.Int_Property("tooltip-margin")))
      }) match {
        case Text.Info(_, msgs) #:: _ if !msgs.isEmpty =>
          Some(msgs.iterator.map(_._2).mkString("\n"))
        case _ => None
      }

  def gutter_message(snapshot: Document.Snapshot, range: Text.Range): Option[Icon] =
  {
    val icons =
      (for {
        Text.Info(_, Some(icon)) <-
          // FIXME snapshot.cumulate_markup
          snapshot.select_markup[Icon](range,
            Some(Set(Isabelle_Markup.WARNING, Isabelle_Markup.ERROR)),
            {
              case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.WARNING, _), body)) =>
                body match {
                  case List(XML.Elem(Markup(Isabelle_Markup.LEGACY, _), _)) => legacy_icon
                  case _ => warning_icon
                }
              case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ERROR, _), _)) => error_icon
            })
        } yield icon).toList.sortWith(_ >= _)
    icons match {
      case icon :: _ => Some(icon)
      case Nil => None
    }
  }

  def background1(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
  {
    for {
      Text.Info(r, result) <-
        snapshot.cumulate_markup[(Option[Protocol.Status], Option[Color])](
          range, (Some(Protocol.Status()), None),
          Some(Protocol.command_status_markup + Isabelle_Markup.BAD + Isabelle_Markup.HILITE),
          {
            case (((Some(status), color), Text.Info(_, XML.Elem(markup, _))))
            if (Protocol.command_status_markup(markup.name)) =>
              (Some(Protocol.command_status(status, markup)), color)
            case (_, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.BAD, _), _))) =>
              (None, Some(bad_color))
            case (_, Text.Info(_, XML.Elem(Markup(Isabelle_Markup.HILITE, _), _))) =>
              (None, Some(hilite_color))
          })
      color <-
        (result match {
          case (Some(status), _) =>
            if (status.is_running) Some(running1_color)
            else if (status.is_unprocessed) Some(unprocessed1_color)
            else None
          case (_, opt_color) => opt_color
        })
    } yield Text.Info(r, color)
  }

  def background2(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
    for {
      Text.Info(r, Some(color)) <-
        snapshot.select_markup(range,
          Some(Set(Isabelle_Markup.TOKEN_RANGE)),
          {
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.TOKEN_RANGE, _), _)) => light_color
          })
    } yield Text.Info(r, color)

  def foreground(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Color]] =
    for {
      Text.Info(r, Some(color)) <-
        snapshot.select_markup(range,
          Some(Set(Isabelle_Markup.STRING, Isabelle_Markup.ALTSTRING, Isabelle_Markup.VERBATIM)),
          {
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.STRING, _), _)) => quoted_color
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ALTSTRING, _), _)) => quoted_color
            case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.VERBATIM, _), _)) => quoted_color
          })
    } yield Text.Info(r, color)

  private val text_colors: Map[String, Color] =
    Map(
      Isabelle_Markup.STRING -> get_color("black"),
      Isabelle_Markup.ALTSTRING -> get_color("black"),
      Isabelle_Markup.VERBATIM -> get_color("black"),
      Isabelle_Markup.LITERAL -> keyword1_color,
      Isabelle_Markup.DELIMITER -> get_color("black"),
      Isabelle_Markup.TFREE -> get_color("#A020F0"),
      Isabelle_Markup.TVAR -> get_color("#A020F0"),
      Isabelle_Markup.FREE -> get_color("blue"),
      Isabelle_Markup.SKOLEM -> get_color("#D2691E"),
      Isabelle_Markup.BOUND -> get_color("green"),
      Isabelle_Markup.VAR -> get_color("#00009B"),
      Isabelle_Markup.INNER_STRING -> get_color("#D2691E"),
      Isabelle_Markup.INNER_COMMENT -> get_color("#8B0000"),
      Isabelle_Markup.DYNAMIC_FACT -> get_color("#7BA428"),
      Isabelle_Markup.ML_KEYWORD -> keyword1_color,
      Isabelle_Markup.ML_DELIMITER -> get_color("black"),
      Isabelle_Markup.ML_NUMERAL -> get_color("red"),
      Isabelle_Markup.ML_CHAR -> get_color("#D2691E"),
      Isabelle_Markup.ML_STRING -> get_color("#D2691E"),
      Isabelle_Markup.ML_COMMENT -> get_color("#8B0000"),
      Isabelle_Markup.ML_MALFORMED -> get_color("#FF6A6A"),
      Isabelle_Markup.ANTIQ -> get_color("blue"))

  private val text_color_elements = Set.empty[String] ++ text_colors.keys

  def text_color(snapshot: Document.Snapshot, range: Text.Range): Stream[Text.Info[Option[Color]]] =
    snapshot.select_markup(range, Some(text_color_elements),
      {
        case Text.Info(_, XML.Elem(Markup(m, _), _))
        if text_colors.isDefinedAt(m) => text_colors(m)
      })

  private val tooltips: Map[String, String] =
    Map(
      Isabelle_Markup.SORT -> "sort",
      Isabelle_Markup.TYP -> "type",
      Isabelle_Markup.TERM -> "term",
      Isabelle_Markup.PROP -> "proposition",
      Isabelle_Markup.TOKEN_RANGE -> "inner syntax token",
      Isabelle_Markup.FREE -> "free variable",
      Isabelle_Markup.SKOLEM -> "skolem variable",
      Isabelle_Markup.BOUND -> "bound variable",
      Isabelle_Markup.VAR -> "schematic variable",
      Isabelle_Markup.TFREE -> "free type variable",
      Isabelle_Markup.TVAR -> "schematic type variable",
      Isabelle_Markup.ML_SOURCE -> "ML source",
      Isabelle_Markup.DOC_SOURCE -> "document source")

  private def string_of_typing(kind: String, body: XML.Body): String =
    Pretty.string_of(List(Pretty.block(XML.Text(kind) :: Pretty.Break(1) :: body)),
      margin = Isabelle.Int_Property("tooltip-margin"))

  def tooltip(snapshot: Document.Snapshot, range: Text.Range): Option[String] =
  {
    val tip1 =
      snapshot.select_markup(range,
        Some(Set(Isabelle_Markup.ENTITY, Isabelle_Markup.ML_TYPING) ++ tooltips.keys),
        {
          case Text.Info(_, XML.Elem(Isabelle_Markup.Entity(kind, name), _)) =>
            kind + " " + quote(name)
          case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.ML_TYPING, _), body)) =>
            string_of_typing("ML:", body)
          case Text.Info(_, XML.Elem(Markup(name, _), _))
          if tooltips.isDefinedAt(name) => tooltips(name)
        })
    val tip2 =
      snapshot.select_markup(range, Some(Set(Isabelle_Markup.TYPING)),
        {
          case Text.Info(_, XML.Elem(Markup(Isabelle_Markup.TYPING, _), body)) =>
            string_of_typing("::", body)
        })

    val tips =
      (tip1 match { case Text.Info(_, Some(text)) #:: _ => List(text) case _ => Nil }) :::
      (tip2 match { case Text.Info(_, Some(text)) #:: _ => List(text) case _ => Nil })

    if (tips.isEmpty) None else Some(tips.mkString("\n"))
  }

  private val subexp_include =
    Set(Isabelle_Markup.SORT, Isabelle_Markup.TYP, Isabelle_Markup.TERM, Isabelle_Markup.PROP,
      Isabelle_Markup.ML_TYPING, Isabelle_Markup.TOKEN_RANGE, Isabelle_Markup.ENTITY,
      Isabelle_Markup.TYPING, Isabelle_Markup.FREE, Isabelle_Markup.SKOLEM, Isabelle_Markup.BOUND,
      Isabelle_Markup.VAR, Isabelle_Markup.TFREE, Isabelle_Markup.TVAR, Isabelle_Markup.ML_SOURCE,
      Isabelle_Markup.DOC_SOURCE)

  def subexp(snapshot: Document.Snapshot, range: Text.Range): Option[(Text.Range, Color)] =
  {
    snapshot.select_markup(range, Some(subexp_include),
        {
          case Text.Info(range, XML.Elem(Markup(name, _), _)) if subexp_include(name) =>
            (range, subexp_color)
        }) match {
      case Text.Info(_, Some((range, color))) #:: _ => Some((snapshot.convert(range), color))
      case _ => None
    }
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
      Token.Kind.STRING -> LITERAL1,
      Token.Kind.ALT_STRING -> LITERAL2,
      Token.Kind.VERBATIM -> COMMENT3,
      Token.Kind.SPACE -> NULL,
      Token.Kind.COMMENT -> COMMENT1,
      Token.Kind.UNPARSED -> INVALID
    ).withDefaultValue(NULL)
  }

  def token_markup(syntax: Outer_Syntax, token: Token): Byte =
    if (token.is_command) command_style(syntax.keyword_kind(token.content).getOrElse(""))
    else if (token.is_operator) JEditToken.OPERATOR
    else token_style(token.kind)
}
