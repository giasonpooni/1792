extends RefCounted
## Deterministic authored-fiction NPC variations for the Mahan/Gujranwala greybox.
## Does not randomize canonical actors, does not write childhood/Lahore saves,
## and does not transfer generated memories into ranjit_singh or mahan_singh.

const TABLES_PATH := "res://npc/data/variation_tables.json"
const SCHEMA := "npc-variation.v1"
const DYNASTY_UNSPECIFIED := "unspecified"
const HOUSEHOLD_UNAFFILIATED := "unaffiliated_fiction"
const FACTION_NONE := "none"

const REFUSE_COUNT := "Refuse: count out of range (1..64)."
const REFUSE_SEED := "Refuse: seed required for deterministic generation."
const REFUSE_TABLES := "Refuse: variation tables missing or invalid."
const REFUSE_CANONICAL := "Refuse: canonical id is fixed and is not a generated NPC."
const REFUSE_FORBIDDEN := "Refuse: forbidden roster id (not a generated extra)."
const REFUSE_SPILL := "Refuse: generated NPC memories do not write into actor journals."
const REFUSE_SITE := "Refuse: site is outside the Mahan/Gujranwala greybox list."
const REFUSE_COLLISION := "Refuse: generated id collided with a canonical or duplicate id."

static func load_tables() -> Dictionary:
	if not FileAccess.file_exists(TABLES_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLES_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func canonical_actor_ids() -> Array:
	return ["mahan_singh", "ranjit_singh"]


static func canonical_household_ids() -> Array:
	return ["sukerchakia"]


static func forbidden_roster_ids() -> Array:
	return ["raj_kaur", "sandhawalia"]


static func is_blocked_id(raw_id: String) -> bool:
	var key := raw_id.strip_edges().to_lower()
	return key in canonical_actor_ids() or key in canonical_household_ids() or key in forbidden_roster_ids()


static func claim_id(requested: String) -> Dictionary:
	## Explicit refusal surface for tests and callers. Never allocates a canonical id.
	var key := requested.strip_edges().to_lower()
	if key.is_empty():
		return {"ok": false, "error": REFUSE_SEED, "id": ""}
	if key in canonical_actor_ids() or key in canonical_household_ids():
		return {"ok": false, "error": REFUSE_CANONICAL, "id": ""}
	if key in forbidden_roster_ids():
		return {"ok": false, "error": REFUSE_FORBIDDEN, "id": ""}
	if key.begins_with("fic_"):
		return {"ok": true, "error": "", "id": key}
	return {"ok": false, "error": REFUSE_CANONICAL, "id": ""}


static func generate(count: int, seed_text: String) -> Dictionary:
	var out := {"ok": false, "error": "", "npcs": []}
	if count < 1 or count > 64:
		out.error = REFUSE_COUNT
		return out
	var seed := seed_text.strip_edges()
	if seed.is_empty():
		out.error = REFUSE_SEED
		return out
	var tables := load_tables()
	if not _tables_ok(tables):
		out.error = REFUSE_TABLES
		return out
	var state := _fnv32(seed)
	var tag := "%08x" % state
	var npcs: Array = []
	var seen := {}
	for index in count:
		var picks := {}
		for field in ["roles", "clothing", "kit", "mount_presence", "disposition_band", "speech_style"]:
			state = _lcg(state)
			var column: Array = tables[field]
			picks[field] = str(column[state % column.size()])
		var npc_id := "fic_%s_%03d" % [tag, index]
		if is_blocked_id(npc_id) or seen.has(npc_id):
			out.error = REFUSE_COLLISION
			out.npcs = []
			return out
		seen[npc_id] = true
		var disposition := str(picks.disposition_band)
		npcs.append({
			"schema_version": SCHEMA,
			"id": npc_id,
			"person_id": npc_id,
			"display_name": "Fiction %s %s" % [str(picks.roles), npc_id],
			"kind": "person",
			"historical_person": false,
			"canon_class": "game_canon_fiction",
			"role": str(picks.roles),
			"clothing": str(picks.clothing),
			"kit": str(picks.kit),
			"mount_presence": str(picks.mount_presence),
			"disposition_band": disposition,
			"speech_style": str(picks.speech_style),
			"dynasty_id": DYNASTY_UNSPECIFIED,
			"household_id": HOUSEHOLD_UNAFFILIATED,
			"faction_id": FACTION_NONE,
			"current_alignment": disposition,
			"seed": seed,
			"index": index,
			"memories": [],
			"refuses_write_to": canonical_actor_ids(),
		})
	out.ok = true
	out.npcs = npcs
	return out


static func for_site(site_id: String, seed_text: String, count: int) -> Dictionary:
	var tables := load_tables()
	var sites: Array = tables.get("greybox_sites", [])
	if not site_id in sites:
		return {"ok": false, "error": REFUSE_SITE, "npcs": []}
	var generated := generate(count, seed_text)
	if not generated.ok:
		return generated
	var tagged: Array = []
	for raw in generated.npcs:
		var npc: Dictionary = raw
		npc["present_at"] = site_id
		npc["profile_scope"] = "mahan.v1"
		npc["usable_by"] = ["mahan_greybox", "gujranwala_greybox"]
		tagged.append(npc)
	generated.npcs = tagged
	return generated


static func attach_memory(npc: Dictionary, text: String, tick: int) -> Dictionary:
	var npc_id := str(npc.get("id", ""))
	if is_blocked_id(npc_id) or not npc_id.begins_with("fic_"):
		return {"ok": false, "error": REFUSE_CANONICAL, "npc": npc}
	var out: Dictionary = npc.duplicate(true)
	var mems: Array = out.get("memories", [])
	mems.append({
		"text": text,
		"tick": tick,
		"owner_id": npc_id,
		"scope": "generated_npc_only",
		"transfers_to": [],
	})
	out["memories"] = mems
	return {"ok": true, "error": "", "npc": out}


static func spill_memories_to_journal(actor_id: String, journal: Array, npcs: Array) -> Dictionary:
	## Always refuses. Generated memories never copy into any actor journal,
	## including ranjit_singh (Buddh) and mahan_singh.
	var unchanged: Array = journal.duplicate(true)
	var _ignored := npcs.size()
	return {
		"ok": false,
		"error": REFUSE_SPILL,
		"actor_id": actor_id.strip_edges().to_lower(),
		"journal": unchanged,
		"wrote": 0,
		"ignored_npc_count": _ignored,
	}


static func _tables_ok(tables: Dictionary) -> bool:
	if tables.is_empty():
		return false
	if str(tables.get("schema_version", "")) != SCHEMA:
		return false
	for field in ["roles", "clothing", "kit", "mount_presence", "disposition_band", "speech_style"]:
		var column: Variant = tables.get(field, [])
		if typeof(column) != TYPE_ARRAY or column.is_empty():
			return false
	return true


static func _fnv32(text: String) -> int:
	var h := 2166136261
	for i in text.length():
		h = ((h ^ text.unicode_at(i)) * 16777619) & 0xFFFFFFFF
	return h


static func _lcg(state: int) -> int:
	return int((int(state) * 1664525 + 1013904223) & 0xFFFFFFFF)
