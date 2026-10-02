# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## A game-owned recollection. Native motors execute movement; this owner admits
## nearby choices. It holds no reference to the waiting Home's authoritative model.
signal return_requested(completed: bool)
const State = preload("res://history/punjab_chiefs_state.gd")
const Player = preload("res://player/player.tscn")
const Horse = preload("res://mounts/horse.tscn")
const Costume = preload("res://presentation/costume_proxy.gd")
const RegencyAccess = preload("res://history/regency_access.gd")
const CHECKPOINT_SCHEMA := "1792.punjab-chiefs.visit.v2"
const LEGACY_CHECKPOINT_SCHEMA := "1792.punjab-chiefs.visit.v1"
var model = State.new()
var sequence_id := "delegation"
var save_path := "user://punjab_chiefs_visit.json"
var avatar: CharacterBody3D
var horse: CharacterBody3D
var companion: CharacterBody3D
var companion_id := ""
var stations: Dictionary = {}
var actors: Dictionary = {}
var mounted := false
var ride_distance := 0.0
var paused := true
var message := ""
var last_interaction_error := ""
var execution_steps := 0
var _stage: Node3D
var _hud: CanvasLayer
var _title: Label
var _objective: Label
var _hint: Label
var _panel: PanelContainer
var _dialogue: Label
var _buttons: VBoxContainer
var _marker: Label3D
var _camera: Camera3D
var _costume: Node3D
var _cut_camera: Camera3D
var _dialogue_is_choice := false
var _pending_choice := ""
var _interaction_requested := false
var _save_requested := false
var _load_requested := false
var _elapsed := 0.0
var _returned := false
var _awaiting_opening := true
var _well_water: MeshInstance3D
var _covered_litter: Node3D
var _litter_station_id := ""
var _regency_access: RefCounted
var screen_barrier: StaticBody3D

func configure(id: String) -> void:
	sequence_id = id

func _ready() -> void:
	if save_path=="user://punjab_chiefs_visit.json": save_path="user://punjab_chiefs_visit_%s.json" % sequence_id
	var error: String = model.start(sequence_id)
	if not error.is_empty():
		push_error(error)
		return
	_build_stage()
	_build_interface()
	_open(model.sequence.opening, [{"text":"Step into the telling", "call":begin_play}])
	_refresh()

func begin_play() -> void:
	_awaiting_opening = false
	_close()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	return material

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, scale_value := Vector3.ONE) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.position = at
	item.scale = scale_value
	item.material_override = _material(color)
	parent.add_child(item)
	return item

func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, solid := false) -> Node3D:
	var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
	holder.position = at
	parent.add_child(holder)
	var cube := BoxMesh.new()
	cube.size = size
	_mesh(holder, cube, Vector3.ZERO, color)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		holder.add_child(collision)
	return holder

func _oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 14
	sphere.rings = 8
	return _mesh(parent, sphere, at, color, size)

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	return _mesh(parent, mesh, at, color)

func _figure(parent: Node3D, cloth: Color) -> void:
	var body := CylinderMesh.new()
	body.top_radius = 0.23
	body.bottom_radius = 0.31
	body.height = 0.85
	body.radial_segments = 14
	_mesh(parent, body, Vector3(0,0.90,0), cloth)
	_cylinder(parent, Vector3(0,0.74,0), 0.25, 0.11, Color("704b40"))
	for side in [-1,1]:
		_oval(parent, Vector3(side*0.13,0.31,0), Vector3(0.17,0.56,0.2), cloth.darkened(0.14))
		_oval(parent, Vector3(side*0.14,0.08,-0.06), Vector3(0.2,0.13,0.35), Color("3f3329"))
		_oval(parent, Vector3(side*0.31,1.05,0), Vector3(0.16,0.62,0.2), cloth)
		_oval(parent, Vector3(side*0.32,0.74,-0.015), Vector3(0.12,0.17,0.12), Color("9e7658"))
	_oval(parent, Vector3(0,1.53,0), Vector3(0.31,0.36,0.29), Color("9e7658"))
	_oval(parent, Vector3(0,1.73,0), Vector3(0.4,0.23,0.37), cloth.lightened(0.15))
	_oval(parent, Vector3(0,1.43,-0.1), Vector3(0.27,0.24,0.17), Color("342b26"))
	for side in [-1,1]:
		_oval(parent, Vector3(side*0.075,1.57,-0.146), Vector3(0.04,0.022,0.012), Color("191a19"))

