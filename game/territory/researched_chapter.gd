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
	var layer:=CanvasLayer.new()
	layer.layer=7
	add_child(layer)
	_narrator_label=Label.new()
	_narrator_label.position=Vector2(18,230)
	_narrator_label.size=Vector2(620,100)
	_narrator_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_narrator_label.add_theme_font_size_override("font_size",16)
	_narrator_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	_narrator_label.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(_narrator_label)
	_presentation_initialized=true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F2:
		if not _paused: _show_dialog("GUJRANWALA — RESEARCH VIEW",fabric.notebook(),[["Return","resume"]])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _apply() -> void:
	super._apply()
	if _presentation_initialized: narrator.rebind(model.snapshot())

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(fabric): fabric.update_from_tick(int(model.progress().tick))
	if is_instance_valid(_narrator_label):
		_narrator_label.text=narrator.observe(model.snapshot())
		_narrator_label.visible=not _paused
		_narrator_label.size.x=minf(620,get_viewport().get_visible_rect().size.x-36)
	if is_instance_valid(_hud): _hud.text+="\nF2: reconstruction notebook (development reference)"
