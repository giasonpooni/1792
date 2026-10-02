extends RefCounted
## Optional first-message errand. All dialogue is original dramatic writing,
## not a historical quotation or confirmation of an ambush conspiracy.
const SCHEMA := "opening-message.v1"
const RANGE := 3.0
const STEWARD_OFFER := "The note speaks of dawn. The courier speaks of later. Before you ride, tell the trainer what you actually know. You can take both accounts now, or ask the courier to make his meaning plain."
const DIRECT_REPLY := "Then carry the uncertainty with the message. Do not turn a clear trail at dawn into a promise about the whole day."
const CLARIFY_REPLY := "Ask what he saw, and what he only heard. Then take his answer to the trainer yourself."
const COURIER_CLARIFICATION := "I heard hooves beyond the grove. I saw no faces. Do not turn a sound into a name."
const REPORT_DIRECT := "The note says the north trail was clear at dawn. The courier heard riders later, but did not scout the trail. I cannot tell you who they were."
const REPORT_CLARIFIED := "The courier heard hooves beyond the grove but saw no faces. I cannot name those riders. The note only describes the trail at dawn."
const TRAINER_REPLY := "Then keep the two accounts separate. Train your hands here; keep your eyes open when you leave."

static func phase(value: Dictionary) -> String:
	if value.is_empty(): return "dormant"
	var last: String = str(value.receipts.back().kind)
	if last == "report": return "complete"
	return "clarify" if last == "clarify" else "report"

static func begin(choice: String, tick: int) -> Dictionary:
	return {"schema_version": SCHEMA, "choice": choice,
		"receipts": [{"kind": choice, "received_tick": tick}]}

static func _exact(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func _whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value >= 0 and value == floor(value)

static func validate(value: Variant, childhood: Dictionary) -> String:
	if not _exact(value, ["schema_version", "choice", "receipts"]): return "Malformed opening-message receipt."
	if value.schema_version != SCHEMA or value.choice not in ["direct", "clarify"]:
		return "Unknown opening-message route."
	if not value.receipts is Array or value.receipts.is_empty() or value.receipts.size() > 3:
		return "Invalid opening-message receipt count."
	if not childhood.letter_seen or childhood.heard.size() != 2:
		return "Opening-message follow-up before both accounts."
	var account_tick := -1
	var accounts: Array = []
	for memory in childhood.memories:
		if memory.id in ["courier", "steward"]:
			accounts.append(memory.id)
			account_tick = maxi(account_tick, int(memory.received_tick))
	if accounts.size() != 2 or not "courier" in accounts or not "steward" in accounts:
		return "Opening-message follow-up without received testimony."
	var order: Array = ["direct", "report"] if value.choice == "direct" else ["clarify", "confirm", "report"]
	if value.receipts.size() > order.size(): return "Duplicate opening-message receipt."
	var prior := account_tick
	for index in range(value.receipts.size()):
		var receipt: Variant = value.receipts[index]
		if not _exact(receipt, ["kind", "received_tick"]): return "Malformed opening-message step."
		if receipt.kind != order[index]: return "Reordered or unknown opening-message step."
		if not _whole(receipt.received_tick) or receipt.received_tick > childhood.tick or receipt.received_tick < prior:
			return "Invalid opening-message time."
		if childhood.ambush.start_tick >= 0 and receipt.received_tick >= childhood.ambush.start_tick:
			return "Opening-message receipt after the return encounter began."
		# The opening choice can occur while the steward conversation is paused.
		# Subsequent steps require travel to another speaker on a later common tick.
		if index > 0 and receipt.received_tick == prior: return "Opening-message travel has no elapsed time."
		prior = int(receipt.received_tick)
	return ""

static func normalize(value: Dictionary) -> void:
	for receipt in value.receipts: receipt.received_tick = int(receipt.received_tick)

static func journal(value: Dictionary) -> Array:
	var entries: Array = []
	for receipt in value.get("receipts", []):
		var kind: String = str(receipt.kind)
		var source := "self"
		var channel := "decision"
		var words := "I chose to carry both accounts to the trainer, keeping their uncertainty intact."
		if kind == "clarify": words = "I chose to ask the courier what he actually saw before reporting to the trainer."
		elif kind == "confirm":
			source = "fictional_courier"
			channel = "testimony"
			words = COURIER_CLARIFICATION
		elif kind == "report":
			channel = "spoken_report"
			words = REPORT_DIRECT if value.choice == "direct" else REPORT_CLARIFIED
		entries.append({"id": "opening_message_" + kind, "source_id": source,
			"channel": channel, "received_tick": receipt.received_tick, "text": words})
	return entries
