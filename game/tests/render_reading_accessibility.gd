# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit presentation fixtures; not the joypad-only journey or a human accessibility study.
const Reading := preload("res://platform/reading_profile.gd")
const ReadUI := preload("res://platform/reading_ui.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const PREFS := "user://reading-render-test-only.json"
var failed:=0
var count:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await process_frame
	await physics_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://platform-reading-"+name+".png")!=OK: failed+=1
func _run() -> void:
	Reading.install(PREFS)
	var settings:=Reading.DEFAULTS.duplicate(true);settings.text_percent=200;settings.high_contrast=true
	ok(Reading.set_preferences(settings,PREFS))
	root.size=Vector2i(1280,720)
	var menu=load("res://ui/main_menu.tscn").instantiate()
	menu.reading_settings_path=PREFS
	root.add_child(menu);current_scene=menu;await frames()
	menu._scroll.scroll_vertical=0
	await capture("title-200-percent")
	menu.queue_free();current_scene=null;await frames()
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	scene.reading_settings_path=PREFS
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home);current_scene=home;await frames()
	root.size=Vector2i(800,600)
	scene._open_reading_settings();await frames()
	scene._journal_scroll.scroll_vertical=0
	await capture("settings-small-window")
	# Original fictional story accounts are explicitly seeded for this visual-only fixture.
	for id in ["quartermaster_account","trader_account","well_echo"]:
		var site: String=Memory.content().tellings[id].site
		ok(Pose.pose(scene.model,Memory.SITES[site]+Vector3(0,0,-1)))
		ok(scene.model.oral_operation("hear",id))
	scene._apply()
	scene._open_oral_memory();await frames()
	scene._journal_scroll.scroll_vertical=0
	await capture("stories-small-window")
	scene._open_reading_settings("Not saved: simulated storage failure. Your existing text size and layout remain active.")
	await frames();scene._journal_scroll.scroll_vertical=0
	await capture("failure-small-window")
	ok(Reading.set_preferences(Reading.DEFAULTS,PREFS))
	DirAccess.remove_absolute(PREFS)
	home.queue_free();current_scene=null;await frames()
	print("READING_ACCESSIBILITY_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=4 else 0)
