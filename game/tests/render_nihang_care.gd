# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Render a retained input-driven care state in original Home, then click its real UI.
## This is executed-state rendering; it does not claim a fresh journey or force poses.
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://warband/nihang_rules.gd")
var output := ""
var home: Node3D
var scene: Node3D
var evidence: CanvasLayer
var annotation: Label
var frozen: Dictionary
var captures: Array[Dictionary]=[]
var guidance_captures: Array[Dictionary]=[]
var final_care_choice_pressed:=false
var failures:=0
var source_sha256:=""

func _initialize() -> void: run.call_deferred()

func check(value: bool,label: String) -> void:
	if not value:
		failures+=1
		push_error("NIHANG CARE RENDER: "+label)

func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw

func rect_value(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func click_choice(prefix: String) -> void:
	for button in scene._actions.get_children():
		if not button is Button or not button.text.begins_with(prefix): continue
		var point: Vector2=button.get_global_rect().get_center()
		var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
		root.push_input(motion)
		for pressed in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
			event.position=point;event.global_position=point;event.pressed=pressed
			root.push_input(event)
		await frames()
		return
	check(false,"displayed UI choice missing: "+prefix)

func capture(index: int,id: String) -> void:
	await frames()
	check(scene._paused and scene._care_page==index,"real dialogue reaches page "+id)
	check(scene.model.snapshot()==frozen,"paused Home snapshot remains equal on page "+id)
	var viewport:=Rect2(Vector2.ZERO,Vector2(1280,720))
	var panel: Rect2=scene._panel.get_global_rect()
	var text: Rect2=scene._panel_text.get_global_rect()
	var scroll: Rect2=scene._journal_scroll.get_global_rect()
	check(scene._panel.is_visible_in_tree() and viewport.encloses(panel),"dialogue panel fits viewport on page "+id)
	check(scene._panel_text.is_visible_in_tree() and viewport.encloses(text) and scroll.encloses(text),"all dialogue text fits its visible scroll viewport on page "+id)
	var button_bounds: Array=[]
	for button in scene._actions.get_children():
		if not button is Button: continue
		var bounds: Rect2=button.get_global_rect()
		check(button.is_visible_in_tree() and viewport.encloses(bounds) and scroll.encloses(bounds),"visible button fits without scrolling: "+button.text)
		button_bounds.append({"text":button.text,"rect":rect_value(bounds)})
	check(button_bounds.size()==2,"page exposes one progression and one leave choice: "+id)
	check(viewport.encloses(annotation.get_global_rect()),"executed-state annotation fits "+id)
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.get_width()==1280 and image.get_height()==720,"native frame is 1280x720: "+id)
	var filename:="care-"+id+".png"
	var path:=output.path_join(filename)
	check(image.save_png(path)==OK,"native screenshot retained: "+id)
	captures.append({"file":filename,"page":index,"panel_text":scene._panel_text.text,
		"panel_rect":rect_value(panel),"label_rect":rect_value(text),"scroll_rect":rect_value(scroll),"buttons":button_bounds,
		"viewport":[1280,720],"image_sha256":FileAccess.get_sha256(path),
		"paused_snapshot_unchanged":scene.model.snapshot()==frozen,
		"snapshot_sha256":JSON.stringify(frozen,"",true,true).sha256_text(),
		"camera":"original player camera facing the nearby veteran; no body pose changes"})
	print("NIHANG_CARE_CAPTURE: "+filename)

func capture_guidance(id: String,task: String,target: Vector3) -> void:
	annotation.position=Vector2(16,190)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven Home journey\nOriginal HUD · optional horse care yields to household riding"
	await frames()
	var before: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
	var hud: Node=scene.art.detail.hud;hud.sample()
	check(not scene._paused and hud.visible and hud.task.text==task,"native compact guidance shows "+id)
	check(scene._marker.visible and scene._marker.position.is_equal_approx(target+Vector3.UP*2.1),"native destination marker matches "+id)
	check(scene.model.snapshot()==before and scene.model.journal()==journal,"guidance sampling changes no state or testimony: "+id)
	var viewport:=Rect2(Vector2.ZERO,Vector2(1280,720))
	var bounds: Array=[]
	var caption: String=scene.story_caption()
	check(hud.words.text==caption and hud.bottom.is_visible_in_tree()==(not caption.is_empty()),"directed speech card follows the current spoken or silent interval: "+id)
	var visible_controls: Array=[hud.top,hud.title,hud.task,hud.narrator,hud.control_strip,hud.controls,annotation]
	if not caption.is_empty(): visible_controls.append_array([hud.bottom,hud.words])
	for control in visible_controls:
		check(control.is_visible_in_tree() and viewport.encloses(control.get_global_rect()),"visible guidance fits: "+id+" / "+control.name)
		bounds.append(rect_value(control.get_global_rect()))
	check(not hud.top.get_global_rect().intersects(hud.control_strip.get_global_rect()),"actual control strip remains separate from the task card: "+id)
	if not caption.is_empty():
		check(not hud.bottom.get_global_rect().intersects(hud.control_strip.get_global_rect()),"directed speech remains separate from the actual control strip: "+id)
	var image:=root.get_texture().get_image()
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"native guidance frame dimensions: "+id)
	var filename:="guidance-"+id+".png";var path:=output.path_join(filename)
	check(image.save_png(path)==OK,"native guidance screenshot retained: "+id)
	guidance_captures.append({"file":filename,"image_sha256":FileAccess.get_sha256(path),"task":task,
		"phase":scene.model.nihang_camp().phase,"marker":scene._marker.text,"bounds":bounds,
		"caption":caption,"caption_visible":hud.bottom.is_visible_in_tree(),"control_rect":rect_value(hud.control_strip.get_global_rect()),
		"sampled_snapshot_sha256":JSON.stringify(before,"",true,true).sha256_text(),
		"sampling_preserves_state":scene.model.snapshot()==before,"classification":"read-only HUD sampling during an executing Home"})
	print("NIHANG_GUIDANCE_CAPTURE: "+filename)

