extends "res://mahan/mahan_politics_state.gd"
## Mahan-only subordinate column orders adapter.
## Issues scout / hold_rear / pursue_contact to politics subordinates.
## Pursuit is a timed outcome stub (delayed custody), not combat AI.
## Does not rewrite house_command_state or patrol_director.
const ORDERS_DELAY := 75
const ORDER_KINDS := ["scout", "hold_rear", "pursue_contact"]
const ORDER_ROSTER := {
	"scout": {
		"subordinate_id": "fictional_horse_jemadar",
		"label": "flank scout"
	},
	"hold_rear": {
		"subordinate_id": "fictional_camp_retainer",
		"label": "rear guard"
	},
	"pursue_contact": {
		"subordinate_id": "fictional_horse_jemadar",
		"label": "contact pursuit"
	}
}
## Offensive sub-orders require steady/aligned disposition; hold_rear is always disposition-ok.
const OFFENSIVE_ORDERS := ["scout", "pursue_contact"]
const PURSUIT_TEXTS := {
	"contact_stub": {
		"source_id": "fictional_horse_jemadar",
		"channel": "delayed_pursuit_report",
		"text": "The jemadar's pursuit party returned on the delay clock. Contact broke before the ridge; no engagement was forced. This is a timed outcome stub under household command relations, not a combat resolution."
	}
}
const ORDER_TEXTS := {
	"scout": "I ordered the horse jemadar to scout the column flank. The assignment stays under Sukerchakia household relations; it is not a Faction tag and does not rewrite patrol_director.",
	"hold_rear": "I ordered the camp retainer to hold the rear of the horse column. Rear-guard duty is subordinate command under the household graph.",
	"pursue_contact": "I ordered the horse jemadar to pursue fleeting contact. The outcome will arrive on a delay clock as a custody stub, not as live combat."
}

func _init() -> void:
	super._init()
	_ensure_orders()

func _ensure_orders() -> Dictionary:
	if not _state.mahan.has("orders") or not _state.mahan.orders is Dictionary:
		_state.mahan.orders = _fresh_orders()
	var ord: Dictionary = _state.mahan.orders
	for key in ["assignments", "pursuit_reports"]:
		if not ord.has(key):
			_state.mahan.orders = _fresh_orders()
			return _state.mahan.orders
	return ord

func _fresh_orders() -> Dictionary:
	return {
		"assignments": {},
		"pursuit_reports": []
	}

func orders() -> Dictionary:
	return _ensure_orders().duplicate(true)

func active_assignments() -> Dictionary:
	return _ensure_orders().assignments.duplicate(true)

func subordinate_order(sid: String) -> String:
	return str(_ensure_orders().assignments.get(sid, ""))

func pending_pursuit_reports() -> Array:
	var out: Array = []
	for report in _ensure_orders().pursuit_reports:
		if not report.delivered:
			out.append(report.duplicate(true))
	return out

func received_pursuit_reports() -> Array:
	var out: Array = []
	for report in _ensure_orders().pursuit_reports:
		if report.delivered:
			out.append(report.duplicate(true))
	return out

func order_allowed(kind: String) -> String:
	## Empty string means allowed; otherwise a refuse reason.
	if not ORDER_KINDS.has(kind):
		return "Unknown subordinate order."
	if is_mounted():
		return "Dismount before issuing subordinate orders."
	if stage() != "march":
		return "Issue the column order before assigning subordinate orders."
	if _state.mahan.decision != "advance_scouts":
		return "Subordinate column orders apply only while the horse column is advancing."
	if not near(_state.mahan.column_node) and not near("camp_table"):
		return "Stand with the column or at the camp table to issue subordinate orders."
	var disp := disposition()
	if kind in OFFENSIVE_ORDERS and disp == "strained":
		return "Clan-house strain blocks offensive sub-orders; hold the rear or acknowledge pressure until disposition steadies."
	if kind in OFFENSIVE_ORDERS and disp not in ["steady", "aligned"]:
		return "Offensive sub-orders require steady or aligned disposition."
	var roster: Dictionary = ORDER_ROSTER[kind]
	var sid: String = str(roster.subordinate_id)
	if not SUBORDINATE_DEFS.has(sid):
		return "Subordinate is not on the politics roster."
	var existing: String = subordinate_order(sid)
	if existing != "":
		return "That subordinate already holds a column order (%s)." % existing
	if kind == "pursue_contact":
		var ord := _ensure_orders()
		if not ord.pursuit_reports.is_empty():
			return "A contact pursuit is already on the book."
	return ""

