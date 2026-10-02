extends RefCounted
## Split-out Mahan politics validators (tooling size split; same ontology rules).

static func validate_ledger(host, value: Dictionary, pol: Dictionary, stripped: bool) -> String:
	for key in ["consulted", "disposition", "pressure_acknowledged", "loyalty", "alignments", "rumors"]:
		if not pol.has(key):
			return "Malformed politics ledger."
	if not pol.consulted is bool or not pol.pressure_acknowledged is bool:
		return "Malformed politics flags."
	if pol.disposition not in host.DISPOSITIONS:
		return "Unknown column disposition."
	if not pol.loyalty is Dictionary or not pol.alignments is Dictionary or not pol.rumors is Array:
		return "Malformed politics collections."
	if pol.loyalty.size() != host.SUBORDINATE_DEFS.size() or pol.alignments.size() != host.SUBORDINATE_DEFS.size():
		return "Politics subordinates disagree with authored roster."
	for sid in host.SUBORDINATE_DEFS:
		if not pol.loyalty.has(sid) or not pol.alignments.has(sid):
			return "Missing subordinate politics entry."
		var loy = pol.loyalty[sid]
		if typeof(loy) not in [TYPE_INT, TYPE_FLOAT] or loy != floor(loy) or (not (loy >= 0)) or loy > 3:
			return "Invalid subordinate loyalty."
		var aln = pol.alignments[sid]
		if not aln is Dictionary or not aln.has("stance") or not aln.has("valid_from") or not aln.has("valid_until"):
			return "Malformed subordinate alignment."
		if aln.stance not in host.STANCES:
			return "Unknown subordinate stance."
		if typeof(aln.valid_from) not in [TYPE_INT, TYPE_FLOAT] or aln.valid_from != floor(aln.valid_from) or (not (aln.valid_from >= 0)):
			return "Invalid alignment valid_from."
		if typeof(aln.valid_until) not in [TYPE_INT, TYPE_FLOAT] or aln.valid_until != floor(aln.valid_until) or (not (aln.valid_until >= -1)):
			return "Invalid alignment valid_until."
		var def: Dictionary = host.SUBORDINATE_DEFS[sid]
		if def.serves_person != host.ACTOR_ID or def.serves_household != host.HOUSEHOLD_ID:
			return "Subordinate must serve mahan_singh under sukerchakia household."
	if pol.pressure_acknowledged and pol.disposition == "steady" and not stripped:
		pass
	if pol.disposition == "strained" and value.mahan.get("decision", "") != "advance_scouts" and not stripped:
		if not pol.consulted:
			return "Strained disposition without subordinate counsel."
	var seen_targets := {}
	for rumor in pol.rumors:
		if not rumor is Dictionary:
			return "Malformed household rumor custody."
		for key in ["id", "target", "observer_id", "observed_at", "arrives_at", "delivered", "source_id", "channel", "text"]:
			if not rumor.has(key):
				return "Malformed household rumor custody."
		if rumor.target not in host.RUMOR_TEXTS or rumor.id != "rumor_%s.report" % rumor.target:
			return "Unsupported household rumor identity."
		if rumor.observer_id != "camp_courier":
			return "Rumor observer mismatch."
		var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
		if rumor.observed_at != floor(rumor.observed_at) or (not (rumor.observed_at >= 0)) or rumor.observed_at > tick:
			return "Invalid rumor observation time."
		if rumor.arrives_at != rumor.observed_at + host.POLITICS_DELAY:
			return "Invalid rumor delivery time."
		var authored: Dictionary = host.RUMOR_TEXTS[rumor.target]
		if rumor.source_id != authored.source_id or rumor.channel != authored.channel or rumor.text != authored.text:
			return "Attributed household rumor was rewritten."
		var due: bool = tick >= rumor.arrives_at
		if rumor.delivered != due:
			return "Rumor delivery state disagrees with the clock."
		if seen_targets.has(rumor.target):
			return "Duplicate household rumor target."
		seen_targets[rumor.target] = true
	return ""


static func validate_memories(host, value: Dictionary, politics_memories: Array) -> String:
	var pol: Dictionary = value.mahan.politics
	var expected: Array = []
	if pol.consulted:
		expected.append("consult_subordinates")
	for rumor in pol.rumors:
		if rumor.delivered:
			expected.append(rumor.id)
	if pol.pressure_acknowledged:
		expected.append("clan_pressure_ack")
	if politics_memories.size() != expected.size():
		return "Politics memories disagree with politics ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in politics_memories:
		if not memory is Dictionary:
			return "Malformed politics memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed politics memory."
		if memory.observer_id != host.ACTOR_ID:
			return "Politics memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid politics memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if memory.id == "consult_subordinates":
			if memory.source_id != "self" or memory.channel != "subordinate_counsel" or memory.text != host.CONSULT_TEXT:
				return "Consult memory was rewritten."
		elif memory.id == "clan_pressure_ack":
			if memory.source_id != "self" or memory.channel != "command_acknowledgment" or memory.text != host.PRESSURE_ACK_TEXT:
				return "Pressure acknowledgment memory was rewritten."
		elif str(memory.id).begins_with("rumor_") and str(memory.id).ends_with(".report"):
			var target := str(memory.id).trim_prefix("rumor_").trim_suffix(".report")
			if not host.RUMOR_TEXTS.has(target):
				return "Unsupported delivered rumor memory."
			var authored: Dictionary = host.RUMOR_TEXTS[target]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Delivered rumor memory was rewritten."
			var matched := false
			for rumor in pol.rumors:
				if rumor.id == memory.id and rumor.delivered and memory.received_tick == rumor.arrives_at:
					matched = true
			if not matched:
				return "Rumor memory tick disagrees with delivery custody."
		else:
			return "Unsupported politics memory id."
	if not remaining.is_empty():
		return "Politics memories disagree with politics ledger."
	var full_expected: Array = []
	for report in value.mahan.reports:
		if report.delivered:
			full_expected.append(report.id)
	for node_id in value.mahan.logistics.foraged_nodes:
		full_expected.append("forage_%s" % node_id)
	for mid in expected:
		full_expected.append(mid)
	if value.mahan.decision != "":
		full_expected.append(value.mahan.decision)
	for memory in value.mahan.memories:
		if str(memory.id).begins_with("march_"):
			full_expected.append(memory.id)
	if value.mahan.endpoint_acknowledged:
		full_expected.append("fixed_endpoint")
	if value.mahan.memories.size() != full_expected.size():
		return "Politics journal size disagrees with experienced events."
	var pool: Array = full_expected.duplicate()
	var tick_prior := -1
	for memory in value.mahan.memories:
		if memory.id not in pool or (not (memory.received_tick >= tick_prior)):
			return "Politics journal order or membership invalid."
		pool.erase(memory.id)
		tick_prior = int(memory.received_tick)
	if not pool.is_empty():
		return "Politics journal membership incomplete."
	if value.mahan.decision == "advance_scouts" and pol.consulted:
		if pol.disposition == "strained" and not (pol.pressure_acknowledged is bool):
			return "Malformed strained disposition."
	return ""
