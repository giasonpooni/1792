# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## The two complete audience routes use native keyboard locomotion and ordinary
## admitted dialogue. Explicit poses are confined to adversarial access, physical
## barrier and candidate-checkpoint probes; they do not count as route travel.
const Playable := preload("res://history/punjab_chiefs_playable.tscn")
const State := preload("res://history/punjab_chiefs_state.gd")
const SAVE := "user://regency-access-native-test.json"
var passed := 0
var failed := 0
var scene: Node3D
var native_routes := 0

func _initialize() -> void: _run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else: failed += 1; push_error("REGENCY ACCESS: " + label)

func frames(count: int = 1) -> void:
	for _index in range(count): await physics_frame
	await process_frame

func controls(forward := false, left := false, right := false, backward := false) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)
	if forward: Input.action_press("move_forward")
	if left: Input.action_press("move_left")
	if right: Input.action_press("move_right")
	if backward: Input.action_press("move_backward")

func distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func walk_to(target: Vector3, reach: float = 1.9) -> bool:
	for _tick in range(1600):
		if distance(scene.avatar.global_position, target) <= reach:
			controls(); await frames(10)
			return distance(scene.avatar.global_position, target) <= 2.65
		var local: Vector3 = scene.avatar.pivot.global_basis.inverse() * (target - scene.avatar.global_position)
		controls(local.z < -0.25, local.x < -0.25, local.x > 0.25, local.z > 0.25)
		await frames()
	controls()
	return false

func _create() -> void:
	controls()
	scene = Playable.instantiate()
	scene.configure("audience")
	scene.save_path = SAVE
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	check(scene.model.sequence_id == "audience", "the new tale starts through the existing scene")
	check(scene.paused and not scene.can_complete(), "opening cannot grant completion")
	scene.begin_play()
	await frames(6)

func _dispose() -> void:
	controls()
	current_scene = null
	scene.queue_free()
	await frames(3)

func _status_and_supply(label: String) -> void:
	var flags: Dictionary = scene.model.flags
	var access: Dictionary = scene.audience_status()
	var supply: Dictionary = scene.logistics_outcome()
	check(access.size() == 4, label + " keeps audience, records and residence distinct")
	check(access.get("audience_granted") == flags.get("audience_granted", false), label + " audience permission follows accepted choices")
	check(access.get("public_report") == flags.get("public_report", false), label + " report permission follows accepted choices")
	check(access.get("totals_open") == flags.get("totals_open", false), label + " account inspection follows accepted choices")
	check(access.get("residence_entry") == false, label + " never grants residential entry")
	var counted := 4 if flags.get("stock_counted", false) else 0
	var issued := 2 if flags.get("grain_issued", false) else 0
	check(supply.get("counted_bundles") == counted, label + " counts four physical provision bundles")
	check(supply.get("issued_bundles") == issued, label + " keeps local issues finite")
	check(supply.get("retained_bundles") == counted - issued, label + " conserves counted provision bundles")
	check(issued >= 0 and issued <= counted, label + " cannot issue uncounted stock")
	for key in ["remount_requested", "escort_requested", "dispatch_received", "departure_witnessed"]:
		check(supply.get(key) == flags.get(key, false), label + " retains " + key)
	check(supply.get("delivered") == false, label + " receipt and departure never assert remote delivery")
	var original_access: Dictionary = access.duplicate(true)
	var original_supply: Dictionary = supply.duplicate(true)
	access["residence_entry"] = true
	supply["issued_bundles"] = 999
	check(scene.audience_status() == original_access and scene.logistics_outcome() == original_supply,
		label + " returned policy and provision queries are detached")

func _choose(option: int) -> bool:
	var beat: Dictionary = scene.model.current_beat()
	var before: Dictionary = scene.model.snapshot()
	var error: String = scene.interact()
	check(error.is_empty(), "physical action admits " + str(beat.id) + ": " + error)
	if not error.is_empty(): return false
	scene._commit_choice(beat.choices[option].id)
	check(scene.model.step_index == before.step_index + 1, "choice advances exactly one action: " + str(beat.id))
	if scene.model.step_index != before.step_index + 1: return false
	if not scene.model.complete(): scene._close()
	await frames(2)
	_status_and_supply(str(beat.id))
	return true

func _keep(label: String) -> Dictionary:
	var result: String = scene.save_checkpoint()
	check(result == "Checkpoint kept for this telling.", label + " writes through the actual checkpoint path: " + result)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(value is Dictionary, label + " has readable saved JSON")
	return value if value is Dictionary else {}

