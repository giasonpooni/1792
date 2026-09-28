extends "res://world/command_sandbox.gd"
## Presentation only: reuses the existing command scene, player and authority.

const HouseCampaign := preload("res://campaign/house_command_state.gd")
const HorseScene := preload("res://mounts/horse.tscn")
const RidingRules := preload("res://mounts/riding_rules.gd")
const RIDING_SAVE := "user://1792-riding-v1.json"
const HOUSE_SAVE := "user://1792-house-conflict-v1.json"
var _scroll: ScrollContainer
var _field_sign: Label3D
var horse: CharacterBody3D
var _horse_label: Label3D
var _mount_requested := false
var _pending_load := ""

func _init() -> void:
	campaign = HouseCampaign.new()
	campaign.enable_riding()
	_notice = "E at the table: house politics and patrols. F at the horse: mount. H: antagonist codex."

func _ready() -> void:
	super._ready()
	get_viewport().size_changed.connect(_layout_house_ui)
	_layout_house_ui()
	avatar.get_node("CameraPivot/SpringArm3D").add_excluded_object(horse.get_rid())
	_apply_actor(true)

func _build_world() -> void:
	super._build_world()
	# Static envoy stand-in; no invented historical likeness or extra playable actor.
	_box(Vector3(0.65, 1.8, 0.65), Vector3(5, 0.9, -1), Color("a386ac"), true)
	_label("Kanhaiya envoy\n(fictional petition)", Vector3(5, 3, -1))
	_field_sign = Label3D.new()
	_field_sign.position = Vector3(20, 5, -60)
	_field_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_field_sign.font_size = 24
	add_child(_field_sign)
	horse = HorseScene.instantiate()
	add_child(horse)
	horse.apply_record(campaign.horse_state())
	# Hitching rail, not a historical reconstruction or new territory.
	_box(Vector3(0.18, 1.4, 0.18), Vector3(10.2, 0.7, -6.5), Color("624b39"), true)
	_box(Vector3(0.18, 1.4, 0.18), Vector3(10.2, 0.7, -3.5), Color("624b39"), true)
	_box(Vector3(0.18, 0.18, 3.2), Vector3(10.2, 1.1, -5), Color("624b39"), true)
	_horse_label = Label3D.new()
	_horse_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_horse_label.font_size = 24
	add_child(_horse_label)

func _build_ui() -> void:
	super._build_ui()
	# Keep inherited button dispatch, but make longer biographies scrollable.
	_modal.remove_child(_choices)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202827")
	style.border_color = Color("a58b62")
	style.set_border_width_all(2)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_modal.add_theme_stylebox_override("panel", style)
	_modal.add_child(_scroll)
	_scroll.add_child(_choices)
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _layout_house_ui() -> void:
	if not is_instance_valid(_scroll):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(740.0, maxf(280.0, viewport_size.x - 32.0))
	var height := minf(590.0, maxf(260.0, viewport_size.y - 48.0))
	_modal.custom_minimum_size = Vector2.ZERO
	_modal.size = Vector2(width, height)
	_modal.position = (viewport_size - _modal.size) * 0.5
	_scroll.custom_minimum_size = Vector2(width - 44.0, height - 36.0)
	for child in _choices.get_children():
		if child is Label:
			child.custom_minimum_size.x = maxf(220.0, width - 64.0)
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if child is Button:
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.size.x = maxf(250.0, viewport_size.x - 410.0)
	_journal.position = Vector2(maxf(18.0, viewport_size.x - 370.0), 20)
	_journal.size = Vector2(350, 420)
	if viewport_size.x < 900:
		_journal.position = Vector2(18, maxf(270.0, viewport_size.y - 220.0))
		_journal.size.x = viewport_size.x - 36.0

func _open_panel(title: String, description: String, actions: Array) -> void:
	if title == "Paused":
		actions = actions.duplicate(true)
		actions.insert(2, ["Load riding save", "load", ""])
		actions.insert(3, ["Import earlier house-conflict save", "import_house", ""])
		actions.insert(4, ["Import original command-story save", "import_command", ""])
	super._open_panel(title, description, actions)
	_layout_house_ui()
	_hud.hide()
	_journal.hide()
	_scroll.scroll_vertical = 0
	for child in _choices.get_children():
		if child is Button:
			child.grab_focus()
			break

func _close_panel() -> void:
	super._close_panel()
	_hud.show()
	_journal.show()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if not _modal.visible:
			_mount_requested = true # Spatial queries run in physics time, not input dispatch.
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		_open_houses()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact() -> void:
	if campaign.is_mounted():
		_notice = "Stop and press F to dismount before speaking or issuing orders."
		return
	super._interact()
	if campaign.actor_id() == Campaign.RANJIT and campaign.near_site("lahore_darbar") and _modal.visible:
		var button := Button.new()
		button.name = "HousePoliticsButton"
		button.text = "Houses / antagonist biographies"
		button.custom_minimum_size.y = 44
		button.pressed.connect(_open_houses)
		_choices.add_child(button)

