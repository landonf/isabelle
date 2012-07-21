/*  Title:      Pure/System/build.scala
    Author:     Makarius

Build and manage Isabelle sessions.
*/

package isabelle


import java.io.{File => JFile}

import scala.collection.mutable
import scala.annotation.tailrec


object Build
{
  /** session information **/

  object Session
  {
    /* Key */

    object Key
    {
      object Ordering extends scala.math.Ordering[Key]
      {
        def compare(key1: Key, key2: Key): Int =
          key1.order compare key2.order match {
            case 0 => key1.name compare key2.name
            case ord => ord
          }
      }
    }

    sealed case class Key(name: String, order: Int)
    {
      override def toString: String = name
    }


    /* Info */

    sealed abstract class Status
    case object Pending extends Status
    case object Running extends Status

    sealed case class Info(
      dir: Path,
      parent: Option[String],
      description: String,
      options: Options,
      theories: List[(Options, List[Path])],
      files: List[Path],
      status: Status = Pending)


    /* Queue */

    object Queue
    {
      val empty: Queue = new Queue()
    }

    final class Queue private(
      keys: Map[String, Key] = Map.empty,
      graph: Graph[Key, Info] = Graph.empty(Key.Ordering))
    {
      def defined(name: String): Boolean = keys.isDefinedAt(name)

      def is_inner(name: String): Boolean = !graph.is_maximal(keys(name))

      def + (key: Key, info: Info): Queue =
      {
        val keys1 =
          if (defined(key.name)) error("Duplicate session: " + quote(key.name))
          else keys + (key.name -> key)

        val graph1 =
          try {
            graph.new_node(key, info).add_deps_acyclic(key, info.parent.toList.map(keys(_)))
          }
          catch {
            case exn: Graph.Cycles[_] =>
              error(cat_lines(exn.cycles.map(cycle =>
                "Cyclic session dependency of " +
                  cycle.map(key => quote(key.toString)).mkString(" via "))))
          }
        new Queue(keys1, graph1)
      }

      def required(names: List[String]): Queue =
      {
        val req = graph.all_preds(names.map(keys(_))).map(_.name).toSet
        val keys1 = keys -- keys.keySet.filter(name => !req(name))
        val graph1 = graph.restrict(key => keys1.isDefinedAt(key.name))
        new Queue(keys1, graph1)
      }

      def topological_order: List[(String, Info)] =
        graph.topological_order.map(key => (key.name, graph.get_node(key)))
    }
  }


  /* parsing */

  private case class Session_Entry(
    name: String,
    reset: Boolean,
    order: Int,
    path: Option[String],
    parent: Option[String],
    description: String,
    options: List[Options.Spec],
    theories: List[(List[Options.Spec], List[String])],
    files: List[String])

  private object Parser extends Parse.Parser
  {
    val SESSION = "session"
    val IN = "in"
    val DESCRIPTION = "description"
    val OPTIONS = "options"
    val THEORIES = "theories"
    val FILES = "files"

    val syntax =
      Outer_Syntax.empty + "!" + "(" + ")" + "+" + "," + "=" + "[" + "]" +
        SESSION + IN + DESCRIPTION + OPTIONS + THEORIES + FILES

    val session_entry: Parser[Session_Entry] =
    {
      val session_name = atom("session name", _.is_name)
      val theory_name = atom("theory name", _.is_name)

      val option =
        name ~ opt(keyword("=") ~! name ^^ { case _ ~ x => x }) ^^ { case x ~ y => (x, y) }
      val options = keyword("[") ~> repsep(option, keyword(",")) <~ keyword("]")

      val theories =
        keyword(THEORIES) ~! ((options | success(Nil)) ~ rep1(theory_name)) ^^
          { case _ ~ (x ~ y) => (x, y) }

      ((keyword(SESSION) ~! session_name) ^^ { case _ ~ x => x }) ~
        (keyword("!") ^^^ true | success(false)) ~
        (keyword("(") ~! (nat <~ keyword(")")) ^^ { case _ ~ x => x } | success(Integer.MAX_VALUE)) ~
        (opt(keyword(IN) ~! string ^^ { case _ ~ x => x })) ~
        (keyword("=") ~> opt(session_name <~ keyword("+"))) ~
        (keyword(DESCRIPTION) ~! text ^^ { case _ ~ x => x } | success("")) ~
        (keyword(OPTIONS) ~! options ^^ { case _ ~ x => x } | success(Nil)) ~
        rep(theories) ~
        (keyword(FILES) ~! rep1(path) ^^ { case _ ~ x => x } | success(Nil)) ^^
          { case a ~ b ~ c ~ d ~ e ~ f ~ g ~ h ~ i => Session_Entry(a, b, c, d, e, f, g, h, i) }
    }

