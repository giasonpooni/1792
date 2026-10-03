# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original lesson staging, sampled from Home's existing clock and authority.
## No process loop, collision, hidden knowledge, independent agent or save state.
const Home := preload("res://childhood/childhood_state.gd")
const TrailFocus := preload("res://presentation/childhood_trail_focus.gd")
const ACTIVE := Color("b78649")
const COMPLETE := Color("64785c")
const REMAINING := Color("81796a")
const STOP_OFFSET := Vector3(0, 0, 4.1)
var trail_focus: Node3D
var gate_flags: Array[Dictionary] = []
var trace_roots: Array[Node3D] = []
var stop_marker: Node3D
var trainer_arm: Node3D
var assailant_arm: Node3D
var assailant_pose: Node3D
var quarry_body: MeshInstance3D
var last_tick := -1
var trainer_pose := "rest"
var threat_pose := "hidden"
var _chapter: Node3D
var _trainer: MeshInstance3D
var _attacker_mesh: MeshInstance3D
var _trainer_rest := Transform3D.IDENTITY
var _attacker_rest := Transform3D.IDENTITY
var _quarry_rest := Transform3D.IDENTITY
var _external_nodes: Array[Node3D] = []
var _hidden_traces: Array[Dictionary] = []
var _costume_arms: Array[Dictionary] = []
var _trainer_costume: Node3D
var _materials: Dictionary = {}

func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.97
		_materials[key] = material
	return _materials[key]

