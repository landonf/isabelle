/*  Title:      Pure/System/isabelle_process.ML
    Author:     Makarius
    Options:    :folding=explicit:collapseFolds=1:

Isabelle process management -- always reactive due to multi-threaded I/O.
*/

package isabelle

import java.util.concurrent.LinkedBlockingQueue
import java.io.{BufferedReader, BufferedWriter, InputStreamReader, OutputStreamWriter,
  InputStream, OutputStream, BufferedOutputStream, IOException}

import scala.actors.Actor
import Actor._
import scala.collection.mutable


object Isabelle_Process
{
  /* results */

  object Kind
  {
    val message_markup = Map(
      ('A' : Int) -> Markup.INIT,
      ('B' : Int) -> Markup.STATUS,
      ('C' : Int) -> Markup.REPORT,
      ('D' : Int) -> Markup.WRITELN,
      ('E' : Int) -> Markup.TRACING,
      ('F' : Int) -> Markup.WARNING,
      ('G' : Int) -> Markup.ERROR)
  }

  class Result(val message: XML.Elem)
  {
    def kind = message.markup.name
    def properties = message.markup.properties
    def body = message.body

    def is_init = kind == Markup.INIT
    def is_exit = kind == Markup.EXIT
    def is_stdout = kind == Markup.STDOUT
    def is_system = kind == Markup.SYSTEM
    def is_status = kind == Markup.STATUS
    def is_report = kind == Markup.REPORT
    def is_ready = is_status && body == List(XML.Elem(Markup.Ready, Nil))

    override def toString: String =
    {
      val res =
        if (is_status || is_report) message.body.map(_.toString).mkString
        else Pretty.string_of(message.body)
      if (properties.isEmpty)
        kind.toString + " [[" + res + "]]"
      else
        kind.toString + " " +
          (for ((x, y) <- properties) yield x + "=" + y).mkString("{", ",", "}") + " [[" + res + "]]"
    }
  }
}


class Isabelle_Process(system: Isabelle_System, timeout: Int, receiver: Actor, args: String*)
{
  import Isabelle_Process._


  /* demo constructor */

  def this(args: String*) =
    this(new Isabelle_System, 10000,
      actor { loop { react { case res => Console.println(res) } } }, args: _*)


  /* input actors */

  private case class Input_Text(text: String)
  private case class Input_Chunks(chunks: List[Array[Byte]])

  private case object Close
  private def close(a: Actor) { if (a != null) a ! Close }

  @volatile private var standard_input: Actor = null
  @volatile private var command_input: Actor = null


  /* process manager */

  private val in_fifo = system.mk_fifo()
  private val out_fifo = system.mk_fifo()
  private def rm_fifos() { system.rm_fifo(in_fifo); system.rm_fifo(out_fifo) }

  private val proc =
    try {
      val cmdline =
        List(system.getenv_strict("ISABELLE_PROCESS"), "-W", in_fifo + ":" + out_fifo) ++ args
      system.execute(true, cmdline: _*)
    }
    catch { case e: IOException => rm_fifos(); throw(e) }

  private val stdout_reader =
    new BufferedReader(new InputStreamReader(proc.getInputStream, Standard_System.charset))

  private val stdin_writer =
    new BufferedWriter(new OutputStreamWriter(proc.getOutputStream, Standard_System.charset))

  private val (process_manager, _) = Simple_Thread.actor("process_manager")
  {
    val (startup_failed, startup_output) =
    {
      val expired = System.currentTimeMillis() + timeout
      val result = new StringBuilder(100)

      var finished = false
      while (!finished && System.currentTimeMillis() <= expired) {
        while (!finished && stdout_reader.ready) {
          val c = stdout_reader.read
          if (c == 2) finished = true
          else result += c.toChar
        }
        Thread.sleep(10)
      }
      (!finished, result.toString)
    }
    system_result(startup_output)

    if (startup_failed) {
      put_result(Markup.EXIT, "127")
      stdin_writer.close
      Thread.sleep(300)  // FIXME !?
      proc.destroy  // FIXME unreliable
    }
    else {
      // rendezvous
      val command_stream = system.fifo_output_stream(in_fifo)
      val message_stream = system.fifo_input_stream(out_fifo)

      val stdin = stdin_actor(); standard_input = stdin._2
      val stdout = stdout_actor()
      val input = input_actor(command_stream); command_input = input._2
      val message = message_actor(message_stream)

      val rc = proc.waitFor()
      system_result("Isabelle process terminated")
      for ((thread, _) <- List(stdin, stdout, input, message)) thread.join
      system_result("process_manager terminated")
      put_result(Markup.EXIT, rc.toString)
    }
    rm_fifos()
  }

  def join() { process_manager.join() }


  /* system log */

  private val system_results = new mutable.ListBuffer[String]

  private def system_result(text: String)
  {
    synchronized { system_results += text }
    receiver ! new Result(XML.Elem(Markup(Markup.SYSTEM, Nil), List(XML.Text(text))))
  }

  def syslog(): List[String] = synchronized { system_results.toList }


  /* results */

  private val xml_cache = new XML.Cache(131071)

  private def put_result(kind: String, props: List[(String, String)], body: XML.Body)
  {
    if (pid.isEmpty && kind == Markup.INIT) {
      rm_fifos()
      props.find(_._1 == Markup.PID).map(_._1) match {
        case None => system_result("Bad Isabelle process initialization: missing pid")
        case p => pid = p
      }
    }

    val msg = XML.Elem(Markup(kind, props), Isar_Document.clean_message(body))
    xml_cache.cache_tree(msg)((message: XML.Tree) =>
      receiver ! new Result(message.asInstanceOf[XML.Elem]))
  }

