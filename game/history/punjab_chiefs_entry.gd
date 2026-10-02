# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Nearby input opens the catalogue; a choice launches an actual isolated visit.
const Session := preload("res://history/punjab_chiefs_session.gd")
const BENCH_POSITION := Vector3(-4.0, 0.14, 6.0)
const REACH := 3.0
const CATALOGUE := "res://history/punjab_chiefs_catalogue.json"
var chapter: Node3D
var _menu: CanvasLayer
var _panel: PanelContainer
var _status: Label
var _catalogue_open := false
var _prior_process := Node.PROCESS_MODE_INHERIT
var _prior_mouse := Input.MOUSE_MODE_VISIBLE
var _choices: Array = []
var _catalogue_audio: Array[Dictionary] = []

func _ready() -> void:
	chapter = get_parent().get_node("ChildhoodChapter")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_bench()
	_build_menu()

func _build_bench() -> void:
	var seat := MeshInstance3D.new()
	seat.name = "StoryBench"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 0.22, 0.65)
	seat.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("74523a")
	material.roughness = 0.95
	seat.material_override = material
	seat.position = BENCH_POSITION + Vector3(0, 0.45, 0)
	add_child(seat)
	for x in [-0.85, 0.85]:
		var leg := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.16, 0.4, 0.5)
		leg.mesh = shape
		leg.material_override = material
		leg.position = BENCH_POSITION + Vector3(x, 0.2, 0)
		add_child(leg)
	var label := Label3D.new()
	label.text = "Family tales · T"
	label.position = BENCH_POSITION + Vector3(0, 1.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.pixel_size = 0.002
	add_child(label)

func _build_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.name = "PunjabChiefsCatalogue"
	_menu.layer = 80
	add_child(_menu)
	var scrim := ColorRect.new()
	scrim.color = Color(0.025, 0.03, 0.035, 0.86)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(scrim)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 32
	_panel.offset_right = -32
	_panel.offset_top = 28
	_panel.offset_bottom = -28
	_menu.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "FAMILY TALES"
	heading.add_theme_font_size_override("font_size", 27)
	column.add_child(heading)
	var description := Label.new()
	description.text = "Choose a tale to enter. Your household waits while you play; each telling keeps its own choices."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var options := VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 8)
	scroll.add_child(options)
	var document = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	if document is Dictionary and document.get("sequences", null) is Array: _choices = document.sequences
	for record in _choices:
		if not record is Dictionary or str(record.get("id", "")) not in Session.SEQUENCES: continue
		var button := Button.new()
		button.name = "Story_" + str(record.id)
		button.text = str(record.get("title", record.id))
		button.custom_minimum_size.y = 46
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(str(record.id)))
		options.add_child(button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var resume := Button.new()
	resume.text = "Return to the courtyard · Esc"
	resume.custom_minimum_size.y = 42
	resume.pressed.connect(close_catalogue)
	column.add_child(resume)
	_menu.hide()

func nearby() -> bool:
	if not is_instance_valid(chapter) or not is_instance_valid(chapter.avatar): return false
	var offset: Vector3 = chapter.avatar.global_position - BENCH_POSITION
	if Vector2(offset.x, offset.z).length() > REACH: return false
	var from: Vector3 = chapter.avatar.global_position + Vector3.UP * 1.1
	var to := BENCH_POSITION + Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [chapter.avatar.get_rid(), chapter.horse.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	# A story overlay owns routed input. The bench must not process it a second time.
	if chapter.has_meta(Session.OWNER_META) or is_instance_valid(chapter.intro_session) or is_instance_valid(chapter.training_session): return
	if _catalogue_open:
		if event.keycode in [KEY_ESCAPE, KEY_T]:
			close_catalogue()
			get_viewport().set_input_as_handled()
		return
	if event.keycode != KEY_T or not nearby(): return
	var error := open_catalogue()
	if not error.is_empty():
		chapter._message = error
		chapter._refresh()
	get_viewport().set_input_as_handled()

func open_catalogue() -> String:
	if _catalogue_open: return "The family tales are already open."
	if not nearby(): return "Walk to the family story bench."
	var error := Session.entry_error(chapter)
	if not error.is_empty(): return error
	_prior_process = get_parent().process_mode
	_prior_mouse = Input.mouse_mode
	chapter._clear_pending_actions()
	chapter.avatar.clear_motion_requests()
	for node in get_parent().find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			_catalogue_audio.append({"node": node, "paused": node.stream_paused})
	get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	for record in _catalogue_audio: record.node.stream_paused = true
	_catalogue_open = true
	_menu.show()
	_status.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var first := _menu.find_child("Story_*", true, false) as Button
	if first != null: first.grab_focus()
	return ""

func close_catalogue() -> void:
	if not _catalogue_open: return
	_catalogue_open = false
	_menu.hide()
	if is_instance_valid(get_parent()): get_parent().process_mode = _prior_process
	for record in _catalogue_audio:
		if is_instance_valid(record.node): record.node.stream_paused = record.paused
	_catalogue_audio.clear()
	Input.mouse_mode = _prior_mouse
	if is_instance_valid(chapter):
		chapter._clear_pending_actions()
		chapter.avatar.clear_motion_requests()

func _choose(id: String) -> void:
	if not _catalogue_open: return
	close_catalogue()
	var session := Session.new()
	session.name = "PunjabChiefsStorySession"
	get_tree().root.add_child(session)
	var error := session.start_story(chapter, id)
	if error.is_empty(): return
	session.queue_free()
	var reopened := open_catalogue()
	if reopened.is_empty(): _status.text = error
	else:
		chapter._message = error
		chapter._refresh()

func _exit_tree() -> void:
	close_catalogue()
