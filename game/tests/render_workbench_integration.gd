# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Views of retained, input-driven journey stages; no fabricated economic progression.
const Launch:=preload("res://childhood/home_launch.gd")
const Bench:=preload("res://workshops/accepted_workbench.gd")
var captures:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	if not ok: failed+=1;push_error("BENCH RENDER: "+label)
func frames(n: int=5) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(scene,id: String,camera: Camera3D,table_visible: bool) -> void:
	await frames();await RenderingServer.frame_post_draw
	var bench: Node3D=scene.workshop_world.bench
	if table_visible:
		var target:=bench.global_position+Vector3(0,.94,0)
		var q:=PhysicsRayQueryParameters3D.create(camera.global_position,target,1,[scene.avatar.get_rid()])
		check(scene.get_world_3d().direct_space_state.intersect_ray(q).is_empty(),"inspection camera has clear view of tabletop")
		check(not camera.is_position_behind(target) and Rect2(Vector2.ZERO,root.get_visible_rect().size).has_point(camera.unproject_position(target)),"bench in actual camera frame")
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.save_png("user://bench-gameplay-"+id+".png")==OK,"write actual framebuffer")
	captures+=1
func run() -> void:
	var record: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bench-integration-gameplay.json"))
	if not record is Dictionary or record.get("failed",-1)!=0:
		push_error("Run and pass the actual integration journey first.");quit(1);return
	for id in ["court","ready","carried","compact"]:
		root.size=Vector2i(800,450) if id=="compact" else Vector2i(1280,720)
		var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
		scene.save_path="user://bench-render-only.json"
		var state: Dictionary=record.stages.carried if id=="carried" else record.stages.ready
		check(scene.model.restore(state).is_empty(),"restore actual journey stage")
		root.add_child(home);scene._paused=true;scene.avatar.set_physics_process(false)
		await frames();check(scene._candidate_error(scene.model).is_empty(),"played snapshot fits integrated world")
		var camera: Camera3D=scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
		if id in ["court","ready"]:
			camera=Camera3D.new();camera.fov=55;camera.far=250;home.add_child(camera);camera.current=true
			camera.global_position=Vector3(-39,6.0,-1.5) if id=="court" else Vector3(-42.5,2.8,-2.8)
			camera.look_at(Bench.PLACEMENT+Vector3(0,.65,0))
			# Inspection framing hides interface text, never game geometry or actors.
			scene._hud.hide();scene._caption.hide()
			var canvas:=CanvasLayer.new();home.add_child(canvas)
			var label:=Label.new();label.position=Vector2(24,24);label.add_theme_font_size_override("font_size",22)
			label.text="1792 / WEST-GATE SMITH / ACCEPTED BENCH IN EXISTING GAME WORLD\nExecuted journey: output ready, still owned by the smith. Inspection camera."
			canvas.add_child(label)
		elif id=="carried":
			scene.avatar.pivot.rotation=Vector3(-.22,-.8,0)
			scene._message="Journey state: collected tools are carried; the bench no longer holds the order.";scene._refresh()
		else:
			scene._open_smith()
		check(scene.workshop_world.finished.visible==(id!="carried"),"one correct visible tool custodian")
		await capture(scene,id,camera,id in ["court","ready"])
		home.queue_free();await frames(3)
	print("BENCH_INTEGRATION_RENDER: %d captures; %d failures"%[captures,failed]);quit(1 if failed or captures!=4 else 0)
