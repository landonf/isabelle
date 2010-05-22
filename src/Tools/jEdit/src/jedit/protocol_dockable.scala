/*  Title:      Tools/jEdit/src/jedit/protocol_dockable.scala
    Author:     Makarius

Dockable window for raw protocol messages.
*/

package isabelle.jedit


import isabelle._

import scala.actors.Actor._

import java.awt.{Dimension, Graphics, BorderLayout}
import javax.swing.{JPanel, JTextArea, JScrollPane}

import org.gjt.sp.jedit.View
import org.gjt.sp.jedit.gui.DockableWindowManager


class Protocol_Dockable(view: View, position: String) extends JPanel(new BorderLayout)
{
  if (position == DockableWindowManager.FLOATING)
    setPreferredSize(new Dimension(500, 250))

  private val text_area = new JTextArea
  add(new JScrollPane(text_area), BorderLayout.CENTER)


  /* actor wiring */

  private val protocol_actor = actor {
    loop {
      react {
        case result: Isabelle_Process.Result =>
          Swing_Thread.now { text_area.append(result.message.toString + "\n") }

        case bad => System.err.println("protocol_actor: ignoring bad message " + bad)
      }
    }
  }

  override def addNotify()
  {
    super.addNotify()
    Isabelle.session.raw_results += protocol_actor
  }

  override def removeNotify()
  {
    Isabelle.session.raw_results -= protocol_actor
    super.removeNotify()
  }
}
