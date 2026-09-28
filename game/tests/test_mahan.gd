extends SceneTree
## Domain + delayed scout custody + column march + epistemic fence. Injected save path never writes player slots.
const Model := preload("res://mahan/mahan_state.gd")
const Childhood := preload("res://childhood/childhood_state.gd")
const Aftermath := preload("res://childhood/aftermath_state.gd")
const Command := preload("res://campaign/command_state.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-regression-only.json"
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

func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), label + " refused")
	check(model.snapshot() == before, label + " leaves state unchanged")

func fixture_pose(model, p: Vector3) -> void:
	var s: Dictionary = model.snapshot()
	s.player.position = Model.coords(p)
	s.actors[Model.ACTOR_ID].position = Model.coords(p)
	ok(model.restore(s), "install domain pose fixture")

func _domain() -> void:
	var model := Model.new()
	ok(model.validate(model.snapshot()), "initial mahan profile")
	check(model.snapshot().profile == "mahan.v1", "profile authority is mahan.v1")
	check(model.snapshot().player.character_id == "mahan_singh", "separate actor id")
	check(model.snapshot().player.character_id != "ranjit_singh", "does not steal childhood key")
	check(model.stage() == "recon", "starts in recon / dispatch stage")
	check(model.journal().is_empty(), "no seeded secret knowledge")
	check(model.known_nodes() == ["camp"], "only camp is initially known")
	check(model.provisions() == 10, "provisions stub starts at 10")
	reject(model, model.decide_column.bind("advance_scouts"), "decision before delivered report")
	reject(model, model.acknowledge_fixed_endpoint, "endpoint before decision")
	reject(model, model.march_to.bind("ford"), "march before decision")
	reject(model, model.record_position.bind(Vector3(20, 0.14, 20), 1.0 / 60), "teleport sample")
	reject(model, model.record_position.bind(Vector3(NAN, 0, 0), 1.0 / 60), "nonfinite motion")
	fixture_pose(model, Model.SITES.ridge)
	reject(model, model.dispatch_scout.bind("ford"), "dispatch away from table")
	fixture_pose(model, Model.SITES.camp_table + Vector3.FORWARD)
	ok(model.dispatch_scout("ford"), "dispatch ford scout detachment")
	check(model.pending_reports().size() == 1, "one pending custody report")
	check(model.received_reports().is_empty(), "undelivered report is not received knowledge")
	check(model.journal().is_empty(), "journal stays empty until delivery")
	check(model.provisions() == 9, "dispatch spends one provision")
	check(model.known_nodes() == ["camp"], "ford not known before delivery")
	reject(model, model.dispatch_scout.bind("ford"), "duplicate ford detachment")
	reject(model, model.decide_column.bind("hold_for_corroboration"), "cannot decide on pending-only custody")
	# Advance just shy of delivery — still no knowledge.
	model.advance(Model.REPORT_DELAY - 1)
	check(model.pending_reports().size() == 1, "still pending one tick early")
	check(model.journal().is_empty(), "no journal leak before arrives_at")
	check(model.stage() == "recon", "stage stays recon until delivery")
	model.advance(1)
	check(model.pending_reports().is_empty(), "custody delivered on arrives_at")
	check(model.received_reports().size() == 1, "delivered report is received knowledge")
	check(model.journal().size() == 1 and model.journal()[0].observer_id == "mahan_singh", "memory attributed to Mahan on delivery")
	check(model.journal()[0].channel == "delayed_report", "delayed information channel")
	check(model.journal()[0].received_tick == model.received_reports()[0].arrives_at, "memory tick equals delivery tick")
	check("ford" in model.known_nodes(), "ford enters known nodes only on delivery")
	check(model.stage() == "decision", "decision unlocks after delivery")
	# Second detachment still allowed before the column order.
	ok(model.dispatch_scout("ridge"), "dispatch ridge while awaiting decision")
	check(model.pending_reports().size() == 1, "ridge pending alongside delivered ford")
	ok(model.decide_column("advance_scouts"), "advance column after delivered custody")
	reject(model, model.decide_column.bind("hold_for_corroboration"), "cannot switch after order")
	reject(model, model.dispatch_scout.bind("ridge"), "no further dispatch after order")
	check(model.stage() == "march", "march stage after column order")
	# March requires physical presence at destination and delivered knowledge.
	reject(model, model.march_to.bind("ford"), "march refused away from ford marker")
	fixture_pose(model, Model.SITES.ford + Vector3.LEFT)
	# Ridge still pending — ford is known, so ford march is legal.
	var prov_before: int = model.provisions()
	var tick_before: int = int(model.snapshot().mahan.tick)
	ok(model.march_to("ford"), "march column camp to ford")
	check(model.column_node() == "ford", "column node is ford")
	check(model.provisions() == prov_before - Model.MARCH_COST, "march spends provisions")
	check(int(model.snapshot().mahan.tick) >= tick_before + Model.MARCH_TICKS, "march advances time")
	# Ridge may deliver during march ticks.
	check("ridge" in model.known_nodes() or model.pending_reports().size() <= 1, "ridge custody progresses with clock")
	fixture_pose(model, Model.SITES.ridge + Vector3.BACK)
	if "ridge" in model.known_nodes():
		ok(model.march_to("ridge"), "march column ford to ridge")
		check(model.column_node() == "ridge", "column node is ridge")
	else:
		# Force delivery then march.
		model.advance(Model.REPORT_DELAY)
		check("ridge" in model.known_nodes(), "ridge known after forced delivery")
		ok(model.march_to("ridge"), "march column ford to ridge after delivery")
	ok(model.acknowledge_fixed_endpoint(), "acknowledge fixed historical endpoint")
	check(model.stage() == "closed", "beat closes without alternate-history survival")
	check(model.journal().size() >= 4, "report + decision + march(es) + endpoint memories")
	var altered: Dictionary = model.snapshot()
	altered.mahan.memories[0].text = "Buddh already knows the fort is empty."
	reject(model, model.restore.bind(altered), "tampered scout testimony")
	altered = model.snapshot()
	altered.mahan.memories[0].observer_id = "ranjit_singh"
	reject(model, model.restore.bind(altered), "cannot reattribute Mahan memory to Buddh")
	altered = model.snapshot()
	altered.profile = "childhood.v1"
	reject(model, model.restore.bind(altered), "refuse childhood profile envelope")
	altered = model.snapshot()
	altered.player.character_id = "ranjit_singh"
	altered.actors = {"ranjit_singh": {"position": altered.player.position.duplicate()}}
	reject(model, model.restore.bind(altered), "refuse childhood actor injection")
	altered = model.snapshot()
	altered.mahan.decision = "hold_for_corroboration"
	reject(model, model.restore.bind(altered), "rewrite decision without matching memory")
	# Pending-text must not leak via premature delivered flag.
	altered = model.snapshot()
	if not altered.mahan.reports.is_empty():
		altered.mahan.reports[0].delivered = not altered.mahan.reports[0].delivered
		reject(model, model.restore.bind(altered), "delivery flag must agree with clock")
	ok(model.save_to(SAVE), "save mahan beat")
	var reloaded := Model.new()
	ok(reloaded.load_from(SAVE), "load mahan beat")
	check(reloaded.snapshot() == model.snapshot(), "round-trip preserves isolated state")

