extends RefCounted
## Explicit opt-in Mahan → Buddh / ranjit_singh handoff cutter.
## REFUSES by default. Never silently merges journal or map knowledge.
## Live childhood / Buddh save-slot writes are FUTURE — apply_transfer must not
## mutate childhood_state slots in this stub even when the controller opts in.
## Does not rewrite childhood_state, command_state, house_command_state, or
## character_names accession inference. No silent transition on menu load.

const SOURCE_PROFILE := "mahan.v1"
const TARGET_ACTOR_HINT := "ranjit_singh"
const CHILDHOOD_SAVE_HINT := "user://1792-childhood-v1.json"

const REFUSE_DEFAULT := "Refuse: handoff disabled by default (no controller opt-in)."
const REFUSE_NO_ALLOWLIST := "Refuse: empty allowlist; selected report IDs required."
const REFUSE_ID_NOT_ALLOWED := "Refuse: report id not on controller allowlist."
const REFUSE_EMPTY_IDS := "Refuse: no report ids proposed."
const REFUSE_BAD_SOURCE := "Refuse: source profile is not mahan.v1."
const REFUSE_WHOLESALE_JOURNAL := "Refuse: wholesale journal merge is forbidden."
const REFUSE_JOURNAL_TEXTS := "Refuse: journal texts must never copy wholesale."
const REFUSE_KNOWN_NODES := "Refuse: writing mahan known_nodes into Buddh knowledge bag without allowlist."
const REFUSE_NO_APPROVE_APPLY := "Refuse: apply requires explicit approve_apply on controller."
const REFUSE_CHILDHOOD_SLOT := "Refuse: live childhood/Buddh save-slot write is not implemented in this stub (future)."
const REFUSE_HISTORICAL_OUTCOME := "Refuse: historical_outcome / fixed death endpoint must stay fixed."
const REFUSE_SILENT_MERGE := "Refuse: silent knowledge merge is forbidden."
const REFUSE_BAD_PACKET := "Refuse: malformed transfer packet."
const REFUSE_ALTER_OUTCOME := "Refuse: cannot alter fixed historical_outcome via handoff."

static func fresh_controller() -> Dictionary:
	## Default deny. Opt-in requires opt_in=true, a non-empty report allowlist,
	## and (for apply) approve_apply=true. Childhood slot writes stay false forever
	## in this stub — even if a caller flips the flag, apply refuses the write.
	return {
		"opt_in": false,
		"allowlist_report_ids": [],
		"allowlist_known_nodes": [],
		"approve_apply": false,
		"allow_childhood_slot_write": false
	}


static func can_handoff(controller: Dictionary = {}) -> bool:
	## True only when the controller explicitly opts in with a non-empty report allowlist.
	## Default / empty controller → false (refuse).
	if controller.is_empty():
		return false
	if not bool(controller.get("opt_in", false)):
		return false
	var allow: Array = _as_string_array(controller.get("allowlist_report_ids", []))
	return not allow.is_empty()


static func propose_transfer(
	report_ids: Array,
	source_snapshot: Dictionary = {},
	controller: Dictionary = {}
) -> Dictionary:
	## Build a dry proposal of *selected* report IDs only.
	## Never copies journal text bodies. Returns {ok, error, packet}.
	var out := {"ok": false, "error": "", "packet": {}}
	if not can_handoff(controller):
		if controller.is_empty() or not bool(controller.get("opt_in", false)):
			out.error = REFUSE_DEFAULT
		else:
			out.error = REFUSE_NO_ALLOWLIST
		return out
	if report_ids.is_empty():
		out.error = REFUSE_EMPTY_IDS
		return out
	if not source_snapshot.is_empty():
		var profile := str(source_snapshot.get("profile", ""))
		if profile != "" and profile != SOURCE_PROFILE:
			out.error = REFUSE_BAD_SOURCE
			return out
	var allow: Array = _as_string_array(controller.get("allowlist_report_ids", []))
	var selected: Array = []
	for raw in report_ids:
		var rid := str(raw)
		if rid.is_empty():
			continue
		if rid == "*" or rid.to_lower() == "all" or rid.to_lower() == "journal":
			out.error = REFUSE_WHOLESALE_JOURNAL
			return out
		if rid not in allow:
			out.error = REFUSE_ID_NOT_ALLOWED + " (%s)" % rid
			return out
		if rid not in selected:
			selected.append(rid)
	if selected.is_empty():
		out.error = REFUSE_EMPTY_IDS
		return out
	# Packet: selected IDs only — no journal texts, no known_nodes dump, outcome fixed.
	out.packet = {
		"schema": "mahan-handoff-proposal.v1",
		"source_profile": SOURCE_PROFILE,
		"target_actor_hint": TARGET_ACTOR_HINT,
		"report_ids": selected.duplicate(),
		"journal_texts": [],  # intentionally empty; wholesale copy forbidden
		"known_nodes": [],  # map knowledge not auto-included
		"historical_outcome_fixed": true,
		"silent_merge": false
	}
	out.ok = true
	return out


