extends Node3D
## Home tutorial controller. Reuses the original player and horse physics.
## No Lahore clock/order execution runs while this chapter is loaded.
const Model := preload("res://childhood/childhood_state.gd")
const Horse := preload("res://mounts/horse.tscn")
const Names := preload("res://characters/character_names.gd")
const Riding := preload("res://mounts/riding_rules.gd")
var model := Model.new()
var save_path := Model.SAVE_PATH # tests inject a different path
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
var _message := "Buddh · I know the yard, the horse, and the voices. I do not yet know what lies beyond them."

func _ready() -> void:
	avatar = get_parent().get_node("Player")
	avatar.menu_shortcut = false
	avatar.get_node("HomeIdentity").hide()
	get_parent().get_node("HomeMarker").hide()
	horse = Horse.instantiate()
	add_child(horse)
	_build_world()
	_build_ui()
	_apply()
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
	_panel_text = Label.new()
	_panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_text.add_theme_font_size_override("font_size",17)
	scroll.add_child(_panel_text)
	for spec in [["Resume", "resume"],["Save chapter", "save"],["Load chapter", "load"],["Main menu (unsaved changes lost)", "menu"]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size.y = 38
		button.pressed.connect(_menu_action.bind(spec[1]))
		box.add_child(button)
	_panel.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_panel.size = Vector2(minf(640,size.x-32),minf(540,size.y-32))
	_panel.position = (size-_panel.size)*0.5
	_journal_scroll.custom_minimum_size = Vector2(maxf(220,_panel.size.x-40),maxf(110,_panel.size.y-196))
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
		"menu": get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _open_journal() -> void:
	_paused = true
	avatar.input_enabled = false
	avatar.set_physics_process(false)
	avatar.velocity = Vector3.ZERO
	var text := "BUDDH SINGH · WHAT I HAVE HEARD AND SEEN\n\n"
	for memory in model.journal():
		text += "[%s · %s · %.1fs]\n%s\n\n" % [memory.channel,memory.source_id,memory.received_tick/60.0,memory.text]
	if model.journal().is_empty(): text += "No reports have reached me.\n\n"
	text += "An account is not its confirmation. The readable text here represents remembered speech and experience, not Buddh reading a document.\n\nSOURCE PROFILE: Latif's History of the Panjab (1891), selected passages; the lessons, dialogue, map and escape outcome are authored. Eye loss is already present; F4 changes only subjective framing. There is no historically established progressive-blindness schedule here."
	_panel_text.text = text
	_panel.show()
	_hud.hide()
	_caption.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	_paused = false
	avatar.input_enabled = true
	avatar.set_physics_process(not model.mounted())
	_panel.hide()
	_hud.show()
	_caption.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh()

func _physics_process(delta: float) -> void:
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
		_message = "Caught in this attempt. J: load your last chapter save or return to the menu."
		avatar.input_enabled = false
		avatar.set_physics_process(false)
		_refresh()
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
	_strike_requested = false
	guard_visual.visible = not model.mounted() and Input.is_key_pressed(KEY_Q)
	_refresh()

func _interact() -> void:
	if model.mounted():
		_message = "Stop and dismount to speak or examine something."
		return
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
		_message = "Buddh · I survived. I still do not know who sent him. [J: remembered accounts]"

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

func _apply() -> void:
	avatar.global_position = model.position()
	avatar.velocity = Vector3.ZERO
	horse.apply_record(model.horse_record())
	attacker.global_position = Model.point(model.progress().ambush.position)
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

func _load() -> void:
	var staged := Model.new()
	var error := staged.load_from(save_path)
	if error.is_empty() and (not horse.record_fits_world(staged.horse_record(),avatar) or (not staged.mounted() and not _fits(staged.position()))):
		error = "Saved position has no clear standing room. Session unchanged."
	if error.is_empty() and not _fits(Model.point(staged.progress().ambush.position)):
		error = "Saved encounter position is obstructed. Session unchanged."
	if error.is_empty():
		error = model.restore(staged.snapshot())
		_apply()
	_message = "Chapter loaded; heard accounts and lesson progress retained." if error.is_empty() else error
	_interact_requested = false
	_mount_requested = false
	_strike_requested = false
	_resume()

func _refresh() -> void:
	var s := model.progress()
	var lesson := model.stage()
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
		"caught": instructions = "Attempt ended. J / F1: load a save or return to the menu."
		"escaped": instructions = "CHAPTER PROTOTYPE COMPLETE · You returned alive. No mastermind or faction is revealed. J: memories."
	_hud.text = "1792 · BUDDH SINGH · HOME CHAPTER\n%s\n\n%s\n\nWASD move · Mouse look · F horse · E examine/speak · Q guard · C quiet approach\nF4 peripheral framing: %s · J journal · F5/F9 save/load · F1 menu" % [lesson.to_upper(),instructions,"subjective" if _subjective else "clear"]
	_caption.text = "  " + _message + "  "
	_marker.position = target+Vector3.UP*2.1
	_marker.text = "Practice waypoint" if lesson in ["orientation","riding","sparring","tracking"] else "Speaker" if lesson=="letter" else "Return"
	_marker.visible = lesson not in ["orientation","escaped","caught"]