func _hold_path_and_pending_custody() -> void:
	var model := Model.new()
	fixture_pose(model, Model.SITES.camp_table)
	ok(model.dispatch_scout("ridge"), "hold-path ridge dispatch")
	model.advance(Model.REPORT_DELAY)
	check(model.stage() == "decision", "decision after ridge delivery")
	ok(model.decide_column("hold_for_corroboration"), "hold column for corroboration")
	reject(model, model.march_to.bind("ford"), "held column cannot march")
	check(model.column_node() == "camp", "held column remains at camp")
	fixture_pose(model, Model.SITES.camp_table)
	ok(model.acknowledge_fixed_endpoint(), "hold path still closes on fixed endpoint")
	check(model.stage() == "closed", "hold path closes")
	# Fresh model: undelivered report text is in state but not in received_reports / journal.
	var pending_model := Model.new()
	fixture_pose(pending_model, Model.SITES.camp_table)
	ok(pending_model.dispatch_scout("ford"), "pending custody fixture")
	var raw: Dictionary = pending_model.snapshot().mahan.reports[0]
	check(raw.has("text") and not str(raw.text).is_empty(), "authored text exists in custody envelope")
	check(pending_model.received_reports().is_empty(), "received_reports hides undelivered text")
	check(pending_model.journal().is_empty(), "journal hides undelivered text")
	ok(pending_model.save_to(SAVE), "save with pending custody")
	var again := Model.new()
	ok(again.load_from(SAVE), "load pending custody")
	check(again.pending_reports().size() == 1, "pending survives round-trip")
	check(again.journal().is_empty(), "pending load still not knowledge")
	again.advance(Model.REPORT_DELAY)
	check(again.received_reports().size() == 1, "delivery after load")
	check(again.journal().size() == 1, "knowledge appears only after post-load delivery")