    def parse_entries(root: JFile): List[Session_Entry] =
    {
      val toks = syntax.scan(File.read(root))
      parse_all(rep(session_entry), Token.reader(toks, root.toString)) match {
        case Success(result, _) => result
        case bad => error(bad.toString)
      }
    }
  }


  /* find sessions */

  private val ROOT = Path.explode("ROOT")
  private val SESSIONS = Path.explode("etc/sessions")

  private def is_pure(name: String): Boolean = name == "RAW" || name == "Pure"

  private def sessions_root(options: Options, dir: Path, root: JFile, queue: Session.Queue)
    : Session.Queue =
  {
    (queue /: Parser.parse_entries(root))((queue1, entry) =>
      try {
        if (entry.name == "") error("Bad session name")

        val full_name =
          if (is_pure(entry.name)) {
            if (entry.parent.isDefined) error("Illegal parent session")
            else entry.name
          }
          else
            entry.parent match {
              case Some(parent_name) if queue1.defined(parent_name) =>
                if (entry.reset) entry.name
                else parent_name + "-" + entry.name
              case _ => error("Bad parent session")
            }

        val path =
          entry.path match {
            case Some(p) => Path.explode(p)
            case None => Path.basic(entry.name)
          }

        val key = Session.Key(full_name, entry.order)

        val theories =
          entry.theories.map({ case (opts, thys) => (options ++ opts, thys.map(Path.explode(_))) })
        val files = entry.files.map(Path.explode(_))
        val info =
          Session.Info(dir + path, entry.parent,
            entry.description, options ++ entry.options, theories, files)

        queue1 + (key, info)
      }
      catch {
        case ERROR(msg) =>
          error(msg + "\nThe error(s) above occurred in session entry " +
            quote(entry.name) + Position.str_of(Position.file(root)))
      })
  }

  private def sessions_dir(options: Options, strict: Boolean, dir: Path, queue: Session.Queue)
    : Session.Queue =
  {
    val root = (dir + ROOT).file
    if (root.isFile) sessions_root(options, dir, root, queue)
    else if (strict) error("Bad session root file: " + quote(root.toString))
    else queue
  }

  private def sessions_catalog(options: Options, dir: Path, catalog: JFile, queue: Session.Queue)
    : Session.Queue =
  {
    val dirs =
      split_lines(File.read(catalog)).filterNot(line => line == "" || line.startsWith("#"))
    (queue /: dirs)((queue1, dir1) =>
      try {
        val dir2 = dir + Path.explode(dir1)
        if (dir2.file.isDirectory) sessions_dir(options, true, dir2, queue1)
        else error("Bad session directory: " + dir2.toString)
      }
      catch {
        case ERROR(msg) =>
          error(msg + "\nThe error(s) above occurred in session catalog " + quote(catalog.toString))
      })
  }

  def find_sessions(options: Options, all_sessions: Boolean, sessions: List[String],
    more_dirs: List[Path]): Session.Queue =
  {
    var queue = Session.Queue.empty

    for (dir <- Isabelle_System.components()) {
      queue = sessions_dir(options, false, dir, queue)

      val catalog = (dir + SESSIONS).file
      if (catalog.isFile)
        queue = sessions_catalog(options, dir, catalog, queue)
    }

    for (dir <- more_dirs) queue = sessions_dir(options, true, dir, queue)

    sessions.filter(name => !queue.defined(name)) match {
      case Nil =>
      case bad => error("Undefined session(s): " + commas_quote(bad))
    }

    if (all_sessions) queue else queue.required(sessions)
  }


  /* dependencies */

  sealed case class Node(
    loaded_theories: Set[String],
    sources: List[Path])

  def dependencies(queue: Session.Queue): Map[String, Node] =
    (Map.empty[String, Node] /: queue.topological_order)(
      { case (deps, (name, info)) =>
          val preloaded =
            info.parent match {
              case None => Set.empty[String]
              case Some(parent) => deps(parent).loaded_theories
            }
          val thy_info = new Thy_Info(new Thy_Load(preloaded))

          val thy_deps =
            thy_info.dependencies(
              info.theories.map(_._2).flatten.
                map(thy => Document.Node.Name(info.dir + Thy_Load.thy_path(thy))))

          val loaded_theories = preloaded ++ thy_deps.map(_._1.theory)
          val sources =
            thy_deps.map({ case (n, h) =>
              val thy = Path.explode(n.node).expand
              val uses =
                h match {
                  case Exn.Res(d) =>
                    d.uses.map(p => (Path.explode(n.dir) + Path.explode(p._1)).expand)
                  case _ => Nil
                }
              thy :: uses
            }).flatten ::: info.files.map(file => info.dir + file)

          deps + (name -> Node(loaded_theories, sources))
      })



