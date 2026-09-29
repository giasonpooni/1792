# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit presentation fixtures. Native test_locomotion owns the input-driven journey.
const Course := preload("res://mechanics/course.gd")
var captures := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String,c: Node3D) -> void:
	await frames(6);await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty(): failures+=1;return
	var rect:=Rect2(Vector2.ZERO,Vector2(root.size))
	if not rect.encloses(c.hud.get_global_rect()) or not rect.encloses(c.status.get_global_rect()):
		print("UI BOUNDS ",root.size," hud ",c.hud.get_global_rect()," status ",c.status.get_global_rect()," visible ",root.get_visible_rect());push_error("Course UI is outside the viewport.");failures+=1;return
	if image.save_png("user://locomotion-"+name+".png")!=OK: failures+=1;return
	captures+=1
func pose(c: Node3D,p: Vector3) -> void:
	c.avatar.clear_traversal();c.avatar.global_position=p;c.avatar.velocity=Vector3.ZERO;c.avatar._grounded=false
	c.avatar._coyote=0;c.avatar._buffer=0;c.avatar.clear_motion_requests();await frames(15)
func run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var c:=Course.new();root.add_child(c);await frames(20)
	await capture("alley",c)
	var camera:=Camera3D.new();c.add_child(camera);camera.global_position=Vector3(17,18,20)
	camera.look_at(Vector3(0,0,-5));camera.current=true;camera.fov=65
	await capture("overview",c)
	await pose(c,Vector3(0,0.04,-2.7))
	camera.global_position=Vector3(4.5,3.8,-2);camera.look_at(Vector3(0,1.4,-3.3))
	var e:=InputEventAction.new();e.action="traverse_obstacle";e.pressed=true;Input.parse_input_event(e);await frames(10)
	e=InputEventAction.new();e.action="traverse_obstacle";e.pressed=false;Input.parse_input_event(e)
	c.set_paused(true);c.message="Presentation fixture: same capsule is mid-mantle; contact IK applies only when the ledge is in arm reach.";c.refresh()
	await capture("mantle",c)
	camera.current=false;c.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").current=true
	c.set_paused(false);await pose(c,Vector3(0,1.44,-10.5))
	await capture("landing",c)
	root.size=Vector2i(800,450);c.reset_course();await frames(20)
	await capture("compact",c)
	print("LOCOMOTION_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures else 0)
