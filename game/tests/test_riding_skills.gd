# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Domain-only receipt fixtures; native integration separately establishes execution facts.
const State := preload("res://mounts/riding_skill_state.gd")
const Prior := preload("res://workshops/workshop_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const Later := preload("res://tests/gujranwala_fixture.gd")
const Checkpoint := preload("res://childhood/checkpoint_store.gd")
const Supply := preload("res://territory/misl_rules.gd")
const SAVE := "user://riding-skills-domain-test-isolated.json"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("RIDING SKILLS: " + message)

func ok(error: String, message: String) -> void:
	check(error.is_empty(), message + ": " + error)

func refused(model, operation: Callable, message: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(operation.call()).is_empty(), message + " refused")
	check(model.snapshot() == before, message + " preserves whole Home")

func digest(value: Variant) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(JSON.stringify(value, "", true, true).to_utf8_buffer())
	return hash.finish().hex_encode()

func early_fixture() -> Dictionary:
	var prior = Prior.new()
	ok(Pose.pose(prior, Base.SITES.letter), "domain fixture approaches courier")
	ok(prior.inspect_letter(), "domain fixture acquires message")
	ok(prior.hear("courier"), "domain fixture hears courier")
	ok(Pose.pose(prior, Base.SITES.steward), "domain fixture approaches steward")
	ok(prior.hear("steward"), "domain fixture hears steward")
	var world: Dictionary = prior.snapshot()
	world.childhood.walked = 6.0
	world.childhood.looked = 1.0
	world.childhood.ride_gate = 1
	# Explicit domain fixture, not a claim of input-driven gate traversal.
	world.childhood.tick = 10000
	world.game_time.hour = 7.0 + 10000.0 / 216000.0
	world.player.position = Base.coords(State.TRAINING_SITE)
	world.actors[Base.Names.HERO_ID].position = world.player.position.duplicate()
	ok(prior.restore(world), "domain fixture preserves existing lesson schema")
	return prior.snapshot()

func eligible():
	var model = State.new()
	ok(model.restore(early_fixture()), "old Home migration at childhood riding lesson")
	return model

func receipt(model) -> Dictionary:
	var proof := {"single_hold_ticks": 60, "paired_hold_ticks": 60,
		"volley_slots": [0, 1, 2, 3], "reloaded_slots": [3, 0, 1, 2]}
	var certificate := {"schema": State.RECEIPT_SCHEMA, "lesson_id": State.LESSON_ID,
		"subject_id": "ranjit_singh", "flashback_actor_id": "mahan_singh",
		"present_sha256": model.present_sha256(), "completion_sha256": digest(proof),
		"entry_tick": model.progress().tick, "completed_tick": 1200,
		"milestones": [{"id": "single_standing", "tick": 120},
			{"id": "paired_standing", "tick": 240}, {"id": "mounted_matchlock", "tick": 241}],
		"historical_status": State.ATTRIBUTION, "facts": proof}
	certificate.completion_sha256 = State.proof_sha256(certificate)
	return certificate

func _run() -> void:
	_test_access_and_migration()
	_test_binding_and_receipt_refusals()
	_test_atomic_skills_and_saves()
	_test_restored_receipt_constraints()
	_test_existing_ledgers_and_checkpoint()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RIDING_SKILLS_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_access_and_migration() -> void:
	var model = State.new()
	ok(model.validate(model.snapshot()), "new additive skill profile validates")
	check(model.capabilities() == {"single_standing": false, "paired_standing": false, "mounted_matchlock": false}, "new skills begin locked")
	check(not model.has_riding_skill("invented_skill"), "unknown skill has no capability")
	check(not model.training_access().is_empty(), "orientation cannot enter advanced riding lesson")
	var old := early_fixture()
	ok(model.restore(old), "old riding save migrates")
	var migrated: Dictionary = model.snapshot()
	migrated.erase("riding_skills")
	check(migrated == old, "missing extension migration preserves every prior Home field")
	check(not model.has_riding_skill("single_standing"), "prior gate progress does not infer new skill grants")
	ok(model.training_access(), "first riding gate and nearby foot pose allow lesson")
	var projection := model.capabilities()
	projection.single_standing = true
	check(not model.has_riding_skill("single_standing"), "capability projection cannot change authority")
	ok(Pose.pose(model, Vector3(20, 0.14, 20)), "fixture moves away from training site")
	check(not model.training_access().is_empty(), "remote training is refused")
	ok(Pose.pose(model, State.TRAINING_SITE + Vector3.UP), "fixture moves above training ground")
	check(not model.training_access().is_empty(), "training requires the local foot-height envelope")
	ok(Pose.pose(model, Base.Riding.position(model.horse_record())), "fixture approaches horse")
	ok(model.mount(), "existing mounted control remains available")
	check(not model.training_access().is_empty(), "mounted hero must dismount before flashback")
	var later = State.new()
	ok(later.restore(Later.complete()), "late prior-world migration remains valid")
	ok(Pose.pose(later, State.TRAINING_SITE), "late world returns to training ground")
	ok(later.training_access(), "missed lesson remains accessible after prior progression")
	check(later.stage() == "escaped", "training eligibility does not rewrite earlier story stages")

func _test_binding_and_receipt_refusals() -> void:
	var model = eligible()
	var admitted := receipt(model)
	var origin: String = admitted.present_sha256
	for value in ["", "a".repeat(63), "G".repeat(64), "0".repeat(64)]:
		refused(model, model.accept_riding_training.bind(admitted, value), "invalid or mismatched expected present digest")
	var bad := admitted.duplicate(true)
	bad.present_sha256 = "0".repeat(64)
	refused(model, model.accept_riding_training.bind(bad, bad.present_sha256), "receipt rebound to a different present")
	for field in admitted:
		bad = admitted.duplicate(true)
		bad.erase(field)
		refused(model, model.accept_riding_training.bind(bad, origin), "receipt missing " + field)
	for field in ["entry_tick", "completed_tick"]:
		for value in [true, NAN, INF, -1, 0.5, 10000001]:
			bad = admitted.duplicate(true)
			bad[field] = value
			refused(model, model.accept_riding_training.bind(bad, origin), "invalid " + field)
	for pair in [["schema", "other.v1"], ["lesson_id", "paired-only-study.v1"],
		["subject_id", "mahan_singh"], ["flashback_actor_id", "ranjit_singh"],
		["historical_status", "verified"], ["completion_sha256", "x".repeat(64)]]:
		bad = admitted.duplicate(true)
		bad[pair[0]] = pair[1]
		refused(model, model.accept_riding_training.bind(bad, origin), "invalid receipt identity " + pair[0])
	bad = admitted.duplicate(true)
	bad.knowledge_grants = ["mahan_battle_location"]
	refused(model, model.accept_riding_training.bind(bad, origin), "receipt cannot append unrequested historical knowledge")
	for milestones in [[], [admitted.milestones[1], admitted.milestones[0], admitted.milestones[2]],
		[admitted.milestones[0], admitted.milestones[0], admitted.milestones[2]]]:
		bad = admitted.duplicate(true)
		bad.milestones = milestones
		refused(model, model.accept_riding_training.bind(bad, origin), "missing, duplicate or reordered skill milestones")
	for value in [true, NAN, -1, 0.5, 1201, 10000001]:
		bad = admitted.duplicate(true)
		bad.milestones[1].tick = value
		refused(model, model.accept_riding_training.bind(bad, origin), "invalid milestone time")
	for field in ["single_hold_ticks", "paired_hold_ticks"]:
		for value in [true, NAN, 0, 59, 60.5, 10000001]:
			bad = admitted.duplicate(true)
			bad.facts[field] = value
			refused(model, model.accept_riding_training.bind(bad, origin), "invalid completed standing hold")
	for field in ["volley_slots", "reloaded_slots"]:
		for slots in [[], [0, 1, 2], [0, 1, 2, 2], [true, 1, 2, 3], [0, 1, 2, 4], [0, 1, 2, NAN]]:
			bad = admitted.duplicate(true)
			bad.facts[field] = slots
			refused(model, model.accept_riding_training.bind(bad, origin), "invalid distinct weapon identities")
	bad = admitted.duplicate(true)
	bad.facts.reloaded_slots = [0, 1, 2, 3]
	refused(model, model.accept_riding_training.bind(bad, origin), "valid changed proof facts with retained completion digest")
	bad = admitted.duplicate(true)
	bad.milestones[2].tick += 1
	refused(model, model.accept_riding_training.bind(bad, origin), "valid changed milestone with retained completion digest")
	model.advance()
	refused(model, model.accept_riding_training.bind(admitted, origin), "Home changed while external lesson was running")
	check(model.capabilities().values() == [false, false, false], "all rejected receipts leave entire capability bundle locked")

func _test_atomic_skills_and_saves() -> void:
	var model = eligible()
	var before: Dictionary = model.snapshot()
	var awarded := receipt(model)
	ok(model.accept_riding_training(awarded, awarded.present_sha256), "complete bound lesson grants skill bundle")
	check(model.capabilities() == {"single_standing": true, "paired_standing": true, "mounted_matchlock": true}, "all three mechanics become available together")
	check(model.snapshot().riding_skills.lesson_receipts.size() == 1, "one lesson has one retained receipt")
	check(model.progress().tick > awarded.completed_tick, "home and lesson tick identities remain separate")
	var after: Dictionary = model.snapshot()
	after.erase("riding_skills")
	before.erase("riding_skills")
	check(after == before, "skill admission preserves every world, economy, pose, clock and memory field")
	var qualified: Dictionary = model.snapshot()
	ok(model.accept_riding_training(awarded, awarded.present_sha256), "exact repeated receipt is idempotent")
	check(model.snapshot() == qualified, "repeat admission cannot duplicate skills or receipts")
	var changed := awarded.duplicate(true)
	changed.completion_sha256 = "a".repeat(64)
	refused(model, model.accept_riding_training.bind(changed, changed.present_sha256), "altered repeat completion cannot replace receipt")
	ok(model.save_to(SAVE), "existing inherited Home save writer persists skills")
	var restored = State.new()
	ok(restored.load_from(SAVE), "same Home save identity loads skills")
	check(Supply._equal(restored.snapshot(), model.snapshot()), "whole new Home state roundtrips including skill receipt")
	check(restored.capabilities() == model.capabilities(), "restored gameplay capabilities are derived from receipt")
	var detached: Dictionary = restored.snapshot()
	detached.riding_skills.lesson_receipts[0].facts.reloaded_slots.clear()
	check(restored.has_riding_skill("paired_standing"), "deep receipt projection cannot erase learned capabilities")
	var old_reader = Prior.new()
	check(not old_reader.restore(model.snapshot()).is_empty(), "old reader explicitly refuses unsupported extension instead of dropping receipts")
	var legacy := model.snapshot()
	legacy.erase("riding_skills")
	ok(restored.restore(legacy), "explicit legacy whole-world restore removes later skill acquisition")
	check(not restored.has_riding_skill("mounted_matchlock"), "legacy restore never carries future skill grants backwards")
	var marker_before: Dictionary = restored.snapshot()
	var checkpoint := {"schema": Checkpoint.SCHEMA, "reason": "return_trail", "camera": [0.0, 0.0], "snapshot": qualified}
	check(not Checkpoint.validate(checkpoint, State).is_empty(), "new authority still enforces original checkpoint reason/location")
	check(restored.snapshot() == marker_before, "checkpoint validation creates no live skill or world mutation")

func _test_restored_receipt_constraints() -> void:
	var model = eligible()
	var awarded := receipt(model)
	ok(model.accept_riding_training(awarded, awarded.present_sha256), "restore tamper fixture acquires skills")
	var valid: Dictionary = model.snapshot()
	for extension in [null, {}, {"schema_version": "riding-skills.v9", "lesson_receipts": []},
		{"schema_version": State.SKILL_SCHEMA, "lesson_receipts": [awarded, awarded]},
		{"schema_version": State.SKILL_SCHEMA, "lesson_receipts": [], "capabilities": {"single_standing": true}}]:
		var bad: Dictionary = valid.duplicate(true)
		bad.riding_skills = extension
		refused(model, model.restore.bind(bad), "malformed, duplicated or writable capability extension")
	var bad: Dictionary = valid.duplicate(true)
	bad.riding_skills.lesson_receipts[0].entry_tick = model.progress().tick + 1
	refused(model, model.restore.bind(bad), "future Home receipt acquisition")
	bad = valid.duplicate(true)
	bad.childhood.ride_gate = 0
	refused(model, model.restore.bind(bad), "receipt before first riding gate")
	bad = valid.duplicate(true)
	bad.riding_skills.lesson_receipts[0].milestones[0].id = "paired_standing"
	refused(model, model.restore.bind(bad), "paired-only completion cannot grant single standing")
	var from_json: Variant = JSON.parse_string(JSON.stringify(valid, "", true, true))
	ok(model.restore(from_json), "JSON numeric normalization restores proof metadata")
	check(typeof(model.snapshot().riding_skills.lesson_receipts[0].entry_tick) == TYPE_INT \
		and typeof(model.snapshot().riding_skills.lesson_receipts[0].facts.reloaded_slots[0]) == TYPE_INT,
		"persisted whole-number proof identities normalize to integer runtime values")

func _test_existing_ledgers_and_checkpoint() -> void:
	var model = State.new()
	ok(model.restore(Later.complete()), "completed prior Home supplies domain fixture")
	ok(model.begin_allowance(), "same Home authority admits original allowance")
	ok(model.workshop_action("reserve"), "original workshop reserves real fuel and payment")
	ok(Pose.pose(model, State.TRAINING_SITE), "active workshop custody returns near trainer")
	var prior: Dictionary = model.snapshot()
	var awarded := receipt(model)
	ok(model.accept_riding_training(awarded, awarded.present_sha256), "riding receipt extends existing full workshop authority")
	check(model.snapshot().misl == prior.misl and model.carrying_workshop(), "training does not settle, refund or recreate existing workshop custody")
	ok(model.save_to(SAVE), "shared save persists skill receipts alongside real economic ledger")
	var loaded = State.new()
	ok(loaded.load_from(SAVE), "shared full-ledger save reads through parent validators")
	check(Supply._equal(loaded.snapshot(), model.snapshot()), "full economic/skill world roundtrips together")
	var learner = eligible()
	awarded = receipt(learner)
	ok(learner.accept_riding_training(awarded, awarded.present_sha256), "checkpoint learner admits bound skill bundle")
	var world: Dictionary = learner.snapshot()
	world.childhood.ride_gate = 3
	world.childhood.parries = 2
	world.childhood.counters = 1
	ok(learner.restore(world), "explicit later-lesson fixture preserves prior skills")
	for index in range(1, 4):
		learner.advance()
		ok(Pose.pose(learner, Base.SITES["track_%d" % index]), "checkpoint fixture approaches existing track")
		ok(learner.inspect_track("track_%d" % index), "checkpoint fixture records original track observation")
	ok(Pose.pose(learner, Base.SITES.quarry), "checkpoint fixture reaches original quarry")
	ok(learner.observe_quarry(true), "original quiet observation unlocks return-trail checkpoint")
	var envelope := {"schema": Checkpoint.SCHEMA, "reason": "return_trail", "camera": [0.0, 0.0], "snapshot": learner.snapshot()}
	ok(Checkpoint.validate(envelope, State), "caller-supplied skill authority validates unchanged checkpoint format")
	check(envelope.snapshot.riding_skills.lesson_receipts == learner.snapshot().riding_skills.lesson_receipts, "checkpoint retains same acquisition receipt without a second skill ledger")