func _capture() -> Dictionary:
	var actors := {}
	for id in scene.actors:
		actors[id] = {"transform": scene.actors[id].global_transform, "velocity": scene.actors[id].velocity}
	return {"progress": scene.model.snapshot(), "access": scene.audience_status(),
		"supply": scene.logistics_outcome(), "player": scene.avatar.global_transform,
		"velocity": scene.avatar.velocity, "camera": scene.avatar.pivot.rotation,
		"actors": actors, "companion_id": scene.companion_id, "paused": scene.paused,
		"input": scene.avatar.input_enabled, "physics": scene.avatar.is_physics_processing()}

func _reject_checkpoint(value: Dictionary, label: String) -> void:
	var before := _capture()
	check(scene.restore_checkpoint(value) != "Checkpoint recalled.", label + " rejects")
	check(_capture() == before, label + " leaves authority and native bodies unchanged")

func _adversarial_access() -> void:
	await _create()
	if scene.model.sequence_id != "audience": await _dispose(); return
	check(await walk_to(scene.target_position()), "native approach reaches the audience attendant")
	if not await _choose(0): await _dispose(); return
	check(scene.model.current_beat().target == "raj_screen", "the permission action leads to the authored screened audience")
	var screen_point: Vector3 = scene.target_position()
	check(await walk_to(screen_point + Vector3(0, 0, 1.1), 0.35), "native approach reaches the public speech point")
	check(scene.interaction_error().is_empty(), "an admitted public audience can converse directly")
	check(is_instance_valid(scene.screen_barrier), "screened audience has an actual physical barrier")
	var query := PhysicsRayQueryParameters3D.create(screen_point + Vector3.UP * 1.4,
		screen_point + Vector3(0, 1.4, -3.3), 1, [scene.avatar.get_rid()])
	var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.get("collider") == scene.screen_barrier,
		"the concealed speaking location is visually and physically occluded by the authored screen")
	var usable := _keep("before screened speech")
	var progress: Dictionary = scene.model.snapshot()
	# Explicit private-side and distant positions probe admission, not travelled history.
	scene.avatar.global_position = Vector3(0, 0.03, -8.35)
	scene.avatar.velocity = Vector3.ZERO
	await frames(2)
	check(not scene.interact().is_empty(), "private-side access refuses even with an audience permission")
	check(scene.model.snapshot() == progress, "private-side refusal preserves narrative authority")
	var private_candidate: Dictionary = usable.duplicate(true)
	private_candidate.player = [0, 0, -8.35]
	_reject_checkpoint(private_candidate, "checkpoint inside the protected room")
	scene.avatar.global_position = screen_point + Vector3(0, 0.03, 4.5)
	scene.avatar.velocity = Vector3.ZERO
	await frames(2)
	check(not scene.interact().is_empty(), "remote speech remains outside the admitted hearing radius")
	check(scene.model.snapshot() == progress, "distant speech cannot advance choices")
	check(scene.restore_checkpoint(usable) == "Checkpoint recalled.", "legitimate public audience checkpoint remains usable")
	await frames(2)
	var obstacle := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 2.6, 0.18)
	collision.shape = box
	obstacle.position = (scene.avatar.global_position + screen_point) * 0.5 + Vector3.UP * 1.3
	obstacle.add_child(collision)
	scene._stage.add_child(obstacle)
	await frames(2)
	check(not scene.interact().is_empty(), "ordinary masonry still blocks speech before the authorised screen")
	check(scene.model.snapshot() == progress, "masonry obstruction does not advance the audience")
	obstacle.queue_free()
	await frames(2)
	var interior_obstacle := StaticBody3D.new()
	var interior_collision := CollisionShape3D.new()
	var interior_box := BoxShape3D.new()
	interior_box.size = Vector3(1.5, 2.6, 0.18)
	interior_collision.shape = interior_box
	interior_obstacle.position = Vector3(0, 1.3, -8.8)
	interior_obstacle.add_child(interior_collision)
	scene._stage.add_child(interior_obstacle)
	await frames(2)
	check(not scene.interact().is_empty(), "screen exemption cannot bypass a second obstruction behind the curtain")
	check(scene.model.snapshot() == progress, "concealed obstruction refusal preserves the same audience")
	interior_obstacle.queue_free()
	await frames(2)
	check(scene.interact().is_empty(), "removing the unrelated obstruction restores the public conversation")
	check(scene._cut_camera.global_position.z >= -7.3, "audience composition keeps the camera on the public side")
	scene.avatar.global_position = Vector3(0, 0.03, -8.35)
	scene.avatar.velocity = Vector3.ZERO
	await frames(2)
	scene._commit_choice(scene.model.current_beat().choices[0].id)
	check(scene.model.snapshot() == progress, "choice commit rechecks physical admission after a modal opens")
	scene._close()
	check(scene.restore_checkpoint(usable) == "Checkpoint recalled.", "failed commit can return to the same earned moment")
	await frames(2)
	# Adversarial starting pose, then the ordinary native motor actually pushes
	# against the screen. This is a barrier probe, separate from either journey.
	scene.avatar.global_position = Vector3(0, 0.03, -6.85)
	scene.avatar.velocity = Vector3.ZERO
	scene.avatar.pivot.rotation = Vector3.ZERO
	await frames(3)
	controls(true)
	await frames(80)
	controls()
	await frames(5)
	check(scene.avatar.global_position.z >= -7.4, "native foot contact cannot penetrate the audience screen")
	check(scene.model.snapshot() == progress, "pushing the screen creates no permission or supply state")
	await _dispose()

