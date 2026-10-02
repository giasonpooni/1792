extends Control

const GAME_TITLE := "1792: The Lotus Throne"
const HomeLaunch := preload("res://childhood/home_launch.gd")
const MahanLaunch := preload("res://mahan/mahan_launch.gd")
const Names := preload("res://characters/character_names.gd")
const SliceLaunch := preload("res://slice/slice_launch.gd")
const Continuation := preload("res://slice/continuation_store.gd")

func _ready() -> void:
	get_window().title = GAME_TITLE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	background.color = Color("172321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left=24;scroll.offset_right=-24;scroll.offset_top=20;scroll.offset_bottom=-20
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size=Vector2(660,0)
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)
	var title := Label.new()
	title.text = GAME_TITLE
	title.add_theme_font_size_override("font_size", 40)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Escape Sobraon. Hear the story carried through defeat.\nFollow Shah Muhammad's telling into Ranjit Singh's childhood in Gujranwala."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(subtitle)
	var begin:=_add_button(panel, "Begin · 1792 · " + Names.PLAYER_NAME + " · Home territory", "res://world/home_territory.tscn")
	begin.name="BeginChildhood"
	var help:=Label.new()
	help.text="WASD move · Mouse look · E speak · F mount\nJ / Esc opens the journal, saves and Main menu."
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;panel.add_child(help)
	var prototypes:=Label.new()
	prototypes.text="DEVELOPMENT STUDIES"
	prototypes.add_theme_font_size_override("font_size",14)
	prototypes.add_theme_color_override("font_color",Color("b9b29b"));panel.add_child(prototypes)
	var slice_title:=Label.new();slice_title.text="GUJRANWALA · VERTICAL SLICE 0.1";slice_title.add_theme_font_size_override("font_size",24);panel.add_child(slice_title)
	_slice_button(panel,"Continue your Gujranwala visit","continue",FileAccess.file_exists(Continuation.PATH))
	_slice_button(panel,"Start a new Gujranwala run · replaces Continue","new")
	_add_button(panel, "Living politics + one-eye vision (extended home chapter)", "res://world/political_home.tscn")
	_add_button(panel, "Lahore · Command story (separate 1801 sandbox)", "res://world/command_sandbox.tscn")
	_add_button(panel, "Lahore · Houses and rivals (riding / companions / house politics)", "res://world/house_sandbox.tscn")
	_add_button(panel, "Movement qualification · shared motor / no story progress", "res://mechanics/course.tscn")
	_add_button(panel, "Equipment study · sword, scabbard, shield and helmet", "res://presentation/equipment_study.tscn")
	_add_button(panel, "Horsecraft · paired riding and mounted matchlocks", "res://mounts/horsecraft_study.tscn")
	_add_button(panel, "Ground contact practice · stairs and slopes", "res://mechanics/ground_course.tscn")
	_add_button(panel, "1790 · Mahan Singh · Field camp (interlude)", "res://world/mahan_camp.tscn")
	_add_button(panel, "Punjab Chiefs · thirteen playable recollections", "res://history/punjab_chiefs_home.tscn")
	var note := Label.new()
	note.text = "Early development prototypes. The figures, dialogue and scenes are authored studies.\nThe sandbox captain, missions and geography are fictional placeholders."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)
	begin.grab_focus()

func _slice_button(parent: Node,text: String,mode: String,enabled: bool=true) -> void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=48
	button.set_meta("slice_mode",mode)
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.disabled=not enabled
	button.pressed.connect(func(): SliceLaunch.enter.call_deferred(get_tree(),mode))
	parent.add_child(button)

func _add_button(parent: Node, text: String, scene: String) -> Button:
	var button := Button.new()
	button.set_meta("destination_scene", scene)
	button.text = text
	button.clip_text=true
	button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text=text
	button.custom_minimum_size.y = 48
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func():
		if scene == "res://world/home_territory.tscn":
			HomeLaunch.enter.call_deferred(get_tree())
		elif scene == "res://world/mahan_camp.tscn":
			MahanLaunch.enter.call_deferred(get_tree())
		else:
			get_tree().change_scene_to_file(scene))
	parent.add_child(button)
	return button
