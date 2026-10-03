# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Labelled spatial fixtures qualify the actual mount transfer, not a played route.
const Horse := preload("res://mounts/horse.gd")
const Player := preload("res://player/player.tscn")
const Launch := preload("res://childhood/home_launch.gd")
const RidingFixture := preload("res://tests/test_riding_training.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("MOUNT CLEARANCE: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	parent.add_child(body)
	return body

func centre_ray_clear(horse: CharacterBody3D, avatar: CharacterBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(avatar.global_position + Vector3.UP,
		horse.global_position + Vector3.UP * 1.4, 1, [horse.get_rid(), avatar.get_rid()])
	return horse.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func body_clear(avatar: CharacterBody3D, horse: CharacterBody3D) -> bool:
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.collision_mask = 1
	query.exclude = [avatar.get_rid(), horse.get_rid()]
	return avatar.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func observation(horse: CharacterBody3D, avatar: CharacterBody3D) -> Dictionary:
	return {"horse_pose": horse.global_transform, "avatar_pose": avatar.global_transform,
		"horse_velocity": horse.velocity, "avatar_velocity": avatar.velocity,
		"speed": horse.speed, "stride": horse._stride,
		"horse_mask": horse.collision_mask, "avatar_mask": avatar.collision_mask,
		"horse_layer": horse.collision_layer, "avatar_layer": avatar.collision_layer,
		"avatar_collider_transform": avatar.get_node("CollisionShape3D").transform,
		"hull_identity": horse.get_node("Hull").shape.get_instance_id(),
		"avatar_shape_identity": avatar.get_node("CollisionShape3D").shape.get_instance_id()}

func repeated_query_is_read_only(horse: CharacterBody3D, avatar: CharacterBody3D, label: String) -> void:
	var before := observation(horse, avatar)
	for _i in range(10): horse.clear_mount_path(avatar)
	check(observation(horse, avatar) == before, label + " repeated queries retain physical state and shape identities")

func _isolated_fixtures() -> void:
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(0, -0.1, 0), Vector3(20, 0.2, 20))
	var horse := Horse.new()
	horse.position = Vector3(0, 0.04, 0)
	world.add_child(horse)
	var avatar: CharacterBody3D = Player.instantiate()
	avatar.position = Vector3(1.8, 0.04, 0)
	world.add_child(avatar)
	avatar.set_physics_process(false)
	await frames()
	var capsule: CapsuleShape3D = avatar.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius * 2.0, 0.7), "fixture uses the actual retained 0.70 m avatar capsule")
	check(body_clear(avatar, horse), "normal approach starts with an unobstructed actual avatar hull")
	check(horse.clear_mount_path(avatar), "normal clear approach admits mounting")
	repeated_query_is_read_only(horse, avatar, "clear approach")
	var before := observation(horse, avatar)
	var landing: Variant = horse.dismount_position(avatar)
	check(landing is Vector3, "normal clear floor admits a dismount destination")
	check(observation(horse, avatar) == before, "dismount query is read-only")
	if landing is Vector3:
		check(landing.distance_to(horse.global_position) <= 2.5 and landing.y >= 0, "dismount remains on nearby supporting floor")
	var posts: Array[StaticBody3D] = []
	for z in [-0.30, 0.30]: posts.append(box(world, Vector3(0.95, 1.5, z), Vector3(0.2, 3, 0.3)))
	await frames()
	check(body_clear(avatar, horse), "narrow-post fixture does not start with avatar overlap")
	check(centre_ray_clear(horse, avatar), "narrow posts leave the existing centre ray clear")
	check(not horse.clear_mount_path(avatar), "a 0.30 m gap cannot admit the 0.70 m avatar capsule")
	repeated_query_is_read_only(horse, avatar, "narrow posts")
	for post in posts: post.queue_free()
	await frames()
	var barrier := box(world, Vector3(0.95, 0.35, 0), Vector3(0.2, 0.7, 3))
	await frames()
	check(body_clear(avatar, horse), "low-barrier fixture does not start with avatar overlap")
	check(centre_ray_clear(horse, avatar), "low barrier leaves the existing elevated ray clear")
	check(not horse.clear_mount_path(avatar), "low solid barrier prevents an unmodelled transfer through its body")
	repeated_query_is_read_only(horse, avatar, "low barrier")
	barrier.queue_free()
	await frames()
	check(horse.clear_mount_path(avatar), "removing blockers restores a clear mount approach")
	var overlap := box(world, Vector3(1.8, 0.8, 0.30), Vector3(0.15, 0.5, 0.15))
	await frames()
	check(centre_ray_clear(horse, avatar), "start-overlap blocker is outside the centre ray")
	check(not body_clear(avatar, horse), "start-overlap fixture intersects the actual current avatar hull")
	check(not horse.clear_mount_path(avatar), "an initially intersecting hull is refused even when cast_motion would ignore it")
	repeated_query_is_read_only(horse, avatar, "initial overlap")
	overlap.queue_free()
	await frames()
	overlap = box(world, Vector3(0, 0.8, 0.30), Vector3(0.15, 0.5, 0.15))
	await frames()
	check(centre_ray_clear(horse, avatar), "end-overlap blocker is outside the centre ray")
	check(body_clear(avatar, horse), "end-overlap fixture leaves the initial avatar hull clear")
	var destination_query := PhysicsShapeQueryParameters3D.new()
	destination_query.shape = capsule
	destination_query.transform = avatar.get_node("CollisionShape3D").global_transform
	destination_query.transform.origin += horse.global_position - avatar.global_position + Vector3.UP * 0.04
	destination_query.collision_mask = 1
	destination_query.exclude = [horse.get_rid(), avatar.get_rid()]
	check(not avatar.get_world_3d().direct_space_state.intersect_shape(destination_query, 1).is_empty(),
		"end-overlap fixture intersects the actual transferred avatar hull")
	check(not horse.clear_mount_path(avatar), "intersecting final avatar hull is refused")
	repeated_query_is_read_only(horse, avatar, "destination overlap")
	overlap.queue_free()
	await frames()
	var collider: CollisionShape3D = avatar.get_node("CollisionShape3D")
	collider.disabled = true
	check(not horse.clear_mount_path(avatar), "disabled walking hull cannot authorize mount transfer")
	collider.disabled = false
	var retained_shape: Shape3D = collider.shape
	collider.shape = null
	check(not horse.clear_mount_path(avatar), "missing walking shape cannot authorize mount transfer")
	collider.shape = retained_shape
	collider.name = "UnavailableWalkingHull"
	check(not horse.clear_mount_path(avatar), "missing walking collider cannot authorize mount transfer")
	collider.name = "CollisionShape3D"
	await frames()
	check(horse.clear_mount_path(avatar), "restoring the original hull restores unobstructed admission")
	var collider_before: Transform3D = collider.transform
	collider.position.z = 0.7
	collider.rotation.x = PI / 2.0
	await frames()
	check(horse.clear_mount_path(avatar), "a displaced and rotated child hull admits its own clear route")
	var transformed_blocker := box(world, Vector3(0.95, 0.8, 1.25), Vector3(0.2, 0.5, 0.2))
	await frames()
	check(centre_ray_clear(horse, avatar), "transformed-hull blocker lies outside the retained centre ray")
	check(body_clear(avatar, horse), "transformed child hull starts clear of its route blocker")
	check(not horse.clear_mount_path(avatar), "body sweep retains both child displacement and rotation")
	repeated_query_is_read_only(horse, avatar, "transformed walking hull")
	transformed_blocker.queue_free()
	collider.transform = collider_before
	await frames()
	check(horse.clear_mount_path(avatar), "restoring the child transform restores the original clear approach")
	world.queue_free()
	await frames()

