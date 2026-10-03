extends SceneTree
## Deterministic fiction NPC variations. No canonical randomization, no Buddh journal writes.
const Npc := preload("res://npc/npc_variation.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _run() -> void:
	_tables()
	_determinism()
	_uniqueness_and_ontology()
	_refusals()
	_epistemic_fence()
	_greybox_site()
	print("NPC_VARIATION_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _tables() -> void:
	var tables := Npc.load_tables()
	check(not tables.is_empty(), "tables load")
	check(tables.schema_version == "npc-variation.v1", "schema version")
	check(tables.canon_class == "game_canon_fiction", "tables canon class")
	check(tables.not_historical_persons == true, "tables mark non-historical")
	for field in ["roles", "clothing", "kit", "mount_presence", "disposition_band", "speech_style"]:
		check(tables[field] is Array and not tables[field].is_empty(), "column " + field)
	check(tables.canonical_actor_ids == ["mahan_singh", "ranjit_singh"], "canonical actors listed fixed")
	check(tables.canonical_household_ids == ["sukerchakia"], "sukerchakia household fixed")
	check("raj_kaur" in tables.forbidden_roster_ids, "raj_kaur forbidden")
	check("sandhawalia" in tables.forbidden_roster_ids, "sandhawalia forbidden")
	var blob := JSON.stringify(tables).to_lower()
	check(not blob.contains("sandhawalia roster"), "no sandhawalia roster prose")
	for column_name in ["roles", "clothing", "kit", "mount_presence", "disposition_band", "speech_style"]:
		for entry in tables[column_name]:
			var token := str(entry).to_lower()
			check(token != "raj_kaur" and token != "sandhawalia", "table entry not forbidden: " + token)
			check(token != "mahan_singh" and token != "ranjit_singh", "table entry not canonical actor: " + token)

func _determinism() -> void:
	var a := Npc.generate(4, "greybox-1792")
	var b := Npc.generate(4, "greybox-1792")
	check(a.ok and b.ok, "generate ok")
	check(JSON.stringify(a.npcs) == JSON.stringify(b.npcs), "same seed identical records")
	var first: Dictionary = a.npcs[0]
	check(first.id == "fic_38ed52f9_000", "seed tag id 0")
	check(first.role == "traveler", "npc0 role")
	check(first.clothing == "camp_tunic", "npc0 clothing")
	check(first.kit == "empty_hands", "npc0 kit")
	check(first.mount_presence == "mounted", "npc0 mount")
	check(first.disposition_band == "wary", "npc0 disposition")
	check(first.speech_style == "quiet", "npc0 speech")
	check(first.display_name == "Fiction traveler fic_38ed52f9_000", "npc0 display")
	var second: Dictionary = a.npcs[1]
	check(second.id == "fic_38ed52f9_001", "id 1")
	check(second.role == "scout", "npc1 role")
	check(second.clothing == "camp_tunic", "npc1 clothing")
	check(second.kit == "waterskin", "npc1 kit")
	check(second.mount_presence == "led_horse", "npc1 mount")
	check(second.disposition_band == "cordial", "npc1 disposition")
	check(second.speech_style == "formal", "npc1 speech")
	var third: Dictionary = a.npcs[2]
	check(third.role == "scout" and third.kit == "staff" and third.clothing == "travel_wrap", "npc2 picks")
	check(third.mount_presence == "led_horse" and third.speech_style == "quiet", "npc2 mount speech")
	var fourth: Dictionary = a.npcs[3]
	check(fourth.role == "gate_watcher" and fourth.clothing == "plain_cotton", "npc3 role clothing")
	check(fourth.mount_presence == "mounted" and fourth.disposition_band == "cordial", "npc3 mount disposition")
	var other := Npc.generate(4, "other-seed")
	check(other.ok, "other seed ok")
	check(other.npcs[0].id != first.id, "different seed different id")
	check(JSON.stringify(other.npcs) != JSON.stringify(a.npcs), "different seed different records")

func _uniqueness_and_ontology() -> void:
	var generated := Npc.generate(8, "greybox-1792")
	check(generated.npcs.size() == 8, "count 8")
	var ids := {}
	var roles := {}
	for raw in generated.npcs:
		var npc: Dictionary = raw
		var npc_id := str(npc.id)
		check(not ids.has(npc_id), "unique id " + npc_id)
		ids[npc_id] = true
		roles[str(npc.role)] = true
		check(npc.kind == "person", "kind person")
		check(npc.historical_person == false, "not historical person")
		check(npc.canon_class == "game_canon_fiction", "fiction canon class")
		check(npc.person_id == npc_id, "person id is the generated id")
		check(npc.dynasty_id == "unspecified", "dynasty separate")
		check(npc.household_id == "unaffiliated_fiction", "household not a clan roster")
		check(npc.faction_id == "none", "faction separate")
		check(npc.current_alignment == npc.disposition_band, "alignment is disposition not household")
		check(npc.person_id != npc.dynasty_id, "person \u2260 dynasty")
		check(npc.dynasty_id != npc.household_id, "dynasty \u2260 household")
		check(npc.household_id != npc.faction_id, "household \u2260 faction")
		check(npc.faction_id != str(npc.current_alignment), "faction \u2260 current alignment")
		check(npc.household_id != "sukerchakia", "not filed as sukerchakia")
		check(npc.id != "mahan_singh" and npc.id != "ranjit_singh", "not a canonical actor id")
		check(npc.memories.is_empty(), "starts with no memories")
		var blob := JSON.stringify(npc).to_lower()
		check(not blob.contains("raj_kaur"), "record omits raj_kaur")
		check(not blob.contains("sandhawalia"), "record omits sandhawalia")
	check(roles.size() >= 2, "role variation across batch")

func _refusals() -> void:
	var zero := Npc.generate(0, "greybox-1792")
	check(not zero.ok and zero.npcs.is_empty(), "count 0 refuses")
	check(zero.error == Npc.REFUSE_COUNT, "count 0 message")
	var huge := Npc.generate(65, "greybox-1792")
	check(not huge.ok, "count 65 refuses")
	var blank := Npc.generate(2, "   ")
	check(not blank.ok and blank.error == Npc.REFUSE_SEED, "blank seed refuses")
	for blocked in ["mahan_singh", "ranjit_singh", "sukerchakia", "Raj_Kaur", "Sandhawalia"]:
		var claim := Npc.claim_id(blocked)
		check(not claim.ok and claim.id == "", "claim refuses " + blocked)
	check(Npc.claim_id("mahan_singh").error == Npc.REFUSE_CANONICAL, "mahan canonical refuse")
	check(Npc.claim_id("ranjit_singh").error == Npc.REFUSE_CANONICAL, "ranjit canonical refuse")
	check(Npc.claim_id("sukerchakia").error == Npc.REFUSE_CANONICAL, "household canonical refuse")
	check(Npc.claim_id("raj_kaur").error == Npc.REFUSE_FORBIDDEN, "raj_kaur forbidden")
	check(Npc.claim_id("sandhawalia").error == Npc.REFUSE_FORBIDDEN, "sandhawalia forbidden")
	var ok_claim := Npc.claim_id("fic_example")
	check(ok_claim.ok and ok_claim.id == "fic_example", "fiction id claim allowed")
	var bare := Npc.claim_id("some_traveler")
	check(not bare.ok, "non fic_ id refused")

func _epistemic_fence() -> void:
	var generated := Npc.generate(2, "greybox-1792")
	var npc: Dictionary = generated.npcs[0]
	var remembered := Npc.attach_memory(npc, "Saw dust on the fort road.", 12)
	check(remembered.ok, "attach memory ok")
	var owned: Dictionary = remembered.npc
	check(owned.memories.size() == 1, "one memory")
	check(owned.memories[0].owner_id == owned.id, "memory owned by generated npc")
	check(owned.memories[0].transfers_to.is_empty(), "memory transfers_to empty")
	check(owned.memories[0].scope == "generated_npc_only", "memory scope local")
	check(npc.memories.is_empty(), "source record not mutated")
	var buddh_journal := [{"owner": "ranjit_singh", "text": "private childhood note"}]
	var before := JSON.stringify(buddh_journal)
	var spill := Npc.spill_memories_to_journal("ranjit_singh", buddh_journal, [owned])
	check(not spill.ok, "spill to ranjit refuses")
	check(spill.error == Npc.REFUSE_SPILL, "spill message")
	check(spill.wrote == 0, "spill wrote nothing")
	check(JSON.stringify(buddh_journal) == before, "ranjit journal unchanged")
	check(JSON.stringify(spill.journal) == before, "returned journal is the original")
	check(not JSON.stringify(spill.journal).contains("fort road"), "memory text absent from ranjit journal")
	var mahan_journal := [{"owner": "mahan_singh", "text": "fixed column note"}]
	var mahan_before := JSON.stringify(mahan_journal)
	var spill_mahan := Npc.spill_memories_to_journal("mahan_singh", mahan_journal, [owned])
	check(not spill_mahan.ok and spill_mahan.wrote == 0, "spill to mahan_singh refuses")
	check(JSON.stringify(mahan_journal) == mahan_before, "mahan journal unchanged")
	var canon_memory := Npc.attach_memory({"id": "ranjit_singh", "memories": []}, "nope", 1)
	check(not canon_memory.ok, "cannot attach memory onto ranjit_singh")
	check(canon_memory.error == Npc.REFUSE_CANONICAL, "canonical attach message")

func _greybox_site() -> void:
	var placed := Npc.for_site("gujranwala_settlement", "greybox-1792", 3)
	check(placed.ok and placed.npcs.size() == 3, "settlement spawn")
	for raw in placed.npcs:
		var npc: Dictionary = raw
		check(npc.present_at == "gujranwala_settlement", "present at settlement")
		check(npc.profile_scope == "mahan.v1", "profile scope mahan")
		check("gujranwala_greybox" in npc.usable_by, "usable by gujranwala greybox")
	var again := Npc.for_site("gujranwala_settlement", "greybox-1792", 3)
	check(JSON.stringify(again.npcs) == JSON.stringify(placed.npcs), "site spawn deterministic")
	var garhi := Npc.for_site("gujranwala_garhi", "greybox-1792", 1)
	check(garhi.ok and garhi.npcs[0].present_at == "gujranwala_garhi", "garhi spawn")
	var lahore := Npc.for_site("lahore_court", "greybox-1792", 2)
	check(not lahore.ok and lahore.npcs.is_empty(), "lahore site refused")
	check(lahore.error == Npc.REFUSE_SITE, "lahore refuse message")
	var home := Npc.for_site("home_territory", "greybox-1792", 1)
	check(not home.ok, "childhood home site refused")
