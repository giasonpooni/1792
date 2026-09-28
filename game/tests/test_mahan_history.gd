extends SceneTree
const Model := preload("res://mahan/mahan_history_state.gd")
const Orders := preload("res://mahan/mahan_orders_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-history-regression.json"
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

func _to_march(model) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch ford")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision stage")
	ok(model.decide_column("advance_scouts"), "advance column")
	check(model.stage() == "march", "march stage")

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial history snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("history"), "history envelope present")
	check(model.snapshot().mahan.has("orders"), "orders envelope still present")
	check(model.authored_catalog().size() == 3, "three authored catalog events")
	check(model.authored_catalog().has("mahan_singh_death_fixed"), "death event loaded")
	check(model.authored_catalog().has("mahan_late_campaign_illness"), "illness event loaded")
	check(model.known_historical_events().is_empty(), "no known frames yet")
	check(model.pending_historical_reports().is_empty(), "no pending historical reports")
	var death: Dictionary = model.authored_event("mahan_singh_death_fixed")
	check(death.historical_outcome.fixed == true, "death outcome fixed")
	check(death.knowledge.player_knowledge == false, "authored death starts unknown")
	check(death.canon_class == "game_canon", "death marked game_canon")
	check(death.gameplay.intervention_scope == "none", "death not alterable")
	var illness: Dictionary = model.authored_event("mahan_late_campaign_illness")
	check(illness.historical_outcome.fixed == false, "illness outcome not fixed")
	check("mahan_singh" in illness.knowledge.direct_observers, "mahan observes illness")
	check(illness.canon_class == "game_canon", "illness marked game_canon")
	check(model.authored_locations().size() == 6, "six location stubs loaded")
	check(model.resolve_place_id("gujranwala_settlement"), "gujranwala settlement resolves")
	check(model.resolve_place_id("gujranwala_fort_road"), "gujranwala fort road resolves")
	check(model.resolve_place_id("gujranwala_camp"), "gujranwala camp resolves")
	check(model.resolve_place_id("gujranwala_camp"), "gujranwala camp resolves")
	var settlement: Dictionary = model.authored_location("gujranwala_settlement")
	check(settlement.kind == "settlement", "settlement kind")
	check(settlement.gameplay.role == "home_ground", "settlement home_ground role")
	check(settlement.household_context == "sukerchakia", "settlement household context")
	check("gujranwala_fort_road" in illness.location.related_place_ids, "illness relates fort road")
	var home: Dictionary = model.authored_event("mahan_gujranwala_home_ground")
	check(home.location.place_id == "gujranwala_settlement", "home-ground event at settlement")
	ok(Model.validate_authored_location(settlement), "settlement location validates")

	## Orders adapter remains history-free.
	var ord := Orders.new()
	ord.enable_riding()
	check(not ord.snapshot().mahan.has("history"), "orders adapter stays history-free")
	## Gujranwala home-ground observe.
	var home_model := Model.new()
	home_model.enable_riding()
	pose(home_model, Base.SITES.camp_table)
	ok(home_model.observe_historical_event("mahan_gujranwala_home_ground"), "observe home-ground")
	check(home_model.known_historical_events().size() == 1, "home-ground known alone")
	check(home_model.known_historical_events()[0].event_id == "mahan_gujranwala_home_ground", "known is home-ground")
	ok(home_model.validate(home_model.snapshot()), "valid after home-ground observe")
	## Refuse observe on death (not observer / intervention none).
	pose(model, Base.SITES.camp_table)
	reject(model, model.observe_historical_event.bind("mahan_singh_death_fixed"), "cannot observe fixed death")
	## Observe illness as direct observer.
	ok(model.observe_historical_event("mahan_late_campaign_illness"), "observe illness")
	check(model.known_historical_events().size() == 1, "one known frame after observe")
	check(model.known_historical_events()[0].event_id == "mahan_late_campaign_illness", "known is illness")
	reject(model, model.observe_historical_event.bind("mahan_late_campaign_illness"), "duplicate observe")
	ok(model.validate(model.snapshot()), "valid after observe")
	## Refuse forging player_knowledge without observer/delivery.
	var forged: Dictionary = model.snapshot()
	forged.mahan.history.events["mahan_singh_death_fixed"].player_knowledge = true
	reject(model, model.restore.bind(forged), "forge death knowledge without ack")
	## Delayed report path on clean model.
	var courier := Model.new()
	courier.enable_riding()
	pose(courier, Base.SITES.camp_table)
	ok(courier.request_historical_report("mahan_late_campaign_illness"), "request illness report")
	check(courier.pending_historical_reports().size() == 1, "historical report pending")
	check(courier.known_historical_events().is_empty(), "not known before delivery")
	check(courier.journal().filter(func(m): return str(m.id).begins_with("history_") and str(m.id).ends_with(".report")).is_empty(), "no early history report journal")
	var delay: int = int(courier.authored_event("mahan_late_campaign_illness").knowledge.propagation_delay)
	courier.advance(delay - 1)
	check(courier.pending_historical_reports().size() == 1, "still pending one tick early")
	courier.advance(1)
	check(courier.received_historical_reports().size() == 1, "historical report delivered")
	check(courier.known_historical_events().size() == 1, "known after delivery")
	check(courier.pending_historical_reports().is_empty(), "no pending after delivery")
	ok(courier.validate(courier.snapshot()), "valid after historical delivery")
	## Fixed death knowledge only via endpoint ack.
	var endp := Model.new()
	endp.enable_riding()
	_to_march(endp)
	pose(endp, Base.SITES.camp_table)
	check(endp.known_historical_events().is_empty(), "death unknown before ack")
	ok(endp.acknowledge_fixed_endpoint(), "ack fixed endpoint")
	var known_ids: Array = []
	for event in endp.known_historical_events():
		known_ids.append(event.event_id)
	check("mahan_singh_death_fixed" in known_ids, "death known after endpoint ack")
	ok(endp.validate(endp.snapshot()), "valid after endpoint history grant")
	## Schema-shaped authored validation helper.
	ok(Model.validate_authored_event(death), "death authored validates")
	ok(Model.validate_authored_event(illness), "illness authored validates")
	var bad_ev: Dictionary = death.duplicate(true)
	bad_ev.knowledge.player_knowledge = true
	check(not Model.validate_authored_event(bad_ev).is_empty(), "authored death cannot claim player_knowledge")
	bad_ev = illness.duplicate(true)
	bad_ev.actors.append({"id": "mahan_singh", "role": "also_household", "kind": "household"})
	check(not Model.validate_authored_event(bad_ev).is_empty(), "Person≠Household collapse refused")
	bad_ev = illness.duplicate(true)
	bad_ev.summary = "Raj Kaur aside"
	check(not Model.validate_authored_event(bad_ev).is_empty(), "Raj Kaur token refused")
	## Save/load + ontology fence.
	var round := Model.new()
	round.enable_riding()
	pose(round, Base.SITES.camp_table)
	ok(round.observe_historical_event("mahan_late_campaign_illness"), "round observe")
	ok(round.save_to(SAVE), "save history")
	var again := Model.new()
	ok(again.load_from(SAVE), "load history")
	check(again.known_historical_events().size() == 1, "known round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	check(not again.snapshot().actors.has("fictional_camp_retainer"), "subordinates stay out of top-level actors")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from history slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from history slice")
	check(not snap_text.contains("sandhawalia") and not snap_text.contains("Sandhawalia"), "Sandhawalia absent from history snapshot")
	## Catalog evidence classes are inspectable (no invented primary claim).
	var ev0: Dictionary = again.authored_event("mahan_late_campaign_illness").evidence[0]
	check(ev0.evidence_class in ["A", "B", "C", "D"], "evidence class present")
	check(ev0.evidence_class != "A", "illness not claimed as class A primary")

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes history chapter")
	check(chapter.campaign.has_method("observe_historical_event"), "chapter campaign is history model")
	check(chapter.campaign.has_method("issue_sub_order"), "history still exposes orders")
	check(chapter.campaign.has_method("consult_subordinates"), "history still exposes politics")
	check(chapter.campaign.has_method("forage"), "history still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("history"), "chapter history envelope")
	check(chapter.campaign.snapshot().mahan.has("orders"), "chapter orders envelope")
	check(chapter.campaign.authored_catalog().size() == 3, "chapter catalog loaded")
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
	print("MAHAN_HISTORY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
