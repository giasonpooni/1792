# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Presentation cameras compose three earned moments of the native audience
## journey. Body poses, choices, permission and stock are never set by the capture.
const Playable := preload("res://history/punjab_chiefs_playable.tscn")
const MANIFEST := "user://regency-access-manifest.json"
var scene: Node3D
var captures := 0
var failures := 0
var records: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()

func check(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error("REGENCY ACCESS RENDER: " + label)
	return condition

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
			return check(distance(scene.avatar.global_position, target) <= 2.65,
				"native arrival remains in reach")
		var local: Vector3 = scene.avatar.pivot.global_basis.inverse() * (target - scene.avatar.global_position)
		controls(local.z < -0.25, local.x < -0.25, local.x > 0.25, local.z > 0.25)
		await frames()
	controls()
	return check(false, "native route cannot reach " + str(target))

func choose_first() -> bool:
	var beat: Dictionary = scene.model.current_beat()
	var before: int = scene.model.step_index
	var error: String = scene.interact()
	if not check(error.is_empty(), "ordinary interaction admits " + str(beat.id) + ": " + error): return false
	scene._commit_choice(beat.choices[0].id)
	if not check(scene.model.step_index == before + 1, "accepted choice advances " + str(beat.id)): return false
	if not scene.model.complete(): scene._close()
	await frames(3)
	return true

func point(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func capture(id: String, camera_at: Vector3, look_at: Vector3) -> void:
	controls()
	# Camera movement is presentation only, always outside the protected room.
	scene._cut_camera.position = camera_at
	scene._cut_camera.look_at(look_at)
	scene._cut_camera.make_current()
	await frames(4)
	await RenderingServer.frame_post_draw
	var bounds := Rect2(Vector2.ZERO, Vector2(root.size))
	for control in [scene._title, scene._objective, scene._hint]:
		if not check(bounds.encloses(control.get_global_rect()), "visible gameplay HUD fits " + id): return
	var image: Image = root.get_texture().get_image()
	if not check(image != null and not image.is_empty(), "viewport renders " + id): return
	if not check(image.get_size() == Vector2i(1280, 720), "capture dimensions " + id): return
	var path := "user://regency-access-" + id + ".png"
	if not check(image.save_png(path) == OK, "capture writes " + id): return
	var sacks: Array[Dictionary] = []
	for index in range(4):
		var sack := scene._stage.find_child("CountedGrain_%d" % index, true, false) as Node3D
		if not check(sack != null, "physical bundle exists for " + id): return
		sacks.append({"id": sack.name, "parent": sack.get_parent().name, "position": point(sack.global_position)})
	records.append({"id": id, "file": path, "width": 1280, "height": 720,
		"progress": scene.model.snapshot(), "player": point(scene.avatar.global_position),
		"camera": point(scene._cut_camera.global_position),
		"companion": point(scene.companion.global_position) if is_instance_valid(scene.companion) else [],
		"access": scene.audience_status(), "supply": scene.logistics_outcome(), "bundles": sacks})
	captures += 1
	print("REGENCY_ACCESS_CAPTURE: " + ProjectSettings.globalize_path(path))
	scene._camera.make_current()
	await frames(2)

func journey() -> void:
	if not await walk_to(scene.target_position()): return
	if not await choose_first(): return
	if not await walk_to(scene.target_position() + Vector3(0, 0, 1.1), 0.4): return
	if not check(scene.interaction_error().is_empty(), "earned hearing is admitted from outside the screen"): return
	if not check(scene.avatar.global_position.z > -7.3, "hearing screenshot is on the public side"): return
	await capture("public-hearing", Vector3(5.7, 3.7, -1.0), Vector3(0, 1.6, -7.5))
	if not await choose_first(): return
	if not await walk_to(scene.target_position()): return
	if not await choose_first(): return
	if not await walk_to(scene.target_position() + Vector3(0, 0, 1.1), 0.4): return
	if not await choose_first(): return
	if not await walk_to(scene.stations.dispatch_table.global_position + Vector3(0, 0, 1.2), 0.6): return
	if not check(scene.logistics_outcome().counted_bundles == 4 and scene.logistics_outcome().issued_bundles == 2,
		"account capture follows witnessed count and a bounded authorization"): return
	await capture("account-desk", Vector3(-3.1, 4.3, 5.6), Vector3(-8.1, 1.0, -0.7))
	if not await walk_to(scene.target_position()): return
	if not await choose_first(): return
	if not check(is_instance_valid(scene.companion), "the actual runner accepted the dispatch"): return
	var gate: Vector3 = scene.target_position()
	if not await walk_to(gate + Vector3(0, 0, 3.5), 0.6): return
	if not await walk_to(gate): return
	for _tick in range(1400):
		if scene.companion.global_position.distance_to(gate) <= 4.5: break
		await frames()
	if not check(scene.companion.global_position.distance_to(gate) <= 4.5, "native runner reaches the departure gate"): return
	if not await choose_first(): return
	if not check(scene.logistics_outcome().departure_witnessed and not scene.logistics_outcome().delivered,
		"departure capture retains the limit of the locally witnessed result"): return
	for index in range(2):
		var sack := scene._stage.find_child("CountedGrain_%d" % index, true, false) as Node3D
		if not check(sack != null and sack.get_parent() == scene.companion, "two issued sacks move with the real runner"): return
	await capture("runner-at-gate", Vector3(16.4, 4.2, -7.6), Vector3(10.0, 1.1, -12.3))

func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	if not check(DisplayServer.get_name() != "headless", "captures require a rendered display"):
		finish(); return
	scene = Playable.instantiate()
	scene.configure("audience")
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	if check(scene.model.sequence_id == "audience", "existing visit starts the audience tale"):
		scene.begin_play()
		await frames(6)
		await journey()
	controls()
	current_scene = null
	scene.queue_free()
	await frames(4)
	finish()

func finish() -> void:
	check(captures == 3, "all three earned moments were captured")
	var file := FileAccess.open(MANIFEST, FileAccess.WRITE)
	if check(file != null, "manifest opens"):
		file.store_string(JSON.stringify({"schema": "1792.regency-access-render.v1", "captures": records,
			"failures": failures, "presentation": "Authored audience tale; native movement and admitted choices. Cameras compose earned state only."}, "\t"))
		file.close()
		print("REGENCY_ACCESS_MANIFEST: " + ProjectSettings.globalize_path(MANIFEST))
	print("REGENCY_ACCESS_RENDER: %d captures; %d failures" % [captures, failures])
	quit(1 if failures else 0)