  private def put_result(kind: String, text: String)
  {
    put_result(kind, Nil, List(XML.Text(system.symbols.decode(text))))
  }


  /* signals */

  @volatile private var pid: Option[String] = None

  def interrupt()
  {
    pid match {
      case None => system_result("Cannot interrupt Isabelle: unknowd pid")
      case Some(i) =>
        try {
          if (system.execute(true, "kill", "-INT", i).waitFor == 0)
            system_result("Interrupt Isabelle")
          else
            system_result("Cannot interrupt Isabelle: kill command failed")
        }
        catch { case e: IOException => error("Cannot interrupt Isabelle: " + e.getMessage) }
    }
  }

  def kill()
  {
    val running =
      try { proc.exitValue; false }
      catch { case e: java.lang.IllegalThreadStateException => true }
    if (running) {
      close()
      Thread.sleep(500)  // FIXME !?
      system_result("Kill Isabelle")
      proc.destroy
    }
  }



  /** stream actors **/

  /* raw stdin */

  private def stdin_actor(): (Thread, Actor) =
  {
    val name = "standard_input"
    Simple_Thread.actor(name) {
      var finished = false
      while (!finished) {
        try {
          //{{{
          receive {
            case Input_Text(text) =>
              stdin_writer.write(text)
              stdin_writer.flush
            case Close =>
              stdin_writer.close
              finished = true
            case bad => System.err.println(name + ": ignoring bad message " + bad)
          }
          //}}}
        }
        catch { case e: IOException => system_result(name + ": " + e.getMessage) }
      }
      system_result(name + " terminated")
    }
  }


  /* raw stdout */

  private def stdout_actor(): (Thread, Actor) =
  {
    val name = "standard_output"
    Simple_Thread.actor(name) {
      var result = new StringBuilder(100)

      var finished = false
      while (!finished) {
        try {
          //{{{
          var c = -1
          var done = false
          while (!done && (result.length == 0 || stdout_reader.ready)) {
            c = stdout_reader.read
            if (c >= 0) result.append(c.asInstanceOf[Char])
            else done = true
          }
          if (result.length > 0) {
            put_result(Markup.STDOUT, result.toString)
            result.length = 0
          }
          else {
            stdout_reader.close
            finished = true
          }
          //}}}
        }
        catch { case e: IOException => system_result(name + ": " + e.getMessage) }
      }
      system_result(name + " terminated")
    }
  }


  /* command input */

  private def input_actor(raw_stream: OutputStream): (Thread, Actor) =
  {
    val name = "command_input"
    Simple_Thread.actor(name) {
      val stream = new BufferedOutputStream(raw_stream)
      var finished = false
      while (!finished) {
        try {
          //{{{
          receive {
            case Input_Chunks(chunks) =>
              stream.write(Standard_System.string_bytes(
                  chunks.map(_.length).mkString("", ",", "\n")));
              chunks.foreach(stream.write(_));
              stream.flush
            case Close =>
              stream.close
              finished = true
            case bad => System.err.println(name + ": ignoring bad message " + bad)
          }
          //}}}
        }
        catch { case e: IOException => system_result(name + ": " + e.getMessage) }
      }
      system_result(name + " terminated")
    }
  }


  /* message output */

  private def message_actor(stream: InputStream): (Thread, Actor) =
  {
    class EOF extends Exception
    class Protocol_Error(msg: String) extends Exception(msg)

    val name = "message_output"
    Simple_Thread.actor(name) {
      val default_buffer = new Array[Byte](65536)
      var c = -1

      def read_chunk(): XML.Body =
      {
        //{{{
        // chunk size
        var n = 0
        c = stream.read
        if (c == -1) throw new EOF
        while (48 <= c && c <= 57) {
          n = 10 * n + (c - 48)
          c = stream.read
        }
        if (c != 10) throw new Protocol_Error("bad message chunk header")

        // chunk content
        val buf =
          if (n <= default_buffer.size) default_buffer
          else new Array[Byte](n)

        var i = 0
        var m = 0
        do {
          m = stream.read(buf, i, n - i)
          i += m
        } while (m > 0 && n > i)

        if (i != n) throw new Protocol_Error("bad message chunk content")

        YXML.parse_body_failsafe(YXML.decode_chars(system.symbols.decode, buf, 0, n))
        //}}}
      }

      do {
        try {
          val header = read_chunk()
          val body = read_chunk()
          header match {
            case List(XML.Elem(Markup(name, props), Nil))
                if name.size == 1 && Kind.message_markup.isDefinedAt(name(0)) =>
              put_result(Kind.message_markup(name(0)), props, body)
            case _ => throw new Protocol_Error("bad header: " + header.toString)
          }
        }
        catch {
          case e: IOException => system_result("Cannot read message:\n" + e.getMessage)
          case e: Protocol_Error => system_result("Malformed message:\n" + e.getMessage)
          case _: EOF =>
        }
      } while (c != -1)
      stream.close

      system_result(name + " terminated")
    }
  }


  /** main methods **/

  def input_raw(text: String): Unit = standard_input ! Input_Text(text)

  def input_bytes(name: String, args: Array[Byte]*): Unit =
    command_input ! Input_Chunks(Standard_System.string_bytes(name) :: args.toList)

  def input(name: String, args: String*): Unit =
    input_bytes(name, args.map(Standard_System.string_bytes): _*)

  def close(): Unit = { close(command_input); close(standard_input) }
}
