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
const DISMOUNT_CLEARANCE_LIFTS := [0.0,0.02,0.04,0.06,0.08,0.12,0.16]
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
func _avatar_collider(avatar: CharacterBody3D, allow_disabled: bool = false) -> CollisionShape3D:
	var collider: CollisionShape3D=avatar.get_node_or_null("CollisionShape3D")
	if collider==null or (collider.disabled and not allow_disabled) or collider.shape==null: return null
	if not avatar.global_transform.is_finite() or not collider.transform.is_finite(): return null
	return collider

func _avatar_query(avatar: CharacterBody3D,collider: CollisionShape3D,body_transform: Transform3D) -> PhysicsShapeQueryParameters3D:
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=collider.shape;query.transform=body_transform*collider.transform
	query.collision_mask=collision_mask;query.exclude=[get_rid(),avatar.get_rid()]
	return query

func _raised_clear_avatar(space: PhysicsDirectSpaceState3D,avatar: CharacterBody3D,collider: CollisionShape3D,body_transform: Transform3D) -> Variant:
	# An upright capsule needs slightly more vertical clearance on a slope than
	# on a flat plane. Search a small declared lift; never alter the real shape.
	for lift in DISMOUNT_CLEARANCE_LIFTS:
		var candidate:=body_transform;candidate.origin+=Vector3.UP*lift
		if space.intersect_shape(_avatar_query(avatar,collider,candidate),1).is_empty():
			return candidate
	return null

func clear_mount_path(avatar: CharacterBody3D) -> bool:
	# Mounting removes the walking body only after admission. Sweep its actual
	# configured shape and local transform to the horse; an eye-height ray could
	# miss a low wall that the avatar capsule cannot cross.
	var collider:=_avatar_collider(avatar)
	if collider==null or collision_mask==0: return false
	var space:=get_world_3d().direct_space_state
	var clear_start:Variant=_raised_clear_avatar(space,avatar,collider,avatar.global_transform)
	var destination:=avatar.global_transform;destination.origin=global_position
	var clear_destination:Variant=_raised_clear_avatar(space,avatar,collider,destination)
	# Resting player and horse contacts can differ by a few millimetres. Use the
	# same bounded support clearance as dismounting before sweeping the full hull.
	if clear_start==null or clear_destination==null: return false
	var query:=_avatar_query(avatar,collider,clear_start)
	destination=clear_destination
	query.motion=(destination*collider.transform).origin-query.transform.origin
	var fraction:=space.cast_motion(query)
	return fraction.size()==2 and fraction[0]>=0.999

func dismount_position(avatar: CharacterBody3D) -> Variant:
	# Try both sides, then rear/front. Ray ground, then clear and sweep the same
	# collision shape/local transform that resumes walking after dismount.
	var space := get_world_3d().direct_space_state
	# A seated scene may disable its walking shape. Admission still sweeps that
	# configured shape before the scene reenables it at the accepted landing.
	var collider:=_avatar_collider(avatar,true)
	if collider==null or collision_mask==0: return null
	var exclusions: Array[RID]=[get_rid(),avatar.get_rid()]
	for offset in [global_basis.x * 1.8, -global_basis.x * 1.8, global_basis.z * 2.1, -global_basis.z * 2.1]:
		var p: Vector3 = global_position + offset
		# Cover the full vertical change possible across this horizontal offset at
		# the horse's admitted floor angle. The old fixed ray missed both the
		# uphill and downhill exits on a 30-degree support.
		var reach:=maxf(0.8,offset.length()*tan(floor_max_angle)+0.2)
		var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*reach,p-Vector3.UP*reach,collision_mask,exclusions)
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < cos(deg_to_rad(40.0)):
			continue
		var destination:=avatar.global_transform;destination.origin=hit.position+Vector3.UP*0.04
		var clear_destination:Variant=_raised_clear_avatar(space,avatar,collider,destination)
		var clear_start:Variant=_raised_clear_avatar(space,avatar,collider,avatar.global_transform)
		if clear_destination==null or clear_start==null: continue
		var query:=_avatar_query(avatar,collider,clear_start)
		var target_origin: Vector3=(clear_destination*collider.transform).origin
		query.motion=target_origin-query.transform.origin
		var fraction := space.cast_motion(query)
		if fraction.size() == 2 and fraction[0] >= 0.999:
			return clear_destination.origin
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
