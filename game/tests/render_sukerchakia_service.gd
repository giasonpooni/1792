# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Presentation fixtures, not human playtests. Guard motion below uses the real controller.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Rules:=preload("res://misl/service_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
var captures:=0
var failures:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failures+=1;push_error(error)
func shot(name: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image();captures+=1
	if image.is_empty() or image.save_png("user://service-"+name+".png")!=OK: failures+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://service-render-isolated.json"
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home);await frames()
	ok(scene.model.begin_allowance());ok(scene.model.begin_service())
	ok(scene.model.operate("hire","guard"));ok(scene.model.rest_watch())
	scene._apply();scene._paused=true;scene.avatar.set_physics_process(false)
	var camera:=Camera3D.new();home.add_child(camera);camera.far=300;camera.current=true
	camera.position=Vector3(5,6,1);camera.look_at(Vector3(-5,1,9))
	await shot("dispatch-courtyard")
	scene._open_quartermaster();await shot("household-brief")
	ok(Pose.pose(scene.model,Rules.SITES.market));ok(scene.model.service_action("hear","market"))
	ok(Pose.pose(scene.model,Supply.QUARTERMASTER));scene._apply()
	scene._open_quartermaster();await shot("dispatch-order")
	ok(scene.model.service_action("dispatch","market"));scene._sync_economy();scene._sync_service(true);scene._resume()
	# Wait for real collision-driven movement out of the courtyard; no agent pose injection.
	for _i in range(2000):
		if scene.service_agent.global_position.z< -8: break
		await physics_frame
	scene._paused=true;scene.avatar.set_physics_process(false)
	if scene.service_agent.global_position.z>= -8: failures+=1;push_error("Service guard did not leave the actual home gate.")
	camera.position=scene.service_agent.global_position+Vector3(5,4,5)
	camera.look_at(scene.service_agent.global_position+Vector3.UP)
	await shot("guard-on-road")
	scene._open_accounts();root.size=Vector2i(800,600);await frames()
	scene._journal_scroll.scroll_vertical=int(scene._journal_scroll.get_v_scroll_bar().max_value)
	await shot("accounts-800")
	scene._resume()
	var event:=InputEventKey.new();event.keycode=KEY_F2;event.pressed=true
	scene._unhandled_input(event);await frames()
	# Show the actual new section inside the combined notebook using its real scroll.
	var prefix: String=scene._panel_text.text.get_slice("SUKERCHAKIA · DEVELOPMENT",0)
	var font: Font=scene._panel_text.get_theme_font("font")
	var font_size: int=scene._panel_text.get_theme_font_size("font_size")
	var height: float=font.get_multiline_string_size(prefix,HORIZONTAL_ALIGNMENT_LEFT,scene._panel_text.size.x,font_size).y
	scene._journal_scroll.scroll_vertical=int(height)
	await shot("research-800")
	home.queue_free();await frames()
	print("SUKERCHAKIA_SERVICE_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures or captures!=6 else 0)
