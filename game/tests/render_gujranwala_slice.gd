# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Native viewport qualification only; no historical authentication or human playtest.
## Each run uses a caller-provided output directory and an isolated continuation.
const Menu := preload("res://ui/main_menu.tscn")
const Launch := preload("res://slice/slice_launch.gd")
var output := ""
var captures: Array[Dictionary] = []
var failures := 0
var checks: Array[Dictionary] = []
var source_files: Dictionary = {}
var source_runtime_sha256 := ""

func _initialize() -> void:
	run.call_deferred()

func frames(n: int = 5) -> void:
	for _i in range(n): await physics_frame
	await process_frame

func check(value: bool, label: String) -> void:
	checks.append({"check":label,"passed":value})
	if not value:
		failures += 1
		push_error("SLICE CAPTURE: " + label)

func inventory(path: String = "res://") -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		check(false,"Runtime source directory could not be read: " + path)
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if not name.begins_with("."):
			var child := path.path_join(name)
			if directory.current_is_dir(): inventory(child)
			elif not name.ends_with(".uid") and not name.ends_with(".import"):
				source_files[child] = FileAccess.get_sha256(child)
		name = directory.get_next()
	directory.list_dir_end()

func within_viewport(control: Control) -> bool:
	return Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect())

func qualify_menu(menu: Control) -> void:
	var scrolls := menu.find_children("*","ScrollContainer",true,false)
	check(scrolls.size() == 1,"Main menu has one bounded scroll container")
	if scrolls.size() != 1: return
	var scroll: ScrollContainer = scrolls[0]
	check(within_viewport(scroll),"Main menu scroll bounds fit " + str(root.size))
	var buttons := menu.find_children("*","Button",true,false)
	for mode in ["continue","new"]:
		var actions := buttons.filter(func(button): return button.get_meta("slice_mode","") == mode)
		check(actions.size() == 1,"Exactly one Slice action remains: " + mode)
	for destination in ["res://world/home_territory.tscn","res://world/political_home.tscn",
			"res://world/command_sandbox.tscn","res://world/house_sandbox.tscn",
			"res://mechanics/course.tscn","res://presentation/equipment_study.tscn",
			"res://mounts/horsecraft_study.tscn","res://mechanics/ground_course.tscn",
			"res://world/mahan_camp.tscn","res://history/punjab_chiefs_home.tscn"]:
		var retained := buttons.filter(func(button): return button.get_meta("destination_scene","") == destination)
		check(retained.size() == 1,"Exactly one retained destination remains: " + destination)
	for node in buttons:
		var button: Button = node
		scroll.ensure_control_visible(button)
		await frames(3)
		check(scroll.get_global_rect().encloses(button.get_global_rect()),"Menu action can be scrolled fully into view at " + str(root.size) + ": " + button.text + " / button " + str(button.get_global_rect()) + " / scroll " + str(scroll.get_global_rect()))
	scroll.scroll_vertical = 0
	await frames()

func qualify_dialog(chapter: Node3D) -> void:
	check(within_viewport(chapter._panel),"Route panel fits " + str(root.size))
	check(within_viewport(chapter._journal_scroll),"Route scroll fits " + str(root.size))
	var actions: Array = chapter._actions.get_children()
	check(actions.size() == 2,"Briefing retains courtyard and save/menu choices")
	for node in actions:
		var button: Button = node
		chapter._journal_scroll.ensure_control_visible(button)
		await frames(3)
		check(chapter._journal_scroll.get_global_rect().encloses(button.get_global_rect()),"Route action can be scrolled fully into view: " + button.text)
	chapter._journal_scroll.scroll_vertical = 0
	await frames()

func capture(id: String, kind: String, chapter: Node3D = null) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var bitmap := root.get_texture().get_image()
	var path := output.path_join("gujranwala-slice-" + id + ".png")
	if bitmap == null or bitmap.is_empty() or bitmap.save_png(path) != OK:
		check(false,"Native viewport capture failed: " + id)
		return
	check(bitmap.get_size() == root.size,"Native image dimensions match viewport: " + id)
	var record: Dictionary = {"capture_id":id,"setup":kind,"viewport":[root.size.x,root.size.y],
		"image_sha256":FileAccess.get_sha256(path),"pixel_sha256":bitmap.get_data().hex_encode().sha256_text(),
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),"source_commit":OS.get_environment("SOURCE_COMMIT"),
		"source_tree":OS.get_environment("SOURCE_TREE"),"source_runtime_sha256":source_runtime_sha256,
		"operation_id":"gujranwala-slice-native-capture.v0.1","human_playtested":false}
	if chapter != null:
		record.tick = int(chapter.model.progress().tick)
		record.snapshot_sha256 = JSON.stringify(chapter.model.snapshot(),"",true,true).sha256_text()
		record.hud_text = chapter._hud.text
		record.paused = chapter._paused
		var camera: Camera3D = chapter.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
		record.camera_position = [camera.global_position.x,camera.global_position.y,camera.global_position.z]
		record.camera_rotation = [chapter.avatar.pivot.rotation.x,chapter.avatar.pivot.rotation.y]
		if is_instance_valid(chapter.art.detail.hud) and chapter.art.detail.hud.visible:
			record.hud_text = chapter.art.detail.hud.task.text + "\n" + chapter.art.detail.hud.controls.text
	captures.append(record)