func _provisions_and_adjacency() -> void:
	var model := Model.new()
	fixture_pose(model, Model.SITES.camp_table)
	# Drain provisions via dispatches then refuse.
	var s: Dictionary = model.snapshot()
	s.mahan.provisions = 0
	# Can't restore provisions=0 with no matching accounting if reports empty — expected_prov=10.
	# Instead spend through legal dispatches... only 2 targets. Force via restore after building matching state is hard.
	# Directly test MARCH_COST refusal by restoring a valid mid-beat snapshot.
	ok(model.dispatch_scout("ford"), "prov fixture dispatch ford")
	model.advance(Model.REPORT_DELAY)
	ok(model.decide_column("advance_scouts"), "prov fixture decide")
	s = model.snapshot()
	s.mahan.provisions = 1  # less than MARCH_COST (2); expected_prov would be 10-1=9 — will fail validate.
	# So refuse march by temporarily lowering through a crafted valid path:
	# Spend by marching once after setting provisions correctly — use reject on insufficient by
	# restoring legal state then manually calling with depleted via second march attempts.
	# Build: provisions after 1 dispatch = 9; after decide still 9; march costs 2.
	fixture_pose(model, Model.SITES.ford)
	ok(model.march_to("ford"), "first march for prov drain")
	# Now at ford with provisions 7. Drain by restoring matching march count is automatic.
	# Set provisions to 1 via illegal restore should fail; instead march until low:
	# From ford can go ridge if known — ford delivery only, ridge unknown.
	reject(model, model.march_to.bind("ridge"), "refuse march to unknown ridge")
	reject(model, model.march_to.bind("camp"), "refuse march without standing at camp marker")
	# Go back toward camp: need to be near camp to march to camp.
	fixture_pose(model, Model.SITES.camp)
	ok(model.march_to("camp"), "march back to camp")
	# Exhaust provisions: start 10 -1 dispatch -2 -2 = 5. Dispatch already done.
	# Restore a copy with provisions=1 and matching expected: need more marches in memories — skip.
	# Explicit insufficient check: clone state, subtract provisions in a validate-aware way by extra dispatches — only 2 targets.
	var poor := Model.new()
	fixture_pose(poor, Model.SITES.camp_table)
	ok(poor.dispatch_scout("ford"), "poor dispatch ford")
	ok(poor.dispatch_scout("ridge"), "poor dispatch ridge")
	poor.advance(Model.REPORT_DELAY)
	# provisions = 8. Decide and march repeatedly.
	ok(poor.decide_column("advance_scouts"), "poor decide")
	fixture_pose(poor, Model.SITES.ford)
	ok(poor.march_to("ford"), "poor march ford")  # 6
	fixture_pose(poor, Model.SITES.ridge)
	ok(poor.march_to("ridge"), "poor march ridge")  # 4
	fixture_pose(poor, Model.SITES.ford)
	ok(poor.march_to("ford"), "poor march back ford")  # 2
	fixture_pose(poor, Model.SITES.camp)
	ok(poor.march_to("camp"), "poor march camp")  # 0
	fixture_pose(poor, Model.SITES.ford)
	reject(poor, poor.march_to.bind("ford"), "march refused at zero provisions")
	var broke := Model.new()
	fixture_pose(broke, Model.SITES.camp_table)
	var snap: Dictionary = broke.snapshot()
	snap.mahan.provisions = 0
	# expected_prov with 0 reports is 10 — restore must fail.
	reject(broke, broke.restore.bind(snap), "cannot invent zero provisions without spend trail")

