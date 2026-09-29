extends Control

const PlatformRuntime := preload("res://platform/platform_runtime.gd")
var platform_runtime: Node
var _hardware_box: VBoxContainer

const Reading := preload("res://platform/reading_profile.gd")
const ReadingUI := preload("res://platform/reading_ui.gd")
var reading_settings_path:=Reading.PATH
var _reading_box: VBoxContainer
const HomeLaunch := preload("res://childhood/home_launch.gd")
const Shell := preload("res://platform/controller_shell.gd")
const Probe := preload("res://platform/build_probe.gd")
const Recovery := preload("res://platform/save_recovery.gd")
const SaveState := preload("res://narrative/oral_memory/memory_state.gd")
var home_save_path := SaveState.ORAL_SAVE # Code-side test injection; never set by save content.
var save_reader:=SaveState.new()
var _title_column: VBoxContainer
var _saved_box: VBoxContainer
var _scroll: ScrollContainer
var _normal_children: Array=[]
var _continue_busy:=false
var _continue_epoch:=0
var _saved_choice: Dictionary={}
var controls: Node

const Names := preload("res://characters/character_names.gd")

func _ready() -> void:
	var args:=OS.get_cmdline_user_args()
	var requested:=false
	for arg in args:
		if arg.begins_with("--steam-app-id") or arg=="--hardware-session": requested=true
	if requested and get_tree().root.get_node_or_null("PlatformRuntime")==null:
		_finish_platform_boot.call_deferred()
		return
	platform_runtime=PlatformRuntime.ensure(get_tree(),OS.get_cmdline_user_args())
	if platform_runtime!=null and platform_runtime.steam_requested and platform_runtime.can_enter():
		save_reader.platform_services=platform_runtime.provider
	Reading.install(reading_settings_path)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	controls=Shell.new()
	add_child(controls)
	controls.interrupted.connect(_saved_interrupted)
	var background := ColorRect.new()
	background.color = Color("172321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var scroll:=ScrollContainer.new()
	_scroll=scroll
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	margin.add_child(scroll)
	controls.scroll_target=scroll
	var panel := VBoxContainer.new()
	_title_column=panel
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 14)
	scroll.add_child(panel)
	var title := Label.new()
	title.text = "1792"
	title.add_theme_font_size_override("font_size", 64)
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Build outward from home.\nEarly development prototypes — not a finished historical reconstruction."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(subtitle)
	_add_button(panel, "1792 · " + Names.PLAYER_NAME + " · Home territory", "res://world/home_territory.tscn")
	_add_button(panel, "Living politics + one-eye vision (extended home chapter)", "res://world/political_home.tscn")
	_add_button(panel, "Lahore · Command story (separate 1801 sandbox)", "res://world/command_sandbox.tscn")
	_add_button(panel, "Lahore · Houses and rivals (riding / companions / house politics)", "res://world/house_sandbox.tscn")
	var primary:=Recovery.inspect(save_reader,home_save_path) if platform_runtime==null or platform_runtime.can_enter() else {"status":"unavailable"}
	var continue_button:=Button.new()
	continue_button.text="Continue saved home chapter"
	continue_button.custom_minimum_size.y=48
	continue_button.disabled=primary.status!="valid"
	continue_button.pressed.connect(func():
		if not _continue_busy and controls.focused: _continue_selected(primary))
	panel.add_child(continue_button)
	var saves_button:=Button.new()
	saves_button.text="Saved home chapter / recovery"
	saves_button.custom_minimum_size.y=48
	saves_button.pressed.connect(func():
		if not _continue_busy and controls.focused: _open_saved())
	panel.add_child(saves_button)
	Shell.focus_buttons(panel,scroll)
	var note := Label.new()
	note.text = "WASD: move · Shift: run · Mouse: look\nE interact · F5 save · F9 load · F1 menu · H houses · F mount · G companions (Houses and rivals)\nThe sandbox captain, missions and geography are fictional placeholders."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.text+="\nXbox-style controller: D-pad selects · A confirms · Left stick moves · Right stick looks\nHome: X interacts · Menu opens journal/save/settings · View opens stories\nLocal PC build — no store sign-in, cloud save or Xbox console integration."
	panel.add_child(note)
	var reading_button:=Button.new()
	reading_button.text="Text and reading settings"
	reading_button.custom_minimum_size.y=48
	reading_button.pressed.connect(func():
		if not _continue_busy and controls.focused: _open_reading(Reading.warning))
	panel.add_child(reading_button)
	if platform_runtime!=null:
		var platform_note:=Label.new()
		platform_note.text=platform_runtime.status_text()
		platform_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(platform_note)
		if platform_runtime.recorder!=null:
			var hardware_button:=Button.new()
			hardware_button.text="Local hardware test session"
			hardware_button.custom_minimum_size.y=48
			hardware_button.pressed.connect(_open_hardware)
			panel.add_child(hardware_button)
	_normal_children=panel.get_children()
	_hardware_box=VBoxContainer.new()
	_hardware_box.hide()
	panel.add_child(_hardware_box)
	_saved_box=VBoxContainer.new()
	_saved_box.add_theme_constant_override("separation",14)
	_saved_box.hide()
	panel.add_child(_saved_box)
	_reading_box=VBoxContainer.new()
	_reading_box.add_theme_constant_override("separation",14)
	_reading_box.hide()
	panel.add_child(_reading_box)
	ReadingUI.apply(panel)
	Shell.focus_buttons(panel,scroll)
	if "--platform-smoke" in OS.get_cmdline_user_args(): Probe.run.call_deferred(self)
	elif "--platform-integration-smoke" in OS.get_cmdline_user_args():
		preload("res://platform/store_probe.gd").run.call_deferred(self)

