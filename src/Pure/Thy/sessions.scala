/*  Title:      Pure/Thy/sessions.scala
    Author:     Makarius

Cumulative session information.
*/

package isabelle

import java.io.{File => JFile}
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.StandardOpenOption

import scala.collection.SortedSet
import scala.collection.mutable


object Sessions
{
  /* base info and source dependencies */

  val DRAFT = "Draft"

  def is_pure(name: String): Boolean = name == Thy_Header.PURE

  object Known
  {
    val empty: Known = Known()

    def make(local_dir: Path, bases: List[Base], theories: List[Document.Node.Name]): Known =
    {
      def bases_iterator(local: Boolean) =
        for {
          base <- bases.iterator
          (_, name) <- (if (local) base.known.theories_local else base.known.theories).iterator
        } yield name

      def local_theories_iterator =
      {
        val local_path = local_dir.canonical_file.toPath
        theories.iterator.filter(name =>
          Path.explode(name.node).canonical_file.toPath.startsWith(local_path))
      }

      val known_theories =
        (Map.empty[String, Document.Node.Name] /: (bases_iterator(false) ++ theories.iterator))({
          case (known, name) =>
            known.get(name.theory) match {
              case Some(name1) if name != name1 =>
                error("Duplicate theory " + quote(name.node) + " vs. " + quote(name1.node))
              case _ => known + (name.theory -> name)
            }
          })
      val known_theories_local =
        (Map.empty[String, Document.Node.Name] /:
            (bases_iterator(true) ++ local_theories_iterator))({
          case (known, name) => known + (name.theory -> name)
        })
      val known_files =
        (Map.empty[JFile, List[Document.Node.Name]] /:
            (bases_iterator(true) ++ bases_iterator(false) ++ theories.iterator))({
          case (known, name) =>
            val file = Path.explode(name.node).canonical_file
            val theories1 = known.getOrElse(file, Nil)
            if (theories1.exists(name1 => name.node == name1.node && name.theory == name1.theory))
              known
            else known + (file -> (name :: theories1))
        })
      Known(known_theories, known_theories_local,
        known_files.iterator.map(p => (p._1, p._2.reverse)).toMap)
    }
  }

  sealed case class Known(
    theories: Map[String, Document.Node.Name] = Map.empty,
    theories_local: Map[String, Document.Node.Name] = Map.empty,
    files: Map[JFile, List[Document.Node.Name]] = Map.empty)
  {
    def platform_path: Known =
      copy(theories = for ((a, b) <- theories) yield (a, b.map(File.platform_path(_))),
        theories_local = for ((a, b) <- theories_local) yield (a, b.map(File.platform_path(_))),
        files = for ((a, b) <- files) yield (a, b.map(c => c.map(File.platform_path(_)))))

    def standard_path: Known =
      copy(theories = for ((a, b) <- theories) yield (a, b.map(File.standard_path(_))),
        theories_local = for ((a, b) <- theories_local) yield (a, b.map(File.standard_path(_))),
        files = for ((a, b) <- files) yield (a, b.map(c => c.map(File.standard_path(_)))))

    def get_file(file: JFile, bootstrap: Boolean = false): Option[Document.Node.Name] =
    {
      val res = files.getOrElse(File.canonical(file), Nil).headOption
      if (bootstrap) res.map(_.map_theory(Thy_Header.bootstrap_name(_))) else res
    }
  }

  object Base
  {
    def pure(options: Options): Base = session_base(options, Thy_Header.PURE)

    def bootstrap(global_theories: Map[String, String]): Base =
      Base(
        global_theories = global_theories,
        keywords = Thy_Header.bootstrap_header,
        syntax = Thy_Header.bootstrap_syntax)
  }

