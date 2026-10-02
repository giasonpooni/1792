extends SceneTree
const Model := preload("res://mahan/mahan_orders_state.gd")
const Politics := preload("res://mahan/mahan_politics_state.gd")
const Base := preload("res://mahan/mahan_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-orders-regression.json"
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

func _to_march(model, consultation: bool = false) -> void:
	pose(model, Base.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch ford")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision stage")
	if consultation:
		ok(model.consult_subordinates(), "consult before advance")
	ok(model.decide_column("advance_scouts"), "advance column")
	check(model.stage() == "march", "march stage")

func _domain() -> void:
	var model := Model.new()
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial orders snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia household graph object")
	check(model.snapshot().mahan.has("orders"), "orders envelope present")
	check(model.snapshot().mahan.has("politics"), "politics envelope still present")
	check(model.active_assignments().is_empty(), "no assignments yet")
	check(model.pending_pursuit_reports().is_empty(), "no pursuit pending")
	var pol := Politics.new()
	pol.enable_riding()
	check(not pol.snapshot().mahan.has("orders"), "politics adapter stays orders-free")
	reject(model, model.issue_sub_order.bind("hold_rear"), "orders before column decision")
	_to_march(model)
	pose(model, Base.SITES.camp_table)
	ok(model.issue_sub_order("hold_rear"), "hold rear while steady")
	check(model.subordinate_order("fictional_camp_retainer") == "hold_rear", "retainer holds rear")
	check(model.active_assignments().size() == 1, "one assignment")
	reject(model, model.issue_sub_order.bind("hold_rear"), "duplicate hold rear")
	ok(model.issue_sub_order("scout"), "scout while steady")
	check(model.subordinate_order("fictional_horse_jemadar") == "scout", "jemadar scouts")
	reject(model, model.issue_sub_order.bind("pursue_contact"), "jemadar already assigned blocks pursue")
	ok(model.validate(model.snapshot()), "valid after scout and hold rear")
	## Pursuit path on a clean column.
	var hunt := Model.new()
	hunt.enable_riding()
	_to_march(hunt)
	pose(hunt, Base.SITES.camp_table)
	ok(hunt.issue_sub_order("pursue_contact"), "issue pursue contact")
	check(hunt.pending_pursuit_reports().size() == 1, "pursuit pending")
	check(hunt.received_pursuit_reports().is_empty(), "pursuit not knowledge yet")
	check(hunt.journal().filter(func(m): return str(m.id).begins_with("pursuit_")).is_empty(), "no early pursuit journal")
	reject(hunt, hunt.issue_sub_order.bind("pursue_contact"), "duplicate pursue")
	reject(hunt, hunt.issue_sub_order.bind("scout"), "jemadar busy on pursue")
	hunt.advance(Model.ORDERS_DELAY - 1)
	check(hunt.pending_pursuit_reports().size() == 1, "still pending one tick early")
	hunt.advance(1)
	check(hunt.received_pursuit_reports().size() == 1, "pursuit delivered on clock")
	check(hunt.pending_pursuit_reports().is_empty(), "no pending after delivery")
	var found := false
	for memory in hunt.journal():
		if memory.id == "pursuit_contact_stub.report" and memory.channel == "delayed_pursuit_report":
			found = true
	check(found, "pursuit memory on delivery only")
	ok(hunt.validate(hunt.snapshot()), "valid after pursuit delivery")
	## Disposition gate: strained blocks offensive, allows hold rear.
	var strained := Model.new()
	strained.enable_riding()
	_to_march(strained, true)
	check(strained.disposition() == "strained", "strained after advance against hold counsel")
	pose(strained, Base.SITES.camp_table)
	reject(strained, strained.issue_sub_order.bind("scout"), "strained blocks scout")
	reject(strained, strained.issue_sub_order.bind("pursue_contact"), "strained blocks pursue")
	ok(strained.issue_sub_order("hold_rear"), "hold rear allowed while strained")
	check(strained.subordinate_order("fictional_camp_retainer") == "hold_rear", "rear under strain")
	ok(strained.validate(strained.snapshot()), "valid strained hold rear")
	## Hold column refuses subordinate orders.
	var held := Model.new()
	held.enable_riding()
	pose(held, Base.SITES.camp_table)
	ok(held.dispatch_scout("ridge"), "held dispatch")
	held.advance(Model.REPORT_DELAY)
	ok(held.decide_column("hold_for_corroboration"), "hold column")
	reject(held, held.issue_sub_order.bind("hold_rear"), "hold column blocks sub-orders")
	## Ontology + fence.
	var round := Model.new()
	round.enable_riding()
	_to_march(round)
	pose(round, Base.SITES.camp_table)
	ok(round.issue_sub_order("hold_rear"), "round hold rear")
	ok(round.issue_sub_order("pursue_contact"), "round pursue")
	ok(round.save_to(SAVE), "save orders")
	var again := Model.new()
	ok(again.load_from(SAVE), "load orders")
	check(again.subordinate_order("fictional_camp_retainer") == "hold_rear", "hold rear round trip")
	check(again.pending_pursuit_reports().size() == 1, "pending pursuit round trip")
	check(again.snapshot().mahan.household_id == "sukerchakia", "household round trip")
	check(not again.snapshot().actors.has("fictional_horse_jemadar"), "subordinates stay out of top-level actors")
	var bad: Dictionary = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Sandhawalia ontology collapse")
	bad = again.snapshot()
	bad.mahan.orders.assignments["fictional_camp_retainer"] = "pursue_contact"
	reject(again, again.restore.bind(bad), "roster mismatch assignment")
	bad = again.snapshot()
	bad.mahan.orders.pursuit_reports[0].text = "rewritten"
	reject(again, again.restore.bind(bad), "pursuit text rewrite")
	var snap_text := JSON.stringify(again.snapshot())
	check(not snap_text.contains("raj_kaur") and not snap_text.contains("Raj Kaur"), "Raj Kaur absent from orders slice")
	check(not snap_text.contains("phulkian") and not snap_text.contains("Phulkian"), "Phulkian absent from orders slice")
	check(not snap_text.contains("sandhawalia") and not snap_text.contains("Sandhawalia"), "Sandhawalia absent from orders snapshot")
	## Fixed endpoint still available after orders.
	pose(again, Base.SITES.camp_table)
	ok(again.acknowledge_fixed_endpoint(), "fixed endpoint after orders")
	check(again.stage() == "closed", "closed after endpoint")
	ok(again.validate(again.snapshot()), "valid closed with orders")

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes orders chapter")
	check(chapter.campaign.has_method("issue_sub_order"), "chapter campaign is orders model")
	check(chapter.campaign.has_method("consult_subordinates"), "orders still exposes politics")
	check(chapter.campaign.has_method("forage"), "orders still exposes logistics")
	check(chapter.campaign.snapshot().mahan.has("orders"), "chapter orders envelope")
	check(chapter.campaign.snapshot().mahan.has("politics"), "chapter politics envelope")
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
	print("MAHAN_ORDERS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
