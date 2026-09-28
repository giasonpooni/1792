extends "res://mahan/mahan_orders_chapter.gd"
## Mahan historical-event presentation: known frames only after observe / delayed delivery / endpoint ack.
const HistoryModel := preload("res://mahan/mahan_history_state.gd")

func _ready() -> void:
	# Allow encounter (or other) adapters to install their model before super._ready().
	if campaign == null or not campaign.has_method("begin_ridge_settlement_encounter"):
		campaign = HistoryModel.new()
	campaign.enable_riding()
	super._ready()
	_notice = "E at the table for scouts, counsel, orders, or historical frames. F to mount. Known history appears only after observation or delivery."

func _open_dispatch_panel() -> void:
	var known_n: int = campaign.known_historical_events().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	var lines := "Dispatch a scout detachment. The report is not knowledge until it arrives (delay %d ticks).\nProvisions: %d · Foraged: %s · Disposition: %s\nHistorical frames known: %d · Pending historical reports: %d (authored stubs; not primary-source quotes)." % [
		HistoryModel.REPORT_DELAY, campaign.provisions(),
		_foraged_label(), campaign.disposition(), known_n, pending_h
	]
	var actions: Array = []
	for target in HistoryModel.scout_targets():
		actions.append(["Scout the %s (−%d provisions)" % [HistoryModel.node_label(target), HistoryModel.DISPATCH_COST], "dispatch_%s" % target])
	actions.append(["Consult subordinates (hold vs advance counsel)", "consult"])
	actions.append(["Request household word (delayed clan-house rumor)", "request_word"])
	actions.append(["Consult historical frames (observe / report)", "open_history"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Cancel", "close"])
	_open_panel("Scout dispatch", lines, actions)

func _open_history_panel() -> void:
	var known: Array = campaign.known_historical_events()
	var known_labels: PackedStringArray = PackedStringArray()
	for event in known:
		known_labels.append(str(event.event_id))
	var known_txt := "none" if known_labels.is_empty() else ", ".join(known_labels)
	var pending_h: int = campaign.pending_historical_reports().size()
	var body := "Authored historical stubs (game-canon vs source-class marked in data).\nKnown to player: %s\nPending delayed historical reports: %d\nObserve only if you are a direct observer; otherwise request a courier report. Fixed death becomes known only via endpoint acknowledgement." % [
		known_txt, pending_h
	]
	var actions: Array = []
	actions.append(["Observe late-campaign illness frame", "observe_illness"])
	actions.append(["Observe Gujranwala home-ground frame", "observe_home_ground"])
	actions.append(["Request delayed illness report (courier)", "request_illness_report"])
	actions.append(["Cancel", "close"])
	_open_panel("Historical frames", body, actions)

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	var known_n: int = campaign.known_historical_events().size()
	var body := "Column at: %s · Provisions: %d · Disposition: %s · March: %s\nPending pursuit: %d · Pending historical reports: %d · Known historical frames: %d\nWalk/ride to an adjacent authored node, dismount, then commit the march, issue subordinate orders, or consult historical frames." % [
		node, campaign.provisions(), campaign.disposition(), willing,
		pending_p, pending_h, known_n
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in HistoryModel.ADJACENT[node]:
			actions.append(["March column to %s (−%d provisions)" % [nxt, HistoryModel.MARCH_COST], "march_%s" % nxt])
		actions.append(["Issue subordinate orders (scout / hold rear / pursue)", "open_orders"])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append(["Consult historical frames (observe / report)", "open_history"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _interact() -> void:
	if campaign.is_mounted():
		_notice = "Dismount (F when stopped) before orders, counsel, forage, historical frames, or marker interactions."
		return
	campaign.record_position(avatar.global_position, 1.0 / 60.0)
	match campaign.stage():
		"decision":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table once scout custody has been delivered."
				return
			var body := "Delivered scout reports: %d. Pending: %d. Pending household word: %d.\nProvisions: %d · Disposition: %s · Consulted: %s\nKnown historical frames: %d · Pending historical reports: %d\nSubordinate counsel and authored historical stubs do not rewrite Mahan's fixed endpoint." % [
				campaign.received_reports().size(), campaign.pending_reports().size(),
				campaign.pending_rumors().size(), campaign.provisions(), campaign.disposition(),
				"yes" if campaign.consulted() else "no",
				campaign.known_historical_events().size(), campaign.pending_historical_reports().size()
			]
			_open_panel("Column order", body, [
				["Consult subordinates (hold vs advance)", "consult"],
				["Request household word (delayed rumor)", "request_word"],
				["Consult historical frames (observe / report)", "open_history"],
				["Advance the horse column", "advance_scouts"],
				["Hold the column for corroboration", "hold_for_corroboration"],
				["Dispatch another scout", "open_dispatch"],
				[_forage_action_label(), "forage"],
				["Cancel", "close"]
			])
		_:
			super._interact()

func _perform(action: String) -> void:
	match action:
		"open_history":
			_open_history_panel()
			return
		"observe_illness":
			var err: String = campaign.observe_historical_event("mahan_late_campaign_illness")
			_notice = "Late-campaign illness frame observed (authored / game-canon)." if err.is_empty() else err
			_close()
			return
		"observe_home_ground":
			var err_h: String = campaign.observe_historical_event("mahan_gujranwala_home_ground")
			_notice = "Gujranwala home-ground frame observed (reconstructed / game-canon)." if err_h.is_empty() else err_h
			_close()
			return
		"request_illness_report":
			var err2: String = campaign.request_historical_report("mahan_late_campaign_illness")
			_notice = "Historical courier sent; frame arrives after delay." if err2.is_empty() else err2
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var known_n: int = campaign.known_historical_events().size()
	var pending_h: int = campaign.pending_historical_reports().size()
	_hud.text += "\nHistory: known frames %d · pending reports %d · catalog stubs (Mahan-scoped)" % [
		known_n, pending_h
	]
