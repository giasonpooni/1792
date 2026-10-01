extends Control

const HomeLaunch := preload("res://childhood/home_launch.gd")
const Names := preload("res://characters/character_names.gd")
const SliceLaunch := preload("res://slice/slice_launch.gd")
const Continuation := preload("res://slice/continuation_store.gd")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	background.color = Color("172321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,36)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var panel := VBoxContainer.new()
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
	var slice_title:=Label.new();slice_title.text="GUJRANWALA · VERTICAL SLICE 0.1";slice_title.add_theme_font_size_override("font_size",24);panel.add_child(slice_title)
	_slice_button(panel,"Continue your Gujranwala visit","continue",FileAccess.file_exists(Continuation.PATH))
	_slice_button(panel,"Start a new Gujranwala run · replaces Continue","new")
	_add_button(panel, "1792 · " + Names.PLAYER_NAME + " · Home territory", "res://world/home_territory.tscn")
	_add_button(panel, "Living politics + one-eye vision (extended home chapter)", "res://world/political_home.tscn")
	_add_button(panel, "Lahore · Command story (separate 1801 sandbox)", "res://world/command_sandbox.tscn")
	_add_button(panel, "Lahore · Houses and rivals (riding / companions / house politics)", "res://world/house_sandbox.tscn")
	_add_button(panel, "Movement qualification · shared motor / no story progress", "res://mechanics/course.tscn")
	var note := Label.new()
	note.text = "WASD: move · Shift: run · Mouse: look\nE interact · F5 save · F9 load · F1 menu · H houses · F mount · G companions (Houses and rivals)\nThe sandbox captain, missions and geography are fictional placeholders."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)

func _slice_button(parent: Node,text: String,mode: String,enabled: bool=true) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=48
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.disabled=not enabled
	button.pressed.connect(func(): SliceLaunch.enter.call_deferred(get_tree(),mode))
	parent.add_child(button)

func _add_button(parent: Node, text: String, scene: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		if scene == "res://world/home_territory.tscn":
			HomeLaunch.enter.call_deferred(get_tree())
		else:
			get_tree().change_scene_to_file(scene))
	parent.add_child(button)
