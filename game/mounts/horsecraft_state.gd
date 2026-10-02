extends RefCounted
## Isolated, deterministic horsecraft study. The scene alone owns horse physics.
## Authored play thresholds and matchlock charge timing are game abstractions,
## not a riding instruction, ballistic simulation or historical reconstruction.
## No campaign authority, inventory, saves, clocks or historical grants live here.

const TICK_HZ := 60
const RISE_TICKS := 48
const RECOVER_TICKS := 36
const STAND_OBJECTIVE_TICKS := 30
const RELOAD_TICKS := 180
const MAX_SPEED := 6.5
const RELOAD_SPEED := 3.2
# The existing Vector3 motor reports float32 speeds: a nominal 6.5 m/s turn
# can measure 6.5000004768. This tolerance admits that roundoff, not a faster gait.
const SPEED_EPSILON := 0.00001
const MAX_SHOTS := 256
const MAX_TICKS := 2147483646
const HISTORICAL_STATUS := "user-attributed-unverified"

var _state: Dictionary

func _init() -> void:
	restart()

func restart() -> void:
	_state = {"schema_version": "horsecraft-study.v1", "historical_status": HISTORICAL_STATUS,
		"tick": 0, "stance": "seated", "stance_ticks": 0, "balance": 1.0, "sway": 0.0,
		"brake_required": false, "stage": "approach", "standing_ticks": 0, "volley_count": 0, "volley_slots": [],
		"slots": [true, true, true, true], "selected_slot": 0,
		"reload_slot": -1, "reload_ticks": 0, "reload_paused": false,
		"shots": [], "hits": [], "reload_completions": [], "objective": "Move both horses together at a controlled gait."}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func stance() -> String:
	return _state.stance

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _record_error(record: Variant) -> String:
	if not record is Dictionary:
		return "Horse observation must be a dictionary."
	for key in ["position", "yaw", "speed", "grounded"]:
		if not record.has(key):
			return "Horse observation lacks " + key + "."
	if not record.position is Array or record.position.size() != 3:
		return "Horse position must contain three finite coordinates."
	for coordinate in record.position:
		if not _number(coordinate) or absf(float(coordinate)) > 100000.0:
			return "Horse position is outside the finite study bounds."
	if not _number(record.yaw) or absf(float(record.yaw)) > PI:
		return "Horse yaw must be finite and wrapped to [-PI, PI]."
	if not _number(record.speed) or float(record.speed) < 0.0 or float(record.speed) > 20.0:
		return "Horse speed must be a finite observation between 0 and 20."
	if typeof(record.grounded) != TYPE_BOOL:
		return "Horse grounded observation must be boolean."
	return ""

func metrics(left_record: Variant, right_record: Variant) -> Dictionary:
	var error := _record_error(left_record)
	if error.is_empty():
		error = _record_error(right_record)
	if not error.is_empty():
		return {"valid": false, "safe": false, "reason": error}
	var left := Vector3(float(left_record.position[0]), float(left_record.position[1]), float(left_record.position[2]))
	var right := Vector3(float(right_record.position[0]), float(right_record.position[1]), float(right_record.position[2]))
	var yaw_gap := absf(wrapf(float(right_record.yaw) - float(left_record.yaw), -PI, PI))
	var yaw := float(left_record.yaw) + wrapf(float(right_record.yaw) - float(left_record.yaw), -PI, PI) * 0.5
	var side := Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var offset := right - left
	var measured := {"valid": true, "separation": absf(offset.dot(side)),
		"fore_aft": absf(offset.dot(forward)), "yaw_gap": yaw_gap,
		"height_gap": absf(offset.y), "speed_gap": absf(float(left_record.speed) - float(right_record.speed)),
		"grounded": bool(left_record.grounded and right_record.grounded),
		"mean_speed": (float(left_record.speed) + float(right_record.speed)) * 0.5,
		"min_speed": minf(float(left_record.speed), float(right_record.speed)),
		"max_speed": maxf(float(left_record.speed), float(right_record.speed))}
	measured.safe = _support_safe(measured)
	return measured

func single_metrics(horse_record: Variant) -> Dictionary:
	var error:=_record_error(horse_record)
	if not error.is_empty(): return {"valid":false,"safe":false,"reason":error}
	# Single support has no measured pair geometry. Its explicit kind keeps
	# these zero-valued, inapplicable fields separate from the pair envelope.
	var speed: float=horse_record.speed
	var measured:={"valid":true,"support_kind":"single","separation":0.0,
		"fore_aft":0.0,"yaw_gap":0.0,"height_gap":0.0,"speed_gap":0.0,
		"grounded":horse_record.grounded,"mean_speed":speed,"min_speed":speed,"max_speed":speed}
	measured.safe=_support_safe(measured)
	return measured

