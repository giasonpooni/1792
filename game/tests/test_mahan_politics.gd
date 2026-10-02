extends SceneTree
const Model := preload("res://mahan/mahan_politics_state.gd")
const Logistics := preload("res://mahan/mahan_logistics_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-politics-regression.json"
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

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial politics snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("politics"), "politics envelope present")
	check(model.disposition() == "steady", "starts steady")
	check(not model.consulted(), "not consulted yet")
	check(model.march_willingness(), "march willing when steady")
	check(model.subordinate_loyalty("fictional_camp_retainer") == 2, "retainer loyalty seed")
	check(model.subordinate_loyalty("fictional_horse_jemadar") == 3, "jemadar loyalty seed")
	check(model.active_stance("fictional_camp_retainer") == "prefer_hold", "retainer prefer_hold")
	check(model.active_stance("fictional_horse_jemadar") == "prefer_advance", "jemadar prefer_advance")
	var logi := Logistics.new()
	logi.enable_riding()
	check(not logi.snapshot().mahan.has("politics"), "logistics adapter stays politics-free")
	var pol: Dictionary = model.politics()
	check(pol.alignments.has("fictional_camp_retainer"), "retainer is separate subordinate actor")
	check(not model.snapshot().actors.has("fictional_camp_retainer"), "subordinates stay out of top-level actors fence")
	pose(model, Base.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch ford")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision after delivery")
	ok(model.consult_subordinates(), "consult subordinates")
	check(model.consulted(), "consulted flag")
	check(model.journal().size() >= 2, "consult memory present")
	reject(model, model.consult_subordinates, "duplicate consult")
	var loy_before: int = model.subordinate_loyalty("fictional_camp_retainer")
	ok(model.decide_column("hold_for_corroboration"), "hold matches retainer advice")
	check(model.disposition() == "aligned", "hold aligns disposition")
	check(model.subordinate_loyalty("fictional_camp_retainer") == loy_before + 1, "loyalty bump on matching hold")
	ok(model.validate(model.snapshot()), "valid after hold politics")
	var strained := Model.new()
	strained.enable_riding()
	pose(strained, Base.SITES.camp_table)
	ok(strained.dispatch_scout("ford"), "strained dispatch")
	strained.advance(Model.REPORT_DELAY)
	ok(strained.consult_subordinates(), "strained consult")
	ok(strained.decide_column("advance_scouts"), "advance against prefer_hold")
	check(strained.disposition() == "strained", "disposition strained")
	check(not strained.march_willingness(), "march blocked while strained")
	pose(strained, Base.SITES.ford)
	reject(strained, strained.march_to.bind("ford"), "strained blocks march")
	pose(strained, Base.SITES.camp_table)
	ok(strained.acknowledge_clan_pressure(), "ack pressure")
	check(strained.march_willingness(), "march willing after ack")
	pose(strained, Base.SITES.ford)
	ok(strained.march_to("ford"), "march after pressure ack")
	check(strained.column_node() == "ford", "column at ford after politics gate")
	ok(strained.validate(strained.snapshot()), "valid after strained march path")
	var rumor := Model.new()
	rumor.enable_riding()
	pose(rumor, Base.SITES.camp_table)
	ok(rumor.request_household_word(), "request household word")
	check(rumor.pending_rumors().size() == 1, "rumor pending")
	check(rumor.received_rumors().is_empty(), "rumor not knowledge yet")
	check(rumor.journal().filter(func(m): return str(m.id).begins_with("rumor_")).is_empty(), "no early rumor journal")
	reject(rumor, rumor.request_household_word, "duplicate household word")
	rumor.advance(Model.POLITICS_DELAY - 1)
	check(rumor.pending_rumors().size() == 1, "still pending one tick early")
	rumor.advance(1)
	check(rumor.received_rumors().size() == 1, "rumor delivered on clock")
	check(rumor.pending_rumors().is_empty(), "no pending after delivery")
	check(rumor.active_stance("fictional_camp_retainer") == "counsel_noted", "rumor softens retainer stance")
	var found := false
	for memory in rumor.journal():
		if memory.id == "rumor_household_pressure.report" and memory.channel == "delayed_household_word":
			found = true
	check(found, "rumor memory on delivery only")
	ok(rumor.validate(rumor.snapshot()), "valid after rumor delivery")
	var fed := Model.new()
	fed.enable_riding()
	pose(fed, Base.SITES.camp_table)
	ok(fed.forage(), "politics adapter still forages")
	check(fed.foraged_nodes() == ["camp"], "forage ledger intact")
	var quiet := Model.new()
	quiet.enable_riding()
	pose(quiet, Base.SITES.camp_table)
	ok(quiet.dispatch_scout("ridge"), "quiet dispatch")
	quiet.advance(Model.REPORT_DELAY)
	ok(quiet.decide_column("advance_scouts"), "advance without consult")
	check(quiet.disposition() == "steady", "no strain without counsel")
	check(quiet.march_willingness(), "willing without counsel pressure")
	var round := Model.new()
	round.enable_riding()
	pose(round, Base.SITES.camp_table)
	ok(round.consult_subordinates(), "round consult")
	ok(round.request_household_word(), "round rumor")
	ok(round.dispatch_scout("ford"), "round dispatch")
	ok(round.save_to(SAVE), "save politics")
	var again := Model.new()
	ok(again.load_from(SAVE), "load politics")
	check(again.consulted(), "consulted round trip")
	check(again.pending_rumors().size() == 1, "pending rumor round trip")
	check(again.disposition() == "steady", "disposition round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.politics.loyalty["fictional_camp_retainer"] = 9
	reject(again, again.restore.bind(bad), "loyalty out of bounds")
	bad = again.snapshot()
	bad.mahan.politics.disposition = "mutinous"
	reject(again, again.restore.bind(bad), "invented disposition")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from Mahan politics slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from Mahan politics slice")

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes politics chapter")
	check(chapter.campaign.has_method("consult_subordinates"), "chapter campaign is politics model")
	check(chapter.campaign.has_method("forage"), "politics still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("politics"), "chapter politics envelope")
	check(chapter.campaign.snapshot().mahan.has("logistics"), "chapter logistics envelope")
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
	print("MAHAN_POLITICS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