  sealed case class Base(
    pos: Position.T = Position.none,
    imports: Option[Base] = None,
    global_theories: Map[String, String] = Map.empty,
    loaded_theories: Map[String, String] = Map.empty,
    known: Known = Known.empty,
    keywords: Thy_Header.Keywords = Nil,
    syntax: Outer_Syntax = Outer_Syntax.empty,
    sources: List[(Path, SHA1.Digest)] = Nil,
    session_graph: Graph_Display.Graph = Graph_Display.empty_graph,
    errors: List[String] = Nil)
  {
    def get_imports: Base = imports getOrElse Base.bootstrap(global_theories)

    def platform_path: Base = copy(known = known.platform_path)
    def standard_path: Base = copy(known = known.standard_path)

    def loaded_theory(name: Document.Node.Name): Boolean =
      loaded_theories.isDefinedAt(name.theory)

    def known_theory(name: String): Option[Document.Node.Name] =
      known.theories.get(name)

    def dest_known_theories: List[(String, String)] =
      for ((theory, node_name) <- known.theories.toList)
        yield (theory, node_name.node)
  }

  sealed case class Deps(session_bases: Map[String, Base], all_known: Known)
  {
    def is_empty: Boolean = session_bases.isEmpty
    def apply(name: String): Base = session_bases(name)
    def sources(name: String): List[SHA1.Digest] = session_bases(name).sources.map(_._2)

    def errors: List[String] =
      (for {
        (name, base) <- session_bases.iterator
        if base.errors.nonEmpty
      } yield cat_lines(base.errors) +
          "\nThe error(s) above occurred in session " + quote(name) + Position.here(base.pos)
      ).toList

    def check_errors: Deps =
      errors match {
        case Nil => this
        case errs => error(cat_lines(errs))
      }
  }

  def deps(sessions: T,
      progress: Progress = No_Progress,
      inlined_files: Boolean = false,
      verbose: Boolean = false,
      list_files: Boolean = false,
      check_keywords: Set[String] = Set.empty,
      global_theories: Map[String, String] = Map.empty): Deps =
  {
    val session_bases =
      (Map.empty[String, Base] /: sessions.imports_topological_order)({
        case (session_bases, info) =>
          if (progress.stopped) throw Exn.Interrupt()

          try {
            val parent_base: Sessions.Base =
              info.parent match {
                case None => Base.bootstrap(global_theories)
                case Some(parent) => session_bases(parent)
              }
            val imports_base: Sessions.Base =
              parent_base.copy(known =
                Known.make(info.dir, parent_base :: info.imports.map(session_bases(_)), Nil))

            val resources = new Resources(imports_base)

            if (verbose || list_files) {
              val groups =
                if (info.groups.isEmpty) ""
                else info.groups.mkString(" (", " ", ")")
              progress.echo("Session " + info.chapter + "/" + info.name + groups)
            }

            val thy_deps =
            {
              val root_theories =
                info.theories.flatMap({ case (_, thys) =>
                  thys.map({ case (thy, pos) =>
                    (resources.import_name(info.theory_qualifier, info.dir.implode, thy), pos) })
                })
              resources.thy_info.dependencies(root_theories)
            }

            val syntax = thy_deps.syntax

            val theory_files = thy_deps.deps.map(dep => Path.explode(dep.name.node))
            val loaded_files =
              if (inlined_files) {
                val pure_files =
                  if (is_pure(info.name)) {
                    val roots = Thy_Header.ml_roots.map(p => info.dir + Path.explode(p._1))
                    val files =
                      roots.flatMap(root => resources.loaded_files(syntax, File.read(root))).
                        map(file => info.dir + Path.explode(file))
                    roots ::: files
                  }
                  else Nil
                pure_files ::: thy_deps.loaded_files
              }
              else Nil

            val all_files =
              (theory_files ::: loaded_files :::
                info.files.map(file => info.dir + file) :::
                info.document_files.map(file => info.dir + file._1 + file._2)).map(_.expand)

            if (list_files)
              progress.echo(cat_lines(all_files.map(_.implode).sorted.map("  " + _)))

            if (check_keywords.nonEmpty)
              Check_Keywords.check_keywords(progress, syntax.keywords, check_keywords, theory_files)

            val session_graph: Graph_Display.Graph =
            {
              def session_node(name: String): Graph_Display.Node =
                Graph_Display.Node("[" + name + "]", "session." + name)

              def node(name: Document.Node.Name): Graph_Display.Node =
              {
                val qualifier = resources.theory_qualifier(name)
                if (qualifier == info.theory_qualifier)
                  Graph_Display.Node(name.theory_base_name, "theory." + name.theory)
                else session_node(qualifier)
              }

              val imports_subgraph =
                sessions.imports_graph.restrict(
                  sessions.imports_graph.all_preds(info.parent.toList ::: info.imports).toSet)

              val graph0 =
                (Graph_Display.empty_graph /: imports_subgraph.topological_order)(
                  { case (g, session) =>
                      val a = session_node(session)
                      val bs = imports_subgraph.imm_preds(session).toList.map(session_node(_))
                      ((g /: (a :: bs))(_.default_node(_, Nil)) /: bs)(_.add_edge(_, a)) })

              (graph0 /: thy_deps.deps)(
                { case (g, dep) =>
                    val a = node(dep.name)
                    val bs =
                      dep.header.imports.map({ case (name, _) => node(name) }).
                        filterNot(_ == a)
                    ((g /: (a :: bs))(_.default_node(_, Nil)) /: bs)(_.add_edge(_, a)) })
            }

            val sources =
              for (p <- all_files if p.is_file) yield (p, SHA1.digest(p.file))
            val sources_errors =
              for (p <- all_files if !p.is_file) yield "No such file: " + p

            val base =
              Base(
                pos = info.pos,
                imports = Some(imports_base),
                global_theories = global_theories,
                loaded_theories = thy_deps.loaded_theories,
                known = Known.make(info.dir, List(imports_base), thy_deps.deps.map(_.name)),
                keywords = thy_deps.keywords,
                syntax = syntax,
                sources = sources,
                session_graph = session_graph,
                errors = thy_deps.errors ::: sources_errors)

            session_bases + (info.name -> base)
          }
          catch {
            case ERROR(msg) =>
              cat_error(msg, "The error(s) above occurred in session " +
                quote(info.name) + Position.here(info.pos))
          }
      })

    Deps(session_bases, Known.make(Path.current, session_bases.toList.map(_._2), Nil))
  }

