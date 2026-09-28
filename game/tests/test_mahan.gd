extends SceneTree
## Domain + epistemic fence + one authored beat. Injected save path never writes player slots.
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
	check(model.stage() == "await_report", "starts awaiting delayed scout")
	check(model.journal().is_empty(), "no seeded secret knowledge")
	reject(model, model.decide_column.bind("advance_scouts"), "decision before report")
	reject(model, model.acknowledge_fixed_endpoint, "endpoint before decision")
	reject(model, model.record_position.bind(Vector3(20, 0.14, 20), 1.0 / 60), "teleport sample")
	reject(model, model.record_position.bind(Vector3(NAN, 0, 0), 1.0 / 60), "nonfinite motion")
	fixture_pose(model, Model.SITES.scout + Vector3.RIGHT)
	ok(model.hear_scout_report(), "hear delayed scout report")
	reject(model, model.hear_scout_report, "duplicate scout report")
	check(model.journal().size() == 1 and model.journal()[0].observer_id == "mahan_singh", "memory attributed to Mahan")
	check(model.journal()[0].channel == "delayed_report", "delayed information channel")
	fixture_pose(model, Model.SITES.camp_table + Vector3.FORWARD)
	reject(model, model.decide_column.bind("accuse_rival_house"), "invented political order")
	ok(model.decide_column("hold_for_corroboration"), "hold column for corroboration")
	reject(model, model.decide_column.bind("advance_scouts"), "cannot switch after order")
	ok(model.acknowledge_fixed_endpoint(), "acknowledge fixed historical endpoint")
	check(model.stage() == "closed", "beat closes without alternate-history survival")
	check(model.journal().size() == 3, "report + decision + endpoint memories")
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
	altered.mahan.decision = "advance_scouts"
	reject(model, model.restore.bind(altered), "rewrite decision without matching memory")
	ok(model.save_to(SAVE), "save mahan beat")
	var reloaded := Model.new()
	ok(reloaded.load_from(SAVE), "load mahan beat")
	check(reloaded.snapshot() == model.snapshot(), "round-trip preserves isolated state")

func _cross_profile_fence() -> void:
	var mahan := Model.new()
	fixture_pose(mahan, Model.SITES.scout + Vector3.RIGHT)
	ok(mahan.hear_scout_report(), "mahan report for fence fixture")
	ok(mahan.save_to(SAVE), "persist mahan fence fixture")
	var childhood := Childhood.new()
	var before_child: Dictionary = childhood.snapshot()
	check(not childhood.load_from(SAVE).is_empty(), "childhood refuses mahan save path")
	check(childhood.snapshot() == before_child, "childhood session unchanged by mahan file")
	var aftermath := Aftermath.new()
	var before_after: Dictionary = aftermath.snapshot()
	check(not aftermath.load_from(SAVE).is_empty(), "aftermath refuses mahan save path")
	check(aftermath.snapshot() == before_after, "aftermath session unchanged by mahan file")
	# Inverse: childhood/command snapshots cannot restore into Mahan.
	var m2 := Model.new()
	var before_m: Dictionary = m2.snapshot()
	check(not m2.restore(Childhood.new().snapshot()).is_empty(), "mahan refuses childhood snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after childhood reject")
	check(not m2.restore(Aftermath.new().snapshot()).is_empty(), "mahan refuses aftermath snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after aftermath reject")
	var command_snap: Dictionary = Command.new().snapshot()
	check(not m2.restore(command_snap).is_empty(), "mahan refuses Lahore command snapshot")
	check(m2.snapshot() == before_m, "mahan unchanged after command reject")
	# Childhood authority also rejects a mahan-shaped dictionary restore.
	var child2 := Childhood.new()
	var before2: Dictionary = child2.snapshot()
	check(not child2.restore(mahan.snapshot()).is_empty(), "childhood restore refuses mahan dictionary")
	check(child2.snapshot() == before2, "childhood unchanged after mahan dictionary reject")

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
	world.queue_free()
	await process_frame
	# Menu signal path: fourth entry should call launch composition.
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
	_cross_profile_fence()
	await _smoke_launch()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
