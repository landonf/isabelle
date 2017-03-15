/*  Title:      Tools/jEdit/src/plugin.scala
    Author:     Makarius

Main plumbing for PIDE infrastructure as jEdit plugin.
*/

package isabelle.jedit


import isabelle._

import javax.swing.JOptionPane

import java.io.{File => JFile}

import org.gjt.sp.jedit.{jEdit, EBMessage, EBPlugin, Buffer, View, Debug, PerspectiveManager}
import org.gjt.sp.jedit.textarea.JEditTextArea
import org.gjt.sp.jedit.syntax.ModeProvider
import org.gjt.sp.jedit.msg.{EditorStarted, BufferUpdate, EditPaneUpdate, PropertiesChanged}
import org.gjt.sp.util.SyntaxUtilities
import org.gjt.sp.util.Log


object PIDE
{
  /* plugin instance */

  @volatile var _plugin: Plugin = null

  def plugin: Plugin =
    if (_plugin == null) error("Uninitialized Isabelle/jEdit plugin")
    else _plugin

  def options: JEdit_Options = plugin.options
  def resources: JEdit_Resources = plugin.resources
  def session: Session = plugin.session


  /* semantic document content */

  def snapshot(view: View): Document.Snapshot = GUI_Thread.now
  {
    Document_Model.get(view.getBuffer) match {
      case Some(model) => model.snapshot
      case None => error("No document model for current buffer")
    }
  }

  def rendering(view: View): JEdit_Rendering = GUI_Thread.now
  {
    val text_area = view.getTextArea
    Document_View.get(text_area) match {
      case Some(doc_view) => doc_view.get_rendering()
      case None => error("No document view for current text area")
    }
  }
}


class Plugin extends EBPlugin
{
  /* options */

  private var _options: JEdit_Options = null
  private def init_options(): Unit = _options = new JEdit_Options(Options.init())
  def options: JEdit_Options = _options


  /* resources */

  private var _resources: JEdit_Resources = null
  private def init_resources()
  {
    val options = this.options.value
    val session_name = JEdit_Sessions.session_name(options)
    val session_base =
      try { Sessions.session_base(options, session_name, JEdit_Sessions.session_dirs()) }
      catch { case ERROR(_) => Sessions.pure_base(options) }

    _resources =
      new JEdit_Resources(session_base.copy(known_theories =
        for ((a, b) <- session_base.known_theories) yield (a, b.map(File.platform_path(_)))))
  }
  def resources: JEdit_Resources = _resources


  /* session */

  private var _session: Session = null
  private def init_session()
  {
    _session =
      new Session(resources) {
        override def output_delay = options.seconds("editor_output_delay")
        override def prune_delay = options.seconds("editor_prune_delay")
        override def syslog_limit = options.int("editor_syslog_limit")
        override def reparse_limit = options.int("editor_reparse_limit")
      }
  }
  def session: Session = _session


  /* misc support */

  val completion_history = new Completion.History_Variable
  val spell_checker = new Spell_Checker_Variable


  /* global changes */

  def options_changed()
  {
    session.global_options.post(Session.Global_Options(options.value))
    delay_load.invoke()
  }

  def deps_changed()
  {
    delay_load.invoke()
  }


  /* theory files */

  lazy val delay_init =
    GUI_Thread.delay_last(options.seconds("editor_load_delay"))
    {
      init_models()
    }

  private val delay_load_active = Synchronized(false)
  private def delay_load_activated(): Boolean =
    delay_load_active.guarded_access(a => Some((!a, true)))
  private def delay_load_action()
  {
    if (Isabelle.continuous_checking && delay_load_activated() &&
        PerspectiveManager.isPerspectiveEnabled)
    {
      if (JEdit_Lib.jedit_buffers().exists(_.isLoading)) delay_load.invoke()
      else {
        val required_files =
        {
          val models = Document_Model.get_models()

          val thys =
            (for ((node_name, model) <- models.iterator if model.is_theory)
              yield (node_name, Position.none)).toList
          val thy_files = resources.thy_info.dependencies("", thys).deps.map(_.name)

          val aux_files =
            if (options.bool("jedit_auto_resolve")) {
              val stable_tip_version =
                if (models.forall(p => p._2.is_stable))
                  session.current_state().stable_tip_version
                else None
              stable_tip_version match {
                case Some(version) => resources.undefined_blobs(version.nodes)
                case None => delay_load.invoke(); Nil
              }
            }
            else Nil

          (thy_files ::: aux_files).filterNot(models.isDefinedAt(_))
        }
        if (required_files.nonEmpty) {
          try {
            Standard_Thread.fork("resolve_dependencies") {
              val loaded_files =
                for {
                  name <- required_files
                  text <- resources.read_file_content(name)
                } yield (name, text)

              GUI_Thread.later {
                try {
                  Document_Model.provide_files(session, loaded_files)
                  delay_init.invoke()
                }
                finally { delay_load_active.change(_ => false) }
              }
            }
          }
          catch { case _: Throwable => delay_load_active.change(_ => false) }
        }
        else delay_load_active.change(_ => false)
      }
    }
  }