  def session_base_errors(
    options: Options,
    session: String,
    dirs: List[Path] = Nil,
    all_known: Boolean = false): (List[String], Base) =
  {
    val full_sessions = load(options, dirs = dirs)
    val global_theories = full_sessions.global_theories
    val (_, selected_sessions) = full_sessions.selection(Selection(sessions = List(session)))

    val sessions: T = if (all_known) full_sessions else selected_sessions
    val deps = Sessions.deps(sessions, global_theories = global_theories)
    val base = if (all_known) deps(session).copy(known = deps.all_known) else deps(session)
    (deps.errors, base)
  }

  def session_base(
    options: Options,
    session: String,
    dirs: List[Path] = Nil,
    all_known: Boolean = false): Base =
  {
    val (errs, base) = session_base_errors(options, session, dirs = dirs, all_known = all_known)
    if (errs.isEmpty) base else error(cat_lines(errs))
  }


  /* cumulative session info */

  sealed case class Info(
    name: String,
    chapter: String,
    select: Boolean,
    pos: Position.T,
    groups: List[String],
    dir: Path,
    parent: Option[String],
    description: String,
    options: Options,
    imports: List[String],
    theories: List[(Options, List[(String, Position.T)])],
    global_theories: List[String],
    files: List[Path],
    document_files: List[(Path, Path)],
    meta_digest: SHA1.Digest)
  {
    def timeout: Time = Time.seconds(options.real("timeout") * options.real("timeout_scale"))

    def theory_qualifier: String =
      options.string("theory_qualifier") match {
        case "" => name
        case qualifier => qualifier
      }
  }

  object Selection
  {
    val empty: Selection = Selection()
    val all: Selection = Selection(all_sessions = true)
  }

