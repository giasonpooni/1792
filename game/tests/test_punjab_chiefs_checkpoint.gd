# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Checkpoints use the real scene, save writer, loader and physics world. Native
## movement earns the setup choices; explicit body poses below are adversarial
## fixtures for candidate-vs-live occupancy, not evidence of player travel.
const Playable := preload("res://history/punjab_chiefs_playable.tscn")
const SAVE := "user://punjab-chiefs-checkpoint-regression.json"
var passed := 0
var failed := 0
var scene: Node3D

func _initialize() -> void: _run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else: failed += 1; push_error("PUNJAB CHIEFS CHECKPOINT: " + label)

func frames(count: int = 2) -> void:
	for _index in range(count): await physics_frame
	await process_frame

func controls(forward := false, left := false, right := false, back := false) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]: Input.action_release(action)
	if forward: Input.action_press("move_forward")
	if left: Input.action_press("move_left")
	if right: Input.action_press("move_right")
	if back: Input.action_press("move_backward")

func distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func walk(target: Vector3) -> bool:
	for _tick in range(1500):
		if distance(scene.avatar.global_position,target)<1.9:
			controls(); await frames(8); return true
		var local: Vector3 = scene.avatar.pivot.global_basis.inverse()*(target-scene.avatar.global_position)
		controls(local.z < -0.2, local.x < -0.2, local.x > 0.2, local.z > 0.2)
		await frames(1)
	controls()
	return false

func choose_here() -> bool:
	var beat: Dictionary = scene.model.current_beat()
	var error: String = scene.interact()
	check(error.is_empty(), "physical setup admits " + str(beat.id) + ": " + error)
	if not error.is_empty(): return false
	var before: int = scene.model.step_index
	scene._commit_choice(beat.choices[0].id)
	check(scene.model.step_index == before+1, "physical setup chooses " + str(beat.id))
	scene._close()
	await frames(3)
	return scene.model.step_index == before+1

func create(id: String) -> void:
	controls()
	scene = Playable.instantiate()
	scene.configure(id)
	scene.save_path = SAVE
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	scene.begin_play()
	await frames(6)

func dispose() -> void:
	controls()
	current_scene = null
	scene.queue_free()
	await frames(3)

func keep(label: String) -> Dictionary:
	var result: String = scene.save_checkpoint()
	check(result == "Checkpoint kept for this telling.", label + " writes actual checkpoint: " + result)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(value is Dictionary, label + " produces readable JSON")
	return value if value is Dictionary else {}

func exception_ids(body: PhysicsBody3D) -> Array:
	var ids: Array = []
	for other in body.get_collision_exceptions(): ids.append(other.get_instance_id())
	ids.sort()
	return ids

func capture() -> Dictionary:
	var bodies := {}
	for id in scene.actors:
		var actor: CharacterBody3D = scene.actors[id]
		bodies[id] = {"transform":actor.global_transform,"velocity":actor.velocity,"exceptions":exception_ids(actor)}
	var result := {"progress":scene.model.snapshot(),"player":scene.avatar.global_transform,
		"velocity":scene.avatar.velocity,"pivot":scene.avatar.pivot.rotation,"mounted":scene.mounted,
		"distance":scene.ride_distance,"companion_id":scene.companion_id,"actors":bodies,
		"avatar_exceptions":exception_ids(scene.avatar),"input":scene.avatar.input_enabled,
		"physics":scene.avatar.is_physics_processing(),"paused":scene.paused,
		"collider":scene.avatar.get_node("CollisionShape3D").disabled,
		"spring":scene.avatar.get_node("CameraPivot/SpringArm3D").spring_length,
		"costume":scene._costume.transform,"pending":scene._pending_choice,
		"interaction":scene._interaction_requested}
	if is_instance_valid(scene.horse):
		result.horse = {"transform":scene.horse.global_transform,"velocity":scene.horse.velocity,"speed":scene.horse.speed}
	return result

func reject(value: Variant, label: String) -> void:
	var before := capture()
	var error: String = scene.restore_checkpoint(value)
	check(error != "Checkpoint recalled.", label + " rejects")
	check(capture() == before, label + " is atomic across progress and physical bodies")

func recalled(value: Dictionary, label: String) -> bool:
	var result: String = scene.restore_checkpoint(value)
	check(result == "Checkpoint recalled.", label + ": " + result)
	return result == "Checkpoint recalled."

