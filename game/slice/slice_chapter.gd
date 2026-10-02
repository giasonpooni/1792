# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://workshops/home_workshop_chapter.gd"
## Slice presentation and durable visits on the existing controller/model/motor/clock.
const Continuation := preload("res://slice/continuation_store.gd")
const Guide := preload("res://slice/route_guide.gd")
const AUTOSAVE_TICKS := 1800
var startup_mode:="new"
var continuation_path:=Continuation.PATH
var run_id:=Continuation.new_run_id()
var continuation_ready:=false
var _last_continuation_tick:=-1
var _exit_action:=""
var _prior_auto_quit:=true

func _init() -> void:
	model=WorkshopState.new()
	save_path=Continuation.manual_path(run_id)

func _ready() -> void:
	super._ready()
	_prior_auto_quit=get_tree().auto_accept_quit;get_tree().auto_accept_quit=false
	_show_dialog("GUJRANWALA · VERTICAL SLICE 0.1","Preparing the Home courtyard.",[])
	_finish_startup.call_deferred()

func _finish_startup() -> void:
	# Native collision structures must exist before the physical restore gate runs.
	await get_tree().physics_frame;await get_tree().physics_frame
	if startup_mode=="continue":
		var error:=restore_continuation()
		if not error.is_empty():
			_show_dialog("CONTINUE NOT RESTORED",error+"\nYour saved continuation is unchanged.",[["Return to menu","slice:abandon"]])
			return
	elif startup_mode!="new":
		_show_dialog("SLICE NOT STARTED","Unknown launch mode.",[["Return to menu","slice:abandon"]]);return
	else:
		continuation_ready=true
		var error:=save_continuation()
		if not error.is_empty():
			continuation_ready=false
			_show_dialog("CONTINUATION NOT CREATED",error+"\nThe previous continuation is unchanged.",[["Return to menu","slice:abandon"]]);return
	_message="Gujranwala · Home, its obligations, and a short walk. O opens your route."
	_show_dialog("GUJRANWALA · VERTICAL SLICE 0.1",Guide.text(model),[["Continue in the courtyard","resume"],["Save and return to menu","menu"]])

func restore_continuation() -> String:
	var result:=Continuation.read(continuation_path)
	var error: String=result.error
	var staged:=WorkshopState.new()
	if error.is_empty(): error=staged.restore(result.envelope.snapshot)
	if error.is_empty(): error=_candidate_error(staged)
	if not error.is_empty(): return error
	error=model.restore(staged.snapshot())
	if not error.is_empty(): return error
	run_id=result.envelope.run_id;save_path=Continuation.manual_path(run_id)
	_apply();avatar.pivot.rotation=Vector3(result.envelope.camera[0],result.envelope.camera[1],0)
	_clear_pending_actions();continuation_ready=true;_last_continuation_tick=int(model.progress().tick)
	_checkpoint_note="A checkpoint file is available. R validates and restores it." if FileAccess.file_exists(checkpoint_path()) else "No checkpoint yet. F5 keeps a separate manual save for this run."
	return ""

func save_continuation() -> String:
	if not continuation_ready: return "This visit has no accepted continuation to save."
	var error:=_candidate_error(model)
	if error.is_empty(): error=Continuation.write(continuation_path,run_id,model.snapshot(),avatar.pivot.rotation)
	if error.is_empty(): _last_continuation_tick=int(model.progress().tick)
	return error

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_O:
		if continuation_ready: _show_dialog("GUJRANWALA · YOUR ROUTE",Guide.text(model),[["Return to the courtyard","resume"],["Save and return to menu","menu"]])
		get_viewport().set_input_as_handled();return
	if not continuation_ready: return
	super._unhandled_input(event)

func _menu_action(action: String) -> void:
	if action=="slice:abandon" and not continuation_ready:
		_exit_action="abandon";return
	if action=="menu": _exit_action="menu";return
	super._menu_action(action)

func _clear_pending_actions() -> void:
	super._clear_pending_actions();_exit_action=""

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		_exit_action="quit" if continuation_ready else "abandon_quit"

func _exit_tree() -> void:
	if get_tree()!=null: get_tree().auto_accept_quit=_prior_auto_quit

func _physics_process(delta: float) -> void:
	if not _exit_action.is_empty():
		var action:=_exit_action;_exit_action=""
		var error:="" if action.begins_with("abandon") else save_continuation()
		if not error.is_empty():
			_show_dialog("VISIT NOT SAVED",error+"\nStay in the courtyard and retry saving before leaving.",[["Return","resume"],["Retry save and return to menu","menu"]]);return
		if action in ["quit","abandon_quit"]: get_tree().quit()
		else: get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		return
	if not continuation_ready: return
	super._physics_process(delta)
	var tick:=int(model.progress().tick)
	if tick<_last_continuation_tick: _last_continuation_tick=tick
	if not _paused and tick-_last_continuation_tick>=AUTOSAVE_TICKS:
		# Jump/vault poses can be admitted motion without being a safe standing restore.
		# Wait for a physical save point rather than interrupting the jump with a modal.
		if not _candidate_error(model).is_empty(): return
		var error:=save_continuation()
		if not error.is_empty():
			_last_continuation_tick=tick # Do not retry filesystem writes every native frame.
			_show_dialog("CONTINUATION NOT SAVED",error+"\nYour earlier continuation remains available.",[["Return","resume"],["Retry save and return to menu","menu"]])

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud): return
	var task: String=Guide.inspect(model).next
	if model.aftermath_phase()!="complete":
		# Retain the current inherited lesson and its counters while removing developer
		# discovery keys from the gameplay view. They remain in their existing panels.
		var paragraphs:=_hud.text.split("\n\n")
		if paragraphs.size()>1: task=paragraphs[1]
	var cargo:=""
	if model.has_water_round():
		var water: Dictionary=model.water_round().ledger
		if water.phase=="drawing": cargo="\nDrawing · %.1f seconds remaining"%[maxi(0,int(water.started_tick)+Water.DRAW_TICKS-int(model.progress().tick))/60.0]
		elif water.carried>0: cargo="\nWater · %d carried · %d returned"%[water.carried,water.stored]
	_hud.text="1792 · GUJRANWALA\n\n"+task+cargo+"\n\nWASD / Mouse · E speak · F horse · Q guard · O route · J journal"

func _open_journal() -> void:
	super._open_journal()
	_panel_text.text+="\n\nCOURTYARD CONTROLS\nO route · F5/F9 manual save/load · R checkpoint · F6 sound\nF2 research notebook · F4 peripheral frame · F7 visual comparison\nContinue saves your visit every 30 seconds of active play and when returning to the menu."
	for button in _actions.get_children():
		if button.text.begins_with("Main menu"): button.text="Save this visit and return to menu"
