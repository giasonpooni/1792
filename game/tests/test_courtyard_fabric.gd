# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch := preload("res://childhood/home_launch.gd")
var passed := 0
var failed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error("COURTYARD FABRIC: "+label)
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var result: Array = []
	for node in home.find_children("*","CollisionShape3D",true,false):
		result.append([node.get_instance_id(),node.global_transform,node.shape.get_rid(),node.disabled,node.get_parent().collision_layer,node.get_parent().collision_mask])
	return result
func run() -> void:
	var home := Launch.make_world()
	root.add_child(home)
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	await frames(6)
	chapter.open_art_study()
	var fabric: Node3D = chapter.art.detail.fabric
	var state: Dictionary = chapter.model.snapshot()
	var bodies := physical(home)
	check(fabric._built and fabric.is_visible_in_tree(),"detail attached to composed Home")
	check(not fabric.build(chapter.art.detail).is_empty(),"duplicate build refused")
	check(fabric.evidence_digest == FileAccess.get_sha256(fabric.EVIDENCE_PATH),"actual evidence content identity")
	for kind in ["CollisionObject3D","CollisionShape3D","NavigationRegion3D","Timer"]:
		check(fabric.find_children("*",kind,true,false).is_empty(),"no new "+kind)
	check(not fabric.is_processing() and not fabric.is_physics_processing(),"no independent frame owner")
	for mesh in fabric.groups:
		check(not mesh.get_meta("photo_ids").is_empty() and mesh.get_meta("evidence_digest")==fabric.evidence_digest,"visible mesh resolves photo evidence")
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var finite := true
		for i in range(vertices.size()):
			finite = finite and vertices[i].is_finite() and normals[i].is_finite() and normals[i].length()>.99
		check(finite,"finite vertices and usable normals")
	# Containment is checked against the actual game-owned body, not copied bounds.
	for i in range(fabric.shafts.size()):
		var mesh: MeshInstance3D = fabric.shafts[i]
		var shape: CollisionShape3D = chapter.get_node("CourtyardPierEnvelopes/Pier%d"%i).get_child(1)
		var local: Transform3D = shape.global_transform.affine_inverse()*mesh.global_transform
		var half: Vector3 = shape.shape.size*.5
		var contained := true
		for vertex in mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var p: Vector3 = local*vertex
			contained = contained and absf(p.x)<=half.x and absf(p.y)<=half.y and absf(p.z)<=half.z
		check(contained,"grouped shafts inside physical pier %d"%i)
	for _i in range(3):
		chapter.art.set_refinement(false)
		check(not fabric.is_visible_in_tree(),"earlier study hides new detail")
		chapter.art.set_refinement(true)
		chapter.art.set_enabled(false)
		check(not fabric.is_visible_in_tree(),"greybox hides new detail")
		chapter.art.set_enabled(true)
		check(fabric.is_visible_in_tree(),"refined view restores detail")
	await frames(12)
	check(chapter.model.snapshot()==state and physical(home)==bodies,"clock, state and all body identities unchanged")
	var before: Dictionary = chapter.model.snapshot()
	chapter.art.detail.remove_child(fabric)
	fabric.queue_free()
	await frames()
	check(chapter.model.snapshot()==before and physical(home)==bodies,"removal leaves domain and physics intact")
	home.queue_free()
	await frames()
	print("COURTYARD_FABRIC_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