static func apply_transfer(
	packet: Dictionary,
	controller: Dictionary = {},
	target: Dictionary = {}
) -> Dictionary:
	## Apply a previously proposed packet under an explicit controller.
	## Primarily refuse paths. Even when opted in:
	##   - never writes childhood save slots (stub / future)
	##   - never copies journal texts wholesale
	##   - never mutates historical_outcome / fixed death
	##   - refuses grafting known_nodes into a Buddh bag without allowlist_known_nodes
	## Returns {ok, error, receipt, bag}.
	var out := {"ok": false, "error": "", "receipt": {}, "bag": {}}
	if target.get("silent_merge", false) == true or target.get("auto_merge", false) == true:
		out.error = REFUSE_SILENT_MERGE
		return out
	if bool(target.get("merge_journal_wholesale", false)):
		out.error = REFUSE_WHOLESALE_JOURNAL
		return out
	if target.has("journal_texts"):
		var texts = target.get("journal_texts")
		if texts is Array and not texts.is_empty():
			out.error = REFUSE_JOURNAL_TEXTS
			return out
		if texts is String and not str(texts).is_empty():
			out.error = REFUSE_JOURNAL_TEXTS
			return out
	if not can_handoff(controller):
		if controller.is_empty() or not bool(controller.get("opt_in", false)):
			out.error = REFUSE_DEFAULT
		else:
			out.error = REFUSE_NO_ALLOWLIST
		return out
	if not bool(controller.get("approve_apply", false)):
		out.error = REFUSE_NO_APPROVE_APPLY
		return out
	var perr := _validate_packet(packet, controller)
	if not perr.is_empty():
		out.error = perr
		return out
	# historical_outcome must stay fixed — refuse any attempt to flip it.
	if target.has("historical_outcome"):
		out.error = REFUSE_HISTORICAL_OUTCOME
		return out
	if target.get("alter_historical_outcome", false) == true:
		out.error = REFUSE_ALTER_OUTCOME
		return out
	if packet.get("historical_outcome_fixed", true) != true:
		out.error = REFUSE_HISTORICAL_OUTCOME
		return out
	# Childhood / Buddh save-slot write: always refused in this stub.
	var slot_path := str(target.get("childhood_save_path", ""))
	if slot_path.is_empty():
		slot_path = str(target.get("write_save_path", ""))
	if not slot_path.is_empty() or bool(controller.get("allow_childhood_slot_write", false)) \
			or bool(target.get("write_childhood_slot", false)):
		out.error = REFUSE_CHILDHOOD_SLOT
		return out
	# Fake Buddh knowledge bag: refuse known_nodes graft without allowlist.
	var bag: Dictionary = {}
	if target.get("knowledge_bag") is Dictionary:
		bag = (target.knowledge_bag as Dictionary).duplicate(true)
	out.bag = bag
	if target.has("graft_known_nodes"):
		var nodes: Array = _as_string_array(target.get("graft_known_nodes", []))
		var node_allow: Array = _as_string_array(controller.get("allowlist_known_nodes", []))
		if not nodes.is_empty() and node_allow.is_empty():
			out.error = REFUSE_KNOWN_NODES
			return out
		for node_id in nodes:
			if node_id not in node_allow:
				out.error = REFUSE_KNOWN_NODES + " (%s)" % node_id
				return out
		# Even with node allowlist: stub records intent only — does not mutate bag map
		# knowledge silently into childhood. Dry-run receipt lists ids; bag unchanged
		# unless caller also passed an explicit accept_node_dry_run (still no slot write).
		if bool(target.get("accept_node_dry_run", false)):
			if not bag.has("transferred_node_ids"):
				bag["transferred_node_ids"] = []
			for node_id in nodes:
				if node_id not in bag.transferred_node_ids:
					bag.transferred_node_ids.append(node_id)
			out.bag = bag
	# Success path (opt-in + allowlist + approve): dry-run receipt only.
	# Does not touch childhood_state / command_state / house_command_state.
	var report_ids: Array = _as_string_array(packet.get("report_ids", []))
	if bool(target.get("accept_report_dry_run", false)):
		if not bag.has("transferred_report_ids"):
			bag["transferred_report_ids"] = []
		for rid in report_ids:
			if rid not in bag.transferred_report_ids:
				bag.transferred_report_ids.append(rid)
		out.bag = bag
	out.receipt = {
		"applied": false,  # live apply is future
		"dry_run": true,
		"source_profile": SOURCE_PROFILE,
		"target_actor_hint": TARGET_ACTOR_HINT,
		"report_ids": report_ids.duplicate(),
		"journal_texts_copied": 0,
		"known_nodes_copied": 0,
		"childhood_slot_written": false,
		"historical_outcome_fixed": true
	}
	out.ok = true
	return out


