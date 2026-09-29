# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit presentation fixtures. Uses production model, motor, UI and budget.
const Launch:=preload("res://childhood/home_launch.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const C:=preload("res://commissions/commission_rules.gd")
var captures:=0
var failures:=0
var scene: Node3D
var home: Node3D
var camera: Camera3D
func _initialize() -> void: run.call_deferred()
func frames(n: int=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func ok(error: String) -> void:
	if not error.is_empty(): failures+=1;push_error(error)
func shot(id: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if image.is_empty() or image.save_png("user://commission-"+id+".png")!=OK: failures+=1
	captures+=1
func freeze() -> void:
	scene._paused=true;scene.avatar.set_physics_process(false);scene.specialist_body.set_physics_process(false)
func view(p: Vector3,target: Vector3) -> void:
	camera.global_position=p;camera.look_at(target);camera.current=true
func run() -> void:
	root.size=Vector2i(1280,720)
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter");scene.save_path="user://commission-render-only.json"
	ok(scene.model.restore(Fixture.complete()));root.add_child(home);await frames(6)
	ok(scene.model.begin_allowance());ok(scene.model.commission_action("reserve","standard"));scene._apply()
	scene._open_quartermaster();await shot("reserved-budget")
	scene._resume();ok(Pose.pose(scene.model,C.BROKER));ok(scene.model.commission_action("broker"))
	ok(Pose.pose(scene.model,C.RECEPTION+Vector3(1.2,0,1.4)));scene._apply();freeze()
	camera=Camera3D.new();camera.fov=58;home.add_child(camera)
	view(Vector3(-19,4.8,-3),C.RECEPTION+Vector3.UP);scene._refresh()
	await shot("receiving-yard")
	# Reuse the output of the actual input-driven test; no fabricated appointment receipt.
	var result: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://commission-journey.json"))
	if not result is Dictionary or result.get("kind")!="input_driven_after_declared_inquiry_fixture":
		failures+=1;push_error("Run test_commissions.gd before render; actual journey result required.")
	else:
		ok(scene.model.restore(result.state));scene._apply();freeze()
		view(Vector3(11,6.2,14),Vector3(4,1,5));scene._refresh()
		await shot("returned-household")
		ok(scene.model.commission_action("control",C.SPECIALIST));scene._apply();freeze()
		scene.specialist_body.pivot.rotation=Vector3(-.25,-.6,0);scene._message="Instructor · One practice session is complete. Wages remain an obligation each watch.";scene._refresh()
		await shot("instructor-view")
		scene._open_journal();root.size=Vector2i(800,600);await frames(8)
		await shot("limited-journal-800")
		ok(scene.model.commission_action("control",C.HERO));scene._apply();freeze()
		scene._open_accounts();await frames(6);scene._journal_scroll.scroll_vertical=int(scene._journal_scroll.get_v_scroll_bar().max_value)
		await shot("budget-800")
	home.queue_free();await frames()
	print("COMMISSION_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures or captures!=6 else 0)
