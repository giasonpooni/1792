# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Render a retained input-driven care state in original Home, then click its real UI.
## This is executed-state rendering; it does not claim a fresh journey or force poses.
const Launch := preload("res://childhood/home_launch.gd")
const Rules := preload("res://warband/nihang_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
var output := ""
var home: Node3D
var scene: Node3D
var evidence: CanvasLayer
var annotation: Label
var frozen: Dictionary
var captures: Array[Dictionary]=[]
var guidance_captures: Array[Dictionary]=[]
var obligation_captures: Array[Dictionary]=[]
var handoff_captures: Array[Dictionary]=[]
var followup_captures: Array[Dictionary]=[]
var final_care_choice_pressed:=false
var failures:=0
var source_sha256:=""
var completed_source_sha256:=""
var second_source_sha256:=""
var handoff_source_sha256:=""

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

func capture_followup(id: String,expected_text: String,button_count: int) -> void:
	await frames()
	check(scene._paused and scene._panel_text.text.contains(expected_text),"farther-road dialogue shows "+id)
	var before: Dictionary=scene.model.snapshot()
	var viewport:=Rect2(Vector2.ZERO,Vector2(1280,720))
	var panel: Rect2=scene._panel.get_global_rect()
	var text: Rect2=scene._panel_text.get_global_rect()
	var scroll: Rect2=scene._journal_scroll.get_global_rect()
	check(scene._panel.is_visible_in_tree() and viewport.encloses(panel),"farther-road panel fits viewport: "+id)
	check(scene._panel_text.is_visible_in_tree() and viewport.encloses(text) and scroll.encloses(text),"farther-road text fits its scroll viewport: "+id)
	var buttons: Array=[]
	for button in scene._actions.get_children():
		if not button is Button: continue
		var bounds: Rect2=button.get_global_rect()
		check(button.is_visible_in_tree() and viewport.encloses(bounds) and scroll.encloses(bounds),"farther-road button fits without scrolling: "+button.text)
		buttons.append({"text":button.text,"rect":rect_value(bounds)})
	check(buttons.size()==button_count,"farther-road page has bounded choices: "+id)
	var image:=root.get_texture().get_image();var filename:="followup-"+id+".png";var path:=output.path_join(filename)
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"farther-road native frame dimensions: "+id)
	check(image.save_png(path)==OK,"farther-road native screenshot retained: "+id)
	followup_captures.append({"file":filename,"image_sha256":FileAccess.get_sha256(path),"panel_text":scene._panel_text.text,
		"panel_rect":rect_value(panel),"label_rect":rect_value(text),"scroll_rect":rect_value(scroll),"buttons":buttons,
		"snapshot_sha256":JSON.stringify(before,"",true,true).sha256_text(),"sampling_preserves_state":scene.model.snapshot()==before,
		"classification":"executed-state follow-up in the original Home dialogue"})
	print("NIHANG_FOLLOWUP_CAPTURE: "+filename)

func render_obligation(id: String,source_file: String) -> void:
	var source:=output.path_join(source_file)
	check(FileAccess.file_exists(source),"retained active undertaking exists: "+id)
	if not FileAccess.file_exists(source): return
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	check(value is Dictionary,"retained active undertaking parses: "+id)
	if not value is Dictionary: return
	if is_instance_valid(home): home.queue_free()
	await process_frame
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-obligation-"+id+"-slot.json")
	var error: String=scene.model.restore(value)
	check(error.is_empty(),"retained active undertaking validates: "+id+" / "+error)
	if not error.is_empty(): return
	root.add_child(home);await frames(5)
	check(scene._candidate_error(scene.model).is_empty(),"retained active undertaking fits Home: "+id)
	var obligation: Dictionary=Rules.obligation(scene.model.nihang_camp())
	check(not obligation.is_empty(),"retained state has an active derived undertaking: "+id)
	if obligation.is_empty(): return
	annotation.position=Vector2(16,16)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven camp ride\nOriginal journal · active jatha term is derived from received testimony"
	var before: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
	scene._open_journal();await frames()
	var viewport:=Rect2(Vector2.ZERO,Vector2(1280,720))
	var panel: Rect2=scene._panel.get_global_rect();var scroll: Rect2=scene._journal_scroll.get_global_rect()
	var text_rect: Rect2=scene._panel_text.get_global_rect()
	check(scene._paused and scene._panel_text.text.contains("ACTIVE JATHA UNDERTAKING · DERIVED FROM RECEIVED TERMS"),"ordinary journal shows active undertaking: "+id)
	check(scene._panel_text.text.contains(obligation.title) and scene._panel_text.text.contains(obligation.text),"journal shows the exact derived obligation: "+id)
	check(scene._journal_scroll.scroll_vertical==0 and text_rect.position.y>=scroll.position.y-1 and text_rect.position.y<scroll.end.y,"active undertaking begins in the first visible journal field: "+id)
	check(viewport.encloses(panel) and viewport.encloses(scroll) and viewport.encloses(annotation.get_global_rect()),"journal presentation fits the native viewport: "+id)
	check(scene.model.snapshot()==before and scene.model.journal()==journal,"rendered obligation changes no state or testimony: "+id)
	var image:=root.get_texture().get_image();var filename:="obligation-"+id+".png";var path:=output.path_join(filename)
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"native obligation frame dimensions: "+id)
	check(image.save_png(path)==OK,"native obligation screenshot retained: "+id)
	obligation_captures.append({"file":filename,"image_sha256":FileAccess.get_sha256(path),
		"source_file":source_file,"source_sha256":FileAccess.get_sha256(source),"phase":scene.model.nihang_camp().phase,
		"title":obligation.title,"text":obligation.text,"address":scene.model.nihang_address(obligation.source_id),
		"panel_rect":rect_value(panel),"scroll_rect":rect_value(scroll),"scroll_position":scene._journal_scroll.scroll_vertical,
		"snapshot_sha256":JSON.stringify(before,"",true,true).sha256_text(),"sampling_preserves_state":scene.model.snapshot()==before,
		"classification":"read-only active undertaking derived from received camp terms"})
	check(not FileAccess.file_exists(scene.save_path),"obligation rendering creates no player save: "+id)
	print("NIHANG_OBLIGATION_CAPTURE: "+filename)