func _perform(action: String, argument: String = "") -> void:
	match action:
		"houses":
			_open_houses()
			return
		"biography":
			_open_biography(argument)
			return
		"estate":
			_open_estate()
			return
		"petition":
			campaign.record_position(avatar.global_position)
			var error: String = campaign.petition(argument)
			_notice = _message(error, "House agreement updated; the current patrol keeps its identity and allocation.")
			_open_estate()
			_refresh_hud()
			return
		"save":
			campaign.record_position(avatar.global_position)
			var error: String = campaign.save_to(RIDING_SAVE)
			_notice = _message(error, "Riding, patrol and house decisions saved together.")
			_close_panel()
			_refresh_hud()
			return
		"load", "import_house", "import_command":
			_pending_load = RIDING_SAVE if action == "load" else HOUSE_SAVE if action == "import_house" else SAVE_PATH
			return
	super._perform(action, argument)

func _open_houses() -> void:
	var p: Dictionary = campaign.house_state()
	var options: Array = [["Estate petition / revise commission", "estate", ""]]
	for person in campaign.roster().people:
		options.append([person.name + "  ·  NPC / " + person.scenario_presence.replace("_", " "), "biography", person.id])
	options.append(["Return to the world", "close", ""])
	_open_panel("1792 · Houses and rivals", "ANTAGONIST CODEX — authored campaign biographies\n\nThese characters are not playable. Kinship, estates, appointments, patronage and command produce competing interests; shared faith or a surname never automatically declares war.\n\nOnly Sada Kaur's estate petition is interactive in this slice. The full development codex includes earlier/later profiles and may reveal story plans.\n\nCurrent Sada relationship: " + p.relations.sada_kaur.stance.replace("_", " "), options)

func _open_biography(id: String) -> void:
	var person: Dictionary = campaign.biography(id)
	if person.is_empty():
		_notice = "Unknown biography."
		return
	var body: String = "ANTAGONIST · NON-PLAYABLE\nChapter presence: %s\n\n%s\n\nObjective: %s\nLeverage: %s\n\nSOURCE NOTE\n%s" % [
		person.scenario_presence.replace("_", " "), person.biography, person.objective, person.leverage, person.source_note]
	_open_panel(person.name, body, [["Back to houses", "houses", ""], ["Close", "close", ""]])

func _open_estate() -> void:
	var p: Dictionary = campaign.house_state()
	var s: Dictionary = campaign.snapshot()
	var options: Array = []
	var body := "FICTIONAL 1801 DEVELOPMENT ENCOUNTER\n\nAn envoy asks that the road patrol recognize the Kanhaiya household's local revenue claim. Protection of a road is not ownership of its villages.\n\n"
	body += "Sada Kaur: " + p.relations.sada_kaur.stance.replace("_", " ") + "\nCommission: " + (p.decision.replace("_", " ") if p.decision != "" else "not settled")
	var can_negotiate: bool = campaign.actor_id() == Campaign.RANJIT and campaign.near_site("lahore_darbar") and s.order.status not in ["reporting", "completed"]
	if can_negotiate:
		match p.phase:
			"dormant":
				options.append(["Hear the envoy's estate petition", "petition", "begin"])
			"awaiting_response":
				options.append(["Recognize the local claim — joint patrol, no annexation", "petition", "respect_claim"])
				options.append(["Assert Lahore's authority — military presence, contested legitimacy", "petition", "assert_authority"])
				options.append(["Observe only — defer the claim and report", "petition", "defer"])
			"decided":
				if p.decision in ["assert_authority", "defer"]:
					options.append(["Reconcile: recognize the claim before the patrol resolves", "petition", "reconcile"])
	else:
		body += "\n\nNegotiation requires Ranjit at the table, before this patrol resolves."
	body += "\n\n" + _notice
	options.append(["Back to biographies", "houses", ""])
	options.append(["Close and continue patrol", "close", ""])
	_open_panel("Two claims to one road", body, options)

