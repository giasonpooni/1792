extends CharacterBody3D
## Physics/presentation adapter. Only the owning scene calls step() in physics time.
## No separate campaign, clock, inventory, save or AI executor lives here.

const Rules := preload("res://mounts/riding_rules.gd")
const HorseVisual := preload("res://mounts/horse_visual.gd")
const WALK := 3.0
const TROT := 6.5
const ACCELERATION := 4.5
const BRAKING := 9.0
const GRAVITY := 22.0
var speed := 0.0
var gait_speed_limit := Rules.MAX_SPEED # Optional supplied-condition cap; original default preserved.
var _rider: Node3D
var _legs: Array[Node3D] = []
var _stride := 0.0
var _hull: CapsuleShape3D
var _visual: Node3D

func _ready() -> void:
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(40.0)
	floor_constant_speed = true
	set_physics_process(false)
	_hull = CapsuleShape3D.new()
	_hull.radius = 0.8
	_hull.height = 3.2 # Conservative horse+rider hull; no mesh-perfect collision claim.
	var collider := CollisionShape3D.new()
	collider.name = "Hull"
	collider.position.y = 1.6
	collider.shape = _hull
	add_child(collider)
	_build_blockout()
	# Preserve legacy leg/rider handles; the visual adapter has no physics authority.
	for node in get_children():
		if node is MeshInstance3D:
			node.hide()
	for leg in _legs:
		for node in leg.get_children():
			if node is MeshInstance3D:
				node.hide()
	_visual = HorseVisual.new()
	_visual.name = "HorseVisual"
	add_child(_visual)
	_visual.build()

func apply_record(record: Dictionary) -> void:
	global_position = Rules.position(record)
	rotation.y = record.yaw
	speed = record.speed
	velocity = -global_basis.z * speed + Vector3.UP * record.vertical_speed
	_rider.visible = record.rider_id != ""
	if is_instance_valid(_visual):
		_visual.sample(speed, _stride)

func step(delta: float, throttle: float, steering: float, canter: bool, walk: bool, brake: bool) -> Dictionary:
	var maximum := minf(gait_speed_limit, Rules.MAX_SPEED if canter else WALK if walk else TROT)
	var target := maximum * clampf(throttle, 0.0, 1.0) if not brake else 0.0
	speed = move_toward(speed, target, (ACCELERATION if target > speed else BRAKING) * delta)
	# No sideways strafe or instantaneous high-speed turn. Low-speed pivot is allowed.
	var turn_rate := lerpf(1.9, 0.65, speed / Rules.MAX_SPEED)
	rotation.y = wrapf(rotation.y - clampf(steering, -1.0, 1.0) * turn_rate * delta, -PI, PI)
	var forward := -global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y = 0.0 if is_on_floor() else maxf(-Rules.MAX_FALL, velocity.y - GRAVITY * delta)
	move_and_slide()
	# Do not store requested speed when a wall prevented movement.
	speed = clampf(Vector2(velocity.x, velocity.z).length(), 0.0, Rules.MAX_SPEED)
	if is_on_floor():
		velocity.y = 0.0
	_stride += speed * delta * 2.2
	for i in range(_legs.size()):
		_legs[i].rotation.x = sin(_stride + (PI if i in [1, 2] else 0.0)) * minf(speed / 12.0, 0.55)
	_visual.sample(speed, _stride)
	return {"position": [global_position.x, global_position.y, global_position.z],
		"yaw": rotation.y, "speed": speed, "vertical_speed": minf(0.0, velocity.y), "grounded": is_on_floor()}

func saddle_support_point() -> Vector3:
	return _visual.saddle_support_point()

func bridle_points_world() -> Array[Vector3]:
	return _visual.bridle_points_world()

func clear_mount_path(avatar: CharacterBody3D) -> bool:
	# Mounting is a discrete transfer, but the whole walking hull must fit along
	# the approach. A clear elevated ray alone admits narrow gaps and low walls.
	var collider := avatar.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collider == null or collider.disabled or collider.shape == null:
		return false
	var space := get_world_3d().direct_space_state
	var exclusions: Array[RID] = [get_rid(), avatar.get_rid()]
	var ray := PhysicsRayQueryParameters3D.create(avatar.global_position + Vector3.UP,
		global_position + Vector3.UP * 1.4, avatar.collision_mask, exclusions)
	if not space.intersect_ray(ray).is_empty():
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.collision_mask = avatar.collision_mask
	query.exclude = exclusions
	var start := collider.global_transform
	# Match the existing dismount floor clearance without shrinking the hull.
	start.origin += Vector3.UP * 0.04
	var motion := global_position - avatar.global_position
	query.transform = start
	# cast_motion ignores existing overlaps; qualify both ends independently.
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.transform.origin += motion
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.transform = start
	query.motion = motion
	var fraction := space.cast_motion(query)
	return fraction.size() == 2 and fraction[0] == 1.0 and fraction[1] == 1.0

