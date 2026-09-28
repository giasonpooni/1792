extends Node3D
## First bounded Mahan beat: delayed scout report + column order + fixed historical endpoint frame.
## Epistemic fence: Mahan memories never migrate into childhood/Lahore authorities.
const Model := preload("res://mahan/mahan_state.gd")
const PlayerScene := preload("res://player/player.tscn")
const SAVE := "user://1792-mahan-v1.json"
var campaign = Model.new()
var avatar: CharacterBody3D
var _hud: Label
var _modal: PanelContainer
var _actions: VBoxContainer
var _notice := "Walk to the delayed scout at the camp edge and press E."
var _paused := false

func _ready() -> void:
	_build_world()
	_build_ui()
	avatar = PlayerScene.instantiate()
	avatar.set("menu_shortcut", false)
	add_child(avatar)
	avatar.global_position = campaign.position()
	_refresh()

func _physics_process(delta: float) -> void:
	if _paused or _modal.visible:
		return
	var err: String = campaign.record_position(avatar.global_position, delta)
	if err.is_empty():
		campaign.advance()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E:
			if not _modal.visible:
				_interact()
		KEY_J:
			_open_journal()
		KEY_F1:
			_open_panel("Paused", "Separate Mahan interlude. Returning to the menu discards unsaved changes.\nChildhood and Lahore saves are never written from this profile.", [
				["Resume", "close"], ["Save and resume", "save"], ["Journal", "journal"], ["Main menu (discard unsaved progress)", "menu"]
			])
		KEY_F5:
			_notice = "Saved." if campaign.save_to(SAVE).is_empty() else "Save failed."
		KEY_F9:
			var error: String = campaign.load_from(SAVE)
			if error.is_empty():
				avatar.global_position = campaign.position()
				_notice = "Loaded Mahan save."
			else:
				_notice = error
		KEY_ESCAPE:
			if _modal.visible:
				_close()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_:
			return
	get_viewport().set_input_as_handled()
	_refresh()

func _interact() -> void:
	campaign.record_position(avatar.global_position, 1.0 / 60.0)
	match campaign.stage():
		"await_report":
			var err: String = campaign.hear_scout_report()
			_notice = "Scout report remembered." if err.is_empty() else err
			if err.is_empty():
				_notice = "Return to the camp table and press E to order the column."
		"decision":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table to issue the column order."
				return
			_open_panel("Column order", "You have one delayed scout report. The fort road is still unverified.\nChoose a subordinate command; this does not rewrite Mahan's fixed historical endpoint.", [
				["Advance a scout detachment", "advance_scouts"],
				["Hold the column for corroboration", "hold_for_corroboration"],
				["Cancel", "close"]
			])
		"endpoint":
			var err2: String = campaign.acknowledge_fixed_endpoint()
			_notice = "Interlude beat closed. Historical endpoint remains fixed." if err2.is_empty() else err2
		"closed":
			_notice = "This first Mahan beat is complete. Childhood and Lahore saves remain separate."
		_:
			_notice = "No interaction here."

func _open_journal() -> void:
	var lines: PackedStringArray = ["MAHAN SINGH — attributed field memories (not Buddh Singh knowledge)\n"]
	for memory in campaign.journal():
		lines.append("[%s · %s · tick %s]\n%s\n" % [memory.source_id, memory.channel, str(memory.received_tick), memory.text])
	if campaign.journal().is_empty():
		lines.append("(none yet)")
	_open_panel("Field journal", "\n".join(lines), [["Close", "close"]])

func _perform(action: String) -> void:
	match action:
		"close":
			_close()
		"save":
			_notice = "Saved." if campaign.save_to(SAVE).is_empty() else "Save failed."
			_close()
		"journal":
			_close()
			_open_journal()
		"advance_scouts", "hold_for_corroboration":
			var err: String = campaign.decide_column(action)
			_notice = "Column order recorded. Press E at the table to acknowledge the fixed endpoint." if err.is_empty() else err
			_close()
		"menu":
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_:
			_close()

func _build_world() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 35, 0)
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3d4a3a")
	ground.material_override = mat
	add_child(ground)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 0.2, 40)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	body.add_child(col)
	add_child(body)
	_marker(Model.SITES.camp_table, Color("c4a35a"), "Camp table")
	_marker(Model.SITES.scout, Color("7a9bb0"), "Delayed scout")
	_marker(Model.SITES.column_mark, Color("8b6b4a"), "Horse column")

func _marker(p: Vector3, color: Color, label_text: String) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	mesh.position = p + Vector3(0, 0.5, 0)
	add_child(mesh)
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 48
	label.position = p + Vector3(0, 1.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(24, 18)
	_hud.size = Vector2(900, 160)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)
	_modal = PanelContainer.new()
	_modal.visible = false
	_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_modal.custom_minimum_size = Vector2(620, 320)
	layer.add_child(_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_modal.add_child(box)
	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var body := Label.new()
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	_actions = VBoxContainer.new()
	_actions.name = "Actions"
	box.add_child(_actions)

func _open_panel(title_text: String, body_text: String, actions: Array) -> void:
	_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_modal.visible = true
	var root_box: VBoxContainer = _modal.get_child(0)
	root_box.get_child(0).text = title_text
	root_box.get_child(1).text = body_text
	for child in _actions.get_children():
		child.queue_free()
	for item in actions:
		var button := Button.new()
		button.text = item[0]
		var action: String = item[1]
		button.pressed.connect(func(): _perform(action))
		_actions.add_child(button)

func _close() -> void:
	_modal.visible = false
	_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh() -> void:
	var s: Dictionary = campaign.snapshot()
	var stage: String = campaign.stage()
	_hud.text = "1790 · Mahan Singh · Field camp (interlude skeleton)\nStage: %s · Tick: %d\n%s\nE interact · J journal · F5/F9 save/load · Esc menu cursor\nEpistemic fence: this journal never fills Buddh Singh's childhood/Lahore knowledge." % [
		stage, int(s.mahan.tick), _notice
	]
