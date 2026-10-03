# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Synthetic elevated platforms qualify native motion continuity through the real
## Home and House file writers and load adapters, not a traversed campaign route.
const Launch := preload("res://childhood/home_launch.gd")
const HouseScene := preload("res://world/house_sandbox.tscn")
const RidingFixture := preload("res://tests/test_riding_training.gd")
const Horse := preload("res://mounts/horse.gd")
const DT := 1.0 / 60.0
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSE MOTION RESUME LOAD: " + label)

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
	# Keep native collision registration; disabling a process mode removes it.
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

func position_of(record: Dictionary) -> Vector3:
	var p: Array = record.position
	return Vector3(p[0], p[1], p[2])

func positioned(state: Dictionary, at: Vector3, grounded: bool) -> Dictionary:
	var next := state.duplicate(true)
	next.riding.horse.position = [at.x, at.y, at.z]
	next.riding.horse.rider_id = "ranjit_singh"
	next.riding.horse.yaw = .25
	next.riding.horse.speed = 0.0
	next.riding.horse.vertical_speed = 0.0
	next.riding.horse.grounded = grounded
	next.player.position = next.riding.horse.position.duplicate()
	next.actors.ranjit_singh.position = next.player.position.duplicate()
	return next

func step_record(ctx: Dictionary) -> String:
	# Same horse and reducer as the owners; advance neither independent clocks
	# nor a second mover while qualifying this exact first-motion boundary.
	var motion: Dictionary = ctx.adapter.horse.step(DT, 0.0, 0.0, false, false, true)
	var error: String = ctx.model.record_ride(motion, DT)
	ctx.adapter.avatar.global_position = ctx.model.position() if ctx.home else ctx.model.actor_position(ctx.model.actor_id())
	return error

func native_steps(ctx: Dictionary, count: int) -> Array[String]:
	var errors: Array[String] = []
	for _i in range(count):
		var error := step_record(ctx)
		if not error.is_empty(): errors.append(error)
		await physics_frame
	return errors

func settle_at(ctx: Dictionary, state: Dictionary, at: Vector3, label: String) -> void:
	check(ctx.model.restore(positioned(state, at, false)).is_empty(), ctx.label + " " + label + " fixture installs")
	project(ctx)
	await frames()
	var errors: Array[String] = await native_steps(ctx, 60)
	check(errors.is_empty(), ctx.label + " " + label + " native settling enters the existing reducer: " + str(errors))
	check(ctx.adapter.horse.is_on_floor() and ctx.model.snapshot().riding.horse.grounded,
		ctx.label + " " + label + " actually settles native floor contact")
	check(is_zero_approx(ctx.adapter.horse.velocity.y), ctx.label + " " + label + " has stopped vertical motion")

func projection_agrees(ctx: Dictionary, label: String) -> void:
	var state: Dictionary = ctx.model.snapshot()
	var record: Dictionary = state.riding.horse
	var at := position_of(record)
	check(ctx.adapter.horse.global_position.is_equal_approx(at)
		and ctx.adapter.avatar.global_position.is_equal_approx(at), ctx.label + " " + label + " projects both mounted bodies")
	check(state.player.position == record.position and state.actors.ranjit_singh.position == record.position,
		ctx.label + " " + label + " retains actor, player and horse authority agreement")
	check(ctx.adapter.avatar.collision_layer == 0 and ctx.adapter.avatar.collision_mask == 0
		and not ctx.adapter.avatar.is_physics_processing() and not ctx.adapter.avatar.get_node("MeshInstance3D").visible,
		ctx.label + " " + label + " retains sole horse movement ownership")
	check(absf(ctx.adapter.horse.velocity.y - record.vertical_speed) < .0001,
		ctx.label + " " + label + " retains observed vertical velocity in the reducer")

func save_current(ctx: Dictionary) -> PackedByteArray:
	check(ctx.model.save_to(ctx.path).is_empty(), ctx.label + " actual file writer succeeds")
	var bytes := FileAccess.get_file_as_bytes(ctx.path)
	check(not bytes.is_empty(), ctx.label + " saved file has observable bytes")
	return bytes