func render_obligations() -> void:
	await render_obligation("first-return","active-outing.json")
	await render_obligation("farther-outbound","active-second-outing.json")

func render_handoff() -> void:
	var source:=output.path_join("jatha-handoff.json")
	check(FileAccess.file_exists(source),"retained input-driven jatha handoff exists")
	if not FileAccess.file_exists(source): return
	handoff_source_sha256=FileAccess.get_sha256(source)
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	check(value is Dictionary,"retained jatha handoff parses as a whole Home snapshot")
	if not value is Dictionary: return
	if is_instance_valid(home): home.queue_free()
	await process_frame
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-handoff-render-slot.json")
	var error: String=scene.model.restore(value)
	check(error.is_empty(),"retained jatha handoff validates: "+error)
	if not error.is_empty(): return
	root.add_child(home);await frames(5)
	check(scene._candidate_error(scene.model).is_empty(),"retained jatha handoff fits original Home geometry")
	check(scene.model.message_phase()=="report" and Rules.handoff_echo(scene.model.nihang_camp())==Rules.FIRST_HANDOFF_ECHO,"retained first return awaits the existing trainer report")
	var target: Vector3=Base.SITES.spar;var offset: Vector3=target-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-offset.x,-offset.z)
	annotation.position=Vector2(16,16)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven first outing\nExisting childhood report · received jatha conduct changes dialogue, not progression"
	var before_message: Dictionary=scene.model.message_followup();var before_events: Array=scene.model.nihang_camp().events.duplicate(true)
	var event:=InputEventKey.new();event.keycode=KEY_E;event.pressed=true
	scene._unhandled_input(event);await frames()
	check(scene._paused and scene._panel_text.text.begins_with("THE WORDS BETWEEN US"),"native E opens the existing childhood report")
	check(scene._panel_text.text.contains(Rules.FIRST_HANDOFF_ECHO.account),"report includes the exact witnessed jatha echo")
	var opened: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal();await frames()
	var viewport:=Rect2(Vector2.ZERO,Vector2(1280,720));var panel: Rect2=scene._panel.get_global_rect()
	var label: Rect2=scene._panel_text.get_global_rect();var scroll: Rect2=scene._journal_scroll.get_global_rect();var buttons: Array=[]
	check(viewport.encloses(panel) and scroll.encloses(label),"jatha handoff text fits without scrolling")
	for button in scene._actions.get_children():
		if not button is Button: continue
		var bounds: Rect2=button.get_global_rect()
		check(button.is_visible_in_tree() and scroll.encloses(bounds),"jatha handoff button fits: "+button.text)
		buttons.append({"text":button.text,"rect":rect_value(bounds)})
	check(buttons.size()==2 and String(buttons[0].text).begins_with("Give the trainer"),"jatha handoff retains the original bounded report choice")
	check(scene.model.snapshot()==opened and scene.model.journal()==journal and scene.model.message_followup()==before_message and scene.model.nihang_camp().events==before_events,"open rendered jatha echo freezes Home and grants no report or camp receipt")
	var image:=root.get_texture().get_image();var filename:="handoff-first-return.png";var path:=output.path_join(filename)
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"jatha handoff native frame dimensions")
	check(image.save_png(path)==OK,"jatha handoff screenshot retained")
	handoff_captures.append({"file":filename,"image_sha256":FileAccess.get_sha256(path),"source_file":"jatha-handoff.json",
		"source_sha256":handoff_source_sha256,"account":Rules.FIRST_HANDOFF_ECHO.account,"reply":Rules.FIRST_HANDOFF_ECHO.reply,
		"panel_rect":rect_value(panel),"label_rect":rect_value(label),"scroll_rect":rect_value(scroll),"buttons":buttons,
		"snapshot_sha256":JSON.stringify(opened,"",true,true).sha256_text(),"sampling_preserves_state":scene.model.snapshot()==opened,
		"classification":"authored reconstruction derived from received jatha testimony in the existing childhood report"})
	check(not FileAccess.file_exists(scene.save_path),"jatha handoff rendering creates no player save")
	print("NIHANG_HANDOFF_CAPTURE: "+filename)

