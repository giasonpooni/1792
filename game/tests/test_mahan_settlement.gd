extends SceneTree
const Model := preload("res://mahan/mahan_settlement_state.gd")
const Encounter := preload("res://mahan/mahan_encounter_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-settlement-regression.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), label + " refused")
	check(model.snapshot() == before, label + " unchanged")

func pose(model, p: Vector3) -> void:
	var s: Dictionary = model.snapshot()
	var riding = s.get("riding")
	s.erase("riding")
	s.player.position = Base.coords(p)
	s.actors[Base.ACTOR_ID].position = Base.coords(p)
	ok(model.restore(s), "pose restore")
	if riding != null:
		model._riding = riding.duplicate(true)

func _to_gujranwala_settlement(model) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.forage(), "forage camp before dispatch")
	ok(model.dispatch_scout("gujranwala_fort_road"), "dispatch fort road")
	ok(model.dispatch_scout("gujranwala_camp"), "dispatch gujranwala camp")
	ok(model.dispatch_scout("gujranwala_settlement"), "dispatch settlement")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision stage")
	ok(model.decide_column("advance_scouts"), "advance column")
	check(model.stage() == "march", "march stage")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.march_to("gujranwala_fort_road"), "march to fort road")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.forage(), "forage fort road")
	pose(model, Base.SITES.gujranwala_camp)
	ok(model.march_to("gujranwala_camp"), "march to gujranwala camp")
	pose(model, Base.SITES.gujranwala_camp)
	ok(model.forage(), "forage gujranwala camp")
	pose(model, Base.SITES.gujranwala_settlement)
	ok(model.march_to("gujranwala_settlement"), "march to settlement")
	pose(model, Base.SITES.gujranwala_settlement)

