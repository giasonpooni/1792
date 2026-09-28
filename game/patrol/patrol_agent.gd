extends CharacterBody3D
## Friendly dismounted trooper blockout. One scene-owned physical executor.
const Rules := preload("res://patrol/companion_rules.gd")
var limbs: Array[Node3D] = []
var stride := 0.0
var entity_id := ""
var caption: Label3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	_piece(self, Vector3(0.55, 0.78, 0.36), Vector3(0, 1.12, 0), Color("797858"))
	_piece(self, Vector3(0.27, 0.30, 0.28), Vector3(0, 1.64, 0), Color("ab8966"))
	_piece(self, Vector3(0.36, 0.20, 0.36), Vector3(0, 1.85, 0), Color("48575a"))
	for x in [-0.15, 0.15]:
		var leg := Node3D.new()
		leg.position = Vector3(x, 0.78, 0)
		add_child(leg)
		_piece(leg, Vector3(0.18, 0.72, 0.22), Vector3(0, -0.37, 0), Color("414339"))
		limbs.append(leg)
	for x in [-0.36, 0.36]:
		_piece(self, Vector3(0.16, 0.63, 0.19), Vector3(x, 1.13, 0), Color("797858"))
	_piece(self, Vector3(0.08, 1.0, 0.08), Vector3(0.32, 1.0, 0.22), Color("43382b"))
	caption = Label3D.new()
	caption.position.y = 2.3
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size = 18
	caption.fixed_size = true
	caption.pixel_size = 0.0015
	caption.outline_size = 5
	add_child(caption)
	set_physics_process(false)

func apply(record: Dictionary) -> void:
	global_position = Rules.point(record.position)
	rotation.y = record.yaw
	velocity = Rules.point(record.velocity)

func step(delta: float, waypoint: Vector3, moving: bool) -> Dictionary:
	var direction := waypoint - global_position
	direction.y = 0
	var speed := minf(Rules.SPEED, direction.length() / delta) if moving and direction.length() > 0.2 else 0.0
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0 if is_on_floor() else maxf(-50.0, velocity.y - 22.0 * delta)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if speed > 0.1:
		rotation.y = atan2(-direction.x, -direction.z)
	stride += Vector2(velocity.x, velocity.z).length() * delta * 2.5
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(stride + i * PI) * (0.4 if speed > 0.1 else 0.0)
	return {"id": entity_id, "position": [global_position.x, global_position.y, global_position.z],
		"yaw": rotation.y, "velocity": [velocity.x, minf(0.0, velocity.y), velocity.z]}

func _piece(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	parent.add_child(visual)