func _node(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	parent.add_child(node)
	return node

func _box(parent: Node3D, label: String, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, label, shape, at, color)

func _mesh(parent: Node3D, label: String, shape: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	return mesh

func _rod(parent: Node3D, label: String, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = from.distance_to(to)
	shape.radial_segments = 6
	var rod := _mesh(parent, label, shape, (from + to) / 2.0, color)
	rod.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return rod

func _oval(parent: Node3D, label: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 10
	shape.rings = 4
	var mesh := _mesh(parent, label, shape, at, color)
	mesh.scale = size
	return mesh

func build(chapter: Node3D) -> void:
	if is_instance_valid(_chapter): return
	_chapter = chapter
	name = "ChildhoodArcStaging"
	set_meta("classification", "original-presentation")
	set_meta("gameplay_authority", false)
	set_process(false)
	set_physics_process(false)
	# Only replace the small, non-colliding trace proxies already in Home.
	# Keep their previous visibility so removing this component is reversible.
	for child in chapter.get_children():
		if not child is Node3D or child is CollisionObject3D: continue
		for node in child.get_children():
			if not node is MeshInstance3D or not node.mesh is BoxMesh: continue
			var size: Vector3 = node.mesh.size
			if size.is_equal_approx(Vector3(0.2, 0.03, 0.35)):
				for index in range(1, 4):
					if node.global_position.distance_to(Home.SITES["track_%d" % index]) < 0.7:
						_hidden_traces.append({"node": node, "visible": node.visible})
						node.hide()
			elif size.is_equal_approx(Vector3(0.65, 0.5, 1.3)) and node.global_position.distance_to(Home.SITES.quarry + Vector3.UP * 0.8) < 0.01:
				quarry_body = node
				_quarry_rest = node.transform
	for index in range(Home.GATES.size()): _build_gate(index)
	_build_stop()
	_build_traces()
	trail_focus = TrailFocus.new()
	add_child(trail_focus)
	trail_focus.build(chapter)
	_trainer = chapter.trainer
	_trainer_rest = _trainer.transform
	trainer_arm = _build_arm(_trainer, "PracticeArm", Vector3(0.31, 0.48, -0.04), Color("a98459"))
	_external_nodes.append(trainer_arm)
	# The pose rig is under the existing assailant: it cannot outlive that body's
	# visibility. The body and its capsule continue to belong to Home's executor.
	for child in chapter.attacker.get_children():
		if child is MeshInstance3D:
			_attacker_mesh = child
			_attacker_rest = child.transform
			break
	assailant_pose = _node(chapter.attacker, "AssailantGesture")
	assailant_arm = _build_arm(assailant_pose, "ThreatArm", Vector3(0.33, 1.22, -0.04), Color("775448"))
	_external_nodes.append(assailant_pose)
	sample()

func _build_gate(index: int) -> void:
	var gate := _node(self, "RidingGate%d" % (index + 1), Home.GATES[index])
	# Keep every upright beside the existing posts, outside the riding lane.
	_rod(gate, "Flagstaff", Vector3(-2.8, 0, 0), Vector3(-2.8, 2.85, 0), 0.045, Color("6d5740"))
	var flag := _node(gate, "NumberedCloth", Vector3(-2.8, 2.42, 0))
	var cloth := _box(flag, "Cloth", Vector3(0.74, 0.68, 0.028), Vector3(-0.36, 0, 0), REMAINING)
	# Numbers are physical stitched lettering, not HUD labels. TextMesh keeps
	# them legible even when the compact HUD suppresses distant speech labels.
	var lettering := TextMesh.new()
	lettering.text = str(index + 1)
	lettering.font = ThemeDB.fallback_font
	lettering.font_size = 72
	lettering.pixel_size = 0.007
	lettering.depth = 0.002
	var number := _mesh(flag, "GateNumber", lettering, Vector3(-0.36, -0.05, 0.018), Color("efe2bd"))
	var reverse := _mesh(flag, "ReverseNumber", lettering, Vector3(-0.36, -0.05, -0.018), Color("efe2bd"))
	reverse.rotation.y = PI
	var stitch := _node(flag, "CompletedStitch")
	_rod(stitch, "ShortStitch", Vector3(-0.52, -0.17, -0.03), Vector3(-0.41, -0.27, -0.03), 0.017, Color("ece0b9"))
	_rod(stitch, "LongStitch", Vector3(-0.41, -0.27, -0.03), Vector3(-0.21, -0.1, -0.03), 0.017, Color("ece0b9"))
	gate_flags.append({"root": gate, "flag": flag, "cloth": cloth, "number": number, "stitch": stitch, "status": "remaining"})

func _build_stop() -> void:
	stop_marker = _node(self, "StopAndSettle", Home.GATES[2] + STOP_OFFSET)
	# Chalk/dust lines lie almost flush with the yard; this is a teaching mark,
	# never an invisible barrier or a second completion trigger.
	for offset in [-1.3, 1.3]:
		_box(stop_marker, "SideDustLine", Vector3(0.055, 0.012, 2.3), Vector3(offset, 0.028, 0), Color("d6c59e"))
	for offset in [-1.15, 1.15]:
		_box(stop_marker, "EndDustLine", Vector3(2.6, 0.012, 0.055), Vector3(0, 0.028, offset), Color("d6c59e"))
	_box(stop_marker, "BrakeLine", Vector3(2.45, 0.012, 0.07), Vector3(0, 0.028, 0.75), Color("a08658"))

func _scrub(parent: Node3D, at: Vector3, seed_offset: int) -> void:
	# A handful of dry stalks at the margin, not a new wetland or a dense wall.
	for index in range(4):
		var angle := float(index + seed_offset) * 1.9
		var base := at + Vector3(cos(angle), 0.02, sin(angle)) * 0.13
		var tip := base + Vector3(cos(angle) * 0.14, 0.23 + index * 0.055, sin(angle) * 0.1)
		_rod(parent, "DryStem", base, tip, 0.012, Color("92905f"))

func _build_traces() -> void:
	var prints := _node(self, "SplitPrints", Home.SITES.track_1)
	trace_roots.append(prints)
	# A quiet patch of exposed soil separates the small dark impressions from
	# the busy market surface; it stays present without selection or emission.
	_build_exposed_soil(prints)
	for step in range(3):
		var center := Vector3(-0.28 + (step % 2) * 0.38, 0.025, -step * 0.32)
		for side in [-1, 1]:
			_oval(prints, "HoofImpression", center + Vector3(side * 0.036, 0, 0), Vector3(0.068, 0.016, 0.21), Color("514635"))
	_scrub(prints, Vector3(-0.95, 0, -0.25), 1)
	var reeds := _node(self, "DisturbedReeds", Home.SITES.track_2)
	trace_roots.append(reeds)
	for index in range(7):
		var base := Vector3(-0.5 + index * 0.14, 0.025, 0.11 * sin(index * 2.3))
		var bend := base + Vector3(0.035, 0.11, -0.15)
		_rod(reeds, "BrokenUpright", base, bend, 0.012, Color("999363"))
		_rod(reeds, "BentReed", bend, base + Vector3(0.06, 0.055, -0.6), 0.011, Color("b3a270"))
	_scrub(reeds, Vector3(0.95, 0, -0.55), 3)
	var grass := _node(self, "CompressedGrass", Home.SITES.track_3)
	trace_roots.append(grass)
	_oval(grass, "PressedEarth", Vector3(0, 0.016, -0.2), Vector3(1.15, 0.015, 0.85), Color("8b8560"))
	for index in range(11):
		var from := Vector3(-0.5 + index * 0.095, 0.035, 0.14 + 0.08 * cos(index * 2.1))
		_rod(grass, "FlattenedBlade", from, from + Vector3(0.08, 0.006, -0.51), 0.009, Color("b4ac76"))
	_scrub(grass, Vector3(-1.0, 0, -0.65), 4)

func _build_exposed_soil(parent: Node3D) -> void:
	# Soft vertex alpha keeps a dust variation from reading like a solid quest
	# decal. No light, pulse, camera-facing billboard or selection state.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color := Color("b29d76")
	for index in range(12):
		for corner in [0, 1, 2]:
			var point := Vector3.ZERO
			var tint := Color(color, 0.0)
			if corner == 0:
				tint.a = 0.80
			else:
				var edge: int = index + corner - 1
				var angle := TAU * float(edge) / 12.0
				var radius := 1.0 + 0.09 * sin(float(edge) * 2.3)
				point = Vector3(cos(angle) * 0.78, 0, sin(angle) * 0.87) * radius
			surface.set_color(tint)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(point)
	var patch := MeshInstance3D.new()
	patch.name = "ExposedSoil"
	patch.mesh = surface.commit()
	patch.position = Vector3(-0.1, 0.012, -0.32)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	patch.material_override = material
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(patch)

func _build_arm(parent: Node3D, label: String, at: Vector3, color: Color) -> Node3D:
	var arm := _node(parent, label, at)
	_rod(arm, "Sleeve", Vector3.ZERO, Vector3(0.03, -0.29, -0.08), 0.065, color)
	_rod(arm, "Forearm", Vector3(0.03, -0.29, -0.08), Vector3(0.025, -0.44, -0.20), 0.045, Color("a18160"))
	_rod(arm, "PracticeStick", Vector3(0.025, -0.45, -0.16), Vector3(0.025, -0.51, -0.85), 0.025, Color("66513a"))
	return arm

func sample() -> void:
	if not is_instance_valid(_chapter) or not is_instance_valid(trainer_arm): return
	_bind_trainer_costume()
	trail_focus.sample()
	var progress: Dictionary = _chapter.model.progress()
	var stage: String = _chapter.model.stage()
	var tick: int = int(progress.tick)
	last_tick = tick
	for index in range(gate_flags.size()):
		var gate: Dictionary = gate_flags[index]
		var status := "complete" if index < int(progress.ride_gate) else "active" if stage == "riding" and index == int(progress.ride_gate) else "remaining"
		gate.status = status
		gate.cloth.material_override = _material(COMPLETE if status == "complete" else ACTIVE if status == "active" else REMAINING)
		gate.stitch.visible = status == "complete"
		gate.flag.rotation.z = 0.025 * sin(float(tick) / 42.0 + index)
	stop_marker.visible = stage in ["riding", "sparring"]
	# The raising, impact and recovery windows are exactly Home's existing ones.
	# Reset the visual after the lesson rather than leaving a raised frozen arm.
	_trainer.transform = _trainer_rest
	trainer_arm.rotation = Vector3.ZERO
	trainer_pose = "rest"
	if stage == "sparring":
		var phase := tick % 150
		if phase >= 90 and phase < 120:
			trainer_pose = "windup"
			trainer_arm.rotation.x = lerpf(0.35, 1.9, float(phase - 90) / 29.0)
			_trainer.rotation.z = -0.12
		elif phase >= 120:
			trainer_pose = "recovery"
			trainer_arm.rotation.x = lerpf(-0.75, 0.0, float(phase - 120) / 29.0)
			_trainer.rotation.z = 0.10 * (1.0 - float(phase - 120) / 29.0)
	_sample_threat(progress, stage)
	if is_instance_valid(quarry_body):
		quarry_body.transform = _quarry_rest
		quarry_body.scale.y *= 1.0 + 0.012 * sin(float(tick) / 29.0)

func _bind_trainer_costume() -> void:
	# Home art is built after the base lesson. Its generic person has a static
	# right sleeve and forearm: replace exactly those two parts, not a third arm.
	if is_instance_valid(_trainer_costume): return
	var costume := _trainer.get_node_or_null("CostumeStudy") as Node3D
	if costume == null: return
	var expected := [Vector3(0.245, 1.125, -0.005), Vector3(0.28, 0.88, -0.03)]
	for mesh in costume.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh is CylinderMesh: continue
		for at in expected:
			if mesh.position.is_equal_approx(at):
				_costume_arms.append({"node": mesh, "visible": mesh.visible})
	if _costume_arms.size() != 2:
		_costume_arms.clear()
		return
	_trainer_costume = costume
	_trainer_costume.visibility_changed.connect(_sync_costume_arm_visibility)
	_sync_costume_arm_visibility()

func _sync_costume_arm_visibility() -> void:
	if not is_instance_valid(_trainer_costume): return
	for record in _costume_arms:
		if is_instance_valid(record.node):
			record.node.visible = false if _trainer_costume.visible else record.visible

func _sample_threat(progress: Dictionary, stage: String) -> void:
	threat_pose = "hidden"
	assailant_pose.visible = stage in ["active", "caught"]
	assailant_pose.transform = Transform3D.IDENTITY
	assailant_arm.rotation = Vector3.ZERO
	if is_instance_valid(_attacker_mesh): _attacker_mesh.transform = _attacker_rest
	if not assailant_pose.visible: return
	# Render an existing threat only. Never turn on the parent body or write seen.
	var threat: Dictionary = progress.ambush
	var offset: Vector3 = _chapter.model.position() - Home.point(threat.position)
	var yaw := atan2(-offset.x, -offset.z) if offset.length_squared() > 0.0001 else 0.0
	assailant_pose.rotation.y = yaw
	if is_instance_valid(_attacker_mesh): _attacker_mesh.rotation.y = yaw
	var tick := int(progress.tick)
	var phase := posmod(tick - int(threat.start_tick), 120)
	var stopped: bool = bool(threat.deflected) or tick <= int(threat.stun_until)
	threat_pose = "rest"
	if stage == "active" and stopped:
		threat_pose = "stagger"
		assailant_pose.rotation.z = 0.25
		assailant_arm.rotation.x = -0.7
		if is_instance_valid(_attacker_mesh): _attacker_mesh.rotation.z = 0.25
	elif stage == "active" and phase >= 90 and Home.distance(_chapter.model.position(), Home.point(threat.position)) < 3.0:
		threat_pose = "windup"
		assailant_arm.rotation.x = lerpf(0.35, 1.9, float(phase - 90) / 29.0)
		if is_instance_valid(_attacker_mesh): _attacker_mesh.rotation.z = -0.12

func _exit_tree() -> void:
	if is_instance_valid(_trainer_costume) and _trainer_costume.visibility_changed.is_connected(_sync_costume_arm_visibility):
		_trainer_costume.visibility_changed.disconnect(_sync_costume_arm_visibility)
	for record in _costume_arms:
		if is_instance_valid(record.node): record.node.visible = record.visible
	for record in _hidden_traces:
		if is_instance_valid(record.node): record.node.visible = record.visible
	if is_instance_valid(_trainer): _trainer.transform = _trainer_rest
	if is_instance_valid(_attacker_mesh): _attacker_mesh.transform = _attacker_rest
	if is_instance_valid(quarry_body): quarry_body.transform = _quarry_rest
	for node in _external_nodes:
		if is_instance_valid(node): node.queue_free()