func _to_advance_custody(model) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.dispatch_scout("gujranwala_fort_road"), "adv dispatch fort")
	ok(model.dispatch_scout("gujranwala_camp"), "adv dispatch camp")
	ok(model.dispatch_scout("gujranwala_settlement"), "adv dispatch settlement")
	model.advance(Model.REPORT_DELAY)
	ok(model.decide_column("advance_scouts"), "adv decide")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.march_to("gujranwala_fort_road"), "adv march fort")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.dispatch_approach_scout(), "adv approach scout")
	model.advance(Model.ENCOUNTER_DELAY)
	ok(model.resolve_encounter_choice("advance_under_custody"), "resolve advance under custody")

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial settlement snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("settlement"), "settlement envelope present")
	check(model.snapshot().mahan.has("encounter"), "encounter envelope still present")
	check(model.settlement().examined.is_empty(), "no markers examined yet")
	check(model.settlement_fact_known(Model.FACT_LOCAL_WORD) == false, "local word sealed initially")
	check(model.pending_settlement_rumors().is_empty(), "no settlement rumor pending")
	## Encounter adapter stays settlement-free.
	var enc := Encounter.new()
	enc.enable_riding()
	check(not enc.snapshot().mahan.has("settlement"), "encounter adapter stays settlement-free")
	## Refuse before settlement unlock.
	reject(model, model.examine_settlement_marker.bind("walls"), "examine before unlock")
	reject(model, model.request_local_settlement_rumor, "rumor before unlock")
	## Path A: column at gujranwala_settlement.
	_to_gujranwala_settlement(model)
	ok(model.settlement_observation_available(), "observation available at settlement")
	pose(model, Model.SETTLEMENT_MARKERS.walls)
	ok(model.examine_settlement_marker("walls"), "examine walls")
	check("walls" in model.examined_markers(), "walls recorded")
	reject(model, model.examine_settlement_marker.bind("walls"), "duplicate walls")
	pose(model, Model.SETTLEMENT_MARKERS.gate)
	ok(model.examine_settlement_marker("gate"), "examine gate")
	pose(model, Model.SETTLEMENT_MARKERS.well)
	ok(model.examine_settlement_marker("well"), "examine well")
	pose(model, Model.SETTLEMENT_MARKERS.house)
	ok(model.examine_settlement_marker("house"), "examine house")
	check(model.examined_markers().size() == 4, "all four markers examined")
	var wall_mem := false
	for memory in model.journal():
		if memory.id == "settlement_examine_walls" and memory.channel == "settlement_observation" and memory.source_id == "self":
			if memory.has("received_tick") and memory.observer_id == "mahan_singh":
				wall_mem = true
	check(wall_mem, "walls memory attributed with source/channel/tick")
	## Delayed local rumor: sealed until delivery.
	pose(model, Base.SITES.gujranwala_settlement)
	ok(model.request_local_settlement_rumor(), "request local rumor")
	check(model.pending_settlement_rumors().size() == 1, "rumor pending")
	check(model.settlement_fact_known(Model.FACT_LOCAL_WORD) == false, "player_knowledge false while pending")
	check(model.journal().filter(func(m): return str(m.id) == "settlement_local_rumor.report").is_empty(), "no early rumor journal")
	reject(model, model.request_local_settlement_rumor, "duplicate rumor request")
	model.advance(Model.SETTLEMENT_DELAY - 1)
	check(model.pending_settlement_rumors().size() == 1, "still pending one tick early")
	check(model.settlement_fact_known(Model.FACT_LOCAL_WORD) == false, "still sealed one tick early")
	model.advance(1)
	check(model.received_settlement_rumors().size() == 1, "rumor delivered")
	check(model.pending_settlement_rumors().is_empty(), "no pending after delivery")
	check(model.settlement_fact_known(Model.FACT_LOCAL_WORD) == true, "player_knowledge true on delivery")
	var rumor_mem := false
	for memory in model.journal():
		if memory.id == "settlement_local_rumor.report" and memory.channel == "delayed_settlement_rumor":
			rumor_mem = true
	check(rumor_mem, "rumor memory on delivery only")
	ok(model.validate(model.snapshot()), "valid after settlement beat")
	## Path B: after encounter advance_under_custody (column may still be on fort road).
	var advanced := Model.new()
	advanced.enable_riding()
	_to_advance_custody(advanced)
	check(advanced.encounter().choice == "advance_under_custody", "advance path unlocked")
	pose(advanced, Base.SITES.gujranwala_settlement)
	# column_node may still be fort_road; near settlement + after advance unlocks.
	ok(advanced.settlement_observation_available(), "observation available after advance")
	pose(advanced, Model.SETTLEMENT_MARKERS.gate)
	ok(advanced.examine_settlement_marker("gate"), "examine gate after advance")
	## Fixed endpoint still reachable; no combat/economy/omniscience APIs.
	pose(model, Base.SITES.camp_table)
	ok(model.acknowledge_fixed_endpoint(), "fixed endpoint after settlement")
	check(model.stage() == "closed", "closed after endpoint")
	check(not model.has_method("alter_historical_outcome"), "no alter_outcome method")
	check(not model.has_method("open_town_economy"), "no town economy method")
	check(not model.has_method("omniscient_settlement_survey"), "no omniscience method")
	## Ontology + save/load + forbidden tokens.
	var round := Model.new()
	round.enable_riding()
	_to_gujranwala_settlement(round)
	pose(round, Model.SETTLEMENT_MARKERS.walls)
	ok(round.examine_settlement_marker("walls"), "round examine walls")
	pose(round, Base.SITES.gujranwala_settlement)
	ok(round.request_local_settlement_rumor(), "round request rumor")
	ok(round.save_to(SAVE), "save settlement")
	var again := Model.new()
	ok(again.load_from(SAVE), "load settlement")
	check(again.examined_markers() == ["walls"], "examined round trip")
	check(again.pending_settlement_rumors().size() == 1, "pending rumor round trip")
	check(again.settlement_fact_known(Model.FACT_LOCAL_WORD) == false, "fact still sealed round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	check(again.resolve_place_id("gujranwala_settlement"), "settlement still place object")
	check(not again.snapshot().actors.has("gujranwala_settlement"), "settlement not a person actor")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.settlement.rumors[0].text = "rewritten"
	reject(again, again.restore.bind(bad), "settlement rumor text rewrite")
	bad = again.snapshot()
	bad.mahan.settlement.facts[Model.FACT_LOCAL_WORD].player_knowledge = true
	reject(again, again.restore.bind(bad), "premature player_knowledge")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from settlement slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from settlement slice")
	check(not snap_text.contains("sandhawalia") and not snap_text.contains("Sandhawalia"), "Sandhawalia absent from settlement snapshot")
	check(not snap_text.to_lower().contains("khalsa faith") and not snap_text.to_lower().contains("religious war"), "no religious framing tokens")
	## Examine texts stay sealed / non-omniscient.
	for kind in Model.EXAMINE_TEXTS:
		var t: String = str(Model.EXAMINE_TEXTS[kind].text).to_lower()
		check("omniscience" in t or "sealed" in t or "not invent" in t or "does not invent" in t or "not a person" in t or "greybox" in t or "local" in t, "examine text stays limited: " + kind)

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes settlement chapter")
	check(chapter.campaign.has_method("examine_settlement_marker"), "chapter campaign is settlement model")
	check(chapter.campaign.has_method("begin_ridge_settlement_encounter"), "settlement still exposes encounter")
	check(chapter.campaign.has_method("observe_historical_event"), "settlement still exposes history")
	check(chapter.campaign.has_method("issue_sub_order"), "settlement still exposes orders")
	check(chapter.campaign.has_method("consult_subordinates"), "settlement still exposes politics")
	check(chapter.campaign.has_method("forage"), "settlement still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("settlement"), "chapter settlement envelope")
	check(chapter.campaign.snapshot().mahan.has("encounter"), "chapter encounter envelope")
	check(chapter.campaign.snapshot().mahan.has("history"), "chapter history envelope")
	check(chapter.campaign.snapshot().mahan.household_id == "sukerchakia", "chapter household object")
	check(chapter.get_node_or_null("FieldHorse") != null, "horse still spawned")
	world.queue_free()
	await process_frame

func _run() -> void:
	_domain()
	await _smoke()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_SETTLEMENT_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
