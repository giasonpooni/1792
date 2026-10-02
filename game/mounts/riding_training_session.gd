# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends CanvasLayer
## Parks the existing Home in-tree. Only the isolated lesson owns execution.
const Lesson:=preload("res://mounts/horsecraft_training.tscn")
var chapter: Node3D
var world: Node3D
var lesson: Node3D
var viewport: SubViewport
var present_sha256: String
var practice_mode: String
var _prior_process_mode: int
var _prior_mouse_mode: int
var _present_parked:=false
var _parent_viewport: Viewport
var _prior_disable_3d:=false
var _drawing_suspended:=false
var _hidden_layers: Array[Dictionary]=[]
var _audio: Array[Dictionary]=[]
var _finished:=false

func start_training(host: Node3D,practice: String="") -> String:
	if is_instance_valid(chapter): return "A riding lesson is already active."
	if practice not in ["","single","pair"]: return "Unknown riding practice formation."
	if not practice.is_empty() and not host.model.has_riding_skill("single_standing" if practice=="single" else "paired_standing"):
		return "Complete the remembered riding lesson before practising that skill."
	var error: String=host.training_entry_error()
	if not error.is_empty(): return error
	practice_mode=practice
	_park_present(host)
	_build_isolated_viewport("RidingLessonViewport")
	lesson=Lesson.instantiate();lesson.configure_binding(present_sha256,int(chapter.model.progress().tick))
	if not practice_mode.is_empty(): lesson.configure_practice(practice_mode,chapter.model.capabilities())
	lesson.return_requested.connect(_return_requested)
	viewport.add_child(lesson)
	return ""

func _park_present(host: Node3D) -> void:
	# The intro and riding lesson share the same retained-world lifecycle.
	chapter=host;world=host.get_parent();present_sha256=chapter.model.present_sha256()
	_prior_process_mode=world.process_mode
	_prior_mouse_mode=Input.mouse_mode
	_present_parked=true
	chapter._clear_pending_actions();chapter.avatar.clear_motion_requests()
	for node in world.find_children("*","CanvasLayer",true,false):
		_hidden_layers.append({"node":node,"visible":node.visible});node.hide()
	for node in world.find_children("*","",true,false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			_audio.append({"node":node,"paused":node.stream_paused})
	# Preserve original flags before process-mode notifications affect audio;
	# apply the pause after disabling inherited execution.
	world.process_mode=Node.PROCESS_MODE_DISABLED
	for item in _audio:
		item.node.stream_paused=true
	_parent_viewport=get_viewport();_prior_disable_3d=_parent_viewport.disable_3d
	_parent_viewport.disable_3d=true;_drawing_suspended=true
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=100

func _build_isolated_viewport(viewport_name: String) -> void:
	viewport=SubViewport.new();viewport.name=viewport_name
	viewport.size=Vector2i(1280,720);viewport.own_world_3d=true
	viewport.handle_input_locally=true;viewport.audio_listener_enable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var display:=TextureRect.new();display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.texture=viewport.get_texture();display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	display.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(display)

func _input(event: InputEvent) -> void:
	if _finished or not is_instance_valid(viewport): return
	viewport.push_input(event,true)
	get_viewport().set_input_as_handled()

func _return_requested(completed: bool) -> void:
	finish.call_deferred(completed)

func finish(completed: bool) -> String:
	if _finished or not is_instance_valid(chapter): return "The riding lesson has already returned."
	if chapter.model.present_sha256()!=present_sha256:
		lesson.set_paused(true)
		lesson.message="The retained lesson changed; the return cannot merge these states."
		lesson._refresh();return lesson.message
	if completed:
		var receipt: Dictionary=lesson.completion_receipt()
		if receipt.is_empty(): return "Complete all three riding exercises before claiming the skills."
		if not chapter.model.has_riding_skill("mounted_matchlock"):
			var error: String=chapter.model.accept_riding_training(receipt,present_sha256)
			if not error.is_empty(): return error
	_finished=true
	_restore_host()
	chapter.training_session=null
	chapter._message="Standing riding, paired standing riding and mounted matchlock firing learned." if completed else "Riding practice ended; your learned skills are retained." if not practice_mode.is_empty() else "Returned to the riding lesson. No new skills were learned."
	chapter._clear_pending_actions();chapter.avatar.clear_motion_requests();chapter._resume()
	if is_instance_valid(lesson.shot_sound): lesson.shot_sound.stop();lesson.shot_sound.stream=null
	queue_free()
	return ""

func _restore_host() -> void:
	# Rejected or never-started visits own no flags; a returned visit must not
	# reclaim input from a later Home menu during repeated scene cleanup.
	if not _present_parked: return
	_present_parked=false
	_restore_drawing()
	Input.mouse_mode=_prior_mouse_mode
	if is_instance_valid(world): world.process_mode=_prior_process_mode
	for item in _hidden_layers:
		if is_instance_valid(item.node): item.node.visible=item.visible
	for item in _audio:
		if is_instance_valid(item.node): item.node.stream_paused=item.paused
	_hidden_layers.clear();_audio.clear()

func _restore_drawing() -> void:
	if _drawing_suspended and is_instance_valid(_parent_viewport): _parent_viewport.disable_3d=_prior_disable_3d
	_drawing_suspended=false;_parent_viewport=null

func abandon() -> void:
	_restore_drawing();_present_parked=false;_finished=true;chapter=null;world=null;queue_free()

func _exit_tree() -> void:
	if not _finished: _restore_host()
	_restore_drawing()
	chapter=null;world=null;lesson=null;viewport=null
