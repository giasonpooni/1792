# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Two bounded fictional hostile contacts for the hawk-scout prototype.
## Their motion is a deterministic projection of the existing chapter tick, not another simulation clock.

var contacts: Array[Node3D] = []
var _bases: Array[Vector3] = [
	Vector3(-13.5, 0.14, 22.0),
	Vector3(12.0, 0.14, 23.5)
]

func build() -> void:
	if not contacts.is_empty():
		return
	name = "HomeScoutContacts"
	set_meta("classification", "authored-fictional-scout-contacts")
	set_meta("historical_claim", false)
	set_meta("persistent_state", false)
	var specs := [
		{"id":"unknown_northwest_lookout","label":"Unknown northwest lookout","cloth":"765448"},
		{"id":"unknown_northeast_scout","label":"Unknown northeast scout","cloth":"4e5f55"}
	]
	for i in range(specs.size()):
		var contact := Node3D.new()
		contact.name = "ScoutContact%d" % i
		contact.position = _bases[i]
		contact.add_to_group("hawk_scout_hostile")
		contact.set_meta("hawk_scout_id", String(specs[i].id))
		contact.set_meta("hawk_scout_label", String(specs[i].label))
		contact.set_meta("hawk_scout_height", 1.15)
		contact.set_meta("historical_claim", false)
		contact.set_meta("persistent_state", false)
		add_child(contact)
		_build_figure(contact, Color(String(specs[i].cloth)))
		contacts.append(contact)
	sample(0)

func sample(tick: int) -> void:
	if contacts.size() != _bases.size():
		return
	var seconds := float(tick) / 60.0
	for i in range(contacts.size()):
		var side := -1.0 if i == 0 else 1.0
		var drift := sin(seconds * (0.22 + i * 0.035) + i * 1.4) * 1.65
		var depth := cos(seconds * 0.16 + i * 0.8) * 0.55
		contacts[i].position = _bases[i] + Vector3(drift, 0.0, depth)
		contacts[i].rotation.y = side * 0.35 + sin(seconds * 0.12 + i) * 0.22

func _build_figure(parent: Node3D, cloth: Color) -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.23
	body_mesh.height = 1.22
	body_mesh.radial_segments = 10
	body_mesh.rings = 5
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.72, 0.0)
	body.material_override = _material(cloth)
	parent.add_child(body)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.32
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.48, 0.0)
	head.material_override = _material(Color("a99072"))
	parent.add_child(head)

	var staff := MeshInstance3D.new()
	staff.name = "Staff"
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.025
	staff_mesh.bottom_radius = 0.025
	staff_mesh.height = 1.65
	staff_mesh.radial_segments = 8
	staff.mesh = staff_mesh
	staff.position = Vector3(0.28, 0.83, 0.0)
	staff.rotation.z = 0.08
	staff.material_override = _material(Color("574331"))
	parent.add_child(staff)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material
