# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Bounded remote-observation instrument.
## Extends what the player can physically observe; never invents hidden world state.
const TARGET_GROUP := "hawk_hostile"
const MAX_TETHER := 120.0
const SCAN_RANGE := 55.0
const TAG_SECONDS := 8.0
const SPEED := 16.0
const CLIMB_SPEED := 7.0
const MIN_CLEARANCE := 3.0
const SCAN_PERIOD := 0.12
const FOV_DOT := 0.34

var active := false
var at_limit := false
var _owner: CharacterBody3D
var _owner_camera: Camera3D
var _camera: Camera3D
var _visual: MeshInstance3D
var _origin := Vector3.ZERO
var _scan_clock := 0.0
var _yaw := 0.0
var _pitch := -0.22
var _excluded: Array[RID] = []
var _tags: Dictionary = {}

func bind(owner: CharacterBody3D, excluded_nodes: Array = []) -> void:
	_owner = owner
	_owner_camera = owner.get_node("CameraPivot/SpringArm3D/Camera3D")
	_excluded.clear()
	_excluded.append(owner.get_rid())
	for node in excluded_nodes:
		add_exclusion(node)
	if _camera == null:
		_build()

func add_exclusion(node: Node) -> void:
	if node is CollisionObject3D:
		var rid := (node as CollisionObject3D).get_rid()
		if rid not in _excluded:
			_excluded.append(rid)

func _build() -> void:
	_visual = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.18
	body.height = 0.55
	_visual.mesh = body
	_visual.rotation_degrees = Vector3(0,0,90)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6f5a38")
	material.roughness = 0.9
	_visual.material_override = material
	add_child(_visual)

	var left := MeshInstance3D.new()
	var wing := BoxMesh.new()
	wing.size = Vector3(0.75,0.035,0.26)
	left.mesh = wing
	left.position = Vector3(-0.43,0,0)
	left.material_override = material
	_visual.add_child(left)
	var right := left.duplicate()
	right.position.x = 0.43
	_visual.add_child(right)

	_camera = Camera3D.new()
	_camera.position = Vector3(0,0.32,1.9)
	_camera.fov = 72.0
	add_child(_camera)
	visible = false
	set_physics_process(true)

func release_from_owner() -> String:
	if active:
		return "Hawk is already scouting."
	if not is_instance_valid(_owner) or not is_instance_valid(_owner_camera):
		return "Hawk scout is not bound to a protagonist."
	_origin = _owner.global_position
	global_position = _origin + Vector3.UP * 2.2
	_yaw = _owner.pivot.global_rotation.y
	_pitch = -0.22
	rotation = Vector3(_pitch,_yaw,0)
	active = true
	at_limit = false
	visible = true
	_owner.input_enabled = false
	_owner.velocity = Vector3.ZERO
	_owner_camera.current = false
	_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return ""

func recall() -> void:
	if not active:
		return
	active = false
	at_limit = false
	visible = false
	if is_instance_valid(_camera):
		_camera.current = false
	if is_instance_valid(_owner_camera):
		_owner_camera.current = true
	if is_instance_valid(_owner):
		_owner.input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_input(event: InputEvent) -> bool:
	if not active:
		return false
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw = wrapf(_yaw - event.relative.x * 0.0024,-PI,PI)
		_pitch = clampf(_pitch - event.relative.y * 0.0018,-0.75,0.28)
		rotation = Vector3(_pitch,_yaw,0)
		return true
	return false

func _physics_process(delta: float) -> void:
	_decay_tags(delta)
	if not active or not is_instance_valid(_owner):
		return
	var stick := Input.get_vector("move_left","move_right","move_forward","move_backward")
	var basis_yaw := Basis(Vector3.UP,_yaw)
	var planar := basis_yaw * Vector3(stick.x,0,stick.y)
	if planar.length() > 1.0:
		planar = planar.normalized()
	var vertical := 0.0
	if Input.is_action_pressed("traverse_jump"):
		vertical += CLIMB_SPEED
	if Input.is_key_pressed(KEY_C):
		vertical -= CLIMB_SPEED
	var next := global_position + (planar * SPEED + Vector3.UP * vertical) * delta
	next = _respect_world(next)
	var offset := next - _origin
	at_limit = offset.length() > MAX_TETHER
	if at_limit:
		next = _origin + offset.normalized() * MAX_TETHER
	global_position = next
	_scan_clock += delta
	if _scan_clock >= SCAN_PERIOD:
		_scan_clock = 0.0
		_scan()

func _respect_world(next: Vector3) -> Vector3:
	if not is_inside_tree():
		return next
	var space := get_world_3d().direct_space_state
	var path := PhysicsRayQueryParameters3D.create(global_position,next,1,_excluded)
	var hit := space.intersect_ray(path)
	if not hit.is_empty():
		next = global_position
	var down := PhysicsRayQueryParameters3D.create(next + Vector3.UP,next - Vector3.UP * 30.0,1,_excluded)
	var ground := space.intersect_ray(down)
	if not ground.is_empty():
		next.y = maxf(next.y,float(ground.position.y) + MIN_CLEARANCE)
	return next

func _scan() -> void:
	for target in get_tree().get_nodes_in_group(TARGET_GROUP):
		if not target is Node3D:
			continue
		var node := target as Node3D
		if not node.is_visible_in_tree():
			continue
		if can_observe(node):
			_tag(node)

func can_observe(target: Node3D) -> bool:
	if not active or not is_instance_valid(target) or not target.is_inside_tree():
		return false
	var aim := target.global_position + Vector3.UP
	var delta := aim - global_position
	var distance := delta.length()
	if distance <= 0.001 or distance > SCAN_RANGE:
		return false
	var forward := -global_basis.z
	if forward.normalized().dot(delta.normalized()) < FOV_DOT:
		return false
	var excludes := _excluded.duplicate()
	if target is CollisionObject3D:
		excludes.append((target as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(global_position,aim,1,excludes)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _tag(target: Node3D) -> void:
	var id := target.get_instance_id()
	_tags[id] = {"node":target,"ttl":TAG_SECONDS}
	var marker := target.get_node_or_null("HawkScoutTag") as Label3D
	if marker == null:
		marker = Label3D.new()
		marker.name = "HawkScoutTag"
		marker.text = str(target.get_meta("hawk_tag_label","HOSTILE MOVEMENT"))
		marker.position = Vector3(0,2.25,0)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 22
		marker.pixel_size = 0.002
		marker.modulate = Color(1.0,0.72,0.32,1)
		target.add_child(marker)
	marker.visible = true

func _decay_tags(delta: float) -> void:
	var expired: Array[int] = []
	for id in _tags:
		var record: Dictionary = _tags[id]
		var node: Node3D = record.node
		record.ttl = maxf(0.0,float(record.ttl)-delta)
		_tags[id] = record
		if record.ttl <= 0.0 or not is_instance_valid(node):
			expired.append(id)
	for id in expired:
		var record: Dictionary = _tags[id]
		var node: Node3D = record.node
		if is_instance_valid(node):
			var marker := node.get_node_or_null("HawkScoutTag")
			if marker != null:
				marker.queue_free()
		_tags.erase(id)

func tagged_count() -> int:
	return _tags.size()

func tagged_instance_ids() -> Array:
	return _tags.keys()
