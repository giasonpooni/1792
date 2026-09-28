extends "res://mahan/mahan_history_chapter.gd"
## Gujranwala ridge->settlement authored encounter presentation (greybox + historical frame).
const EncounterModel := preload("res://mahan/mahan_encounter_state.gd")

func _ready() -> void:
	# Allow settlement (or other) adapters to install their model before super._ready().
	if campaign == null or not campaign.has_method("examine_settlement_marker"):
		campaign = EncounterModel.new()
	campaign.enable_riding()
	super._ready()
	_marker(EncounterModel.ENCOUNTER_MARKER, Color("c47a3a"), "Approach encounter")
	_notice = "E at the table for scouts, counsel, orders, history, or the Gujranwala approach encounter. F to mount. Choices stay inside the fixed endpoint."

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	var pending_e: int = campaign.pending_encounter_reports().size()
	var known_n: int = campaign.known_historical_events().size()
	var enc: Dictionary = campaign.encounter()
	var enc_label := "resolved (%s)" % enc.choice if enc.resolved else ("active" if enc.active else "available on Gujranwala approach")
	var body := "Column at: %s | Provisions: %d | Disposition: %s | March: %s\nPending pursuit: %d | Pending historical reports: %d | Known historical frames: %d\nRidge->settlement encounter: %s | Pending approach scout: %d\nWalk/ride to Gujranwala fort road / camp / settlement, then open the authored encounter stub (no combat AI)." % [
		node, campaign.provisions(), campaign.disposition(), willing,
		pending_p, pending_h, known_n, enc_label, pending_e
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in EncounterModel.ADJACENT[node]:
			actions.append(["March column to %s (-%d provisions)" % [nxt, EncounterModel.MARCH_COST], "march_%s" % nxt])
		actions.append(["Issue subordinate orders (scout / hold rear / pursue)", "open_orders"])
	if node in EncounterModel.ENCOUNTER_NODES or enc.active:
		actions.append(["Open ridge->settlement encounter stub", "open_encounter"])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append(["Consult historical frames (observe / report)", "open_history"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _open_encounter_panel() -> void:
	var enc: Dictionary = campaign.encounter()
	var pending_e: int = campaign.pending_encounter_reports().size()
	var received_e: int = campaign.received_encounter_reports().size()
	var body := "Authored Gujranwala ridge->settlement encounter (greybox + historical-event frame).\nActive: %s | Resolved: %s | Choice: %s\nApproach scout pending: %d | Delivered: %d (delay %d ticks).\nHold/observe or advance under custody - both keep the fixed historical endpoint. No combat AI; no alternate-history win." % [
		str(enc.active), str(enc.resolved), enc.choice if enc.choice != "" else "(none)",
		pending_e, received_e, EncounterModel.ENCOUNTER_DELAY
	]
	var actions: Array = []
	if not enc.resolved:
		actions.append(["Hold and observe the approach", "encounter_hold_observe"])
		actions.append(["Dispatch delayed approach scout", "encounter_dispatch_scout"])
		actions.append(["Advance under delivered custody", "encounter_advance_custody"])
	actions.append(["Cancel", "close"])
	_open_panel("Ridge->settlement encounter", body, actions)

func _open_history_panel() -> void:
	var known: Array = campaign.known_historical_events()
	var known_labels: PackedStringArray = PackedStringArray()
	for event in known:
		known_labels.append(str(event.event_id))
	var known_txt := "none" if known_labels.is_empty() else ", ".join(known_labels)
	var pending_h: int = campaign.pending_historical_reports().size()
	var body := "Authored historical stubs (game-canon vs source-class marked in data).\nKnown to player: %s\nPending delayed historical reports: %d\nObserve only if you are a direct observer; otherwise request a courier report. Fixed death becomes known only via endpoint acknowledgement.\nRidge->settlement encounter frame: mahan_gujranwala_ridge_settlement_approach." % [
		known_txt, pending_h
	]
	var actions: Array = []
	actions.append(["Observe late-campaign illness frame", "observe_illness"])
	actions.append(["Observe Gujranwala home-ground frame", "observe_home_ground"])
	actions.append(["Observe ridge->settlement approach frame", "observe_approach"])
	actions.append(["Request delayed illness report (courier)", "request_illness_report"])
	actions.append(["Cancel", "close"])
	_open_panel("Historical frames", body, actions)

func _perform(action: String) -> void:
	match action:
		"open_encounter":
			var err_open: String = campaign.begin_ridge_settlement_encounter()
			if not err_open.is_empty() and not campaign.encounter().active and not campaign.encounter().resolved:
				_notice = err_open
				_close()
				return
			_open_encounter_panel()
			return
		"encounter_hold_observe":
			var err: String = campaign.resolve_encounter_choice("hold_observe")
			_notice = "Held and observed the Gujranwala approach (fixed endpoint unchanged)." if err.is_empty() else err
			_close()
			return
		"encounter_dispatch_scout":
			var err2: String = campaign.dispatch_approach_scout()
			_notice = "Approach scout dispatched; custody arrives after delay." if err2.is_empty() else err2
			_close()
			return
		"encounter_advance_custody":
			var err3: String = campaign.resolve_encounter_choice("advance_under_custody")
			_notice = "Advanced under delivered approach custody (no alternate-history win)." if err3.is_empty() else err3
			_close()
			return
		"observe_approach":
			var err4: String = campaign.observe_historical_event("mahan_gujranwala_ridge_settlement_approach")
			_notice = "Ridge->settlement approach frame observed (authored fiction)." if err4.is_empty() else err4
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var enc: Dictionary = campaign.encounter()
	var pending_e: int = campaign.pending_encounter_reports().size()
	var label := "resolved/%s" % enc.choice if enc.resolved else ("active" if enc.active else "idle")
	_hud.text += "\nEncounter: %s | pending approach scout %d | marker on fort-road approach" % [
		label, pending_e
	]