  sealed case class Selection(
    requirements: Boolean = false,
    all_sessions: Boolean = false,
    exclude_session_groups: List[String] = Nil,
    exclude_sessions: List[String] = Nil,
    session_groups: List[String] = Nil,
    sessions: List[String] = Nil)
  {
    def + (other: Selection): Selection =
      Selection(
        requirements = requirements || other.requirements,
        all_sessions = all_sessions || other.all_sessions,
        exclude_session_groups = exclude_session_groups ::: other.exclude_session_groups,
        exclude_sessions = exclude_sessions ::: other.exclude_sessions,
        session_groups = session_groups ::: other.session_groups,
        sessions = sessions ::: other.sessions)

    def apply(graph: Graph[String, Info]): (List[String], Graph[String, Info]) =
    {
      val bad_sessions =
        SortedSet((exclude_sessions ::: sessions).filterNot(graph.defined(_)): _*).toList
      if (bad_sessions.nonEmpty) error("Undefined session(s): " + commas_quote(bad_sessions))

      val excluded =
      {
        val exclude_group = exclude_session_groups.toSet
        val exclude_group_sessions =
          (for {
            (name, (info, _)) <- graph.iterator
            if graph.get_node(name).groups.exists(exclude_group)
          } yield name).toList
        graph.all_succs(exclude_group_sessions ::: exclude_sessions).toSet
      }

      val pre_selected =
      {
        if (all_sessions) graph.keys
        else {
          val select_group = session_groups.toSet
          val select = sessions.toSet
          (for {
            (name, (info, _)) <- graph.iterator
            if info.select || select(name) || graph.get_node(name).groups.exists(select_group)
          } yield name).toList
        }
      }.filterNot(excluded)

      val selected =
        if (requirements) (graph.all_preds(pre_selected).toSet -- pre_selected).toList
        else pre_selected

      (selected, graph.restrict(graph.all_preds(selected).toSet))
    }
  }

  def make(infos: Traversable[(String, Info)]): T =
  {
    def add_edges(graph: Graph[String, Info], kind: String, edges: Info => Traversable[String])
      : Graph[String, Info] =
    {
      def add_edge(pos: Position.T, name: String, g: Graph[String, Info], parent: String) =
      {
        if (!g.defined(parent))
          error("Bad " + kind + " session " + quote(parent) + " for " +
            quote(name) + Position.here(pos))

        try { g.add_edge_acyclic(parent, name) }
        catch {
          case exn: Graph.Cycles[_] =>
            error(cat_lines(exn.cycles.map(cycle =>
              "Cyclic session dependency of " +
                cycle.map(c => quote(c.toString)).mkString(" via "))) + Position.here(pos))
        }
      }
      (graph /: graph.iterator) {
        case (g, (name, (info, _))) => (g /: edges(info))(add_edge(info.pos, name, _, _))
      }
    }

    val graph0 =
      (Graph.string[Info] /: infos) {
        case (graph, (name, info)) =>
          if (graph.defined(name))
            error("Duplicate session " + quote(name) + Position.here(info.pos) +
              Position.here(graph.get_node(name).pos))
          else graph.new_node(name, info)
      }
    val graph1 = add_edges(graph0, "parent", _.parent)
    val graph2 = add_edges(graph1, "imports", _.imports)

    new T(graph1, graph2)
  }

  final class T private[Sessions](
      val build_graph: Graph[String, Info],
      val imports_graph: Graph[String, Info])
  {
    def apply(name: String): Info = imports_graph.get_node(name)
    def get(name: String): Option[Info] =
      if (imports_graph.defined(name)) Some(imports_graph.get_node(name)) else None

    def global_theories: Map[String, String] =
      (Thy_Header.bootstrap_global_theories.toMap /:
        (for {
          (_, (info, _)) <- imports_graph.iterator
          thy <- info.global_theories.iterator }
         yield (thy, info)))({
            case (global, (thy, info)) =>
              val qualifier = info.theory_qualifier
              global.get(thy) match {
                case Some(qualifier1) if qualifier != qualifier1 =>
                  error("Duplicate global theory " + quote(thy) + Position.here(info.pos))
                case _ => global + (thy -> qualifier)
              }
          })

    def selection(select: Selection): (List[String], T) =
    {
      val (_, build_graph1) = select(build_graph)
      val (selected, imports_graph1) = select(imports_graph)
      (selected, new T(build_graph1, imports_graph1))
    }

    def build_ancestors(name: String): List[String] =
      build_graph.all_preds(List(name)).tail.reverse

    def build_descendants(names: List[String]): List[String] =
      build_graph.all_succs(names)

    def build_topological_order: List[Info] =
      build_graph.topological_order.map(apply(_))

    def imports_ancestors(name: String): List[String] =
      imports_graph.all_preds(List(name)).tail.reverse

    def imports_topological_order: List[Info] =
      imports_graph.topological_order.map(apply(_))

    override def toString: String =
      imports_graph.keys_iterator.mkString("Sessions.T(", ", ", ")")
  }