func _companion() -> void:
	await create("delegation")
	var initial := keep("before escort")
	check(await walk(scene.target_position()), "native walk reaches keeper")
	if not await choose_here(): await dispose(); return
	check(await walk(scene.target_position()), "native walk reaches delegate")
	if not await choose_here(): await dispose(); return
	check(is_instance_valid(scene.companion), "earned escort installs an actual body")
	if not is_instance_valid(scene.companion): await dispose(); return
	check(await walk(Vector3(3,0,2)), "native walk leads companion away from anchor")
	await frames(60)
	var active := keep("active escort")
	var actor: CharacterBody3D = scene.companion
	check(distance(actor.global_position,scene.stations[scene.companion_id].global_position)>1, "companion physically left its waiting station")
	# Stop stepping while comparing a restore transaction. Candidate transforms
	# must be judged independently of movable bodies' present locations.
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	actor.global_position = scene._point(initial.player)
	actor.velocity = Vector3(1,0,0)
	await frames(2)
	if recalled(initial,"rollback ignores displaced companion at saved player location"):
		check(scene.companion_id.is_empty() and not is_instance_valid(scene.companion), "rollback removes active escort reference")
		check(actor.global_position.is_equal_approx(scene.stations["delegate"].global_position) and actor.velocity == Vector3.ZERO, "rollback restores former companion to waiting station")
		check(not scene.avatar.get_collision_exceptions().has(actor) and not actor.get_collision_exceptions().has(scene.avatar), "rollback removes both escort collision exceptions")
		check(scene.model.step_index == 0, "rollback restores unearned escort progress")
	if recalled(active,"active companion checkpoint restores after rollback"):
		check(scene.companion == actor and scene.companion_id == "delegate", "same actor resumes the saved escort")
		check(actor.global_position.is_equal_approx(scene._point(active.companion)), "saved companion position is restored")
		check(scene.avatar.get_collision_exceptions().has(actor) and actor.get_collision_exceptions().has(scene.avatar), "restored escort installs both exceptions")
		check(scene.model.step_index == 2, "restored escort resumes its arrival objective")
	# Corrupt payloads must leave the retained companion and native player intact.
	for kind in ["extra", "progress", "player_wall", "companion_wall", "companion_id", "companion_yaw", "camera", "riding", "distance"]:
		var bad: Dictionary = active.duplicate(true)
		match kind:
			"extra": bad["campaign_tick"] = 100
			"progress": bad.progress.flags["unearned"] = true
			"player_wall": bad.player = [19,0,0]
			"companion_wall": bad.companion = [19,0,0]
			"companion_id": bad.companion_id = "keeper"
			"companion_yaw": bad.companion_yaw = INF
			"camera": bad.camera = [0,"bad",0]
			"riding": bad.mounted = true
			"distance": bad.ride_distance = INF
		reject(bad,"corrupt escort " + kind)
	for bad in [null,[],{"schema":"other"}]: reject(bad,"invalid checkpoint container")
	# Exercise the disk loader, including JSON parsing failure, without changing
	# the legitimate saved checkpoint into an invented progress fixture.
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string("{broken"); file.close()
	var before := capture()
	check(scene.load_checkpoint() != "Checkpoint recalled.", "corrupt disk checkpoint refuses")
	check(capture() == before, "corrupt disk checkpoint preserves physical visit")
	file = FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify(active)); file.close()
	check(scene.load_checkpoint() == "Checkpoint recalled.", "actual saved escort JSON loads")
	await dispose()

