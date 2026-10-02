# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Third-person hawk scouting layer for the active Home chapter.
## The bird is a local gameplay sensor. It does not write the campaign save or move the player body.

const Rules := preload("res://scouting/hawk_scout_rules.gd")

var active := false
var chapter: Node3D
var avatar: CharacterBody3D
var horse: CharacterBody3D
var camera: Camera3D
var launch_origin := Vector3.ZERO
var _previous_avatar_input := true
var _current_tick := 0
var _status := "Press E or left click to tag a visible hostile."
var _bird: Node3D
var _left_wing: MeshInstance3D
var _right_wing: MeshInstance3D
var _camera_pivot: Node3D
var _hud_layer: CanvasLayer
var _hud: Label
var _targets: Dictionary = {}
var _tags: Dictionary = {}

func _ready() -> void:
	set_meta("classification", "authored-gameplay-scouting")
	set_meta("historical_claim", false)
	set_meta("save_authority", false)
	set_meta("observation_semantics", "transient-last-seen")
	_build_visuals()

func bind(chapter_node: Node3D, avatar_node: CharacterBody3D, horse_node: CharacterBody3D) -> void:
	chapter = chapter_node
	avatar = avatar_node
	horse = horse_node
	_bird.visible = false
	_hud_layer.visible = false

func register_target(target_id: String, node: Node3D, label: String) -> void:
	if target_id.is_empty() or not is_instance_valid(node):
		return
	_targets[target_id] = {"node": node, "label": label}

func launch() -> String:
	if active:
		return "The hawk is already scouting."
	if not is_instance_valid(chapter) or not is_instance_valid(avatar) or not is_instance_valid(horse):
		return "The hawk is not bound to the active Home chapter."
	_previous_avatar_input = avatar.input_enabled
	avatar.input_enabled = false
	avatar.velocity = Vector3.ZERO
	launch_origin = avatar.global_position
	var forward: Vector3 = -avatar.pivot.global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.000001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	global_position = Rules.bound_position(launch_origin, launch_origin + Vector3.UP * 8.5 + forward * 2.0)
	rotation = Vector3(0.0, avatar.pivot.global_rotation.y, 0.0)
	_camera_pivot.rotation.x = -0.22
	_bird.visible = true
	_hud_layer.visible = true
	camera.current = true
	active = true
	_status = "Scout airborne. E / click tags a clear hostile; X or Esc returns."
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()
	return ""

func return_to_player() -> void:
	if not active:
		return
	active = false
	_bird.visible = false
	_hud_layer.visible = false
	camera.current = false
	if is_instance_valid(avatar):
		var player_camera := avatar.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
		if is_instance_valid(player_camera):
			player_camera.current = true
		avatar.input_enabled = _previous_avatar_input
		avatar.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_input(event: InputEvent) -> bool:
	if not active:
		return false
	if event is InputEventMouseMotion:
		rotation.y = wrapf(rotation.y - event.relative.x * 0.0026, -PI, PI)
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - event.relative.y * 0.0022, -0.75, 0.20)
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tag_best_target()
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_X, KEY_ESCAPE]:
			return_to_player()
			return true
		if event.keycode == KEY_E:
			tag_best_target()
			return true
	return false

