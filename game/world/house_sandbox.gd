extends "res://world/command_sandbox.gd"
## Presentation only: reuses the existing command scene, player and authority.

const HouseCampaign := preload("res://campaign/house_command_state.gd")
const HOUSE_SAVE := "user://1792-house-conflict-v1.json"
var _scroll: ScrollContainer
var _field_sign: Label3D

func _init() -> void:
	campaign = HouseCampaign.new()
	_notice = "At the table: E opens commands and house politics. H opens the antagonist codex."

func _ready() -> void:
	super._ready()
	get_viewport().size_changed.connect(_layout_house_ui)
	_layout_house_ui()

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

func _build_ui() -> void:
	super._build_ui()
	# Keep inherited button dispatch, but make longer biographies scrollable.
	_modal.remove_child(_choices)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
	_scroll.custom_minimum_size = Vector2(width - 16.0, height - 16.0)
	for child in _choices.get_children():
		if child is Label:
			child.custom_minimum_size.x = maxf(220.0, width - 52.0)
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
	super._open_panel(title, description, actions)
	_layout_house_ui()
	_scroll.scroll_vertical = 0
	for child in _choices.get_children():
		if child is Button:
			child.grab_focus()
			break

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		_open_houses()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func _interact() -> void:
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
		"save", "load":
			var error := ""
			if action == "save":
				campaign.record_position(avatar.global_position)
				error = campaign.save_to(HOUSE_SAVE)
			else:
				error = campaign.load_from(HOUSE_SAVE)
				if error.is_empty():
					_apply_actor(true)
					_clock_accumulator = 0.0
			_notice = _message(error, "House-conflict session saved." if action == "save" else "House-conflict session loaded.")
			_close_panel()
			_refresh_hud()
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
	if not report.is_empty():
		var t: Dictionary = report.territory
		_journal.text += "\n\nHOUSE REPORT\nMilitary: %s\nPassage: %s\nRevenue: %s\nAnnexed: no" % [
			t.military_presence.replace("_", " "), t.passage, t.revenue_status.replace("_", " ")]
	elif p.phase == "resolved":
		_journal.text += "\n\nHouse consequences: report not yet received."
	if is_instance_valid(_field_sign):
		_field_sign.text = ""
		if not report.is_empty():
			_field_sign.text = report.territory.military_presence.replace("_", " ") + "\nPassage: " + report.territory.passage
		elif campaign.actor_id() == Campaign.CAPTAIN and campaign.near_site("outpost") and p.phase != "dormant":
			_field_sign.text = "Local revenue claim remains disputed\nYour commission: " + (p.decision.replace("_", " ") if p.decision != "" else "observation only")