static func _metrics_error(observation: Variant) -> String:
	if not observation is Dictionary or observation.get("valid") != true:
		return "A valid pair observation is required."
	for key in ["separation", "fore_aft", "yaw_gap", "height_gap", "speed_gap", "mean_speed", "min_speed", "max_speed"]:
		if not observation.has(key) or not _number(observation[key]) or float(observation[key]) < 0.0:
			return "Pair observation has invalid " + key + "."
	for key in ["grounded", "safe", "valid"]:
		if typeof(observation.get(key)) != TYPE_BOOL:
			return "Pair observation has invalid " + key + "."
	if observation.get("support_kind","pair") not in ["single","pair"]:
		return "Unknown riding support kind."
	if observation.get("support_kind","pair")=="single":
		for key in ["separation","fore_aft","yaw_gap","height_gap","speed_gap"]:
			if observation[key]!=0.0: return "Single support cannot contain pair geometry."
	# A caller cannot make an unsafe measurement safe by flipping a summary flag.
	if observation.safe != _support_safe(observation):
		return "Pair safety flag disagrees with the measured support."
	if observation.max_speed > 20.0 or observation.min_speed > observation.max_speed:
		return "Pair speed observation is inconsistent."
	if absf(observation.mean_speed - (observation.min_speed + observation.max_speed) * 0.5) > 0.00001 \
		or absf(observation.speed_gap - (observation.max_speed - observation.min_speed)) > 0.00001:
		return "Pair speed summary is inconsistent."
	return ""

static func _support_safe(observation: Dictionary) -> bool:
	if observation.get("support_kind","pair")=="single":
		return observation.grounded and observation.max_speed<=MAX_SPEED+SPEED_EPSILON
	return observation.grounded and observation.separation >= 1.8 and observation.separation <= 2.6 \
		and observation.fore_aft <= 0.45 and observation.yaw_gap <= 0.2 \
		and observation.height_gap <= 0.35 and observation.speed_gap <= 1.2 and observation.max_speed <= MAX_SPEED + SPEED_EPSILON

func toggle_stance(observation: Variant) -> String:
	var error := _metrics_error(observation)
	if not error.is_empty():
		return error
	if stance() == "recovering":
		return "Finish recovery before changing stance."
	if stance() in ["rising", "standing"]:
		_begin_recovery()
		return ""
	if not observation.safe:
		return "Align both grounded horses at a controlled gait before rising."
	if _state.balance < 0.6:
		return "Recover balance before rising."
	if _state.reload_slot >= 0:
		return "Finish the active charge cycle before changing support."
	_state.stance = "rising"
	_state.stance_ticks = 0
	return ""

func _begin_recovery() -> void:
	_state.stance = "recovering"
	_state.stance_ticks = 0
	_state.brake_required = true
	_state.standing_ticks = 0

func advance(observation: Variant, steering: Variant, lean: Variant) -> String:
	var error := _metrics_error(observation)
	if not error.is_empty():
		return error
	if not _number(steering) or not _number(lean) or absf(float(steering)) > 1.0 or absf(float(lean)) > 1.0:
		return "Steering and lean must be finite inputs between -1 and 1."
	_state.tick = mini(_state.tick + 1, MAX_TICKS)
	if stance() in ["rising", "standing"]:
		if not observation.safe:
			_begin_recovery()
		else:
			# Opposite-sign player lean counters authored turn drift. There is no RNG.
			var effort := absf(float(steering) + float(lean))
			var movement: float = observation.mean_speed / MAX_SPEED
			_state.sway = clampf(_state.sway * 0.985 + (float(steering) + float(lean)) * 0.007 * movement, -1.0, 1.0)
			_state.balance = clampf(_state.balance + (0.0018 if effort <= 0.12 else -0.003 * effort * movement), 0.0, 1.0)
			if _state.balance <= 0.15 or absf(_state.sway) >= 0.85:
				_begin_recovery()
	if stance() == "rising":
		_state.stance_ticks += 1
		if _state.stance_ticks >= RISE_TICKS:
			_state.stance = "standing"
			_state.stance_ticks = 0
	elif stance() == "standing":
		_state.stance_ticks = mini(_state.stance_ticks + 1, MAX_TICKS)
	elif stance() == "recovering":
		_state.stance_ticks += 1
		_state.balance = minf(_state.balance + 0.008, 1.0)
		_state.sway *= 0.92
		if _state.stance_ticks >= RECOVER_TICKS:
			_state.stance = "seated"
			_state.stance_ticks = 0
			_state.brake_required = false
	else:
		_state.balance = minf(_state.balance + 0.008, 1.0)
		_state.sway *= 0.92
	_advance_reload(observation)
	_advance_objective(observation)
	return ""

