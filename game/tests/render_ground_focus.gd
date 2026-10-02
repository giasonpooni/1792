# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit synthetic observation fixtures, drawn by Godot in the real Home scene.
## Fixture preparation uses the retained model tick; captures never advance or save the world.
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://perception/focus_rules.gd")
var output := "user://ground-focus-images"
var captures: Array=[]
var failed := 0
var home: Node3D
var scene: Node3D
var camera: Camera3D
var contact: Node3D
var fixture_label: Label
var baseline: Dictionary

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value:
		failed+=1
		push_error("GROUND FOCUS RENDER FAIL: "+label)

func frames(count: int=3) -> void:
	for _i in range(count): await process_frame
	await RenderingServer.frame_post_draw

func prepare() -> void:
	check(scene.model.restore(baseline).is_empty(), "restore validated native render fixture")
	scene._apply()
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	scene.avatar.input_enabled=false
	scene.avatar.pivot.rotation=Vector3.ZERO
	scene.ground_focus._targets.clear()
	scene.ground_focus._sounds.clear()
	contact.show()
	contact.global_position=Vector3(-13,0.14,-3)
	scene.ground_focus.register_target("native_home_fixture",contact,"Unknown contact","contact",Vector3.UP*1.15)
	camera.global_position=Vector3(-10,4.3,6)
	camera.look_at(Vector3(-14.5,1.2,-3))
	camera.current=true
	for layer in home.find_children("*","CanvasLayer",true,false): layer.hide()
	scene._marker.hide()
	fixture_label.get_parent().show()

func advance_sensor() -> void:
	scene.model.advance()
	scene.ground_focus.sample(int(scene.model.progress().tick))

func stage(mode: String) -> void:
	print("GROUND_FOCUS_STAGE: "+mode)
	prepare()
	if mode=="default": return
	scene.ground_focus.start()
	for _i in range(Rules.DWELL_TICKS): advance_sensor()
	check(scene.ground_focus.observations().size()==1, "real Home sensor acquires "+mode+" fixture")
	if mode=="lastseen":
		contact.hide()
		for _i in range(90): advance_sensor()
	elif mode=="estimated":
		for _i in range(Rules.MOTION_INTERVAL):
			contact.position.x+=0.016
			advance_sensor()
		check(scene.ground_focus.predictions().has("native_home_fixture"), "observed native displacement creates the estimated fixture")
		contact.hide(); advance_sensor()
	scene.ground_focus.sample(int(scene.model.progress().tick))
	check(not scene.ground_focus.overlay.marks.is_empty(), "fixture observation appears in the native camera: "+mode)

func gameplay_view() -> void:
	print("GROUND_FOCUS_GAMEPLAY: begin")
	camera.current=false
	var player_camera: Camera3D=scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	player_camera.current=true
	var arm: SpringArm3D=player_camera.get_parent()
	arm.set_physics_process_internal(true)
	scene.avatar.pivot.rotation=Vector3(-0.1,0,0)
	scene._refresh()
	scene._caption.show(); scene._narrator_label.show()
	scene._veil.visible=scene._subjective
	for visual in [scene._hud,scene._caption,scene._narrator_label,scene._veil]:
		var ancestor: Node=visual.get_parent()
		while ancestor!=null and ancestor!=scene:
			if ancestor is CanvasLayer: ancestor.show()
			ancestor=ancestor.get_parent()
	scene.ground_focus.sample(int(scene.model.progress().tick))
	print("GROUND_FOCUS_GAMEPLAY: ready")

