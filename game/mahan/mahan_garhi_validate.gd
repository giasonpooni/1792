extends RefCounted
## Garhi landmark observation ledger/memory validators (tooling size split).

static func validate_ledger(host, value: Dictionary, garhi: Dictionary, stripped: bool) -> String:
	for key in ["examined", "reports", "facts"]:
		if not garhi.has(key):
			return "Malformed garhi ledger."
	if not garhi.examined is Array:
		return "Malformed garhi examined list."
	var seen := {}
	for kind in garhi.examined:
		if str(kind) not in host.GARHI_MARKERS:
			return "Unsupported garhi marker examined."
		if seen.has(kind):
			return "Duplicate garhi marker examination."
		seen[kind] = true
	if not garhi.reports is Array:
		return "Malformed garhi reports."
	if garhi.reports.size() > 1:
		return "Only one delayed garhi report may be on the book."
	if not garhi.facts is Dictionary or not garhi.facts.has(host.FACT_GARHI_WORD):
		return "Garhi sealed facts missing."
	var fact = garhi.facts[host.FACT_GARHI_WORD]
	if not fact is Dictionary or typeof(fact.get("player_knowledge", null)) != TYPE_BOOL:
		return "Garhi fact player_knowledge must be boolean."
	var tick: int = int(value.mahan.tick) if value.mahan.has("tick") else 0
	var delivered_count := 0
	for report in garhi.reports:
		if not report is Dictionary:
			return "Malformed garhi custody."
		for key in ["id", "target", "observer_id", "observed_at", "arrives_at", "delivered", "source_id", "channel", "text"]:
			if not report.has(key):
				return "Malformed garhi custody."
		if report.id != "garhi_landmark_report.report" or report.target != host.FACT_GARHI_WORD:
			return "Unsupported garhi report identity."
		if report.observer_id != "garhi_courier":
			return "Garhi report observer mismatch."
		if report.source_id != host.GARHI_DELAYED_REPORT_TEXT.source_id or report.channel != host.GARHI_DELAYED_REPORT_TEXT.channel or report.text != host.GARHI_DELAYED_REPORT_TEXT.text:
			return "Garhi report text was rewritten."
		if report.arrives_at != report.observed_at + host.GARHI_DELAY:
			return "Invalid garhi report delivery time."
		if report.observed_at != floor(report.observed_at) or report.observed_at < 0 or report.observed_at > tick:
			return "Invalid garhi observation time."
		var due: bool = tick >= report.arrives_at
		if report.delivered != due:
			return "Garhi delivery state disagrees with the clock."
		if report.delivered:
			delivered_count += 1
	if bool(fact.player_knowledge) != (delivered_count == 1):
		return "Garhi fact player_knowledge disagrees with report delivery."
	if stripped:
		return ""
	if str(value.mahan.get("household_id", "")) != "sukerchakia":
		return "Garhi slice requires sukerchakia household."
	return ""

static func validate_memories(host, value: Dictionary, garhi_memories: Array) -> String:
	var garhi: Dictionary = value.mahan.garhi
	var expected: Array = []
	for kind in garhi.examined:
		expected.append("garhi_examine_%s" % kind)
	if not garhi.reports.is_empty():
		expected.append("garhi_request_delayed_report")
	for report in garhi.reports:
		if report.delivered:
			expected.append(report.id)
	if garhi_memories.size() != expected.size():
		return "Garhi memories disagree with garhi ledger."
	var remaining: Array = expected.duplicate()
	var prior := -1
	for memory in garhi_memories:
		if not memory is Dictionary:
			return "Malformed garhi memory."
		for key in ["id", "source_id", "channel", "received_tick", "text", "observer_id"]:
			if not memory.has(key):
				return "Malformed garhi memory."
		if memory.observer_id != host.ACTOR_ID:
			return "Garhi memory must stay attributed to mahan_singh."
		if memory.id not in remaining or memory.received_tick != floor(memory.received_tick) or (not (memory.received_tick >= prior)) or memory.received_tick > value.mahan.tick:
			return "Invalid garhi memory tick or membership."
		remaining.erase(memory.id)
		prior = int(memory.received_tick)
		if str(memory.id).begins_with("garhi_examine_"):
			var kind := str(memory.id).trim_prefix("garhi_examine_")
			if kind not in host.GARHI_EXAMINE_TEXTS:
				return "Unsupported garhi examine memory."
			var authored: Dictionary = host.GARHI_EXAMINE_TEXTS[kind]
			if memory.source_id != authored.source_id or memory.channel != authored.channel or memory.text != authored.text:
				return "Garhi examine memory was rewritten."
		elif memory.id == "garhi_request_delayed_report":
			if memory.source_id != host.GARHI_REPORT_REQUEST_TEXT.source_id or memory.channel != host.GARHI_REPORT_REQUEST_TEXT.channel or memory.text != host.GARHI_REPORT_REQUEST_TEXT.text:
				return "Garhi report-request memory was rewritten."
		elif memory.id == "garhi_landmark_report.report":
			if memory.source_id != host.GARHI_DELAYED_REPORT_TEXT.source_id or memory.channel != host.GARHI_DELAYED_REPORT_TEXT.channel or memory.text != host.GARHI_DELAYED_REPORT_TEXT.text:
				return "Delivered garhi report memory was rewritten."
			var matched := false
			for report in garhi.reports:
				if report.id == memory.id and report.delivered and memory.received_tick == report.arrives_at:
					matched = true
			if not matched:
				return "Garhi report memory tick disagrees with delivery custody."
		else:
			return "Unsupported garhi memory id."
	if not remaining.is_empty():
		return "Garhi memories disagree with garhi ledger."
	var parent_count: int = 0
	for memory in value.mahan.memories:
		if not host._garhi_memory_id(str(memory.id)):
			parent_count += 1
	if value.mahan.memories.size() != parent_count + expected.size():
		return "Garhi journal size disagrees with experienced events."
	return ""
