/*  Title:      Pure/Admin/build_status.scala
    Author:     Makarius

Present recent build status information from database.
*/

package isabelle


object Build_Status
{
  private val default_target_dir = Path.explode("build_status")
  private val default_history_length = 30
  private val default_image_size = (640, 480)


  /* data profiles */

  sealed case class Profile(name: String, sql: String)
  {
    def select(columns: List[SQL.Column], days: Int, only_sessions: Set[String]): SQL.Source =
    {
      val sql_sessions =
        if (only_sessions.isEmpty) ""
        else
          only_sessions.iterator.map(a => Build_Log.Data.session_name + " = " + SQL.string(a))
            .mkString("(", " OR ", ") AND ")

      Build_Log.Data.universal_table.select(columns, distinct = true,
        sql = "WHERE " +
          Build_Log.Data.pull_date + " > " + Build_Log.Data.recent_time(days) + " AND " +
          Build_Log.Data.status + " = " + SQL.string(Build_Log.Session_Status.finished.toString) +
          " AND " + sql_sessions + SQL.enclose(sql) +
          " ORDER BY " + Build_Log.Data.pull_date + " DESC")
    }
  }

  val standard_profiles: List[Profile] =
    Jenkins.build_status_profiles ::: Isabelle_Cronjob.build_status_profiles

  sealed case class Entry(date: Date, timing: Timing, ml_timing: Timing)

  sealed case class Data(date: Date, entries: Map[String, Map[String, List[Entry]]])
  {
    def sorted_entries: List[(String, List[(String, List[Entry])])] =
      entries.toList.sortBy(_._1).map({ case (name, session_entries) =>
        (name, session_entries.toList.sortBy(_._2.head.timing.elapsed.ms).reverse) })
  }


  /* read data */

  def read_data(options: Options,
    profiles: List[Profile] = standard_profiles,
    progress: Progress = No_Progress,
    history_length: Int = default_history_length,
    only_sessions: Set[String] = Set.empty,
    verbose: Boolean = false): Data =
  {
    val date = Date.now()
    var data_entries = Map.empty[String, Map[String, List[Entry]]]

    val store = Build_Log.store(options)
    using(store.open_database())(db =>
    {
      for (profile <- profiles.sortBy(_.name)) {
        progress.echo("input " + quote(profile.name))
        val columns =
          List(
            Build_Log.Data.pull_date,
            Build_Log.Settings.ISABELLE_BUILD_OPTIONS,
            Build_Log.Settings.ML_PLATFORM,
            Build_Log.Data.session_name,
            Build_Log.Data.threads,
            Build_Log.Data.timing_elapsed,
            Build_Log.Data.timing_cpu,
            Build_Log.Data.timing_gc,
            Build_Log.Data.ml_timing_elapsed,
            Build_Log.Data.ml_timing_cpu,
            Build_Log.Data.ml_timing_gc)

        val Threads_Option = """threads\s*=\s*(\d+)""".r

        val sql = profile.select(columns, history_length, only_sessions)
        if (verbose) progress.echo(sql)

        db.using_statement(sql)(stmt =>
        {
          val res = stmt.execute_query()
          while (res.next()) {
            val ml_platform = res.string(Build_Log.Settings.ML_PLATFORM)

            val threads_option =
              res.string(Build_Log.Settings.ISABELLE_BUILD_OPTIONS) match {
                case Threads_Option(Value.Int(i)) => i
                case _ => 1
              }
            val threads = res.get_int(Build_Log.Data.threads).getOrElse(1)

            val name =
              profile.name +
                "_m" + (if (ml_platform.startsWith("x86_64")) "64" else "32") +
                "_M" + (threads_option max threads)

            val session = res.string(Build_Log.Data.session_name)
            val entry =
              Entry(res.date(Build_Log.Data.pull_date),
                res.timing(
                  Build_Log.Data.timing_elapsed,
                  Build_Log.Data.timing_cpu,
                  Build_Log.Data.timing_gc),
                res.timing(
                  Build_Log.Data.ml_timing_elapsed,
                  Build_Log.Data.ml_timing_cpu,
                  Build_Log.Data.ml_timing_gc))

            val session_entries = data_entries.getOrElse(name, Map.empty)
            val entries = session_entries.getOrElse(session, Nil)
            data_entries += (name -> (session_entries + (session -> (entry :: entries))))
          }
        })
      }
    })

    Data(date,
      for {
        (name, session_entries) <- data_entries
        session_entries1 <-
          {
            val session_entries1 =
              for { (session, entries) <- session_entries if entries.length >= 3 }
              yield (session, entries)
            if (session_entries1.isEmpty) None
            else Some(session_entries1)
          }
      } yield (name, session_entries1))
  }


  /* present data */

