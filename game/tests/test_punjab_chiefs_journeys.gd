# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## All six tellings are reached through ordinary input and the existing native
## player/horse motors. Dialogue choices run only after physical admission.
const Playable := preload("res://history/punjab_chiefs_playable.tscn")
const IDS := ["delegation", "alliance", "revenge", "desi", "exile", "well"]
var passed := 0
var failed := 0
var scene: Node3D
var current_id := ""
var completed: Array[String] = []
var witnessed_escort_delay := false
var witnessed_ride := false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("PUNJAB CHIEFS JOURNEY [%s]: %s" % [current_id, message])

func frames(count: int = 1) -> void:
	for _index in range(count): await physics_frame
	await process_frame

func controls(forward: bool = false, left: bool = false, right: bool = false, brake: bool = false, sprint: bool = false) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)
	if forward: Input.action_press("move_forward")
	if left: Input.action_press("move_left")
	if right: Input.action_press("move_right")
	if brake: Input.action_press("move_backward")
	if sprint: Input.action_press("sprint")

func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x-b.x, a.z-b.z).length()

func walk_to(target: Vector3, reach: float = 1.9) -> bool:
	var start: Vector3 = scene.avatar.global_position
	for _tick in range(1600):
		var distance := horizontal_distance(scene.avatar.global_position, target)
		if distance <= reach:
			controls()
			await frames(12)
			return horizontal_distance(scene.avatar.global_position, target) <= 2.65
		# Keyboard directions are expressed in the actual camera basis. Headless
		# Godot has no captured hardware pointer; movement itself is unchanged.
		var local: Vector3 = scene.avatar.pivot.global_basis.inverse() * (target - scene.avatar.global_position)
		controls(local.z < -0.25, local.x < -0.25, local.x > 0.25, local.z > 0.25, distance > 4.0)
		await frames()
	controls()
	push_error("Native walk stalled from %s at %s toward %s" % [start, scene.avatar.global_position, target])
	return false

func ride_to(target: Vector3, reach: float = 2.2) -> bool:
	for _tick in range(2600):
		var position_value: Vector3 = scene.horse.global_position
		var distance := horizontal_distance(position_value, target)
		var speed: float = scene.horse.speed
		if distance <= reach and speed < 0.25:
			controls(false, false, false, true)
			await frames(3)
			controls()
			return true
		var direction := target - position_value
		var desired := atan2(-direction.x, -direction.z)
		var correction := wrapf(desired - scene.horse.rotation.y, -PI, PI)
		var stopping_distance := speed * speed / 18.0
		var brake := distance < stopping_distance + reach - 0.15 or absf(correction) > 0.22
		var left := correction > 0.045
		var right := correction < -0.045
		# At a halt the qualified horse motor pivots in place; forward input is
		# admitted only once the horse faces the next stage of the actual route.
		controls(not brake, left, right, brake)
		await frames()
	controls(false, false, false, true)
	await frames(20)
	controls()
	push_error("Native ride stalled at %s toward %s; speed=%s yaw=%s" % [scene.horse.global_position, target, scene.horse.speed, scene.horse.rotation.y])
	return false

func wait_for_companion(target: Vector3) -> bool:
	for _tick in range(1400):
		if scene.companion.global_position.distance_to(target) <= 4.5: return true
		await frames()
	return false

