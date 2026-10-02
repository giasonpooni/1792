extends "res://mahan/mahan_settlement_chapter.gd"
## Gujranwala garhi (fort) landmark observation presentation (greybox + delayed report).
const GarhiModel := preload("res://mahan/mahan_garhi_state.gd")

func _ready() -> void:
	campaign = GarhiModel.new()
	campaign.enable_riding()
	super._ready()
	for kind in GarhiModel.GARHI_MARKERS:
		_marker(GarhiModel.GARHI_MARKERS[kind], Color("6a4a2a"), "Garhi %s" % kind)
	_notice = "E at the table for scouts, counsel, orders, history, encounter, settlement, or Gujranwala garhi landmark. F to mount. Sealed facts are not omniscience."

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	var pending_e: int = campaign.pending_encounter_reports().size()
	var pending_s: int = campaign.pending_settlement_rumors().size()
	var pending_g: int = campaign.pending_garhi_reports().size()
	var known_n: int = campaign.known_historical_events().size()
	var enc: Dictionary = campaign.encounter()
	var sett: Dictionary = campaign.settlement()
	var g: Dictionary = campaign.garhi()
	var enc_label := "resolved (%s)" % enc.choice if enc.resolved else ("active" if enc.active else "available on Gujranwala approach")
	var examined_n: int = sett.examined.size()
	var examined_g: int = g.examined.size()
	var body := "Column at: %s | Provisions: %d | Disposition: %s | March: %s\nPending pursuit: %d | Pending historical reports: %d | Known historical frames: %d\nRidge->settlement encounter: %s | Pending approach scout: %d\nSettlement observation: examined %d/4 | Pending local rumor: %d\nGarhi landmark: examined %d/3 | Pending delayed report: %d\nWalk/ride to settlement or fort road (or after advance under custody), then examine greybox markers (no combat)." % [
		node, campaign.provisions(), campaign.disposition(), willing,
		pending_p, pending_h, known_n, enc_label, pending_e, examined_n, pending_s, examined_g, pending_g
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in GarhiModel.ADJACENT[node]:
			actions.append(["March column to %s (-%d provisions)" % [nxt, GarhiModel.MARCH_COST], "march_%s" % nxt])
		actions.append(["Issue subordinate orders (scout / hold rear / pursue)", "open_orders"])
	if node in GarhiModel.ENCOUNTER_NODES or enc.active:
		actions.append(["Open ridge->settlement encounter stub", "open_encounter"])
	var unlock_settlement: bool = (node == GarhiModel.SETTLEMENT_NODE) or (enc.resolved and str(enc.choice) == "advance_under_custody")
	if unlock_settlement or examined_n > 0 or pending_s > 0 or campaign.settlement_fact_known(GarhiModel.FACT_LOCAL_WORD):
		actions.append(["Open Gujranwala settlement observation", "open_settlement"])
	var unlock_garhi: bool = unlock_settlement or (node == GarhiModel.FORT_ROAD_NODE) or examined_g > 0 or pending_g > 0 or campaign.garhi_fact_known(GarhiModel.FACT_GARHI_WORD)
	if unlock_garhi:
		actions.append(["Open Gujranwala garhi landmark observation", "open_garhi"])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append(["Consult historical frames (observe / report)", "open_history"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _open_garhi_panel() -> void:
	var g: Dictionary = campaign.garhi()
	var pending_g: int = campaign.pending_garhi_reports().size()
	var received_g: int = campaign.received_garhi_reports().size()
	var known_word := "yes" if campaign.garhi_fact_known(GarhiModel.FACT_GARHI_WORD) else "no"
	var examined := ",".join(PackedStringArray(g.examined)) if not g.examined.is_empty() else "(none)"
	var body := "Gujranwala garhi landmark observation (place gujranwala_garhi; household sukerchakia).\nExamined markers: %s\nGarhi word known: %s | Pending report: %d | Delivered: %d (delay %d ticks).\nExamine rampart/gatehouse/bastion - sealed attributed facts, not a fort plan. No combat AI; no siege map; fixed endpoint unchanged." % [
		examined, known_word, pending_g, received_g, GarhiModel.GARHI_DELAY
	]
	var actions: Array = []
	for kind in GarhiModel.GARHI_MARKERS:
		if kind not in g.examined:
			actions.append(["Examine garhi %s" % kind, "garhi_examine_%s" % kind])
	if g.reports.is_empty() and not campaign.garhi_fact_known(GarhiModel.FACT_GARHI_WORD):
		actions.append(["Request delayed garhi landmark report", "garhi_request_report"])
	actions.append(["Cancel", "close"])
	_open_panel("Garhi landmark observation", body, actions)

func _perform(action: String) -> void:
	match action:
		"open_garhi":
			var err_open: String = campaign.garhi_observation_available()
			if not err_open.is_empty() and campaign.examined_garhi_markers().is_empty() and campaign.pending_garhi_reports().is_empty() and not campaign.garhi_fact_known(GarhiModel.FACT_GARHI_WORD):
				_notice = err_open
				_close()
				return
			_open_garhi_panel()
			return
		"garhi_examine_rampart", "garhi_examine_gatehouse", "garhi_examine_bastion":
			var kind := action.trim_prefix("garhi_examine_")
			var err: String = campaign.examine_garhi_marker(kind)
			_notice = "Examined garhi %s (sealed attributed observation)." % kind if err.is_empty() else err
			_close()
			return
		"garhi_request_report":
			var err2: String = campaign.request_delayed_garhi_report()
			_notice = "Garhi landmark report requested; custody arrives after delay." if err2.is_empty() else err2
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var g: Dictionary = campaign.garhi()
	var pending_g: int = campaign.pending_garhi_reports().size()
	var known_word := "known" if campaign.garhi_fact_known(GarhiModel.FACT_GARHI_WORD) else "sealed"
	_hud.text += "\nGarhi: examined %d/3 | landmark word %s | pending report %d" % [
		g.examined.size(), known_word, pending_g
	]
