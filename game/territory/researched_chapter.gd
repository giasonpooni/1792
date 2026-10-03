# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://territory/gujranwala_chapter.gd"
## Research presentation and water-task input adapter; the inherited state remains authoritative.
const Fabric := preload("res://reconstruction/district_fabric.gd")
const Narrator := preload("res://narrative/shah_observer.gd")
const Water := preload("res://territory/water_round_rules.gd")
const WaterView := preload("res://territory/water_round_view.gd")
const WaterStory := preload("res://territory/water_round_story.gd")
var water_view: Node3D
var _water_action := ""
var _water_choices: Array[String] = []
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
	_water_choices.clear()
	_water_action=""
	super._show_dialog(title,body,actions)
	if is_instance_valid(_narrator_label): _narrator_label.hide()

func _open_journal() -> void:
	_water_choices.clear()
	_water_action=""
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
	_water_choices.clear()

func _resume() -> void:
	_water_choices.clear()
	_water_action=""
	super._resume()

func _menu_action(action: String) -> void:
	if action.begins_with("water:"):
		var kind := action.trim_prefix("water:")
		if _paused and kind in _water_choices and _water_action.is_empty(): _water_action=kind
		return
	super._menu_action(action)

func _physics_process(delta: float) -> void:
	if not _water_action.is_empty():
		var action:=_water_action
		_water_action=""
		if not _paused or action not in _water_choices: return
		var error := "Return to the well or quartermaster and face the task before continuing."
		var site := Water.STORE if action in ["begin", "deposit"] else Water.WELL
		if _water_contact(site): error = model.begin_water_round() if action=="begin" else model.water_action(action)
		_message=error if not error.is_empty() else WaterStory.action_line(action,model.water_round())
		_sync_water()
		_resume()
		return
	# Only a live clock transition gets a completion beat. Rebinding a loaded or
	# fixture-mutated ledger refreshes the props, without replaying a false event.
	var before: Dictionary = model.water_round()
	var prior_tick: int = int(model.progress().tick)
	var was_paused := _paused
	super._physics_process(delta)
	if was_paused or _paused or int(model.progress().tick) != prior_tick + 1 or before.is_empty(): return
	var after: Dictionary = model.water_round()
	if after.is_empty() or before.ledger.phase != "drawing": return
	if after.ledger.phase == "carrying":
		_message = WaterStory.filled_line(after)
		_refresh()
	elif after.ledger.phase == "ready":
		_message = "Buddh · I have left the rope. That draw will have to begin again."
		_refresh()

func _water_contact(site: Vector3) -> bool:
	if site == Water.STORE: return _economy_contact(site)
	return not model.mounted() and avatar.is_on_floor() and avatar.global_position.distance_to(model.position()) <= 0.25 and Water.near_site(model.position(),site) and _seen(site+Vector3.UP*1.4,4.5)

func _interact() -> void:
	if model.aftermath_phase()=="complete" and not model.mounted() and Water.near_site(model.position(),Water.WELL):
		if not _seen(Water.WELL+Vector3.UP*1.4,4.5):
			_message="Face the well from an unobstructed position."
			return
		var actions: Array=[]
		var choices: Array[String]=[]
		if model.has_water_round():
			match model.water_round().ledger.phase:
				"ready":
					actions.append(["Draw one load","water:draw"])
					choices.append("draw")
				"drawing":
					actions.append(["Cancel this draw","water:cancel"])
					choices.append("cancel")
		actions.append(["Return","resume"])
		_show_dialog("THE EAST WELL",WaterStory.well_body(model.water_round()),actions)
		_water_choices.assign(choices)
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
	_water_choices.assign([action])
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size.y=42
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_menu_action.bind("water:"+action))
	_actions.add_child(button)
	_actions.move_child(button,0)
	button.grab_focus()

func _account_text() -> String:
	return super._account_text()+"\n\n"+WaterView.status(model.water_round(),int(model.progress().tick))+"\nWATER ACCOUNT · Six assigned units, carried in loads of three; not litres, water safety or measured well yield. Each draw uses 180 existing simulation ticks. The finite task does not model recurring consumption or grant money. Scene dialogue is original authored fiction."