func _build_stage() -> void:
	_stage = Node3D.new()
	_stage.name = "RecollectionStage"
	add_child(_stage)
	var palette: Dictionary = model.sequence.get("palette", {})
	var night := sequence_id in ["rumours", "litter"]
	var ground := Color(palette.get("ground", "b79b70"))
	var sky_color := Color(palette.get("sky", "1b2538" if night else "b7c3c0"))
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7d91ba") if night else sky_color.lightened(0.1)
	env.ambient_light_energy = 0.40 if night else 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	_stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "NightSkyFill" if night else "Sun"
	sun.rotation_degrees = Vector3(-28,-36,0)
	sun.light_color = Color("9bb4de") if night else Color("ffe3b5")
	sun.light_energy = 0.24 if night else 0.72
	sun.shadow_enabled = true
	_stage.add_child(sun)
	_box(_stage, Vector3(60,0.4,60), Vector3(0,-0.2,0), ground, true)
	# The playable routes are unobstructed; the perimeter defines a small authored
	# stage, not a surveyed representation of the historical settlement.
	for x in [-24,24]:
		_box(_stage, Vector3(0.7,3.5,49), Vector3(x,1.75,0), ground.darkened(0.16), true)
	for z in [-24,24]:
		_box(_stage, Vector3(49,3.5,0.7), Vector3(0,1.75,z), ground.darkened(0.16), true)
	var open_country: bool = sequence_id in ["desi","exile","alliance","sodhra","settlement"]
	for x in [-19,19]:
		if not open_country:
			_box(_stage, Vector3(5,4,31), Vector3(x,2,-2), ground.lightened(0.07), true)
			for z in [-13,-6,1,8]:
				_box(_stage, Vector3(0.06,2.3,1.6), Vector3(x+(-2.53 if x>0 else 2.53),1.15,z), Color("55493b"))
				_box(_stage, Vector3(0.11,0.2,2.1), Vector3(x+(-2.58 if x>0 else 2.58),2.35,z), Color("866c4b"))
				for k in [-1,0,1]:
					_box(_stage, Vector3(0.1,2.1,0.05), Vector3(x+(-2.60 if x>0 else 2.60),1.2,z+k*0.45), Color("af8c61"))
		else:
			for z in [-18,-6,8,17]:
				_tree(Vector3(x,0,z))
	# A gateway and distant stepped roofline establish readable silhouettes.
	for x in [-6,6]:
		_box(_stage, Vector3(5,5,2), Vector3(x,2.5,-21), ground.darkened(0.08), true)
		_box(_stage, Vector3(5.4,0.3,2.4), Vector3(x,5,-21), Color("ccb082"))
		for offset in [-1.7,0,1.7]:
			_box(_stage, Vector3(0.6,0.65,0.7), Vector3(x+offset,5.5,-20.5), ground.lightened(0.06))
	_box(_stage, Vector3(7,0.5,2), Vector3(0,4.65,-21), ground.darkened(0.08))
	if sequence_id == "desi":
		_box(_stage, Vector3(31,0.025,4), Vector3(0,0.015,-5), Color("758f91"))
		for i in range(16):
			_box(_stage, Vector3(1.2,0.012,0.05), Vector3(-14+i*1.8,0.036,-5+sin(i*1.7)), Color("adbcac"))
	for i in range(36):
		var at := Vector3(-21+fmod(i*7.13,42.0),0, -20+fmod(i*11.17,39.0))
		# Keep terrain dressing outside the main walking lanes and interaction spaces.
		if absf(at.x)<15: continue
		for j in range(3):
			var reed := _box(_stage,Vector3(0.035,0.5+j*0.16,0.035),at+Vector3(j*0.12,0.25,0),Color("8c8961"))
			reed.rotation.z = (j-1)*0.22
	for definition in model.sequence.stations:
		_build_station(definition)
	_build_sequence_dressing(night)
	avatar = Player.instantiate()
	avatar.name = "RecollectionPlayer"
	avatar.menu_shortcut = false
	avatar.position = Vector3(0,0.06,12)
	_stage.add_child(avatar)
	avatar.get_node("MeshInstance3D").hide()
	_costume = Costume.new()
	avatar.add_child(_costume)
	# Costume additions decorate the qualified skeleton without changing its motor.
	var turban := _oval(_costume,Vector3(0,1.62,0),Vector3(0.37,0.23,0.34),Color("e5d8b8"))
	turban.name = "HeadWrap"
	_camera = avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	_camera.fov = 58.0
	_cut_camera = Camera3D.new()
	_cut_camera.fov = 48.0
	_stage.add_child(_cut_camera)
	if is_instance_valid(horse):
		avatar.get_node("CameraPivot/SpringArm3D").add_excluded_object(horse.get_rid())
	_marker = Label3D.new()
	_marker.font_size = 30
	_marker.pixel_size = 0.008
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.modulate = Color("fff0bd")
	_stage.add_child(_marker)

