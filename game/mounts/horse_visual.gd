extends Node3D
## Procedural presentation only. The existing horse motor supplies every sample.
## These poses describe gait rhythm; they are not locomotion or contact simulation.

const SADDLE_CONTACT := Vector3(0.0, 1.72, 0.0)
const BRIDLE_CONTACTS := [Vector3(-0.215, 1.89, -1.37), Vector3(0.215, 1.89, -1.37)]

var _round_mesh: SphereMesh
var _body: Node3D
var _neck: Node3D
var _tail: Node3D
var _hips: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _feet: Array[Node3D] = []
var _hip_rest: Array[Vector3] = []
var _materials: Dictionary = {}

func build() -> void:
	set_process(false)
	set_physics_process(false)
	_round_mesh = SphereMesh.new()
	_round_mesh.radius = 1.0
	_round_mesh.height = 2.0
	_round_mesh.radial_segments = 16
	_round_mesh.rings = 8
	_materials = {
		"coat": _material(Color("805038"), 0.86),
		"chest": _material(Color("73442f"), 0.88),
		"muzzle": _material(Color("695343"), 0.96),
		"hair": _material(Color("30231f"), 0.98),
		"hoof": _material(Color("38322b"), 0.91),
		"eye": _material(Color("171510"), 0.28),
		"leather": _material(Color("423028"), 0.87),
		"cloth": _material(Color("36525b"), 0.98),
		"brass": _material(Color("a48b53"), 0.62, 0.3),
		"sock": _material(Color("b9ab93"), 0.94)
	}
	_body = Node3D.new()
	_body.name = "Trunk"
	add_child(_body)
	_oval(_body, "Barrel", Vector3(0.88, 0.78, 1.85), Vector3(0, 1.23, 0.04), "coat")
	_oval(_body, "Shoulder", Vector3(0.77, 0.88, 0.73), Vector3(0, 1.26, -0.54), "chest")
	_oval(_body, "Haunch", Vector3(0.88, 0.86, 0.79), Vector3(0, 1.24, 0.59), "coat")
	_oval(_body, "Chest", Vector3(0.61, 0.63, 0.54), Vector3(0, 1.13, -0.71), "chest")
	_build_neck()
	_build_tack()
	_build_tail()
	for side in [-1.0, 1.0]:
		for front in [true, false]:
			_build_leg(side, front)
	sample(0.0, 0.0)

func sample(speed: float, stride: float) -> void:
	# No delta, clock, RNG or callback: a paused owner leaves every transform frozen.
	var motion := clampf(speed / 12.0, 0.0, 0.55)
	_body.position.y = sin(stride * 2.0) * motion * 0.036
	_neck.rotation.x = sin(stride * 2.0 + 0.4) * motion * 0.065
	_tail.rotation.x = sin(stride + 0.7) * motion * 0.10
	_tail.rotation.z = sin(stride * 0.5) * motion * 0.18
	for i in range(_hips.size()):
		var phase := stride + (PI if i in [1, 2] else 0.0)
		var swing := sin(phase)
		var lift := maxf(0.0, -cos(phase))
		_hips[i].position = _hip_rest[i] + Vector3.UP * lift * motion * 0.12
		_hips[i].rotation.x = swing * motion * 0.69
		_knees[i].rotation.x = lift * motion * (0.76 if i in [0, 2] else -0.61)
		_feet[i].rotation.x = -_hips[i].rotation.x * 0.40 - _knees[i].rotation.x * 0.50

func saddle_support_point() -> Vector3:
	# The seat is attached to the fixed motor frame, so support is not shifted by bob.
	return to_global(SADDLE_CONTACT)

func bridle_points_world() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point in BRIDLE_CONTACTS:
		result.append(_neck.to_global(point))
	return result

