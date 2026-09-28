extends "res://mahan/mahan_cavalry_chapter.gd"
## Mahan logistics presentation: forage / stockout / wait drain on top of cavalry chapter.
const LogisticsModel := preload("res://mahan/mahan_logistics_state.gd")

func _ready() -> void:
	campaign = LogisticsModel.new()
	campaign.enable_riding()
	super._ready()
	_notice = "E at the table for scouts/orders. F to mount. Forage at the column node when packs have room."

func _open_dispatch_panel() -> void:
	var lines := "Dispatch a scout detachment. The report is not knowledge until it arrives (delay %d ticks).\nProvisions: %d · Foraged: %s · Wait drain units: %d\nStockout blocks advance/march until you forage or hold." % [
		LogisticsModel.REPORT_DELAY, campaign.provisions(),
		_foraged_label(), campaign.wait_units()
	]
	var actions: Array = []
	actions.append(["Scout the ford approach (−%d provisions)" % LogisticsModel.DISPATCH_COST, "dispatch_ford"])
	actions.append(["Scout the ridge approach (−%d provisions)" % LogisticsModel.DISPATCH_COST, "dispatch_ridge"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Cancel", "close"])
	_open_panel("Scout dispatch", lines, actions)

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var body := "Column at: %s · Provisions: %d · Foraged: %s · Wait units: %d\nWalk/ride to an adjacent authored node, dismount, then commit the march.\nStockout blocks march; forage locally or acknowledge the fixed endpoint." % [
		node, campaign.provisions(), _foraged_label(), campaign.wait_units()
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in LogisticsModel.ADJACENT[node]:
			actions.append(["March column to %s (−%d provisions)" % [nxt, LogisticsModel.MARCH_COST], "march_%s" % nxt])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _interact() -> void:
	if campaign.is_mounted():
		_notice = "Dismount (F when stopped) before orders, forage, or marker interactions."
		return
	campaign.record_position(avatar.global_position, 1.0 / 60.0)
	match campaign.stage():
		"decision":
			if not campaign.near("camp_table"):
				_notice = "Return to the camp table once scout custody has been delivered."
				return
			var body := "Delivered scout reports: %d. Pending: %d.\nProvisions: %d · Foraged: %s\nStockout (<%d provisions) blocks advance; hold or forage remains available.\nChoose a subordinate command; this does not rewrite Mahan's fixed historical endpoint." % [
				campaign.received_reports().size(), campaign.pending_reports().size(),
				campaign.provisions(), _foraged_label(), LogisticsModel.MARCH_COST
			]
			_open_panel("Column order", body, [
				["Advance the horse column", "advance_scouts"],
				["Hold the column for corroboration", "hold_for_corroboration"],
				["Dispatch another scout", "open_dispatch"],
				[_forage_action_label(), "forage"],
				["Cancel", "close"]
			])
		_:
			super._interact()

func _perform(action: String) -> void:
	if action == "forage":
		var err: String = campaign.forage()
		if err.is_empty():
			_notice = "Foraged at the %s. Provisions now %d." % [campaign.column_node(), campaign.provisions()]
		else:
			_notice = err
		_close()
		return
	super._perform(action)

func _foraged_label() -> String:
	var nodes: Array = campaign.foraged_nodes()
	return "none" if nodes.is_empty() else ", ".join(PackedStringArray(nodes))

func _forage_action_label() -> String:
	var node: String = campaign.column_node()
	var yield_amt: int = int(LogisticsModel.FORAGE_YIELDS.get(node, 0))
	return "Forage at %s (+%d provisions)" % [node, yield_amt]

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var stock := "STOCKOUT" if campaign.provisions() < LogisticsModel.MARCH_COST else "supplied"
	_hud.text += "\nLogistics: %s · forage ledger [%s] · wait units %d · Household graph: %s" % [
		stock, _foraged_label(), campaign.wait_units(), LogisticsModel.HOUSEHOLD_ID
	]
