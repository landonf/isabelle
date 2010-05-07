/*
 * SideKick parsers for Isabelle proof documents
 *
 * @author Fabian Immler, TU Munich
 * @author Makarius
 */

package isabelle.jedit


import isabelle._

import scala.collection.Set
import scala.collection.immutable.TreeSet

import javax.swing.tree.DefaultMutableTreeNode
import javax.swing.text.Position
import javax.swing.Icon

import org.gjt.sp.jedit.{Buffer, EditPane, TextUtilities, View}
import errorlist.DefaultErrorSource
import sidekick.{SideKickParser, SideKickParsedData, SideKickCompletion, IAsset}


object Isabelle_Sidekick
{
  implicit def int_to_pos(offset: Int): Position =
    new Position { def getOffset = offset; override def toString = offset.toString }
}


class Isabelle_Sidekick(name: String,
    parser: (() => Boolean, SideKickParsedData, Document_Model) => Unit)
  extends SideKickParser(name)
{
  /* parsing */

  @volatile private var stopped = false
  private def is_stopped(): Boolean = stopped
  override def stop() = { stopped = true }

  def parse(buffer: Buffer, error_source: DefaultErrorSource): SideKickParsedData =
  {
    import Isabelle_Sidekick.int_to_pos

    stopped = false

    // FIXME lock buffer !??
    val data = new SideKickParsedData(buffer.getName)
    val root = data.root
    data.getAsset(root).setEnd(buffer.getLength)

    Swing_Thread.now { Document_Model(buffer) } match {
      case Some(model) =>
        parser(is_stopped, data, model)
        if (stopped) root.add(new DefaultMutableTreeNode("<parser stopped>"))
      case None => root.add(new DefaultMutableTreeNode("<buffer inactive>"))
    }
    data
  }


  /* completion */

  override def supportsCompletion = true
  override def canCompleteAnywhere = true

  override def complete(pane: EditPane, caret: Int): SideKickCompletion =
  {
    val buffer = pane.getBuffer

    val line = buffer.getLineOfOffset(caret)
    val start = buffer.getLineStartOffset(line)
    val text = buffer.getSegment(start, caret - start)

    val completion = Isabelle.session.current_syntax.completion

    completion.complete(text) match {
      case None => null
      case Some((word, cs)) =>
        val ds =
          (if (Isabelle_Encoding.is_active(buffer))
            cs.map(Isabelle.system.symbols.decode(_)).sort(_ < _)
           else cs).filter(_ != word)
        if (ds.isEmpty) null
        else new SideKickCompletion(pane.getView, word, ds.toArray.asInstanceOf[Array[Object]]) { }
    }
  }
}


class Isabelle_Sidekick_Default extends Isabelle_Sidekick("isabelle",
  ((is_stopped: () => Boolean, data: SideKickParsedData, model: Document_Model) =>
    {
      import Isabelle_Sidekick.int_to_pos

      val root = data.root
      val document = model.recent_document()
      for {
        (command, command_start) <- document.command_range(0)
        if command.is_command && !is_stopped()
      }
      {
        val name = command.name
        val node =
          new DefaultMutableTreeNode(new IAsset {
            override def getIcon: Icon = null
            override def getShortString: String = name
            override def getLongString: String = name
            override def getName: String = name
            override def setName(name: String) = ()
            override def setStart(start: Position) = ()
            override def getStart: Position = command_start
            override def setEnd(end: Position) = ()
            override def getEnd: Position = command_start + command.length
            override def toString = name
          })
        root.add(node)
      }
    }))


class Isabelle_Sidekick_Raw extends Isabelle_Sidekick("isabelle-raw",
  ((is_stopped: () => Boolean, data: SideKickParsedData, model: Document_Model) =>
    {
      import Isabelle_Sidekick.int_to_pos

      val root = data.root
      val document = model.recent_document()
      for ((command, command_start) <- document.command_range(0) if !is_stopped()) {
        root.add(document.current_state(command).get.markup_root.swing_tree((node: Markup_Node) =>
            {
              val content = Pretty.str_of(List(XML.Text(command.source(node.start, node.stop))))
              val id = command.id

              new DefaultMutableTreeNode(new IAsset {
                override def getIcon: Icon = null
                override def getShortString: String = content
                override def getLongString: String = node.info.toString
                override def getName: String = id
                override def setName(name: String) = ()
                override def setStart(start: Position) = ()
                override def getStart: Position = command_start + node.start
                override def setEnd(end: Position) = ()
                override def getEnd: Position = command_start + node.stop
                override def toString = id + ": " + content + "[" + getStart + " - " + getEnd + "]"
              })
            }))
      }
    }))