func _run() -> void:
	for id in IDS:
		current_id = id
		controls()
		scene = Playable.instantiate()
		scene.configure(id)
		var returned: Array[bool] = []
		scene.return_requested.connect(func(value: bool): returned.append(value))
		root.add_child(scene)
		current_scene = scene
		await frames(3)
		check(scene.paused and not scene.can_complete(), "opening begins before any objective is earned")
		scene.request_return(true)
		check(returned.is_empty() and not scene._returned, "completed return refuses before the first playable objective")
		scene.begin_play()
		await frames(3)
		var initial: Dictionary = scene.model.snapshot()
		check(not scene.interact().is_empty(), "initial distant interaction refuses")
		check(scene.model.snapshot() == initial, "distant refusal changes no narrative choices")
		var route_ok := true
		while not scene.model.complete():
			var beat: Dictionary = scene.model.current_beat()
			var target: Vector3 = scene.target_position()
			var progress_before: Dictionary = scene.model.snapshot()
			if id == "desi" and beat.id == "desi_remember":
				check(await walk_to(Vector3(0, 0, -8)), "on-foot route walks around the well masonry")
			var moved: bool = await ride_to(target, 2.35 if beat.target == "water" else 2.2) if scene.mounted else await walk_to(target, 2.25 if scene._station_kind(beat.target) == "well" else 1.9)
			check(moved, "native movement reaches " + str(beat.id))
			if not moved:
				route_ok = false
				break
			check(scene.model.snapshot() == progress_before, "movement alone never completes " + str(beat.id))
			if scene._station_kind(beat.target) == "well" and not scene.mounted and scene.interaction_error() == "Find a clear way to speak or act.":
				check(not scene.interact().is_empty(), "well support obstructs the side approach")
				check(scene.model.snapshot() == progress_before, "obstructed well approach changes no choices")
				# Walk around the real upright and face the open front of the well.
				check(await walk_to(target + Vector3(3.5, 0, 3.5), 0.35), "native route clears the well's upright")
				check(await walk_to(target + Vector3(0, 0, 2.35), 0.25), "native route reaches the open well front")
			if beat.mode == "escort":
				check(is_instance_valid(scene.companion), "escort action has an actual companion body")
				if scene.companion.global_position.distance_to(target) > 4.5:
					var refusal: String = scene.interact()
					check(refusal == "Wait for your companion to arrive.", "distant companion refuses escorted arrival")
					check(scene.model.snapshot() == progress_before, "waiting-companion refusal preserves progress")
					witnessed_escort_delay = true
				check(await wait_for_companion(target), "companion travels physically to the arrival radius")
			if beat.mode == "ride":
				check(scene.mounted and scene.ride_distance >= float(beat.get("min_ride_distance", 0)), "native horse travel meets the current ridden condition")
				check(scene.horse.speed <= 1.8, "horse has physically halted for the ridden action")
				witnessed_ride = true
			var error: String = scene.interact()
			check(error.is_empty(), "nearby current objective admits interaction: " + error)
			if not error.is_empty():
				route_ok = false
				break
			var index: int = scene.model.step_index
			var selected: Dictionary = beat.choices[0]
			scene._commit_choice(selected.id)
			check(scene.model.step_index == index + 1, "admitted choice advances exactly one objective")
			if scene.model.step_index != index + 1:
				route_ok = false
				break
			if id == "desi" and beat.id == "desi_water":
				check(not scene.mounted, "water action returns the rider to the ground")
				check(horizontal_distance(scene.avatar.global_position, scene.horse.global_position) >= 1.0, "dismount uses a clear ground position beside Desi")
			if not scene.model.complete(): scene._close()
			await frames(2)
			if id == "desi" and beat.id == "desi_water":
				check(scene.avatar.is_physics_processing(), "closing the water conversation resumes native foot movement")
		check(route_ok and scene.can_complete(), "whole physically travelled route reaches its gated ending")
		if route_ok and scene.can_complete():
			completed.append(id)
			check(scene.model.choices.size() == scene.model.sequence.beats.size(), "ending retains one real choice per objective")
			check(not scene.model.ending().is_empty(), "earned ending supplies a consequence")
			scene.request_return(true)
			check(returned == [true], "only the earned final route emits a completed return")
			scene.request_return(true)
			check(returned == [true], "completed return cannot emit twice")
		print("PUNJAB_CHIEFS_JOURNEY: id=%s complete=%s native_ticks=%d choices=%d ride_distance=%.3f" % [id, scene.can_complete(), scene.execution_steps, scene.model.choices.size(), scene.ride_distance])
		controls()
		current_scene = null
		scene.queue_free()
		await frames(3)
	check(completed.size() == IDS.size(), "all six playable sequences completed through their native routes")
	check(witnessed_escort_delay, "at least one route actually observed and waited for a lagging companion")
	check(witnessed_ride, "Desi route actually used mounted motor travel")
	print("PUNJAB_CHIEFS_JOURNEY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
