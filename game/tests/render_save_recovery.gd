# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Labelled presentation fixtures; gamepad journeys and fault tests are independent.
const State := preload("res://narrative/oral_memory/memory_state.gd")
const Recovery := preload("res://platform/save_recovery.gd")
const Launch := preload("res://childhood/home_launch.gd")
const SLOT := "user://save-recovery-render-test-only.json"
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://platform-save-"+name+".png")!=OK: failed+=1
func _run() -> void:
	for path in [SLOT,SLOT+Recovery.PREVIOUS_SUFFIX]: DirAccess.remove_absolute(path)
	var s:=State.new()
	ok(Recovery.save(s,SLOT));s.advance();ok(Recovery.save(s,SLOT))
	root.size=Vector2i(1280,720)
	var menu=load("res://ui/main_menu.tscn").instantiate();menu.home_save_path=SLOT
	root.add_child(menu);current_scene=menu;await frames()
	menu._open_saved()
	await capture("title-overview")
	menu.queue_free();current_scene=null;await frames()
	var home:=Launch.make_world()
	var chapter=home.get_node("ChildhoodChapter");chapter.save_path=SLOT
	root.add_child(home);current_scene=home;await frames()
	root.size=Vector2i(800,600)
	chapter._confirm_saved_action("previous")
	await capture("previous-confirmation-small-window")
	ok(s.platform_services.storage.write_bytes(SLOT,"{truncated".to_utf8_buffer(),s.LIMIT))
	chapter._open_saved_chapter()
	await capture("invalid-primary-small-window")
	home.queue_free();current_scene=null;await frames()
	for path in [SLOT,SLOT+Recovery.PREVIOUS_SUFFIX]: DirAccess.remove_absolute(path)
	print("SAVE_RECOVERY_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=3 else 0)