func dismount_position(avatar: CharacterBody3D) -> Variant:
	# Try both sides, then rear/front. Ray ground, capsule clearance, swept path.
	var space := get_world_3d().direct_space_state
	var exclusions: Array[RID] = [get_rid(), avatar.get_rid()]
	for offset in [global_basis.x * 1.8, -global_basis.x * 1.8, global_basis.z * 2.1, -global_basis.z * 2.1]:
		var p: Vector3 = global_position + offset
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.65, p - Vector3.UP * 0.8, 1, exclusions)
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < cos(deg_to_rad(40.0)):
			continue
		var landing: Vector3 = hit.position + Vector3.UP * 0.04
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.35
		shape.height = 1.6
		query.shape = shape
		query.exclude = exclusions
		query.collision_mask = 1
		query.transform = Transform3D(Basis.IDENTITY, landing + Vector3.UP * 0.8)
		if not space.intersect_shape(query, 1).is_empty():
			continue
		var start := global_position + Vector3.UP * 0.84
		query.transform.origin = start
		query.motion = landing + Vector3.UP * 0.8 - start
		var fraction := space.cast_motion(query)
		if fraction.size() == 2 and fraction[0] >= 0.999:
			return landing
	return null

func record_fits_world(record: Dictionary, avatar: CharacterBody3D) -> bool:
	# Domain validation runs first. Check loaded pose without mutating this body.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _hull
	query.collision_mask = 1
	query.exclude = [get_rid(), avatar.get_rid()]
	query.transform = Transform3D(Basis(Vector3.UP, record.yaw), Rules.position(record) + Vector3.UP * 1.65)
	if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return false
	if record.grounded:
		var p := Rules.position(record)
		var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.1, p - Vector3.UP * 0.2, 1, query.exclude)
		var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
		return not floor_hit.is_empty() and floor_hit.normal.y >= cos(deg_to_rad(40.0))
	return true

func _piece(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	visual.material_override = material
	parent.add_child(visual)
	return visual

func _build_blockout() -> void:
	var coat := Color("75492e")
	var dark := Color("302721")
	_piece(self, Vector3(0.8, 0.8, 1.8), Vector3(0, 1.1, 0), coat)
	var neck := _piece(self, Vector3(0.45, 0.9, 0.6), Vector3(0, 1.6, -0.7), coat)
	neck.rotation.x = -0.35
	_piece(self, Vector3(0.46, 0.42, 0.8), Vector3(0, 1.95, -1.0), coat)
	_piece(self, Vector3(0.4, 0.23, 0.27), Vector3(0, 1.83, -1.35), Color("ad9073"))
	for x in [-0.17, 0.17]:
		_piece(self, Vector3(0.1, 0.25, 0.14), Vector3(x, 2.27, -0.79), coat)
		_piece(self, Vector3(0.025, 0.06, 0.07), Vector3(x * 1.4, 2.05, -0.98), dark)
	_piece(self, Vector3(0.12, 0.65, 0.18), Vector3(0, 1.6, -0.4), dark)
	_piece(self, Vector3(0.18, 0.9, 0.15), Vector3(0, 0.95, 0.95), dark)
	for x in [-0.27, 0.27]:
		for z in [-0.58, 0.58]:
			var leg := Node3D.new()
			leg.position = Vector3(x, 1.0, z)
			add_child(leg)
			_piece(leg, Vector3(0.15, 0.86, 0.17), Vector3(0, -0.45, 0), coat)
			_piece(leg, Vector3(0.2, 0.12, 0.24), Vector3(0, -0.89, -0.02), dark)
			_legs.append(leg)
	_piece(self, Vector3(0.91, 0.14, 0.8), Vector3(0, 1.56, 0.15), Color("374e55"))
	_piece(self, Vector3(0.67, 0.18, 0.6), Vector3(0, 1.66, 0.15), dark)
	_rider = Node3D.new()
	add_child(_rider)
	_piece(_rider, Vector3(0.45, 0.7, 0.32), Vector3(0, 2.06, 0.1), Color("c9b585"))
	_piece(_rider, Vector3(0.29, 0.32, 0.29), Vector3(0, 2.57, 0.1), Color("b28e6b"))
	_piece(_rider, Vector3(0.37, 0.22, 0.37), Vector3(0, 2.78, 0.1), Color("51616c"))
	for x in [-0.43, 0.43]:
		_piece(_rider, Vector3(0.19, 0.66, 0.24), Vector3(x, 1.4, 0.15), Color("454440"))
		_piece(_rider, Vector3(0.16, 0.17, 0.64), Vector3(x * 0.7, 2.16, -0.25), Color("c9b585"))
	_rider.hide()
