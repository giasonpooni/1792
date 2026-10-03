# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Fixed comparison cameras for QA only; production never creates these cameras.
## Construction fixtures are not a claim of a completed player route.
const Launch := preload("res://childhood/home_launch.gd")
const Home := preload("res://childhood/childhood_state.gd")
const Focus := preload("res://presentation/childhood_trail_focus.gd")
var captures := 0
var failed := 0
func _initialize() -> void: run.call_deferred()
func capture(home: Node3D, camera: Camera3D, suffix: String) -> void:
	for index in [1, 2]:
		var site: Vector3 = Home.SITES["track_%d" % index]
		camera.position = site + Vector3(0, 1.5, 2.7)
		camera.look_at(site)
		for _i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		var path := "user://trail-%d-%s.png" % [index, suffix]
		var result := root.get_texture().get_image().save_png(path)
		if result != OK: failed += 1
		else: captures += 1
		print("TRAIL IMAGE ", ProjectSettings.globalize_path(path))
func run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var home := Launch.make_world()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(home)
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	var staging: Node3D = chapter.get_node("ChildhoodArcStaging")
	staging.sample()
	for layer in home.find_children("*", "CanvasLayer", true, false): layer.hide()
	for label in home.find_children("*", "Label3D", true, false): label.hide()
	var camera := Camera3D.new()
	home.add_child(camera)
	camera.current = true
	camera.fov = 52
	await capture(home, camera, "cleared")
	var focus: Node3D = staging.trail_focus
	staging.remove_child(focus)
	focus.free()
	await capture(home, camera, "original-layout")
	home.queue_free()
	await process_frame
	print("CHILDHOOD_TRAIL_FOCUS_RENDER: %d captures; %d failures" % [captures, failed])
	quit(1 if failed else 0)
