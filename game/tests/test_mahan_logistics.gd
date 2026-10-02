extends SceneTree
const Model := preload("res://mahan/mahan_logistics_state.gd")
const Cavalry := preload("res://mahan/mahan_cavalry_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-logistics-regression.json"
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
	# Install pose through logistics restore so ledger stays coherent.
	s.player.position = Base.coords(p)
	s.actors[Base.ACTOR_ID].position = Base.coords(p)
	ok(model.restore(s), "pose restore")
	if riding != null:
		model._riding = riding.duplicate(true)

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial logistics snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("logistics"), "logistics envelope present")
	check(model.provisions() == 10, "starts at 10 provisions")
	check(model.foraged_nodes().is_empty(), "no forage yet")
	check(model.wait_units() == 0, "no wait drain yet")
	# Cavalry-only model remains logistics-free.
	var cav := Cavalry.new()
	cav.enable_riding()
	check(not cav.snapshot().mahan.has("logistics"), "cavalry adapter stays logistics-free")
	# Forage at camp (near table).
	pose(model, Base.SITES.camp_table)
	ok(model.forage(), "forage camp")
	check(model.provisions() == 12, "camp forage +2 to cap")
	check(model.foraged_nodes() == ["camp"], "camp on forage ledger")
	check(model.journal().size() == 1 and model.journal()[0].channel == "field_forage", "forage memory")
	reject(model, model.forage, "duplicate camp forage")
	ok(model.validate(model.snapshot()), "valid after forage")
	# Wait consumption: advance one interval.
	model.advance(Model.WAIT_INTERVAL)
	check(model.wait_units() == 1, "one wait unit after interval")
	check(model.provisions() == 11, "wait consumes one provision")
	ok(model.validate(model.snapshot()), "valid after wait drain")
	# Dispatch still spends.
	ok(model.dispatch_scout("ford"), "dispatch after logistics")
	check(model.provisions() == 10, "dispatch spend on top of wait/forage")
	# Deliver report without extra surprise: advance remaining to arrives_at.
	var arrives: int = int(model.pending_reports()[0].arrives_at)
	var now: int = int(model.snapshot().mahan.tick)
	model.advance(arrives - now)
	check(model.received_reports().size() == 1, "ford delivered")
	check("ford" in model.known_nodes(), "ford known on delivery")
	# Drain toward stockout via wait, then refuse advance.
	var poor := Model.new()
	poor.enable_riding()
	pose(poor, Base.SITES.camp_table)
	ok(poor.dispatch_scout("ford"), "poor dispatch")
	poor.advance(Model.REPORT_DELAY)
	# provisions: 10 -1 dispatch - (REPORT_DELAY/WAIT_INTERVAL) wait
	var expected_after_delivery := 10 - Model.DISPATCH_COST - int(Model.REPORT_DELAY / Model.WAIT_INTERVAL)
	check(poor.provisions() == expected_after_delivery, "delivery wait accounting")
	# Burn remaining provisions above MARCH_COST-1 via wait.
	while poor.provisions() >= Model.MARCH_COST:
		poor.advance(Model.WAIT_INTERVAL)
	check(poor.provisions() < Model.MARCH_COST, "now below march floor")
	reject(poor, poor.decide_column.bind("advance_scouts"), "stockout blocks advance")
	ok(poor.decide_column("hold_for_corroboration"), "stockout still allows hold")
	check(poor.stage() == "march", "hold enters march stage")
	reject(poor, poor.march_to.bind("ford"), "held column still cannot march")
	# Separate path: forage unlocks advance after intentional drain.
	var fed := Model.new()
	fed.enable_riding()
	pose(fed, Base.SITES.camp_table)
	ok(fed.dispatch_scout("ford"), "fed dispatch")
	fed.advance(Model.REPORT_DELAY)
	while fed.provisions() >= Model.MARCH_COST:
		fed.advance(Model.WAIT_INTERVAL)
	reject(fed, fed.decide_column.bind("advance_scouts"), "fed path stockout before forage")
	ok(fed.forage(), "forage to lift stockout")
	check(fed.provisions() >= Model.MARCH_COST, "forage restored march floor")
	ok(fed.decide_column("advance_scouts"), "advance after forage")
	pose(fed, Base.SITES.ford)
	var before_march: int = fed.provisions()
	var wait_before: int = fed.wait_units()
	ok(fed.march_to("ford"), "march after logistics forage")
	check(fed.column_node() == "ford", "column at ford")
	var wait_delta: int = fed.wait_units() - wait_before
	check(fed.provisions() == before_march - Model.MARCH_COST - wait_delta * Model.WAIT_COST, "march + incidental wait")
	# Ford forage once arrived.
	ok(fed.forage(), "forage ford")
	check("ford" in fed.foraged_nodes(), "ford foraged")
	reject(fed, fed.forage, "no second ford forage")
	ok(fed.acknowledge_fixed_endpoint(), "fixed endpoint still available")
	check(fed.stage() == "closed", "closed after endpoint")
	ok(fed.validate(fed.snapshot()), "closed logistics snapshot valid")
	# Mounted forage gate.
	var mounted := Model.new()
	mounted.enable_riding()
	var hp := mounted.horse_state()
	# enable_riding sets horse; pose near horse and mount.
	pose(mounted, Base.point(mounted.horse_state().position) + Vector3(1.4, 0.1, 0))
	ok(mounted.mount_horse(), "mount for gate test")
	reject(mounted, mounted.forage, "mounted forage gate")
	# Save / load round trip with pending + forage.
	var round := Model.new()
	round.enable_riding()
	pose(round, Base.SITES.camp_table)
	ok(round.forage(), "round-trip forage")
	ok(round.dispatch_scout("ridge"), "round-trip dispatch")
	ok(round.save_to(SAVE), "save logistics")
	var again := Model.new()
	ok(again.load_from(SAVE), "load logistics")
	check(again.foraged_nodes() == ["camp"], "forage ledger round trip")
	check(again.pending_reports().size() == 1, "pending custody round trip")
	check(again.provisions() == round.provisions(), "provisions round trip")
	# Ontology refusal.
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.logistics.foraged_nodes = ["camp", "camp"]
	reject(again, again.restore.bind(bad), "duplicate forage ledger")
	bad = again.snapshot()
	bad.mahan.provisions = int(bad.mahan.provisions) + 3
	reject(again, again.restore.bind(bad), "invented provisions without ledger")


func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes logistics chapter")
	check(chapter.campaign.has_method("forage"), "chapter campaign is logistics model")
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
	print("MAHAN_LOGISTICS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
