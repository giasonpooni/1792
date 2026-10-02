# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch := preload("res://childhood/home_launch.gd")
const Fabric := preload("res://reconstruction/district_fabric.gd")
const Rules := preload("res://territory/misl_rules.gd")
var passed := 0
var failed := 0

func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1; push_error("GUJRANWALA DAILY DETAIL: "+label)
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var result: Array = []
	for node in home.find_children("*", "CollisionShape3D", true, false):
		result.append([node.get_instance_id(), node.global_transform, node.shape.get_rid(), node.disabled])
	return result
func contained(mesh: MeshInstance3D, bounds: AABB) -> bool:
	return bounds.encloses(mesh.transform * mesh.mesh.get_aabb())

func run() -> void:
	var home := Launch.make_world()
	root.add_child(home)
	await frames(8)
	var scene = home.get_node("ChildhoodChapter")
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var art: Node3D = scene.art
	var layer: Node3D = art.daily_detail
	var before: Dictionary = scene.model.snapshot()
	var journal: Array = scene.model.journal()
	var bodies := physical(home)
	check(layer.get_meta("historical_claim", true) == false and layer.get_meta("gameplay_authority", true) == false, "art retains explicit historical/gameplay boundaries")
	check(layer.door_hardware.size() == 8 and layer.threshold_wear.size() == 5 and layer.baskets.size() == 2 and layer.well_fittings.size() == 3, "all three authored detail groups completed construction")
	check(layer.find_children("*", "CollisionObject3D", true, false).is_empty(), "new detail has no physical actors or bodies")
	check(layer.find_children("*", "CollisionShape3D", true, false).is_empty() and layer.find_children("*", "NavigationRegion3D", true, false).is_empty(), "no collision shapes or navigation ownership")
	check(layer.find_children("*", "Timer", true, false).is_empty() and not layer.is_processing() and not layer.is_physics_processing(), "static layer creates no second game loop")
	check(not layer.build(scene, art).is_empty(), "duplicate build refused without adding geometry")
	var original_meshes: Array = []
	for bay in art.detail.find_children("AuthoredBay*", "Node3D", false, false):
		for mesh in bay.find_children("*", "MeshInstance3D", true, false): original_meshes.append([mesh, mesh.mesh, mesh.transform])
	for mesh in layer.door_hardware:
		var bay: Node3D = art.detail.get_node(str(mesh.get_meta("anchor")))
		check(mesh.global_position == bay.global_position, "hardware follows its retained bay anchor")
		check(AABB(Vector3(-.8, .25, .10), Vector3(1.6, 1.50, .28)).encloses(mesh.mesh.get_aabb()), "hardware stays flush to the closed door")
	for mesh in layer.threshold_wear:
		check(AABB(Vector3(-.94, .159, 0), Vector3(1.88, .004, .4)).encloses(mesh.mesh.get_aabb()), "wear stays within the existing threshold top")
	var counter := Rules.MARKET+Vector3(0, 1.10, -2.6)
	for mesh in layer.baskets:
		check(contained(mesh, AABB(counter+Vector3(-1.5, 0, -.5), Vector3(3, .22, 1))), "every woven basket fits the solid counter top")
		check(mesh.mesh.get_aabb().size.y > .13, "basket has a real open lattice silhouette")
	var well: Node3D = scene.fabric.get_node("household_well")
	for mesh in layer.well_fittings:
		check(mesh.global_position == well.global_position, "well fittings share the original well anchor")
		var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var fits := true
		for vertex in vertices:
			if Vector2(vertex.x, vertex.z).length() > 1.25 or vertex.y < 0 or vertex.y > 2.85: fits = false
		check(fits, "well fittings remain in the retained solid footprint and support height")
	var triangles := 0
	var meshes := layer.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		triangles += arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX] != null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()/3
	check(meshes.size() <= 24 and triangles <= 20000, "static geometry stays within 24 mesh submissions and 20000 triangles")
	for _i in range(3):
		art.set_refinement(false)
		check(not layer.is_visible_in_tree(), "F7 comparison removes the detail")
		art.set_refinement(true)
		check(layer.is_visible_in_tree(), "F7 restores the detail")
		art.set_enabled(false)
		check(not layer.is_visible_in_tree(), "greybox removes the detail")
		art.set_enabled(true)
		check(layer.is_visible_in_tree(), "authored mode restores the detail")
		for preset in ["golden_hour", "evening", "daylight"]: check(art.set_preset(preset).is_empty(), "inherited lighting preset retained")
		check(physical(home) == bodies, "full switch cycle preserves collision references, transforms and enabled state")
		check(scene.model.snapshot() == before and scene.model.journal() == journal, "full switch cycle preserves campaign, clock, knowledge and journal")
	for record in original_meshes: check(record[0].mesh == record[1] and record[0].transform == record[2], "retained courtyard geometry is unchanged")
	for route in scene.fabric.manifest.routes:
		for i in range(route.points.size()-1):
			check(scene._navigation.clear_segment(Fabric.vector(route.points[i]), Fabric.vector(route.points[i+1])), "swept inherited route remains clear: "+route.id)
	print("DAILY DETAIL GEOMETRY: %d meshes; %d triangles" % [meshes.size(), triangles])
	home.queue_free()
	await frames(4)
	print("GUJRANWALA_DAILY_DETAIL_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
