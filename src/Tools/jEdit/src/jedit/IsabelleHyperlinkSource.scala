/*
 * IsabelleHyperlinkSource.scala
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package isabelle.jedit

import java.io.File

import gatchan.jedit.hyperlinks.Hyperlink
import gatchan.jedit.hyperlinks.HyperlinkSource
import gatchan.jedit.hyperlinks.AbstractHyperlink

import org.gjt.sp.jedit.View
import org.gjt.sp.jedit.jEdit
import org.gjt.sp.jedit.Buffer
import org.gjt.sp.jedit.TextUtilities

import isabelle.prover.RefInfo

class InternalHyperlink(start: Int, end: Int, line: Int, ref_offset: Int)
  extends AbstractHyperlink(start, end, line, "")
{
  override def click(view: View) {
    view.getTextArea.moveCaretPosition(ref_offset)
  }
}

class ExternalHyperlink(start: Int, end: Int, line: Int, ref_file: String, ref_line: Int)
  extends AbstractHyperlink(start, end, line, "")
{
  def subdirs(file: File): List[File] = {
    val subs = file.listFiles.filter(_.isDirectory).toList
    subs ::: subs.flatMap(subdirs)
  }

  val srcs = List(new File(Isabelle.system.getenv("ML_SOURCES")))
  val rec_srcs = List(new File(Isabelle.system.getenv("ISABELLE_HOME"), "src"))

  override def click(view: View) =
    (srcs ::: rec_srcs.flatMap(subdirs)).find(new File(_, ref_file).exists) match {
      case None => System.err.println("Could not find file " + ref_file)
      case Some(dir) =>
        val file = new File(dir, ref_file)
        jEdit.openFiles(view, file.getParent, Array(file.getName, "+line:" + ref_line))
    }
}

class IsabelleHyperlinkSource extends HyperlinkSource
{
	def getHyperlink(buffer: Buffer, original_offset: Int): Hyperlink = {
    val prover = Isabelle.prover_setup(buffer).map(_.prover)
    val theory_view_opt = Isabelle.prover_setup(buffer).map(_.theory_view)
    if (!prover.isDefined || !theory_view_opt.isDefined) null
    else if (prover.get == null || theory_view_opt.get == null) null
    else {
      val document = prover.get.document
      val theory_view = theory_view_opt.get
      val offset = theory_view.from_current(document, original_offset)
      val cmd = document.find_command_at(offset)
      if (cmd != null) {
        val ref_o = cmd.ref_at(offset - cmd.start(document))
        if (!ref_o.isDefined) null
        else {
          val ref = ref_o.get
          val start = theory_view.to_current(document, ref.abs_start(document))
          val line = buffer.getLineOfOffset(start)
          val end = theory_view.to_current(document, ref.abs_stop(document))
          ref.info match {
            case RefInfo(Some(ref_file), Some(ref_line), _, _) =>
              new ExternalHyperlink(start, end, line, ref_file, ref_line)
            case RefInfo(_, _, Some(id), Some(offset)) =>
              prover.get.command(id) match {
                case Some(ref_cmd) =>
                  new InternalHyperlink(start, end, line,
                    theory_view.to_current(document, ref_cmd.start(document) + offset - 1))
                case _ => null
              }
            case _ => null
          }
        }
      } else null
    }
  }
}
