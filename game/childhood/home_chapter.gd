extends Node3D
## Home tutorial controller. Reuses the original player and horse physics.
## No Lahore clock/order execution runs while this chapter is loaded.
const Model := preload("res://childhood/childhood_state.gd")
const Horse := preload("res://mounts/horse.tscn")
const Names := preload("res://characters/character_names.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const Story := preload("res://childhood/aftermath_state.gd")
const Checkpoint := preload("res://childhood/checkpoint_store.gd")
const GatePassage := preload("res://presentation/gate_passage.gd")
const EscortAgent := preload("res://patrol/patrol_agent.gd")
const Navigation := preload("res://patrol/patrol_navigator.gd")
var model := Story.new()
var save_path := Story.AFTER_SAVE # checkpoints derive from this path; tests stay isolated
var avatar: CharacterBody3D
var horse: CharacterBody3D
var attacker: CharacterBody3D
var trainer: MeshInstance3D
var guard_visual: MeshInstance3D
var _hud: Label
var _caption: Label
var _panel: PanelContainer
var _panel_text: Label
var _journal_scroll: ScrollContainer
var _marker: Label3D
var _veil: ColorRect
var _paused := false
var _interact_requested := false
var _mount_requested := false
var _strike_requested := false
var _load_requested := false
var _save_requested := false
var _subjective := true
var escort: CharacterBody3D
var _navigation := Navigation.new()
var _mother: MeshInstance3D
var _clue: MeshInstance3D
var _actions: VBoxContainer
var _retry_requested := false
var _legacy_load_requested := false
var _escort_order_requested := ""
var _after_action := ""
var _checkpoint_note := "No checkpoint yet. F5 keeps a separate manual save."
var _message := "Buddh · I know the yard, the horse, and the voices. I do not yet know what lies beyond them."
var gate_passage: Node3D

func _ready() -> void:
	avatar = get_parent().get_node("Player")
	avatar.menu_shortcut = false
	avatar.get_node("HomeIdentity").hide()
	get_parent().get_node("HomeMarker").hide()
	horse = Horse.instantiate()
	add_child(horse)
	_build_world()
	_build_ui()
	_navigation.bind(get_world_3d(),[avatar.get_rid(),horse.get_rid(),attacker.get_rid(),escort.get_rid()])
	_apply()
	if FileAccess.file_exists(checkpoint_path()): _checkpoint_note = "A checkpoint file is available. R validates and restores it."
	avatar.get_node("CameraPivot/SpringArm3D").add_excluded_object(horse.get_rid())
	_refresh()

func _box(size: Vector3, at: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mesh.material_override = mat
	root.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		root.add_child(shape)
	return mesh

func _build_world() -> void:
	_box(Vector3(38, 0.04, 19), Vector3(0, 0.12, 2), Color("b3986e"))
	_box(Vector3(38, 2.6, 0.5), Vector3(0, 1.4, 12), Color("b48b65"), true)
	_box(Vector3(0.5, 2.6, 19), Vector3(-20, 1.4, 2), Color("b48b65"), true)
	_box(Vector3(0.5, 2.6, 19), Vector3(20, 1.4, 2), Color("b48b65"), true)
	# Simple open stable. No replacement for historical architecture or authored Blender assets.
	_box(Vector3(6, 0.3, 6), Vector3(9, 3.6, -4), Color("735b43"))
	for x in [6,12]:
		for z in [-7,-1]: _box(Vector3(0.2, 3.4, 0.2), Vector3(x, 1.8, z), Color("735b43"), true)
	for id in ["steward", "courier"]:
		_box(Vector3(0.55, 1.6, 0.5), Model.SITES[id] + Vector3.UP * 0.8, Color("7e707f"), true)
	_box(Vector3(0.8, 0.05, 0.5), Model.SITES.letter + Vector3(1, 0.7, 0), Color("e6d9b6"))
	trainer = _box(Vector3(0.55, 1.7, 0.5), Model.SITES.spar + Vector3.UP * 0.85, Color("ab7149"), true)
	for i in range(Model.GATES.size()):
		var p: Vector3 = Model.GATES[i]
		for side in [-1,1]: _box(Vector3(0.12, 1.5, 0.12), p + Vector3(side * 2.8, 0.7, 0), Color("ceba86"))
	gate_passage=GatePassage.new()
	gate_passage.name="HouseholdGatePassageStudy"
	add_child(gate_passage)
	gate_passage.build(Model.GATES[2])
	for i in range(1,4):
		for offset in [Vector3(-0.25, 0, 0), Vector3(0.25, 0, -0.35)]:
			_box(Vector3(0.2, 0.03, 0.35), Model.SITES["track_%d" % i] + offset, Color("443e2e"))
	var p: Vector3 = Model.SITES.quarry
	_box(Vector3(0.65, 0.5, 1.3), p + Vector3.UP * 0.8, Color("927455"))
	_box(Vector3(0.3, 0.6, 0.3), p + Vector3(0, 1.1, -0.55), Color("927455"))
	for x in [-0.22,0.22]:
		for z in [-0.4,0.4]: _box(Vector3(0.12, 0.6, 0.12), p + Vector3(x, 0.3, z), Color("5f513e"))
	for at in [Vector3(-24,0,-23),Vector3(22,0,-24),Vector3(22,0,-12),Vector3(17,0,8)]:
		_box(Vector3(0.8,4,0.8), at + Vector3.UP*2.1, Color("5e533c"), true)
		_box(Vector3(5,2.8,5), at + Vector3.UP*4.7, Color("506248"))
	_box(Vector3(3,0.3,2), Model.SITES.reflection - Vector3(1,0,1), Color("9e956e"))
	for x in [-29,29]: _box(Vector3(0.4,3,58),Vector3(x,1.5,0),Color("506248"),true)
	for z in [-29,29]: _box(Vector3(58,3,0.4),Vector3(0,1.5,z),Color("506248"),true)
	attacker = CharacterBody3D.new()
	attacker.name = "UnknownAssailant"
	add_child(attacker)
	attacker.set_physics_process(false)
	var hull := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	hull.shape = shape
	hull.position.y = 0.8
	attacker.add_child(hull)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	mesh.mesh = capsule
	mesh.position.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("794d44")
	mesh.material_override = material
	attacker.add_child(mesh)
	guard_visual = MeshInstance3D.new()
	var shield := BoxMesh.new()
	shield.size = Vector3(0.5, 0.55, 0.1)
	guard_visual.mesh = shield
	guard_visual.position = Vector3(-0.35, 1.1, -0.5)
	avatar.add_child(guard_visual)
	_marker = Label3D.new()
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.font_size = 18
	_marker.pixel_size = 0.003
	add_child(_marker)
	_mother = _box(Vector3(0.58,1.65,0.5),Story.MOTHER+Vector3.UP*0.825,Color("886a86"))
	var mother_label := Label3D.new()
	mother_label.text = "Raj Kaur [E]"
	mother_label.position = Vector3(0,1.35,0)
	mother_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mother_label.font_size = 20
	mother_label.pixel_size = 0.0015
	mother_label.fixed_size = true
	_mother.add_child(mother_label)
	_clue = _box(Vector3(0.7,0.02,0.55),Story.CLUE,Color("504b39"))
	escort = EscortAgent.new()
	escort.entity_id = "fictional_household_guard"
	add_child(escort)
	escort.caption.text = "Household guard"
	escort.add_collision_exception_with(avatar)
	escort.add_collision_exception_with(horse)

func _build_ui() -> void:
	var visual_layer := CanvasLayer.new()
	visual_layer.layer = 4
	add_child(visual_layer)
	_veil = ColorRect.new()
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://childhood/peripheral_frame.gdshader")
	_veil.material = material
	visual_layer.add_child(_veil)
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",18)
	margin.add_theme_constant_override("margin_right",18)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_bottom",16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	_hud = Label.new()
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_font_size_override("font_size",18)
	_hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	_hud.add_theme_constant_override("shadow_offset_y",2)
	column.add_child(_hud)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var caption_panel := PanelContainer.new()
	caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption_panel)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size",18)
	caption_panel.add_child(_caption)
	_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("202827")
	panel_style.border_color = Color("a58b62")
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var scroll := ScrollContainer.new()
	_journal_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(280,140)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_panel_text = Label.new()
	_panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_text.add_theme_font_size_override("font_size",17)
	content.add_child(_panel_text)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation",8)
	content.add_child(_actions)
	_panel.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_panel.size = Vector2(minf(640,size.x-32),minf(540,size.y-32))
	_panel.position = (size-_panel.size)*0.5
	_journal_scroll.custom_minimum_size = Vector2(maxf(220,_panel.size.x-40),maxf(110,_panel.size.y-32))
	_panel_text.custom_minimum_size.x = maxf(200,_panel.size.x-64)
	# Wrap text independently of the visual impairment treatment.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _paused:
		model.record_look(event.relative.x * avatar.mouse_sensitivity)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _paused:
		_strike_requested = true
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_E: _interact_requested = not _paused
		KEY_F: _mount_requested = not _paused
		KEY_F5: _save_requested = true
		KEY_F9: _load_requested = true
		KEY_R: _retry_requested = true
		KEY_G:
			if _paused: return
			var instruction: String = model.aftermath().escort.instruction
			_escort_order_requested = "follow" if instruction == "hold" else "hold"
		KEY_J, KEY_F1: _open_journal()
		KEY_ESCAPE:
			if _paused: _resume()
			else: _open_journal()
		KEY_F4:
			_subjective = not _subjective
			_veil.visible = _subjective
		_ : return
	get_viewport().set_input_as_handled()

func _menu_action(action: String) -> void:
	match action:
		"resume": _resume()
		"save": _save_requested = true
		"load": _load_requested = true
		"retry": _retry_requested = true
		"import": _legacy_load_requested = true
		"menu": get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_: _after_action = action

func _open_journal() -> void:
	_clear_pending_actions()
	_paused = true
	avatar.input_enabled = false
	avatar.set_physics_process(false)
	avatar.velocity = Vector3.ZERO
	var text := "BUDDH SINGH · WHAT I HAVE HEARD AND SEEN\n\n"
	for memory in model.journal():
		text += "[%s · %s · %.1fs]\n%s\n\n" % [memory.channel,memory.source_id,memory.received_tick/60.0,memory.text]
	if model.journal().is_empty(): text += "No reports have reached me.\n\n"
	text += "An account is not its confirmation. The readable text here represents remembered speech and experience, not Buddh reading a document.\n\nSOURCE PROFILE: Latif's History of the Panjab (1891), selected passages; the lessons, dialogue, map and escape outcome are authored. Eye loss is already present; F4 changes only subjective framing. There is no historically established progressive-blindness schedule here."
	text += "\n\n" + _checkpoint_note + "\nRestoring a checkpoint replaces this whole chapter state, including memories and decisions."
	_panel_text.text = text
	_set_actions([["Resume","resume"],["Save chapter","save"],["Load chapter","load"],
		["Restore last checkpoint [R] — replaces current progress","retry"],
		["Import previous childhood save","import"],["Main menu (unsaved changes lost)","menu"]])
	_panel.show()
	_hud.hide()
	_caption.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	_paused = false
	avatar.input_enabled = model.stage() != "caught"
	avatar.set_physics_process(not model.mounted() and model.stage() != "caught")
	_panel.hide()
	_hud.show()
	_caption.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh()

func _physics_process(delta: float) -> void:
	if _retry_requested:
		_retry_requested = false
		_restore_checkpoint()
		return
	if _legacy_load_requested:
		_legacy_load_requested = false
		_load(Model.SAVE_PATH)
		return
	if not _after_action.is_empty():
		var action := _after_action
		_after_action = ""
		_run_after_action(action)
		return
	if not _escort_order_requested.is_empty():
		var instruction := _escort_order_requested
		_escort_order_requested = ""
		# An independent agreement has no deployed guard to approach. Let the
		# existing authority supply that refusal before testing audible range.
		_message = model.order_escort(instruction) if not model.aftermath().escort.active or _escort_audible() else "Move within sight and calling distance of the guard."
		if _message.is_empty(): _message = "Guard · " + ("I will follow." if instruction == "follow" else "I will hold here.")
		_refresh()
	if _load_requested:
		_load_requested = false
		_load()
		return
	if _save_requested:
		_save_requested = false
		var error := model.save_to(save_path)
		_message = "Chapter saved." if error.is_empty() else error
		if _paused: _resume()
	if _paused: return
	if model.stage() == "caught":
		_message = "This attempt ended. Restore the last checkpoint [R], or load a manual save."
		_show_dialog("ATTEMPT ENDED",_message+"\n\n"+_checkpoint_note,
			[["Restore checkpoint [R]","retry"],["Load manual save","load"],["Journal","journal"],["Main menu","menu"]])
		return
	if _mount_requested:
		_mount_requested = false
		_toggle_mount()
	if model.mounted():
		var motion: Dictionary = horse.step(delta,Input.get_action_strength("move_forward"),Input.get_axis("move_left","move_right"),Input.is_action_pressed("sprint"),Input.is_key_pressed(KEY_CTRL),Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_SPACE))
		var error := model.record_ride(motion,delta)
		if not error.is_empty(): horse.apply_record(model.horse_record())
		avatar.global_position = model.position()
	else:
		avatar.walk_speed = 2.0 if Input.is_key_pressed(KEY_C) else 4.5
		avatar.run_speed = 2.0 if Input.is_key_pressed(KEY_C) else 7.5
		var error := model.record_position(avatar.global_position,delta)
		if not error.is_empty(): avatar.global_position = model.position()
	model.advance()
	if _interact_requested:
		_interact_requested = false
		_interact()
	_step_practice()
	_step_ambush(delta)
	_step_escort(delta)
	_strike_requested = false
	guard_visual.visible = not model.mounted() and Input.is_key_pressed(KEY_Q)
	_refresh()