func _build_sequence_dressing(night: bool) -> void:
	if sequence_id == "audience":
		_regency_access = RegencyAccess.new(self)
		_regency_access.build()
		screen_barrier = _regency_access.screen_barrier
	# The remaining silhouettes and lights decorate existing routes. They own no
	# collider, narrative progress, carrier motor or checkpoint fields.
	if night:
		for definition in model.sequence.stations:
			_build_lamp(_point(definition.position) + Vector3(1.6, 0, 1.1))
	if sequence_id != "litter": return
	for beat in model.sequence.beats:
		for choice in beat.choices:
			if choice.effects.get("escort_following", false) and actors.has(beat.target):
				_litter_station_id = beat.target
				break
		if not _litter_station_id.is_empty(): break
	if _litter_station_id.is_empty(): return
	_covered_litter = Node3D.new()
	_covered_litter.name = "CoveredPalanquin"
	_covered_litter.set_meta("presentation_role", "authored_covered_litter")
	_stage.add_child(_covered_litter)
	var timber := Color("695341")
	var cloth := Color("594750")
	var trim := Color("bc9c64")
	_box(_covered_litter, Vector3(1.38, 0.16, 2.2), Vector3(0, 0.86, 0), timber)
	# Opaque curtains keep the occupant concealed throughout the telling.
	for x in [-0.64, 0.64]:
		_box(_covered_litter, Vector3(0.05, 1.2, 2.1), Vector3(x, 1.53, 0), cloth)
		_box(_covered_litter, Vector3(0.045, 0.07, 2.12), Vector3(x * 1.05, 1.02, 0), trim)
		for z in [-0.98, 0.98]:
			_box(_covered_litter, Vector3(0.08, 1.35, 0.08), Vector3(x, 1.55, z), timber)
	for z in [-1.02, 1.02]:
		_box(_covered_litter, Vector3(1.2, 1.18, 0.055), Vector3(0, 1.53, z), cloth.lightened(0.08))
		for x in [-0.42, 0, 0.42]:
			_box(_covered_litter, Vector3(0.035, 1.08, 0.02), Vector3(x, 1.53, z * 1.04), cloth.darkened(0.18))
	for side in [-1, 1]:
		var roof := _box(_covered_litter, Vector3(0.8, 0.11, 2.38), Vector3(side * 0.34, 2.21, 0), cloth)
		roof.rotation.z = -side * 0.22
		_box(_covered_litter, Vector3(0.09, 0.1, 4.2), Vector3(side * 0.59, 1.05, 0), timber)
		_oval(_covered_litter, Vector3(0, 2.4, side * 1.04), Vector3(0.13, 0.2, 0.13), trim)
	var rear_bearer := Node3D.new()
	rear_bearer.name = "RearBearerPresentation"
	rear_bearer.position.z = 1.68
	_covered_litter.add_child(rear_bearer)
	_figure(rear_bearer, Color("a89b7d"))
	_sync_story_visuals()

