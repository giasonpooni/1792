# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Actual composed production scene, frozen for art-layout invariants.
const Launch := preload("res://childhood/home_launch.gd")
const Focus := preload("res://presentation/childhood_trail_focus.gd")
const Home := preload("res://childhood/childhood_state.gd")
var passed := 0
var failed := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("TRAIL FOCUS: " + label)
func bodies(home: Node3D) -> Array:
	var result: Array = []
	for body in home.find_children("*", "CollisionObject3D", true, false): result.append([body.get_instance_id(), body.global_transform, body.collision_layer, body.collision_mask])
	for shape in home.find_children("*", "CollisionShape3D", true, false): result.append([shape.get_instance_id(), shape.global_transform, shape.shape.get_instance_id()])
	return result
func run() -> void:
	var home := Launch.make_world()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(home)
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	var staging: Node3D = chapter.get_node("ChildhoodArcStaging")
	staging.sample()
	var focus: Node3D = staging.trail_focus
	check(focus.corrections.size() == 2, "production composition binds exactly the identified shop bay and basket")
	var originals: Array = focus.corrections.duplicate()
	staging.remove_child(focus)
	focus.free()
	for record in originals: check(record.node.transform == record.transform, "removal restores original layout exactly")
	var snapshot: Dictionary = chapter.model.snapshot()
	var collision := bodies(home)
	var camera: Transform3D = chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").global_transform
	var trace_positions: Array = staging.trace_roots.map(func(n): return n.global_position)
	var memory_anchor: Vector3 = chapter.get_node("HandWorkedLives/KeptPlace").global_position
	focus = Focus.new()
	staging.add_child(focus)
	staging.trail_focus = focus
	focus.build(chapter)
	focus.sample()
	check(focus.corrections.size() == 2, "rebinding applies both original-layout corrections")
	for i in range(2):
		var node: Node3D = focus.corrections[i].node
		check(node.position.is_equal_approx(Focus.TARGETS[i].position + Focus.TARGETS[i].offset), "fixed layout displacement matches the reviewed scene")
	var after: Array = focus.corrections.map(func(r): return r.node.transform)
	for i in range(10): focus.sample()
	check(after == focus.corrections.map(func(r): return r.node.transform), "repeated paused sampling never accumulates movement")
	check(chapter.model.snapshot() == snapshot, "layout leaves authority, time, memories and knowledge unchanged")
	check(bodies(home) == collision, "layout leaves every physics body and shape unchanged")
	check(chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").global_transform == camera, "layout never takes over the player camera")
	check(staging.trace_roots.map(func(n): return n.global_position) == trace_positions and trace_positions == [Home.SITES.track_1, Home.SITES.track_2, Home.SITES.track_3], "all three authored lesson sites stay fixed")
	check(chapter.get_node("HandWorkedLives/KeptPlace").global_position == memory_anchor, "interactable material-story anchor stays fixed")
	check(not focus.is_processing() and not focus.is_physics_processing(), "focus adds no running clock")
	var ground: MeshInstance3D = staging.trace_roots[0].get_node("ExposedSoil")
	check(not ground.material_override.emission_enabled and ground.get_aabb().size.y < 0.02, "soil contrast stays flat and non-emissive")
	var bay: Node3D = chapter.get_node(Focus.TARGETS[0].path)
	var parent: Node3D = bay.get_parent()
	parent.hide()
	check(not bay.is_visible_in_tree(), "parent comparison visibility continues to hide corrected dressing")
	parent.show()
	check(bay.is_visible_in_tree() and bay.transform == after[0], "comparison visibility restores the same reviewed layout without a tick")
	staging.remove_child(focus)
	focus.free()
	for record in originals: check(record.node.transform == record.transform, "second removal restores exact original transform")
	# A changed target is not blindly moved: unrelated art and new colliders
	# remain owned by their original component.
	var barrier := StaticBody3D.new()
	bay.add_child(barrier)
	focus = Focus.new()
	staging.add_child(focus)
	staging.trail_focus = focus
	focus.build(chapter)
	check(focus.corrections.size() == 1 and bay.transform == originals[0].transform, "a target gaining collision is rejected instead of moved")
	barrier.free()
	staging.remove_child(focus)
	focus.free()
	var basket: MeshInstance3D = chapter.get_node(Focus.TARGETS[1].path)
	var mesh: Mesh = basket.mesh
	basket.mesh = BoxMesh.new()
	focus = Focus.new()
	staging.add_child(focus)
	staging.trail_focus = focus
	focus.build(chapter)
	check(focus.corrections.size() == 1 and basket.transform == originals[1].transform, "a changed shape is rejected instead of silently relocating unrelated art")
	basket.mesh = mesh
	home.queue_free()
	await process_frame
	print("CHILDHOOD_TRAIL_FOCUS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
