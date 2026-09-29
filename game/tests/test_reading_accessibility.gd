# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_platform.gd"
## Reuse joypad helpers only. This suite reports its own assertions and execution evidence.
const Reading := preload("res://platform/reading_profile.gd")
const ReadUI := preload("res://platform/reading_ui.gd")
const READING_PATH := "user://reading-accessibility-test-only.json"
const READ_SAVE := "user://reading-accessibility-story-test-only.json"

class MalformedTransport extends RefCounted:
	func write_bytes(_path: String,_bytes: PackedByteArray,_limit: int) -> Variant: return null
	func read_bytes(_path: String,_limit: int) -> Dictionary: return {"error":"","bytes":"not bytes"}

class OversizedTransport extends RefCounted:
	func read_bytes(_path: String,_limit: int) -> Dictionary:
		var bytes:=PackedByteArray();bytes.resize(4097)
		return {"error":"","bytes":bytes}

func _reading_domain() -> void:
	ok(Storage.new().write_bytes(READING_PATH,"{broken-startup".to_utf8_buffer(),Reading.LIMIT),"explicit corrupt startup fixture")
	Reading.install(READING_PATH)
	check(not Reading.warning.is_empty() and Reading.snapshot()==Reading.DEFAULTS,"corrupt startup keeps defaults and reports the unread file")
	check(FileAccess.get_file_as_bytes(READING_PATH).get_string_from_utf8()=="{broken-startup","startup never rewrites corrupt preferences")
	ok(Reading.set_preferences(Reading.DEFAULTS,READING_PATH),"reading baseline in isolated file")
	var s:=State.new()
	var world:=s.snapshot()
	var p:=Reading.snapshot()
	var original:=FileAccess.get_file_as_bytes(READING_PATH)
	for key in ["text_percent","high_contrast","narrator_captions","schema"]:
		var bad:=p.duplicate(true);bad.erase(key)
		check(not Reading.set_preferences(bad,READING_PATH).is_empty(),"missing setting refused "+key)
	var bad:=p.duplicate(true);bad.player_id="ranjit_singh"
	check(not Reading.set_preferences(bad,READING_PATH).is_empty(),"world field not admitted into settings")
	bad=p.duplicate(true);bad.schema="unrecognized"
	check(not Reading.validate(bad).is_empty(),"unknown preference schema refused")
	for size in [0,-1,101,175,201,100.5,true,"200",null,NAN,INF]:
		bad=p.duplicate(true);bad.text_percent=size
		check(not Reading.set_preferences(bad,READING_PATH).is_empty(),"non-preset size rejected "+str(size))
	for key in ["high_contrast","narrator_captions"]:
		for value in [1,"true",null]:
			bad=p.duplicate(true);bad[key]=value
			check(not Reading.validate(bad).is_empty(),"non-boolean switch refused "+key)
	check(Reading.snapshot()==p and FileAccess.get_file_as_bytes(READING_PATH)==original,"invalid preferences preserve memory and existing bytes")
	for path in ["", "res://ui/main_menu.gd", "user://../outside.json", "user://nested/settings.json", "user://settings.tmp"]:
		check(not Reading.set_preferences(p,path).is_empty(),"scope guard rejects "+path)
	for size in Reading.SIZES:
		p.text_percent=size;p.high_contrast=true;p.narrator_captions=false
		ok(Reading.set_preferences(p,READING_PATH),"persist supported size "+str(size))
		ok(Reading.set_preferences(Reading.DEFAULTS,"user://reading-other-test-only.json"),"different live settings before reload")
		ok(Reading.load_preferences(READING_PATH),"reload supported size "+str(size))
		check(Reading.snapshot()==p,"complete settings roundtrip "+str(size))
	check(s.snapshot()==world,"preferences cannot alter world/knowledge/perception")
	var detached:=Reading.snapshot();detached.text_percent=100
	check(Reading.snapshot().text_percent==200,"preference view is detached")
	check(Reading.proposal("unknown").is_empty(),"unknown UI request is not a reset")
	var bytes:=FileAccess.get_file_as_bytes(READING_PATH)
	check(not Reading.set_preferences(Reading.DEFAULTS,READING_PATH,RefusingTransport.new()).is_empty(),"injected write failure reported")
	check(Reading.snapshot()==p and FileAccess.get_file_as_bytes(READING_PATH)==bytes,"failed write cannot install unsaved settings")
	check(not Reading.load_preferences(READING_PATH,RefusingTransport.new()).is_empty(),"injected read failure has no disk fallback")
	check(not Reading.load_preferences(READING_PATH,MalformedTransport.new()).is_empty(),"malformed provider bytes rejected")
	check(not Reading.set_preferences(Reading.DEFAULTS,READING_PATH,MalformedTransport.new()).is_empty(),"malformed provider write response rejected")
	check(not Reading.load_preferences(READING_PATH,OversizedTransport.new()).is_empty(),"provider cannot bypass byte budget")
	check(Reading.snapshot()==p,"provider failures preserve all live settings")
	ok(Storage.new().write_bytes(READING_PATH,"{broken".to_utf8_buffer(),4096),"explicit corrupt preference fixture")
	check(not Reading.load_preferences(READING_PATH).is_empty() and Reading.snapshot()==p,"corrupt JSON never partly applies")
	ok(Reading.set_preferences(Reading.DEFAULTS,READING_PATH),"recover preferences using explicit valid write")
	var panel:=PanelContainer.new();root.add_child(panel)
	var col:=VBoxContainer.new();panel.add_child(col)
	var label:=Label.new();label.text="Read this without changing the story."
	label.add_theme_font_size_override("font_size",20);col.add_child(label)
	var b:=Button.new();b.text="Continue";col.add_child(b)
	var base_font:=b.get_theme_font_size("font_size")
	for size in Reading.SIZES:
		p=Reading.snapshot();p.text_percent=size;p.high_contrast=true
		ok(Reading.set_preferences(p,READING_PATH),"select renderer scale "+str(size))
		ReadUI.apply(panel);ReadUI.apply(panel)
		check(label.get_theme_font_size("font_size")==int(round(size*0.2)),"label scaling is idempotent")
		check(b.get_theme_font_size("font_size")==int(round(base_font*size/100.0)),"button scaling does not compound")
		check(panel.get_theme_stylebox("panel").bg_color==Color.BLACK,"high contrast uses opaque panel")
	ok(Reading.set_preferences(Reading.DEFAULTS,READING_PATH),"reset presentation after renderer checks")
	ReadUI.apply(panel)
	check(label.get_theme_font_size("font_size")==20 and not b.has_theme_font_size_override("font_size"),"reset preserves explicit and inherited original font styles")
	check(not panel.has_theme_stylebox_override("panel") and not b.has_theme_stylebox_override("focus"),"reset removes only added style overrides")
	panel.queue_free()

