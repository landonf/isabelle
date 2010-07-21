/*  Title:      Pure/System/session.scala
    Author:     Makarius

Isabelle session, potentially with running prover.
*/

package isabelle


import scala.actors.TIMEOUT
import scala.actors.Actor._


object Session
{
  /* events */

  case object Global_Settings
  case object Perspective


  /* managed entities */

  type Entity_ID = String

  trait Entity
  {
    val id: Entity_ID
    def consume(message: XML.Tree, forward: Command => Unit): Unit
  }
}


class Session(system: Isabelle_System)
{
  /* real time parameters */  // FIXME properties or settings (!?)

  // user input (e.g. text edits, cursor movement)
  val input_delay = 300

  // prover output (markup, common messages)
  val output_delay = 100

  // GUI layout updates
  val update_delay = 500


  /* pervasive event buses */

  val global_settings = new Event_Bus[Session.Global_Settings.type]
  val raw_results = new Event_Bus[Isabelle_Process.Result]
  val raw_output = new Event_Bus[Isabelle_Process.Result]
  val commands_changed = new Event_Bus[Command_Set]
  val perspective = new Event_Bus[Session.Perspective.type]


  /* unique ids */

  private var id_count: BigInt = 0
  def create_id(): Session.Entity_ID = synchronized { id_count += 1; "j" + id_count }



  /** main actor **/

  @volatile private var syntax = new Outer_Syntax(system.symbols)
  def current_syntax: Outer_Syntax = syntax

  @volatile private var entities = Map[Session.Entity_ID, Session.Entity]()
  def lookup_entity(id: Session.Entity_ID): Option[Session.Entity] = entities.get(id)
  def lookup_command(id: Session.Entity_ID): Option[Command] =
    lookup_entity(id) match {
      case Some(cmd: Command) => Some(cmd)
      case _ => None
    }

  private case class Start(timeout: Int, args: List[String])
  private case object Stop
  private case class Begin_Document(path: String)

  private lazy val session_actor = actor {

    var prover: Isabelle_Process with Isar_Document = null

    def register(entity: Session.Entity) { entities += (entity.id -> entity) }

    var documents = Map[Isar_Document.Document_ID, Document]()
    def register_document(doc: Document) { documents += (doc.id -> doc) }


    /* document changes */

    def handle_change(change: Change)
    {
      require(change.parent.isDefined)

      val (changes, doc) = change.result.join
      val id_changes = changes map {
        case (c1, c2) =>
          (c1.map(_.id).getOrElse(""),
           c2 match {
              case None => None
              case Some(command) =>
                if (!lookup_command(command.id).isDefined) {
                  register(command)
                  prover.define_command(command.id, system.symbols.encode(command.source))
                }
                Some(command.id)
            })
      }
      register_document(doc)
      prover.edit_document(change.parent.get.id, doc.id, id_changes)
    }


    /* prover results */

    def bad_result(result: Isabelle_Process.Result)
    {
      System.err.println("Ignoring prover result: " + result.message.toString)
    }

    def handle_result(result: Isabelle_Process.Result)
    {
      raw_results.event(result)

      val target_id: Option[Session.Entity_ID] = Position.get_id(result.message.attributes)
      val target: Option[Session.Entity] =
        target_id match {
          case None => None
          case Some(id) => lookup_entity(id)
        }
      if (target.isDefined) target.get.consume(result.message, indicate_command_change)
      else if (result.is_status) {
        // global status message
        result.body match {

          // document state assignment
          case List(Isar_Document.Assign(edits)) if target_id.isDefined =>
            documents.get(target_id.get) match {
              case Some(doc) =>
                val states =
                  for {
                    Isar_Document.Edit(cmd_id, state_id) <- edits
                    cmd <- lookup_command(cmd_id)
                  } yield {
                    val st = cmd.assign_state(state_id)
                    register(st)
                    (cmd, st)
                  }
                doc.assign_states(states)
              case None => bad_result(result)
            }

          // keyword declarations
          case List(Keyword.Command_Decl(name, kind)) => syntax += (name, kind)
          case List(Keyword.Keyword_Decl(name)) => syntax += name

          case _ => if (!result.is_ready) bad_result(result)
        }
      }
      else if (result.kind == Markup.EXIT)
        prover = null
      else if (result.is_raw)
        raw_output.event(result)
      else if (!result.is_system)   // FIXME syslog (!?)
        bad_result(result)
    }


    /* prover startup */

    def startup_error(): String =
    {
      val buf = new StringBuilder
      while (
        receiveWithin(0) {
          case result: Isabelle_Process.Result =>
            if (result.is_raw) {
              for (text <- XML.content(result.message))
                buf.append(text)
            }
            true
          case TIMEOUT => false
        }) {}
      buf.toString
    }

    def prover_startup(timeout: Int): Option[String] =
    {
      receiveWithin(timeout) {
        case result: Isabelle_Process.Result
          if result.kind == Markup.INIT =>
          while (receive {
            case result: Isabelle_Process.Result =>
              handle_result(result); !result.is_ready
            }) {}
          None

        case result: Isabelle_Process.Result
          if result.kind == Markup.EXIT =>
          Some(startup_error())

        case TIMEOUT =>  // FIXME clarify
          prover.kill; Some(startup_error())
      }
    }


    /* main loop */

    val xml_cache = new XML.Cache(131071)

    loop {
      react {
        case Start(timeout, args) =>
          if (prover == null) {
            prover = new Isabelle_Process(system, self, args:_*) with Isar_Document
            val origin = sender
            val opt_err = prover_startup(timeout)
            if (opt_err.isDefined) prover = null
            origin ! opt_err
          }
          else reply(None)

        case Stop =>  // FIXME clarify; synchronous
          if (prover != null) {
            prover.kill
            prover = null
          }

        case Begin_Document(path: String) if prover != null =>
          val id = create_id()
          val doc = Document.empty(id)
          register_document(doc)
          prover.begin_document(id, path)
          reply(doc)

        case change: Change if prover != null =>
          handle_change(change)

        case result: Isabelle_Process.Result =>
          handle_result(result.cache(xml_cache))

        case TIMEOUT =>  // FIXME clarify!

        case bad if prover != null =>
          System.err.println("session_actor: ignoring bad message " + bad)
      }
    }
  }



  /** buffered command changes -- delay_first discipline **/

  private lazy val command_change_buffer = actor {
    import scala.compat.Platform.currentTime

    var changed: Set[Command] = Set()
    var flush_time: Option[Long] = None

    def flush_timeout: Long =
      flush_time match {
        case None => 5000L
        case Some(time) => (time - currentTime) max 0
      }

    def flush()
    {
      if (!changed.isEmpty) commands_changed.event(Command_Set(changed))
      changed = Set()
      flush_time = None
    }

    def invoke()
    {
      val now = currentTime
      flush_time match {
        case None => flush_time = Some(now + output_delay)
        case Some(time) => if (now >= time) flush()
      }
    }

    loop {
      reactWithin(flush_timeout) {
        case command: Command => changed += command; invoke()
        case TIMEOUT => flush()
        case bad => System.err.println("command_change_buffer: ignoring bad message " + bad)
      }
    }
  }

  def indicate_command_change(command: Command)
  {
    command_change_buffer ! command
  }


  /* main methods */

  def start(timeout: Int, args: List[String]): Option[String] =
    (session_actor !? Start(timeout, args)).asInstanceOf[Option[String]]

  def stop() { session_actor ! Stop }
  def input(change: Change) { session_actor ! change }

  def begin_document(path: String): Document =
    (session_actor !? Begin_Document(path)).asInstanceOf[Document]
}
