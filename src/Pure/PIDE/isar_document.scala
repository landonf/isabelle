/*  Title:      Pure/PIDE/isar_document.scala
    Author:     Makarius

Protocol message formats for interactive Isar documents.
*/

package isabelle


object Isar_Document
{
  /* document editing */

  object Assign {
    def unapply(msg: XML.Tree)
        : Option[(Document.Version_ID, List[(Document.Command_ID, Document.Exec_ID)])] =
      msg match {
        case XML.Elem(Markup(Markup.ASSIGN, List((Markup.VERSION, Document.ID(id)))), edits) =>
          val id_edits = edits.map(Edit.unapply)
          if (id_edits.forall(_.isDefined)) Some((id, id_edits.map(_.get)))
          else None
        case _ => None
      }
  }

  object Edit {
    def unapply(msg: XML.Tree): Option[(Document.Command_ID, Document.Exec_ID)] =
      msg match {
        case XML.Elem(
          Markup(Markup.EDIT,
            List((Markup.ID, Document.ID(i)), (Markup.EXEC, Document.ID(j)))), Nil) => Some((i, j))
        case _ => None
      }
  }


  /* toplevel transactions */

  sealed abstract class Status
  case class Forked(forks: Int) extends Status
  case object Unprocessed extends Status
  case object Finished extends Status
  case object Failed extends Status

  def command_status(markup: List[Markup]): Status =
  {
    val forks = (0 /: markup) {
      case (i, Markup(Markup.FORKED, _)) => i + 1
      case (i, Markup(Markup.JOINED, _)) => i - 1
      case (i, _) => i
    }
    if (forks != 0) Forked(forks)
    else if (markup.exists(_.name == Markup.FAILED)) Failed
    else if (markup.exists(_.name == Markup.FINISHED)) Finished
    else Unprocessed
  }


  /* result messages */

  def is_warning(msg: XML.Tree): Boolean =
    msg match {
      case XML.Elem(Markup(Markup.WARNING, _), _) => true
      case _ => false
    }

  def is_error(msg: XML.Tree): Boolean =
    msg match {
      case XML.Elem(Markup(Markup.ERROR, _), _) => true
      case _ => false
    }


  /* reported positions */

  private val include_pos = Set(Markup.BINDING, Markup.ENTITY, Markup.REPORT, Markup.POSITION)
  private val exclude_pos = Set(Markup.LOCATION)

  private def is_state(msg: XML.Tree): Boolean =
    msg match {
      case XML.Elem(Markup(Markup.WRITELN, _), List(XML.Elem(Markup(Markup.STATE, _), _))) => true
      case _ => false
    }

  def reported_positions(command: Command, message: XML.Elem): Set[Text.Range] =
  {
    def reported(set: Set[Text.Range], tree: XML.Tree): Set[Text.Range] =
      tree match {
        case XML.Elem(Markup(name, Position.Id_Range(id, raw_range)), body)
        if include_pos(name) && id == command.id =>
          val range = command.decode(raw_range).restrict(command.range)
          body.foldLeft(if (range.is_singularity) set else set + range)(reported)
        case XML.Elem(Markup(name, _), body) if !exclude_pos(name) =>
          body.foldLeft(set)(reported)
        case _ => set
      }
    val set = reported(Set.empty, message)
    if (set.isEmpty && !is_state(message))
      set ++ Position.Range.unapply(message.markup.properties).map(command.decode(_))
    else set
  }
}


trait Isar_Document extends Isabelle_Process
{
  import Isar_Document._


  /* commands */

  def define_command(id: Document.Command_ID, text: String): Unit =
    input("Isar_Document.define_command", Document.ID(id), text)


  /* document versions */

  def edit_version(old_id: Document.Version_ID, new_id: Document.Version_ID,
      edits: List[Document.Edit[Document.Command_ID]])
  {
    val arg =
      XML_Data.make_list(
        XML_Data.make_pair(XML_Data.make_string)(
          XML_Data.make_option(XML_Data.make_list(
              XML_Data.make_pair(
                XML_Data.make_option(XML_Data.make_long))(
                XML_Data.make_option(XML_Data.make_long))))))(edits)

    input("Isar_Document.edit_version",
      Document.ID(old_id), Document.ID(new_id), YXML.string_of_body(arg))
  }
}
