extends Control

const HomeLaunch := preload("res://childhood/home_launch.gd")
const Shell := preload("res://platform/controller_shell.gd")
const Probe := preload("res://platform/build_probe.gd")
var controls: Node

const Names := preload("res://characters/character_names.gd")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	controls=Shell.new()
	add_child(controls)
	var background := ColorRect.new()
	background.color = Color("172321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	margin.add_child(scroll)
	controls.scroll_target=scroll
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
	_add_button(panel, "1792 · " + Names.PLAYER_NAME + " · Home territory", "res://world/home_territory.tscn")
	_add_button(panel, "Living politics + one-eye vision (extended home chapter)", "res://world/political_home.tscn")
	_add_button(panel, "Lahore · Command story (separate 1801 sandbox)", "res://world/command_sandbox.tscn")
	_add_button(panel, "Lahore · Houses and rivals (riding / companions / house politics)", "res://world/house_sandbox.tscn")
	Shell.focus_buttons(panel,scroll)
	var note := Label.new()
	note.text = "WASD: move · Shift: run · Mouse: look\nE interact · F5 save · F9 load · F1 menu · H houses · F mount · G companions (Houses and rivals)\nThe sandbox captain, missions and geography are fictional placeholders."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.text+="\nXbox-style controller: D-pad selects · A confirms · Left stick moves · Right stick looks\nHome: X interacts · Menu opens journal/save/settings · View opens stories\nLocal PC build — no store sign-in, cloud save or Xbox console integration."
	panel.add_child(note)
	if "--platform-smoke" in OS.get_cmdline_user_args(): Probe.run.call_deferred(self)

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