func finish() -> void:
	var manifest:={"schema":"1792.nihang-care-native-render.v1","classification":"executed-state rendering from retained input-driven Home journey",
		"source_file":"before-care.json","source_sha256":source_sha256,"captures":captures,"guidance_captures":guidance_captures,"failures":failures,
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),"human_playtest":false,"fresh_journey":false,
		"final_care_choice_pressed":final_care_choice_pressed}
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("care-render.json"),FileAccess.WRITE)
		check(file!=null,"render manifest retained")
		if file:
			manifest.failures=failures
			file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	if is_instance_valid(home): home.queue_free()
	if is_instance_valid(evidence): evidence.queue_free()
	await process_frame
	print("NIHANG_CARE_RENDER: %d captures; %d failures"%[captures.size(),failures])
	print("NIHANG_GUIDANCE_RENDER: %d captures; %d failures"%[guidance_captures.size(),failures])
	quit(1 if failures else 0)

func run() -> void:
	output=OS.get_environment("NIHANG_CAPTURE_OUTPUT")
	check(DisplayServer.get_name()!="headless","native graphics display is available; headless runs cannot qualify rendering")
	if DisplayServer.get_name()=="headless": await finish();return
	check(not output.is_empty(),"NIHANG_CAPTURE_OUTPUT identifies the retained journey state and output directory")
	if output.is_empty(): await finish();return
	var source:=output.path_join("before-care.json")
	check(FileAccess.file_exists(source),"retained input-driven before-care state exists")
	if not FileAccess.file_exists(source): await finish();return
	source_sha256=FileAccess.get_sha256(source)
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	check(value is Dictionary,"retained state parses as a whole Home snapshot")
	if not value is Dictionary: await finish();return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-care-render-slot.json")
	var error: String=scene.model.restore(value)
	check(error.is_empty(),"retained executed state validates: "+error)
	if not error.is_empty(): await finish();return
	root.add_child(home);await frames(5)
	check(scene._candidate_error(scene.model).is_empty(),"retained state fits original Home geometry")
	var offset: Vector3=Rules.HORSE_LINES[0]-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-offset.x,-offset.z)
	evidence=CanvasLayer.new();evidence.layer=30;root.add_child(evidence)
	annotation=Label.new();annotation.position=Vector2(16,16);annotation.size=Vector2(1000,48)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven Home journey\nOriginal player camera facing the veteran · Home pauses during the three care pages"
	annotation.add_theme_font_size_override("font_size",16)
	annotation.add_theme_color_override("font_color",Color("eee2c4"))
	annotation.add_theme_color_override("font_shadow_color",Color.BLACK)
	annotation.add_theme_constant_override("shadow_offset_x",2);annotation.add_theme_constant_override("shadow_offset_y",2)
	annotation.mouse_filter=Control.MOUSE_FILTER_IGNORE;evidence.add_child(annotation)
	await capture_guidance("horse-lines","Listen beside the horse lines",Rules.HORSE_LINES[0])
	annotation.position=Vector2(16,16)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven Home journey\nOriginal player camera facing the veteran · Home pauses during the three care pages"
	# Camera facing is presentation setup; the actual local E path admits the conversation.
	var event:=InputEventKey.new();event.keycode=KEY_E;event.pressed=true
	scene._unhandled_input(event);await frames()
	check(scene._paused and scene._care_page==0,"local E opens the first horse-care page")
	if not scene._paused or scene._care_page!=0: await finish();return
	frozen=scene.model.snapshot()
	await capture(0,"bridle")
	await click_choice("Inspect the tack");await capture(1,"footing")
	await click_choice("Look at the footing");await capture(2,"return")
	check(scene.model.nihang_camp().phase=="acquainted" and scene.model.snapshot()==frozen,"partial conversation grants no final care receipt")
	await click_choice("I will bring the horse home")
	final_care_choice_pressed=scene.model.nihang_camp().phase=="prepared"
	check(final_care_choice_pressed and scene.model.nihang_camp().events.size()==frozen.nihang_camp.events.size()+1,"final actual mouse choice records care exactly once")
	check(scene.camp_guidance().is_empty(),"accepted care relinquishes optional guidance")
	await capture_guidance("household-riding","Mount the household horse",Rules.Ride.position(scene.model.horse_record()))
	check(guidance_captures.size()==2,"both native guidance handoffs captured")
	check(not FileAccess.file_exists(scene.save_path),"rendering creates no player save")
	await finish()
