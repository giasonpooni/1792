extends "res://mahan/mahan_cavalry_state.gd"
## Mahan-only logistics adapter: forage at authored nodes, wait consumption, stockout gates.
## Does not rewrite base provisions stub accounting, house/command authorities, or economy UI.
const WAIT_INTERVAL := 60
const WAIT_COST := 1
const FORAGE_YIELDS := {"camp": 2, "ford": 1, "ridge": 1, "gujranwala_fort_road": 1, "gujranwala_camp": 2, "gujranwala_settlement": 1}

func _init() -> void:
	super._init()
	_ensure_logistics()

func _ensure_logistics() -> Dictionary:
	if not _state.mahan.has("logistics") or not _state.mahan.logistics is Dictionary:
		_state.mahan.logistics = {"foraged_nodes": [], "wait_units": 0}
	var logi: Dictionary = _state.mahan.logistics
	if not logi.has("foraged_nodes") or not logi.foraged_nodes is Array:
		logi.foraged_nodes = []
	if not logi.has("wait_units"):
		logi.wait_units = 0
	return logi

func logistics() -> Dictionary:
	return _ensure_logistics().duplicate(true)

func foraged_nodes() -> Array:
	return _ensure_logistics().foraged_nodes.duplicate()

func wait_units() -> int:
	return int(_ensure_logistics().wait_units)

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.logistics = _ensure_logistics().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_consume_wait_tick()

func _consume_wait_tick() -> void:
	var logi := _ensure_logistics()
	var due := int(_state.mahan.tick / WAIT_INTERVAL)
	while int(logi.wait_units) < due:
		if int(_state.mahan.provisions) < WAIT_COST:
			return
		_state.mahan.provisions -= WAIT_COST
		logi.wait_units = int(logi.wait_units) + 1

func forage() -> String:
	if is_mounted():
		return "Dismount before foraging."
	var node: String = column_node()
	var at_column := near(node)
	var at_camp_table := node == "camp" and near("camp_table")
	if not at_column and not at_camp_table:
		return "Stand with the column at the node to forage."
	if not FORAGE_YIELDS.has(node):
		return "No forage authored for this node."
	var logi := _ensure_logistics()
	if node in logi.foraged_nodes:
		return "This ground has already been foraged."
	var yield_amt: int = int(FORAGE_YIELDS[node])
	var room: int = PROVISIONS_MAX - int(_state.mahan.provisions)
	if room < yield_amt:
		return "Packs cannot take the full forage yield; consume or march first."
	_state.mahan.provisions = int(_state.mahan.provisions) + yield_amt
	logi.foraged_nodes.append(node)
	_remember(
		"forage_%s" % node,
		"self",
		"field_forage",
		"The column foraged at the %s and took on %d provisions. Local forage is field logistics, not a tax ledger." % [node, yield_amt]
	)
	return ""

func decide_column(choice: String) -> String:
	if is_mounted():
		return super.decide_column(choice)
	if choice == "advance_scouts" and int(_state.mahan.provisions) < MARCH_COST:
		return "Stockout -- insufficient provisions to advance the horse column; hold or forage first."
	return super.decide_column(choice)

func dispatch_scout(target: String) -> String:
	return super.dispatch_scout(target)

func march_to(next: String) -> String:
	if is_mounted():
		return super.march_to(next)
	if int(_state.mahan.provisions) < MARCH_COST:
		return "Stockout -- insufficient provisions for the horse column to march."
	return super.march_to(next)

func _march_memory_count(memories: Array) -> int:
	var n := 0
	for memory in memories:
		if str(memory.id).begins_with("march_"):
			n += 1
	return n

func _base_provisions(reports_size: int, march_count: int) -> int:
	return 10 - reports_size * DISPATCH_COST - march_count * MARCH_COST

