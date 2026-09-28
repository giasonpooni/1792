# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit render fixtures. Actual input-driven two-trip traversal is tested separately.
const Launch := preload("res://childhood/home_launch.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Water := preload("res://territory/water_round_rules.gd")
var count:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failed+=1;push_error(error)
func check(value: bool,label: String) -> void:
	if not value: failed+=1;push_error(label)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	count+=1
	if image.is_empty() or image.save_png("user://water-round-"+name+".png")!=OK: failed+=1
func _run() -> void:
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path="user://water-round-render-only.json"
	ok(scene.model.restore(Fixture.complete()))
	root.add_child(home)
	await frames()
	ok(scene.model.begin_allowance())
	scene._open_quartermaster()
	await capture("assignment")
	scene._resume()
	ok(scene.model.begin_water_round())
	ok(Pose.pose(scene.model,Vector3(26,0.14,14)))
	scene._apply()
	var camera:=Camera3D.new()
	camera.far=180
	home.add_child(camera)
	camera.position=Vector3(31,6,21)
	camera.look_at(Vector3(24,1.5,15))
	camera.current=true
	ok(scene.model.water_action("draw"))
	await frames(80)
	await capture("drawing")
	await frames(185)
	check(scene.model.water_round().ledger.carried==3,"render fixture holds water")
	await capture("carrying")
	ok(Pose.pose(scene.model,Water.STORE-Vector3(0,0,1)))
	scene._apply()
	ok(scene.model.water_action("deposit"))
	ok(Pose.pose(scene.model,Vector3(26,0.14,14)))
	ok(scene.model.water_action("draw"))
	for _i in range(180):scene.model.advance()
	ok(Pose.pose(scene.model,Water.STORE-Vector3(0,0,1)))
	scene._apply()
	ok(scene.model.water_action("deposit"))
	camera.position=Vector3(12,6,12)
	camera.look_at(Vector3(3,1,5))
	await frames()
	check(scene.water_view.tank_water.visible,"rendered household vessel is provisioned")
	await capture("complete")
	root.size=Vector2i(800,600)
	scene._open_accounts()
	await frames()
	check(scene._paused,"small window account view pauses")
	await capture("small-window")
	home.queue_free()
	await frames()
	print("WATER_ROUND_RENDER: %d captures; %d failures"%[count,failed])
	quit(1 if failed or count!=5 else 0)
