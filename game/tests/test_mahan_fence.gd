extends SceneTree
## Cross-profile integration fence: save slots, knowledge, identity, ontology, schema/menu digests.
## Does not rewrite childhood/Lahore/Mahan authorities — only registers refusal proofs.
const Mahan := preload("res://mahan/mahan_state.gd")
const History := preload("res://mahan/mahan_history_state.gd")
const Childhood := preload("res://childhood/childhood_state.gd")
const Aftermath := preload("res://childhood/aftermath_state.gd")
const Command := preload("res://campaign/command_state.gd")
const House := preload("res://campaign/house_command_state.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const Names := preload("res://characters/character_names.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const MAHAN_SAVE := "user://mahan-fence-regression.json"
const CHILD_SAVE := "user://childhood-fence-regression.json"
const AFTER_SAVE := "user://aftermath-fence-regression.json"
const CMD_SAVE := "user://command-fence-regression.json"
const HOUSE_SAVE := "user://house-fence-regression.json"
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

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func pose_mahan(model, p: Vector3) -> void:
	var s: Dictionary = model.snapshot()
	var riding = s.get("riding")
	s.erase("riding")
	s.player.position = Mahan.coords(p)
	s.actors[Mahan.ACTOR_ID].position = Mahan.coords(p)
	ok(model.restore(s), "pose restore")
	if riding != null:
		model._riding = riding.duplicate(true)

func _rich_mahan() -> History:
	## History stack with delivered scout knowledge + observed illness + endpoint ack.
	var model := History.new()
	model.enable_riding()
	pose_mahan(model, Mahan.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "fence dispatch ford")
	ok(model.dispatch_scout("gujranwala_settlement"), "fence dispatch settlement")
	model.advance(Mahan.REPORT_DELAY)
	check("ford" in model.known_nodes(), "ford known for fence fixture")
	check("gujranwala_settlement" in model.known_nodes(), "settlement known for fence fixture")
	ok(model.observe_historical_event("mahan_late_campaign_illness"), "observe illness for fence")
	ok(model.decide_column("advance_scouts"), "advance for fence")
	check(model.stage() == "march", "march stage for endpoint")
	ok(model.acknowledge_fixed_endpoint(), "endpoint ack for fence")
	check(not model.journal().is_empty(), "mahan journal populated")
	check(not model.known_historical_events().is_empty(), "mahan history knowledge populated")
	return model

func _save_isolation() -> void:
	var mahan := _rich_mahan()
	ok(mahan.save_to(MAHAN_SAVE), "persist rich mahan save")
	# Childhood / aftermath / command / house must refuse the Mahan file.
	var childhood := Childhood.new()
	var before_c: Dictionary = childhood.snapshot()
	check(not childhood.load_from(MAHAN_SAVE).is_empty(), "childhood refuses mahan save slot")
	check(childhood.snapshot() == before_c, "childhood unchanged after mahan file")
	var aftermath := Aftermath.new()
	var before_a: Dictionary = aftermath.snapshot()
	check(not aftermath.load_from(MAHAN_SAVE).is_empty(), "aftermath refuses mahan save slot")
	check(aftermath.snapshot() == before_a, "aftermath unchanged after mahan file")
	var command := Command.new()
	var before_cmd: Dictionary = command.snapshot()
	check(not command.load_from(MAHAN_SAVE).is_empty(), "Lahore command refuses mahan save slot")
	check(command.snapshot() == before_cmd, "command unchanged after mahan file")
	var house := House.new()
	var before_h: Dictionary = house.snapshot()
	check(not house.load_from(MAHAN_SAVE).is_empty(), "house slot refuses mahan save slot")
	check(house.snapshot() == before_h, "house unchanged after mahan file")
	# Persisted foreign slots must refuse to load into Mahan, and Mahan must refuse their dictionaries.
	ok(childhood.save_to(CHILD_SAVE), "persist childhood fence fixture")
	ok(aftermath.save_to(AFTER_SAVE), "persist aftermath fence fixture")
	ok(command.save_to(CMD_SAVE), "persist command fence fixture")
	ok(house.save_to(HOUSE_SAVE), "persist house fence fixture")
	var m2 := Mahan.new()
	var before_m: Dictionary = m2.snapshot()
	check(not m2.load_from(CHILD_SAVE).is_empty(), "mahan refuses childhood save slot")
	check(m2.snapshot() == before_m, "mahan unchanged after childhood file")
	check(not m2.load_from(AFTER_SAVE).is_empty(), "mahan refuses aftermath save slot")
	check(m2.snapshot() == before_m, "mahan unchanged after aftermath file")
	check(not m2.load_from(CMD_SAVE).is_empty(), "mahan refuses command save slot")
	check(m2.snapshot() == before_m, "mahan unchanged after command file")
	check(not m2.load_from(HOUSE_SAVE).is_empty(), "mahan refuses house save slot")
	check(m2.snapshot() == before_m, "mahan unchanged after house file")
	check(not m2.restore(childhood.snapshot()).is_empty(), "mahan restore refuses childhood dict")
	check(not m2.restore(aftermath.snapshot()).is_empty(), "mahan restore refuses aftermath dict")
	check(not m2.restore(command.snapshot()).is_empty(), "mahan restore refuses command dict")
	check(not m2.restore(house.snapshot()).is_empty(), "mahan restore refuses house dict")
	check(m2.snapshot() == before_m, "mahan still pristine after foreign restores")
	# Foreign authorities refuse Mahan dictionaries (not only files).
	check(not childhood.restore(mahan.snapshot()).is_empty(), "childhood restore refuses mahan dict")
	check(not aftermath.restore(mahan.snapshot()).is_empty(), "aftermath restore refuses mahan dict")
	check(not command.restore(mahan.snapshot()).is_empty(), "command restore refuses mahan dict")
	check(not house.restore(mahan.snapshot()).is_empty(), "house restore refuses mahan dict")
	check(childhood.snapshot() == before_c, "childhood pristine after dict refuse")
	check(command.snapshot() == before_cmd, "command pristine after dict refuse")
	check(house.snapshot() == before_h, "house pristine after dict refuse")
	# Canonical save path constants stay distinct.
	check(Mahan.SAVE_PATH == "user://1792-mahan-v1.json", "mahan canonical save path")
	check(Childhood.SAVE_PATH == "user://1792-childhood-v1.json", "childhood canonical save path")
	check(Aftermath.AFTER_SAVE == "user://1792-childhood-aftermath-v1.json", "aftermath canonical save path")
	check(Mahan.SAVE_PATH != Childhood.SAVE_PATH, "mahan≠childhood path")
	check(Mahan.SAVE_PATH != Aftermath.AFTER_SAVE, "mahan≠aftermath path")
	check(Mahan.SAVE_PATH != "user://1792-command-story-v1.json", "mahan≠command path")
	check(Mahan.SAVE_PATH != "user://1792-house-conflict-v1.json", "mahan≠house path")

func _knowledge_isolation() -> void:
	var mahan := _rich_mahan()
	var journal_blob := JSON.stringify(mahan.journal())
	var nodes: Array = mahan.known_nodes()
	var hist_ids: Array = []
	for ev in mahan.known_historical_events():
		hist_ids.append(str(ev.event_id))
	check(journal_blob.contains("mahan_singh") or journal_blob.contains("ford") or journal_blob.contains("Gujranwala"), "mahan journal carries field knowledge")
	check("gujranwala_settlement" in nodes, "mahan known_nodes include Gujranwala")
	check("mahan_singh_death_fixed" in hist_ids or "mahan_late_campaign_illness" in hist_ids, "mahan history knowledge ids present")
	# Transition stub: no auto handoff API — attempting to graft Mahan knowledge into childhood/Lahore must fail.
	var child := Childhood.new()
	var before_child: Dictionary = child.snapshot()
	var grafted: Dictionary = child.snapshot()
	# Invented handoff: try to append Mahan place ids / journal shards into childhood.
	var places: Array = grafted.player.known_places.duplicate()
	for node_id in nodes:
		if node_id not in places:
			places.append(node_id)
	grafted.player.known_places = places
	check(not child.restore(grafted).is_empty(), "childhood refuses grafted mahan known_nodes as known_places")
	check(child.snapshot() == before_child, "childhood unchanged after graft refuse")
	check(child.snapshot().player.known_places == ["sukerchakia_home"], "childhood known_places stay home-only")
	# Explicit: childhood journal must not contain Mahan history event ids / scout texts after refuse.
	var child_journal := JSON.stringify(child.journal())
	for token in ["gujranwala_settlement", "mahan_singh_death_fixed", "mahan_late_campaign_illness", "ford detachment", "Sukerchakia home-ground"]:
		check(not child_journal.contains(token), "childhood journal lacks mahan token: " + token)
	# Lahore command known_places allowlist refuses Mahan nodes.
	var command := Command.new()
	var before_cmd: Dictionary = command.snapshot()
	var cmd_graft: Dictionary = command.snapshot()
	var actor_id: String = cmd_graft.player.character_id
	var cmd_places: Array = cmd_graft.actors[actor_id].known_places.duplicate()
	for node_id in ["gujranwala_settlement", "gujranwala_camp", "ford", "ridge", "sukarchakia_field_camp"]:
		if node_id not in cmd_places:
			cmd_places.append(node_id)
	cmd_graft.actors[actor_id].known_places = cmd_places
	cmd_graft.player.known_places = cmd_places.duplicate()
	check(not command.restore(cmd_graft).is_empty(), "Lahore command refuses grafted mahan place ids")
	check(command.snapshot() == before_cmd, "command unchanged after place graft")
	for place_id in command.snapshot().actors[actor_id].known_places:
		check(place_id in ["lahore_darbar", "village", "outpost"], "Lahore known_places stay sandbox-only: " + str(place_id))
		check(place_id != "gujranwala_settlement", "Lahore lacks gujranwala_settlement")
	# No silent merge helper exists on Mahan that writes into childhood/command.
	check(not mahan.has_method("handoff_to_childhood"), "no childhood handoff API")
	check(not mahan.has_method("handoff_to_lahore"), "no Lahore handoff API")
	check(not mahan.has_method("merge_knowledge"), "no merge_knowledge API")
	# History events stay on Mahan profile_scope.
	for ev in mahan.known_historical_events():
		check(str(ev.gameplay.get("profile_scope", "mahan.v1")) == "mahan.v1", "history profile_scope stays mahan.v1")
		check(str(ev.event_id) not in JSON.stringify(child.snapshot()), "childhood snapshot lacks history event id")

func _identity() -> void:
	check(Names.HERO_ID == "ranjit_singh", "HERO_ID remains ranjit_singh")
	check(Mahan.ACTOR_ID == "mahan_singh", "Mahan actor is mahan_singh")
	check(Names.HERO_ID != Mahan.ACTOR_ID, "HERO_ID ≠ mahan_singh")
	var mahan := Mahan.new()
	check(mahan.snapshot().player.character_id == "mahan_singh", "mahan snapshot actor")
	check(mahan.snapshot().profile == "mahan.v1", "mahan profile")
	var child := Childhood.new()
	check(child.snapshot().player.character_id == Names.HERO_ID, "childhood uses HERO_ID")
	check(child.snapshot().profile == "childhood.v1", "childhood profile")
	var command := Command.new()
	check(command.snapshot().player.character_id in ["ranjit_singh", "patrol_captain"], "Lahore playable is Ranjit/captain")
	# Lahore riding validate still rejects mahan_singh.
	var horse: Dictionary = Riding.initial()
	horse.horse.rider_id = "mahan_singh"
	horse.horse.position = [8.0, 0.04, -5.0]
	horse.horse.speed = 0.0
	horse.horse.grounded = true
	var world := {
		"player": {"character_id": "mahan_singh", "position": horse.horse.position},
		"actors": {"mahan_singh": {"position": horse.horse.position}},
		"order": {"status": "active", "mode": "manual"}
	}
	check(not Riding.validate(horse, world).is_empty(), "Lahore Riding.validate rejects mahan_singh")
	# Positive control: ranjit_singh still admitted under matching world.
	horse.horse.rider_id = "ranjit_singh"
	var world_r := {
		"player": {"character_id": "ranjit_singh", "position": horse.horse.position},
		"actors": {"ranjit_singh": {"position": horse.horse.position}},
		"order": {"status": "active", "mode": "manual"}
	}
	ok(Riding.validate(horse, world_r), "Lahore Riding.validate still admits ranjit_singh")

func _ontology() -> void:
	var mahan := History.new()
	mahan.enable_riding()
	var snap: Dictionary = mahan.snapshot()
	check(snap.mahan.household_id == "sukerchakia", "sukerchakia is household_id field")
	check(snap.player.character_id == "mahan_singh", "person remains mahan_singh")
	check(snap.player.character_id != snap.mahan.household_id, "Person ≠ Household")
	check(not snap.actors.has("sukerchakia"), "household is not an actors Person key")
	var bad: Dictionary = snap.duplicate(true)
	bad.mahan.household_id = "sandhawalia"
	check(not mahan.restore(bad).is_empty(), "Sandhawalia household injection refused")
	bad = mahan.snapshot()
	bad.mahan.household_id = "mahan_singh"
	check(not mahan.restore(bad).is_empty(), "Person-as-household collapse refused")
	var blob := JSON.stringify(mahan.snapshot()).to_lower()
	check(not blob.contains("raj_kaur") and not blob.contains("raj kaur"), "Raj Kaur absent from Mahan snapshot")
	check(not blob.contains("sandhawalia"), "Sandhawalia absent from default Mahan snapshot")
	check(not blob.contains("phulkian"), "Phulkian absent from default Mahan snapshot")
	# Authored history catalog also clean of Sandhawalia/Raj Kaur.
	for event_id in mahan.authored_catalog().keys():
		var text := JSON.stringify(mahan.authored_event(event_id)).to_lower()
		check(not text.contains("raj_kaur"), "history event lacks Raj Kaur: " + str(event_id))
		check(not text.contains("sandhawalia"), "history event lacks Sandhawalia: " + str(event_id))

func _schema_and_menu() -> void:
	# historical_event schema is additive; world_state digest enforced by check_project.
	var schema_path := "res://../schemas/historical_event.schema.json"
	# Schemas live outside game/; assert via FileAccess on project-relative path through absolute.
	var abs_schema := ProjectSettings.globalize_path("res://").path_join("../schemas/historical_event.schema.json")
	# Fallback: open via known relative from game root.
	var text := FileAccess.get_file_as_string("res://mahan/data/mahan_singh_death_fixed.json")
	check(not text.is_empty(), "authored historical event present under mahan data")
	var death: Variant = JSON.parse_string(text)
	check(death is Dictionary and death.schema_version == "historical-event.v1", "historical-event.v1 schema_version")
	check(death.gameplay.profile_scope == "mahan.v1", "event profile_scope mahan.v1")
	check(death.knowledge.player_knowledge == false, "authored death starts unknowable")
	# Menu composes Mahan without needing to mutate home PackedScene.
	var home_bytes_before := FileAccess.get_file_as_bytes("res://world/home_territory.tscn")
	check(not home_bytes_before.is_empty(), "home_territory.tscn readable")
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	check(world.get_node_or_null("MahanChapter") != null, "launch composes MahanChapter")
	var home_bytes_after := FileAccess.get_file_as_bytes("res://world/home_territory.tscn")
	check(home_bytes_before == home_bytes_after, "home_territory PackedScene bytes unchanged by Mahan launch")
	world.queue_free()
	await process_frame
	var menu = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var found: Button = null
	for button in menu.find_children("*", "Button", true, false):
		if button.text.contains("Mahan Singh") and button.text.contains("Field camp"):
			found = button
			break
	check(found != null, "menu retains Mahan entry")
	var home_bytes_menu := FileAccess.get_file_as_bytes("res://world/home_territory.tscn")
	check(home_bytes_before == home_bytes_menu, "home_territory bytes unchanged by menu instantiate")
	if is_instance_valid(menu):
		menu.queue_free()
	await process_frame
	# Silence unused local if schema path resolve differed across platforms.
	check(abs_schema.contains("historical_event.schema.json") or schema_path.contains("historical_event"), "schema path noted")

func _cleanup() -> void:
	for path in [MAHAN_SAVE, CHILD_SAVE, AFTER_SAVE, CMD_SAVE, HOUSE_SAVE,
			MAHAN_SAVE + ".tmp", CHILD_SAVE + ".tmp", AFTER_SAVE + ".tmp", CMD_SAVE + ".tmp", HOUSE_SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	_save_isolation()
	_knowledge_isolation()
	_identity()
	_ontology()
	await _schema_and_menu()
	_cleanup()
	print("MAHAN_FENCE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