  def present_data(data: Data,
    progress: Progress = No_Progress,
    target_dir: Path = default_target_dir,
    image_size: (Int, Int) = default_image_size)
  {
    val data_entries = data.sorted_entries

    for ((data_name, session_entries) <- data_entries) {
      val dir = target_dir + Path.explode(data_name)
      progress.echo("output " + dir)
      Isabelle_System.mkdirs(dir)

      Par_List.map[(String, List[isabelle.Build_Status.Entry]), List[Process_Result]](
        { case (session, entries) =>
          Isabelle_System.with_tmp_file(session, "data") { data_file =>
            Isabelle_System.with_tmp_file(session, "gnuplot") { gnuplot_file =>

              File.write(data_file,
                cat_lines(
                  entries.map(entry =>
                    List(entry.date.unix_epoch.toString,
                      entry.timing.elapsed.minutes,
                      entry.timing.cpu.minutes,
                      entry.ml_timing.elapsed.minutes,
                      entry.ml_timing.cpu.minutes,
                      entry.ml_timing.gc.minutes).mkString(" "))))

              def gnuplot(plots: List[String], kind: String): Process_Result =
              {
                val name = session + "_" + kind
                File.write(gnuplot_file, """
set terminal png size """ + image_size._1 + "," + image_size._2 + """
set output """ + quote(File.standard_path(dir + Path.basic(name + ".png"))) + """
set xdata time
set timefmt "%s"
set format x "%d-%b"
set xlabel """ + quote(session) + """ noenhanced
set key left top
plot [] [0:] """ + plots.map(s => quote(data_file.implode) + " " + s).mkString(", ") + "\n")

                val result =
                  Isabelle_System.bash("\"$ISABELLE_GNUPLOT\" " + File.bash_path(gnuplot_file))
                if (result.ok) result
                else result.error("Gnuplot failed for " + data_name + "/" + name)
              }

              val timing_plots =
                List(
                  """ using 1:3 smooth sbezier title "cpu time (smooth)" """,
                  """ using 1:3 smooth csplines title "cpu time" """,
                  """ using 1:2 smooth sbezier title "elapsed time (smooth)" """,
                  """ using 1:2 smooth csplines title "elapsed time" """)
              val ml_timing_plots =
                List(
                  """ using 1:5 smooth sbezier title "ML cpu time (smooth)" """,
                  """ using 1:5 smooth csplines title "ML cpu time" """,
                  """ using 1:4 smooth sbezier title "ML elapsed time (smooth)" """,
                  """ using 1:4 smooth csplines title "ML elapsed time" """,
                  """ using 1:6 smooth sbezier title "ML gc time (smooth)" """,
                  """ using 1:6 smooth csplines title "ML gc time" """)

              List(gnuplot(timing_plots, "timing"), gnuplot(ml_timing_plots, "ml_timing"))
            }
          }
        }, session_entries).flatten.foreach(_.check)

      val sessions = session_entries.toList.sortBy(_._2.head.timing.elapsed.ms).reverse
      val heading = "Build status for " + data_name + " (" + data.date + ")"

      File.write(dir + Path.basic("index.html"),
        HTML.output_document(
          List(HTML.title(heading)),
          HTML.chapter(heading) ::
          HTML.itemize(
            sessions.map({ case (name, entries) =>
              HTML.link("#session_" + name, HTML.text(name)) ::
              HTML.text(" (" + entries.head.timing.message_resources + ")") })) ::
          sessions.flatMap({ case (name, entries) =>
            List(
              HTML.section(name) + HTML.id("session_" + name),
              HTML.par(
                List(
                  HTML.itemize(List(
                    HTML.bold(HTML.text("timing: ")) ::
                      HTML.text(entries.head.timing.message_resources),
                    HTML.bold(HTML.text("ML timing: ")) ::
                      HTML.text(entries.head.ml_timing.message_resources))),
                  HTML.image(name + "_timing.png"),
                  HTML.image(name + "_ml_timing.png")))) })))
    }

    val heading = "Build status (" + data.date + ")"

    File.write(target_dir + Path.basic("index.html"),
      HTML.output_document(
        List(HTML.title(heading)),
        List(HTML.chapter(heading),
          HTML.itemize(data_entries.map({ case (name, _) =>
            List(HTML.link(name + "/index.html", HTML.text(name))) })))))
  }


  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("build_status", "present recent build status information from database", args =>
    {
      var target_dir = default_target_dir
      var only_sessions = Set.empty[String]
      var history_length = default_history_length
      var options = Options.init()
      var image_size = default_image_size
      var verbose = false

      val getopts = Getopts("""
Usage: isabelle build_status [OPTIONS]

  Options are:
    -D DIR       target directory (default """ + default_target_dir + """)
    -S SESSIONS  only given SESSIONS (comma separated)
    -l LENGTH    length of history (default """ + default_history_length + """)
    -o OPTION    override Isabelle system OPTION (via NAME=VAL or NAME)
    -s WxH       size of PNG image (default """ + image_size._1 + "x" + image_size._2 + """)
    -v           verbose

  Present performance statistics from build log database, which is specified
  via system options build_log_database_host, build_log_database_user etc.
""",
        "D:" -> (arg => target_dir = Path.explode(arg)),
        "S:" -> (arg => only_sessions = space_explode(',', arg).toSet),
        "l:" -> (arg => history_length = Value.Int.parse(arg)),
        "o:" -> (arg => options = options + arg),
        "s:" -> (arg =>
          space_explode('x', arg).map(Value.Int.parse(_)) match {
            case List(w, h) if w > 0 && h > 0 => image_size = (w, h)
            case _ => error("Error bad PNG image size: " + quote(arg))
          }),
        "v" -> (_ => verbose = true))

      val more_args = getopts(args)
      if (more_args.nonEmpty) getopts.usage()

      val progress = new Console_Progress

      val data =
        read_data(options, progress = progress, history_length = history_length,
          only_sessions = only_sessions, verbose = verbose)

      present_data(data, progress = progress, target_dir = target_dir, image_size = image_size)

  }, admin = true)
}