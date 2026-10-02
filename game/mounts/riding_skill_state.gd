# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://workshops/workshop_state.gd"
## Additive training receipts on the existing Home authority and save identity.
## Execution/session owners establish the lesson facts; hashes bind consistency,
## not historical authenticity or an anti-cheat proof. No second clock runs here.

const SKILL_SCHEMA := "riding-skills.v1"
const RECEIPT_SCHEMA := "1792.riding-training-receipt.v1"
const LESSON_ID := "mahan-horsecraft-training.v1"
const SKILL_IDS := ["single_standing", "paired_standing", "mounted_matchlock"]
const TRAINING_SITE := Vector3(6.0, 0.14, -4.0)
const MAX_TRAINING_TICKS := 10000000
const ATTRIBUTION := "user-attributed-unverified"

func _init() -> void:
	super._init()
	_state.riding_skills = _skills_initial()

static func _skills_initial() -> Dictionary:
	return {"schema_version": SKILL_SCHEMA, "lesson_receipts": []}

func capabilities() -> Dictionary:
	var learned: bool = not _state.riding_skills.lesson_receipts.is_empty()
	return {"single_standing": learned, "paired_standing": learned, "mounted_matchlock": learned}

func has_riding_skill(id: String) -> bool:
	return bool(capabilities().get(id, false))

func training_access() -> String:
	if _state.childhood.ride_gate < 1 or stage() in ["orientation", "letter", "active", "caught"]:
		return "Ride through the first practice gate before the remembered riding lesson."
	if mounted():
		return "Stop and dismount beside the training ground first."
	if position().distance_to(TRAINING_SITE) > 3.0 or absf(position().y - TRAINING_SITE.y) > 0.35:
		return "Approach the nearby training ground on foot."
	return ""

static func _whole(value: Variant, minimum: int = 0, maximum: int = MAX_TRAINING_TICKS) -> bool:
	return Riding.finite_number(value) and float(value) == floor(float(value)) \
		and float(value) >= minimum and float(value) <= maximum

