# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Presentation fixtures only; software adapter and synthetic session remain explicitly identified.
const Runtime := preload("res://platform/platform_runtime.gd")
const Launch := preload("res://childhood/home_launch.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await process_frame
func capture(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.is_empty() or image.save_png("user://platform-integration-"+name+".png")!=OK: failed+=1
	count+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var host:=Runtime.new();host.name="PlatformRuntime";root.add_child(host)
	host.configure(PackedStringArray(["--hardware-session"]),null,true)
	var menu=load("res://ui/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	await frames();menu._open_hardware();await capture("local-report")
	menu.queue_free();current_scene=null;await frames()
	var home:=Launch.make_world();root.add_child(home);current_scene=home
	var scene=home.get_node("ChildhoodChapter");await frames()
	scene._hardware_action("check|controller")
	root.size=Vector2i(800,600);await capture("operator-evidence")
	home.queue_free();current_scene=null;host.queue_free();await frames()
	var blocked:=Runtime.new();blocked.name="PlatformRuntime";root.add_child(blocked)
	blocked.configure(PackedStringArray(["--steam-app-id=1234567"]))
	menu=load("res://ui/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	root.size=Vector2i(1280,720);await frames()
	menu._scroll.scroll_vertical=2000;await capture("missing-native-client")
	menu.queue_free();current_scene=null;blocked.queue_free();await frames()
	print("STORE_INTEGRATION_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=3 else 0)