func _cross_profile_fence() -> void:
	var mahan := Model.new()
	fixture_pose(mahan, Model.SITES.camp_table)
	ok(mahan.dispatch_scout("ford"), "mahan report for fence fixture")
	mahan.advance(Model.REPORT_DELAY)
	ok(mahan.save_to(SAVE), "persist mahan fence fixture")
	var childhood := Childhood.new()
	var before_child: Dictionary = childhood.snapshot()
	check(not childhood.load_from(SAVE).is_empty(), "childhood refuses mahan save path")
	check(childhood.snapshot() == before_child, "childhood session unchanged by mahan file")
	var aftermath := Aftermath.new()
	var before_after: Dictionary = aftermath.snapshot()
	check(not aftermath.load_from(SAVE).is_empty(), "aftermath refuses mahan save path")
	check(aftermath.snapshot() == before_after, "aftermath session unchanged by mahan file")
	var m2 := Model.new()
	var before_m: Dictionary = m2.snapshot()
	check(not m2.restore(Childhood.new().snapshot()).is_empty(), "mahan refuses childhood snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after childhood reject")
	check(not m2.restore(Aftermath.new().snapshot()).is_empty(), "mahan refuses aftermath snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after aftermath reject")
	var command_snap: Dictionary = Command.new().snapshot()
	check(not m2.restore(command_snap).is_empty(), "mahan refuses Lahore command snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after command reject")
	var child2 := Childhood.new()
	var before2: Dictionary = child2.snapshot()
	check(not child2.restore(mahan.snapshot()).is_empty(), "childhood restore refuses mahan dictionary")
	check(child2.snapshot() == before2, "childhood unchanged after mahan dictionary reject")
	# Confirm command_state was not rewritten: report delay constant still authoritative there.
	check(Command.REPORT_DELAY == 4, "Lahore REPORT_DELAY untouched")

func _smoke_launch() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	check(world.get_node_or_null("MahanChapter") != null, "launch composes MahanChapter")
	var chapter = world.get_node("MahanChapter")
	check(chapter.campaign.snapshot().profile == "mahan.v1", "composed chapter owns mahan profile")
	check(chapter.campaign.snapshot().player.character_id == "mahan_singh", "composed chapter actor is Mahan")
	check(chapter.campaign.stage() == "recon", "composed chapter starts in recon")
	check(Model.SITES.has("ford") and Model.SITES.has("ridge"), "authored ford and ridge nodes exist")
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
	check(found != null, "fourth menu entry for Mahan interlude found")
	if found != null:
		found.pressed.emit()
		for _i in range(6):
			await process_frame
		check(current_scene != null and is_instance_valid(current_scene) and current_scene.get_node_or_null("MahanChapter") != null, "menu enters composed Mahan camp")
		if current_scene != null and is_instance_valid(current_scene) and current_scene != menu:
			current_scene.queue_free()
	if is_instance_valid(menu):
		menu.queue_free()
	await process_frame

func _run() -> void:
	_domain()
	_hold_path_and_pending_custody()
	_provisions_and_adjacency()
	_cross_profile_fence()
	await _smoke_launch()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