func _add_button(parent: Node, text: String, scene: String) -> void:
	var button := Button.new()
	button.text = text
	if platform_runtime!=null and platform_runtime.steam_requested and scene!="res://world/home_territory.tscn":
		button.disabled=true
		button.text+=" (store profile not adapted)"
	button.custom_minimum_size.y = 48
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		if _continue_busy or not controls.focused: return
		if platform_runtime!=null and platform_runtime.steam_requested and scene!="res://world/home_territory.tscn": return
		if scene == "res://world/home_territory.tscn":
			HomeLaunch.enter.call_deferred(get_tree())
		else:
			get_tree().change_scene_to_file(scene))
	parent.add_child(button)

func _input(event: InputEvent) -> void:
	if _continue_busy or not is_instance_valid(controls): get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(controls) or not controls.focused: return
	if is_instance_valid(_hardware_box) and _hardware_box.visible and event.is_action_pressed("ui_cancel"):
		_close_hardware()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_reading_box) and _reading_box.visible and event.is_action_pressed("ui_cancel"):
		_close_reading()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_saved_box) and _saved_box.visible and event.is_action_pressed("ui_cancel"):
		if not _saved_choice.is_empty(): _open_saved()
		else: _close_saved()
		get_viewport().set_input_as_handled()

func _saved_interrupted(reason: String) -> void:
	_continue_epoch+=1
	_saved_choice={}
	if is_instance_valid(_saved_box) and _saved_box.visible: _open_saved(reason)
	if is_instance_valid(_reading_box) and _reading_box.visible: _open_reading(reason)

func _saved_content(body: String) -> void:
	_reading_box.hide()
	_saved_choice={}
	for child in _normal_children: child.hide()
	for child in _saved_box.get_children():
		_saved_box.remove_child(child);child.queue_free()
	_saved_box.show()
	var label:=Label.new()
	label.text="SAVED HOME CHAPTER\n\n"+body
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",20)
	_saved_box.add_child(label)
	controls.scroll_target=_scroll

func _saved_button(text: String, callback: Callable) -> void:
	var button:=Button.new()
	button.text=text;button.custom_minimum_size.y=48
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		if not _continue_busy and controls.focused: callback.call())
	_saved_box.add_child(button)

func _focus_saved() -> void:
	ReadingUI.apply(_saved_box)
	Shell.focus_buttons(_saved_box,_scroll)
	ReadingUI.reveal_focus_after_layout(_saved_box,_scroll)

func _open_saved(note: String="") -> void:
	var primary:=Recovery.inspect(save_reader,home_save_path) if platform_runtime==null or platform_runtime.can_enter() else {"status":"unavailable"}
	var previous:=Recovery.inspect(save_reader,home_save_path+Recovery.PREVIOUS_SUFFIX)
	var body:=note+"\n\n" if not note.is_empty() else ""
	body+=Recovery.description(primary,"Primary manual save")+"\n\n"+Recovery.description(previous,"Previous manual save")
	body+="\n\nNo automatic fallback: choose the chapter you intend to resume. Files and controller settings are not changed by loading."
	_saved_content(body)
	if primary.status=="valid": _saved_button("Continue primary",_continue_selected.bind(primary))
	if previous.status=="valid": _saved_button("Review previous save",_confirm_previous.bind(previous))
	_saved_button("Back to title",_close_saved)
	_focus_saved.call_deferred()