func render_followup() -> void:
	var source:=output.path_join("completed-outing.json")
	check(FileAccess.file_exists(source),"retained completed outing exists for farther-road rendering")
	if not FileAccess.file_exists(source): return
	completed_source_sha256=FileAccess.get_sha256(source)
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(source))
	check(value is Dictionary,"retained completed outing parses as a whole Home snapshot")
	if not value is Dictionary: return
	if is_instance_valid(home): home.queue_free()
	await process_frame
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-followup-render-slot.json")
	var error: String=scene.model.restore(value)
	check(error.is_empty(),"retained completed outing validates: "+error)
	if not error.is_empty(): return
	root.add_child(home);await frames(5)
	check(scene._candidate_error(scene.model).is_empty(),"retained completed outing fits original Home geometry")
	var offset: Vector3=Rules.CAMP-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-offset.x,-offset.z)
	annotation.position=Vector2(16,16)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven camp ride\nOriginal Home dialogue · veteran willingness derives from the witnessed first undertaking"
	var event:=InputEventKey.new();event.keycode=KEY_E;event.pressed=true
	scene._unhandled_input(event);await frames()
	check(scene._camp_choices.has("second_ready"),"kept executed outing exposes the farther-road question")
	await capture_followup("question","stopped at the low ground",2)
	await click_choice("Ask the veteran")
	check(Rules.has_event(scene.model.nihang_camp(),"second_ready"),"actual rendered choice records veteran willingness")
	check(scene._message==Rules.WORDS.second_ready,"rendered answer uses the retained childhood moniker text")
	scene.avatar.pivot.rotation.y=atan2(-offset.x,-offset.z)
	scene._unhandled_input(event);await frames()
	await capture_followup("answer",Rules.WORDS.second_ready,2)
	var before_terms: Dictionary=scene.model.snapshot();var journal_before_terms: Array=scene.model.journal()
	await click_choice("Ask him to state")
	check(scene.model.snapshot()==before_terms and scene.model.journal()==journal_before_terms,"rendered term page remains transient")
	await capture_followup("term",Rules.SECOND_TERM_BEAT.body,2)
	check(not FileAccess.file_exists(scene.save_path),"farther-road rendering creates no player save")
	var second_source:=output.path_join("second-outing-complete.json")
	check(FileAccess.file_exists(second_source),"retained completed second outing exists for payoff rendering")
	if not FileAccess.file_exists(second_source): return
	second_source_sha256=FileAccess.get_sha256(second_source)
	value=JSON.parse_string(FileAccess.get_file_as_string(second_source))
	check(value is Dictionary,"retained second outing parses as a whole Home snapshot")
	if not value is Dictionary: return
	home.queue_free();await process_frame
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter")
	scene.save_path=output.path_join("unwritten-second-outing-render-slot.json")
	error=scene.model.restore(value)
	check(error.is_empty(),"retained second outing validates: "+error)
	if not error.is_empty(): return
	root.add_child(home);await frames(5)
	check(scene._candidate_error(scene.model).is_empty(),"retained second outing fits original Home geometry")
	offset=Rules.CAMP-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-offset.x,-offset.z)
	annotation.text="EXECUTED-STATE RENDERING · retained input-driven second outing\nOriginal Home dialogue · witnessed payoff, no currency or capability award"
	scene._unhandled_input(event);await frames()
	await capture_followup("farther-homecoming",Rules.WORDS.second_return,1)
	check(not FileAccess.file_exists(scene.save_path),"second-outing payoff rendering creates no player save")

func finish() -> void:
	var manifest:={"schema":"1792.nihang-care-native-render.v1","classification":"executed-state rendering from retained input-driven Home journey",
		"source_file":"before-care.json","source_sha256":source_sha256,"completed_source_file":"completed-outing.json","completed_source_sha256":completed_source_sha256,
		"second_source_file":"second-outing-complete.json","second_source_sha256":second_source_sha256,
		"handoff_source_file":"jatha-handoff.json","handoff_source_sha256":handoff_source_sha256,
		"captures":captures,"guidance_captures":guidance_captures,"obligation_captures":obligation_captures,
		"handoff_captures":handoff_captures,"followup_captures":followup_captures,"failures":failures,
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
	print("NIHANG_OBLIGATION_RENDER: %d captures; %d failures"%[obligation_captures.size(),failures])
	print("NIHANG_HANDOFF_RENDER: %d captures; %d failures"%[handoff_captures.size(),failures])
	print("NIHANG_FOLLOWUP_RENDER: %d captures; %d failures"%[followup_captures.size(),failures])
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
	await render_obligations()
	check(obligation_captures.size()==2,"first and farther active undertakings captured in the ordinary journal")
	await render_handoff()
	check(handoff_captures.size()==1,"received first-return testimony is captured in the existing childhood report")
	await render_followup()
	check(followup_captures.size()==4,"farther-road question, answer, stated term and completed payoff captured")
	await finish()