  /* parser */

  val ROOT = Path.explode("ROOT")
  val ROOTS = Path.explode("ROOTS")

  private val CHAPTER = "chapter"
  private val SESSION = "session"
  private val IN = "in"
  private val DESCRIPTION = "description"
  private val OPTIONS = "options"
  private val SESSIONS = "sessions"
  private val THEORIES = "theories"
  private val GLOBAL = "global"
  private val FILES = "files"
  private val DOCUMENT_FILES = "document_files"

  lazy val root_syntax =
    Outer_Syntax.init() + "(" + ")" + "+" + "," + "=" + "[" + "]" + GLOBAL + IN +
      (CHAPTER, Keyword.THY_DECL) +
      (SESSION, Keyword.THY_DECL) +
      (DESCRIPTION, Keyword.QUASI_COMMAND) +
      (OPTIONS, Keyword.QUASI_COMMAND) +
      (SESSIONS, Keyword.QUASI_COMMAND) +
      (THEORIES, Keyword.QUASI_COMMAND) +
      (FILES, Keyword.QUASI_COMMAND) +
      (DOCUMENT_FILES, Keyword.QUASI_COMMAND)

  private object Parser extends Parse.Parser with Options.Parser
  {
    private abstract class Entry
    private sealed case class Chapter(name: String) extends Entry
    private sealed case class Session_Entry(
      pos: Position.T,
      name: String,
      groups: List[String],
      path: String,
      parent: Option[String],
      description: String,
      options: List[Options.Spec],
      imports: List[String],
      theories: List[(List[Options.Spec], List[((String, Position.T), Boolean)])],
      files: List[String],
      document_files: List[(String, String)]) extends Entry
    {
      def theories_no_position: List[(List[Options.Spec], List[(String, Boolean)])] =
        theories.map({ case (a, b) => (a, b.map({ case ((c, _), d) => (c, d) })) })
    }

    private val chapter: Parser[Chapter] =
    {
      val chapter_name = atom("chapter name", _.is_name)

      command(CHAPTER) ~! chapter_name ^^ { case _ ~ a => Chapter(a) }
    }

    private val session_entry: Parser[Session_Entry] =
    {
      val session_name = atom("session name", _.is_name)

      val option =
        option_name ~ opt($$$("=") ~! option_value ^^
          { case _ ~ x => x }) ^^ { case x ~ y => (x, y) }
      val options = $$$("[") ~> rep1sep(option, $$$(",")) <~ $$$("]")

      val global =
        ($$$("(") ~! $$$(GLOBAL) ~ $$$(")")) ^^ { case _ => true } | success(false)

      val theory_entry =
        position(theory_name) ~ global ^^ { case x ~ y => (x, y) }

      val theories =
        $$$(THEORIES) ~!
          ((options | success(Nil)) ~ rep(theory_entry)) ^^
          { case _ ~ (x ~ y) => (x, y) }

      val document_files =
        $$$(DOCUMENT_FILES) ~!
          (($$$("(") ~! ($$$(IN) ~! (path ~ $$$(")"))) ^^
              { case _ ~ (_ ~ (x ~ _)) => x } | success("document")) ~
            rep1(path)) ^^ { case _ ~ (x ~ y) => y.map((x, _)) }

      command(SESSION) ~!
        (position(session_name) ~
          (($$$("(") ~! (rep1(name) <~ $$$(")")) ^^ { case _ ~ x => x }) | success(Nil)) ~
          (($$$(IN) ~! path ^^ { case _ ~ x => x }) | success(".")) ~
          ($$$("=") ~!
            (opt(session_name ~! $$$("+") ^^ { case x ~ _ => x }) ~
              (($$$(DESCRIPTION) ~! text ^^ { case _ ~ x => x }) | success("")) ~
              (($$$(OPTIONS) ~! options ^^ { case _ ~ x => x }) | success(Nil)) ~
              (($$$(SESSIONS) ~! rep(session_name)  ^^ { case _ ~ x => x }) | success(Nil)) ~
              rep1(theories) ~
              (($$$(FILES) ~! rep1(path) ^^ { case _ ~ x => x }) | success(Nil)) ~
              (rep(document_files) ^^ (x => x.flatten))))) ^^
        { case _ ~ ((a, pos) ~ b ~ c ~ (_ ~ (d ~ e ~ f ~ g ~ h ~ i ~ j))) =>
            Session_Entry(pos, a, b, c, d, e, f, g, h, i, j) }
    }

