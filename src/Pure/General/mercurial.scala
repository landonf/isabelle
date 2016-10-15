/*  Title:      Pure/General/mercurial.scala
    Author:     Makarius

Support for Mercurial repositories.
*/

package isabelle


import java.io.{File => JFile}


object Mercurial
{
  /* command-line syntax */

  def optional(s: String, prefix: String = ""): String =
    if (s == "") "" else " " + prefix + " " + File.bash_string(s)

  def opt_flag(flag: String, b: Boolean): String = if (b) " " + flag else ""
  def opt_rev(s: String): String = optional(s, "--rev")
  def opt_template(s: String): String = optional(s, "--template")


  /* repository access */

  def repository(root: Path, ssh: Option[SSH.Session] = None): Repository =
  {
    val hg = new Repository(root, ssh)
    hg.command("root").check
    hg
  }

  def clone_repository(
    source: String, root: Path, options: String = "", ssh: Option[SSH.Session] = None): Repository =
  {
    val hg = new Repository(root, ssh)
    hg.command("clone", File.bash_string(source) + " " + File.bash_path(hg.root), options).check
    hg
  }

  def setup_repository(source: String, root: Path, ssh: Option[SSH.Session] = None): Repository =
    ssh match {
      case None => if (root.is_dir) repository(root) else clone_repository(source, root)
      case Some(session) =>
        using(session.sftp())(sftp =>
          if (sftp.is_dir(sftp.path(root))) repository(root, ssh = ssh)
          else clone_repository(source, root, ssh = ssh))
    }

  class Repository private[Mercurial](root_path: Path, ssh: Option[SSH.Session])
  {
    hg =>

    val root =
      ssh match {
        case None => root_path.expand
        case Some(session) => using(session.sftp())(sftp => root_path.expand_env(sftp.settings))
      }

    override def toString: String =
      ssh match {
        case None => root.implode
        case Some(session) => session.toString + ":" + root.implode
      }

    def command(name: String, args: String = "", options: String = ""): Process_Result =
    {
      val cmdline =
        "\"${HG:-hg}\"" +
          (if (name == "clone") "" else " --repository " + File.bash_path(root)) +
          " --noninteractive " + name + " " + options + " " + args
      ssh match {
        case None => Isabelle_System.bash(cmdline)
        case Some(session) => session.execute(cmdline)
      }
    }

    def heads(template: String = "{node|short}\n", options: String = ""): List[String] =
      hg.command("heads", opt_template(template), options).check.out_lines

    def identify(rev: String = "", options: String = ""): String =
      hg.command("id", opt_rev(rev), options).check.out_lines.headOption getOrElse ""

    def manifest(rev: String = "", options: String = ""): List[String] =
      hg.command("manifest", opt_rev(rev), options).check.out_lines

    def log(rev: String = "", template: String = "", options: String = ""): String =
      hg.command("log", opt_rev(rev) + opt_template(template), options).check.out

    def pull(remote: String = "", rev: String = "", options: String = ""): Unit =
      hg.command("pull", opt_rev(rev) + optional(remote), options).check

    def pull_id(remote: String = ""): String =
    {
      hg.pull(remote = remote, options = "-q")
      hg.identify("tip", options = "-i")
    }

    def update(
      rev: String = "", clean: Boolean = false, check: Boolean = false, options: String = "")
    {
      hg.command("update",
        opt_rev(rev) + opt_flag("--clean", clean) + opt_flag("--check", check), options).check
    }
  }
}