func issue_sub_order(kind: String) -> String:
	var refuse := order_allowed(kind)
	if not refuse.is_empty():
		return refuse
	var roster: Dictionary = ORDER_ROSTER[kind]
	var sid: String = str(roster.subordinate_id)
	var ord := _ensure_orders()
	ord.assignments[sid] = kind
	_remember("order_%s" % kind, "self", "subordinate_order", ORDER_TEXTS[kind])
	if kind == "pursue_contact":
		var authored: Dictionary = PURSUIT_TEXTS.contact_stub
		ord.pursuit_reports.append({
			"id": "pursuit_contact_stub.report",
			"target": "contact_stub",
			"observer_id": "pursuit_courier",
			"observed_at": _state.mahan.tick,
			"arrives_at": _state.mahan.tick + ORDERS_DELAY,
			"delivered": false,
			"source_id": authored.source_id,
			"channel": authored.channel,
			"text": authored.text,
			"subordinate_id": sid
		})
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.orders = _ensure_orders().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_pursuit_reports()

func _deliver_due_pursuit_reports() -> void:
	var ord := _ensure_orders()
	for report in ord.pursuit_reports:
		if report.delivered or (not (_state.mahan.tick >= report.arrives_at)):
			continue
		report.delivered = true
		_remember(report.id, report.source_id, report.channel, report.text)

func _orders_memory_id(id: String) -> bool:
	return str(id).begins_with("order_") or str(id).begins_with("pursuit_")

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan orders snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var ord = m.get("orders")
	var stripped_parent_path := false
	if ord == null:
		for memory in m.memories:
			if _orders_memory_id(str(memory.id)):
				return "Mahan orders envelope missing."
		ord = _fresh_orders()
		stripped_parent_path = true
	elif not ord is Dictionary:
		return "Mahan orders envelope missing."
	var ledger_err := _validate_orders_ledger(value if not stripped_parent_path else {"mahan": {"orders": ord, "tick": m.tick, "decision": m.decision, "memories": [], "politics": m.get("politics", {})}}, ord, stripped_parent_path)
	if not ledger_err.is_empty():
		return ledger_err
	var kept: Array = []
	var orders_memories: Array = []
	for memory in m.memories:
		if _orders_memory_id(str(memory.id)):
			orders_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("orders")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return _validate_orders_memories(value, orders_memories)

