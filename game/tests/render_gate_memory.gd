# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Draw an already executed, source-bound gate conversation. No domain fixture is used.
## The source snapshot remains frozen; this renderer supplies no gameplay transition.
const Launch:=preload("res://childhood/home_launch.gd")
const Fields:=preload("res://misl/service_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const R:=preload("res://access/gate_rules.gd")
var passed:=0
var failed:=0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool,label: String) -> bool:
	if value:
		passed+=1
	else:
		failed+=1
		push_error("GATE MEMORY RENDER FAIL: "+label)
	return value

func finish(home: Node3D=null) -> void:
	if home!=null:
		home.queue_free()
	print("GATE_MEMORY_RENDER: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

func frames(n: int=3) -> void:
	for _i in range(n):
		await physics_frame
	await process_frame

func run() -> void:
	var directory:=OS.get_environment("GATE_CAPTURE_OUTPUT")
	if not check(not directory.is_empty() and DirAccess.dir_exists_absolute(directory),"dedicated executed-journey output directory exists"):
		finish()
		return
	var path:=directory.path_join("keeper-heard-concern.json")
	var source_bytes:=FileAccess.get_file_as_string(path)
	var parsed: Variant=JSON.parse_string(source_bytes)
	var keys: Array=["schema","snapshot","camera","source_commit","source_tree","received_account"]
	if not check(Fields.fields(parsed,keys) and parsed.get("schema")=="1792.gate-journey-capture.v1","retained executed-journey schema and exact field set"):
		finish()
		return
	var record: Dictionary=parsed
	var typed: bool=record.snapshot is Dictionary and record.camera is Array and record.camera.size()==2 and record.source_commit is String and record.source_tree is String and record.received_account is String
	if not check(typed,"retained state, camera and source identities have declared types"):
		finish()
		return
	var commit:=OS.get_environment("SOURCE_COMMIT")
	var tree:=OS.get_environment("SOURCE_TREE")
	if not check(not commit.is_empty() and not tree.is_empty() and record.source_commit==commit and record.source_tree==tree,"executed state matches both required source commit and tree"):
		finish()
		return
	var camera: Array=record.camera
	if not check(Supply.finite_number(camera[0]) and Supply.finite_number(camera[1]) and camera[0]>=-0.9 and camera[0]<=0.5 and absf(camera[1])<=PI+0.000001,"retained camera is finite and within existing player limits"):
		finish()
		return
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=directory.path_join("unwritten-render-slot.json")
	scene._paused=true # Freeze before _ready/_apply and before the first native physics tick.
	var error: String=scene.model.restore(record.snapshot)
	if not check(error.is_empty(),"retained entire world validates through the current authority: "+error):
		finish(home)
		return
	if not check(scene.model.has_gate_passage() and scene.model.gate_passage().ledger.challenge and scene.model.gate_passage().ledger.challenge_heard,"retained concern was actually heard in the executed journey"):
		finish(home)
		return
	var before:=JSON.stringify(scene.model.snapshot(),"",true,true)
	root.add_child(home)
	await frames(3)
	error=scene._candidate_error(scene.model)
	if not check(error.is_empty(),"retained body and actors have standing room in the actual scene: "+error):
		finish(home)
		return
	scene.avatar.pivot.rotation.x=float(camera[0])
	scene.avatar.pivot.rotation.y=float(camera[1])
	scene._open_gate()
	check(scene._panel_text.text==record.received_account,"native keeper dialogue reconstructs exactly the received account")
	check(scene.gate_passage.guard_root.global_position.distance_to(R.GUARD)<=R.POSITION_EPSILON and scene.gate_passage.guard_root.get_meta("actor_projection_id","")==R.GUARD_ID,"drawn keeper matches the existing authority projection")
	await frames(3)
	check(JSON.stringify(scene.model.snapshot(),"",true,true)==before,"startup and dialog reconstruction preserve canonical decoded snapshot bytes")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(scene._panel.get_global_rect()),"native keeper panel fits the 1280 by 720 viewport")
	if not check(DisplayServer.get_name()!="headless","native pixels require an actual display renderer"):
		finish(home)
		return
	await RenderingServer.frame_post_draw
	var pixels:=root.get_texture().get_image()
	if not check(pixels!=null and not pixels.is_empty() and pixels.get_width()==1280 and pixels.get_height()==720,"native viewport supplies requested pixels"):
		finish(home)
		return
	check(pixels.save_png(directory.path_join("keeper-heard-concern.png"))==OK,"keeper screenshot written from the retained executed state")
	check(JSON.stringify(scene.model.snapshot(),"",true,true)==before,"drawing preserves canonical decoded snapshot bytes and the whole-world tick")
	check(FileAccess.get_file_as_string(path)==source_bytes,"renderer retains the exact executed source file bytes")
	finish(home)