func step(delta: float) -> void:
	if not active or not is_instance_valid(chapter) or not is_finite(delta) or delta <= 0.0 or delta > 0.1:
		return
	var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := global_basis.x * stick.x + global_basis.z * stick.y
	direction.y = 0.0
	var speed := Rules.GLIDE_SPEED
	if direction.length_squared() > 0.000001:
		var strength := minf(stick.length(), 1.0)
		direction = direction.normalized()
		speed = lerpf(Rules.GLIDE_SPEED, Rules.FAST_SPEED if Input.is_action_pressed("sprint") else Rules.CRUISE_SPEED, strength)
	else:
		direction = -global_basis.z
		direction.y = 0.0
		direction = direction.normalized()
	var vertical := 0.0
	if Input.is_key_pressed(KEY_SPACE):
		vertical += Rules.CLIMB_SPEED
	if Input.is_key_pressed(KEY_CTRL):
		vertical -= Rules.CLIMB_SPEED
	var candidate := global_position + direction * speed * delta + Vector3.UP * vertical * delta
	candidate = Rules.bound_position(launch_origin, candidate)
	var exclude: Array[RID] = []
	if is_instance_valid(avatar):
		exclude.append(avatar.get_rid())
	if is_instance_valid(horse):
		exclude.append(horse.get_rid())
	var query := PhysicsRayQueryParameters3D.create(global_position, candidate, 1, exclude)
	var hit := chapter.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		candidate = Rules.bound_position(launch_origin, hit.position + hit.normal * 0.45)
	global_position = candidate
	var bank := clampf(-stick.x * 0.32, -0.32, 0.32)
	_bird.rotation.z = lerpf(_bird.rotation.z, bank, minf(1.0, delta * 7.0))
	var flap := sin(float(_current_tick) * 0.24) * 0.34
	_left_wing.rotation.z = flap
	_right_wing.rotation.z = -flap
	_update_hud()

func sample(tick: int) -> void:
	_current_tick = tick
	for id in _tags.keys():
		var record: Dictionary = _tags[id]
		var observation: Dictionary = record.observation
		if tick >= int(observation.expires_tick):
			var marker: Node3D = record.marker
			if is_instance_valid(marker):
				marker.queue_free()
			_tags.erase(id)
		else:
			var marker: Node3D = record.marker
			if is_instance_valid(marker):
				var label := marker.get_node("Label") as Label3D
				var seconds := int(ceil(float(int(observation.expires_tick) - tick) / 60.0))
				label.text = "◇ HAWK TAG · %s · %ds" % [String(observation.label), seconds]
	if active:
		_update_hud()

func tag_best_target() -> Dictionary:
	if not active:
		return {"error": "Launch the hawk before scouting.", "target_id": ""}
	_discover_group_targets()
	var eye := camera.global_position
	var forward := -camera.global_basis.z
	var best_id := ""
	var best_score := -1.0
	var best_point := Vector3.ZERO
	for id in _targets:
		var target_record: Dictionary = _targets[id]
		var node: Node3D = target_record.node
		if not is_instance_valid(node) or not node.visible or not node.is_visible_in_tree():
			continue
		var point := node.global_position + Vector3.UP * float(node.get_meta("hawk_scout_height", 1.15))
		var score := Rules.view_score(eye, forward, point)
		if score < 0.0 or score <= best_score:
			continue
		if not _line_of_sight(node, eye, point):
			continue
		best_id = String(id)
		best_score = score
		best_point = point
	if best_id.is_empty():
		_status = "No scoutable hostile in the reticle with clear line of sight."
		_update_hud()
		return {"error": _status, "target_id": ""}
	var target_record: Dictionary = _targets[best_id]
	var observation := Rules.observation(best_id, String(target_record.label), best_point, _current_tick)
	_write_tag(observation)
	_status = "Tagged %s at its last observed position." % String(target_record.label)
	_update_hud()
	return {"error": "", "target_id": best_id, "observation": observation.duplicate(true)}

func observations() -> Array:
	var result: Array = []
	for id in _tags:
		var record: Dictionary = _tags[id]
		var observation: Dictionary = record.observation
		result.append(observation.duplicate(true))
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result

func clear_tags() -> void:
	for id in _tags:
		var record: Dictionary = _tags[id]
		var marker: Node3D = record.marker
		if is_instance_valid(marker):
			marker.queue_free()
	_tags.clear()

func _discover_group_targets() -> void:
	if not is_instance_valid(chapter):
		return
	for raw in chapter.get_tree().get_nodes_in_group("hawk_scout_hostile"):
		if not raw is Node3D:
			continue
		var node := raw as Node3D
		var target_id := String(node.get_meta("hawk_scout_id", node.name))
		var label := String(node.get_meta("hawk_scout_label", node.name))
		register_target(target_id, node, label)

