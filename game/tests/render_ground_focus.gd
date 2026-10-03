# Copyright (c) 2026 Notation Systems Inc. / Notations Gaming.
# All rights reserved.
extends SceneTree
## Synthetic sensory and commission fixtures, drawn by Godot in the real Home scene.
## Fixture preparation uses the retained model tick; captures never advance or save the world.
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://perception/focus_rules.gd")
const CampaignState := preload("res://mounts/riding_skill_state.gd")
const InquiryFixture := preload("res://tests/gujranwala_fixture.gd")
const PoseFixture := preload("res://tests/aftermath_fixture.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
var output := "user://ground-focus-images"
var captures: Array=[]
var failed := 0
var home: Node3D
var scene: Node3D
var camera: Camera3D
var contact: Node3D
var fixture_label: Label
var baseline: Dictionary
var compact_baseline: Dictionary
var sound: AudioStreamPlayer3D

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value:
		failed+=1
		push_error("GROUND FOCUS RENDER FAIL: "+label)

func frames(count: int=3) -> void:
	for _i in range(count): await process_frame
	await RenderingServer.frame_post_draw

func looping_sound() -> AudioStreamWAV:
	var data:=PackedByteArray();data.resize(2205*2)
	for i in range(2205):data.encode_s16(i*2,int(sin(TAU*440.0*i/22050.0)*2200))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=data
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=2205
	return stream

func prepare(use_compact: bool) -> void:
	check(scene.model.restore(compact_baseline if use_compact else baseline).is_empty(),"restore validated native render fixture")
	scene._apply()
	scene.set_physics_process(false);scene.avatar.set_physics_process(false)
	scene.avatar.input_enabled=false;scene.avatar.pivot.rotation=Vector3.ZERO
	scene.ground_focus._targets.clear();scene.ground_focus._sounds.clear()
	sound.stop()
	contact.show()
	contact.global_position=Vector3(-19,0.14,7) if use_compact else Vector3(-13,0.14,-3)
	scene.ground_focus.register_target("native_home_fixture",contact,"Unknown contact","contact",Vector3.UP*1.15)
	camera.global_position=Vector3(-10,4.3,-2) if use_compact else Vector3(-10,4.3,6)
	camera.look_at(Vector3(-14.5,1.2,7) if use_compact else Vector3(-14.5,1.2,-3))
	camera.current=true
	for layer in home.find_children("*","CanvasLayer",true,false):layer.hide()
	scene._marker.hide();fixture_label.get_parent().show()
	if use_compact:
		scene.avatar.pivot.rotation=Vector3(-0.1,PI,0)
		scene.art.detail.hud.compact=true
		# Declared transient speech exercises the current caption owner; it does
		# not invent a campaign receipt or claim an earned new-game journey.
		scene._message="Declared Focus fixture: the yard is quiet."
		scene.story_attention.reset(int(scene.model.progress().tick))
		scene.story_attention.offer(scene._message,int(scene.model.progress().tick))
		scene._refresh();scene.art.detail.hud.sample()
		sound.global_position=scene.avatar.global_position+Vector3(0,1.35,2)
		scene.ground_focus.register_sound("synthetic_sound_fixture",sound,"Metal striking")

func advance_sensor() -> void:
	scene.model.advance()
	scene.ground_focus.sample(int(scene.model.progress().tick))

func stage(mode: String,use_compact: bool) -> void:
	print("GROUND_FOCUS_STAGE: "+mode)
	prepare(use_compact)
	if mode=="default":return
	if use_compact:
		sound.play();await frames(3)
		check(sound.playing,"declared prototype audio is actually playing")
	scene.ground_focus.start()
	if mode=="acquiring":
		for _i in range(20):advance_sensor()
		check(scene.ground_focus.acquisitions().size()==1 and scene.ground_focus.observations().is_empty(),"current anonymous evidence remains incomplete in acquiring fixture")
		return
	for _i in range(Rules.DWELL_TICKS):advance_sensor()
	check(scene.ground_focus.observations().size()==1,"real Home sensor acquires "+mode+" fixture")
	if mode=="lastseen":
		contact.hide()
		for _i in range(90):advance_sensor()
	elif mode=="estimated":
		for _i in range(Rules.MOTION_INTERVAL):
			contact.position.x+=0.016;advance_sensor()
		check(scene.ground_focus.predictions().has("native_home_fixture"),"observed native displacement creates the estimated fixture")
		contact.hide();advance_sensor()
	scene.ground_focus.sample(int(scene.model.progress().tick))
	if not use_compact:check(not scene.ground_focus.overlay.marks.is_empty(),"fixture observation appears in the native camera: "+mode)

func gameplay_view() -> void:
	print("GROUND_FOCUS_GAMEPLAY: begin")
	camera.current=false
	var player_camera: Camera3D=scene.avatar.get_node("CameraPivot/SpringArm3D/Camera3D")
	player_camera.current=true
	var arm: SpringArm3D=player_camera.get_parent();arm.set_physics_process_internal(true)
	scene._refresh();scene.art.detail.hud.sample()
	scene._veil.visible=scene._subjective
	for visual in [scene.art.detail.hud.top,scene.art.detail.hud.bottom,scene._veil]:
		var ancestor: Node=visual.get_parent()
		while ancestor!=null and ancestor!=scene:
			if ancestor is CanvasLayer:ancestor.show()
			ancestor=ancestor.get_parent()
	scene.ground_focus.sample(int(scene.model.progress().tick))
	print("GROUND_FOCUS_GAMEPLAY: ready")

func capture(mode: String,size: Vector2i) -> void:
	print("GROUND_FOCUS_BEGIN: %s %dx%d" % [mode,size.x,size.y])
	root.size=size;await frames(3)
	var use_compact:=mode in ["gameplay","compact-ready","compact-acquiring"]
	var sensor_mode:="acquiring" if mode=="compact-acquiring" else ("live" if use_compact else mode)
	await stage(sensor_mode,use_compact)
	if mode=="compact-ready":
		# This retained capture also qualifies the current silent interval:
		# the empty speech card disappears while task and controls remain.
		scene._message=""
		scene.story_attention.reset(int(scene.model.progress().tick))
	if use_compact:gameplay_view()
	fixture_label.add_theme_font_size_override("font_size",16)
	fixture_label.position=Vector2(18,size.y-100);fixture_label.size=Vector2(size.x-36,88)
	fixture_label.text="1792 / GROUND FOCUS  ·  "+mode.to_upper()+"\nSynthetic native Home fixture · inspection camera · no historical claim\nThe retained campaign clock is frozen during this capture."
	if use_compact:
		fixture_label.add_theme_font_size_override("font_size",10)
		fixture_label.text="Synthetic native Home fixture / %s / prototype sound / frozen authority" % mode
		fixture_label.position=Vector2(18,size.y-16);fixture_label.size=Vector2(size.x-36,14)
	var retained: Dictionary=scene.model.snapshot()
	var journal: Array=scene.model.journal()
	await frames(4);scene.ground_focus.sample(int(scene.model.progress().tick));await frames(2)
	if use_compact:
		var hud=scene.art.detail.hud
		check(hud.visible and hud.top.is_visible_in_tree() and hud.control_strip.is_visible_in_tree(),"gameplay fixture displays the actual compact task and available controls")
		check(hud.bottom.is_visible_in_tree()==(not scene.story_caption().is_empty()),"directed speech card follows the actual spoken or silent interval")
		check(hud.task.text==scene.workshop_hint().replace(" [E]","") and hud.words.text==scene.story_caption(),"real compact fixture retains the existing task and directed words")
		check(scene.story_caption().is_empty() if mode=="compact-ready" else scene.story_caption()==scene._message,"declared silent and spoken caption fixtures use the current presentation owner")
		check(hud.controls.text.contains("E  Speak") and hud.controls.text.contains("B  Accounts") and hud.controls.text.contains("J  Journal") and hud.controls.text.contains("Z  Return") and not hud.controls.text.contains("Z  Focus") and hud.controls.text.contains("X  Hawk"),"real compact controls state the current return action once while preserving interaction, accounts, journal and hawk hints")
		check(not scene._hud.is_visible_in_tree() and not scene._caption.is_visible_in_tree() and not scene._narrator_label.is_visible_in_tree() and (not scene._subjective or scene._veil.is_visible_in_tree()),"gameplay compact captions and subjective framing replace duplicate legacy text during Focus")
		check(scene._marker.visible and scene._marker.text=="Smith · E" and scene._marker.position.is_equal_approx(Craft.SITE+Vector3.UP*2.1),"real compact destination pointer remains the smith without leaking remote readiness")
		var viewport:=Rect2(Vector2.ZERO,Vector2(size))
		var top: Rect2=hud.top.get_global_rect();var bottom: Rect2=hud.bottom.get_global_rect()
		var controls: Rect2=hud.control_strip.get_global_rect()
		var heading: Rect2=scene.ground_focus.heading.get_global_rect()
		check(viewport.encloses(top) and viewport.encloses(bottom) and not top.intersects(bottom),"real compact cards fit without intersecting each other")
		check(viewport.encloses(controls) and not controls.intersects(top) and not controls.intersects(bottom),"actual control strip fits separately from task and speech")
		check(not heading.intersects(top) and (not hud.bottom.is_visible_in_tree() or not heading.intersects(bottom)) and not heading.intersects(controls),"Focus heading preserves real compact task, speech and controls")
		var controls_protected:=false
		for rect in scene.ground_focus.overlay.exclusion_rects:
			if rect.encloses(controls):controls_protected=true
		check(controls_protected,"the actual visible control strip is protected from projected markers and labels")
		check(sound.playing and scene.ground_focus.sound_cues().size()==1 and scene.ground_focus.heading.text.contains("heard ahead") and scene.ground_focus.heading.text.contains("0s ago"),"actual declared prototype audio produces a coarse, dated hearing line")
		check(not scene.ground_focus.overlay.marks.is_empty(),"real player camera retains the staged Focus marker between compact cards")
		var safe:=true
		for mark in scene.ground_focus.overlay.marks:
			for rect in scene.ground_focus.overlay.exclusion_rects:
				if rect.has_point(mark.at):safe=false
		check(safe,"native projected marker centers respect task, speech, controls and Focus heading")
	if sensor_mode=="acquiring":
		var rings: Array=scene.ground_focus.overlay.marks.filter(func(mark):return mark.has("progress"))
		check(rings.size()==1 and rings[0].text=="Observing" and is_equal_approx(float(rings[0].progress),20.0/45.0),"native acquiring screenshot contains the neutral pending ring")
		var focus_heading: String=scene.ground_focus.heading.text
		check(focus_heading.begins_with("FOCUS\nKeep subject visible until the ring fills.") and focus_heading.count("Keep subject visible until the ring fills.")==1 and not focus_heading.contains("E  Observe") and not focus_heading.contains("Z  Return"),"acquiring screenshot keeps one contextual ring instruction, composes with hearing evidence and has no duplicate key list")
	check(scene.model.snapshot()==retained and scene.model.journal()==journal,"rendering preserves native world and journal: "+mode)
	var image:=root.get_texture().get_image()
	var filename:="ground-focus-%s-%dx%d.png" % [mode,size.x,size.y]
	var path:=output.path_join(filename)
	check(image!=null and not image.is_empty() and image.save_png(path)==OK,"native image saved: "+filename)
	print("GROUND_FOCUS_CAPTURE: "+filename)
	check(Rect2(Vector2.ZERO,Vector2(size)).encloses(fixture_label.get_global_rect()),"fixture annotation fits "+filename)
	if scene.ground_focus.active:
		check(Rect2(Vector2.ZERO,Vector2(size)).encloses(scene.ground_focus.heading.get_global_rect()),"Focus heading fits "+filename)
		var heading_protected:=false
		for rect in scene.ground_focus.overlay.exclusion_rects:
			if rect.encloses(scene.ground_focus.heading.get_global_rect()):heading_protected=true
		check(heading_protected,"the full laid-out Focus heading is protected from marker and label overlap")
	var compact_data: Dictionary={}
	if use_compact:
		var hud=scene.art.detail.hud
		compact_data={"task":hud.task.text,"words":hud.words.text,"controls":hud.controls.text,"destination_marker":scene._marker.text,
			"caption_visible":hud.bottom.is_visible_in_tree(),"top_rect":var_to_str(hud.top.get_global_rect()),"bottom_rect":var_to_str(hud.bottom.get_global_rect()),
			"control_rect":var_to_str(hud.control_strip.get_global_rect()),"heading_rect":var_to_str(scene.ground_focus.heading.get_global_rect())}
	captures.append({"file":filename,"mode":mode,"viewport":[size.x,size.y],"tick":scene.model.progress().tick,
		"observations":scene.ground_focus.observations(),"acquisitions":scene.ground_focus.acquisitions(),"predictions":scene.ground_focus.predictions(),"sound_cues":scene.ground_focus.sound_cues(),"compact_hud":compact_data,
		"image_sha256":FileAccess.get_sha256(path),"state_sha256":JSON.stringify(retained,"",true,true).sha256_text(),
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"source_content_sha256":OS.get_environment("SOURCE_CONTENT_SHA256"),
		"camera":"original player camera, actual compact task/words/controls and subjective framing" if use_compact else "explicit inspection fixture in native Home","historical_authentication":false,"player_journey_evidence":false,"world_unchanged_during_capture":scene.model.snapshot()==retained})

func run() -> void:
	var provided:=OS.get_environment("GROUND_FOCUS_OUTPUT")
	if not provided.is_empty():output=provided
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-render-slot.json")
	scene.set_physics_process(false);scene.set_process_unhandled_input(false)
	root.add_child(home);await frames(8)
	for node in home.find_children("*","Node",true,false):
		node.set_physics_process(false);node.set_process(false);node.set_process_unhandled_input(false)
	var arm: SpringArm3D=scene.avatar.get_node("CameraPivot/SpringArm3D");arm.set_physics_process_internal(false)
	baseline=scene.model.snapshot();baseline.player.position=[-16.0,0.14,2.0];baseline.actors[scene.Names.HERO_ID].position=[-16.0,0.14,2.0]
	check(scene.model.restore(baseline).is_empty(),"render fixture pose validates against the retained state schema")
	scene._apply();check(scene._candidate_error(scene.model).is_empty(),"render fixture pose fits native Home standing geometry")
	baseline=scene.model.snapshot()
	var declared:=CampaignState.new()
	check(declared.restore(InquiryFixture.complete()).is_empty(),"declared completed-inquiry fixture validates")
	check(declared.begin_allowance().is_empty() and declared.workshop_action("reserve").is_empty(),"declared compact fixture reserves the original commission")
	check(PoseFixture.pose(declared,Craft.SITE+Vector3(0,0,-2)).is_empty() and declared.workshop_action("start").is_empty(),"declared compact fixture transfers native smith custody")
	for _i in range(Craft.WORK_TICKS):declared.advance()
	check(declared.workshop_phase()=="ready" and PoseFixture.pose(declared,Vector3(-16,0.14,2)).is_empty(),"native ready deadline and original clear-yard pose prepare the compact fixture")
	compact_baseline=declared.snapshot()
	contact=scene.scout_contacts.contacts[0]
	sound=AudioStreamPlayer3D.new();sound.max_distance=12;sound.volume_db=-12;sound.stream=looping_sound();scene.add_child(sound)
	camera=Camera3D.new();camera.fov=58;camera.far=350;home.add_child(camera)
	var evidence:=CanvasLayer.new();evidence.layer=30;root.add_child(evidence)
	fixture_label=Label.new();fixture_label.add_theme_font_size_override("font_size",16)
	fixture_label.add_theme_color_override("font_color",Color("eee2c4"));fixture_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	fixture_label.add_theme_constant_override("shadow_offset_x",2);fixture_label.add_theme_constant_override("shadow_offset_y",2)
	fixture_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;evidence.add_child(fixture_label)
	for size in [Vector2i(1280,720),Vector2i(800,450)]:
		for mode in ["default","live","lastseen","estimated","acquiring","gameplay"]:await capture(mode,size)
	for mode in ["compact-ready","compact-acquiring"]:await capture(mode,Vector2i(640,360))
	check(not FileAccess.file_exists(scene.save_path),"render fixtures never create a native player save")
	var manifest:=FileAccess.open(output.path_join("ground-focus-captures.json"),FileAccess.WRITE)
	if manifest!=null:
		manifest.store_string(JSON.stringify({"schema":"1792.ground-focus-native-captures.v2","failed":failed,"captures":captures,"fixture_classification":"synthetic staged sensory and reducer-built commission fixtures in native Home, including declared prototype audio; not played journey evidence","hardware_performance_qualified":false},"\t",true,true));manifest.close()
	home.queue_free();evidence.queue_free();await frames(2)
	print("GROUND_FOCUS_RENDER: %d captures, %d failures" % [captures.size(),failed]);quit(1 if failed else 0)
