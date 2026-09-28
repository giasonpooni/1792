extends SceneTree
const Model := preload("res://mahan/mahan_cavalry_state.gd")
const BaseModel := preload("res://mahan/mahan_state.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const Launch := preload("res://mahan/mahan_launch.gd")
const SAVE := "user://mahan-cavalry-regression.json"
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
	s.mahan.erase("household_id")
	s.player.position = BaseModel.coords(p)
	s.actors[BaseModel.ACTOR_ID].position = BaseModel.coords(p)
	ok(BaseModel.new().validate(s), "base fixture structurally valid")
	model._state = s.duplicate(true)
	if riding != null: model._riding = riding.duplicate(true)

func _domain() -> void:
	var model := Model.new()
	check(not BaseModel.new().snapshot().has("riding"), "base Mahan remains riding-free")
	model.enable_riding()
	ok(model.validate(model.snapshot()), "initial cavalry snapshot")
	check(model.snapshot().profile == "mahan.v1", "same fenced Mahan profile")
	check(model.snapshot().player.character_id == "mahan_singh", "Person remains mahan_singh")
	check(model.snapshot().mahan.household_id == "sukerchakia", "Sukerchakia is household graph object")
	check(model.horse_state().id == Riding.HORSE_ID, "shared riding horse id")
	check(model.snapshot().riding.schema_version == Riding.VERSION, "shared riding version")
	reject(model, model.mount_horse, "far mount")
	var hp := Riding.position(model.horse_state())
	pose(model, hp + Vector3(1.4, 0.1, 0))
	ok(model.mount_horse(), "Mahan mounts")
	check(model.is_mounted(), "mounted")
	check(model.horse_state().rider_id == "mahan_singh", "Mahan rider id")
	reject(model, model.dispatch_scout.bind("ford"), "mounted dispatch gate")
	reject(model, model.decide_column.bind("advance_scouts"), "mounted decision gate")
	reject(model, model.march_to.bind("ford"), "mounted march gate")
	reject(model, model.acknowledge_fixed_endpoint, "mounted endpoint gate")
	reject(model, model.record_position.bind(hp, 1.0/60.0), "mounted walk sample gate")
	var motion := {"position": [hp.x + 0.3, 0.04, hp.z - 0.1], "yaw": -0.2, "speed": 3.0, "vertical_speed": 0.0, "grounded": true}
	ok(model.record_ride(motion, 1.0/30.0), "short mounted travel")
	check(model.position().distance_to(Riding.position(model.horse_state())) < 0.01, "actor and horse agree")
	motion.position = model.horse_state().position.duplicate()
	motion.speed = 0.0
	ok(model.record_ride(motion, 1.0/30.0), "brake")
	var landing := Riding.position(model.horse_state()) + Vector3(1.8, 0, 0)
	ok(model.dismount_horse(landing), "dismount")
	check(not model.is_mounted(), "parked after dismount")
	check(model.position().distance_to(landing) < 0.01, "actor lands beside horse")
	# Existing Lahore validator remains unchanged and rejects this new profile rider.
	var mounted: Dictionary = model.snapshot().riding.duplicate(true)
	mounted.horse.rider_id = "mahan_singh"
	var world := {"player": {"character_id": "mahan_singh", "position": mounted.horse.position}, "actors": {"mahan_singh": {"position": mounted.horse.position}}, "order": {"status": "active", "mode": "manual"}}
	check(not Riding.validate(mounted, world).is_empty(), "Lahore riding contract still rejects Mahan")
	pose(model, BaseModel.SITES.camp_table)
	ok(model.dispatch_scout("ford"), "dispatch after dismount")
	ok(model.save_to(SAVE), "save cavalry + pending custody")
	var again := Model.new()
	ok(again.load_from(SAVE), "load cavalry save")
	check(again.pending_reports().size() == 1 and again.journal().is_empty(), "pending custody remains unknowable")
	check(again.horse_state().rider_id == "", "parked horse round trip")
	var bad: Dictionary = again.snapshot()
	bad.riding.horse.rider_id = "ranjit_singh"
	bad.player.position = bad.riding.horse.position.duplicate()
	bad.actors[BaseModel.ACTOR_ID].position = bad.riding.horse.position.duplicate()
	reject(again, again.restore.bind(bad), "Ranjit rider injection")
	bad = again.snapshot()
	bad.mahan.household_id = "sandhawalia"
	reject(again, again.restore.bind(bad), "Raj Kaur/Sandhawalia ontology collapse")

func _smoke() -> void:
	var world := Launch.make_world()
	root.add_child(world)
	current_scene = world
	await physics_frame
	await process_frame
	var chapter = world.get_node("MahanChapter")
	check(chapter != null, "launch composes cavalry chapter")
	check(chapter.get_node_or_null("FieldHorse") != null, "horse adapter spawned")
	check(chapter.campaign.snapshot().player.character_id == "mahan_singh", "chapter rider identity")
	check(chapter.campaign.snapshot().mahan.household_id == "sukerchakia", "chapter household object")
	world.queue_free()
	await process_frame

func _run() -> void:
	_domain()
	await _smoke()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("MAHAN_CAVALRY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