func _interact() -> void:
	if model.mounted():
		_message = "Stop and dismount to speak or examine something."
		return
	if model.stage() == "escaped" and _interact_aftermath(): return
	var error := ""
	if model.near("reflection"):
		error = model.reflect()
		_message = "Buddh · I return to the prayers I have heard. Others can name me; my conduct is still mine."
	elif model.near("letter") and not model.progress().letter_seen:
		error = model.inspect_letter()
		_message = "Buddh · A sealed message. I cannot read its words. I need to hear what it says."
	elif model.near("steward") or model.near("courier"):
		var id := "steward" if model.near("steward") else "courier"
		error = model.hear(id)
		_message = id.capitalize() + " · " + Model.ACCOUNTS[id].claim
	elif model.stage() == "tracking":
		var expected := "track_%d" % (int(model.progress().tracks)+1)
		if model.progress().tracks < 3 and model.near(expected) and _seen(Model.SITES[expected]+Vector3.UP*0.05,3.4):
			error = model.inspect_track(expected)
			_message = "Buddh · Another trace. I can learn the ground without a reader."
		elif model.near("quarry",6.0) and _seen(Model.SITES.quarry+Vector3.UP*0.8,7.0):
			error = model.observe_quarry(Input.is_key_pressed(KEY_C))
			_message = "Buddh · The quarry is here. Time to return; I remember the bend."
			if error.is_empty(): _capture_checkpoint("return_trail")
		else: error = "Look toward the nearby trace, then examine it [E]."
	else: _message = "Read the current lesson above. Move, look, and practise in the world."
	if not error.is_empty(): _message = error