func _build_neck() -> void:
	_neck = Node3D.new()
	_neck.name = "NeckAndHead"
	add_child(_neck)
	var neck := _oval(_neck, "Neck", Vector3(0.49, 1.02, 0.57), Vector3(0, 1.65, -0.71), "coat")
	neck.rotation.x = -0.34
	_oval(_neck, "Throat", Vector3(0.39, 0.65, 0.41), Vector3(0, 1.75, -0.91), "chest")
	var head := _oval(_neck, "Head", Vector3(0.42, 0.41, 0.82), Vector3(0, 1.99, -1.08), "coat")
	head.rotation.x = 0.30
	var muzzle := _oval(_neck, "Muzzle", Vector3(0.35, 0.28, 0.52), Vector3(0, 1.86, -1.40), "muzzle")
	muzzle.rotation.x = 0.18
	for side in [-1.0, 1.0]:
		var ear := _oval(_neck, "Ear", Vector3(0.11, 0.24, 0.14), Vector3(side * 0.16, 2.24, -0.88), "coat")
		ear.rotation.z = -side * 0.19
		var inner := _oval(_neck, "InnerEar", Vector3(0.050, 0.13, 0.043), Vector3(side * 0.16, 2.255, -0.948), "muzzle")
		inner.rotation.z = ear.rotation.z
		_oval(_neck, "EyeSocket", Vector3(0.043, 0.070, 0.09), Vector3(side * 0.198, 2.05, -1.16), "chest")
		_oval(_neck, "Eye", Vector3(0.028, 0.040, 0.061), Vector3(side * 0.214, 2.055, -1.173), "eye")
		_oval(_neck, "Nostril", Vector3(0.018, 0.038, 0.068), Vector3(side * 0.156, 1.89, -1.555), "hair")
	# Broken, tapered locks read as a mane without a rigid rectangular fin.
	for i in range(7):
		var t := float(i) / 6.0
		var at := Vector3(0.0, lerpf(2.19, 1.34, t), lerpf(-0.69, -0.37, t))
		var lock := _oval(_neck, "ManeLock", Vector3(0.16, 0.24, lerpf(0.22, 0.15, t)), at, "hair")
		lock.rotation.x = -0.27
	_oval(_neck, "Forelock", Vector3(0.16, 0.20, 0.14), Vector3(0, 2.17, -1.12), "hair")
	for side in [-1.0, 1.0]:
		var ring := Vector3(side * 0.215, 1.89, -1.37)
		_strap(_neck, "CheekStrap", Vector3(side * 0.215, 2.18, -0.94), ring, 0.018)
		_strap(_neck, "ThroatStrap", Vector3(side * 0.215, 2.15, -0.89), Vector3(side * 0.195, 1.79, -0.96), 0.016)
		_oval(_neck, "BitRing", Vector3(0.045, 0.066, 0.066), ring, "brass")
	_strap(_neck, "BrowBand", Vector3(-0.20, 2.15, -1.09), Vector3(0.20, 2.15, -1.09), 0.017)
	_strap(_neck, "NoseBand", Vector3(-0.196, 1.94, -1.405), Vector3(0.196, 1.94, -1.405), 0.019)
	_strap(_neck, "Bit", BRIDLE_CONTACTS[0], BRIDLE_CONTACTS[1], 0.010, "brass")

func _build_tack() -> void:
	# Deliberately flat top at 1.72: both single and paired support contracts use it.
	_box(self, "SaddleCloth", Vector3(0.91, 0.065, 0.85), Vector3(0, 1.55, 0.05), "cloth")
	for side in [-1.0, 1.0]:
		_box(self, "ClothDrop", Vector3(0.065, 0.32, 0.78), Vector3(side * 0.437, 1.43, 0.05), "cloth")
		_strap(self, "GirthSide", Vector3(side * 0.443, 1.52, 0.02), Vector3(side * 0.38, 0.98, 0.02), 0.028)
		_oval(self, "SaddleRoll", Vector3(0.16, 0.18, 0.66), Vector3(side * 0.33, 1.62, 0.04), "leather")
		_oval(self, "GirthBuckle", Vector3(0.03, 0.07, 0.058), Vector3(side * 0.457, 1.39, 0.02), "brass")
		_strap(self, "StirrupLeather", Vector3(side * 0.36, 1.67, 0.05), Vector3(side * 0.47, 1.04, 0.05), 0.016)
		_strap(self, "StirrupTread", Vector3(side * 0.47, 1.03, -0.07), Vector3(side * 0.47, 1.03, 0.17), 0.018, "brass")
	_box(self, "SaddleSeat", Vector3(0.65, 0.12, 0.62), Vector3(0, 1.66, 0.05), "leather")
	_oval(self, "Pommel", Vector3(0.50, 0.17, 0.17), Vector3(0, 1.73, -0.28), "leather")
	_oval(self, "Cantle", Vector3(0.56, 0.16, 0.18), Vector3(0, 1.72, 0.39), "leather")
	_strap(self, "GirthBelly", Vector3(-0.38, 0.98, 0.02), Vector3(0.38, 0.98, 0.02), 0.028)

