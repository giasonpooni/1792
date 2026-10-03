# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Synthetic platforms, ceilings and blockers qualify the real Home and House
## save/load boundaries. Their dimensions are physics fixtures, not heritage evidence.
const Launch := preload("res://childhood/home_launch.gd")
const HouseScene := preload("res://world/house_sandbox.tscn")
const RidingFixture := preload("res://tests/test_riding_training.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSE HEADROOM LOAD: " + label)

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

func freeze_callbacks(world: Node3D) -> void:
	# Keep native collision objects registered; PROCESS_MODE_DISABLED removes them.
	world.set_process(false)
	world.set_physics_process(false)
	for node in world.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)

func project(ctx: Dictionary) -> void:
	if ctx.home: ctx.adapter._apply()
	else: ctx.adapter._apply_actor(true)

func load_saved(ctx: Dictionary) -> void:
	if ctx.home: ctx.adapter._load(ctx.path)
	else: ctx.adapter._load_riding(ctx.path)

func clock(ctx: Dictionary, state: Dictionary) -> int:
	return int(state.childhood.tick if ctx.home else state.campaign_tick)

func observation(ctx: Dictionary) -> Dictionary:
	var horse: CharacterBody3D = ctx.adapter.horse
	var avatar: CharacterBody3D = ctx.adapter.avatar
	var shape: CapsuleShape3D = horse.get_node("Hull").shape
	var result := {"state":ctx.model.snapshot(), "horse_pose":horse.global_transform,
		"avatar_pose":avatar.global_transform, "horse_velocity":horse.velocity,
		"avatar_velocity":avatar.velocity, "horse_speed":horse.speed,
		"horse_stride":horse._stride, "horse_layer":horse.collision_layer,
		"horse_mask":horse.collision_mask, "avatar_layer":avatar.collision_layer,
		"avatar_mask":avatar.collision_mask, "avatar_physics":avatar.is_physics_processing(),
		"avatar_visible":avatar.get_node("MeshInstance3D").visible,
		"camera_pivot":avatar.get_node("CameraPivot").transform,
		"camera_length":avatar.get_node("CameraPivot/SpringArm3D").spring_length,
		"horse_shape":shape.get_instance_id(), "horse_shape_height":shape.height,
		"horse_shape_radius":shape.radius}
	if ctx.home:
		result.attacker_pose = ctx.adapter.attacker.global_transform
		result.escort_pose = ctx.adapter.escort.global_transform
	else:
		result.clock_accumulator = ctx.adapter._clock_accumulator
	return result

func positioned(state: Dictionary, at: Vector3, grounded: bool) -> Dictionary:
	var next := state.duplicate(true)
	next.riding.horse.position = [at.x, at.y, at.z]
	next.riding.horse.rider_id = "ranjit_singh"
	next.riding.horse.speed = 0.0
	next.riding.horse.vertical_speed = 0.0
	next.riding.horse.grounded = grounded
	next.player.position = next.riding.horse.position.duplicate()
	next.actors.ranjit_singh.position = next.player.position.duplicate()
	return next

func install_live(ctx: Dictionary, saved: Dictionary) -> void:
	var live := positioned(saved, Vector3(8, .14, -5), true)
	live.riding.horse.yaw = .2
	check(ctx.model.restore(live).is_empty(), ctx.label + " distinguishable live mounted state installs")
	for _i in range(17): ctx.model.advance()
	project(ctx)
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, saved) + 17,
		ctx.label + " live clock differs by exactly 17 existing ticks")

func save_current(ctx: Dictionary) -> PackedByteArray:
	check(ctx.model.save_to(ctx.path).is_empty(), ctx.label + " actual save writer succeeds")
	var bytes := FileAccess.get_file_as_bytes(ctx.path)
	check(not bytes.is_empty(), ctx.label + " save has observable bytes")
	return bytes

func admitted(ctx: Dictionary, saved: Dictionary, bytes: PackedByteArray, label: String) -> void:
	install_live(ctx, saved)
	load_saved(ctx)
	var message: String = ctx.adapter._message if ctx.home else ctx.adapter._notice
	var expected := "Whole Home and riding skills restored." if ctx.home else "Loaded. Horse, rider, patrol and house decisions restored."
	check(message == expected, ctx.label + " " + label + " actual load succeeds: " + message)
	check(RidingFixture.same_json(ctx.model.snapshot(), saved),
		ctx.label + " " + label + " restores whole saved authority and clock")
	var p: Array = saved.riding.horse.position
	var at := Vector3(p[0], p[1], p[2])
	check(ctx.adapter.horse.global_position.is_equal_approx(at) and ctx.adapter.avatar.global_position.is_equal_approx(at),
		ctx.label + " " + label + " restores both mounted poses")
	check(ctx.adapter.avatar.collision_layer == 0 and ctx.adapter.avatar.collision_mask == 0
		and not ctx.adapter.avatar.is_physics_processing() and not ctx.adapter.avatar.get_node("MeshInstance3D").visible,
		ctx.label + " " + label + " retains sole horse movement ownership")
	check(FileAccess.get_file_as_bytes(ctx.path) == bytes, ctx.label + " " + label + " preserves saved bytes")