static func refuse_wholesale_journal_merge(
	journal: Array = [],
	controller: Dictionary = {}
) -> String:
	## Explicit helper: journal bodies never copy wholesale, even if opted in.
	if not journal.is_empty():
		return REFUSE_WHOLESALE_JOURNAL
	# Empty journal still refused as a merge operation — there is no merge API.
	if can_handoff(controller):
		return REFUSE_WHOLESALE_JOURNAL
	return REFUSE_DEFAULT


static func _validate_packet(packet: Dictionary, controller: Dictionary) -> String:
	if packet.is_empty() or str(packet.get("schema", "")) != "mahan-handoff-proposal.v1":
		return REFUSE_BAD_PACKET
	if str(packet.get("source_profile", "")) != SOURCE_PROFILE:
		return REFUSE_BAD_SOURCE
	if packet.get("silent_merge", false) == true:
		return REFUSE_SILENT_MERGE
	var texts = packet.get("journal_texts", [])
	if texts is Array and not texts.is_empty():
		return REFUSE_JOURNAL_TEXTS
	if texts is String and not str(texts).is_empty():
		return REFUSE_JOURNAL_TEXTS
	var nodes = packet.get("known_nodes", [])
	if nodes is Array and not nodes.is_empty():
		# Packet must not smuggle map knowledge; use graft_known_nodes + allowlist.
		return REFUSE_KNOWN_NODES
	var allow: Array = _as_string_array(controller.get("allowlist_report_ids", []))
	var ids: Array = _as_string_array(packet.get("report_ids", []))
	if ids.is_empty():
		return REFUSE_EMPTY_IDS
	for rid in ids:
		if rid not in allow:
			return REFUSE_ID_NOT_ALLOWED + " (%s)" % rid
	if packet.get("historical_outcome_fixed", true) != true:
		return REFUSE_HISTORICAL_OUTCOME
	return ""


static func _as_string_array(value: Variant) -> Array:
	var out: Array = []
	if value == null:
		return out
	if value is PackedStringArray:
		for item in value:
			var s := str(item)
			if not s.is_empty() and s not in out:
				out.append(s)
		return out
	if value is Array:
		for item in value:
			var s2 := str(item)
			if not s2.is_empty() and s2 not in out:
				out.append(s2)
	return out