    def parse(options: Options, select: Boolean, dir: Path): List[(String, Info)] =
    {
      def make_info(entry_chapter: String, entry: Session_Entry): (String, Info) =
      {
        try {
          val name = entry.name

          if (name == "" || name == DRAFT) error("Bad session name")
          if (is_pure(name) && entry.parent.isDefined) error("Illegal parent session")
          if (!is_pure(name) && !entry.parent.isDefined) error("Missing parent session")

          val session_options = options ++ entry.options

          val theories =
            entry.theories.map({ case (opts, thys) => (session_options ++ opts, thys.map(_._1)) })

          val global_theories =
            for { (_, thys) <- entry.theories; ((thy, pos), global) <- thys if global }
            yield {
              val thy_name = Path.explode(thy).expand.base_name
              if (Long_Name.is_qualified(thy_name))
                error("Bad qualified name for global theory " +
                  quote(thy_name) + Position.here(pos))
              else thy_name
            }

          val files = entry.files.map(Path.explode(_))
          val document_files =
            entry.document_files.map({ case (s1, s2) => (Path.explode(s1), Path.explode(s2)) })

          val meta_digest =
            SHA1.digest((entry_chapter, name, entry.parent, entry.options, entry.imports,
              entry.theories_no_position, entry.files, entry.document_files).toString)

          val info =
            Info(name, entry_chapter, select, entry.pos, entry.groups,
              dir + Path.explode(entry.path), entry.parent, entry.description, session_options,
              entry.imports, theories, global_theories, files, document_files, meta_digest)

          (name, info)
        }
        catch {
          case ERROR(msg) =>
            error(msg + "\nThe error(s) above occurred in session entry " +
              quote(entry.name) + Position.here(entry.pos))
        }
      }

      val root = dir + ROOT
      if (root.is_file) {
        val toks = Token.explode(root_syntax.keywords, File.read(root))
        val start = Token.Pos.file(root.implode)

        parse_all(rep(chapter | session_entry), Token.reader(toks, start)) match {
          case Success(result, _) =>
            var entry_chapter = "Unsorted"
            val infos = new mutable.ListBuffer[(String, Info)]
            result.foreach {
              case Chapter(name) => entry_chapter = name
              case entry: Session_Entry => infos += make_info(entry_chapter, entry)
            }
            infos.toList
          case bad => error(bad.toString)
        }
      }
      else Nil
    }
  }


  /* load sessions from certain directories */

  private def is_session_dir(dir: Path): Boolean =
    (dir + ROOT).is_file || (dir + ROOTS).is_file

  private def check_session_dir(dir: Path): Path =
    if (is_session_dir(dir)) File.pwd() + dir.expand
    else error("Bad session root directory: " + dir.toString)

  def directories(dirs: List[Path], select_dirs: List[Path]): List[(Boolean, Path)] =
  {
    val default_dirs = Isabelle_System.components().filter(is_session_dir(_))
    (default_dirs ::: dirs).map((false, _)) ::: select_dirs.map((true, _))
  }