func _forage_gain(foraged: Array) -> int:
	var total := 0
	for node_id in foraged:
		total += int(FORAGE_YIELDS.get(node_id, 0))
	return total

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan logistics snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var logi = m.get("logistics")
	var stripped_parent_path := false
	if logi == null:
		# Parent restore re-enters validate on a logistics-stripped core; accept empty ledger only.
		for memory in m.memories:
			if str(memory.id).begins_with("forage_"):
				return "Mahan logistics envelope missing."
		logi = {"foraged_nodes": [], "wait_units": 0}
		stripped_parent_path = true
	elif not logi is Dictionary:
		return "Mahan logistics envelope missing."
	if not logi.has("foraged_nodes") or not logi.has("wait_units"):
		return "Malformed logistics ledger."
	if not logi.foraged_nodes is Array:
		return "Malformed foraged_nodes."
	if typeof(logi.wait_units) not in [TYPE_INT, TYPE_FLOAT] or logi.wait_units != floor(logi.wait_units) or logi.wait_units < 0:
		return "Invalid wait consumption units."
	var seen := {}
	for node_id in logi.foraged_nodes:
		if typeof(node_id) != TYPE_STRING or node_id not in FORAGE_YIELDS or seen.has(node_id):
			return "Invalid forage ledger."
		seen[node_id] = true
	var forage_memories: Array = []
	var kept: Array = []
	for memory in m.memories:
		if str(memory.id).begins_with("forage_"):
			forage_memories.append(memory)
		else:
			kept.append(memory)
	var forage_gain := _forage_gain(logi.foraged_nodes)
	var wait_spent := int(logi.wait_units) * WAIT_COST
	var march_count := _march_memory_count(kept)
	var base_prov := _base_provisions(m.reports.size(), march_count)
	var expected_prov := base_prov + forage_gain - wait_spent
	if int(m.provisions) != expected_prov:
		return "Logistics provisions disagree with forage/wait ledger."
	if expected_prov < 0 or expected_prov > PROVISIONS_MAX:
		return "Logistics provisions out of bounds."
	if int(logi.wait_units) > int(m.tick / WAIT_INTERVAL):
		return "Wait units exceed elapsed intervals."
	# Rebuild core for cavalry/base validators: strip logistics + forage memories, restore stub provisions.
	core.mahan.memories = kept
	core.mahan.provisions = base_prov
	core.mahan.erase("logistics")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return _validate_forage_memories(value, forage_memories)

func _validate_forage_memories(value: Dictionary, forage_memories: Array) -> String:
	var foraged: Array = value.mahan.logistics.foraged_nodes
	if forage_memories.size() != foraged.size():
		return "Forage memories disagree with forage ledger."
	var remaining: Array = foraged.duplicate()
	var prior := -1
	# Forage memories must appear in the full journal in tick order among themselves;
	# cross-check each against ledger and authored yield text.
	for memory in forage_memories:
		if not memory is Dictionary:
			return "Malformed forage memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed forage memory."
		if memory.observer_id != ACTOR_ID:
			return "Forage memory must stay attributed to mahan_singh."
		if memory.source_id != "self" or memory.channel != "field_forage":
			return "Forage memory was rewritten."
		if memory.received_tick != floor(memory.received_tick) or memory.received_tick < prior or memory.received_tick > value.mahan.tick:
			return "Invalid forage memory tick."
		prior = int(memory.received_tick)
		var node_id := str(memory.id).trim_prefix("forage_")
		if memory.id != "forage_%s" % node_id or node_id not in remaining:
			return "Unsupported or duplicate forage memory."
		remaining.erase(node_id)
		var yield_amt: int = int(FORAGE_YIELDS[node_id])
		var expected_text := "The column foraged at the %s and took on %d provisions. Local forage is field logistics, not a tax ledger." % [node_id, yield_amt]
		if memory.text != expected_text:
			return "Forage memory text was rewritten."
	if not remaining.is_empty():
		return "Forage memories disagree with forage ledger."
	# Full journal must interleave forage ids with other expected events without extras.
	var expected_ids: Array = []
	for report in value.mahan.reports:
		if report.delivered:
			expected_ids.append(report.id)
	for node_id in foraged:
		expected_ids.append("forage_%s" % node_id)
	if value.mahan.decision != "":
		expected_ids.append(value.mahan.decision)
	for memory in value.mahan.memories:
		if str(memory.id).begins_with("march_"):
			expected_ids.append(memory.id)
	if value.mahan.endpoint_acknowledged:
		expected_ids.append("fixed_endpoint")
	# Order in journal is chronological, not grouped -- compare as multisets via size + membership.
	if value.mahan.memories.size() != expected_ids.size():
		return "Logistics journal size disagrees with experienced events."
	var pool: Array = expected_ids.duplicate()
	var tick_prior := -1
	for memory in value.mahan.memories:
		if memory.id not in pool or memory.received_tick < tick_prior:
			return "Logistics journal order or membership invalid."
		pool.erase(memory.id)
		tick_prior = int(memory.received_tick)
	if not pool.is_empty():
		return "Logistics journal membership incomplete."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var logi: Dictionary = core.mahan.logistics.duplicate(true)
	var actual_prov: int = int(core.mahan.provisions)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not str(memory.id).begins_with("forage_"):
			kept.append(memory.duplicate(true))
	var base_prov := _base_provisions(core.mahan.reports.size(), _march_memory_count(kept))
	core.mahan.memories = kept
	core.mahan.provisions = base_prov
	core.mahan.erase("logistics")
	# Parent restore re-validates; missing logistics is accepted as an empty ledger (see validate).
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.logistics = {
		"foraged_nodes": logi.foraged_nodes.duplicate(),
		"wait_units": int(logi.wait_units)
	}
	_state.mahan.provisions = actual_prov
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var copy: Dictionary = memory.duplicate(true)
		copy.received_tick = int(copy.received_tick)
		_state.mahan.memories.append(copy)
	return ""