func _line_of_sight(target: Node3D, eye: Vector3, point: Vector3) -> bool:
	var exclude: Array[RID] = []
	if is_instance_valid(avatar):
		exclude.append(avatar.get_rid())
	if is_instance_valid(horse):
		exclude.append(horse.get_rid())
	var query := PhysicsRayQueryParameters3D.create(eye, point, 1, exclude)
	var hit := chapter.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.collider
	if collider == target:
		return true
	return collider is Node and target.is_ancestor_of(collider)

func _write_tag(observation: Dictionary) -> void:
	var id := String(observation.id)
	var marker: Node3D
	if _tags.has(id):
		var previous: Dictionary = _tags[id]
		marker = previous.marker
	else:
		marker = Node3D.new()
		marker.name = "Tag_" + id
		chapter.add_child(marker)
		var pin := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		pin.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("d6b46d")
		material.emission_enabled = true
		material.emission = Color("d6b46d")
		material.emission_energy_multiplier = 1.2
		pin.material_override = material
		marker.add_child(pin)
		var label := Label3D.new()
		label.name = "Label"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 26
		label.pixel_size = 0.0028
		label.position = Vector3(0.0, 0.32, 0.0)
		marker.add_child(label)
	marker.global_position = Rules.observation_position(observation) + Vector3.UP * 0.45
	_tags[id] = {"observation": observation.duplicate(true), "marker": marker}

func _update_hud() -> void:
	if not active or not is_instance_valid(_hud):
		return
	var radius := Vector2(global_position.x - launch_origin.x, global_position.z - launch_origin.z).length()
	var altitude := global_position.y - launch_origin.y
	_hud.text = "HAWK SCOUT · authored gameplay sensor\nRange %.1f / %.0f m · altitude %.1f m\nWASD fly · Shift fast · Space/Ctrl altitude · mouse look\nE / left click tag · X / Esc return\n%s" % [radius, Rules.MAX_RADIUS, altitude, _status]

func _build_visuals() -> void:
	_bird = Node3D.new()
	_bird.name = "HawkBody"
	add_child(_bird)
	_sphere(_bird, "Body", Vector3.ZERO, Vector3(0.34, 0.22, 0.72), Color("66503a"))
	_sphere(_bird, "Head", Vector3(0.0, 0.05, -0.52), Vector3(0.24, 0.22, 0.28), Color("786047"))
	var beak := _box(_bird, "Beak", Vector3(0.12, 0.08, 0.26), Vector3(0.0, 0.02, -0.78), Color("b18a50"))
	beak.rotation.x = -0.08
	_left_wing = _box(_bird, "LeftWing", Vector3(1.45, 0.06, 0.52), Vector3(-0.83, 0.02, -0.02), Color("584635"))
	_right_wing = _box(_bird, "RightWing", Vector3(1.45, 0.06, 0.52), Vector3(0.83, 0.02, -0.02), Color("584635"))
	_left_wing.rotation.y = -0.08
	_right_wing.rotation.y = 0.08
	_box(_bird, "Tail", Vector3(0.42, 0.05, 0.62), Vector3(0.0, -0.01, 0.56), Color("4f4032"))

	_camera_pivot = Node3D.new()
	_camera_pivot.name = "ScoutCameraPivot"
	_camera_pivot.position = Vector3(0.0, 0.4, 0.0)
	add_child(_camera_pivot)
	camera = Camera3D.new()
	camera.name = "ScoutCamera"
	camera.position = Vector3(0.0, 2.2, 7.5)
	camera.fov = 65.0
	camera.current = false
	_camera_pivot.add_child(camera)

	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 12
	add_child(_hud_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(490, 138)
	_hud_layer.add_child(panel)
	_hud = Label.new()
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_font_size_override("font_size", 17)
	panel.add_child(_hud)

func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)
	return mesh_instance

func _sphere(parent: Node3D, node_name: String, position: Vector3, scale: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 7
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)
	return mesh_instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