func admitted(ctx: Dictionary, saved: Dictionary, bytes: PackedByteArray, label: String) -> void:
	load_saved(ctx)
	var message: String = ctx.adapter._message if ctx.home else ctx.adapter._notice
	var expected := "Whole Home and riding skills restored." if ctx.home else "Loaded. Horse, rider, patrol and house decisions restored."
	check(message == expected, ctx.label + " " + label + " actual load succeeds: " + message)
	check(RidingFixture.same_json(ctx.model.snapshot(), saved), ctx.label + " " + label + " immediately restores the whole saved authority")
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, saved), ctx.label + " " + label + " restores the saved clock")
	projection_agrees(ctx, label + " immediate load")
	check(FileAccess.get_file_as_bytes(ctx.path) == bytes, ctx.label + " " + label + " preserves saved bytes")

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
		"path":"user://horse-motion-resume-home-native-only.json" if home_mode else "user://horse-motion-resume-house-native-only.json"}
	var center := Vector3(0 if home_mode else 30, 4, 0)
	box(world, center - Vector3.UP * .1, Vector3(10, .2, 10))
	var seed: Dictionary = RidingFixture.legacy_riding_seed() if home_mode else ctx.model.snapshot()
	await settle_at(ctx, seed, center + Vector3.UP * .14, "initial mounted support")
	# The saved falling motion follows actual native steps, not an invented
	# velocity. Teleporting the fixture starts well clear of all support.
	var falling_seed := positioned(ctx.model.snapshot(), center + Vector3.UP * 3.0, false)
	check(ctx.model.restore(falling_seed).is_empty(), ctx.label + " explicit falling entry installs")
	project(ctx)
	await frames()
	var fall_errors: Array[String] = await native_steps(ctx, 8)
	check(fall_errors.is_empty(), ctx.label + " actual falling observations enter the existing reducer")
	check(not adapter.horse.is_on_floor() and not ctx.model.snapshot().riding.horse.grounded
		and adapter.horse.velocity.y < -2.0, ctx.label + " saved fixture is genuinely falling clear of support")
	var falling_saved: Dictionary = ctx.model.snapshot()
	var falling_bytes := save_current(ctx)
	var saved_at := position_of(falling_saved.riding.horse)
	var saved_vy: float = falling_saved.riding.horse.vertical_speed
	await settle_at(ctx, falling_saved, center + Vector3(2, .14, 0), "distinguishable live support")
	for _i in range(17): ctx.model.advance()
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, falling_saved) + 17,
		ctx.label + " live clock differs by exactly 17 existing ticks")
	check(adapter.horse.is_on_floor() and adapter.horse.global_position.distance_to(saved_at) > 2.0,
		ctx.label + " pre-load native floor contact and live pose differ from saved fall")
	admitted(ctx, falling_saved, falling_bytes, "airborne over grounded live cache")
	# There must be no extra native move or physics frame between loading and
	# this assertion: it qualifies the first real step with the old floor cache.
	var error := step_record(ctx)
	check(error.is_empty(), ctx.label + " first resumed falling observation is admitted: " + error)
	var expected_vy := saved_vy - Horse.GRAVITY * DT
	var expected_y := saved_at.y + expected_vy * DT
	check(absf(adapter.horse.velocity.y - expected_vy) < .0001,
		ctx.label + " first resumed fall retains saved velocity plus gravity; observed=%f expected=%f" % [adapter.horse.velocity.y, expected_vy])
	check(absf(adapter.horse.global_position.y - expected_y) < .0001,
		ctx.label + " first resumed fall advances saved position by retained velocity; observed=%f expected=%f" % [adapter.horse.global_position.y, expected_y])
	check(not adapter.horse.is_on_floor() and not ctx.model.snapshot().riding.horse.grounded,
		ctx.label + " first resumed falling motion remains airborne")
	projection_agrees(ctx, "first resumed fall")
	await physics_frame
	for i in range(5):
		expected_vy -= Horse.GRAVITY * DT
		expected_y += expected_vy * DT
		error = step_record(ctx)
		check(error.is_empty(), ctx.label + " resumed clear-air step %d enters reducer" % (i + 2))
		check(absf(adapter.horse.velocity.y - expected_vy) < .0002 and absf(adapter.horse.global_position.y - expected_y) < .0002,
			ctx.label + " resumed clear-air step %d follows the retained trajectory" % (i + 2))
		await physics_frame
	var landing_errors: Array[String] = await native_steps(ctx, 80)
	check(landing_errors.is_empty(), ctx.label + " resumed trajectory lands through the same reducer: " + str(landing_errors))
	check(adapter.horse.is_on_floor() and ctx.model.snapshot().riding.horse.grounded and is_zero_approx(adapter.horse.velocity.y),
		ctx.label + " resumed trajectory ends on the actual supporting platform")
	check(absf(adapter.horse.global_position.y - center.y) < .01, ctx.label + " final landed pose agrees with platform elevation")
	projection_agrees(ctx, "landed resumed trajectory")
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, falling_saved), ctx.label + " horse observations do not own or advance the campaign clock")
	check(FileAccess.get_file_as_bytes(ctx.path) == falling_bytes, ctx.label + " resumed motion preserves original falling save bytes")
	# Qualify the opposite cache mismatch too: a grounded file loaded while the
	# live body's native cache says airborne must remain supported and stable.
	var grounded_saved: Dictionary = ctx.model.snapshot()
	var grounded_bytes := save_current(ctx)
	var grounded_at := position_of(grounded_saved.riding.horse)
	check(ctx.model.restore(positioned(grounded_saved, center + Vector3(2, 3, 0), false)).is_empty(),
		ctx.label + " different airborne live entry installs")
	project(ctx)
	await frames()
	fall_errors = await native_steps(ctx, 8)
	check(fall_errors.is_empty() and not adapter.horse.is_on_floor() and adapter.horse.velocity.y < -2.0,
		ctx.label + " opposite pre-load cache is actually airborne")
	for _i in range(17): ctx.model.advance()
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, grounded_saved) + 17,
		ctx.label + " opposite live clock differs by exactly 17 existing ticks")
	admitted(ctx, grounded_saved, grounded_bytes, "grounded over airborne live cache")
	error = step_record(ctx)
	check(error.is_empty(), ctx.label + " first restored support observation enters reducer")
	check(adapter.horse.is_on_floor() and ctx.model.snapshot().riding.horse.grounded and is_zero_approx(adapter.horse.velocity.y),
		ctx.label + " first grounded resume acquires actual floor contact")
	check(adapter.horse.global_position.distance_to(grounded_at) < .003, ctx.label + " first grounded resume retains the supported pose")
	await physics_frame
	var stable_errors: Array[String] = await native_steps(ctx, 20)
	check(stable_errors.is_empty() and adapter.horse.global_position.distance_to(grounded_at) < .003,
		ctx.label + " grounded resume remains stable on later native steps")
	projection_agrees(ctx, "grounded resumed trajectory")
	check(clock(ctx, ctx.model.snapshot()) == clock(ctx, grounded_saved) and FileAccess.get_file_as_bytes(ctx.path) == grounded_bytes,
		ctx.label + " grounded native resume preserves saved clock and file bytes")
	current_scene = null
	world.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ctx.path))

func _run() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	await exercise(true)
	await exercise(false)
	print("HORSE_MOTION_RESUME_LOAD_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
