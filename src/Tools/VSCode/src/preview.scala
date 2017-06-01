/*  Title:      Tools/VSCode/src/preview.scala
    Author:     Makarius

HTML document preview.
*/

package isabelle.vscode


import isabelle._

import java.io.{File => JFile}


class Preview(resources: VSCode_Resources)
{
  private val pending = Synchronized(Map.empty[JFile, Int])

  def request(file: JFile, column: Int): Unit =
    pending.change(map => map + (file -> column))

  def flush(channel: Channel): Boolean =
  {
    pending.change_result(map =>
    {
      val map1 =
        (map /: map.iterator)({ case (m, (file, column)) =>
          resources.get_model(file) match {
            case Some(model) =>
              val snapshot = model.snapshot()
              if (snapshot.is_outdated) m
              else {
                val (label, content) = make_preview(model, snapshot)
                channel.write(Protocol.Preview_Response(file, column, label, content))
                m - file
              }
            case None => m - file
          }
        })
      (map1.nonEmpty, map1)
    })
  }

  def make_preview(model: Document_Model, snapshot: Document.Snapshot): (String, String) =
  {
    val label = "Preview " + quote(model.node_name.toString)
    val content =
      HTML.output_document(head = Nil, css = "", body =
        List(
          HTML.chapter("Theory " + quote(model.node_name.theory_base_name)),
          HTML.source(Symbol.decode(snapshot.node.commands.iterator.map(_.source).mkString))))
    (label, content)
  }
}