func _rider() -> void:
	await create("desi")
	var foot := keep("before mounting")
	var digest := FileAccess.get_sha256(SAVE)
	# Synthetic falling-body fixture: the regular story motor currently has no
	# jump input. A transient airborne pose must not replace a usable checkpoint.
	scene.avatar.global_position.y += 1.5
	await frames(2)
	check(not scene.avatar.is_on_floor(), "falling foot fixture is genuinely off the floor")
	check(scene.save_checkpoint() != "Checkpoint kept for this telling.", "airborne foot save refuses")
	check(FileAccess.get_sha256(SAVE) == digest, "refused airborne save preserves previous checkpoint file")
	recalled(foot,"resume grounded checkpoint after falling fixture")
	await frames(3)
	check(await walk(scene.target_position()), "native walk reaches Desi")
	if not await choose_here(): await dispose(); return
	check(scene.mounted and scene.model.flags.get("mounted",false), "actual admitted choice mounts rider")
	var seated := keep("mounted")
	digest = FileAccess.get_sha256(SAVE)
	scene.horse.global_position.y += 1.5
	await frames(2)
	check(not scene.horse.is_on_floor(), "falling horse fixture is genuinely off the floor")
	check(scene.save_checkpoint() != "Checkpoint kept for this telling.", "airborne mounted save refuses")
	check(FileAccess.get_sha256(SAVE) == digest, "refused airborne mounted save preserves file")
	recalled(seated,"resume grounded mounted checkpoint after falling fixture")
	await frames(3)
	controls(true)
	await frames(45)
	controls(false,false,false,true)
	await frames(65)
	controls()
	check(scene.ride_distance>0.4, "native horse travels after the kept moment")
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	# A present horse over the old foot pose must not obstruct a candidate in
	# which the horse returns to its own saved, separated position.
	scene.horse.global_position = scene._point(foot.player)
	await frames(2)
	if recalled(foot,"foot rollback ignores the horse's superseded position"):
		check(not scene.mounted and scene.avatar.input_enabled and scene.avatar.is_physics_processing(), "foot rollback resumes native player motor")
		check(is_equal_approx(scene.avatar.get_node("CameraPivot/SpringArm3D").spring_length,5.5), "foot rollback restores walking camera")
		check(is_zero_approx(scene._costume.position.y), "foot rollback removes seated costume offset")
		check(scene.avatar.global_position.is_equal_approx(scene._point(foot.player)), "foot rollback restores saved player location")
		check(scene.horse.global_position.is_equal_approx(scene._point(foot.horse)), "foot rollback restores horse independently")
	if recalled(seated,"mounted checkpoint restores after foot rollback"):
		check(scene.mounted and not scene.avatar.input_enabled and not scene.avatar.is_physics_processing(), "mounted restore gives movement authority to horse")
		check(scene.avatar.global_position.is_equal_approx(scene.horse.saddle_support_point()), "mounted player restores onto the native saddle")
		check(is_equal_approx(scene.avatar.get_node("CameraPivot/SpringArm3D").spring_length,7.0), "mounted restore restores riding camera")
		check(is_equal_approx(scene._costume.position.y,-0.78), "mounted restore immediately restores rider costume")
		check(scene.horse.speed == 0 and scene.horse.velocity == Vector3.ZERO, "mounted restore halts native horse")
	await frames(2)
	check(scene.avatar.get_node("CollisionShape3D").disabled, "mounted restore disables foot collider")
	for kind in ["horse_wall","horse_air","horse_yaw","horse_yaw_bounds","mounted_mismatch","player_type"]:
		var bad: Dictionary = seated.duplicate(true)
		match kind:
			"horse_wall": bad.horse = [24,0,0]
			"horse_air": bad.horse = [0,15,0]
			"horse_yaw": bad.horse_yaw = NAN
			"horse_yaw_bounds": bad.horse_yaw = 1e20
			"mounted_mismatch": bad.mounted = false
			"player_type": bad.player = [true,0,0]
		reject(bad,"corrupt rider " + kind)
	scene._open("Paused checkpoint fixture",[{"text":"Continue","call":scene._close}])
	if recalled(foot,"restoring while paused retains the modal freeze"):
		check(scene.paused and not scene.avatar.input_enabled and not scene.avatar.is_physics_processing(), "paused foot restore cannot execute beneath dialogue")
	scene._close()
	await frames(2)
	check(not scene.avatar.get_node("CollisionShape3D").disabled, "foot restore re-enables foot collider")
	check(scene.load_checkpoint() == "Checkpoint recalled.", "actual saved mounted JSON loads after reopening")
	await dispose()

func _litter() -> void:
	await create("litter")
	var initial := keep("before covered-litter departure")
	var waiting_pose: Transform3D = scene._covered_litter.global_transform
	while not scene.model.complete() and scene.model.current_beat().mode != "escort":
		check(await walk(scene.target_position()), "native walk reaches litter preparation")
		if not await choose_here(): await dispose(); return
	check(is_instance_valid(scene.companion), "litter departure has a physical bearer")
	if not is_instance_valid(scene.companion): await dispose(); return
	check(await walk(Vector3(3,0,2)), "native walk leads the covered party")
	await frames(60)
	var active := keep("covered-litter party on the path")
	var travelling_pose: Transform3D = scene._covered_litter.global_transform
	check(not travelling_pose.origin.is_equal_approx(waiting_pose.origin), "covered litter moves with the earned escort")
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	if recalled(initial,"pre-departure recall restores covered-litter staging"):
		check(scene._covered_litter.global_transform.is_equal_approx(waiting_pose), "covered litter returns to its waiting pose")
		check(not is_instance_valid(scene.companion), "recalled preparations do not retain a following bearer")
	if recalled(active,"active departure recall restores covered party"):
		check(scene._covered_litter.global_transform.is_equal_approx(travelling_pose), "covered litter resumes the saved bearer pose")
		check(scene.model.current_beat().mode == "escort", "active recall still requires arrival at the gate")
	var legacy: Dictionary = active.duplicate(true)
	legacy.schema = "1792.punjab-chiefs.visit.v1"
	legacy.erase("companion_yaw")
	if recalled(legacy,"earlier checkpoint format remains readable"):
		check(scene.companion.global_position.is_equal_approx(scene._point(active.companion)), "legacy recall retains the earned companion position")
		check(scene.model.current_beat().mode == "escort", "legacy recall retains the pending arrival")
	await dispose()

func _run() -> void:
	await _companion()
	await _rider()
	await _litter()
	for suffix in ["",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("PUNJAB_CHIEFS_CHECKPOINT_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
