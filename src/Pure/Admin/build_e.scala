/*  Title:      Pure/Admin/build_e.scala
    Author:     Makarius

Build Isabelle E prover component from official downloads.
*/

package isabelle


object Build_E
{
  /* build E prover */

  val default_version = "2.5"

  val default_download_url =
    "https://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD"

  def build_e(
    version: String = default_version,
    download_url: String = default_download_url,
    verbose: Boolean = false,
    progress: Progress = new Progress,
    target_dir: Path = Path.current)
  {
    Isabelle_System.with_tmp_dir("e")(tmp_dir =>
    {
      /* component */

      val component_name = "e-" + version
      val component_dir = Isabelle_System.new_directory(target_dir + Path.basic(component_name))
      progress.echo("Component " + component_dir)

      val platform_name =
        proper_string(Isabelle_System.getenv("ISABELLE_PLATFORM64"))
          .getOrElse(error("No 64bit platform"))

      val platform_dir = Isabelle_System.make_directory(component_dir + Path.basic(platform_name))


      /* download source */

      val e_url = download_url + "/V_" + version + "/E.tgz"
      val e_path = tmp_dir + Path.explode("E.tgz")
      Isabelle_System.download(e_url, e_path, progress = progress)

      Isabelle_System.bash("tar xzf " + e_path, cwd = tmp_dir.file).check
      Isabelle_System.bash("tar xzf " + e_path + " && mv E src", cwd = component_dir.file).check


      /* build */

      progress.echo("Building E prover ...")

      val build_dir = tmp_dir + Path.basic("E")
      val build_options =
      {
        val result = Isabelle_System.bash("./configure --help", cwd = build_dir.file)
        if (result.check.out.containsSlice("--enable-ho")) " --enable-ho" else ""
      }

      val build_script = "./configure" + build_options + " && make"
      Isabelle_System.bash(build_script,
        cwd = build_dir.file,
        progress_stdout = progress.echo_if(verbose, _),
        progress_stderr = progress.echo_if(verbose, _)).check


      /* install */

      File.copy(build_dir + Path.basic("COPYING"), component_dir + Path.basic("LICENSE"))

      val install_files = List("epclextract", "eproof_ram", "eprover", "eprover-ho")
      for (name <- install_files ::: install_files.map(_ + ".exe")) {
        val path = build_dir + Path.basic("PROVER") + Path.basic(name)
        if (path.is_file) File.copy(path, platform_dir)
      }
      Isabelle_System.bash("if [ -f eprover-ho ]; then mv eprover-ho eprover; fi",
        cwd = platform_dir.file).check

      val eproof_ram = platform_dir + Path.basic("eproof_ram")
      if (eproof_ram.is_file) {
        File.change(eproof_ram, _.replace("EXECPATH=.", "EXECPATH=`dirname \"$0\"`"))
      }


      /* settings */

      val etc_dir = Isabelle_System.make_directory(component_dir + Path.basic("etc"))
      File.write(etc_dir + Path.basic("settings"),
        """# -*- shell-script -*- :mode=shellscript:

E_HOME="$COMPONENT/$ISABELLE_PLATFORM64"
E_VERSION=""" + quote(version) + """
""")

      /* README */

      File.write(component_dir + Path.basic("README"),
        "This is E prover " + version + " from\n" + e_url + """

The distribution has been built like this:

    cd src && """ + build_script + """

Only a few executables from PROVERS/ have been moved to the platform-specific
Isabelle component directory: x86_64-linux etc.


    Makarius
    """ + Date.Format.date(Date.now()) + "\n")
    })
}

  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("build_e", "build Isabelle E prover component from official download",
    args =>
    {
      var target_dir = Path.current
      var version = default_version
      var download_url = default_download_url
      var verbose = false

      val getopts = Getopts("""
Usage: isabelle build_e [OPTIONS]

  Options are:
    -D DIR       target directory (default ".")
    -U URL       E prover download URL
                 (default: """" + default_download_url + """")
    -V VERSION   E prover version (default: """ + default_version + """)
    -v           verbose

  Build E prover component from the specified download URLs and version.
""",
        "D:" -> (arg => target_dir = Path.explode(arg)),
        "U:" -> (arg => download_url = arg),
        "V:" -> (arg => version = arg),
        "v" -> (_ => verbose = true))

      val more_args = getopts(args)
      if (more_args.nonEmpty) getopts.usage()

      val progress = new Console_Progress()

      build_e(version = version, download_url = download_url,
        verbose = verbose, progress = progress, target_dir = target_dir)
    })
}