func _refresh_hud() -> void:
	super._refresh_hud()
	var p: Dictionary = campaign.house_state()
	_hud.text = _hud.text.replace("LAHORE COMMAND SANDBOX", "HOUSES AND RIVALS SANDBOX")
	_hud.text += "\nH: antagonist codex · Estate petition: " + p.phase.replace("_", " ")
	if p.phase != "dormant" and campaign.snapshot().order.status == "active" and p.decision in ["", "defer"]:
		_hud.text += "\nPatrol may observe, not secure. Settle the commission at Lahore or withdraw."
	var report: Dictionary = campaign.received_house_report()
	if not report.is_empty() and report.territory != null:
		var t: Dictionary = report.territory
		_journal.text += "\n\nHOUSE REPORT\nMilitary: %s\nPassage: %s\nRevenue: %s\nAnnexed: no" % [
			t.military_presence.replace("_", " "), t.passage, t.revenue_status.replace("_", " ")]
	elif not report.is_empty():
		_journal.text += "\n\nHOUSE REPORT\nTerritorial conditions: unknown\n(outpost not observed)."
	elif p.phase == "resolved":
		_journal.text += "\n\nHouse consequences: report not yet received."
	if is_instance_valid(_field_sign):
		_field_sign.text = ""
		if not report.is_empty() and report.territory != null:
			_field_sign.text = report.territory.military_presence.replace("_", " ") + "\nPassage: " + report.territory.passage
		elif campaign.actor_id() == Campaign.CAPTAIN and campaign.near_site("outpost") and p.phase != "dormant":
			_field_sign.text = "Local revenue claim remains disputed\nYour commission: " + (p.decision.replace("_", " ") if p.decision != "" else "observation only")

	if is_instance_valid(horse):
		var h: Dictionary = campaign.horse_state()
		if campaign.is_mounted():
			_hud.text = "1792 · HOUSES AND RIVALS · Riding prototype\n%s · Horse %.1f m/s\nW forward · A/D steer · Shift canter · Ctrl walk\nS / Space brake · F dismount when stopped · E speak on foot\nH houses · F5 save · F9 load · F1 menu\n\n%s" % [campaign.snapshot().actors[campaign.actor_id()].name, h.speed, _notice]
		else:
			_hud.text += "\nF near the household horse: mount · Horse stays where it is left."
		_horse_label.position = RidingRules.position(h) + Vector3.UP * 3.6
		_horse_label.text = "Household horse [F]\nPrototype mount" if not campaign.is_mounted() else ""


func _physics_process(delta: float) -> void:
	if not _pending_load.is_empty():
		var path := _pending_load
		_pending_load = ""
		_load_riding(path)
		return
	if _modal.visible:
		_mount_requested = false
		return
	if _mount_requested:
		_mount_requested = false
		_toggle_mount()
	if campaign.is_mounted():
		var controls: bool = avatar.get("input_enabled")
		var throttle := Input.get_action_strength("move_forward") if controls else 0.0
		var steer := Input.get_axis("move_left", "move_right") if controls else 0.0
		var brake := not controls or Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_SPACE)
		var motion: Dictionary = horse.step(delta, throttle, steer, Input.is_action_pressed("sprint"), Input.is_key_pressed(KEY_CTRL), brake)
		var error: String = campaign.record_ride(motion, delta)
		if not error.is_empty():
			horse.apply_record(campaign.horse_state())
			_notice = error
		avatar.global_position = campaign.actor_position(campaign.actor_id())
	else:
		campaign.record_position(avatar.global_position)
	_clock_accumulator += delta
	while _clock_accumulator >= 0.5:
		_clock_accumulator -= 0.5
		campaign.advance()
	_apply_actor()
	_refresh_hud()

func _apply_actor(force: bool = false) -> void:
	var changed: bool = force or _shown_actor != campaign.actor_id()
	super._apply_actor(force)
	if not is_instance_valid(horse):
		return
	if changed:
		horse.apply_record(campaign.horse_state())
	var mounted: bool = campaign.is_mounted()
	avatar.set_physics_process(not mounted)
	avatar.collision_layer = 0 if mounted else 1
	avatar.collision_mask = 0 if mounted else 1
	avatar.get_node("MeshInstance3D").visible = not mounted
	avatar.get_node("CameraPivot").position.y = 2.5 if mounted else 1.4
	avatar.get_node("CameraPivot/SpringArm3D").spring_length = 6.8 if mounted else 5.5

func _toggle_mount() -> void:
	if _modal.visible:
		return
	var error := ""
	if campaign.is_mounted():
		var h: Dictionary = campaign.horse_state()
		if h.speed > RidingRules.DISMOUNT_SPEED or not h.grounded:
			error = "Stop on solid ground before dismounting (S or Space to brake)."
		else:
			var landing = horse.dismount_position(avatar)
			error = "No clear ground beside the horse. Move to an open space." if landing == null else campaign.dismount_horse(landing)
	else:
		campaign.record_position(avatar.global_position)
		if not horse.clear_mount_path(avatar):
			error = "A wall blocks the way to the horse."
		else:
			error = campaign.mount_horse()
	_notice = _message(error, "Mounted. W forward, A/D steer, Shift canter; S/Space brake." if campaign.is_mounted() else "Dismounted. Your horse stays here.")
	if error.is_empty():
		_apply_actor(true)
	_refresh_hud()

func _load_riding(path: String) -> void:
	# Stage and spatially validate BEFORE touching the live authority or body.
	var staged = HouseCampaign.new()
	staged.enable_riding()
	var error: String = staged.load_from(path)
	if error.is_empty() and not horse.record_fits_world(staged.horse_state(), avatar):
		error = "Saved horse pose intersects scenery or lacks ground; current session unchanged."
	if error.is_empty():
		error = campaign.restore(staged.snapshot())
	if error.is_empty():
		_apply_actor(true)
		_mount_requested = false
		_clock_accumulator = 0.0
	_notice = _message(error, "Loaded. Horse, rider, patrol and house decisions restored.")
	_close_panel()
	_refresh_hud()
