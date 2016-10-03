/*  Title:      Pure/Tools/build_history.scala
    Author:     Makarius

Build other history versions.
*/

package isabelle


import java.io.{File => JFile}
import java.util.Calendar


object Build_History
{
  /* build_history */

  private val default_rev = "tip"
  private val default_isabelle_identifier = "build_history"

  def build_history(
    hg: Mercurial.Repository,
    rev: String = default_rev,
    isabelle_identifier: String = default_isabelle_identifier,
    components_base: String = "",
    nonfree: Boolean = false,
    verbose: Boolean = false)
  {
    hg.update(rev = rev, clean = true)
    if (verbose) hg.command("log -l1").check.print

    def bash(script: String): Process_Result =
      Isabelle_System.bash("env ISABELLE_IDENTIFIER=" + File.bash_string(isabelle_identifier) +
        " " + script, cwd = hg.root.file, env = null)

    def isabelle(cmdline: String): Process_Result = bash("bin/isabelle " + cmdline)

    val isabelle_home_user: Path = Path.explode(isabelle("getenv -b ISABELLE_HOME_USER").check.out)


    /* init settings */

    {
      val etc_settings: Path = isabelle_home_user + Path.explode("etc/settings")
      if (etc_settings.is_file && !File.read(etc_settings).startsWith("# generated by Isabelle"))
        error("User settings file already exists: " + etc_settings)

      Isabelle_System.mkdirs(etc_settings.dir)

      val components_base_path =
        if (components_base == "") isabelle_home_user.dir + Path.explode("contrib")
        else Path.explode(components_base).expand

      val catalogs =
        if (nonfree) List("main", "optional", "nonfree") else List("main", "optional")

      val settings =
        catalogs.map(catalog =>
          "init_components " + File.bash_path(components_base_path) +
            " \"$ISABELLE_HOME/Admin/components/" + catalog + "\"")

      File.write(etc_settings,
        "# generated by Isabelle " + Calendar.getInstance.getTime + "\n" +
        "#-*- shell-script -*- :mode=shellscript:\n\n" +
        Library.terminate_lines(settings))
    }


    /* components */

    isabelle("components -a").check.print_if(verbose)
    isabelle("jedit -b -f").check.print_if(verbose)

    isabelle("build -?").print
  }


  /* command line entry point */

  def main(args: Array[String])
  {
    Command_Line.tool0 {
      var components_base = ""
      var isabelle_identifier = default_isabelle_identifier
      var force = false
      var nonfree = false
      var rev = default_rev
      var verbose = false

      val getopts = Getopts("""
Usage: isabelle build_history [OPTIONS] REPOSITORY

  Options are:
    -C DIR       base directory for Isabelle components (default: $ISABELLE_HOME_USER/../contrib)
    -N NAME      alternative ISABELLE_IDENTIFIER (default: """ + default_isabelle_identifier + """)
    -f           force -- allow irreversible operations on REPOSITORY clone
    -n           include nonfree components
    -r REV       update to revision
    -v           verbose

  Build Isabelle sessions from the history of another REPOSITORY clone,
  starting at changeset REV (default: """ + default_rev + """).
""",
        "C:" -> (arg => components_base = arg),
        "N:" -> (arg => isabelle_identifier = arg),
        "f" -> (_ => force = true),
        "n" -> (_ => nonfree = true),
        "r:" -> (arg => rev = arg),
        "v" -> (_ => verbose = true))

      val more_args = getopts(args)
      val root = more_args match { case List(root) => (root) case _ => getopts.usage() }

      using(Mercurial.open_repository(Path.explode(root)))(hg =>
        {
          if (!force)
            error("Repository " + hg + " will be cleaned by force!\n" +
              "Need to provide option -f to confirm this.")

          build_history(hg, rev = rev, isabelle_identifier = isabelle_identifier,
            components_base = components_base, nonfree = nonfree, verbose = verbose)
        })
    }
  }
}