func _journey(option: int) -> Dictionary:
	await _create()
	if scene.model.sequence_id != "audience": await _dispose(); return {}
	var early: Dictionary = {}
	var active: Dictionary = {}
	var carried_start: Array[Vector3] = []
	var retained_start: Array[Vector3] = []
	var reached := true
	while not scene.model.complete():
		var beat: Dictionary = scene.model.current_beat()
		var before: Dictionary = scene.model.snapshot()
		var target: Vector3 = scene.target_position()
		if scene._station_kind(beat.target) == "gate":
			check(await walk_to(target + Vector3(0, 0, 3.5), 0.6), "native escort route approaches the gate opening")
		var moved := await walk_to(target, 1.4 if beat.target == "raj_screen" else 1.9)
		check(moved, "native movement reaches " + str(beat.id))
		check(scene.model.snapshot() == before, "movement alone cannot perform " + str(beat.id))
		if not moved: reached = false; break
		if beat.mode == "escort":
			check(is_instance_valid(scene.companion), "departure has its earned physical dispatch recipient")
			if not is_instance_valid(scene.companion): reached = false; break
			for _tick in range(1400):
				if scene.companion.global_position.distance_to(target) <= 4.5: break
				await frames()
			check(scene.companion.global_position.distance_to(target) <= 4.5, "dispatch recipient physically arrives before departure")
			if option == 0 and carried_start.size() == 2:
				for index in range(4):
					var sack := scene._stage.find_child("CountedGrain_%d" % index, true, false) as Node3D
					if index < 2:
						check(sack != null and distance(sack.global_position, carried_start[index]) > 4.0,
							"issued bundle physically travels with the dispatch recipient")
					else:
						check(sack != null and sack.global_position.is_equal_approx(retained_start[index - 2]),
							"retained bundle remains beside the public accounts")
		if not await _choose(option): reached = false; break
		if option == 0 and scene.model.step_index == 1: early = _keep("earned audience before local policy")
		if option == 0 and scene.model.step_index == 5:
			active = _keep("received dispatch before escorted departure")
			for index in range(4):
				var sack := scene._stage.find_child("CountedGrain_%d" % index, true, false) as Node3D
				check(sack != null, "the counted stock includes its physical bundle presentation")
				if sack == null: continue
				if index < 2:
					check(sack.get_parent() == scene.companion, "issued stock is attached to the actual recipient body")
					carried_start.append(sack.global_position)
				else:
					check(sack.get_parent() == scene._stage, "unissued stock stays at the dispatch desk")
					retained_start.append(sack.global_position)
	check(reached and scene.can_complete(), "complete audience route earns its ending through native input")
	var result: Dictionary = scene.logistics_outcome()
	if reached and scene.can_complete():
		native_routes += 1
		check(scene.model.choices.size() == 7, "audience route retains all seven admitted decisions")
		check(not scene.model.ending().is_empty(), "local policy reaches an explicit outcome")
		check(result.departure_witnessed and result.dispatch_received, "completed departure has a received dispatch and physical witness")
		check(not result.delivered, "the completed local journey still does not prove remote delivery")
		if option == 0:
			scene._close()
			var bad: Dictionary = active.duplicate(true)
			bad["supplies"] = {"issued_bundles": 999}
			_reject_checkpoint(bad, "extra writable supply checkpoint field")
			bad = early.duplicate(true)
			bad.progress.flags["grain_issued"] = true
			_reject_checkpoint(bad, "unearned issue hidden in recorded flags")
			check(scene.restore_checkpoint(early) == "Checkpoint recalled.", "early audience checkpoint recalls after completed departure")
			check(scene.model.step_index == 1 and not is_instance_valid(scene.companion), "rollback removes later dispatch recipient and decisions")
			_status_and_supply("early checkpoint rollback")
			check(scene.logistics_outcome().issued_bundles == 0 and not scene.logistics_outcome().dispatch_received,
				"rollback removes later stock issues and dispatch receipt")
			check(scene.restore_checkpoint(active) == "Checkpoint recalled.", "later accepted dispatch restores after the rollback")
			check(scene.model.step_index == 5 and is_instance_valid(scene.companion), "dispatch restore retains the physical recipient and pending gate arrival")
			_status_and_supply("accepted dispatch restore")
			check(not scene.logistics_outcome().departure_witnessed, "dispatch recall does not invent the subsequent departure")
	await _dispose()
	return result