  def load(options: Options, dirs: List[Path] = Nil, select_dirs: List[Path] = Nil): T =
  {
    def load_dir(select: Boolean, dir: Path): List[(String, Info)] =
      load_root(select, dir) ::: load_roots(select, dir)

    def load_root(select: Boolean, dir: Path): List[(String, Info)] =
      Parser.parse(options, select, dir)

    def load_roots(select: Boolean, dir: Path): List[(String, Info)] =
    {
      val roots = dir + ROOTS
      if (roots.is_file) {
        for {
          line <- split_lines(File.read(roots))
          if !(line == "" || line.startsWith("#"))
          dir1 =
            try { check_session_dir(dir + Path.explode(line)) }
            catch {
              case ERROR(msg) =>
                error(msg + "\nThe error(s) above occurred in session catalog " + roots.toString)
            }
          info <- load_dir(select, dir1)
        } yield info
      }
      else Nil
    }

    make(
      for {
        (select, dir) <- directories(dirs, select_dirs)
        info <- load_dir(select, check_session_dir(dir))
      } yield info)
  }



  /** heap file with SHA1 digest **/

  private val sha1_prefix = "SHA1:"

  def read_heap_digest(heap: Path): Option[String] =
  {
    if (heap.is_file) {
      val file = FileChannel.open(heap.file.toPath, StandardOpenOption.READ)
      try {
        val len = file.size
        val n = sha1_prefix.length + SHA1.digest_length
        if (len >= n) {
          file.position(len - n)

          val buf = ByteBuffer.allocate(n)
          var i = 0
          var m = 0
          do {
            m = file.read(buf)
            if (m != -1) i += m
          }
          while (m != -1 && n > i)

          if (i == n) {
            val prefix = new String(buf.array(), 0, sha1_prefix.length, UTF8.charset)
            val s = new String(buf.array(), sha1_prefix.length, SHA1.digest_length, UTF8.charset)
            if (prefix == sha1_prefix) Some(s) else None
          }
          else None
        }
        else None
      }
      finally { file.close }
    }
    else None
  }

  def write_heap_digest(heap: Path): String =
    read_heap_digest(heap) match {
      case None =>
        val s = SHA1.digest(heap).rep
        File.append(heap, sha1_prefix + s)
        s
      case Some(s) => s
    }



  /** persistent store **/

  object Session_Info
  {
    val session_name = SQL.Column.string("session_name", primary_key = true)

    // Build_Log.Session_Info
    val session_timing = SQL.Column.bytes("session_timing")
    val command_timings = SQL.Column.bytes("command_timings")
    val ml_statistics = SQL.Column.bytes("ml_statistics")
    val task_statistics = SQL.Column.bytes("task_statistics")
    val errors = SQL.Column.bytes("errors")
    val build_log_columns =
      List(session_name, session_timing, command_timings, ml_statistics, task_statistics, errors)

    // Build.Session_Info
    val sources = SQL.Column.string("sources")
    val input_heaps = SQL.Column.string("input_heaps")
    val output_heap = SQL.Column.string("output_heap")
    val return_code = SQL.Column.int("return_code")
    val build_columns = List(sources, input_heaps, output_heap, return_code)

    val table = SQL.Table("isabelle_session_info", build_log_columns ::: build_columns)
  }

  def store(system_mode: Boolean = false): Store = new Store(system_mode)

  class Store private[Sessions](system_mode: Boolean)
  {
    /* file names */

    def database(name: String): Path = Path.basic("log") + Path.basic(name).ext("db")
    def log(name: String): Path = Path.basic("log") + Path.basic(name)
    def log_gz(name: String): Path = log(name).ext("gz")


    /* SQL database content */

    val xml_cache = new XML.Cache()

    def read_bytes(db: SQL.Database, name: String, column: SQL.Column): Bytes =
      db.using_statement(Session_Info.table.select(List(column),
        Session_Info.session_name.where_equal(name)))(stmt =>
      {
        val res = stmt.execute_query()
        if (!res.next()) Bytes.empty else res.bytes(column)
      })