  private lazy val delay_load =
    GUI_Thread.delay_last(options.seconds("editor_load_delay")) { delay_load_action() }

  private def file_watcher_action(changed: Set[JFile]): Unit =
    if (Document_Model.sync_files(changed)) JEdit_Editor.invoke_generated()

  lazy val file_watcher: File_Watcher =
    File_Watcher(file_watcher_action _, options.seconds("editor_load_delay"))


  /* session phase */

  val session_phase_changed: Session.Phase => Unit =
  {
    case Session.Terminated(_) =>
      GUI_Thread.later {
        GUI.error_dialog(jEdit.getActiveView, "Prover process terminated",
          "Isabelle Syslog", GUI.scrollable_text(session.syslog_content()))
      }

    case Session.Ready =>
      session.update_options(options.value)
      init_models()

      if (!Isabelle.continuous_checking) {
        GUI_Thread.later {
          val answer =
            GUI.confirm_dialog(jEdit.getActiveView,
              "Continuous checking of PIDE document",
              JOptionPane.YES_NO_OPTION,
              "Continuous checking is presently disabled:",
              "editor buffers will remain inactive!",
              "Enable continuous checking now?")
          if (answer == 0) Isabelle.continuous_checking = true
        }
      }

      delay_load.invoke()

    case Session.Shutdown =>
      GUI_Thread.later {
        delay_load.revoke()
        delay_init.revoke()
        JEdit_Editor.flush()
        exit_models(JEdit_Lib.jedit_buffers().toList)
      }

    case _ =>
  }


  /* document model and view */

  def exit_models(buffers: List[Buffer])
  {
    GUI_Thread.now {
      buffers.foreach(buffer =>
        JEdit_Lib.buffer_lock(buffer) {
          JEdit_Lib.jedit_text_areas(buffer).foreach(Document_View.exit)
          Document_Model.exit(buffer)
        })
      }
  }

  def init_models()
  {
    GUI_Thread.now {
      JEdit_Editor.flush()

      for {
        buffer <- JEdit_Lib.jedit_buffers()
        if buffer != null && !buffer.getBooleanProperty(Buffer.GZIPPED)
      } {
        if (buffer.isLoaded) {
          JEdit_Lib.buffer_lock(buffer) {
            val node_name = resources.node_name(buffer)
            val model = Document_Model.init(session, node_name, buffer)
            for {
              text_area <- JEdit_Lib.jedit_text_areas(buffer)
              if Document_View.get(text_area).map(_.model) != Some(model)
            } Document_View.init(model, text_area)
          }
        }
        else delay_init.invoke()
      }

      JEdit_Editor.invoke_generated()
    }
  }

  def init_view(buffer: Buffer, text_area: JEditTextArea): Unit =
    GUI_Thread.now {
      JEdit_Lib.buffer_lock(buffer) {
        Document_Model.get(buffer) match {
          case Some(model) => Document_View.init(model, text_area)
          case None =>
        }
      }
    }

  def exit_view(buffer: Buffer, text_area: JEditTextArea): Unit =
    GUI_Thread.now {
      JEdit_Lib.buffer_lock(buffer) {
        Document_View.exit(text_area)
      }
    }


  /* main plugin plumbing */

  @volatile private var startup_failure: Option[Throwable] = None
  @volatile private var startup_notified = false

