/*  Title:      Pure/Admin/jenkins.scala
    Author:     Makarius

Support for Jenkins continuous integration service.
*/

package isabelle


import java.net.URL
import java.time.ZoneId

import scala.util.matching.Regex


object Jenkins
{
  /* CI service */

  def root(): String =
    Isabelle_System.getenv_strict("ISABELLE_JENKINS_ROOT")

  def invoke(url: String, args: String*): Any =
  {
    val req = url + "/api/json?" + args.mkString("&")
    val result = Url.read(req)
    try { JSON.parse(result) }
    catch { case ERROR(_) => error("Malformed JSON from " + quote(req)) }
  }


  /* build jobs */

  def build_jobs(): List[String] =
    for {
      job <- JSON.array(invoke(root()), "jobs").getOrElse(Nil)
      _class <- JSON.string(job, "_class")
      if _class == "hudson.model.FreeStyleProject"
      name <- JSON.string(job, "name")
    } yield name

  sealed case class Job_Info(
    job_name: String,
    timestamp: Long,
    output: URL,
    session_logs: List[(String, URL)])
  {
    def date: Date = Date(Time.ms(timestamp), ZoneId.of("Europe/Berlin"))
    def log_filename: Path =
      Build_Log.log_filename(Build_Log.Jenkins.engine, date, List(job_name))
    def read_main_log(): Build_Log.Log_File =
      Build_Log.Log_File(log_filename.implode, Url.read(output))
    def read_session_log(name: String): Build_Log.Log_File =
      Build_Log.Log_File(name,
        session_logs.collectFirst({ case (a, b) if a == name => Url.read_gzip(b) }) getOrElse "")
  }

  def build_job_builds(job_name: String): List[Job_Info] =
  {
    val Log_Session = new Regex("""^.*/log/([^/]+)\.gz$""")

    for {
      build <-
        JSON.array(
          invoke(root() + "/job/" + job_name, "tree=allBuilds[number,timestamp,artifacts[*]]"),
          "allBuilds").getOrElse(Nil)
      number <- JSON.int(build, "number")
      timestamp <- JSON.long(build, "timestamp")
    } yield {
      val job_prefix = root() + "/job/" + job_name + "/" + number
      val output = Url(job_prefix + "/consoleText")
      val session_logs =
        for {
          artifact <- JSON.array(build, "artifacts").getOrElse(Nil)
          log_path <- JSON.string(artifact, "relativePath")
          session <- (log_path match { case Log_Session(name) => Some(name) case _ => None })
        } yield (session -> Url(job_prefix + "/artifact/" + log_path))
      Job_Info(job_name, timestamp, output, session_logs)
    }
  }
}