func _advance_reload(observation: Dictionary) -> void:
	if _state.reload_slot < 0:
		return
	_state.reload_paused = not observation.safe or observation.max_speed > RELOAD_SPEED + SPEED_EPSILON or stance() not in ["seated", "standing"]
	if _state.reload_paused:
		return
	_state.reload_ticks += 1
	if _state.reload_ticks >= RELOAD_TICKS:
		_state.reload_completions.append({"slot": _state.reload_slot, "tick": _state.tick})
		_state.slots[_state.reload_slot] = true
		_state.reload_slot = -1
		_state.reload_ticks = 0
		_state.reload_paused = false
		if _state.stage == "reload" and not false in _state.slots:
			_state.stage = "exit"
			_state.objective = "Sit back down and bring both horses to a stop."

func _advance_objective(observation: Dictionary) -> void:
	if _state.stage == "approach" and observation.safe and observation.min_speed >= 1.0:
		_state.stage = "stand"
		_state.objective = "Stand across the pair and hold balanced support briefly."
	if _state.stage == "stand":
		if stance() == "standing" and observation.safe:
			_state.standing_ticks = mini(_state.standing_ticks + 1, STAND_OBJECTIVE_TICKS)
		else:
			_state.standing_ticks = 0
		if _state.standing_ticks >= STAND_OBJECTIVE_TICKS:
			_state.stage = "volley"
			_state.objective = "While standing, discharge all four charged slots into the practice field."
	if _state.stage == "exit" and stance() == "seated" and observation.max_speed <= 0.15:
		_state.stage = "complete"
		_state.objective = "Horsecraft study complete. The proposed Maha Singh story remains unverified."

func select_slot(slot: Variant) -> String:
	if typeof(slot) != TYPE_INT or slot < 0 or slot >= 4:
		return "Choose one of the four numbered slots."
	if _state.reload_slot >= 0:
		return "Finish the active charge cycle before selecting another slot."
	_state.selected_slot = slot
	return ""

func fire(observation: Variant) -> Dictionary:
	var error := _metrics_error(observation)
	if error.is_empty() and not observation.safe:
		error = "The pair is outside supported firing formation."
	if error.is_empty() and stance() not in ["seated", "standing"]:
		error = "Finish the stance transition before firing."
	if error.is_empty() and _state.reload_slot >= 0:
		error = "A charge cycle is active."
	if error.is_empty() and not _state.slots[_state.selected_slot]:
		error = "The selected slot is empty."
	if error.is_empty() and _state.shots.size() >= MAX_SHOTS:
		error = "The bounded study shot budget is exhausted; restart the study."
	if not error.is_empty():
		return {"accepted": false, "reason": error, "slot": _state.selected_slot, "dispersion": 0.0, "shot_id": -1}
	var shot_id: int = _state.shots.size() + 1
	var dispersion: float = 0.01 + observation.mean_speed * 0.006 + absf(_state.sway) * 0.09 + (1.0 - _state.balance) * 0.04
	_state.slots[_state.selected_slot] = false
	_state.shots.append({"id": shot_id, "slot": _state.selected_slot, "tick": _state.tick, "stance": stance(), "dispersion": dispersion})
	if _state.stage == "volley" and stance() == "standing" and not _state.selected_slot in _state.volley_slots:
		_state.volley_slots.append(_state.selected_slot)
		_state.volley_count += 1
		if _state.volley_count >= 4:
			_state.stage = "reload"
			_state.objective = "Slow the pair and recharge all four separate matchlock slots."
	return {"accepted": true, "reason": "", "slot": _state.selected_slot, "dispersion": dispersion, "shot_id": shot_id}

func reload(observation: Variant) -> String:
	var error := _metrics_error(observation)
	if not error.is_empty():
		return error
	if _state.reload_slot >= 0:
		return "A charge cycle is already active."
	if _state.slots[_state.selected_slot]:
		return "The selected slot is already charged."
	if not observation.safe or observation.max_speed > RELOAD_SPEED + SPEED_EPSILON:
		return "Bring the aligned pair to a slower gait before charging."
	if stance() not in ["seated", "standing"]:
		return "Finish the stance transition before charging."
	_state.reload_slot = _state.selected_slot
	_state.reload_ticks = 0
	_state.reload_paused = false
	return ""

func record_hit(shot_id: Variant, target_id: Variant) -> String:
	if typeof(shot_id) != TYPE_INT or shot_id < 1 or shot_id > _state.shots.size():
		return "A hit must refer to an accepted shot identity."
	if typeof(target_id) != TYPE_STRING or target_id.is_empty() or target_id.length() > 64:
		return "A bounded practice target identity is required."
	for hit in _state.hits:
		if hit.shot_id == shot_id:
			return "This shot already has an acknowledged hit."
	# The scene must establish the target contact with its physics ray before calling.
	_state.hits.append({"shot_id": shot_id, "target_id": target_id})
	return ""
