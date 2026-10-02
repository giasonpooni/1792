extends "res://mahan/mahan_encounter_chapter.gd"
## Gujranwala settlement observation presentation (greybox markers + delayed local rumor).
const SettlementModel := preload("res://mahan/mahan_settlement_state.gd")

func _ready() -> void:
	# Allow garhi (or other) adapters to install their model before super._ready().
	if campaign == null or not campaign.has_method("examine_garhi_marker"):
		campaign = SettlementModel.new()
	campaign.enable_riding()
	super._ready()
	for kind in SettlementModel.SETTLEMENT_MARKERS:
		_marker(SettlementModel.SETTLEMENT_MARKERS[kind], Color("8a6b3a"), "Settlement %s" % kind)
	_notice = "E at the table for scouts, counsel, orders, history, encounter, or Gujranwala settlement observation. F to mount. Sealed facts are not omniscience."

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	var pending_e: int = campaign.pending_encounter_reports().size()
	var pending_s: int = campaign.pending_settlement_rumors().size()
	var known_n: int = campaign.known_historical_events().size()
	var enc: Dictionary = campaign.encounter()
	var sett: Dictionary = campaign.settlement()
	var enc_label := "resolved (%s)" % enc.choice if enc.resolved else ("active" if enc.active else "available on Gujranwala approach")
	var examined_n: int = sett.examined.size()
	var body := "Column at: %s | Provisions: %d | Disposition: %s | March: %s\nPending pursuit: %d | Pending historical reports: %d | Known historical frames: %d\nRidge->settlement encounter: %s | Pending approach scout: %d\nSettlement observation: examined %d/4 | Pending local rumor: %d\nWalk/ride to Gujranwala settlement (or after advance under custody), then examine greybox markers (no town sim)." % [
		node, campaign.provisions(), campaign.disposition(), willing,
		pending_p, pending_h, known_n, enc_label, pending_e, examined_n, pending_s
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in SettlementModel.ADJACENT[node]:
			actions.append(["March column to %s (-%d provisions)" % [nxt, SettlementModel.MARCH_COST], "march_%s" % nxt])
		actions.append(["Issue subordinate orders (scout / hold rear / pursue)", "open_orders"])
	if node in SettlementModel.ENCOUNTER_NODES or enc.active:
		actions.append(["Open ridge->settlement encounter stub", "open_encounter"])
	var unlock_settlement: bool = (node == SettlementModel.SETTLEMENT_NODE) or (enc.resolved and str(enc.choice) == "advance_under_custody")
	if unlock_settlement or examined_n > 0 or pending_s > 0 or campaign.settlement_fact_known(SettlementModel.FACT_LOCAL_WORD):
		actions.append(["Open Gujranwala settlement observation", "open_settlement"])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append(["Consult historical frames (observe / report)", "open_history"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _open_settlement_panel() -> void:
	var sett: Dictionary = campaign.settlement()
	var pending_s: int = campaign.pending_settlement_rumors().size()
	var received_s: int = campaign.received_settlement_rumors().size()
	var known_word := "yes" if campaign.settlement_fact_known(SettlementModel.FACT_LOCAL_WORD) else "no"
	var examined := ",".join(PackedStringArray(sett.examined)) if not sett.examined.is_empty() else "(none)"
	var body := "Gujranwala settlement observation greybox (place object; household sukerchakia).\nExamined markers: %s\nLocal hearth-word known: %s | Pending rumor: %d | Delivered: %d (delay %d ticks).\nExamine walls/gate/well/house - sealed attributed facts, not omniscience. No combat AI; no town economy; fixed endpoint unchanged." % [
		examined, known_word, pending_s, received_s, SettlementModel.SETTLEMENT_DELAY
	]
	var actions: Array = []
	for kind in SettlementModel.SETTLEMENT_MARKERS:
		if kind not in sett.examined:
			actions.append(["Examine settlement %s" % kind, "settlement_examine_%s" % kind])
	if sett.rumors.is_empty() and not campaign.settlement_fact_known(SettlementModel.FACT_LOCAL_WORD):
		actions.append(["Request delayed local settlement word", "settlement_request_rumor"])
	actions.append(["Cancel", "close"])
	_open_panel("Settlement observation", body, actions)

func _perform(action: String) -> void:
	match action:
		"open_settlement":
			var err_open: String = campaign.settlement_observation_available()
			if not err_open.is_empty() and campaign.examined_markers().is_empty() and campaign.pending_settlement_rumors().is_empty() and not campaign.settlement_fact_known(SettlementModel.FACT_LOCAL_WORD):
				_notice = err_open
				_close()
				return
			_open_settlement_panel()
			return
		"settlement_examine_walls", "settlement_examine_gate", "settlement_examine_well", "settlement_examine_house":
			var kind := action.trim_prefix("settlement_examine_")
			var err: String = campaign.examine_settlement_marker(kind)
			_notice = "Examined settlement %s (sealed attributed observation)." % kind if err.is_empty() else err
			_close()
			return
		"settlement_request_rumor":
			var err2: String = campaign.request_local_settlement_rumor()
			_notice = "Local settlement word requested; custody arrives after delay." if err2.is_empty() else err2
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var sett: Dictionary = campaign.settlement()
	var pending_s: int = campaign.pending_settlement_rumors().size()
	var known_word := "known" if campaign.settlement_fact_known(SettlementModel.FACT_LOCAL_WORD) else "sealed"
	_hud.text += "\nSettlement: examined %d/4 | local word %s | pending rumor %d" % [
		sett.examined.size(), known_word, pending_s
	]