func _assert_focus_visible(scroll: ScrollContainer,label: String) -> void:
	var focus:=root.gui_get_focus_owner()
	check(focus is Button and focus.is_visible_in_tree(),label+" focuses a visible button")
	if focus is Control:
		var rect:=focus.get_global_rect()
		check(scroll.get_global_rect().grow(3).encloses(rect),label+" keeps the complete focused button inside scroll viewport: button="+str(rect)+" viewport="+str(scroll.get_global_rect()))

func _reading_journey() -> void:
	# Real title and only joypad navigation/movement; no pose or story-progress injection.
	var menu=load("res://ui/main_menu.tscn").instantiate()
	menu.reading_settings_path=READING_PATH;menu.home_save_path=READ_SAVE
	root.add_child(menu);current_scene=menu;await frames(5)
	await choose("Text and reading settings")
	check(menu._reading_box.visible,"reading options reachable before gameplay")
	for _i in range(3): await choose("Cycle text size")
	check(Reading.snapshot().text_percent==200,"controller selects 200 percent text")
	await choose("Toggle high-contrast")
	check(Reading.snapshot().high_contrast,"controller enables stronger modal contrast")
	_assert_focus_visible(menu._scroll,"large title settings")
	axis(JOY_AXIS_RIGHT_Y,-1);await frames(90);axis(JOY_AXIS_RIGHT_Y,0)
	check(menu._scroll.scroll_vertical==0,"right stick can reach start of enlarged title description")
	await tap(JOY_BUTTON_B)
	check(not menu._reading_box.visible,"fixed Back leaves reading settings")
	await choose("1792 ·")
	var scene=current_scene.get_node("ChildhoodChapter")
	scene.reading_settings_path=READING_PATH;scene.save_path=READ_SAVE
	check(Reading.snapshot().text_percent==200,"settings carry from title into same home chapter")
	await tap(JOY_BUTTON_START);await choose("Text and reading settings")
	var paused: Dictionary=scene.model.snapshot()
	var veil: bool=scene._veil.visible
	check(scene._panel_text.get_theme_font_size("font_size")==34,"actual home dialog is twice its base text size")
	_assert_focus_visible(scene._journal_scroll,"large home settings")
	root.size=Vector2i(800,600);await frames(5)
	_assert_focus_visible(scene._journal_scroll,"small-window large home settings")
	check(scene._panel_text.get_theme_font_size("font_size")==34,"resizing never silently shrinks chosen text")
	await frames(40)
	check(scene.model.snapshot()==paused and scene._veil.visible==veil,"reading never advances time or alters perception presentation")
	var provider: RefCounted=scene.model.platform_services.storage
	scene.model.platform_services.storage=RefusingTransport.new()
	await choose("Cycle text size")
	check(scene._panel_text.text.contains("Not saved") and Reading.snapshot().text_percent==200,"actual UI preserves scale on write failure")
	scene.model.platform_services.storage=provider
	scene.controls.set_focus(false);await frames(2)
	await tap(JOY_BUTTON_A)
	check(scene._paused and Reading.snapshot().text_percent==200,"background confirmation cannot change preferences or resume")
	scene.controls.set_focus(true);await tap(JOY_BUTTON_A)
	check(not scene._paused and scene._reading_page.is_empty(),"explicit resume clears reading context at largest text")
	root.size=Vector2i(1280,720);await frames(3)
	# Observe actual displayed-only reader content, including no unreceived rope catalogue.
	await tap(JOY_BUTTON_START);await choose("Read current messages")
	check(scene._panel_text.text.contains("CURRENT TASK AND CONTROLS"),"reader includes the current rendered task")
	check(not scene._panel_text.text.contains("I lent the spare lead-rope"),"reader does not reveal an unreceived story")
	paused=scene.model.snapshot();await frames(30)
	check(scene.model.snapshot()==paused,"current-message reader pauses every existing world domain")
	axis(JOY_AXIS_RIGHT_Y,-1);await frames(160);axis(JOY_AXIS_RIGHT_Y,0)
	check(scene._journal_scroll.scroll_vertical==0,"controller reads the beginning of long current messages")
	await choose("Resume")
	axis(JOY_AXIS_RIGHT_X,1);await frames(32);axis(JOY_AXIS_RIGHT_X,0)
	await walk(scene,Vector3(0,0,-7))
	await walk(scene,Vector3(-2.5,0,3));await look(scene,Base.SITES.letter)
	await tap(JOY_BUTTON_X);await tap(JOY_BUTTON_X)
	check(scene.model.progress().heard==["courier"],"real listening still requires physical arrival and interaction")
	await tap(JOY_BUTTON_START);await choose("Save chapter")
	var saved:=FileAccess.get_file_as_bytes(READ_SAVE)
	check(not saved.get_string_from_utf8().contains("reading-settings"),"story schema has no reading preferences")
	await tap(JOY_BUTTON_START);await choose("Text and reading settings")
	await choose("Toggle Shah Muhammad")
	check(not Reading.snapshot().narrator_captions,"optional retrospective captions can be disabled independently")
	await tap(JOY_BUTTON_B);await choose("Load chapter")
	check(Reading.snapshot().text_percent==200 and not Reading.snapshot().narrator_captions,"loading story retains independent text preferences")
	check(not scene._narrator_label.visible,"disabled narrator stays hidden after load")
	await tap(JOY_BUTTON_START);await choose("Read current messages")
	check(not scene._panel_text.text.contains("RETROSPECTIVE NARRATION"),"reader does not reveal hidden captions")
	check(FileAccess.get_file_as_bytes(READ_SAVE)==saved,"reader leaves saved bytes unchanged")
	await tap(JOY_BUTTON_B);await choose("Text and reading settings")
	await choose("Reset reading preferences")
	check(Reading.snapshot()==Reading.DEFAULTS and scene._panel_text.get_theme_font_size("font_size")==17,"explicit reset restores initial reading presentation")
	await tap(JOY_BUTTON_B);await choose("Main menu")
	check(current_scene.scene_file_path=="res://ui/main_menu.tscn","same controller reaches title without keyboard escape")
	current_scene.queue_free();current_scene=null;await frames(3)

func _run() -> void:
	Input.use_accumulated_input=false
	_reading_domain();neutral();await frames(3)
	await _reading_journey()
	var audit: Dictionary={"schema":"cg.reading-conformance.v1","model_id":Reading.SCHEMA,
		"operation_id":"synthetic-reading-journey.v1","verification_id":"reading-native.v1",
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"execution_id":OS.get_environment("GITHUB_RUN_ID"),
		"engine":Engine.get_version_info().string,"os":OS.get_name(),"joy_events":joy_events,
		"physical_controller_test":false,"journey_fixture":false,"keyboard_or_mouse_events_in_journey":0,
		"accessibility_certification":false,"screen_reader_test":false}
	var file:=FileAccess.open("user://platform-reading-audit.json",FileAccess.WRITE)
	check(file!=null,"retain reading conformance observation")
	if file!=null:
		audit.passed=passed;audit.failed=failed
		file.store_string(JSON.stringify(audit,"\t"));file.close()
	for path in [READING_PATH,"user://reading-other-test-only.json",READ_SAVE,READ_SAVE+".previous",READ_SAVE+".checkpoint.json"]: DirAccess.remove_absolute(path)
	print("READING_ACCESSIBILITY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
