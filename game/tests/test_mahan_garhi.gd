extends SceneTree
const Model := preload("res://mahan/mahan_garhi_state.gd")
const Settlement := preload("res://mahan/mahan_settlement_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-garhi-regression.json"
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

func _to_fort_road_only(model) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.forage(), "fort forage camp")
	ok(model.dispatch_scout("gujranwala_fort_road"), "fort dispatch road")
	ok(model.dispatch_scout("gujranwala_camp"), "fort dispatch camp")
	ok(model.dispatch_scout("gujranwala_settlement"), "fort dispatch settlement")
	model.advance(Model.REPORT_DELAY)
	ok(model.decide_column("advance_scouts"), "fort decide")
	pose(model, Base.SITES.gujranwala_fort_road)
	ok(model.march_to("gujranwala_fort_road"), "fort march road")
	pose(model, Base.SITES.gujranwala_fort_road)

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial garhi snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("garhi"), "garhi envelope present")
	check(model.snapshot().mahan.has("settlement"), "settlement envelope still present")
	check(model.snapshot().mahan.has("encounter"), "encounter envelope still present")
	check(model.garhi().examined.is_empty(), "no garhi markers examined yet")
	check(model.garhi_fact_known(Model.FACT_GARHI_WORD) == false, "garhi word sealed initially")
	check(model.pending_garhi_reports().is_empty(), "no garhi report pending")
	check(model.resolve_place_id("gujranwala_garhi"), "garhi location stub resolves")
	check(model.resolve_place_id("gujranwala_fort_road"), "fort_road location stub resolves")
	var sett := Settlement.new()
	sett.enable_riding()
	check(not sett.snapshot().mahan.has("garhi"), "settlement adapter stays garhi-free")
	reject(model, model.examine_garhi_marker.bind("rampart"), "examine before unlock")
	reject(model, model.request_delayed_garhi_report, "report before unlock")
	_to_gujranwala_settlement(model)
	ok(model.garhi_observation_available(), "garhi observation available at settlement")
	pose(model, Model.GARHI_MARKERS.rampart)
	ok(model.examine_garhi_marker("rampart"), "examine rampart")
	check("rampart" in model.examined_garhi_markers(), "rampart recorded")
	reject(model, model.examine_garhi_marker.bind("rampart"), "duplicate rampart")
	pose(model, Model.GARHI_MARKERS.gatehouse)
	ok(model.examine_garhi_marker("gatehouse"), "examine gatehouse")
	pose(model, Model.GARHI_MARKERS.bastion)
	ok(model.examine_garhi_marker("bastion"), "examine bastion")
	check(model.examined_garhi_markers().size() == 3, "all three garhi markers examined")
	var ramp_mem := false
	for memory in model.journal():
		if memory.id == "garhi_examine_rampart" and memory.channel == "garhi_observation" and memory.source_id == "self":
			if memory.has("received_tick") and memory.observer_id == "mahan_singh":
				ramp_mem = true
	check(ramp_mem, "rampart memory attributed with source/channel/tick")
	pose(model, Model.SETTLEMENT_MARKERS.walls)
	ok(model.examine_settlement_marker("walls"), "settlement walls under garhi adapter")
	pose(model, Base.SITES.gujranwala_settlement)
	ok(model.request_delayed_garhi_report(), "request delayed garhi report")
	check(model.pending_garhi_reports().size() == 1, "garhi report pending")
	check(model.garhi_fact_known(Model.FACT_GARHI_WORD) == false, "player_knowledge false while pending")
	check(model.journal().filter(func(m): return str(m.id) == "garhi_landmark_report.report").is_empty(), "no early garhi report journal")
	reject(model, model.request_delayed_garhi_report, "duplicate garhi report request")
	model.advance(Model.GARHI_DELAY - 1)
	check(model.pending_garhi_reports().size() == 1, "still pending one tick early")
	check(model.garhi_fact_known(Model.FACT_GARHI_WORD) == false, "still sealed one tick early")
	model.advance(1)
	check(model.received_garhi_reports().size() == 1, "garhi report delivered")
	check(model.pending_garhi_reports().is_empty(), "no pending after delivery")
	check(model.garhi_fact_known(Model.FACT_GARHI_WORD) == true, "player_knowledge true on delivery")
	var report_mem := false
	for memory in model.journal():
		if memory.id == "garhi_landmark_report.report" and memory.channel == "delayed_garhi_report":
			report_mem = true
	check(report_mem, "garhi report memory on delivery only")
	ok(model.validate(model.snapshot()), "valid after garhi beat")
	var road := Model.new()
	road.enable_riding()
	_to_fort_road_only(road)
	ok(road.garhi_observation_available(), "garhi observation available at fort road")
	pose(road, Model.GARHI_MARKERS.gatehouse)
	ok(road.examine_garhi_marker("gatehouse"), "examine gatehouse from fort-road path")
	pose(model, Base.SITES.camp_table)
	ok(model.acknowledge_fixed_endpoint(), "fixed endpoint after garhi")
	check(model.stage() == "closed", "closed after endpoint")
	check(not model.has_method("alter_historical_outcome"), "no alter_outcome method")
	check(not model.has_method("open_siege_map"), "no siege map method")
	check(not model.has_method("omniscient_garhi_survey"), "no omniscience method")
	var round := Model.new()
	round.enable_riding()
	_to_gujranwala_settlement(round)
	pose(round, Model.GARHI_MARKERS.rampart)
	ok(round.examine_garhi_marker("rampart"), "round examine rampart")
	pose(round, Base.SITES.gujranwala_settlement)
	ok(round.request_delayed_garhi_report(), "round request report")
	ok(round.save_to(SAVE), "save garhi")
	var again := Model.new()
	ok(again.load_from(SAVE), "load garhi")
	check(again.examined_garhi_markers() == ["rampart"], "examined round trip")
	check(again.pending_garhi_reports().size() == 1, "pending report round trip")
	check(again.garhi_fact_known(Model.FACT_GARHI_WORD) == false, "fact still sealed round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	check(again.resolve_place_id("gujranwala_garhi"), "garhi still place object")
	check(not again.snapshot().actors.has("gujranwala_garhi"), "garhi not a person actor")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.garhi.reports[0].text = "rewritten"
	reject(again, again.restore.bind(bad), "garhi report text rewrite")
	bad = again.snapshot()
	bad.mahan.garhi.facts[Model.FACT_GARHI_WORD].player_knowledge = true
	reject(again, again.restore.bind(bad), "premature player_knowledge")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from garhi slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from garhi slice")
	check(not snap_text.contains("sandhawalia") and not snap_text.contains("Sandhawalia"), "Sandhawalia absent from garhi snapshot")
	check(not snap_text.to_lower().contains("khalsa faith") and not snap_text.to_lower().contains("religious war"), "no religious framing tokens")
	for kind in Model.GARHI_EXAMINE_TEXTS:
		var t: String = str(Model.GARHI_EXAMINE_TEXTS[kind].text).to_lower()
		check("sealed" in t or "greybox" in t or "local" in t or "not a surveyed" in t or "no combat" in t or "no siege" in t, "examine text stays limited: " + kind)

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes garhi chapter")
	check(chapter.campaign.has_method("examine_garhi_marker"), "chapter campaign is garhi model")
	check(chapter.campaign.has_method("examine_settlement_marker"), "garhi still exposes settlement")
	check(chapter.campaign.has_method("begin_ridge_settlement_encounter"), "garhi still exposes encounter")
	check(chapter.campaign.has_method("observe_historical_event"), "garhi still exposes history")
	check(chapter.campaign.has_method("issue_sub_order"), "garhi still exposes orders")
	check(chapter.campaign.has_method("consult_subordinates"), "garhi still exposes politics")
	check(chapter.campaign.has_method("forage"), "garhi still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("garhi"), "chapter garhi envelope")
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
	print("MAHAN_GARHI_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