static func _sha256(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.length() != 64:
		return false
	for character in value:
		if character not in "0123456789abcdef":
			return false
	return true

func present_sha256() -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(JSON.stringify(snapshot(), "", true, true).to_utf8_buffer())
	return hash.finish().hex_encode()

func _receipt_error(value: Variant, home_tick: int) -> String:
	var template := {"schema": "", "lesson_id": "", "subject_id": "", "flashback_actor_id": "",
		"present_sha256": "", "completion_sha256": "", "entry_tick": 0, "completed_tick": 0,
		"milestones": [], "historical_status": "", "facts": {"single_hold_ticks": 0,
			"paired_hold_ticks": 0, "volley_slots": [], "reloaded_slots": []}}
	if not _shape(value, template):
		return "Malformed riding-training receipt."
	if value.schema != RECEIPT_SCHEMA or value.lesson_id != LESSON_ID \
		or value.subject_id != Names.HERO_ID or value.flashback_actor_id != "mahan_singh" \
		or value.historical_status != ATTRIBUTION:
		return "Unsupported lesson, subject, flashback actor or attribution."
	if not _sha256(value.present_sha256) or not _sha256(value.completion_sha256):
		return "Training receipt requires bounded SHA-256 consistency bindings."
	if not _whole(value.entry_tick) or value.entry_tick > home_tick or not _whole(value.completed_tick):
		return "Invalid home entry or lesson completion tick."
	if value.milestones.size() != SKILL_IDS.size():
		return "The complete three-skill lesson is required."
	var previous := 0
	for index in range(SKILL_IDS.size()):
		var milestone: Variant = value.milestones[index]
		if not _shape(milestone, {"id": "", "tick": 0}) or milestone.id != SKILL_IDS[index] \
			or not _whole(milestone.tick) or milestone.tick < previous or milestone.tick > value.completed_tick:
			return "Unknown, reordered, nonfinite or future training milestone."
		previous = int(milestone.tick)
	if not _whole(value.facts.single_hold_ticks, 60) or not _whole(value.facts.paired_hold_ticks, 60):
		return "Both supported standing holds must be completed."
	if value.milestones[0].tick < value.facts.single_hold_ticks \
		or value.milestones[1].tick - value.milestones[0].tick < value.facts.paired_hold_ticks:
		return "Training milestones cannot precede their supported hold work."
	if value.facts.volley_slots.size() != 4 or value.facts.reloaded_slots.size() != 4:
		return "Four distinct discharge and recharge slots are required."
	var seen: Array = []
	for index in range(4):
		if not _whole(value.facts.volley_slots[index], 0, 3) or value.facts.volley_slots[index] != index:
			return "The discharged slot set must identify all four weapons."
		var slot: Variant = value.facts.reloaded_slots[index]
		if not _whole(slot, 0, 3) or int(slot) in seen:
			return "Recharge receipts must name four separate weapons."
		seen.append(int(slot))
	if value.completion_sha256 != proof_sha256(value):
		return "Training proof changed without its consistency binding."
	return ""

static func proof_sha256(receipt: Dictionary) -> String:
	# Called after structural checks, or by the trusted lesson/session exporter.
	# JSON's integral floats normalize to the same proof identity after restore.
	var proof := receipt.duplicate(true)
	for field in ["schema", "present_sha256", "completion_sha256"]:
		proof.erase(field)
	_normalize_receipt(proof)
	return JSON.stringify(proof, "", true, true).sha256_text()

static func _normalize_receipt(receipt: Dictionary) -> void:
	for field in ["entry_tick", "completed_tick"]:
		receipt[field] = int(receipt[field])
	for milestone in receipt.milestones:
		milestone.tick = int(milestone.tick)
	for field in ["single_hold_ticks", "paired_hold_ticks"]:
		receipt.facts[field] = int(receipt.facts[field])
	for field in ["volley_slots", "reloaded_slots"]:
		for index in range(4):
			receipt.facts[field][index] = int(receipt.facts[field][index])

func accept_riding_training(receipt: Dictionary, expected_present_sha256: String) -> String:
	var error := _receipt_error(receipt, int(_state.childhood.tick))
	if not error.is_empty():
		return error
	if not _sha256(expected_present_sha256) or receipt.present_sha256 != expected_present_sha256:
		return "Training receipt does not bind the suspended present."
	var canonical := receipt.duplicate(true)
	_normalize_receipt(canonical)
	if not _state.riding_skills.lesson_receipts.is_empty():
		return "" if _state.riding_skills.lesson_receipts[0] == canonical else "This lesson already has a different admitted receipt."
	error = training_access()
	if not error.is_empty():
		return error
	if receipt.entry_tick != _state.childhood.tick or expected_present_sha256 != present_sha256():
		return "The Home present changed while the riding lesson was suspended."
	var candidate := snapshot()
	candidate.riding_skills.lesson_receipts.append(canonical)
	error = validate(candidate)
	if not error.is_empty():
		return error
	_state = candidate
	return ""

func validate(value: Variant) -> String:
	if not value is Dictionary:
		return "Malformed Home snapshot."
	var parent: Dictionary = value.duplicate(true)
	parent.erase("riding_skills")
	var error := super.validate(parent)
	if not error.is_empty():
		return error
	if not value.has("riding_skills"):
		return "" # Explicit old-save migration; never infer learned capabilities.
	var skills: Variant = value.riding_skills
	if not _shape(skills, _skills_initial()) or skills.schema_version != SKILL_SCHEMA \
		or skills.lesson_receipts.size() > 1:
		return "Malformed or duplicate riding-skills extension."
	if skills.lesson_receipts.is_empty():
		return ""
	if value.childhood.ride_gate < 1:
		return "Riding skills precede the first observed lesson gate."
	return _receipt_error(skills.lesson_receipts[0], int(value.childhood.tick))

func restore(value: Variant) -> String:
	var error := super.restore(value)
	if not error.is_empty():
		return error
	if not _state.has("riding_skills"):
		_state.riding_skills = _skills_initial()
	for receipt in _state.riding_skills.lesson_receipts:
		_normalize_receipt(receipt)
	return ""