func run() -> void:
	output = OS.get_environment("GUJRANWALA_SLICE_OUTPUT")
	if output.is_empty() or not DirAccess.dir_exists_absolute(output):
		push_error("An existing GUJRANWALA_SLICE_OUTPUT directory is required.")
		quit(2)
		return
	inventory()
	source_runtime_sha256 = JSON.stringify(source_files,"",true,true).sha256_text()
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280,720)
	var menu: Control = Menu.instantiate()
	root.add_child(menu)
	await frames(8)
	await qualify_menu(menu)
	await capture("menu-full","native main-menu controls; no game-state fixture")
	root.size = Vector2i(800,450)
	await frames(8)
	await qualify_menu(menu)
	await capture("menu-compact","same native menu at compact viewport")
	root.remove_child(menu)
	menu.queue_free()
	await frames()
	root.size = Vector2i(1280,720)
	var home := Launch.make_world("new")
	var chapter: Node3D = home.get_node("ChildhoodChapter")
	chapter.continuation_path = output.path_join("isolated-render-continue.json")
	chapter.save_path = output.path_join("isolated-render-manual.json")
	root.add_child(home)
	await frames(12)
	check(chapter.continuation_ready and chapter._paused,"Actual new-run startup reaches the courtyard briefing")
	var initial: Dictionary = chapter.model.snapshot()
	await qualify_dialog(chapter)
	await capture("briefing-full","actual new-run briefing; no completed-inquiry fixture",chapter)
	root.size = Vector2i(800,450)
	await frames(8)
	await qualify_dialog(chapter)
	await capture("briefing-compact","same paused new run at compact viewport",chapter)
	check(chapter.model.snapshot() == initial,"Briefing render and scrolling preserve the entire world")
	root.size = Vector2i(1280,720)
	chapter._menu_action("resume")
	await frames(12)
	# Freeze only to capture the actual default gameplay camera/HUD consistently.
	# There is no pose, economic state, training progress or historical-fact injection.
	chapter.avatar.input_enabled = false
	chapter._refresh()
	# Freeze the actual hierarchy without presenting it as a paused conversation,
	# which deliberately hides the guided gameplay HUD.
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var display = chapter.art.detail.hud
	if is_instance_valid(display) and display.visible:
		check(within_viewport(display.top) and within_viewport(display.bottom),"Visible guided gameplay HUD fits the full viewport")
		check(not display.task.text.is_empty() and display.controls.text.contains("O  Route"),"Current objective and Slice route control remain visible")
	else:
		check(chapter._hud.is_visible_in_tree() and within_viewport(chapter._hud),"Visible legacy gameplay HUD fits the full viewport")
		check(chapter._hud.text.contains("O route") and chapter._hud.text.contains("E speak"),"Core controls remain visible in the gameplay HUD")
	var captured_state: Dictionary = chapter.model.snapshot()
	await capture("courtyard-gameplay","native fresh-courtyard gameplay camera after resuming the actual briefing",chapter)
	check(chapter.model.snapshot() == captured_state,"Gameplay capture preserves the complete frozen world")
	check(captures.size() == 5,"Five expected native captures completed")
	var original_sources: Dictionary = source_files.duplicate(true)
	source_files = {}
	inventory()
	check(source_files == original_sources,"Runtime source bytes remained unchanged throughout capture")
	source_files = original_sources
	var report: Dictionary = {"schema":"1792.gujranwala-slice-captures.v0.1","captures":captures,"checks":checks,"failures":failures,
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"source_tree":OS.get_environment("SOURCE_TREE"),
		"source_runtime_sha256":source_runtime_sha256,"source_files":source_files,
		"historical_authentication":false,"human_playtested":false,"hardware_performance_qualified":false}
	var file := FileAccess.open(output.path_join("gujranwala-slice-captures.json"),FileAccess.WRITE)
	if file == null: check(false,"Capture report could not be written")
	else:
		file.store_string(JSON.stringify(report,"\t",true,true))
		file.close()
	var paths: Array[String] = [chapter.continuation_path,chapter.save_path]
	root.remove_child(home)
	home.queue_free()
	await frames()
	for path in paths:
		for suffix in ["",".tmp",".checkpoint.json",".bazaar-retry.json"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("GUJRANWALA_SLICE_RENDER: %d captures; %d failures" % [captures.size(),failures])
	quit(1 if failures or captures.size() != 5 else 0)
