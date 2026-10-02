# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native lifecycle checks use the actual retained Home and actual playable scene.
const Launch := preload("res://childhood/home_launch.gd")
const Session := preload("res://history/punjab_chiefs_session.gd")
const Entry := preload("res://history/punjab_chiefs_entry.gd")
const SAVE_PATHS := ["user://1792-childhood-v1.json", "user://1792-childhood-aftermath-v1.json", "user://1792-gujranwala-v1.json", "user://1792-companions-v1.json", "user://1792-home-workshop-v2.json", "user://1792-home-workshop-v2.json.checkpoint.json"]
var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D
var entry: Node3D
var saves: Dictionary

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("PUNJAB CHIEFS SESSION: " + message)

func frames(count: int = 2) -> void:
	for _index in range(count): await physics_frame
	await process_frame

func digest_files() -> Dictionary:
	var result := {}
	for path in SAVE_PATHS:
		result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return result

func capture() -> Dictionary:
	var bodies := {}
	for body in home.find_children("*", "CharacterBody3D", true, false):
		bodies[body.get_instance_id()] = body.global_transform
	var layers := {}
	for layer in home.find_children("*", "CanvasLayer", true, false):
		layers[layer.get_instance_id()] = layer.visible
	var audio := {}
	for node in home.find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			audio[node.get_instance_id()] = node.stream_paused
	return {"snapshot": chapter.model.snapshot(), "sha": chapter.model.present_sha256(), "bodies": bodies,
		"layers": layers, "audio": audio, "process_mode": home.process_mode,
		"intro_shown": chapter._intro_shown, "art": chapter.art.get_instance_id()}

func controls(left: bool = false, backward: bool = false) -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)
	if left: Input.action_press("move_left")
	if backward: Input.action_press("move_backward")

func make_home() -> void:
	controls()
	home = Launch.make_world()
	entry = Entry.new()
	entry.name = "TestStoryBench"
	home.add_child(entry)
	root.add_child(home)
	current_scene = home
	chapter = home.get_node("ChildhoodChapter")
	await frames(3)

func _run() -> void:
	saves = digest_files()
	await make_home()
	check(not entry.nearby(), "story bench requires physical approach from the Home spawn")
	check(not entry.open_catalogue().is_empty(), "distant selector entry is refused")
	var from: Vector3 = chapter.avatar.global_position
	# Ordinary input drives the shared motor. No fixture teleports the Home player.
	controls(true, true)
	await frames(66)
	controls()
	await frames(10)
	check(chapter.avatar.global_position.distance_to(from) > 3.0, "native player motor moved toward the bench")
	check(entry.nearby(), "physical approach reaches the story bench")
	var before: Dictionary = capture()
	check(entry.open_catalogue().is_empty(), "nearby selector opens")
	check(entry._catalogue_open and home.process_mode == Node.PROCESS_MODE_DISABLED, "catalogue parks live Home")
	await frames(6)
	check(chapter.model.snapshot() == before.snapshot, "catalogue selection time changes no Home authority")
	entry.close_catalogue()
	check(capture() == before, "closing selector restores all retained flags and body transforms")
	check(digest_files() == saves, "catalogue writes no Home save")
	var story := Session.new()
	root.add_child(story)
	check(not story.start_story(chapter, "unknown").is_empty(), "unknown tale refuses before parking Home")
	check(story.start_story(chapter, "delegation").is_empty(), "actual playable tale starts")
	check(chapter.get_meta(Session.OWNER_META, null) == story, "story owns distinct metadata")
	check(story.viewport.own_world_3d and story.lesson.get_world_3d() != chapter.get_world_3d(), "tale owns separate native World3D")
	check(root.disable_3d and home.process_mode == Node.PROCESS_MODE_DISABLED, "only retained Home drawing and execution are suspended")
	check(not story.finish(true).is_empty(), "premature completed return refuses")
	check(not story._finished, "refused completion leaves playable visit active")
	var duplicate := Session.new()
	root.add_child(duplicate)
	check(not duplicate.start_story(chapter, "well").is_empty(), "overlapping tale refuses")
	duplicate.queue_free()
	controls(true, true)
	await frames(12)
	controls()
	check(chapter.model.snapshot() == before.snapshot and chapter.model.present_sha256() == before.sha, "tale input cannot advance Home authority")
	check(capture().bodies == before.bodies, "all actual Home player horse and actor bodies stay frozen")
	check(digest_files() == saves, "story input and refused completion write no Home saves")
	check(story.finish(false).is_empty(), "cancellation restores Home")
	check(capture() == before, "cancel restores exact Home state identities flags and transforms")
	check(not chapter.has_meta(Session.OWNER_META), "cancel releases only tale ownership")
	check(not root.disable_3d, "cancel restores root rendering")
	await frames(2)
	before = capture()
	var removed := Session.new()
	root.add_child(removed)
	check(removed.start_story(chapter, "well").is_empty(), "second tale opens after cancellation")
	removed.free()
	check(capture() == before, "forced overlay removal restores exact Home")
	check(not root.disable_3d and not chapter.has_meta(Session.OWNER_META), "forced cleanup releases viewport flags and ownership")
	var last := Session.new()
	root.add_child(last)
	check(last.start_story(chapter, "exile").is_empty(), "host teardown fixture starts actual visit")
	current_scene = null
	home.queue_free()
	await frames(3)
	check(not is_instance_valid(last), "host teardown releases its root story session")
	check(not root.disable_3d, "host teardown restores root drawing")
	check(digest_files() == saves, "all lifecycle routes preserve Home save bytes")
	controls()
	print("PUNJAB_CHIEFS_SESSION_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