func capture(mode: String, size: Vector2i) -> void:
	print("GROUND_FOCUS_BEGIN: %s %dx%d" % [mode,size.x,size.y])
	root.size=size
	await frames(3)
	stage("live" if mode=="gameplay" else mode)
	if mode=="gameplay": gameplay_view()
	fixture_label.position=Vector2(18,size.y-100)
	fixture_label.size=Vector2(size.x-36,88)
	fixture_label.text="1792 / GROUND FOCUS  ·  "+mode.to_upper()+"\nSynthetic native Home fixture · inspection camera · no historical claim\nThe retained campaign clock is frozen during this capture."
	if mode=="gameplay":
		fixture_label.text="1792 / FOCUS PRESENTATION FIXTURE\nPlayer camera · inherited caption/framing · verbose help suppressed\nSynthetic staged observation · retained campaign clock frozen"
		fixture_label.position=Vector2(18,size.y-160)
	var retained: Dictionary=scene.model.snapshot()
	var journal: Array=scene.model.journal()
	await frames(4)
	scene.ground_focus.sample(int(scene.model.progress().tick))
	await frames(2)
	if mode=="gameplay":
		check(not scene._hud.is_visible_in_tree() and scene._caption.is_visible_in_tree() and (not scene._subjective or scene._veil.is_visible_in_tree()), "gameplay fixture displays inherited captions/framing and suppresses verbose help during Focus")
	check(scene.model.snapshot()==retained and scene.model.journal()==journal, "rendering preserves native world and journal: "+mode)
	var image:=root.get_texture().get_image()
	var filename:="ground-focus-%s-%dx%d.png" % [mode,size.x,size.y]
	var path:=output.path_join(filename)
	check(image!=null and not image.is_empty() and image.save_png(path)==OK, "native image saved: "+filename)
	print("GROUND_FOCUS_CAPTURE: "+filename)
	check(Rect2(Vector2.ZERO,Vector2(size)).encloses(fixture_label.get_global_rect()), "fixture annotation fits "+filename)
	if scene.ground_focus.active:
		check(Rect2(Vector2.ZERO,Vector2(size)).encloses(scene.ground_focus.heading.get_global_rect()), "Focus heading fits "+filename)
	captures.append({"file":filename,"mode":mode,"viewport":[size.x,size.y],"tick":scene.model.progress().tick,
		"observations":scene.ground_focus.observations(),"predictions":scene.ground_focus.predictions(),
		"image_sha256":FileAccess.get_sha256(path),"state_sha256":JSON.stringify(retained,"",true,true).sha256_text(),
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),
		"camera":"original player camera, inherited caption/framing, verbose help suppressed" if mode=="gameplay" else "explicit inspection fixture in native Home","historical_authentication":false,"world_unchanged_during_capture":scene.model.snapshot()==retained})

func run() -> void:
	var provided:=OS.get_environment("GROUND_FOCUS_OUTPUT")
	if not provided.is_empty(): output=provided
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	home=Launch.make_world()
	scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-render-slot.json")
	scene.set_physics_process(false)
	scene.set_process_unhandled_input(false)
	root.add_child(home); await frames(8)
	for node in home.find_children("*","Node",true,false):
		node.set_physics_process(false); node.set_process(false); node.set_process_unhandled_input(false)
	var arm: SpringArm3D=scene.avatar.get_node("CameraPivot/SpringArm3D")
	arm.set_physics_process_internal(false)
	baseline=scene.model.snapshot()
	baseline.player.position=[-16.0,0.14,2.0]
	baseline.actors[scene.Names.HERO_ID].position=[-16.0,0.14,2.0]
	check(scene.model.restore(baseline).is_empty(), "render fixture pose validates against the retained state schema")
	scene._apply()
	check(scene._candidate_error(scene.model).is_empty(), "render fixture pose fits native Home standing geometry")
	baseline=scene.model.snapshot()
	contact=scene.scout_contacts.contacts[0]
	camera=Camera3D.new(); camera.fov=58; camera.far=350; home.add_child(camera)
	var evidence:=CanvasLayer.new(); evidence.layer=30; root.add_child(evidence)
	fixture_label=Label.new()
	fixture_label.add_theme_font_size_override("font_size",16)
	fixture_label.add_theme_color_override("font_color",Color("eee2c4"))
	fixture_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	fixture_label.add_theme_constant_override("shadow_offset_x",2)
	fixture_label.add_theme_constant_override("shadow_offset_y",2)
	fixture_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	evidence.add_child(fixture_label)
	for size in [Vector2i(1280,720),Vector2i(800,450)]:
		for mode in ["default","live","lastseen","estimated","gameplay"]: await capture(mode,size)
	check(not FileAccess.file_exists(scene.save_path), "render fixtures never create a native player save")
	var manifest:=FileAccess.open(output.path_join("ground-focus-captures.json"),FileAccess.WRITE)
	if manifest!=null:
		manifest.store_string(JSON.stringify({"schema":"1792.ground-focus-native-captures.v1","failed":failed,"captures":captures,"fixture_classification":"synthetic staged observation fixtures in native Home","hardware_performance_qualified":false},"\t",true,true)); manifest.close()
	home.queue_free(); evidence.queue_free(); await frames(2)
	print("GROUND_FOCUS_RENDER: %d captures, %d failures" % [captures.size(),failed])
	quit(1 if failed else 0)