func _build_lamp(at: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.name = "CourtyardOilLamp"
	lamp.position = at
	_stage.add_child(lamp)
	_cylinder(lamp, Vector3(0, 0.75, 0), 0.055, 1.5, Color("675443"))
	_cylinder(lamp, Vector3(0, 1.53, 0), 0.16, 0.055, Color("a4804b"))
	var flame := _oval(lamp, Vector3(0, 1.65, 0), Vector3(0.075, 0.19, 0.075), Color("ffe8aa"))
	var material := flame.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color("ffd08b")
	material.emission_energy_multiplier = 2.0
	var light := OmniLight3D.new()
	light.position.y = 1.68
	light.light_color = Color("ffd098")
	light.light_energy = 1.7
	light.omni_range = 7.0
	light.omni_attenuation = 1.2
	lamp.add_child(light)

func _build_dispatch_table(anchor: Node3D) -> void:
	var table := Node3D.new()
	table.name = "SealedDispatchTable"
	anchor.add_child(table)
	var wood := Color("72563e")
	_box(table, Vector3(1.9, 0.12, 1.0), Vector3(0, 0.85, 0), wood)
	for x in [-0.82, 0.82]:
		for z in [-0.37, 0.37]:
			_box(table, Vector3(0.09, 0.82, 0.09), Vector3(x, 0.41, z), wood.darkened(0.1))
	for i in range(4):
		var at := Vector3(-0.59 + (i % 2) * 0.62, 0.927 + i * 0.002, -0.19 + (i / 2) * 0.32)
		_box(table, Vector3(0.39, 0.025, 0.25), at, Color("dbcfad"))
		_box(table, Vector3(0.035, 0.009, 0.26), at + Vector3.UP * 0.017, Color("938065"))
		_cylinder(table, at + Vector3(0.0, 0.026, 0.035), 0.043, 0.012, Color("8d3f38"))
	_cylinder(table, Vector3(0.69, 0.977, -0.27), 0.065, 0.13, Color("403a35"))
	var reed := _box(table, Vector3(0.018, 0.018, 0.28), Vector3(0.69, 0.937, 0.03), Color("bca476"))
	reed.rotation.y = 0.45

func _sync_story_visuals() -> void:
	if _regency_access != null: _regency_access.sync_visuals()
	if not is_instance_valid(_covered_litter): return
	var following: bool = is_instance_valid(companion) and companion_id == _litter_station_id and model.flags.get("escort_following", false)
	var destination: Node3D = companion if following else _stage
	if _covered_litter.get_parent() != destination: _covered_litter.reparent(destination, false)
	# Recompute from accepted state after ordinary choices and checkpoint recall.
	# A recalled pre-escort state returns the litter to its original waiting place.
	_covered_litter.position = Vector3(0, 0, 1.68) if following else stations[_litter_station_id].position + Vector3(0, 0, 1.68)
	_covered_litter.rotation = Vector3.ZERO

func _tree(at: Vector3) -> void:
	_cylinder(_stage,at+Vector3.UP*1.6,0.18,3.2,Color("655343"))
	for i in range(4):
		_oval(_stage,at+Vector3((i-1.5)*0.8,3.2+sin(i)*0.35,0),Vector3(2.4,0.8,2.0),Color("657552"))

func _build_station(definition: Dictionary) -> void:
	var anchor := Node3D.new()
	anchor.name = definition.id
	anchor.position = _point(definition.position)
	_stage.add_child(anchor)
	stations[definition.id] = anchor
	match definition.kind:
		"npc":
			var actor := CharacterBody3D.new()
			actor.position = anchor.position
			actor.name = "Actor_"+definition.id
			_stage.add_child(actor)
			var collision := CollisionShape3D.new()
			var shape := CapsuleShape3D.new()
			shape.radius = 0.3
			shape.height = 1.7
			collision.shape = shape
			collision.position.y = 0.85
			actor.add_child(collision)
			_figure(actor,Color("d4cbb2") if actors.size()%2==0 else Color("6b8585"))
			actors[definition.id] = actor
		"horse":
			horse = Horse.instantiate()
			horse.position = anchor.position
			_stage.add_child(horse)
			# Desi's piebald marking is a presentation treatment on the existing horse.
			for mesh in horse.get_node("HorseVisual").find_children("*","MeshInstance3D",true,false):
				if mesh.name in ["Barrel","Haunch","Shoulder","Head","Neck"]:
					mesh.material_override = _material(Color("e5dfcc") if mesh.name in ["Barrel","Shoulder","Head"] else Color("35312c"))
			_oval(horse.get_node("HorseVisual/Trunk"),Vector3(-0.43,1.25,0.3),Vector3(0.06,0.62,0.74),Color("35312c"))
		"well":
			var water := _cylinder(anchor,Vector3(0,0.04,0),0.95,0.05,Color("344e50"))
			if sequence_id=="well": _well_water=water
			for level in range(3):
				for i in range(18):
					var angle := (i+0.5*(level%2))*TAU/18.0
					var brick := _box(anchor,Vector3(0.36,0.2,0.28),Vector3(sin(angle),0.13+level*0.21,cos(angle)),Color("a88764"),true)
					brick.rotation.y = angle
			for side in [-1,1]:
				_box(anchor,Vector3(0.16,2.4,0.16),Vector3(side*1.2,1.2,0),Color("695943"),true)
			_box(anchor,Vector3(2.8,0.18,0.2),Vector3(0,2.45,0),Color("695943"))
			_cylinder(anchor,Vector3(0,1.4,0),0.025,2.0,Color("b9a780"))
		"gate":
			for side in [-1,1]:
				_box(anchor,Vector3(0.2,2.5,0.2),Vector3(side*1.8,1.25,0),Color("725c42"),true)
				var cloth := _box(anchor,Vector3(1.1,0.8,0.025),Vector3(side*1.5,2.1,0),Color("b69a63"))
				cloth.rotation.z = side*0.08
		"bundle":
			if definition.id == "dispatch_table":
				_build_dispatch_table(anchor)
			else:
				for i in range(3):
					_oval(anchor,Vector3((i-1)*0.4,0.3,0),Vector3(0.52,0.56,0.72),Color("9a8669"))
		"track":
			if sequence_id=="well" and definition.id=="resting_place":
				_box(anchor,Vector3(1.4,0.12,2.3),Vector3(0,0.55,0),Color("9e8965"),true)
				for x in [-0.59,0.59]:
					for z in [-1.03,1.03]:
						_box(anchor,Vector3(0.12,0.7,0.12),Vector3(x,0.35,z),Color("65523f"))
				for z in range(12):
					_box(anchor,Vector3(1.25,0.025,0.035),Vector3(0,0.625,-1.0+z*0.18),Color("d7c5a0"))
			else:
				for i in range(5):
					_box(anchor,Vector3(0.16,0.012,0.3),Vector3((i%2)*0.38,0.025,i*0.35),Color("78644b"))
	var label := Label3D.new()
	label.text = definition.label
	label.position = Vector3(0,2.9,0)
	label.font_size = 20
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e9dbbb")
	anchor.add_child(label)

func _label(parent: Node, size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color("252522"))
	label.add_theme_constant_override("shadow_offset_y",2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _build_interface() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 8
	add_child(_hud)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	_title = _label(column,28,Color("fff1d3"))
	var period := _label(column,15,Color("ebddbe"))
	var roles := {"delegation":"Nakai household runner", "alliance":"Attendant to the allied chiefs", "revenge":"Dal Singh's household", "desi":"Budha Singh", "exile":"Among the Ramgarhia followers", "well":"Bahrwal household attendant"}
	period.text = model.sequence.period+"  •  "+str(model.sequence.get("display_role", roles.get(sequence_id, model.sequence.get("role", "Household attendant"))))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	_objective = _label(column,21,Color("fff1d3"))
	_hint = _label(column,15,Color("e9dbbd"))
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.anchor_left = 0.12
	_panel.anchor_right = 0.88
	_panel.anchor_top = 0.18
	_panel.anchor_bottom = 0.78
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09,0.12,0.12,0.97)
	style.border_color = Color("b29665")
	style.set_border_width_all(1)
	style.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel",style)
	_hud.add_child(_panel)
	var scroll := ScrollContainer.new()
	_panel.add_child(scroll)
	var dialogue_column := VBoxContainer.new()
	dialogue_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_column.add_theme_constant_override("separation",15)
	scroll.add_child(dialogue_column)
	_dialogue = _label(dialogue_column,21,Color("f2e8cd"))
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation",8)
	dialogue_column.add_child(_buttons)

func _open(text_value: String, actions: Array, is_choice := false) -> void:
	paused = true
	avatar.input_enabled = false
	avatar.set_physics_process(false)
	avatar.clear_motion_requests()
	_dialogue_is_choice = is_choice
	_panel.anchor_top = 0.54 if is_choice else 0.22
	_panel.anchor_bottom = 0.92 if is_choice else 0.73
	_dialogue.add_theme_font_size_override("font_size",18 if is_choice else 21)
	_dialogue.text = text_value
	for button in _buttons.get_children():
		_buttons.remove_child(button)
		button.queue_free()
	for action in actions:
		var button := Button.new()
		button.text = action.text
		button.custom_minimum_size.y = 44
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(action.call)
		_buttons.add_child(button)
	_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _buttons.get_child_count()>0: _buttons.get_child(0).grab_focus()

func _close() -> void:
	_panel.hide()
	_cut_camera.current = false
	_camera.make_current()
	_dialogue_is_choice = false
	paused = false
	avatar.set_physics_process(not mounted)
	avatar.input_enabled = not mounted
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if _returned: return
	if event is InputEventMouseMotion and mounted and not paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		avatar.pivot.rotation.y = wrapf(avatar.pivot.rotation.y-event.relative.x*avatar.mouse_sensitivity,-PI,PI)
		avatar.pivot.rotation.x = clampf(avatar.pivot.rotation.x-event.relative.y*avatar.mouse_sensitivity,-0.9,0.5)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if paused and not _awaiting_opening and not model.complete(): _close()
				else: _open("Leave this telling? Your last F5 checkpoint remains available.",[
					{"text":"Continue", "call":_close},
					{"text":"Return to the courtyard", "call":func(): request_return(false)}])
			KEY_E:
				if not paused: _interaction_requested = true
			KEY_F5:
				if not paused: _save_requested = true
			KEY_F9:
				if not paused: _load_requested = true
			_: return
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(avatar) or _returned: return
	if not _pending_choice.is_empty():
		var id := _pending_choice
		_pending_choice = ""
		_commit_choice(id)
	if _save_requested:
		_save_requested = false
		message = save_checkpoint()
	if _load_requested:
		_load_requested = false
		message = load_checkpoint()
	if paused:
		_refresh()
		return
	execution_steps += 1
	_elapsed += delta
	if mounted:
		var before: Vector3 = horse.global_position
		horse.step(delta,Input.get_action_strength("move_forward"),Input.get_axis("move_left","move_right"),Input.is_action_pressed("sprint"),false,Input.is_action_pressed("move_backward"))
		ride_distance += Vector2(horse.global_position.x-before.x,horse.global_position.z-before.z).length()
		avatar.global_position = horse.saddle_support_point()
		avatar.velocity = Vector3.ZERO
		_costume.rotation.y = horse.rotation.y
	elif is_instance_valid(horse):
		horse.step(delta,0.0,0.0,false,false,true)
	if is_instance_valid(companion): _move_companion(delta)
	_costume.sample_tick(execution_steps)
	_sample_rider()
	if _interaction_requested:
		_interaction_requested = false
		interact()
	_refresh()

func _sample_rider() -> void:
	_costume.position.y = -0.78 if mounted else 0.0
	if not mounted: return
	_costume.rotation.y = horse.rotation.y
	for side in [-1,1]:
		var suffix := "L" if side<0 else "R"
		_costume.skeleton.set_bone_pose_rotation(_costume.bones["upper_leg"+suffix],Quaternion(Vector3.RIGHT,-0.8)*Quaternion(Vector3.FORWARD,side*0.42))
		_costume.skeleton.set_bone_pose_rotation(_costume.bones["lower_leg"+suffix],Quaternion(Vector3.RIGHT,1.1))
		_costume.skeleton.set_bone_pose_rotation(_costume.bones["upper_arm"+suffix],Quaternion(Vector3.RIGHT,-0.85))
		_costume.skeleton.set_bone_pose_rotation(_costume.bones["forearm"+suffix],Quaternion(Vector3.RIGHT,-0.55))

func _move_companion(delta: float) -> void:
	var difference := avatar.global_position-companion.global_position
	difference.y = 0
	var direction := difference.normalized() if difference.length()>2.0 else Vector3.ZERO
	companion.velocity.x = direction.x*3.3
	companion.velocity.z = direction.z*3.3
	companion.velocity.y = 0.0 if companion.is_on_floor() else companion.velocity.y-22.0*delta
	companion.move_and_slide()
	if direction.length()>0.1: companion.rotation.y = atan2(-direction.x,-direction.z)

func target_position() -> Vector3:
	var beat: Dictionary = model.current_beat()
	if beat.is_empty(): return avatar.global_position
	if actors.has(beat.target): return actors[beat.target].global_position
	if is_instance_valid(horse) and _station_kind(beat.target)=="horse": return horse.global_position
	return stations[beat.target].global_position

func _station_kind(id: String) -> String:
	for station in model.sequence.stations:
		if station.id==id: return station.kind
	return ""

func interaction_error() -> String:
	if model.complete(): return "The telling is complete."
	var beat: Dictionary = model.current_beat()
	var target := target_position()
	var position_value: Vector3 = horse.global_position if mounted else avatar.global_position
	if Vector2(position_value.x-target.x,position_value.z-target.z).length()>2.7:
		return "Come closer to "+_station_label(beat.target)+"."
	if _regency_access != null:
		var admission: String = _regency_access.interaction_error(position_value)
		if not admission.is_empty(): return admission
	var exclusions: Array[RID] = [avatar.get_rid()]
	if is_instance_valid(horse): exclusions.append(horse.get_rid())
	if actors.has(beat.target): exclusions.append(actors[beat.target].get_rid())
	if is_instance_valid(companion): exclusions.append(companion.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(position_value+Vector3.UP*1.4,target+Vector3.UP*1.4,1,exclusions)
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return "Find a clear way to speak or act."
	for flag in beat.get("requires_flags",[]):
		if not model.flags.get(flag,false): return "There is something to settle first."
	if beat.mode=="escort":
		if not is_instance_valid(companion): return "Your companion is still waiting."
		if companion.global_position.distance_to(target)>4.5: return "Wait for your companion to arrive."
	if beat.mode=="ride":
		if not mounted: return "This part of the story is ridden with Desi."
		if horse.speed>1.8: return "Steady Desi before continuing. Hold S to halt."
		if ride_distance<float(beat.get("min_ride_distance",0)): return "Ride the crossing before finishing the journey."
	if mounted and horse.speed>1.8: return "Steady Desi before continuing. Hold S to halt."
	return ""

func interact() -> String:
	if paused: return "Finish the current conversation first."
	var error := interaction_error()
	last_interaction_error = error
	if not error.is_empty():
		message = error
		return error
	var beat: Dictionary = model.current_beat()
	var actions: Array = []
	for choice in beat.choices:
		var id: String = choice.id
		actions.append({"text":choice.label,"call":func(): _pending_choice=id})
	_open(beat.line,actions,true)
	# A brief composed view keeps the speaker and player in the frame. It is
	# presentation only; all interaction admission uses physical body positions.
	var target := target_position()
	_cut_camera.position = avatar.global_position+Vector3(3.1,2.3,3.3)
	_cut_camera.look_at((avatar.global_position+target)*0.5+Vector3.UP)
	if _regency_access != null and beat.target == "raj_screen": _regency_access.compose_camera(_cut_camera)
	_cut_camera.make_current()
	return ""

func _commit_choice(id: String) -> void:
	if not _dialogue_is_choice: return
	var error := interaction_error()
	if not error.is_empty():
		message = error
		_close()
		return
	var beat: Dictionary = model.current_beat().duplicate(true)
	var selected: Dictionary = {}
	for choice in beat.choices:
		if choice.id==id: selected=choice
	if selected.is_empty(): return
	if selected.effects.get("mounted",false) and not mounted:
		if not is_instance_valid(horse) or not horse.clear_mount_path(avatar):
			message = "There is no clear path to Desi's saddle."
			_close()
			return
	var landing: Variant = null
	if mounted and selected.effects.has("mounted") and not selected.effects.mounted:
		landing = horse.dismount_position(avatar)
		if landing == null:
			message = "Bring Desi to clear ground before dismounting."
			_close()
			return
	error = model.choose(id)
	if not error.is_empty():
		message = error
		return
	message = selected.line
	if model.flags.get("escort_following",false) and not is_instance_valid(companion):
		if actors.has(beat.target):
			companion_id = beat.target
			companion = actors[beat.target]
			companion.add_collision_exception_with(avatar)
			avatar.add_collision_exception_with(companion)
	if selected.effects.get("mounted",false) and not mounted:
		mounted = true
		avatar.set_physics_process(false)
		avatar.input_enabled = false
		avatar.global_position = horse.saddle_support_point()
		avatar.velocity = Vector3.ZERO
		# The root collider is disabled while seated; the original horse hull owns
		# mounted contact. No free coordinate movement substitutes for riding.
		avatar.get_node("CollisionShape3D").set_deferred("disabled",true)
		avatar.get_node("CameraPivot/SpringArm3D").spring_length = 7.0
	elif landing != null:
		mounted = false
		avatar.global_position = landing
		avatar.velocity = Vector3.ZERO
		avatar.get_node("CollisionShape3D").set_deferred("disabled",false)
		avatar.get_node("CameraPivot/SpringArm3D").spring_length = 5.5
	_costume.sample_tick(execution_steps)
	_sample_rider()
	if model.complete():
		_open(message+"\n\n"+model.ending(),[{"text":"Carry this story back", "call":func(): request_return(true)}])
	else:
		_open(message,[{"text":"Continue", "call":_close}])
	_refresh()

func _station_label(id: String) -> String:
	for station in model.sequence.stations:
		if station.id==id: return station.label
	return id

func _refresh() -> void:
	if not is_instance_valid(_title): return
	_sync_story_visuals()
	_title.text = model.sequence.title
	_objective.visible = not paused
	_hint.visible = not paused
	for id in stations:
		for child in stations[id].get_children():
			if child is Label3D:
				child.visible = not paused and _flat_distance(avatar.global_position,stations[id].global_position)<11.0
	if model.complete():
		_objective.text = "The telling is complete"
		_marker.hide()
	else:
		var beat: Dictionary = model.current_beat()
		_objective.text = "%d / %d   %s" % [model.step_index+1,model.sequence.beats.size(),beat.objective]
		_marker.position = target_position()+Vector3.UP*2.5
		_marker.text = "◆"
		_marker.visible = not paused
	if is_instance_valid(_well_water):
		_well_water.material_override.albedo_color = Color("79b3a8") if model.flags.get("miracle_witnessed",false) else Color("344e50")
	var controls := "WASD move · mouse look · E act · F5 keep checkpoint · F9 recall · Esc return"
	if mounted: controls = "W ride · A/D turn · S halt · Shift canter · E act · F5 / F9 checkpoint · Esc return"
	_hint.text = (message+"\n" if not message.is_empty() else "")+controls

func can_complete() -> bool:
	return model.complete()

func audience_status() -> Dictionary:
	return _regency_access.audience_status() if _regency_access != null else {}

func logistics_outcome() -> Dictionary:
	return _regency_access.logistics_outcome() if _regency_access != null else {}

func reject_return(error: String) -> void:
	_returned = false
	message = error
	_open(error,[{"text":"Continue", "call":_close}])

func request_return(completed: bool) -> void:
	if _returned or (completed and not can_complete()): return
	_returned = true
	avatar.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if return_requested.get_connections().is_empty():
		# Direct scene play has a usable end; integrated visits delegate to their owner.
		get_tree().change_scene_to_file("res://history/punjab_chiefs_home.tscn")
	else:
		return_requested.emit(completed)

func _array(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _point(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

func _valid_vector(value: Variant, maximum: float) -> bool:
	if not value is Array or value.size()!=3: return false
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)) or absf(float(component))>maximum: return false
	return true

func save_checkpoint() -> String:
	if paused or _returned: return "Finish the conversation before keeping this moment."
	if mounted and horse.speed>0.25: return "Halt Desi before keeping this moment."
	if mounted and not horse.is_on_floor() or not mounted and not avatar.is_on_floor():
		return "Stand on firm ground before keeping this moment."
	var value := {"schema":CHECKPOINT_SCHEMA,"progress":model.snapshot(),
		"player":_array(avatar.global_position),"camera":_array(avatar.pivot.rotation),
		"mounted":mounted,"ride_distance":ride_distance,"companion_id":companion_id,
		"companion":_array(companion.global_position) if is_instance_valid(companion) else [],
		"companion_yaw":companion.rotation.y if is_instance_valid(companion) else 0.0,
		"horse":_array(horse.global_position) if is_instance_valid(horse) else [],
		"horse_yaw":horse.rotation.y if is_instance_valid(horse) else 0.0}
	var temporary := save_path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return "This moment could not be kept."
	file.store_string(JSON.stringify(value))
	file.close()
	if DirAccess.rename_absolute(temporary,save_path)!=OK: return "This moment could not be kept."
	return "Checkpoint kept for this telling."

func load_checkpoint() -> String:
	if paused or _returned: return "Finish the conversation before recalling a checkpoint."
	if not FileAccess.file_exists(save_path): return "No checkpoint has been kept."
	var file := FileAccess.open(save_path,FileAccess.READ)
	if file==null or file.get_length()>65536: return "The checkpoint cannot be read."
	var parsed := JSON.new()
	var parse_error := parsed.parse(file.get_as_text())
	file.close()
	if parse_error!=OK: return "The checkpoint cannot be read."
	return restore_checkpoint(parsed.data)

func restore_checkpoint(value: Variant) -> String:
	# Validate the entire candidate before changing the live visit.
	if not value is Dictionary or value.get("schema","") not in [CHECKPOINT_SCHEMA, LEGACY_CHECKPOINT_SCHEMA]: return "This is not a story checkpoint."
	var keys := ["schema","progress","player","camera","mounted","ride_distance","companion_id","companion","horse","horse_yaw"]
	var has_companion_yaw: bool = value.schema == CHECKPOINT_SCHEMA
	if has_companion_yaw: keys.append("companion_yaw")
	if value.size()!=keys.size(): return "Invalid checkpoint fields."
	for key in keys:
		if not value.has(key): return "Invalid checkpoint fields."
	var candidate = State.new()
	var error: String = candidate.restore(value.get("progress",null))
	if not error.is_empty() or candidate.sequence_id!=sequence_id: return "This checkpoint belongs to a different or incomplete telling."
	if not _valid_vector(value.get("player"),30) or not _valid_vector(value.get("camera"),TAU): return "Invalid checkpoint pose."
	if not value.get("mounted") is bool or not value.get("ride_distance") is float and not value.get("ride_distance") is int: return "Invalid checkpoint riding state."
	if not is_finite(float(value.ride_distance)) or value.ride_distance<0 or value.ride_distance>100000: return "Invalid checkpoint distance."
	if value.mounted!=bool(candidate.flags.get("mounted",false)): return "The rider state disagrees with the telling."
	var expected_companion := ""
	for i in range(candidate.step_index):
		var beat: Dictionary = candidate.sequence.beats[i]
		for choice in beat.choices:
			if choice.id==candidate.choices[i] and choice.effects.get("escort_following",false) and expected_companion.is_empty(): expected_companion=beat.target
	if value.get("companion_id",null)!=expected_companion: return "The companion state disagrees with the telling."
	if not expected_companion.is_empty() and (not actors.has(expected_companion) or not _valid_vector(value.get("companion"),25)): return "Invalid companion position."
	if expected_companion.is_empty() and value.companion!=[]: return "Unexpected companion position."
	var companion_yaw := 0.0
	if has_companion_yaw:
		if not (value.companion_yaw is float or value.companion_yaw is int) or not is_finite(float(value.companion_yaw)) or absf(float(value.companion_yaw))>TAU:
			return "Invalid companion facing."
		companion_yaw = float(value.companion_yaw)
		if expected_companion.is_empty() and companion_yaw!=0.0: return "Unexpected companion facing."
	elif not expected_companion.is_empty():
		# Old checkpoints did not retain facing. Infer it without changing their
		# saved locations or requiring the player to discard an earlier visit.
		var toward_player := _point(value.player)-_point(value.companion)
		if Vector2(toward_player.x,toward_player.z).length()>0.01:
			companion_yaw = atan2(-toward_player.x,-toward_player.z)
	if is_instance_valid(horse):
		if not _valid_vector(value.get("horse"),25) or not (value.get("horse_yaw") is float or value.get("horse_yaw") is int) or not is_finite(float(value.horse_yaw)) or absf(float(value.horse_yaw))>TAU: return "Invalid horse position."
		var record := {"position":value.horse,"yaw":float(value.horse_yaw),"grounded":true}
		if not horse.record_fits_world(record,avatar): return "The remembered horse position is obstructed."
	elif value.horse!=[] or value.horse_yaw!=0: return "Unexpected horse position."
	if not value.mounted and not _clear_avatar_at(_point(value.player)): return "The remembered place is obstructed."
	# Validate future body positions together, rather than testing a saved player
	# against the companion's current position before that companion is restored.
	var actor_positions: Dictionary = {}
	for id in actors:
		actor_positions[id] = _point(value.companion) if id==expected_companion else stations[id].global_position
		if not _clear_avatar_at(actor_positions[id]): return "A remembered companion place is obstructed."
		if not value.mounted and id!=expected_companion and _flat_distance(_point(value.player),actor_positions[id])<0.65:
			return "The remembered player and household overlap."
		if is_instance_valid(horse) and _flat_distance(_point(value.horse),actor_positions[id])<1.1:
			return "The remembered horse and household overlap."
	for id in actor_positions:
		for other in actor_positions:
			if id!=other and _flat_distance(actor_positions[id],actor_positions[other])<0.6: return "The remembered household overlaps."
	if is_instance_valid(horse) and not value.mounted and _flat_distance(_point(value.player),_point(value.horse))<1.15:
		return "The remembered player and horse overlap."
	if is_instance_valid(companion):
		companion.remove_collision_exception_with(avatar)
		avatar.remove_collision_exception_with(companion)
	for id in actors:
		actors[id].global_position = actor_positions[id]
		actors[id].rotation = Vector3.ZERO
		actors[id].velocity = Vector3.ZERO
	model = candidate
	mounted = value.mounted
	ride_distance = float(value.ride_distance)
	companion_id = expected_companion
	companion = actors[companion_id] if not companion_id.is_empty() else null
	if is_instance_valid(companion):
		companion.global_position = _point(value.companion)
		companion.rotation.y = companion_yaw
		companion.velocity = Vector3.ZERO
		companion.add_collision_exception_with(avatar)
		avatar.add_collision_exception_with(companion)
	if is_instance_valid(horse):
		horse.global_position = _point(value.horse)
		horse.rotation.y = float(value.horse_yaw)
		horse.speed = 0
		horse.velocity = Vector3.ZERO
	avatar.global_position = horse.saddle_support_point() if mounted else _point(value.player)
	avatar.velocity = Vector3.ZERO
	avatar.pivot.rotation = _point(value.camera)
	avatar.set_physics_process(not mounted and not paused)
	avatar.input_enabled = not mounted and not paused
	avatar.get_node("CollisionShape3D").set_deferred("disabled",mounted)
	avatar.get_node("CameraPivot/SpringArm3D").spring_length = 7.0 if mounted else 5.5
	avatar.clear_motion_requests()
	_costume.sample_tick(execution_steps)
	_sample_rider()
	_pending_choice = ""
	_interaction_requested = false
	_refresh()
	return "Checkpoint recalled."

func _flat_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func _clear_avatar_at(at: Vector3, extra_rid := RID()) -> bool:
	if absf(at.x)>22 or absf(at.z)>22 or at.y< -0.02 or at.y>0.25: return false
	if _regency_access != null and not _regency_access.pose_allowed(at): return false
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	query.shape = shape
	query.transform.origin = at+Vector3.UP*0.83
	query.collision_mask = 1
	var exclusions: Array[RID] = [avatar.get_rid()]
	if extra_rid.is_valid(): exclusions.append(extra_rid)
	for actor in actors.values(): exclusions.append(actor.get_rid())
	if is_instance_valid(horse): exclusions.append(horse.get_rid())
	query.exclude = exclusions
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
