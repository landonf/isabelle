/*
 * Higher-level prover communication: interactive document model
 *
 * @author Johannes Hölzl, TU Munich
 * @author Fabian Immler, TU Munich
 * @author Makarius
 */

package isabelle.prover


import scala.actors.Actor, Actor._

import javax.swing.JTextArea

import isabelle.jedit.Isabelle
import isabelle.proofdocument.{ProofDocument, Change, Token}


class Prover(isabelle_system: Isabelle_System, logic: String) extends Actor
{
  /* incoming messages */
  
  private var prover_ready = false

  def act() {
    loop {
      react {
        case result: Isabelle_Process.Result => handle_result(result)
        case change: Change if prover_ready => handle_change(change)
        case bad if prover_ready => System.err.println("prover: ignoring bad message " + bad)
      }
    }
  }


  /* outgoing messages */
  
  val command_change = new Event_Bus[Command]
  val document_change = new Event_Bus[ProofDocument]


  /* prover process */

  private val process =
    new Isabelle_Process(isabelle_system, this, "-m", "xsymbols", logic)
      with Isar_Document

  def stop() { process.kill }

  
  /* outer syntax keywords and completion */

  @volatile private var _command_decls = Map[String, String]()
  def command_decls() = _command_decls

  @volatile private var _keyword_decls = Set[String]()
  def keyword_decls() = _keyword_decls

  @volatile private var _completion = Isabelle.completion
  def completion() = _completion


  /* document state information */

  @volatile private var states = Map[Isar_Document.State_ID, Command_State]()
  @volatile private var commands = Map[Isar_Document.Command_ID, Command]()
  val document_0 =
    ProofDocument.empty.
      set_command_keyword((s: String) => command_decls().contains(s))
  @volatile private var document_versions = List(document_0)

  def command(id: Isar_Document.Command_ID): Option[Command] = commands.get(id)
  def document(id: Isar_Document.Document_ID): Option[ProofDocument] =
    document_versions.find(_.id == id)
  

  /* prover results */

  val output_text_view = new JTextArea

  private def handle_result(result: Isabelle_Process.Result)
  {
    val state =
      result.props.find(p => p._1 == Markup.ID) match {
        case None => None
        case Some((_, id)) =>
          if (commands.contains(id)) Some(commands(id))
          else if (states.contains(id)) Some(states(id))
          else None
      }
    Swing_Thread.later { output_text_view.append(result.toString + "\n") }  // slow?

    val message = Isabelle_Process.parse_message(isabelle_system, result)

    if (state.isDefined) state.get ! (this, message)
    else result.kind match {

      case Isabelle_Process.Kind.STATUS =>
        //{{{ handle all kinds of status messages here
        message match {
          case XML.Elem(Markup.MESSAGE, _, elems) =>
            for (elem <- elems) {
              elem match {
                //{{{
                // command and keyword declarations
                case XML.Elem(Markup.COMMAND_DECL,
                    (Markup.NAME, name) :: (Markup.KIND, kind) :: _, _) =>
                  _command_decls += (name -> kind)
                  _completion += name
                case XML.Elem(Markup.KEYWORD_DECL, (Markup.NAME, name) :: _, _) =>
                  _keyword_decls += name
                  _completion += name

                // process ready (after initialization)
                case XML.Elem(Markup.READY, _, _) => prover_ready = true

                // document edits
                case XML.Elem(Markup.EDITS, (Markup.ID, doc_id) :: _, edits)
                if document_versions.exists(_.id == doc_id) =>
                  val doc = document_versions.find(_.id == doc_id).get
                  for {
                    XML.Elem(Markup.EDIT, (Markup.ID, cmd_id) :: (Markup.STATE, state_id) :: _, _)
                      <- edits
                  } {
                    if (commands.contains(cmd_id)) {
                      val cmd = commands(cmd_id)
                      val state = new Command_State(cmd)
                      states += (state_id -> state)
                      doc.states += (cmd -> state)
                      command_change.event(cmd)
                    }
                  }
                case XML.Elem(kind, attr, body) =>
                  // TODO: This is mostly irrelevant information on removed commands, but it can
                  // also be outer-syntax-markup since there is no id in props (fix that?)
                  val (begin, end) = Position.offsets_of(attr)
                  val markup_id = Position.id_of(attr)
                  val outer = isabelle.jedit.DynamicTokenMarker.is_outer(kind)
                  if (outer && begin.isDefined && end.isDefined && markup_id.isDefined)
                    commands.get(markup_id.get).map(cmd => cmd ! (this, message))
                case _ =>
                //}}}
              }
            }
          case _ =>
        }
        //}}}
      case _ =>
    }
  }


  /* document changes */

  def handle_change(change: Change) {
    val old = document(change.parent.get.id).get
    val (doc, structure_change) = old.text_changed(change)
    document_versions ::= doc
    edit_document(old, doc, structure_change)
    document_change.event(doc)
  }

  def set_document(path: String) {
    process.begin_document(document_0.id, path)
  }

  private def edit_document(old: ProofDocument, doc: ProofDocument,
    changes: ProofDocument.StructureChange) =
  {
    val id_changes = changes map { case (c1, c2) =>
      (c1.map(_.id).getOrElse(document_0.id),
      c2 match {
        case None => None
        case Some(cmd) =>
          commands += (cmd.id -> cmd)
          process.define_command(cmd.id, isabelle_system.symbols.encode(cmd.content))
          Some(cmd.id)
      })
    }
    process.edit_document(old.id, doc.id, id_changes)
  }
}
