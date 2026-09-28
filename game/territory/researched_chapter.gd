# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/gujranwala_chapter.gd"
## Presentation-only extension. The supply/childhood controller remains authoritative.
const Fabric := preload("res://reconstruction/district_fabric.gd")
const Narrator := preload("res://narrative/shah_observer.gd")
var fabric: Node3D
var narrator := Narrator.new()
var _narrator_label: Label
var _presentation_initialized := false

func _build_world() -> void:
	super._build_world()
	fabric=Fabric.new()
	fabric.name="ResearchDistrict"
	add_child(fabric)
	var error: String=fabric.build()
	if not error.is_empty(): push_error(error)

func _ready() -> void:
	super._ready()
	_narrator_label=Label.new()
	_narrator_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_narrator_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_narrator_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_narrator_label.add_theme_font_size_override("font_size",16)
	_narrator_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	_narrator_label.add_theme_constant_override("shadow_offset_y",2)
	# Share the existing responsive column instead of guessing a fixed screen Y.
	var column: VBoxContainer=_hud.get_parent()
	column.add_child(_narrator_label)
	column.move_child(_narrator_label,_hud.get_index()+1)
	_presentation_initialized=true
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		if not _paused: _show_dialog("GUJRANWALA — RESEARCH VIEW",fabric.notebook(),[["Return","resume"]])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _show_dialog(title: String, body: String, actions: Array) -> void:
	super._show_dialog(title,body,actions)
	if is_instance_valid(_narrator_label): _narrator_label.hide()

func _open_journal() -> void:
	super._open_journal()
	if is_instance_valid(_narrator_label): _narrator_label.hide()

func _apply() -> void:
	super._apply()
	if _presentation_initialized: narrator.rebind(model.snapshot())

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(fabric): fabric.update_from_tick(int(model.progress().tick))
	if is_instance_valid(_narrator_label):
		_narrator_label.text=narrator.observe(model.snapshot())
		_narrator_label.visible=not _paused and not _narrator_label.text.is_empty()
	if is_instance_valid(_hud): _hud.text+="\nF2: reconstruction notebook (development reference)"