    def read_properties(db: SQL.Database, name: String, column: SQL.Column): List[Properties.T] =
      Properties.uncompress(read_bytes(db, name, column), Some(xml_cache))


    /* output */

    val browser_info: Path =
      if (system_mode) Path.explode("~~/browser_info")
      else Path.explode("$ISABELLE_BROWSER_INFO")

    val output_dir: Path =
      if (system_mode) Path.explode("~~/heaps/$ML_IDENTIFIER")
      else Path.explode("$ISABELLE_OUTPUT")

    override def toString: String = "Store(output_dir = " + output_dir.expand + ")"

    def prepare_output() { Isabelle_System.mkdirs(output_dir + Path.basic("log")) }


    /* input */

    private val input_dirs =
      if (system_mode) List(output_dir)
      else {
        val ml_ident = Path.explode("$ML_IDENTIFIER").expand
        output_dir :: Path.split(Isabelle_System.getenv_strict("ISABELLE_PATH")).map(_ + ml_ident)
      }

    def find_database_heap(name: String): Option[(Path, Option[String])] =
      input_dirs.find(dir => (dir + database(name)).is_file).map(dir =>
        (dir + database(name), read_heap_digest(dir + Path.basic(name))))

    def find_database(name: String): Option[Path] =
      input_dirs.map(_ + database(name)).find(_.is_file)

    def heap(name: String): Path =
      input_dirs.map(_ + Path.basic(name)).find(_.is_file) getOrElse
        error("Unknown logic " + quote(name) + " -- no heap file found in:\n" +
          cat_lines(input_dirs.map(dir => "  " + dir.expand.implode)))


    /* session info */

    def write_session_info(
      db: SQL.Database,
      name: String,
      build_log: Build_Log.Session_Info,
      build: Build.Session_Info)
    {
      db.transaction {
        db.create_table(Session_Info.table)
        db.using_statement(
          Session_Info.table.delete(Session_Info.session_name.where_equal(name)))(_.execute)
        db.using_statement(Session_Info.table.insert())(stmt =>
        {
          stmt.string(1) = name
          stmt.bytes(2) = Properties.encode(build_log.session_timing)
          stmt.bytes(3) = Properties.compress(build_log.command_timings)
          stmt.bytes(4) = Properties.compress(build_log.ml_statistics)
          stmt.bytes(5) = Properties.compress(build_log.task_statistics)
          stmt.bytes(6) = Build_Log.compress_errors(build_log.errors)
          stmt.string(7) = cat_lines(build.sources)
          stmt.string(8) = cat_lines(build.input_heaps)
          stmt.string(9) = build.output_heap getOrElse ""
          stmt.int(10) = build.return_code
          stmt.execute()
        })
      }
    }

    def read_session_timing(db: SQL.Database, name: String): Properties.T =
      Properties.decode(read_bytes(db, name, Session_Info.session_timing), Some(xml_cache))

    def read_command_timings(db: SQL.Database, name: String): List[Properties.T] =
      read_properties(db, name, Session_Info.command_timings)

    def read_ml_statistics(db: SQL.Database, name: String): List[Properties.T] =
      read_properties(db, name, Session_Info.ml_statistics)

    def read_task_statistics(db: SQL.Database, name: String): List[Properties.T] =
      read_properties(db, name, Session_Info.task_statistics)

    def read_errors(db: SQL.Database, name: String): List[String] =
      Build_Log.uncompress_errors(read_bytes(db, name, Session_Info.errors))

    def read_build(db: SQL.Database, name: String): Option[Build.Session_Info] =
      db.using_statement(Session_Info.table.select(Session_Info.build_columns,
        Session_Info.session_name.where_equal(name)))(stmt =>
      {
        val res = stmt.execute_query()
        if (!res.next()) None
        else {
          Some(
            Build.Session_Info(
              split_lines(res.string(Session_Info.sources)),
              split_lines(res.string(Session_Info.input_heaps)),
              res.string(Session_Info.output_heap) match { case "" => None case s => Some(s) },
              res.int(Session_Info.return_code)))
        }
      })
  }
}
