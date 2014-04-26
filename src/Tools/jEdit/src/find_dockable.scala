/*  Title:      Tools/jEdit/src/find_dockable.scala
    Author:     Makarius

Dockable window for "find" dialog.
*/

package isabelle.jedit


import isabelle._

import java.awt.event.{ComponentEvent, ComponentAdapter, KeyEvent}
import javax.swing.{JComponent, JTextField}

import scala.swing.{Button, Component, TextField, CheckBox, Label,
  ComboBox, TabbedPane, BorderPanel}
import scala.swing.event.{ButtonClicked, Key, KeyPressed}

import org.gjt.sp.jedit.View


object Find_Dockable
{
  private abstract class Operation
  {
    def query_operation: Query_Operation[View]
    def query: JComponent
    def pretty_text_area: Pretty_Text_Area
    def page: TabbedPane.Page
  }
}

class Find_Dockable(view: View, position: String) extends Dockable(view, position)
{
  /* common GUI components */

  private var zoom_factor = 100

  private val zoom =
    new GUI.Zoom_Box(factor => if (zoom_factor != factor) { zoom_factor = factor; handle_resize() })
    {
      tooltip = "Zoom factor for output font size"
    }


  private def make_query(property: String, tooltip: String, apply_query: () => Unit): JTextField =
    new Completion_Popup.History_Text_Field(property)
    {
      override def processKeyEvent(evt: KeyEvent)
      {
        if (evt.getID == KeyEvent.KEY_PRESSED && evt.getKeyCode == KeyEvent.VK_ENTER) apply_query()
        super.processKeyEvent(evt)
      }
      { val max = getPreferredSize; max.width = Integer.MAX_VALUE; setMaximumSize(max) }
      setColumns(40)
      setToolTipText(tooltip)
      setFont(GUI.imitate_font(Font_Info.main_family(), getFont, 1.2))
    }


  /* consume status */

  def consume_status(process_indicator: Process_Indicator, status: Query_Operation.Status.Value)
  {
    status match {
      case Query_Operation.Status.WAITING =>
        process_indicator.update("Waiting for evaluation of context ...", 5)
      case Query_Operation.Status.RUNNING =>
        process_indicator.update("Running find operation ...", 15)
      case Query_Operation.Status.FINISHED =>
        process_indicator.update(null, 0)
    }
  }


  /* find theorems */

  private val find_theorems = new Find_Dockable.Operation
  {
    val pretty_text_area = new Pretty_Text_Area(view)


    /* query */

    private val process_indicator = new Process_Indicator

    val query_operation =
      new Query_Operation(PIDE.editor, view, "find_theorems",
        consume_status(process_indicator, _),
        (snapshot, results, body) =>
          pretty_text_area.update(snapshot, results, Pretty.separate(body)))

    private def apply_query()
    {
      query_operation.apply_query(List(limit.text, allow_dups.selected.toString, query.getText))
    }

    private val query_label = new Label("Search criteria:") {
      tooltip =
        GUI.tooltip_lines(
          "Search criteria for find operation, e.g.\n\"_ = _\" \"op +\" name: Group -name: monoid")
    }

    val query = make_query("isabelle-find-theorems", query_label.tooltip, apply_query _)


    /* controls */

    private val limit = new TextField(PIDE.options.int("find_theorems_limit").toString, 5) {
      tooltip = "Limit of displayed results"
      verifier = (s: String) =>
        s match { case Properties.Value.Int(x) => x >= 0 case _ => false }
      listenTo(keys)
      reactions += { case KeyPressed(_, Key.Enter, 0, _) => apply_query() }
    }

    private val allow_dups = new CheckBox("Duplicates") {
      tooltip = "Show all versions of matching theorems"
      selected = false
    }

    private val apply_button = new Button("Apply") {
      tooltip = "Find theorems meeting specified criteria"
      reactions += { case ButtonClicked(_) => apply_query() }
    }


    /* GUI page */

    private val controls: List[Component] =
      List(query_label, Component.wrap(query), limit, allow_dups,
        process_indicator.component, apply_button, zoom)

    val page =
      new TabbedPane.Page("Theorems", new BorderPanel {
        add(new Wrap_Panel(Wrap_Panel.Alignment.Right)(controls:_*), BorderPanel.Position.North)
        add(Component.wrap(pretty_text_area), BorderPanel.Position.Center)
      }, apply_button.tooltip)
  }


  /* operations */

  private val operations = List(find_theorems)

  private val tabs = new TabbedPane { for (op <- operations) pages += op.page }
  set_content(tabs)

  override def focusOnDefaultComponent {
    try { operations(tabs.selection.index).query.requestFocus }
    catch { case _: IndexOutOfBoundsException => }
  }


  /* resize */

  private def handle_resize(): Unit =
    Swing_Thread.require {
      for (op <- operations) {
        op.pretty_text_area.resize(
          Font_Info.main(PIDE.options.real("jedit_font_scale") * zoom_factor / 100))
      }
    }

  private val delay_resize =
    Swing_Thread.delay_first(PIDE.options.seconds("editor_update_delay")) { handle_resize() }

  addComponentListener(new ComponentAdapter {
    override def componentResized(e: ComponentEvent) { delay_resize.invoke() }
  })


  /* main */

  private val main =
    Session.Consumer[Session.Global_Options](getClass.getName) {
      case _: Session.Global_Options => Swing_Thread.later { handle_resize() }
    }

  override def init()
  {
    PIDE.session.global_options += main
    handle_resize()
    operations.foreach(op => op.query_operation.activate())
  }

  override def exit()
  {
    operations.foreach(op => op.query_operation.deactivate())
    PIDE.session.global_options -= main
    delay_resize.revoke()
  }
}