func _policy_replays() -> void:
	# These are explicitly finite choice replay fixtures, not four more native
	# journeys. The two complete travelled routes above own that evidence.
	await _create()
	if scene.model.sequence_id != "audience": await _dispose(); return
	var endings: Array[String] = []
	var outcomes: Array[Dictionary] = []
	for provision in range(2):
		for escort in range(2):
			var label := "policy replay provision=%d escort=%d" % [provision, escort]
			check(scene.model.start("audience").is_empty(), label + " begins an isolated recorded choice fixture")
			var route := [0, 0, 0, provision, 0, escort, 0]
			for option in route:
				var beat: Dictionary = scene.model.current_beat()
				check(scene.model.choose(beat.choices[option].id).is_empty(), label + " replays " + str(beat.id))
			check(scene.model.complete(), label + " has all seven recorded decisions")
			var ending: String = scene.model.ending()
			var outcome: Dictionary = scene.logistics_outcome()
			check(not ending.is_empty() and not endings.has(ending), label + " has a distinct finite narrative ending")
			check(not outcomes.has(outcome), label + " has a distinct logistics outcome")
			endings.append(ending)
			outcomes.append(outcome.duplicate(true))
			var expected_issue := 2 if provision == 0 else 0
			check(outcome.counted_bundles == 4 and outcome.issued_bundles == expected_issue
				and outcome.retained_bundles == 4 - expected_issue, label + " conserves all four counted bundles")
			check(outcome.remount_requested == (provision == 1), label + " keeps inspection requests separate from grain issues")
			check(outcome.escort_requested == (escort == 0), label + " changes escort policy independently of provision policy")
			check(outcome.dispatch_received and outcome.departure_witnessed and not outcome.delivered,
				label + " keeps the witnessed local result separate from distant delivery")
			var replay := State.new()
			check(replay.restore(JSON.parse_string(JSON.stringify(scene.model.snapshot()))).is_empty(),
				label + " survives the exact finite history format")
			check(replay.snapshot() == scene.model.snapshot() and replay.ending() == ending,
				label + " restores the same policy and ending")
	check(endings.size() == 4 and outcomes.size() == 4 and native_routes == 2,
		"all four policy combinations are checked without claiming additional native journeys")
	await _dispose()

func _run() -> void:
	await _adversarial_access()
	var issued: Dictionary = await _journey(0)
	var reserve: Dictionary = await _journey(1)
	check(native_routes == 2, "both provision policies complete through native walked routes")
	check(not issued.is_empty() and not reserve.is_empty() and issued != reserve, "alternate policies produce distinct local logistics")
	if not issued.is_empty() and not reserve.is_empty():
		check(issued.issued_bundles == 2 and issued.retained_bundles == 2, "grain policy issues two bundles and keeps two")
		check(reserve.issued_bundles == 0 and reserve.retained_bundles == 4, "remount policy preserves all four counted bundles")
		check(reserve.remount_requested and not reserve.delivered, "a remount request remains separate from observed delivery")
	await _policy_replays()
	for suffix in ["", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("REGENCY_ACCESS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