func _home_transfer() -> void:
	var home: Node3D = Launch.make_world()
	root.add_child(home)
	current_scene = home
	var chapter = home.get_node("ChildhoodChapter")
	await frames(5)
	# A qualified legacy fixture supplies only the existing riding gate. Freeze
	# ordinary advancement to inspect the atomic transfer boundary exactly.
	# Disable callbacks, not process_mode: disabling CollisionObject3D processing
	# can remove bodies from PhysicsServer and would invalidate the collision test.
	home.set_process(false)
	home.set_physics_process(false)
	for node in home.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)
	var seed := RidingFixture.legacy_riding_seed()
	seed.player.position = [9.8, 0.14, -5.0]
	seed.actors.ranjit_singh.position = seed.player.position.duplicate()
	check(chapter.model.restore(seed).is_empty(), "explicit legacy Home riding fixture restores")
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	var posts: Array[StaticBody3D] = []
	for z in [-0.30, 0.30]: posts.append(box(home, Vector3(8.95, 1.5, -5.0 + z), Vector3(0.2, 3, 0.3)))
	await frames()
	check(centre_ray_clear(chapter.horse, chapter.avatar), "Home posts reproduce a clear centre ray")
	var before: Dictionary = chapter.model.snapshot()
	var physical_before := observation(chapter.horse, chapter.avatar)
	chapter._toggle_mount()
	check(not chapter.model.mounted(), "Home mount action refuses the narrow physical gap")
	check(chapter.model.snapshot() == before, "refused Home transfer preserves the full authoritative state and clock")
	check(observation(chapter.horse, chapter.avatar) == physical_before, "refused Home transfer preserves both bodies and movement ownership")
	check(chapter._message.contains("wall"), "Home explains the physical mount refusal")
	# The normal handler queues F; one explicit owning physics tick consumes it.
	# Unlike the atomic action check above, this boundary earns one normal tick.
	check(chapter.model.restore(seed).is_empty(), "Home queued-input fixture restores independently")
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	await frames()
	var position_before: Vector3 = chapter.avatar.global_position
	var horse_before: Vector3 = chapter.horse.global_position
	var tick_before: int = chapter.model.progress().tick
	var key := InputEventKey.new()
	key.keycode = KEY_F
	key.pressed = true
	chapter._unhandled_input(key)
	check(chapter._mount_requested, "Home F handler queues the existing mount action")
	chapter._physics_process(1.0 / 60.0)
	check(not chapter._mount_requested, "one owning Home physics tick consumes queued F")
	check(not chapter.model.mounted(), "queued F also refuses a body-obstructed transfer")
	check(chapter.avatar.global_position == position_before and chapter.horse.global_position == horse_before,
		"queued F refusal does not teleport either body")
	check(chapter.model.progress().tick == tick_before + 1, "queued F executes exactly one existing Home clock tick")
	# Reinstall the fixture so a failed baseline cannot contaminate the clear case.
	check(chapter.model.restore(seed).is_empty(), "Home clear-case fixture restores independently")
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	for post in posts: post.queue_free()
	await frames()
	chapter._toggle_mount()
	check(chapter.model.mounted(), "same Home mount action succeeds after removing the obstruction")
	current_scene = null
	home.queue_free()
	await frames()

func _run() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	await _isolated_fixtures()
	await _home_transfer()
	print("MOUNT_CLEARANCE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
