# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/gujranwala_chapter.gd"
## Research presentation and water-task input adapter; the inherited state remains authoritative.
const Fabric := preload("res://reconstruction/district_fabric.gd")
const Narrator := preload("res://narrative/shah_observer.gd")
const Water := preload("res://territory/water_round_rules.gd")
const WaterView := preload("res://territory/water_round_view.gd")
var water_view: Node3D
var _water_action := ""
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
	water_view=WaterView.new()
	water_view.name="HouseholdWaterView"
	add_child(water_view)
	water_view.build(avatar)

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
	_sync_water()

func _refresh() -> void:
	super._refresh()
	if is_instance_valid(fabric): fabric.update_from_tick(int(model.progress().tick))
	if is_instance_valid(_narrator_label):
		_narrator_label.text=narrator.observe(model.snapshot())
		_narrator_label.visible=not _paused and not _narrator_label.text.is_empty()
	if is_instance_valid(_hud):
		_hud.text+="\nF2: reconstruction notebook (development reference)"
		if model.has_economy(): _hud.text+="\n"+WaterView.status(model.water_round(),int(model.progress().tick))
	_sync_water()

func _sync_water() -> void:
	if is_instance_valid(avatar):
		avatar.external_speed_limit=Water.CARRY_SPEED if model.has_water_round() and model.water_round().ledger.carried>0 else INF
	if is_instance_valid(water_view): water_view.sample(model.water_round(),int(model.progress().tick))

func _clear_pending_actions() -> void:
	super._clear_pending_actions()
	_water_action=""

func _menu_action(action: String) -> void:
	if action.begins_with("water:"):
		_water_action=action.trim_prefix("water:")
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _water_action.is_empty():
		var action:=_water_action
		_water_action=""
		var error: String=model.begin_water_round() if action=="begin" else model.water_action(action)
		_message=error if not error.is_empty() else "Household water round · "+action+" recorded."
		_sync_water()
		_resume()
		return
	super._physics_process(delta)

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.mounted() and Water.near_site(model.position(),Water.WELL):
		if not _seen(Water.WELL+Vector3.UP*1.4,4.5):
			_message="Face the well from an unobstructed position."
			return
		var actions: Array=[]
		if model.has_water_round():
			match model.water_round().ledger.phase:
				"ready": actions.append(["Draw one load · 180 existing ticks / 3 abstract units","water:draw"])
				"drawing": actions.append(["Cancel this draw · no water consumed","water:cancel"])
		actions.append(["Return","resume"])
		_show_dialog("WELL · HOUSEHOLD WATER ROUND",WaterView.status(model.water_round(),int(model.progress().tick))+"\n\nAssigned task quantities, not litres, water safety or a measured well yield. Water is transferred once the draw finishes; money and historical knowledge do not change.",actions)
		return
	super._interact()

func _open_quartermaster() -> void:
	super._open_quartermaster()
	if not model.has_economy(): return
	var action: String=""
	var text: String=""
	if not model.has_water_round():
		action="begin"
		text="Accept household water round · two loads from the east-side well"
	elif model.water_round().ledger.phase=="carrying":
		action="deposit"
		text="Deposit carried water into the household vessel"
	if action.is_empty(): return
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("water:"+action))
	_actions.add_child(button)
	_actions.move_child(button,0)
	button.grab_focus()

func _account_text() -> String:
	return super._account_text()+"\n\n"+WaterView.status(model.water_round(),int(model.progress().tick))+"\nThis finite round does not yet model recurring household water consumption."
