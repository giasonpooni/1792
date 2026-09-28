# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared presentation fixtures, not a human playthrough. Combat below advances normally.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const R:=preload("res://youth/brawl_rules.gd")
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
	if image.is_empty() or image.save_png("user://youth-"+name+".png")!=OK: failures+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://youth-render-isolated.json"
	ok(scene.model.restore(Fixture.complete()));ok(Pose.pose(scene.model,Supply.MARKET))
	root.add_child(home);await frames()
	ok(scene.model.begin_brawl());scene._apply();scene._paused=true;scene.avatar.set_physics_process(false)
	var camera:=Camera3D.new();home.add_child(camera);camera.far=300;camera.current=true
	camera.position=Vector3(-16,6,-7);camera.look_at(Vector3(-24,1,-13))
	await shot("market-companions")
	# Explicit scene-presentation setup for the confrontation (not a played route).
	var state: Dictionary=scene.model.snapshot()
	state.player.position=Base.coords(Vector3(-12,0.14,-18));state.actors.ranjit_singh.position=state.player.position.duplicate()
	for i in [3,4]: state.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,0.14,-16))
	ok(scene.model.restore(state));scene._apply();scene._paused=true;scene.avatar.set_physics_process(false)
	var d: Vector3=scene.youths[0].global_position-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
	scene._interact();await shot("challenge-dialogue")
	scene._menu_action("youth:stand");await frames(3)
	var key:=InputEventKey.new();key.keycode=KEY_Q;key.pressed=true;Input.parse_input_event(key)
	for _i in range(160):
		d=scene.youths[0].global_position-scene.avatar.global_position;scene.avatar.pivot.rotation.y=atan2(-d.x,-d.z)
		if scene.model.brawl().ledger.stun_until[0]>=scene.model.progress().tick:
			var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;scene._unhandled_input(click)
		if scene.model.brawl().ledger.down[0]: break
		await physics_frame
	key.pressed=false;Input.parse_input_event(key)
	if not scene.model.brawl().ledger.down[0]: failures+=1;push_error("The rendered combat fixture did not execute its counter.")
	scene._paused=true;scene.avatar.set_physics_process(false)
	camera.position=Vector3(-5,6,-12);camera.look_at(Vector3(-12,1,-19))
	await shot("counter-and-companions")
	scene._resume();root.size=Vector2i(800,600)
	key=InputEventKey.new();key.keycode=KEY_T;key.pressed=true;scene._unhandled_input(key)
	await shot("story-slate-800")
	home.queue_free();await frames()
	print("YOUTH_BRAWL_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures or captures!=4 else 0)