  /** build **/

  private def echo(msg: String) { java.lang.System.out.println(msg) }
  private def echo_n(msg: String) { java.lang.System.out.print(msg) }

  class Build_Job(cwd: JFile, env: Map[String, String], script: String, args: String)
  {
    private val args_file = File.tmp_file("args")
    private val env1 = env + ("ARGS_FILE" -> Isabelle_System.posix_path(args_file.getPath))
    File.write(args_file, args)

    private val (thread, result) = Simple_Thread.future("build_job") {
      Isabelle_System.bash_env(cwd, env1, script)
    }

    def terminate: Unit = thread.interrupt
    def is_finished: Boolean = result.is_finished
    def join: (String, String, Int) = { val rc = result.join; args_file.delete; rc }
  }

  private def build_job(save: Boolean, name: String, info: Session.Info): Build_Job =
  {
    val parent = info.parent.getOrElse("")

    val cwd = info.dir.file
    val env = Map("INPUT" -> parent, "TARGET" -> name)
    val script =
      if (is_pure(name)) "./build " + (if (save) "-b " else "") + name
      else {
        """
        . "$ISABELLE_HOME/lib/scripts/timestart.bash"
        """ +
          (if (save)
            """ "$ISABELLE_PROCESS" -e "Build.build \"$ARGS_FILE\";" -q -w "$INPUT" "$TARGET" """
          else
            """ "$ISABELLE_PROCESS" -e "Build.build \"$ARGS_FILE\";" -r -q "$INPUT" """) +
        """
        RC="$?"

        . "$ISABELLE_HOME/lib/scripts/timestop.bash"

        if [ "$RC" -eq 0 ]; then
          echo "Finished $TARGET ($TIMES_REPORT)" >&2
        fi

        exit "$RC"
        """
      }
    val args_xml =
    {
      import XML.Encode._
      pair(bool, pair(string, pair(string, list(string))))(
        save, (parent, (name, info.theories.map(_._2).flatten.map(_.implode))))
    }
    new Build_Job(cwd, env, script, YXML.string_of_body(args_xml))
  }

  def build(all_sessions: Boolean, build_images: Boolean, list_only: Boolean,
    more_dirs: List[Path], more_options: List[String], sessions: List[String]): Int =
  {
    val options = (Options.init() /: more_options)(_.define_simple(_))
    val queue = find_sessions(options, all_sessions, sessions, more_dirs)


    // prepare browser info dir
    if (options.bool("browser_info") &&
      !Path.explode("$ISABELLE_BROWSER_INFO/index.html").file.isFile)
    {
      Path.explode("$ISABELLE_BROWSER_INFO").file.mkdirs()
      File.copy(Path.explode("$ISABELLE_HOME/lib/logo/isabelle.gif"),
        Path.explode("$ISABELLE_BROWSER_INFO/isabelle.gif"))
      File.write(Path.explode("$ISABELLE_BROWSER_INFO/index.html"),
        File.read(Path.explode("$ISABELLE_HOME/lib/html/library_index_header.template")) +
        File.read(Path.explode("$ISABELLE_HOME/lib/html/library_index_content.template")) +
        File.read(Path.explode("$ISABELLE_HOME/lib/html/library_index_footer.template")))
    }

    // prepare log dir
    val log_dir = Path.explode("$ISABELLE_OUTPUT/log")
    log_dir.file.mkdirs()

    // run jobs
    val rcs =
      for ((name, info) <- queue.topological_order) yield
      {
        if (list_only) { echo(name + " in " + info.dir); 0 }
        else {
          val save = build_images || queue.is_inner(name)
          echo((if (save) "Building " else "Running ") + name + " ...")

          val (out, err, rc) = build_job(save, name, info).join
          echo_n(err)

          val log = log_dir + Path.basic(name)
          if (rc == 0) {
            File.write_zip(log.ext("gz"), out)
          }
          else {
            File.write(log, out)
            echo(name + " FAILED")
            echo("(see also " + log.file + ")")
            val lines = split_lines(out)
            val tail = lines.drop(lines.length - 20 max 0)
            echo("\n" + cat_lines(tail))
          }
          rc
        }
      }
    (0 /: rcs)(_ max _)
  }


  /* command line entry point */

  def main(args: Array[String])
  {
    Command_Line.tool {
      args.toList match {
        case
          Properties.Value.Boolean(all_sessions) ::
          Properties.Value.Boolean(build_images) ::
          Properties.Value.Boolean(list_only) ::
          Command_Line.Chunks(more_dirs, options, sessions) =>
            build(all_sessions, build_images, list_only,
              more_dirs.map(Path.explode), options, sessions)
        case _ => error("Bad arguments:\n" + cat_lines(args))
      }
    }
  }
}