func refused(ctx: Dictionary, saved: Dictionary, bytes: PackedByteArray, label: String) -> void:
	install_live(ctx, saved)
	var before := observation(ctx)
	load_saved(ctx)
	var message: String = ctx.adapter._message if ctx.home else ctx.adapter._notice
	check(message.contains("no clear standing room" if ctx.home else "Saved horse pose intersects scenery"),
		ctx.label + " " + label + " explains spatial refusal")
	check(observation(ctx) == before, ctx.label + " " + label + " preserves whole live state, clock, bodies, camera and ownership")
	check(FileAccess.get_file_as_bytes(ctx.path) == bytes, ctx.label + " " + label + " preserves saved bytes")

func actual_hull_overlaps(ctx: Dictionary, support: StaticBody3D = null) -> bool:
	# Independent fixture proof uses the actual native body shape and transform,
	# without reproducing the production save query's support allowance.
	var collider: CollisionShape3D = ctx.adapter.horse.get_node("Hull")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.collision_mask = 1
	query.exclude = [ctx.adapter.horse.get_rid(), ctx.adapter.avatar.get_rid()]
	# A grounded native body may retain contact-scale overlap with its floor;
	# this fixture proof checks overhead clearance independently of that contact.
	if support != null:
		var excluded: Array[RID] = query.exclude
		excluded.append(support.get_rid())
		query.exclude = excluded
	return not ctx.world.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func exercise(home_mode: bool) -> void:
	var world: Node3D = Launch.make_world() if home_mode else HouseScene.instantiate()
	root.add_child(world)
	current_scene = world
	await frames(5)
	freeze_callbacks(world)
	var adapter: Node3D = world.get_node("ChildhoodChapter") if home_mode else world
	var ctx := {"home":home_mode, "world":world, "adapter":adapter,
		"model":adapter.model if home_mode else adapter.campaign,
		"label":"Home" if home_mode else "House",
		"path":"user://horse-headroom-home-native-only.json" if home_mode else "user://horse-headroom-house-native-only.json"}
	var center := Vector3(0 if home_mode else 30, 4, 0)
	var platform := box(world, center - Vector3.UP * .1, Vector3(6, .2, 6))
	var seed: Dictionary = RidingFixture.legacy_riding_seed() if home_mode else ctx.model.snapshot()
	seed = positioned(seed, center + Vector3.UP * .14, false)
	check(ctx.model.restore(seed).is_empty(), ctx.label + " explicit mounted fixture installs")
	project(ctx)
	await frames()
	var motion_errors: Array[String] = []
	for _i in range(60):
		var motion: Dictionary = adapter.horse.step(1.0 / 60.0, 0.0, 0.0, false, false, true)
		var error: String = ctx.model.record_ride(motion, 1.0 / 60.0)
		if not error.is_empty(): motion_errors.append(error)
		ctx.model.advance()
		adapter.avatar.global_position = adapter.horse.global_position
		await physics_frame
	check(motion_errors.is_empty() and adapter.horse.is_on_floor(), ctx.label + " native settling enters the mounted reducer on actual support")
	var floor_position: Vector3 = adapter.horse.global_position
	var ceiling := box(world, floor_position + Vector3.UP * 3.34, Vector3(4, .2, 4))
	await frames()
	check(not actual_hull_overlaps(ctx, platform), ctx.label + " native settled body clears the 3.24 metre ceiling")
	var saved: Dictionary = ctx.model.snapshot()
	var bytes := save_current(ctx)
	admitted(ctx, saved, bytes, "grounded low headroom")
	# Lowering just the ceiling must now reject the same saved native body.
	ceiling.position.y = floor_position.y + 3.28
	await frames()
	refused(ctx, saved, bytes, "grounded head obstruction")
	ceiling.queue_free()
	platform.queue_free()
	await frames()
	# Explicit airborne setup is intentionally not a traversed campaign route.
	# No support tolerance is available to hide intersections at the feet.
	var airborne := positioned(saved, center, false)
	check(ctx.model.restore(airborne).is_empty(), ctx.label + " explicit airborne mounted fixture installs")
	project(ctx)
	ceiling = box(world, center + Vector3.UP * 3.34, Vector3(4, .2, 4))
	await frames()
	check(not actual_hull_overlaps(ctx), ctx.label + " actual airborne body clears the 3.24 metre ceiling")
	saved = ctx.model.snapshot()
	bytes = save_current(ctx)
	admitted(ctx, saved, bytes, "airborne low headroom")
	ceiling.queue_free()
	await frames()
	# A 3 cm cap intersection is smaller than the old whole-body query lift.
	check(ctx.model.restore(saved).is_empty(), ctx.label + " saved airborne pose reinstalls for independent fixture proof")
	project(ctx)
	var foot := box(world, center - Vector3.UP * .07, Vector3(1, .2, 1))
	await frames()
	check(actual_hull_overlaps(ctx), ctx.label + " native capsule intersects the 3 cm foot blocker")
	refused(ctx, saved, bytes, "airborne foot obstruction")
	foot.queue_free()
	await frames()
	admitted(ctx, saved, bytes, "removed airborne obstruction")
	current_scene = null
	world.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ctx.path))

func _run() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	await exercise(true)
	await exercise(false)
	print("HORSE_HEADROOM_LOAD_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
