extends SceneTree

const State := preload("res://mounts/horsecraft_state.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func ok(error: String, message: String) -> void:
	check(error.is_empty(), message + ": " + error)

func record(at: Vector3 = Vector3.ZERO, speed: float = 2.0, yaw: float = 0.0, grounded: bool = true) -> Dictionary:
	return {"position": [at.x, at.y, at.z], "yaw": yaw, "speed": speed, "grounded": grounded}

func pair(model, speed: float = 2.0) -> Dictionary:
	return model.metrics(record(Vector3(-1.05, 0, 0), speed), record(Vector3(1.05, 0, 0), speed))

func refuse(model, operation: Callable, message: String) -> void:
	var before: Dictionary = model.snapshot()
	var result: Variant = operation.call()
	check(not str(result).is_empty() if result is String else result is Dictionary and result.get("accepted") == false, message + " refused")
	check(model.snapshot() == before, message + " preserves complete snapshot")

func tick(model, observation: Dictionary, count: int, steering: float = 0.0, lean: float = 0.0) -> void:
	for _i in range(count):
		var error: String = model.advance(observation, steering, lean)
		if not error.is_empty():
			check(false, "valid observation advances: " + error)
			return

func standing(model, speed: float = 2.0) -> Dictionary:
	var observation := pair(model, speed)
	tick(model, observation, 1)
	ok(model.toggle_stance(observation), "enter supported rising stance")
	tick(model, observation, 85)
	check(model.stance() == "standing" and model.snapshot().stage == "volley", "sustained support reaches standing volley objective")
	return observation

func _run() -> void:
	_test_isolation_and_invalid_inputs()
	_test_geometry_and_recovery()
	_test_lean_and_determinism()
	_test_slots_and_hit_identities()
	_test_reload_pause()
	_test_mission_order()
	_test_distinct_volley_and_bounded_events()
	print("HORSECRAFT_STATE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_isolation_and_invalid_inputs() -> void:
	var model = State.new()
	var fresh: Dictionary = model.snapshot()
	check(fresh.historical_status == "user-attributed-unverified", "story attribution never becomes authenticated history")
	check(fresh.stage == "approach" and fresh.slots == [true, true, true, true], "study starts with isolated four-charge inventory")
	var copy: Dictionary = model.snapshot()
	copy.slots[0] = false
	copy.shots.append({"id": 999})
	check(model.snapshot() == fresh, "deep read cannot mutate slot or shot authority")
	check(not fresh.has("campaign") and not fresh.has("save_path") and not fresh.has("date"), "no campaign, persistence or invented historical date")
	var observation := pair(model)
	for slot in [true, false, 1.0, -1, 4, "1", null]:
		refuse(model, model.select_slot.bind(slot), "invalid slot " + str(slot))
	for field in ["yaw", "speed", "position", "grounded"]:
		var bad := record()
		bad.erase(field)
		var measured: Dictionary = model.metrics(bad, record(Vector3(2.1, 0, 0)))
		check(not measured.valid and not measured.safe, "missing " + field + " observation is invalid")
		refuse(model, model.advance.bind(measured, 0.0, 0.0), "advance missing " + field)
	for field in ["yaw", "speed"]:
		for value in [NAN, INF, -INF, true]:
			var bad := record()
			bad[field] = value
			var measured: Dictionary = model.metrics(bad, record(Vector3(2.1, 0, 0)))
			check(not measured.valid, "nonfinite or boolean " + field + " invalid")
			refuse(model, model.fire.bind(measured), "fire invalid " + field)
	var invalid_position := record()
	invalid_position.position = [NAN, 0.0, 0.0]
	var invalid_metrics: Dictionary = model.metrics(invalid_position, record(Vector3(2.1, 0, 0)))
	refuse(model, model.toggle_stance.bind(invalid_metrics), "nonfinite position stance")
	refuse(model, model.reload.bind(invalid_metrics), "nonfinite position reload")
	for field in ["separation", "fore_aft", "yaw_gap", "speed_gap", "mean_speed", "min_speed", "max_speed", "height_gap"]:
		var bad: Dictionary = observation.duplicate(true)
		bad[field] = NAN
		refuse(model, model.advance.bind(bad, 0.0, 0.0), "tampered nonfinite metric " + field)
	for input in [NAN, INF, true, 1.01, -1.01]:
		refuse(model, model.advance.bind(observation, input, 0.0), "invalid steering")
		refuse(model, model.advance.bind(observation, 0.0, input), "invalid lean")
	var contradictory: Dictionary = observation.duplicate(true)
	contradictory.max_speed = 0.0
	refuse(model, model.advance.bind(contradictory, 0.0, 0.0), "contradictory speed summaries")

func _test_geometry_and_recovery() -> void:
	var model = State.new()
	var observation := pair(model)
	check(observation.safe and is_equal_approx(observation.separation, 2.1), "ordinary side-by-side support is safe")
	var turned: Dictionary = model.metrics(record(Vector3(0, 0, -1.05), 2.0, PI * 0.5), record(Vector3(0, 0, 1.05), 2.0, PI * 0.5))
	check(turned.safe and turned.fore_aft < 0.00001, "support rotates with horses instead of world axes")
	var wrapped: Dictionary = model.metrics(record(Vector3(-1.05, 0, 0), 2.0, PI - 0.02), record(Vector3(1.05, 0, 0), 2.0, -PI + 0.02))
	check(wrapped.safe and wrapped.yaw_gap < 0.05, "wrapped yaws straddling PI remain aligned")
	for right_record in [record(Vector3(0.3, 0, 0)), record(Vector3(3.0, 0, 0)), record(Vector3(1.05, 0, 1.0)),
		record(Vector3(1.05, 0.5, 0)), record(Vector3(1.05, 0, 0), 2.0, 0.5),
		record(Vector3(1.05, 0, 0), 2.0, 0.0, false), record(Vector3(1.05, 0, 0), 5.0)]:
		var unsafe: Dictionary = model.metrics(record(Vector3(-1.05, 0, 0)), right_record)
		check(not unsafe.safe, "unsafe support is detected from horse measurements")
		refuse(model, model.toggle_stance.bind(unsafe), "rise on unsafe pair")
		var forged: Dictionary = unsafe.duplicate(true)
		forged.safe = true
		refuse(model, model.toggle_stance.bind(forged), "forged safety summary")
	check(not pair(model, 7.0).safe, "two equally fast horses still exceed supported gait")
	var roundoff := pair(model, 6.50000047683716)
	check(roundoff.safe, "observed float32 trot roundoff retains supported gait")
	check(not pair(model, 6.5001).safe, "numeric tolerance does not admit a genuinely higher speed")
	observation = standing(model)
	ok(model.advance(roundoff, 0.1, -0.1), "nominal trot turn survives motor speed roundoff")
	check(model.stance() == "standing", "speed roundoff cannot spuriously drop supported rider")
	var airborne: Dictionary = model.metrics(record(Vector3(-1.05, 0, 0)), record(Vector3(1.05, 0, 0), 2.0, 0.0, false))
	ok(model.advance(airborne, 0.0, 0.0), "unsupported standing observation is retained as an operation")
	check(model.stance() == "recovering" and model.snapshot().brake_required, "support loss triggers lowering and scene brake request")
	refuse(model, model.toggle_stance.bind(observation), "cannot bypass recovery")
	refuse(model, model.fire.bind(observation), "cannot shoot during recovery")
	tick(model, observation, 40)
	check(model.stance() == "seated" and not model.snapshot().brake_required, "timed recovery returns to single seated support")

func _test_lean_and_determinism() -> void:
	var neutral = State.new()
	var counter = State.new()
	var replay = State.new()
	var observation := standing(neutral, 6.5)
	standing(counter, 6.5)
	standing(replay, 6.5)
	tick(neutral, observation, 120, 1.0, 0.0)
	tick(counter, observation, 120, 1.0, -1.0)
	tick(replay, observation, 120, 1.0, -1.0)
	check(counter.snapshot() == replay.snapshot(), "identical submitted ticks replay without TIME, timers or random state")
	check(counter.snapshot().balance > neutral.snapshot().balance and absf(counter.snapshot().sway) < absf(neutral.snapshot().sway), "opposite lean reduces turn sway and balance drain")
	check(counter.stance() == "standing", "controlled lean sustains standing under turn")
	var low: bool = false
	for _i in range(400):
		neutral.advance(observation, 1.0, 0.0)
		if neutral.stance() == "recovering":
			low = true
			break
	check(low and neutral.snapshot().brake_required, "uncontrolled turn eventually exhausts support and brakes")
	var still = State.new()
	var moving = State.new()
	var stationary: Dictionary = still.fire(pair(still, 0.0))
	var mobile: Dictionary = moving.fire(pair(moving, 6.0))
	check(stationary.accepted and mobile.accepted and mobile.dispersion > stationary.dispersion, "moving discharge has authored dispersion penalty")

func _test_slots_and_hit_identities() -> void:
	var model = State.new()
	var observation := pair(model)
	refuse(model, model.record_hit.bind(1, "practice_1"), "unfired shot cannot claim target")
	refuse(model, model.reload.bind(observation), "charged slot cannot reload")
	for slot in range(4):
		ok(model.select_slot(slot), "select independent slot")
		var shot: Dictionary = model.fire(observation)
		check(shot.accepted and shot.slot == slot and shot.shot_id == slot + 1, "accepted shot identity follows event order")
		check(not model.snapshot().slots[slot], "one shot consumes only selected charge")
		refuse(model, model.fire.bind(observation), "empty slot cannot fire twice")
	check(model.snapshot().slots == [false, false, false, false], "four independent slots exhaust separately")
	check(model.snapshot().stage == "approach", "seated practice fire cannot skip mission ordering")
	for shot_id in [true, 1.0, 0, -1, 5, null]:
		refuse(model, model.record_hit.bind(shot_id, "practice_1"), "invalid shot identity")
	for target in [null, true, "", "x".repeat(65)]:
		refuse(model, model.record_hit.bind(1, target), "invalid practice target identity")
	ok(model.record_hit(1, "practice_1"), "accepted physics contact acknowledges existing shot")
	refuse(model, model.record_hit.bind(1, "practice_2"), "one shot cannot credit multiple hits")
	check(model.snapshot().hits == [{"shot_id": 1, "target_id": "practice_1"}], "hit ledger retains operation identity separately from shot")
	model.restart()
	check(model.snapshot() == State.new().snapshot(), "restart clears only local experiment state and event identities")

func _test_reload_pause() -> void:
	var model = State.new()
	var slow := pair(model, 2.0)
	check(model.fire(slow).accepted, "reload test empties first charge")
	refuse(model, model.reload.bind(pair(model, 4.0)), "faster supported gait refuses reload start")
	ok(model.reload(slow), "slower supported gait starts one charge cycle")
	tick(model, slow, 60)
	check(model.snapshot().reload_ticks == 60 and not model.snapshot().slots[0], "charge cannot complete early")
	refuse(model, model.reload.bind(slow), "exclusive reload cannot be restarted")
	refuse(model, model.select_slot.bind(1), "cannot move active reload into another slot")
	refuse(model, model.fire.bind(slow), "cannot fire another action during charge cycle")
	tick(model, pair(model, 4.0), 90)
	check(model.snapshot().reload_ticks == 60 and model.snapshot().reload_paused, "higher speed pauses charge work without hidden advancement")
	var unsupported: Dictionary = model.metrics(record(Vector3(-1.05, 0, 0)), record(Vector3(1.05, 0, 0), 2.0, 0.0, false))
	tick(model, unsupported, 45)
	check(model.snapshot().reload_ticks == 60 and not model.snapshot().slots[0], "ground contact loss also pauses charge work")
	tick(model, slow, 119)
	check(model.snapshot().reload_ticks == 179 and not model.snapshot().slots[0], "paused cycle resumes its retained work")
	tick(model, slow, 1)
	check(model.snapshot().reload_slot == -1 and model.snapshot().reload_ticks == 0 and model.snapshot().slots[0], "exactly one complete abstract charge cycle replenishes only its slot")
	check(model.snapshot().reload_completions.size() == 1 and model.snapshot().reload_completions[0].slot == 0, "reload completion ledger names only the charged slot")

func _test_mission_order() -> void:
	var model = State.new()
	var stopped := pair(model, 0.0)
	tick(model, stopped, 60)
	check(model.snapshot().stage == "approach", "elapsed time alone cannot finish approach")
	ok(model.toggle_stance(stopped), "standing practice is allowed before mission approach")
	tick(model, stopped, 85)
	check(model.stance() == "standing" and model.snapshot().stage == "approach", "stationary standing cannot bypass moving approach objective")
	model.restart()
	var moving := pair(model, 2.0)
	tick(model, moving, 1)
	check(model.snapshot().stage == "stand", "paired moving approach advances first objective")
	ok(model.toggle_stance(moving), "start mission stance transition")
	refuse(model, model.fire.bind(moving), "rising cannot discharge")
	tick(model, moving, 48)
	check(model.stance() == "standing" and model.snapshot().stage == "stand", "standing still requires sustained support objective")
	tick(model, moving, 29)
	check(model.snapshot().stage == "volley", "sustained support unlocks volley objective")
	for slot in range(4):
		ok(model.select_slot(slot), "select volley slot")
		check(model.fire(moving).accepted, "standing volley consumes real charged slot")
		if slot < 3:
			check(model.snapshot().stage == "volley", "partial volley cannot skip remaining independent slots")
	check(model.snapshot().stage == "reload" and model.snapshot().volley_count == 4, "four standing slots unlock four-slot reload objective")
	tick(model, stopped, 10)
	check(model.snapshot().stage == "reload", "stopping alone cannot complete reload objective")
	ok(model.reload(moving), "standing slower gait can charge")
	tick(model, moving, 180)
	check(model.snapshot().stage == "reload" and model.snapshot().slots == [false, false, false, true], "one completed charge cannot satisfy four-weapon reload objective")
	for slot in range(3):
		ok(model.select_slot(slot), "select each remaining empty weapon")
		ok(model.reload(moving), "start remaining weapon charge")
		tick(model, moving, 180)
		if slot < 2:
			check(model.snapshot().stage == "reload", "partial recharge cannot finish four-slot objective")
	check(model.snapshot().stage == "exit" and model.snapshot().slots == [true, true, true, true], "four separate completed charges advance exit after preceding mission stages")
	check(model.snapshot().reload_completions.size() == 4 and model.snapshot().reload_completions.map(func(entry): return entry.slot) == [3, 0, 1, 2], "actual charge completions retain distinct slot identities and accepted order")
	tick(model, stopped, 60)
	check(model.snapshot().stage == "exit", "standing stop cannot bypass seated exit")
	ok(model.toggle_stance(stopped), "lower stance for exit")
	tick(model, stopped, 40)
	check(model.snapshot().stage == "complete" and model.stance() == "seated", "ordered study completes only after lowering and stopping")
	check(model.snapshot().historical_status == "user-attributed-unverified", "success never promotes story to evidence")

func _test_distinct_volley_and_bounded_events() -> void:
	var model = State.new()
	var observation := standing(model)
	check(model.fire(observation).accepted, "first standing slot is discharged")
	ok(model.reload(observation), "standing slot can be replenished during practice")
	tick(model, observation, 180)
	check(model.fire(observation).accepted, "replenished slot can produce another real shot")
	check(model.snapshot().volley_count == 1 and model.snapshot().stage == "volley", "repeated use of one slot cannot masquerade as four-slot volley")
	var bounded = State.new()
	var stopped := pair(bounded, 0.0)
	var errors := 0
	for _i in range(256):
		if not bounded.fire(stopped).accepted:
			errors += 1
		if not bounded.reload(stopped).is_empty():
			errors += 1
		tick(bounded, stopped, 180)
	check(errors == 0 and bounded.snapshot().shots.size() == 256, "bounded accepted ledger retains every authorized event identity")
	refuse(bounded, bounded.fire.bind(stopped), "shot budget exhaustion")
	check(bounded.snapshot().slots[0], "budget refusal does not consume available ammunition")
