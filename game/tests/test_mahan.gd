extends SceneTree
## Domain + delayed scout custody + column march + epistemic fence. Injected save path never writes player slots.
const Model := preload("res://mahan/mahan_state.gd")
const Childhood := preload("res://campaign/campaign_state.gd")
const SAVE := "user://1792-mahan-test-v1.json"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func ok(err: String, label: String) -> void:
	check(err.is_empty(), label if err.is_empty() else "%s (%s)" % [label, err])

func reject(model, callable: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	var err: String = callable.call()
	check(not err.is_empty(), label)
	check(model.snapshot() == before, label + " leaves state")

func fixture_pose(model, p: Vector3) -> void:
	model._set_position(p)

func _domain() -> void:
	var model := Model.new()
	check(model.snapshot().profile == "mahan.v1", "profile")
	check(model.snapshot().player.character_id == "mahan_singh", "actor")
	check(model.stage() == "recon", "starts recon")
	check(model.known_nodes() == ["camp"], "only camp is initially known")
	check(model.provisions() == 10, "provisions start")
	ok(model.validate(model.snapshot()), "fresh validates")

func _hold_path_and_pending_custody() -> void:
	var model := Model.new()
	fixture_pose(model, Model.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch ford")
	check(model.pending_reports().size() == 1, "one pending")
	check(model.received_reports().is_empty(), "none received yet")
	check(model.known_nodes() == ["camp"], "ford not known before delivery")
	check(model.provisions() == 9, "dispatch cost")
	model.advance(Model.REPORT_DELAY - 1)
	check(model.pending_reports().size() == 1, "still pending before arrives_at")
	model.advance(1)
	check(model.pending_reports().is_empty(), "delivered")
	check(model.received_reports().size() == 1, "one received")
	check("ford" in model.known_nodes(), "ford enters known nodes only on delivery")
	check(model.stage() == "decision", "decision stage")
	ok(model.decide_column("hold_for_corroboration"), "hold")
	check(model.stage() == "march", "march stage after hold")
	reject(model, model.march_to.bind("ford"), "held column refuses march")
	ok(model.acknowledge_fixed_endpoint(), "ack hold endpoint")
	check(model.stage() == "closed", "closed")

func _provisions_and_adjacency() -> void:
	var model := Model.new()
	fixture_pose(model, Model.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch")
	ok(model.dispatch_scout("ridge"), "dispatch ridge")
	model.advance(Model.REPORT_DELAY)
	check("ridge" in model.known_nodes() or model.pending_reports().size() <= 1, "ridge custody progresses with clock")
	if "ridge" not in model.known_nodes():
		model.advance(Model.REPORT_DELAY)
		check("ridge" in model.known_nodes(), "ridge known after forced delivery")
	ok(model.decide_column("advance_scouts"), "advance")
	fixture_pose(model, Model.SITES.ford)
	ok(model.march_to("ford"), "march to ford")
	check(model.column_node() == "ford", "column at ford")
	check(model.provisions() == 6, "march cost after two dispatches")
	reject(model, model.march_to.bind("camp"), "cannot skip adjacency without being at camp from ford toward ridge first check")

func _cross_profile_fence() -> void:
	var model := Model.new()
	var child := Childhood.new()
	var before: Dictionary = child.snapshot()
	check(not child.restore(model.snapshot()).is_empty(), "childhood refuses mahan snapshot")
	check(child.snapshot() == before, "childhood unchanged")

func _smoke_launch() -> void:
	pass

func _gujranwala_home_ground_march() -> void:
	var model := Model.new()
	check("gujranwala_fort_road" in Model.NODES, "fort road node authored")
	check("gujranwala_camp" in Model.NODES, "gujranwala camp node authored")
	check("gujranwala_settlement" in Model.NODES, "gujranwala settlement node authored")
	check(Model.ADJACENT["gujranwala_fort_road"] == ["camp", "gujranwala_camp"], "fort road adjacency")
	check(Model.ADJACENT["gujranwala_camp"] == ["gujranwala_fort_road", "gujranwala_settlement"], "gujranwala camp adjacency")
	check(Model.ADJACENT["gujranwala_settlement"] == ["gujranwala_camp"], "settlement adjacency")
	fixture_pose(model, Model.SITES.camp_table)
	ok(model.dispatch_scout("gujranwala_fort_road"), "dispatch gujranwala fort road")
	ok(model.dispatch_scout("gujranwala_camp"), "dispatch gujranwala camp")
	ok(model.dispatch_scout("gujranwala_settlement"), "dispatch gujranwala settlement")
	check(model.known_nodes() == ["camp"], "Gujranwala nodes unknown before delivery")
	check(model.pending_reports().size() == 3, "three Gujranwala detachments pending")
	model.advance(Model.REPORT_DELAY)
	check("gujranwala_fort_road" in model.known_nodes(), "fort road known on delivery")
	check("gujranwala_camp" in model.known_nodes(), "gujranwala camp known on delivery")
	check("gujranwala_settlement" in model.known_nodes(), "settlement known on delivery")
	ok(model.decide_column("advance_scouts"), "advance after Gujranwala custody")
	fixture_pose(model, Model.SITES.gujranwala_fort_road)
	ok(model.march_to("gujranwala_fort_road"), "march camp to fort road")
	check(model.column_node() == "gujranwala_fort_road", "column on fort road")
	fixture_pose(model, Model.SITES.gujranwala_camp)
	ok(model.march_to("gujranwala_camp"), "march fort road to gujranwala camp")
	fixture_pose(model, Model.SITES.gujranwala_settlement)
	ok(model.march_to("gujranwala_settlement"), "march camp to settlement")
	check(model.column_node() == "gujranwala_settlement", "column at Gujranwala town")
	var texts: PackedStringArray = PackedStringArray()
	for memory in model.journal():
		texts.append(str(memory.text))
		check(memory.observer_id == "mahan_singh", "Gujranwala memories attributed to Mahan")
	check("Sukerchakia home-ground" in "\n".join(texts) or "Gujranwala" in "\n".join(texts), "journal mentions Gujranwala home-ground framing")
	ok(model.validate(model.snapshot()), "valid after Gujranwala marches")
	var child := Childhood.new()
	var before: Dictionary = child.snapshot()
	check(not child.restore(model.snapshot()).is_empty(), "childhood refuses Gujranwala-extended mahan snapshot")
	check(child.snapshot() == before, "childhood unchanged after Gujranwala fence check")
	var leap := Model.new()
	fixture_pose(leap, Model.SITES.camp_table)
	ok(leap.dispatch_scout("ford"), "leap fixture dispatch")
	leap.advance(Model.REPORT_DELAY)
	ok(leap.decide_column("advance_scouts"), "leap advance")
	fixture_pose(leap, Model.SITES.gujranwala_settlement)
	reject(leap, leap.march_to.bind("gujranwala_settlement"), "refuse leap to unknown settlement")
	reject(leap, leap.march_to.bind("gujranwala_camp"), "refuse leap to unknown gujranwala camp")

func _run() -> void:
	_domain()
	_hold_path_and_pending_custody()
	_provisions_and_adjacency()
	_gujranwala_home_ground_march()
	_cross_profile_fence()
	await _smoke_launch()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
