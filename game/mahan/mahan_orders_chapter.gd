extends "res://mahan/mahan_politics_chapter.gd"
## Mahan subordinate orders presentation: scout / hold rear / pursue-contact stub.
const OrdersModel := preload("res://mahan/mahan_orders_state.gd")

func _ready() -> void:
	campaign = OrdersModel.new()
	campaign.enable_riding()
	super._ready()
	_notice = "E at the table for scouts, counsel, household word, or subordinate orders. F to mount. Forage when packs have room."

func _open_march_panel() -> void:
	var node: String = campaign.column_node()
	var willing: String = "willing" if campaign.march_willingness() else "blocked by clan-house pressure"
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var body := "Column at: %s · Provisions: %d · Disposition: %s · March: %s\nPending pursuit custody: %d (delay %d ticks).\nWalk/ride to an adjacent authored node, dismount, then commit the march or issue subordinate orders.\nStockout and strained politics can each block march; forage or acknowledge pressure as needed." % [
		node, campaign.provisions(), campaign.disposition(), willing,
		pending_p, OrdersModel.ORDERS_DELAY
	]
	var actions: Array = []
	if campaign.snapshot().mahan.decision == "advance_scouts":
		for nxt in OrdersModel.ADJACENT[node]:
			actions.append(["March column to %s (−%d provisions)" % [nxt, OrdersModel.MARCH_COST], "march_%s" % nxt])
		actions.append(["Issue subordinate orders (scout / hold rear / pursue)", "open_orders"])
	if not campaign.march_willingness():
		actions.append(["Acknowledge clan-house pressure", "ack_pressure"])
	actions.append([_forage_action_label(), "forage"])
	actions.append(["Acknowledge fixed historical endpoint", "ack_endpoint"])
	actions.append(["Cancel", "close"])
	_open_panel("Column movement", body, actions)

func _open_orders_panel() -> void:
	var assigns: Dictionary = campaign.active_assignments()
	var assign_label := "none" if assigns.is_empty() else ", ".join(PackedStringArray(assigns.values()))
	var lines := "Subordinate column orders (politics roster). Disposition: %s · Active: %s\nOffensive orders (scout / pursue) require steady or aligned disposition.\nPursuit returns a timed outcome stub via delayed custody — not combat AI." % [
		campaign.disposition(), assign_label
	]
	var actions: Array = []
	actions.append(["Order jemadar to scout the flank", "order_scout"])
	actions.append(["Order retainer to hold the rear", "order_hold_rear"])
	actions.append(["Order jemadar to pursue contact (timed stub)", "order_pursue_contact"])
	actions.append(["Cancel", "close"])
	_open_panel("Subordinate orders", lines, actions)

func _perform(action: String) -> void:
	match action:
		"open_orders":
			_open_orders_panel()
			return
		"order_scout":
			var err: String = campaign.issue_sub_order("scout")
			_notice = "Flank scout order issued to the horse jemadar." if err.is_empty() else err
			_close()
			return
		"order_hold_rear":
			var err2: String = campaign.issue_sub_order("hold_rear")
			_notice = "Rear-guard order issued to the camp retainer." if err2.is_empty() else err2
			_close()
			return
		"order_pursue_contact":
			var err3: String = campaign.issue_sub_order("pursue_contact")
			_notice = "Contact pursuit ordered; outcome arrives after delay." if err3.is_empty() else err3
			_close()
			return
		_:
			super._perform(action)

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(_hud):
		return
	var pending_p: int = campaign.pending_pursuit_reports().size()
	var assigns: Dictionary = campaign.active_assignments()
	var assign_label := "none" if assigns.is_empty() else ", ".join(PackedStringArray(assigns.values()))
	_hud.text += "\nOrders: active [%s] · pending pursuit %d · Household graph: %s" % [
		assign_label, pending_p, OrdersModel.HOUSEHOLD_ID
	]
