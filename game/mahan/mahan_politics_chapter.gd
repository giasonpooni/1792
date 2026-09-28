extends "res://mahan/mahan_logistics_chapter.gd"
## Mahan politics presentation: subordinate counsel, delayed household rumor, march willingness.
const PoliticsModel := preload("res://mahan/mahan_politics_state.gd")

func _ready() -> void:
	campaign = PoliticsModel.new()
	campaign.enable_riding()
	super._ready()
	_notice = "E at the table for scouts, subordinate counsel, or household word. F to mount. Forage when packs have room."

func _open_dispatch_panel() -> void:
	var lines := "Dispatch a scout detachment. The report is not knowledge until it arrives (delay %d ticks).\nProvisions: %d · Foraged: %s · Disposition: %s\nHousehold word arrives on its own delay clock (%d ticks), like scout custody." % [
		PoliticsModel.REPORT_DELAY, campaign.provisions(),
		_foraged_label(), campaign.disposition(), PoliticsModel.POLITICS_DELAY
	]
	var actions: Array = []
	actions.append(["Scout the ford approach (−%d provisions)" % PoliticsModel.DISPATCH_COST, "dispatch_ford"])
	actions.append(["Scout the ridge approach (−%d provisions)" % PoliticsModel.DISPATCH_COST, "dispatch_ridge"])
	actions.append(["Consult subordinates (hold vs advance counsel)", "consult"])
	actions.append(["Request household word (delayed clan-house rumor)", "request_word"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Cancel", "close"])
	_open_panel("Scout dispatch", lines, actions)

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var body := "Column at: %s · Provisions: %d · Disposition: %s · March: %s\nWalk/ride to an adjacent authored node, dismount, then commit the march.\nStockout and strained politics can each block march; forage or acknowledge pressure as needed." % [
		node, campaign.provisions(), campaign.disposition(), willing
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in PoliticsModel.ADJACENT[node]:
			actions.append(["March column to %s (−%d provisions)" % [nxt, PoliticsModel.MARCH_COST], "march_%s" % nxt])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _interact() -> void:
	if campaign.is_mounted():
		_notice = "Dismount (F when stopped) before orders, counsel, forage, or marker interactions."
		return
	campaign.record_position(avatar.global_position, 1.0 / 60.0)
	match campaign.stage():
		"decision":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table once scout custody has been delivered."
				return
			var body := "Delivered scout reports: %d. Pending: %d. Pending household word: %d.\nProvisions: %d · Disposition: %s · Consulted: %s\nSubordinate counsel and delayed household rumor affect march willingness; they do not rewrite Mahan's fixed endpoint or house_command_state." % [
				campaign.received_reports().size(), campaign.pending_reports().size(),
				campaign.pending_rumors().size(), campaign.provisions(), campaign.disposition(),
				"yes" if campaign.consulted() else "no"
			]
			_open_panel("Column order", body, [
				["Consult subordinates (hold vs advance)", "consult"],
				["Request household word (delayed rumor)", "request_word"],
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
		"consult":
			var err: String = campaign.consult_subordinates()
			_notice = "Subordinate counsel recorded." if err.is_empty() else err
			_close()
			return
		"request_word":
			var err2: String = campaign.request_household_word()
			_notice = "Household courier sent; word arrives after delay." if err2.is_empty() else err2
			_close()
			return
		"ack_pressure":
			var err3: String = campaign.acknowledge_clan_pressure()
			_notice = "Clan-house pressure acknowledged; march willingness restored." if err3.is_empty() else err3
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var pending_w: int = campaign.pending_rumors().size()
	var willing: String = "yes" if campaign.march_willingness() else "no"
	_hud.text += "\nPolitics: disposition %s · march willing %s · pending household word %d · Household graph: %s" % [
		campaign.disposition(), willing, pending_w, PoliticsModel.HOUSEHOLD_ID
	]
