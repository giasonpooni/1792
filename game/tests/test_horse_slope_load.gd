# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Authored physics fixture in the actual Home load boundary; not a played route.
const Launch := preload("res://childhood/home_launch.gd")
const RidingFixture := preload("res://tests/test_riding_training.gd")
const SAVE := "user://horse-slope-load-native-only.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSE SLOPE LOAD: " + label)

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

func freeze_callbacks(home: Node3D) -> void:
	# PROCESS_MODE_DISABLED removes collision objects from PhysicsServer. Keep
	# objects active while suspending only ordinary campaign advancement.
	home.set_process(false)
	home.set_physics_process(false)
	for node in home.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)

func observation(chapter: Node3D) -> Dictionary:
	return {"state":chapter.model.snapshot(), "horse_pose":chapter.horse.global_transform,
		"avatar_pose":chapter.avatar.global_transform, "attacker_pose":chapter.attacker.global_transform,
		"escort_pose":chapter.escort.global_transform, "horse_velocity":chapter.horse.velocity,
		"avatar_velocity":chapter.avatar.velocity, "horse_speed":chapter.horse.speed,
		"horse_stride":chapter.horse._stride, "horse_layer":chapter.horse.collision_layer,
		"horse_mask":chapter.horse.collision_mask, "avatar_layer":chapter.avatar.collision_layer,
		"avatar_mask":chapter.avatar.collision_mask,
		"horse_shape":chapter.horse.get_node("Hull").shape.get_instance_id()}

func install_live(chapter: Node3D, saved: Dictionary) -> void:
	var live := saved.duplicate(true)
	live.riding.horse.position = [8.0, 0.14, -5.0]
	live.riding.horse.yaw = 0.2
	live.riding.horse.speed = 0.0
	live.riding.horse.vertical_speed = 0.0
	live.riding.horse.grounded = true
	live.player.position = live.riding.horse.position.duplicate()
	live.actors.ranjit_singh.position = live.player.position.duplicate()
	check(chapter.model.restore(live).is_empty(), "different valid mounted live state installs")
	for _i in range(17): chapter.model.advance()
	chapter._apply()
	chapter.avatar.set_physics_process(false)

func refused_load_retains(chapter: Node3D, label: String, bytes: PackedByteArray) -> void:
	var before := observation(chapter)
	chapter._load(SAVE)
	check(chapter._message.contains("no clear standing room"), label + " explains spatial refusal")
	check(observation(chapter) == before, label + " preserves full live authority, clock, poses and movement ownership")
	check(FileAccess.get_file_as_bytes(SAVE) == bytes, label + " leaves the original save bytes unchanged")

func _run() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	var home: Node3D = Launch.make_world()
	root.add_child(home)
	current_scene = home
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	await frames(5)
	freeze_callbacks(home)
	var angle := deg_to_rad(39.0)
	# A finite plane through (0,4,0) keeps saved support well above the retained
	# Home ground, and away from the saved encounter and escort positions.
	var ramp := box(home, Vector3(0, 4.0 - .1 / cos(angle), 0), Vector3(8, .2, 8))
	ramp.rotation.x = angle
	var seed := RidingFixture.legacy_riding_seed()
	seed.riding.horse.position = [0.0, 5.0, 0.0]
	seed.riding.horse.rider_id = "ranjit_singh"
	seed.riding.horse.grounded = false
	seed.player.position = seed.riding.horse.position.duplicate()
	seed.actors.ranjit_singh.position = seed.player.position.duplicate()
	check(chapter.model.restore(seed).is_empty(), "explicit mounted legacy Home fixture installs")
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	await frames()
	var motion: Dictionary
	var motion_errors: Array[String] = []
	for _i in range(90):
		motion = chapter.horse.step(1.0 / 60.0, 0.0, 0.0, false, false, true)
		var error: String = chapter.model.record_ride(motion, 1.0 / 60.0)
		if not error.is_empty(): motion_errors.append(error)
		chapter.model.advance()
		chapter.avatar.global_position = chapter.model.position()
		await physics_frame
	check(motion_errors.is_empty(), "all native settling observations enter the existing mounted reducer")
	check(chapter.horse.is_on_floor() and chapter.model.horse_record().grounded, "actual horse and authoritative record are grounded")
	check(absf(rad_to_deg(chapter.horse.get_floor_angle()) - 39.0) < .02, "actual supporting surface is the authored 39 degree ramp")
	check(chapter.horse.global_position.y > 4.20, "rounded hull settles beyond the old short centre-ray reach")
	var saved: Dictionary = chapter.model.snapshot()
	var saved_position: Vector3 = chapter.horse.global_position
	check(chapter._candidate_error(chapter.model).is_empty(), "whole Home candidate admits the physically grounded slope record")
	check(chapter.model.save_to(SAVE).is_empty(), "actual mounted slope state saves through the existing save writer")
	var saved_bytes := FileAccess.get_file_as_bytes(SAVE)
	check(not saved_bytes.is_empty(), "saved file has observable bytes")
	install_live(chapter, saved)
	check(chapter.model.progress().tick == saved.childhood.tick + 17, "live state is distinguishable by its existing clock")
	chapter._load(SAVE)
	check(chapter._message == "Whole Home and riding skills restored.", "actual Home load accepts supported mounted slope save")
	check(RidingFixture.same_json(chapter.model.snapshot(), saved), "load restores the whole saved authority including the original tick and time")
	check(chapter.horse.global_position.is_equal_approx(saved_position) and chapter.avatar.global_position.is_equal_approx(saved_position),
		"load projects both mounted bodies onto the saved slope pose")
	check(chapter.avatar.collision_layer == 0 and chapter.avatar.collision_mask == 0 and not chapter.avatar.is_physics_processing(),
		"load retains sole horse movement ownership")
	check(FileAccess.get_file_as_bytes(SAVE) == saved_bytes, "successful load preserves save bytes")
	install_live(chapter, saved)
	var blocker := box(home, saved_position + Vector3.UP * 1.6, Vector3(.5, .5, .5))
	await frames()
	refused_load_retains(chapter, "obstructed saved hull", saved_bytes)
	blocker.queue_free()
	await frames()
	chapter._load(SAVE)
	check(chapter._message == "Whole Home and riding skills restored." and RidingFixture.same_json(chapter.model.snapshot(), saved),
		"removing hull obstruction restores whole-state load admission")
	install_live(chapter, saved)
	ramp.queue_free()
	await frames()
	refused_load_retains(chapter, "missing saved slope support", saved_bytes)
	current_scene = null
	home.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("HORSE_SLOPE_LOAD_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
