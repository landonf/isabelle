/*  Title:      Tools/jEdit/src/isabelle.scala
    Author:     Makarius

Convenience operations for Isabelle/jEdit.
*/

package isabelle.jedit


import isabelle._

import org.gjt.sp.jedit.{jEdit, View, Buffer}
import org.gjt.sp.jedit.textarea.JEditTextArea
import org.gjt.sp.jedit.gui.DockableWindowManager


object Isabelle
{
  /* dockable windows */

  private def wm(view: View): DockableWindowManager = view.getDockableWindowManager

  def docked_session(view: View): Option[Session_Dockable] =
    wm(view).getDockableWindow("isabelle-session") match {
      case dockable: Session_Dockable => Some(dockable)
      case _ => None
    }

  def docked_output(view: View): Option[Output_Dockable] =
    wm(view).getDockableWindow("isabelle-output") match {
      case dockable: Output_Dockable => Some(dockable)
      case _ => None
    }

  def docked_raw_output(view: View): Option[Raw_Output_Dockable] =
    wm(view).getDockableWindow("isabelle-raw-output") match {
      case dockable: Raw_Output_Dockable => Some(dockable)
      case _ => None
    }

  def docked_protocol(view: View): Option[Protocol_Dockable] =
    wm(view).getDockableWindow("isabelle-protocol") match {
      case dockable: Protocol_Dockable => Some(dockable)
      case _ => None
    }


  /* font size */

  def change_font_size(view: View, change: Int => Int)
  {
    val size = change(jEdit.getIntegerProperty("view.fontsize", 16)) max 5
    jEdit.setIntegerProperty("view.fontsize", size)
    jEdit.propertiesChanged()
    jEdit.saveSettings()
    view.getStatus.setMessageAndClear("Text font size: " + size)
  }

  def increase_font_size(view: View): Unit = change_font_size(view, i => i + ((i / 10) max 1))
  def decrease_font_size(view: View): Unit = change_font_size(view, i => i - ((i / 10) max 1))


  /* control styles */

  def control_sub(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, Symbol.sub_decoded) }

  def control_sup(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, Symbol.sup_decoded) }

  def control_isub(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, Symbol.isub_decoded) }

  def control_isup(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, Symbol.isup_decoded) }

  def control_bold(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, Symbol.bold_decoded) }

  def control_reset(text_area: JEditTextArea)
  { Token_Markup.edit_control_style(text_area, "") }


  /* block styles */

  private def enclose_input(text_area: JEditTextArea, s1: String, s2: String)
  {
    s1.foreach(text_area.userInput(_))
    s2.foreach(text_area.userInput(_))
    s2.foreach(_ => text_area.goToPrevCharacter(false))
  }

  def input_bsub(text_area: JEditTextArea)
  { enclose_input(text_area, Symbol.bsub_decoded, Symbol.esub_decoded) }

  def input_bsup(text_area: JEditTextArea)
  { enclose_input(text_area, Symbol.bsup_decoded, Symbol.esup_decoded) }
}

