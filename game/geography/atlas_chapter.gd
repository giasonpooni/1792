# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://youth/brawl_chapter.gd"
## Extend the SAME world/clock/controller. No campaign data, actor or save migration.
const AtlasPanel := preload("res://geography/atlas_panel.gd")
var atlas_panel: CanvasLayer

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F3:
		if is_instance_valid(atlas_panel): close_atlas()
		elif not _paused: open_atlas()
		get_viewport().set_input_as_handled();return
	if is_instance_valid(atlas_panel):
		# Do not let another inherited key replace the modal underneath this view.
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func open_atlas() -> void:
	if _paused or is_instance_valid(atlas_panel): return
	_show_dialog("World atlas","Research only",[["Return","resume"]])
	_panel.hide()
	atlas_panel=AtlasPanel.new();atlas_panel.name="HistoricalWorldAtlas"
	atlas_panel.closed.connect(close_atlas);add_child(atlas_panel)

func close_atlas() -> void:
	if not is_instance_valid(atlas_panel): return
	remove_child(atlas_panel);atlas_panel.queue_free();atlas_panel=null
	_resume()
