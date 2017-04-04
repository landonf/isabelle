/*  Title:      Tools/VSCode/src/build_vscode.scala
    Author:     Makarius

Build VSCode configuration and extension module for Isabelle.
*/

package isabelle.vscode


import isabelle._


object Build_VSCode
{
  val extension_dir = Path.explode("~~/src/Tools/VSCode/extension")


  /* Prettify Symbols Mode */

  def prettify_config: String =
    """{
  "prettifySymbolsMode.substitutions": [
      {
        "language": "isabelle",
        "revealOn": "none",
        "adjustCursorMovement": true,
        "substitutions": [""" +
          (for ((s, c) <- Symbol.codes)
           yield
            JSON.Format(
              Map("ugly" -> Library.escape_regex(s),
                "pretty" -> Library.escape_regex(Codepoint.string(c)))))
            .mkString("\n          ", ",\n          ", "") +
        """]
      }
    ]
}"""

  def build_symbols(progress: Progress = No_Progress)
  {
    val output_path = extension_dir + Path.explode("isabelle-symbols.json")
    progress.echo(output_path.implode)
    File.write_backup(output_path, prettify_config)
  }


  /* grammar */

  def build_grammar(options: Options, progress: Progress = No_Progress)
  {
    val logic = Grammar.default_logic
    val keywords = Sessions.session_base(options, logic).syntax.keywords

    val output_path = extension_dir + Path.explode(Grammar.default_output(logic))
    progress.echo(output_path.implode)
    File.write_backup(output_path, Grammar.generate(keywords))
  }


  /* extension */

  def build_extension(progress: Progress = No_Progress, publish: Boolean = false)
  {
    val output_path = extension_dir + Path.explode("out")
    progress.echo(output_path.implode)

    progress.bash(
      "npm install && npm update --dev && vsce " + (if (publish) "publish" else "package"),
      cwd = extension_dir.file, echo = true).check
  }


  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("build_vscode", "build Isabelle/VSCode extension module", args =>
    {
      var publish = false

      val getopts = Getopts("""
Usage: isabelle build_vscode

  Options are:
    -P           publish the package

Build Isabelle/VSCode extension module in directory
""" + extension_dir.expand + """

This requires npm and the vsce build and publishing tool, see also
https://code.visualstudio.com/docs/tools/vscecli
""",
        "P" -> (_ => publish = true))

      val more_args = getopts(args)
      if (more_args.nonEmpty) getopts.usage()

      val options = Options.init()
      val progress = new Console_Progress()

      build_symbols(progress)
      build_grammar(options, progress)
      build_extension(progress, publish = publish)
    }, admin = true)
}
