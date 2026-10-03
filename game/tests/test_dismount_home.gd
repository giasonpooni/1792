# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit mounted legacy fixtures exercise the real Home dismount boundary.
const Launch := preload("res://childhood/home_launch.gd")
const RidingFixture := preload("res://tests/test_riding_training.gd")
const Formation := preload("res://warband/mounted_formation.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("DISMOUNT HOME: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return body

func observation(chapter: Node3D) -> Dictionary:
	var avatar: CharacterBody3D = chapter.avatar
	var horse: CharacterBody3D = chapter.horse
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	return {"avatar_pose": avatar.global_transform, "horse_pose": horse.global_transform,
		"avatar_velocity": avatar.velocity, "horse_velocity": horse.velocity,
		"horse_speed": horse.speed, "horse_stride": horse._stride,
		"avatar_layer": avatar.collision_layer, "avatar_mask": avatar.collision_mask,
		"horse_layer": horse.collision_layer, "horse_mask": horse.collision_mask,
		"avatar_physics": avatar.is_physics_processing(), "horse_physics": horse.is_physics_processing(),
		"avatar_mesh_visible": avatar.get_node("MeshInstance3D").visible,
		"camera_pivot": avatar.get_node("CameraPivot").transform,
		"camera_length": avatar.get_node("CameraPivot/SpringArm3D").spring_length,
		"collider_transform": collider.transform, "collider_disabled": collider.disabled,
		"shape_id": 0 if collider.shape == null else collider.shape.get_instance_id()}

func refused_action(chapter: Node3D, label: String) -> void:
	var before: Dictionary = chapter.model.snapshot()
	var physical_before := observation(chapter)
	check(chapter.horse.dismount_position(chapter.avatar) == null, label + " has no qualified landing")
	chapter._toggle_mount()
	check(chapter.model.mounted(), label + " keeps rider mounted")
	check(chapter.model.snapshot() == before, label + " preserves the complete state and clock")
	check(observation(chapter) == physical_before, label + " preserves bodies, controller, collision and camera")
	check(chapter._message.contains("No clear ground"), label + " explains the refusal")

func _run() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	var home: Node3D = Launch.make_world()
	root.add_child(home)
	current_scene = home
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	await frames(5)
	# Keep native colliders in PhysicsServer: disable callbacks, never process_mode.
	home.set_process(false)
	home.set_physics_process(false)
	for node in home.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)
	var seed := RidingFixture.legacy_riding_seed()
	seed.riding.horse.rider_id = "ranjit_singh"
	seed.riding.horse.speed = 0.0
	seed.riding.horse.vertical_speed = 0.0
	seed.riding.horse.grounded = true
	seed.player.position = seed.riding.horse.position.duplicate()
	seed.actors.ranjit_singh.position = seed.player.position.duplicate()
	check(chapter.model.restore(seed).is_empty(), "explicit mounted legacy Home fixture restores")
	chapter._apply()
	await frames()
	check(chapter.model.mounted(), "fixture starts mounted")
	check(chapter.avatar.collision_mask == 0 and chapter.avatar.collision_layer == 0,
		"mounted adapter disables walking collisions")
	check(not chapter.avatar.is_physics_processing(), "mounted adapter disables the walking controller")
	var collider: CollisionShape3D = chapter.avatar.get_node("CollisionShape3D")
	check(not collider.disabled and collider.shape is CapsuleShape3D, "mounted adapter retains the actual walking shape")
	check(chapter.horse.dismount_position(chapter.avatar) is Vector3, "unobstructed mounted Home has an exit despite mask zero")
	var horse_position: Vector3 = chapter.horse.global_position
	var blocker := box(home, horse_position + Vector3(0, 0.76, 0.25), Vector3(0.2, 0.5, 0.2))
	await frames()
	var overlap_query := PhysicsShapeQueryParameters3D.new()
	overlap_query.shape = collider.shape
	overlap_query.transform = collider.global_transform
	overlap_query.transform.origin += Vector3.UP * 0.04
	overlap_query.collision_mask = 1
	overlap_query.exclude = [chapter.avatar.get_rid(), chapter.horse.get_rid()]
	check(not chapter.get_world_3d().direct_space_state.intersect_shape(overlap_query, 1).is_empty(),
		"explicit blocker overlaps the actual dismount start hull")
	refused_action(chapter, "initial overlap")
	blocker.queue_free()
	await frames()
	check(chapter.horse.dismount_position(chapter.avatar) is Vector3, "removing the overlap restores a qualified exit")
	var shape: Shape3D = collider.shape
	collider.shape = null
	refused_action(chapter, "unavailable walking shape")
	collider.shape = shape
	collider.disabled = true
	refused_action(chapter, "disabled walking shape")
	collider.disabled = false
	await frames()
	var landing: Variant = chapter.horse.dismount_position(chapter.avatar)
	check(landing is Vector3, "restored actual collider qualifies the clear exit")
	var before: Dictionary = chapter.model.snapshot()
	var horse_before: Transform3D = chapter.horse.global_transform
	var clock_before: int = chapter.model.progress().tick
	chapter._toggle_mount()
	check(not chapter.model.mounted(), "actual Home action dismounts after removing the obstruction")
	check(chapter.avatar.is_physics_processing(), "successful action restores the walking controller before test refreezing")
	check(chapter.avatar.collision_mask == (1 | Formation.TRAFFIC_LAYER) and chapter.avatar.collision_layer == 1,
		"successful action restores the current Home walking floor and camp-traffic mask and layer")
	check(chapter.avatar.get_node("MeshInstance3D").visible, "successful action restores the visible walking avatar")
	check(chapter.avatar.global_position == landing and chapter.model.position() == landing,
		"model and physical avatar share the qualified landing")
	check(chapter.horse.global_transform == horse_before, "successful dismount leaves the parked horse pose unchanged")
	check(chapter.model.progress().tick == clock_before, "atomic successful action retains the original clock")
	var expected := before.duplicate(true)
	expected.riding.horse.rider_id = ""
	expected.riding.horse.speed = 0.0
	expected.player.position = [landing.x, landing.y, landing.z]
	expected.actors.ranjit_singh.position = expected.player.position.duplicate()
	check(chapter.model.snapshot() == expected, "successful action changes only existing rider and position fields")
	chapter.avatar.set_physics_process(false)
	# Reinstall independently: queued F also performs one ordinary mounted tick.
	check(chapter.model.restore(seed).is_empty(), "queued F fixture restores independently")
	chapter._apply()
	blocker = box(home, horse_position + Vector3(0, 0.76, 0.25), Vector3(0.2, 0.5, 0.2))
	await frames()
	clock_before = chapter.model.progress().tick
	var event := InputEventKey.new()
	event.keycode = KEY_F
	event.pressed = true
	chapter._unhandled_input(event)
	check(chapter._mount_requested, "actual Home F handler queues dismount")
	chapter._physics_process(1.0 / 60.0)
	check(not chapter._mount_requested, "one owning Home tick consumes queued F")
	check(chapter.model.mounted(), "queued F refuses the overlapping dismount start")
	check(chapter.model.progress().tick == clock_before + 1, "queued refusal earns exactly one existing Home clock tick")
	check(chapter.avatar.collision_mask == 0 and not chapter.avatar.is_physics_processing(),
		"queued refusal retains mounted controller ownership")
	# Any ordinary horse collision response in that tick is distinct from the
	# atomic transfer checks above; this deliberately intersecting fixture is not a route.
	current_scene = null
	home.queue_free()
	await frames()
	print("DISMOUNT_HOME_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