func _confirm_previous(view: Dictionary) -> void:
	_saved_content(Recovery.description(view,"Previous manual save")+"\n\nResume this previous chapter? It may omit more recent progress. Neither save file will be overwritten.")
	_saved_choice=view.duplicate(true)
	_saved_button("Confirm previous chapter",_continue_selected.bind(view))
	_saved_button("Cancel",_open_saved)
	_focus_saved.call_deferred()

func _close_saved() -> void:
	_saved_choice={}
	_saved_box.hide()
	for child in _normal_children: child.show()
	Shell.focus_buttons(_title_column,_scroll)

func _continue_selected(view: Dictionary) -> void:
	if _continue_busy or not controls.focused: return
	_continue_busy=true
	_continue_epoch+=1
	var epoch:=_continue_epoch
	var allowed:=func() -> bool: return is_inside_tree() and controls.focused and epoch==_continue_epoch
	var error: String=await HomeLaunch.enter_saved(get_tree(),view.path,view.digest,home_save_path,save_reader.platform_services,allowed)
	# Successful entry removed this menu. Do not manipulate the new scene's focus.
	if error.is_empty(): return
	_continue_busy=false
	if is_inside_tree(): _open_saved(error)

func _open_reading(note: String="") -> void:
	_saved_choice={}
	_saved_box.hide()
	for child in _normal_children: child.hide()
	for child in _reading_box.get_children():
		_reading_box.remove_child(child);child.queue_free()
	_reading_box.show()
	var label:=Label.new()
	label.text="TEXT AND READING\n\n"+Reading.description(note)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",20)
	_reading_box.add_child(label)
	for spec in Reading.actions("reading_back"):
		var button:=Button.new()
		button.text=spec[0];button.custom_minimum_size.y=48
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_reading_action.bind(spec[1]))
		_reading_box.add_child(button)
	ReadingUI.apply(_reading_box)
	Shell.focus_buttons(_reading_box,_scroll)
	ReadingUI.reveal_focus_after_layout(_reading_box,_scroll)

func _reading_action(action: String) -> void:
	if _continue_busy or not controls.focused: return
	if action=="reading_back":
		_close_reading()
		return
	var candidate:=Reading.proposal(action)
	if candidate.is_empty(): return
	var reading_io: RefCounted=save_reader.platform_services.storage
	if save_reader.platform_services.has_method("reading_storage"): reading_io=save_reader.platform_services.reading_storage()
	var error:=Reading.set_preferences(candidate,reading_settings_path,reading_io)
	ReadingUI.apply(_title_column)
	_open_reading("Saved." if error.is_empty() else "Not saved: "+error)

func _close_reading() -> void:
	_reading_box.hide()
	for child in _normal_children: child.show()
	ReadingUI.apply(_title_column)
	Shell.focus_buttons(_title_column,_scroll)

func _open_hardware(message: String="") -> void:
	if platform_runtime==null or platform_runtime.recorder==null or not controls.focused or _continue_busy: return
	for child in _normal_children: child.hide()
	_saved_box.hide();_reading_box.hide()
	for child in _hardware_box.get_children():
		_hardware_box.remove_child(child);child.queue_free()
	_hardware_box.show()
	var text:=Label.new()
	text.text=platform_runtime.recorder.text()+"\n"+message
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_hardware_box.add_child(text)
	_hardware_button("Export local report",func(): _open_hardware(platform_runtime.recorder.write_report()))
	_hardware_button("Capture current game view",func(): _open_hardware(await platform_runtime.recorder.capture_view()))
	_hardware_button("Return",_close_hardware)
	ReadingUI.apply(_hardware_box);Shell.focus_buttons(_hardware_box,_scroll)
	ReadingUI.reveal_focus_after_layout(_hardware_box,_scroll)

func _hardware_button(text: String, action: Callable) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=48
	button.pressed.connect(func():
		if controls.focused and not _continue_busy: action.call())
	_hardware_box.add_child(button)

func _close_hardware() -> void:
	_hardware_box.hide()
	for child in _normal_children: child.show()
	Shell.focus_buttons(_title_column,_scroll)

func _finish_platform_boot() -> void:
	# The root is busy during main-scene _ready. Attach the process owner only after setup.
	PlatformRuntime.ensure(get_tree(),OS.get_cmdline_user_args())
	_ready()