func _seen(at: Vector3, reach: float) -> bool:
	# Character-eye position, not the third-person camera: no inspecting through walls.
	var eye := avatar.global_position + Vector3.UP*1.35
	var offset := at-eye
	if offset.length() > reach: return false
	var forward: Vector3 = -avatar.pivot.global_basis.z
	var horizontal := Vector3(offset.x,0,offset.z).normalized()
	if Vector3(forward.x,0,forward.z).normalized().dot(horizontal) < 0.15: return false
	var ray := PhysicsRayQueryParameters3D.create(eye,at,1,[avatar.get_rid(),horse.get_rid(),attacker.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _step_practice() -> void:
	if model.stage() != "sparring": return
	var phase: int = int(model.progress().tick)%150
	trainer.rotation.z = -0.4 if phase >= 90 and phase < 120 else 0.0
	if not model.near("spar",3.3) or model.mounted(): return
	var facing := _facing(Model.SITES.spar)
	if phase >= 90 and phase < 120: _message = "Trainer · Watch the raised arm. Face me and hold Q to guard."
	if phase == 120:
		if Input.is_key_pressed(KEY_Q) and facing:
			model.spar_result("parry")
			_message = "Trainer · Guard held. After two guards, counter during my recovery [left click]."
		else: _message = "Trainer · Turn toward the strike and guard. Again."
	if _strike_requested and phase > 120 and model.progress().parries >= 2 and facing:
		var error := model.spar_result("counter")
		_message = "Trainer · Good. The next lesson is on the hunting trail." if error.is_empty() else error

func _facing(p: Vector3) -> bool:
	var forward: Vector3 = -avatar.pivot.global_basis.z
	var toward := p-avatar.global_position
	return Vector2(forward.x,forward.z).normalized().dot(Vector2(toward.x,toward.z).normalized()) > 0.35

func _step_ambush(delta: float) -> void:
	if model.stage() == "ready" and model.near("bend",3.0):
		model.start_ambush()
		attacker.global_position = Model.point(model.progress().ambush.position)
		_message = "[A sharp movement beside the path.] Buddh · Someone is coming at me. Get back to the courtyard!"
	attacker.visible = model.stage() in ["active","caught"]
	attacker.collision_layer = 1 if attacker.visible else 0
	attacker.collision_mask = 1 if attacker.visible else 0
	if model.stage() != "active": return
	var a: Dictionary = model.progress().ambush
	var tick: int = model.progress().tick
	if _seen(attacker.global_position+Vector3.UP,24.0): model.witness_threat()
	var d := Model.distance(attacker.global_position,avatar.global_position)
	var phase := (tick-int(a.start_tick))%120
	var stopped: bool = a.deflected or tick <= a.stun_until
	var move := (avatar.global_position-attacker.global_position)
	move.y = 0
	attacker.velocity = move.normalized()*3.0 if not stopped and d > 2.0 and phase < 90 else Vector3.ZERO
	attacker.velocity.y = 0.0 if attacker.is_on_floor() else -4.0
	attacker.move_and_slide()
	var error := model.record_threat(attacker.global_position,delta)
	if not error.is_empty(): attacker.global_position = Model.point(a.position)
	if not stopped and d < 3.0:
		if phase >= 90: _message = "[Nearby movement: a strike is being raised.] Face it and guard [Q], or create distance."
		if phase == 119:
			if not model.mounted() and Input.is_key_pressed(KEY_Q) and _facing(attacker.global_position):
				model.parry_threat()
				_message = "Buddh · The blow is checked. Counter [left click] or leave now."
			else:
				model.take_hit()
				_message = "Buddh · Too close. I need distance or a guard."
	if _strike_requested and not model.mounted() and d < 3.4 and _facing(attacker.global_position) and tick <= model.progress().ambush.stun_until:
		model.deflect()
		_message = "Buddh · I have an opening. Return home."
	if model.near("home",5.0):
		model.reach_home()
		_message = "Buddh · I survived. I need to hear the household's answers. [E: speak / J: memories]"
		if not model.mounted(): _capture_checkpoint("courtyard_return")

func _toggle_mount() -> void:
	var error := ""
	if model.mounted():
		var at = horse.dismount_position(avatar)
		error = "No clear ground to dismount." if at == null else model.dismount(at)
	elif not horse.clear_mount_path(avatar): error = "A wall blocks the horse."
	else: error = model.mount()
	if error.is_empty():
		_apply()
		_message = "Mounted: W forward; A/D steer; Shift canter; S/Space brake." if model.mounted() else "Dismounted. The horse stays here."
	else: _message = error
	if error.is_empty() and not model.mounted() and model.stage() == "escaped" and model.near("home",5.0) and model.aftermath().memories.is_empty():
		_capture_checkpoint("courtyard_return")

func _apply() -> void:
	avatar.global_position = model.position()
	avatar.velocity = Vector3.ZERO
	horse.apply_record(model.horse_record())
	attacker.global_position = Model.point(model.progress().ambush.position)
	attacker.visible = model.stage() in ["active","caught"]
	attacker.collision_layer = 1 if attacker.visible else 0
	attacker.collision_mask = 1 if attacker.visible else 0
	escort.apply(_escort_record())
	_sync_aftermath_visuals()
	var riding := model.mounted()
	avatar.set_physics_process(not riding and not _paused)
	avatar.collision_layer = 0 if riding else 1
	avatar.collision_mask = 0 if riding else 1
	avatar.get_node("MeshInstance3D").visible = not riding
	avatar.get_node("CameraPivot").position.y = 2.5 if riding else 1.4
	avatar.get_node("CameraPivot/SpringArm3D").spring_length = 6.8 if riding else 5.5

func _fits(p: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = p+Vector3.UP*0.85
	query.collision_mask = 1
	query.exclude = [avatar.get_rid(),horse.get_rid(),attacker.get_rid()]
	var space := get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return false
	var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.2,p-Vector3.UP*0.3,1,query.exclude)
	var hit := space.intersect_ray(ray)
	return not hit.is_empty() and hit.normal.y > 0.8

func _candidate_error(staged: Story) -> String:
	if not horse.record_fits_world(staged.horse_record(),avatar) or (not staged.mounted() and not _fits(staged.position())):
		return "Saved position has no clear standing room. Session unchanged."
	if not _fits(Model.point(staged.progress().ambush.position)):
		return "Saved encounter position is obstructed. Session unchanged."
	if not _navigation.fits(staged.aftermath().escort):
		return "Saved guard position is obstructed. Session unchanged."
	return ""

func _load(path: String = "") -> void:
	var staged := Story.new()
	var error := staged.load_from(save_path if path.is_empty() else path)
	if error.is_empty(): error = _candidate_error(staged)
	if error.is_empty(): error = model.restore(staged.snapshot())
	if error.is_empty(): _apply()
	_message = "Chapter loaded; accounts, agreements and poses retained." if error.is_empty() else error
	_clear_pending_actions()
	_resume()

func _refresh() -> void:
	var s := model.progress()
	var lesson := model.stage()
	if is_instance_valid(gate_passage):
		gate_passage.sample(int(s.tick),model.position(),model.mounted(),lesson)
	var target := Model.SITES.home
	var instructions := ""
	match lesson:
		"orientation": instructions = "Walk around the yard [WASD] and turn your view [mouse]. Learn where home is."
		"letter":
			instructions = "Collect the sealed message from the courier [E], then hear both the steward and courier [E]."
			target = Model.SITES.letter if not s.letter_seen else Model.SITES.steward if "steward" not in s.heard else Model.SITES.courier
		"riding":
			instructions = "Mount the horse [F]. Ride between the poles in order: %d/3. Brake and dismount afterwards." % s.ride_gate
			target = Model.GATES[s.ride_gate] if model.mounted() else Riding.position(model.horse_record())
		"sparring":
			instructions = "Face the trainer. Guard two raised blows [hold Q]: %d/2. Counter during recovery [left click]." % s.parries
			target = Model.SITES.spar
		"tracking":
			instructions = "Examine the three tracks [look + E]: %d/3. Approach the quarry quietly [hold C + E]." % s.tracks
			target = Model.SITES["track_%d" % (s.tracks+1)] if s.tracks < 3 else Model.SITES.quarry
		"ready":
			instructions = "Return by the marked bend. Your training is over; keep looking and listening."
			target = Model.SITES.bend
		"active": instructions = "Ambush. Reach the courtyard alive. Make distance, or face the attacker and guard [Q] / counter [click]."
		"caught": instructions = "Attempt ended. R restores the last checkpoint; J opens manual saves."
		"escaped":
			var after: Dictionary = model.aftermath()
			match model.aftermath_phase():
				"accounts":
					instructions = "Hear the steward and courier after the attack, then speak to Raj Kaur [E]."
					target = Model.SITES.steward if "return_steward" not in after.heard else Model.SITES.courier if "return_courier" not in after.heard else Story.MOTHER
				"choice":
					instructions = "Answer Raj Kaur's protection offer [E]. Company has obligations; independence has costs."
					target = Story.MOTHER
				"inspect":
					instructions = "Revisit the bend on foot. Face the disturbed ground and examine [E]."
					target = Story.CLUE
				"return":
					instructions = "Bring the observed account back to Raj Kaur [E]. Return with the guard if you accepted one."
					target = Story.MOTHER
				"complete": instructions = "INQUIRY COMPLETE · You reported a trace, not a culprit. Explore or review the journal."
			instructions += "\n" + model.household_disposition()
			if after.escort.active: instructions += " · Guard: " + after.escort.instruction + " [G toggles, within 10 m]"

	_hud.text = "1792 · BUDDH SINGH · HOME CHAPTER\n%s\n\n%s\n\nWASD move · Mouse look · F horse · E examine/speak · Q guard · C quiet approach\nF4 peripheral framing: %s · J journal · F5/F9 save/load · R checkpoint · F1 menu" % [("HOUSEHOLD / " + model.aftermath_phase().to_upper()) if lesson == "escaped" else lesson.to_upper(),instructions,"subjective" if _subjective else "clear"]
	_caption.text = "  " + _message + "  "
	_marker.position = target+Vector3.UP*2.1
	_marker.text = "Practice waypoint" if lesson in ["orientation","riding","sparring","tracking"] else "Speaker" if lesson=="letter" else "Return"
	_marker.visible = lesson not in ["orientation","caught"] and model.aftermath_phase() != "complete"
	_sync_aftermath_visuals()

func _set_actions(specs: Array) -> void:
	for node in _actions.get_children():
		_actions.remove_child(node)
		node.queue_free()
	for spec in specs:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size.y = 42
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_menu_action.bind(spec[1]))
		_actions.add_child(button)
	_layout()
	_journal_scroll.scroll_vertical = 0

func _clear_pending_actions() -> void:
	_interact_requested = false
	_mount_requested = false
	_strike_requested = false
	_escort_order_requested = ""
	_after_action = ""
	_load_requested = false
	_save_requested = false
	_retry_requested = false
	_legacy_load_requested = false

func _show_dialog(title: String, body: String, actions: Array) -> void:
	_clear_pending_actions()
	_paused = true
	avatar.input_enabled = false
	avatar.set_physics_process(false)
	avatar.velocity = Vector3.ZERO
	_panel_text.text = title + "\n\n" + body
	_set_actions(actions)
	_panel.show()
	_hud.hide()
	_caption.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _actions.get_child_count() > 0: _actions.get_child(0).grab_focus()

func _interact_aftermath() -> bool:
	var a: Dictionary = model.aftermath()
	if Model.distance(model.position(),Story.MOTHER) <= 3.0:
		if not _seen(Story.MOTHER+Vector3.UP,4.0):
			_message = "Turn toward Raj Kaur before speaking."
			return true
		if model.aftermath_phase() == "return":
			_show_dialog("RAJ KAUR · THE ACCOUNT YOU BRING BACK", "You can report the hoof marks you observed. That does not identify the riders or prove who ordered the attack.",
				[["Give the observed account aloud","report"],["Not yet","resume"]])
		elif not a.offer_heard:
			var error := model.hear_offer()
			if not error.is_empty(): _message = error
			else: _protection_dialog()
		elif model.aftermath_phase() == "choice": _protection_dialog()
		else:
			_message = "Raj Kaur · Bring me what you saw, Buddh. A suspicion is not a name." if model.aftermath_phase() != "complete" else "Buddh · I have given my account. The agreement remains; the unanswered questions remain too."
		return true
	for speaker in ["steward","courier"]:
		if model.near(speaker):
			if not _seen(Model.SITES[speaker]+Vector3.UP*1.5,4.0):
				# Existing solid speaker bodies end the ray. Target just in front of the body.
				var offset: Vector3 = (avatar.global_position-Model.SITES[speaker]).normalized()*0.55
				if not _seen(Model.SITES[speaker]+Vector3.UP*1.35+offset,4.0):
					_message = "Turn toward the speaker and move into clear sight."
					return true
			var error := model.hear_return(speaker)
			if not error.is_empty(): _message = error
			else:
				_show_dialog(speaker.to_upper()+" · AFTER YOUR RETURN",Story.AFTER_ACCOUNTS["return_"+speaker].text+
					"\n\nRemembered testimony, not independent confirmation of a culprit.",[["Remember the account and continue","resume"]])
			return true
	if model.aftermath_phase() == "inspect" and Model.distance(model.position(),Story.CLUE) <= 3.0:
		if not _seen(Story.CLUE+Vector3.UP*0.05,4.0): _message = "Face the disturbed ground; a camera view alone is not an observation."
		else:
			var error := model.inspect_bend()
			_message = Story.AFTER_ACCOUNTS.bend_trace.text if error.is_empty() else error
		return true
	return false

func _protection_dialog() -> void:
	_show_dialog("RAJ KAUR · PROTECTION AND ITS PRICE",Story.AFTER_ACCOUNTS.protection_offer.text+
		"\n\nAUTHORED ENCOUNTER\nTake a guard: company on the route, but the household's witness must be present for inspection and return.\nGo alone: no guard, and strained relations with the household. Neither choice reveals a conspirator.",
		[["Accept the household guard — examine the bend together","household_escort"],
		["Insist on an independent inquiry — go alone","independent_inquiry"],["Consider the offer","resume"]])

func _run_after_action(action: String) -> void:
	if action == "journal":
		_open_journal()
		return
	var error := "Unknown dialogue action."
	if action == "report": error = model.report_home()
	elif action in ["household_escort","independent_inquiry"]:
		if action == "household_escort" and not _navigation.fits(model.aftermath().escort):
			error = "The guard's standing position is obstructed; agreement unchanged."
		else: error = model.decide_protection(action)
	_message = error if not error.is_empty() else Story.AFTER_ACCOUNTS.oral_return.text if action == "report" else Story.AFTER_ACCOUNTS[action].text
	if error.is_empty():
		escort.apply(_escort_record())
		_resume()
	else:
		_show_dialog("THE AGREEMENT IS NOT COMPLETE",error,[["Return to the world","resume"]])
	_refresh()

func _escort_record() -> Dictionary:
	var e: Dictionary = model.aftermath().escort
	return {"id":e.id,"position":e.position,"yaw":e.yaw,"velocity":e.velocity}

func _sync_aftermath_visuals() -> void:
	if not is_instance_valid(escort): return
	var a: Dictionary = model.aftermath()
	escort.visible = a.decision == "household_escort"
	escort.collision_layer = 2 if escort.visible else 0
	_mother.get_parent().visible = model.stage() == "escaped"
	_clue.get_parent().visible = model.aftermath_phase() in ["inspect","return","complete"]

func _step_escort(delta: float) -> void:
	var a: Dictionary = model.aftermath()
	if not a.escort.active: return
	var target := model.position()+Vector3(-1.4,0,2.2)
	var moving: bool = a.escort.instruction == "follow" and Model.distance(escort.global_position,target) > 0.65
	var waypoint := _navigation.waypoint(escort.global_position,target) if moving else escort.global_position
	var motion: Dictionary = escort.step(delta,waypoint,moving)
	var error := model.record_escort(motion,delta)
	if not error.is_empty():
		escort.apply(_escort_record())
		_message = error

func _escort_audible() -> bool:
	if _paused or not model.aftermath().escort.active: return false
	var from := avatar.global_position+Vector3.UP*1.35
	var to := escort.global_position+Vector3.UP*1.35
	var query := PhysicsRayQueryParameters3D.create(from,to,1,[avatar.get_rid(),horse.get_rid(),attacker.get_rid(),escort.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func checkpoint_path() -> String:
	return save_path + ".checkpoint.json"

func _capture_checkpoint(reason: String) -> void:
	var error := _candidate_error(model)
	if error.is_empty(): error = Checkpoint.write(checkpoint_path(),model.snapshot(),avatar.pivot.rotation,reason)
	_checkpoint_note = "Checkpoint saved: " + ("before the return-path ambush" if reason == "return_trail" else "back in the courtyard") + ". R restores it." if error.is_empty() else "Checkpoint not saved: " + error
	_message += "\n" + _checkpoint_note

func _restore_checkpoint() -> void:
	var result := Checkpoint.read(checkpoint_path())
	var error: String = result.error
	var staged := Story.new()
	if error.is_empty(): error = staged.restore(result.envelope.snapshot)
	if error.is_empty(): error = _candidate_error(staged)
	if error.is_empty(): error = model.restore(staged.snapshot())
	if not error.is_empty():
		_show_dialog("CHECKPOINT NOT RESTORED",error+"\nYour current chapter is unchanged.",
			[["Return","resume"],["Load manual save","load"],["Main menu","menu"]])
		return
	_apply()
	avatar.pivot.rotation = Vector3(result.envelope.camera[0],result.envelope.camera[1],0)
	_clear_pending_actions()
	_message = "Checkpoint restored. Future memories, decisions and damage from the discarded attempt have not been carried back."
	_resume()