  override def handleMessage(message: EBMessage)
  {
    GUI_Thread.assert {}

    if (startup_failure.isDefined && !startup_notified) {
      message match {
        case msg: EditorStarted =>
          GUI.error_dialog(null, "Isabelle plugin startup failure",
            GUI.scrollable_text(Exn.message(startup_failure.get)),
            "Prover IDE inactive!")
          startup_notified = true
        case _ =>
      }
    }

    if (startup_failure.isEmpty) {
      message match {
        case msg: EditorStarted =>
          if (Distribution.is_identified && !Distribution.is_official) {
            GUI.warning_dialog(jEdit.getActiveView, "Isabelle version for testing",
              "This is " + Distribution.version + ".",
              "It is for testing only, not for production use.")
          }

          val view = jEdit.getActiveView()

          Session_Build.check_dialog(view)

          Keymap_Merge.check_dialog(view)

          JEdit_Editor.hyperlink_position(true, Document.Snapshot.init,
            JEdit_Sessions.session_info(options.value).open_root).foreach(_.follow(view))

        case msg: BufferUpdate
        if msg.getWhat == BufferUpdate.LOAD_STARTED || msg.getWhat == BufferUpdate.CLOSING =>
          if (msg.getBuffer != null) {
            exit_models(List(msg.getBuffer))
            JEdit_Editor.invoke_generated()
          }

        case msg: BufferUpdate
        if msg.getWhat == BufferUpdate.PROPERTIES_CHANGED || msg.getWhat == BufferUpdate.LOADED =>
          if (session.is_ready) {
            delay_init.invoke()
            delay_load.invoke()
          }

        case msg: EditPaneUpdate
        if msg.getWhat == EditPaneUpdate.BUFFER_CHANGING ||
            msg.getWhat == EditPaneUpdate.BUFFER_CHANGED ||
            msg.getWhat == EditPaneUpdate.CREATED ||
            msg.getWhat == EditPaneUpdate.DESTROYED =>
          val edit_pane = msg.getEditPane
          val buffer = edit_pane.getBuffer
          val text_area = edit_pane.getTextArea

          if (buffer != null && text_area != null) {
            if (msg.getWhat == EditPaneUpdate.BUFFER_CHANGED ||
                msg.getWhat == EditPaneUpdate.CREATED) {
              if (session.is_ready)
                init_view(buffer, text_area)
            }
            else {
              Isabelle.dismissed_popups(text_area.getView)
              exit_view(buffer, text_area)
            }

            if (msg.getWhat == EditPaneUpdate.CREATED)
              Completion_Popup.Text_Area.init(text_area)

            if (msg.getWhat == EditPaneUpdate.DESTROYED)
              Completion_Popup.Text_Area.exit(text_area)
          }

        case msg: PropertiesChanged =>
          for {
            view <- JEdit_Lib.jedit_views
            edit_pane <- JEdit_Lib.jedit_edit_panes(view)
          } {
            val buffer = edit_pane.getBuffer
            val text_area = edit_pane.getTextArea
            if (buffer != null && text_area != null) init_view(buffer, text_area)
          }

          spell_checker.update(options.value)
          session.update_options(options.value)

        case _ =>
      }
    }
  }


  /* mode provider */

  private var orig_mode_provider: ModeProvider = null
  private var pide_mode_provider: ModeProvider = null

  def init_mode_provider()
  {
    orig_mode_provider = ModeProvider.instance
    if (orig_mode_provider.isInstanceOf[ModeProvider]) {
      pide_mode_provider = new Token_Markup.Mode_Provider(orig_mode_provider)
      ModeProvider.instance = pide_mode_provider
    }
  }

  def exit_mode_provider()
  {
    if (ModeProvider.instance == pide_mode_provider)
      ModeProvider.instance = orig_mode_provider
  }


  /* start and stop */

  override def start()
  {
    Debug.DISABLE_SEARCH_DIALOG_POOL = true


    /* strict initialization */

    // adhoc patch of confusing message
    val orig_plugin_error = jEdit.getProperty("plugin-error.start-error")
    jEdit.setProperty("plugin-error.start-error", "Cannot start plugin:\n{0}")

    init_options()
    init_resources()
    init_session()
    PIDE._plugin = this

    jEdit.setProperty("plugin-error.start-error", orig_plugin_error)


    /* non-strict initialization */

    try {
      completion_history.load()
      spell_checker.update(options.value)

      SyntaxUtilities.setStyleExtender(Syntax_Style.Extender)
      init_mode_provider()
      JEdit_Lib.jedit_text_areas.foreach(Completion_Popup.Text_Area.init _)

      startup_failure = None
    }
    catch {
      case exn: Throwable =>
        startup_failure = Some(exn)
        startup_notified = false
        Log.log(Log.ERROR, this, exn)
    }
  }

  override def stop()
  {
    SyntaxUtilities.setStyleExtender(Syntax_Style.No_Extender)
    exit_mode_provider()
    JEdit_Lib.jedit_text_areas.foreach(Completion_Popup.Text_Area.exit _)

    if (startup_failure.isEmpty) {
      options.value.save_prefs()
      completion_history.value.save()
    }

    exit_models(JEdit_Lib.jedit_buffers().toList)
    session.stop()
    file_watcher.shutdown()

    PIDE._plugin = null
  }
}
