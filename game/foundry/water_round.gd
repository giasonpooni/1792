# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Game-owned NET Foundry adapter. Explicit domain fixture, NOT a played journey.
## The live reducer/clock/save APIs are unchanged. No NET implementation is vendored.
const State := preload("res://territory/gujranwala_state.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func require_ok(error: String) -> bool:
	if error.is_empty(): return true
	failed = true
	push_error("FOUNDRY_REFUSED: " + error)
	quit(2)
	return false

func sample(model, stage: String) -> Dictionary:
	return {"stage":stage, "tick":int(model.snapshot().childhood.tick),
		"ledger":model.water_round().ledger, "money":model.economy().ledger,
		"known_places":model.snapshot().player.known_places.duplicate()}

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		require_ok("Expected request, response and isolated save paths.")
		return
	var file := FileAccess.open(args[0], FileAccess.READ)
	if file == null or file.get_length() > 4096:
		require_ok("Missing or oversized request.")
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		require_ok("Malformed request.")
		return
	file.close()
	var request: Variant = parser.data
	if not request is Dictionary or request.size() != 4 or request.get("schema") != "ciw.foundry-water-request.v1":
		require_ok("Unsupported request contract.")
		return
	if not request.get("nonce") is String or not request.get("source_lock_id") is String or not (request.get("trips") is float or request.get("trips") is int) or request.trips not in [1,2]:
		require_ok("Invalid request fields.")
		return
	var model := State.new()
	if not require_ok(model.restore(Fixture.complete())): return
	if not require_ok(model.begin_allowance()): return
	if not require_ok(Pose.pose(model, Water.STORE - Vector3(0,0,1))): return
	if not require_ok(model.begin_water_round()): return
	var samples: Array = [sample(model, "assigned")]
	var checkpoint_before: Dictionary = {}
	var checkpoint_after: Dictionary = {}
	for trip in range(int(request.trips)):
		if not require_ok(Pose.pose(model, Water.WELL + Vector3(2,0,-1))): return
		if not require_ok(model.water_action("draw")): return
		samples.append(sample(model, "draw-start"))
		for _i in range(90): model.advance()
		if trip == 0:
			checkpoint_before = model.snapshot()
			if not require_ok(model.save_to(args[2])): return
			var restored := State.new()
			if not require_ok(restored.load_from(args[2])): return
			checkpoint_after = restored.snapshot()
			model = restored
		for _i in range(89): model.advance()
		samples.append(sample(model, "before-fill"))
		model.advance()
		samples.append(sample(model, "filled"))
		if not require_ok(Pose.pose(model, Water.STORE - Vector3(0,0,1))): return
		if not require_ok(model.water_action("deposit")): return
		samples.append(sample(model, "deposited"))
	var before_duplicate := sample(model, "duplicate-probe")
	var duplicate_error: String = model.water_action("deposit")
	var after_duplicate := sample(model, "duplicate-probe")
	if not require_ok(model.validate(model.snapshot())): return
	var response := {"schema":"cartesian.foundry-water-observations.v1",
		"request_nonce":request.nonce, "source_lock_id":request.source_lock_id,
		"engine_version":Engine.get_version_info().string,
		"model_id":Water.MODEL_ID, "clock_id":"1792.childhood.tick", "tick_hz":60,
		"source_class":"authored_game_with_explicit_domain_fixture",
		"trips":int(request.trips), "samples":samples, "water_round":model.water_round(),
		"checkpoint_before":checkpoint_before, "checkpoint_after":checkpoint_after,
		"duplicate_error":duplicate_error, "before_duplicate":before_duplicate,
		"after_duplicate":after_duplicate}
	var encoded := JSON.stringify(response, "", true, true)
	if encoded.to_utf8_buffer().size() > 65536:
		require_ok("Response exceeds capture budget.")
		return
	file = FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		require_ok("Cannot create response.")
		return
	file.store_string(encoded)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		require_ok("Response write failed.")
		return
	print("FOUNDRY_WATER: captured ", request.trips, " trips; acceptance belongs to NET")
	quit(0)
