# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://geography/atlas_chapter.gd"
## Same Home authority. F7 opens a paused, read-only art-development control.
const HomeArt := preload("res://presentation/home_art.gd")
var art: Node3D
var _art_open := false

func _ready() -> void:
	super._ready()
	art=HomeArt.new();art.name="HomeArtStudy";add_child(art)
	var error: String=art.build(self)
	if not error.is_empty(): push_error(error)
	_refresh()

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(art) and not art.manifest.is_empty():
		art.sample(int(model.progress().tick))
		if is_instance_valid(_hud): _hud.text+="\nF7: visual study / lighting comparison (not historical time)"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F7:
		if _art_open: _resume()
		elif not _paused: open_art_study()
		get_viewport().set_input_as_handled();return
	if _art_open:
		get_viewport().set_input_as_handled();return
	super._unhandled_input(event)

func open_art_study() -> void:
	if not is_instance_valid(art) or art.manifest.is_empty() or (_paused and not _art_open): return
	super._show_dialog("HOME · VISUAL DEVELOPMENT STUDY",
		"The same childhood scene and saved world. Lighting presets do not advance the calendar.\n\nOriginal procedural materials, cloth, foliage, pottery and costume/horse proxies. These are art studies, not a surveyed Gujranwala or authenticated garments.\n\nPresentation: %s · light: %s\nCloth samples the existing chapter clock and freezes here.\nContent SHA-256: %s" % ["study" if art.enabled else "retained greybox",art.preset,art.digest],
		[["Compare: study / retained greybox","art:toggle"],["Daylight","art:daylight"],["Golden hour","art:golden_hour"],["Evening","art:evening"],["Return to childhood","resume"]])
	_art_open=true

func _menu_action(action: String) -> void:
	if action.begins_with("art:"):
		if not _art_open: return
		var choice:=action.trim_prefix("art:")
		if choice=="toggle": art.set_enabled(not art.enabled)
		elif choice in ["daylight","golden_hour","evening"]: art.set_preset(choice)
		open_art_study();return
	super._menu_action(action)

func _resume() -> void:
	_art_open=false
	super._resume()

func _layout() -> void:
	# Clear stale child minimums BEFORE requesting a smaller window size.
	if is_instance_valid(_journal_scroll): _journal_scroll.custom_minimum_size=Vector2(220,110)
	if is_instance_valid(_panel_text): _panel_text.custom_minimum_size.x=200
	super._layout()