func _build_tail() -> void:
	_tail = Node3D.new()
	_tail.name = "Tail"
	_tail.position = Vector3(0, 1.37, 0.85)
	add_child(_tail)
	_oval(_tail, "TailDock", Vector3(0.16, 0.23, 0.31), Vector3(0, -0.06, 0.10), "coat")
	for i in range(5):
		var t := float(i) / 4.0
		var lock := _oval(_tail, "TailLock", Vector3(lerpf(0.19, 0.12, t), 0.31, 0.19), Vector3(0, -0.17 - t * 0.70, 0.22 + t * 0.09), "hair")
		lock.rotation.x = -0.11

func _build_leg(side: float, front: bool) -> void:
	var hip := Node3D.new()
	hip.name = ("Front" if front else "Hind") + ("Left" if side < 0 else "Right") + "Leg"
	hip.position = Vector3(side * 0.28, 1.16, -0.58 if front else 0.58)
	add_child(hip)
	_hips.append(hip)
	_hip_rest.append(hip.position)
	_segment(hip, "UpperLeg", Vector3.ZERO, Vector3(0, -0.51, 0.02), 0.092 if front else 0.108, "coat")
	_oval(hip, "ShoulderMuscle" if front else "ThighMuscle", Vector3(0.22, 0.38, 0.26), Vector3(0, -0.11, 0.015), "coat")
	var knee := Node3D.new()
	knee.name = "Knee" if front else "Hock"
	knee.position = Vector3(0, -0.51, 0.02)
	hip.add_child(knee)
	_knees.append(knee)
	_oval(knee, "Joint", Vector3(0.17, 0.17, 0.20), Vector3.ZERO, "chest")
	_segment(knee, "Cannon", Vector3.ZERO, Vector3(0, -0.525, -0.015), 0.047, "coat")
	_oval(knee, "Fetlock", Vector3(0.135, 0.15, 0.16), Vector3(0, -0.495, -0.015), "coat")
	if not front and side > 0:
		_segment(knee, "UnequalSock", Vector3(0, -0.40, -0.015), Vector3(0, -0.515, -0.015), 0.050, "sock")
	var foot := Node3D.new()
	foot.name = "Hoof"
	foot.position = Vector3(0, -0.575, -0.02)
	knee.add_child(foot)
	_feet.append(foot)
	_oval(foot, "HoofMass", Vector3(0.18, 0.15, 0.25), Vector3(0, 0, -0.04), "hoof")

func _material(color: Color, roughness: float, metal: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metal
	return result

func _oval(parent: Node3D, label: String, size: Vector3, at: Vector3, material: String) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = label
	result.mesh = _round_mesh
	result.scale = size * 0.5
	result.position = at
	result.material_override = _materials[material]
	parent.add_child(result, true)
	return result

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: String) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	result.mesh = mesh
	result.position = at
	result.material_override = _materials[material]
	parent.add_child(result, true)
	return result

func _strap(parent: Node3D, label: String, start: Vector3, end: Vector3, radius: float, material: String = "leather") -> void:
	_segment(parent, label, start, end, radius, material)

func _segment(parent: Node3D, label: String, start: Vector3, end: Vector3, radius: float, material: String) -> void:
	var result := MeshInstance3D.new()
	result.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = start.distance_to(end) + radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 4
	result.mesh = mesh
	result.position = (start + end) * 0.5
	var axis := (end - start).normalized()
	var across := Vector3.RIGHT if absf(axis.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var side := axis.cross(across).normalized()
	result.basis = Basis(side, axis, side.cross(axis).normalized())
	result.material_override = _materials[material]
	parent.add_child(result, true)
