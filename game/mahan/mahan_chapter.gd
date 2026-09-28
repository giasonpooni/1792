extends Node3D
## Mahan beat: delayed scout custody + column march on authored nodes + fixed endpoint.
## Epistemic fence: Mahan memories never migrate into childhood/Lahore authorities.
const Model := preload("res://mahan/mahan_state.gd")
const PlayerScene := preload("res://player/player.tscn")
const SAVE := "user://1792-mahan-v1.json"
var campaign = Model.new()
var avatar: CharacterBody3D
var _hud: Label
var _modal: PanelContainer
var _actions: VBoxContainer
var _notice := "At the camp table, press E to dispatch a scout detachment. Reports arrive on a delay clock."
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
		"recon":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table to dispatch scouts, or wait for a pending report to arrive."
				return
			_open_dispatch_panel()
		"decision":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table once scout custody has been delivered."
				return
			var body := "Delivered scout reports: %d. Pending: %d.\nPlayer knowledge updates only when a detachment returns.\nChoose a subordinate command; this does not rewrite Mahan's fixed historical endpoint." % [
				campaign.received_reports().size(), campaign.pending_reports().size()
			]
			_open_panel("Column order", body, [
				["Advance the horse column", "advance_scouts"],
				["Hold the column for corroboration", "hold_for_corroboration"],
				["Dispatch another scout", "open_dispatch"],
				["Cancel", "close"]
			])
		"march":
			_open_march_panel()
		"closed":
			_notice = "This Mahan beat is complete. Childhood and Lahore saves remain separate."
		_:
			_notice = "No interaction here."

func _open_dispatch_panel() -> void:
	var lines := "Dispatch a scout detachment. The report is not knowledge until it arrives (delay %d ticks).\nProvisions: %d.\nTargets include the ford/ridge line and the Gujranwala home-ground approach." % [Model.REPORT_DELAY, campaign.provisions()]
	var actions: Array = []
	for target in Model.scout_targets():
		actions.append(["Scout the %s (−%d provisions)" % [Model.node_label(target), Model.DISPATCH_COST], "dispatch_%s" % target])
	actions.append(["Cancel", "close"])
	_open_panel("Scout dispatch", lines, actions)

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var body := "Column at: %s · Provisions: %d\nWalk to an adjacent authored node, then commit the march.\nYou may also acknowledge the fixed historical endpoint." % [node, campaign.provisions()]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in Model.ADJACENT[node]:
			actions.append(["March column to %s (−%d provisions)" % [nxt, Model.MARCH_COST], "march_%s" % nxt])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _open_journal() -> void:
	var lines: PackedStringArray = ["MAHAN SINGH — attributed field memories (not Buddh Singh knowledge)\n"]
	for memory in campaign.journal():
		lines.append("[%s · %s · tick %s]\n%s\n" % [memory.source_id, memory.channel, str(memory.received_tick), memory.text])
	if campaign.journal().is_empty():
		lines.append("(none yet — pending scout reports are not journal knowledge)")
	var pending: Array = campaign.pending_reports()
	if not pending.is_empty():
		lines.append("\nPENDING CUSTODY (not yet knowledge):")
		for report in pending:
			lines.append("- %s · arrives tick %s (no text until delivery)" % [report.target, str(report.arrives_at)])
	_open_panel("Field journal", "\n".join(lines), [["Close", "close"]])

func _perform(action: String) -> void:
	if action.begins_with("dispatch_"):
		var target := action.trim_prefix("dispatch_")
		var err: String = campaign.dispatch_scout(target)
		if err.is_empty():
			_notice = "Detachment sent to the %s. Knowledge updates only when the report arrives." % Model.node_label(target)
		else:
			_notice = err
		_close()
		return
	if action.begins_with("march_"):
		var dest := action.trim_prefix("march_")
		var err3: String = campaign.march_to(dest)
		if err3.is_empty():
			avatar.global_position = campaign.position()
			_notice = "Column marched to the %s." % Model.node_label(dest)
		else:
			_notice = err3
		_close()
		return
	match action:
		"close":
			_close()
		"save":
			_notice = "Saved." if campaign.save_to(SAVE).is_empty() else "Save failed."
			_close()
		"journal":
			_close()
			_open_journal()
		"open_dispatch":
			_close()
			_open_dispatch_panel()
		"advance_scouts", "hold_for_corroboration":
			var err2: String = campaign.decide_column(action)
			if err2.is_empty():
				_notice = "Column order recorded. Press E to march (if advancing) or acknowledge the fixed endpoint."
			else:
				_notice = err2
			_close()
		"ack_endpoint":
			var err4: String = campaign.acknowledge_fixed_endpoint()
			_notice = "Interlude beat closed. Historical endpoint remains fixed." if err4.is_empty() else err4
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
	plane.size = Vector2(48, 48)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3d4a3a")
	ground.material_override = mat
	add_child(ground)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(48, 0.2, 48)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	body.add_child(col)
	add_child(body)
	_marker(Model.SITES.camp_table, Color("c4a35a"), "Camp table")
	_marker(Model.SITES.camp, Color("8b6b4a"), "Column · camp")
	_marker(Model.SITES.ford, Color("5a7a8b"), "Ford")
	_marker(Model.SITES.ridge, Color("6b5a7a"), "Ridge")
	_marker(Model.SITES.gujranwala_fort_road, Color("7a6b4a"), "Gujranwala fort road")
	_marker(Model.SITES.gujranwala_camp, Color("8a5a4a"), "Gujranwala camp")
	_marker(Model.SITES.gujranwala_settlement, Color("9a4a3a"), "Gujranwala town")

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
	_hud.size = Vector2(980, 200)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)
	_modal = PanelContainer.new()
	_modal.visible = false
	_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_modal.custom_minimum_size = Vector2(640, 340)
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
	var pending: Array = campaign.pending_reports()
	var pending_txt := "none"
	if not pending.is_empty():
		var bits: PackedStringArray = []
		for report in pending:
			bits.append("%s@%d" % [report.target, int(report.arrives_at)])
		pending_txt = ", ".join(bits)
	_hud.text = "1790 · Mahan Singh · Field camp (recon + column)\nStage: %s · Tick: %d · Column: %s · Provisions: %d\nPending custody: %s · Delivered: %d · Known nodes: %s\n%s\nE interact · J journal · F5/F9 save/load · Esc menu cursor\nEpistemic fence: this journal never fills Buddh Singh's childhood/Lahore knowledge." % [
		stage, int(s.mahan.tick), str(s.mahan.column_node), int(s.mahan.provisions),
		pending_txt, campaign.received_reports().size(), ", ".join(PackedStringArray(campaign.known_nodes())),
		_notice
	]
