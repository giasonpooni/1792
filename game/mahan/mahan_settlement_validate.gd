extends RefCounted
## Settlement observation ledger/memory validators (tooling size split).

static func validate_ledger(host, value: Dictionary, sett: Dictionary, stripped: bool) -> String:
	for key in ["examined", "rumors", "facts"]:
		if not sett.has(key):
			return "Malformed settlement ledger."
	if not sett.examined is Array:
		return "Malformed settlement examined list."
	var seen := {}
	for kind in sett.examined:
		if str(kind) not in host.SETTLEMENT_MARKERS:
			return "Unsupported settlement marker examined."
		if seen.has(kind):
			return "Duplicate settlement marker examination."
		seen[kind] = true
	if not sett.rumors is Array:
		return "Malformed settlement rumors."
	if sett.rumors.size() > 1:
		return "Only one local settlement rumor may be on the book."
	if not sett.facts is Dictionary or not sett.facts.has(host.FACT_LOCAL_WORD):
		return "Settlement sealed facts missing."
	var fact = sett.facts[host.FACT_LOCAL_WORD]
	if not fact is Dictionary or typeof(fact.get("player_knowledge", null)) != TYPE_BOOL:
		return "Settlement fact player_knowledge must be boolean."
	var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
	var delivered_count := 0
	for rumor in sett.rumors:
		if not rumor is Dictionary:
			return "Malformed settlement custody."
		for key in ["id", "target", "observer_id", "observed_at", "arrives_at", "delivered", "source_id", "channel", "text"]:
			if not rumor.has(key):
				return "Malformed settlement custody."
		if rumor.id != "settlement_local_rumor.report" or rumor.target != host.FACT_LOCAL_WORD:
			return "Unsupported settlement rumor identity."
		if rumor.observer_id != "settlement_courier":
			return "Settlement rumor observer mismatch."
		if rumor.source_id != host.LOCAL_RUMOR_TEXT.source_id or rumor.channel != host.LOCAL_RUMOR_TEXT.channel or rumor.text != host.LOCAL_RUMOR_TEXT.text:
			return "Settlement rumor text was rewritten."
		if rumor.arrives_at != rumor.observed_at + host.SETTLEMENT_DELAY:
			return "Invalid settlement rumor delivery time."
		if rumor.observed_at != floor(rumor.observed_at) or rumor.observed_at < 0 or rumor.observed_at > tick:
			return "Invalid settlement observation time."
		var due: bool = tick >= rumor.arrives_at
		if rumor.delivered != due:
			return "Settlement delivery state disagrees with the clock."
		if rumor.delivered:
			delivered_count += 1
	if bool(fact.player_knowledge) != (delivered_count == 1):
		return "Settlement fact player_knowledge disagrees with rumor delivery."
	if stripped:
		return ""
	if str(value.mahan.get("household_id", "")) != "sukerchakia":
		return "Settlement slice requires sukerchakia household."
	return ""

static func validate_memories(host, value: Dictionary, settlement_memories: Array) -> String:
	var sett: Dictionary = value.mahan.settlement
	var expected: Array = []
	for kind in sett.examined:
		expected.append("settlement_examine_%s" % kind)
	if not sett.rumors.is_empty():
		expected.append("settlement_request_local_rumor")
	for rumor in sett.rumors:
		if rumor.delivered:
			expected.append(rumor.id)
	if settlement_memories.size() != expected.size():
		return "Settlement memories disagree with settlement ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in settlement_memories:
		if not memory is Dictionary:
			return "Malformed settlement memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed settlement memory."
		if memory.observer_id != host.ACTOR_ID:
			return "Settlement memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid settlement memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if str(memory.id).begins_with("settlement_examine_"):
			var kind := str(memory.id).trim_prefix("settlement_examine_")
			if kind not in host.EXAMINE_TEXTS:
				return "Unsupported settlement examine memory."
			var authored: Dictionary = host.EXAMINE_TEXTS[kind]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Settlement examine memory was rewritten."
		elif memory.id == "settlement_request_local_rumor":
			if memory.source_id != host.RUMOR_REQUEST_TEXT.source_id or memory.channel != host.RUMOR_REQUEST_TEXT.channel or memory.text != host.RUMOR_REQUEST_TEXT.text:
				return "Settlement rumor-request memory was rewritten."
		elif memory.id == "settlement_local_rumor.report":
			if memory.source_id != host.LOCAL_RUMOR_TEXT.source_id or memory.channel != host.LOCAL_RUMOR_TEXT.channel or memory.text != host.LOCAL_RUMOR_TEXT.text:
				return "Delivered settlement rumor memory was rewritten."
			var matched := false
			for rumor in sett.rumors:
				if rumor.id == memory.id and rumor.delivered and memory.received_tick == rumor.arrives_at:
					matched = true
			if not matched:
				return "Settlement rumor memory tick disagrees with delivery custody."
		else:
			return "Unsupported settlement memory id."
	if not remaining.is_empty():
		return "Settlement memories disagree with settlement ledger."
	var parent_count: int = 0
	for memory in value.mahan.memories:
		if not host._settlement_memory_id(str(memory.id)):
			parent_count += 1
	if value.mahan.memories.size() != parent_count + expected.size():
		return "Settlement journal size disagrees with experienced events."
	return ""
