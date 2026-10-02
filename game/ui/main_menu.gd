extends Control

const HomeLaunch := preload("res://childhood/home_launch.gd")
const Names := preload("res://characters/character_names.gd")

func _ready() -> void:
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
	title.text = "1792"
	title.add_theme_font_size_override("font_size", 64)
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
	_add_button(panel, "Living politics + one-eye vision (extended home chapter)", "res://world/political_home.tscn")
	_add_button(panel, "Lahore · Command story (separate 1801 sandbox)", "res://world/command_sandbox.tscn")
	_add_button(panel, "Lahore · Houses and rivals (riding / companions / house politics)", "res://world/house_sandbox.tscn")
	_add_button(panel, "Movement qualification · shared motor / no story progress", "res://mechanics/course.tscn")
	_add_button(panel, "Horsecraft · paired riding and mounted matchlocks", "res://mounts/horsecraft_study.tscn")
	var note := Label.new()
	note.text = "Early development prototypes. The figures, dialogue and scenes are authored studies.\nThe sandbox captain, missions and geography are fictional placeholders."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)
	begin.grab_focus()

func _add_button(parent: Node, text: String, scene: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(func():
		if scene == "res://world/home_territory.tscn":
			HomeLaunch.enter.call_deferred(get_tree())
		else:
			get_tree().change_scene_to_file(scene))
	parent.add_child(button)
	return button
