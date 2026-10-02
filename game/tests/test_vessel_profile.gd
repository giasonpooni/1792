# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const VesselProfile := preload("res://presentation/vessel_profile.gd")
const Launch := preload("res://childhood/home_launch.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("VESSEL_PROFILE FAIL: " + label)

func _mesh_contract(radius: float, height: float, variant: int) -> void:
	var mesh: ArrayMesh = VesselProfile.build(radius, height, variant)
	var label := "r=%s h=%s variant=%d: " % [radius, height, variant]
	check(mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES, label + "one bounded triangle surface")
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var finite := vertices.size() > 100 and vertices.size() < 2000 and vertices.size() == normals.size() and vertices.size() == uvs.size()
	var bounded := true
	var unit_normals := true
	var valid_uvs := true
	var max_radius := 0.0
	var min_y := INF
	var max_y := -INF
	var outward_count := 0
	var inward_count := 0
	for i in range(vertices.size()):
		var p := vertices[i]
		var n := normals[i]
		var uv := uvs[i]
		finite = finite and p.is_finite() and n.is_finite() and uv.is_finite()
		var r := Vector2(p.x, p.z).length()
		bounded = bounded and r <= radius + 0.0000001 and absf(p.y) <= height * 0.5 + 0.0000001
		max_radius = maxf(max_radius, r)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
		unit_normals = unit_normals and is_equal_approx(n.length(), 1.0)
		valid_uvs = valid_uvs and uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0
		if r > radius * 0.985 and n.dot(Vector3(p.x, 0.0, p.z).normalized()) > 0.9:
			outward_count += 1
		if r > radius * 0.3 and n.dot(Vector3(p.x, 0.0, p.z).normalized()) < -0.6:
			inward_count += 1
	check(finite, label + "finite paired positions, analytic normals and UVs within vertex budget")
	check(bounded and is_equal_approx(max_radius, radius) and is_equal_approx(min_y, -height * 0.5) and is_equal_approx(max_y, height * 0.5), label + "exact previous-cylinder maximum radius and elevations; no envelope expansion")
	check(unit_normals and outward_count >= 24 and inward_count >= 24, label + "unit normals include outward belly and inward cavity")
	check(valid_uvs, label + "finite normalized UVs on wall, lip, floor and base")
	check(_closed_oriented_shell(vertices, normals, indices), label + "nondegenerate correctly facing triangles and watertight oriented shell")
	var hits := _axis_heights(vertices, indices, height)
	check(hits.size() == 2 and is_equal_approx(hits[0], -height * 0.5) and hits[1] > -height * 0.45 and hits[1] < 0.0, label + "open mouth reaches interior floor above the closed underside")
	check(mesh.surface_get_material(0) == null and mesh.get_meta("historical_claim", true) == false and mesh.get_meta("gameplay_authority", true) == false, label + "mesh only, caller-owned material, no historical or state admission")
	var repeated := VesselProfile.build(radius, height, variant).surface_get_arrays(0)
	check(vertices == repeated[Mesh.ARRAY_VERTEX] and normals == repeated[Mesh.ARRAY_NORMAL] and uvs == repeated[Mesh.ARRAY_TEX_UV] and indices == repeated[Mesh.ARRAY_INDEX], label + "same inputs reproduce identical mesh arrays")

func _closed_oriented_shell(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> bool:
	if indices.size() == 0 or indices.size() % 3 != 0:
		return false
	# Weld only for topology inspection: actual mesh keeps UV seams and hard lip/floor edges.
	var welded := {}
	var ids: Array[int] = []
	for p in vertices:
		var key := Vector3i(roundi(p.x * 1000000.0), roundi(p.y * 1000000.0), roundi(p.z * 1000000.0))
		if not welded.has(key):
			welded[key] = welded.size()
		ids.append(welded[key])
	var edges := {}
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		if a < 0 or b < 0 or c < 0 or a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
			return false
		var cross := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
		if cross.length_squared() <= 0.00000000000001 or cross.dot(normals[a] + normals[b] + normals[c]) >= 0.0:
			return false
		for pair in [[ids[a], ids[b]], [ids[b], ids[c]], [ids[c], ids[a]]]:
			if pair[0] == pair[1]:
				return false
			var key := Vector2i(mini(pair[0], pair[1]), maxi(pair[0], pair[1]))
			var edge: Vector2i = edges.get(key, Vector2i.ZERO)
			edge.x += 1
			edge.y += 1 if pair[0] < pair[1] else -1
			edges[key] = edge
	for edge in edges.values():
		if edge != Vector2i(2, 0):
			return false
	return true

func _axis_heights(vertices: PackedVector3Array, indices: PackedInt32Array, height: float) -> Array[float]:
	# Vertical geometric ray along the mouth axis, independent of profile controls.
	var origin := Vector3(0.0, height, 0.0)
	var direction := Vector3.DOWN
	var elevations := {}
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		var e1 := vertices[indices[i + 1]] - a
		var e2 := vertices[indices[i + 2]] - a
		var p := direction.cross(e2)
		var determinant := e1.dot(p)
		if absf(determinant) < 0.0000000001:
			continue
		var inverse := 1.0 / determinant
		var s := origin - a
		var u := s.dot(p) * inverse
		var q := s.cross(e1)
		var v := direction.dot(q) * inverse
		var distance := e2.dot(q) * inverse
		if u >= -0.00001 and v >= -0.00001 and u + v <= 1.00001 and distance >= 0.0:
			elevations[roundi((height - distance) * 1000000.0)] = true
	var result: Array[float] = []
	for key in elevations:
		result.append(float(key) / 1000000.0)
	result.sort()
	return result

func frames(n: int = 4) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func _open_lip(mesh: ArrayMesh, height: float) -> bool:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var lip_triangles := 0
	var inner_radius := INF
	var outer_radius := 0.0
	for i in range(0, indices.size(), 3):
		var top_triangle := true
		for index in [indices[i], indices[i + 1], indices[i + 2]]:
			# Godot compresses/decodes surface normals, so inspect direction rather
			# than requiring exact zero components after resource round-tripping.
			top_triangle = top_triangle and is_equal_approx(vertices[index].y, height * 0.5) and normals[index].dot(Vector3.UP) > 0.99999
		if top_triangle:
			lip_triangles += 1
			for index in [indices[i], indices[i + 1], indices[i + 2]]:
				var r := Vector2(vertices[index].x, vertices[index].z).length()
				inner_radius = minf(inner_radius, r)
				outer_radius = maxf(outer_radius, r)
	var hits := _axis_heights(vertices, indices, height)
	return lip_triangles >= 24 and inner_radius > 0.0 and outer_radius > inner_radius and hits.size() == 2 and hits[-1] < height * 0.5

func _key(chapter: Node3D, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	chapter._unhandled_input(event)

func _physics(home: Node3D) -> Array:
	var records: Array = []
	for node in home.find_children("*", "CollisionShape3D", true, false):
		records.append([node.get_instance_id(), node.global_transform, node.shape.get_rid(), node.disabled, node.get_parent().collision_layer, node.get_parent().collision_mask])
	return records

func _inventory_transforms(beauty: Node3D, detail: Node3D) -> Array:
	var result: Array = []
	for i in range(6):
		var vessel: MeshInstance3D = beauty.pottery[i]
		result.append([vessel.get_instance_id(), vessel.transform, vessel.mesh.get_rid(), vessel.material_override.get_rid()])
	for storage in detail.storage_roots:
		for j in range(3):
			var vessel: MeshInstance3D = storage.get_node("StorageJar%d" % j)
			result.append([vessel.get_instance_id(), vessel.transform, vessel.mesh.get_rid(), vessel.material_override.get_rid()])
	return result

func _scene_contract() -> void:
	var home: Node3D = Launch.make_world()
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	root.add_child(home)
	await frames(8)
	_key(chapter, KEY_F7)
	check(chapter._art_open and chapter._paused, "real F7 opens the existing art modal and freezes the common clock")
	var beauty: Node3D = chapter.art.beauty
	var detail: Node3D = chapter.art.microdetail
	check(beauty.pottery.size() == 6 and beauty.get_node("MarketBeauty").get_child_count() == 18 and detail.storage_roots.size() == 2, "existing six market vessels, six storage jars and surrounding prop inventory remain bounded")
	var positions: Array[Vector3] = [
		Vector3(-26.1, 1.15, -17.75), Vector3(-25.55, 1.10, -17.92), Vector3(-24.95, 1.13, -17.72),
		Vector3(-24.25, 1.08, -17.94), Vector3(-23.58, 1.14, -17.70), Vector3(-22.95, 1.07, -17.90)]
	for i in range(6):
		var vessel: MeshInstance3D = beauty.pottery[i]
		check(vessel.name == "Vessel%d" % i and vessel.position.is_equal_approx(positions[i]) and vessel.scale == Vector3.ONE and vessel.rotation == Vector3.ZERO and vessel.mesh is ArrayMesh and vessel.material_override != null, "market vessel %d preserves existing identity, transform and material override" % i)
		check(vessel.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == VesselProfile.build(.16 + .025 * (i % 3), .30 + .05 * (i % 2), i).surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "market vessel %d is bound to its original radius/height envelope" % i)
		var legacy_rim: MeshInstance3D = beauty.get_node("MarketBeauty/Rim%d" % i)
		check(legacy_rim.mesh is TorusMesh and legacy_rim.layers == 0 and vessel.layers != 0 and _open_lip(vessel.mesh, .30 + .05 * (i % 2)), "market vessel %d owns its visible open annular lip while legacy duplicate rim stays unrendered" % i)
	for i in range(2):
		var storage: Node3D = detail.storage_roots[i]
		check(storage.get_child_count() == 5 and storage.position.is_equal_approx([Vector3(-17.3, .14, 9.65), Vector3(17.6, .14, 10.3)][i]), "storage corner %d preserves its parent transform and five props" % i)
		for j in range(3):
			var vessel: MeshInstance3D = storage.get_node("StorageJar%d" % j)
			check(vessel.position.is_equal_approx(Vector3(-.34 + .32 * j, .17, .02 + .10 * (j % 2))) and vessel.scale == Vector3.ONE and vessel.rotation == Vector3.ZERO and vessel.mesh is ArrayMesh and vessel.material_override != null, "storage jar %d/%d preserves transform and caller material" % [i, j])
			check(vessel.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == VesselProfile.build(.15 + .025 * j, .30 + .045 * (j % 2), i * 3 + j).surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "storage jar %d/%d retains its original envelope" % [i, j])
	for layer in [beauty, detail]:
		check(layer.get_meta("historical_claim", true) == false and layer.get_meta("gameplay_authority", true) == false, "pottery layers retain explicit presentation classification")
		check(layer.find_children("*", "CollisionObject3D", true, false).is_empty() and layer.find_children("*", "CollisionShape3D", true, false).is_empty() and layer.find_children("*", "NavigationRegion3D", true, false).is_empty() and layer.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "mesh refinement creates no collision or navigation authority")
	var state: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var physics := _physics(home)
	var inventory := _inventory_transforms(beauty, detail)
	for preset in ["daylight", "golden_hour", "evening"]:
		chapter._menu_action("art:" + preset)
		check(chapter.art.preset == preset and beauty.preset == preset, "existing preset binding reaches refined pottery layer: " + preset)
		chapter._menu_action("art:refinement")
		check(not beauty.visible and not detail.visible and beauty.pottery.all(func(v): return not v.is_visible_in_tree()), "F7 refinement disables all pottery with its existing layer: " + preset)
		chapter._menu_action("art:refinement")
		check(beauty.visible and detail.visible and beauty.pottery.all(func(v): return v.is_visible_in_tree()), "F7 refinement restores all pottery through existing layer: " + preset)
		var rims_hidden := true
		for i in range(6):
			rims_hidden = rims_hidden and beauty.get_node("MarketBeauty/Rim%d" % i).layers == 0
		check(rims_hidden, "F7/preset restore cannot render legacy duplicate pottery rims: " + preset)
		await frames(3)
		check(chapter.model.snapshot() == state and chapter.model.journal() == journal and _physics(home) == physics and _inventory_transforms(beauty, detail) == inventory, "preset/F7 leave state, journal, physics and pottery transforms/resources unchanged: " + preset)
	home.queue_free()
	await frames(3)

func run() -> void:
	# Every original size, every deterministic variant; no single golden profile.
	for i in range(6):
		for variant in range(VesselProfile.VARIANT_COUNT):
			_mesh_contract(.16 + .025 * (i % 3), .30 + .05 * (i % 2), variant)
	for j in range(3):
		for variant in range(VesselProfile.VARIANT_COUNT):
			_mesh_contract(.15 + .025 * j, .30 + .045 * (j % 2), variant)
	var first := VesselProfile.build(.2, .3, 0).surface_get_arrays(0)
	var second := VesselProfile.build(.2, .3, 1).surface_get_arrays(0)
	var third := VesselProfile.build(.2, .3, 2).surface_get_arrays(0)
	check(first[Mesh.ARRAY_VERTEX] != second[Mesh.ARRAY_VERTEX] and second[Mesh.ARRAY_VERTEX] != third[Mesh.ARRAY_VERTEX] and first[Mesh.ARRAY_VERTEX] != third[Mesh.ARRAY_VERTEX], "three distinct deterministic silhouettes without a random generator or clock")
	await _scene_contract()
	print("VESSEL_PROFILE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