func _validate_orders_ledger(value: Dictionary, ord: Dictionary, _stripped: bool) -> String:
	if not ord.has("assignments") or not ord.has("pursuit_reports"):
		return "Malformed orders ledger."
	if not ord.assignments is Dictionary or not ord.pursuit_reports is Array:
		return "Malformed orders collections."
	var used_subs := {}
	for sid in ord.assignments:
		if not SUBORDINATE_DEFS.has(sid):
			return "Orders assignment names unknown subordinate."
		var kind = ord.assignments[sid]
		if kind not in ORDER_KINDS:
			return "Unknown assigned subordinate order."
		var roster: Dictionary = ORDER_ROSTER[kind]
		if str(roster.subordinate_id) != str(sid):
			return "Subordinate order assignment disagrees with authored roster."
		if used_subs.has(sid):
			return "Duplicate subordinate order assignment."
		used_subs[sid] = true
	var seen_pursuit := {}
	for report in ord.pursuit_reports:
		if not report is Dictionary:
			return "Malformed pursuit custody."
		for key in ["id", "target", "observer_id", "observed_at", "arrives_at", "delivered", "source_id", "channel", "text", "subordinate_id"]:
			if not report.has(key):
				return "Malformed pursuit custody."
		if report.target not in PURSUIT_TEXTS or report.id != "pursuit_%s.report" % report.target:
			return "Unsupported pursuit identity."
		if report.observer_id != "pursuit_courier":
			return "Pursuit observer mismatch."
		if str(report.subordinate_id) != str(ORDER_ROSTER.pursue_contact.subordinate_id):
			return "Pursuit subordinate mismatch."
		var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
		if report.observed_at != floor(report.observed_at) or (not (report.observed_at >= 0)) or report.observed_at > tick:
			return "Invalid pursuit observation time."
		if report.arrives_at != report.observed_at + ORDERS_DELAY:
			return "Invalid pursuit delivery time."
		var authored: Dictionary = PURSUIT_TEXTS[report.target]
		if report.source_id != authored.source_id or report.channel != authored.channel or report.text != authored.text:
			return "Attributed pursuit report was rewritten."
		var due: bool = tick >= report.arrives_at
		if report.delivered != due:
			return "Pursuit delivery state disagrees with the clock."
		if seen_pursuit.has(report.target):
			return "Duplicate pursuit target."
		seen_pursuit[report.target] = true
	if not ord.pursuit_reports.is_empty():
		var jem := str(ORDER_ROSTER.pursue_contact.subordinate_id)
		if str(ord.assignments.get(jem, "")) != "pursue_contact":
			return "Pursuit custody without pursue_contact assignment."
	return ""

func _validate_orders_memories(value: Dictionary, orders_memories: Array) -> String:
	var ord: Dictionary = value.mahan.orders
	var expected: Array = []
	for sid in ord.assignments:
		expected.append("order_%s" % ord.assignments[sid])
	for report in ord.pursuit_reports:
		if report.delivered:
			expected.append(report.id)
	if orders_memories.size() != expected.size():
		return "Orders memories disagree with orders ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in orders_memories:
		if not memory is Dictionary:
			return "Malformed orders memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed orders memory."
		if memory.observer_id != ACTOR_ID:
			return "Orders memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid orders memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if str(memory.id).begins_with("order_"):
			var kind := str(memory.id).trim_prefix("order_")
			if kind not in ORDER_TEXTS:
				return "Unsupported subordinate order memory."
			if memory.source_id != "self" or memory.channel != "subordinate_order" or memory.text != ORDER_TEXTS[kind]:
				return "Subordinate order memory was rewritten."
		elif str(memory.id).begins_with("pursuit_") and str(memory.id).ends_with(".report"):
			var target := str(memory.id).trim_prefix("pursuit_").trim_suffix(".report")
			if not PURSUIT_TEXTS.has(target):
				return "Unsupported delivered pursuit memory."
			var authored: Dictionary = PURSUIT_TEXTS[target]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Delivered pursuit memory was rewritten."
			var matched := false
			for report in ord.pursuit_reports:
				if report.id == memory.id and report.delivered and memory.received_tick == report.arrives_at:
					matched = true
			if not matched:
				return "Pursuit memory tick disagrees with delivery custody."
		else:
			return "Unsupported orders memory id."
	if not remaining.is_empty():
		return "Orders memories disagree with orders ledger."
	## Full journal size: parent-validated memories plus orders memories.
	var parent_count: int = 0
	for memory in value.mahan.memories:
		if not _orders_memory_id(str(memory.id)):
			parent_count += 1
	if value.mahan.memories.size() != parent_count + expected.size():
		return "Orders journal size disagrees with experienced events."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var ord: Dictionary = core.mahan.orders.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _orders_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("orders")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.orders = {
		"assignments": ord.assignments.duplicate(true),
		"pursuit_reports": []
	}
	for report in ord.pursuit_reports:
		var copy: Dictionary = report.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.orders.pursuit_reports.append(copy)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
