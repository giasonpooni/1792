# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://mounts/horsecraft_study.gd"
## A riding lesson recalled as an attributed Maha Singh tale. Physics and weapon
## observations remain scene-owned; the retained host alone admits skill grants.
signal return_requested(completed: bool)

const Names := preload("res://characters/character_names.gd")
const LESSON_ID := "mahan-horsecraft-training.v1"
const HOLD_TICKS := 60

var lesson_phase := "single"
var lesson_tick := 0
var single_standing_ticks := 0
var paired_standing_ticks := 0
var max_single_hold_ticks := 0
var max_paired_hold_ticks := 0
var milestones: Array[Dictionary] = []
var _present_sha256 := ""
var _entry_tick := 0
var _returned := false
var practice_mode := ""
var _practice_capabilities: Dictionary = {}

func configure_binding(present_sha256: String, entry_tick: int) -> void:
	# The host binds its suspended present before adding this scene to the tree.
	if is_inside_tree(): return
	_present_sha256 = present_sha256
	_entry_tick = entry_tick

func configure_practice(formation: String, capabilities: Dictionary) -> void:
	if is_inside_tree() or formation not in ["single", "pair"]: return
	practice_mode = formation
	_practice_capabilities = capabilities.duplicate(true)

func _ready() -> void:
	release_mouse_on_exit=false
	super._ready()
	set_meta("classification", "learned-horsecraft-practice" if not practice_mode.is_empty() else "riding-training-flashback")
	set_meta("flashback_actor_id", "" if not practice_mode.is_empty() else "mahan_singh")
	set_meta("subject_id", Names.HERO_ID)
	set_meta("historical_authentication", false)
	_refresh()

func observation() -> Dictionary:
	if lesson_phase == "single": return model.single_metrics(record(left))
	return super.observation()

func _step_motion(delta: float, throttle: float, steering: float, canter: bool, walk: bool, brake: bool) -> Dictionary:
	if lesson_phase != "single": return super._step_motion(delta, throttle, steering, canter, walk, brake)
	var lead: Dictionary = left.step(delta, throttle, steering, canter, walk, brake)
	return {"left": lead, "right": {}, "support": model.single_metrics(lead)}

func riding_centers() -> Array[Vector3]:
	if lesson_phase == "single": return [left.global_position, left.global_position]
	return super.riding_centers()

func active_riding_horses() -> Array[CharacterBody3D]:
	if lesson_phase == "single": return [left]
	return super.active_riding_horses()

func rider_support_points() -> Array[Vector3]:
	if lesson_phase == "single":
		# Both feet are supported by the same saddle. The inactive horse contributes
		# neither a transform, a contact nor a fictitious record to this formation.
		return [left.saddle_support_point() - left.global_basis.x * .22,
			left.saddle_support_point() + left.global_basis.x * .22]
	return super.rider_support_points()

func restart_study() -> void:
	lesson_phase = "single" if practice_mode.is_empty() else practice_mode
	lesson_tick = 0
	single_standing_ticks = 0
	paired_standing_ticks = 0
	max_single_hold_ticks = 0
	max_paired_hold_ticks = 0
	milestones.clear()
	_returned = false
	super.restart_study()
	_set_pair_active(lesson_phase != "single")
	if practice_mode.is_empty():
		message = "At the riding lesson, %s recalls a tale of his father, Maha Singh. Ride forward, rise on one saddle, and hold your balance." % Names.PLAYER_NAME
	else:
		message = "%s practices the riding skills learned from his father's tale. These horses and matchlocks are borrowed for practice." % Names.PLAYER_NAME
	_present(); _refresh()

func _set_pair_active(active: bool) -> void:
	right.visible = active
	right.collision_layer = 1 if active else 0
	right.collision_mask = 1 if active else 0
	for shape in right.find_children("*", "CollisionShape3D", true, false):
		shape.set_deferred("disabled", not active)

func _physics_process(delta: float) -> void:
	if paused or _returned: return
	super._physics_process(delta)
	if not practice_mode.is_empty():
		if model.snapshot().stage == "complete":
			message = "The four practice weapons are recharged. Ride on, retry with Backspace, or return with Enter."
		_refresh(); return
	lesson_tick += 1
	var support: Dictionary = observation()
	var supported_standing: bool = model.stance() == "standing" and support.get("safe", false) and support.get("min_speed", 0.0) >= 1.0
	if lesson_phase == "single":
		single_standing_ticks = mini(single_standing_ticks + 1, HOLD_TICKS) if supported_standing else 0
		max_single_hold_ticks = maxi(max_single_hold_ticks, single_standing_ticks)
		if single_standing_ticks >= HOLD_TICKS and not _has_milestone("single_standing"):
			_stamp("single_standing")
			message = "You held your balance on one moving horse. Press Enter to practice across a pair."
	elif lesson_phase == "pair":
		paired_standing_ticks = mini(paired_standing_ticks + 1, HOLD_TICKS) if supported_standing else 0
		max_paired_hold_ticks = maxi(max_paired_hold_ticks, paired_standing_ticks)
		if paired_standing_ticks >= HOLD_TICKS and not _has_milestone("paired_standing"):
			_stamp("paired_standing")
			message = "The pair stays together under your feet. Press Enter for mounted matchlock practice."
	elif lesson_phase == "weapons" and model.snapshot().stage == "complete":
		var proof: Dictionary = _weapon_facts()
		if proof.volley_slots == [0, 1, 2, 3] and proof.reloaded_slots.size() == 4:
			lesson_phase = "complete"
			_stamp("mounted_matchlock")
			message = "Lesson complete. Press Enter to return to %s's riding lesson with these three skills." % Names.PLAYER_NAME
	if lesson_phase == "complete":
		message = "Lesson complete. Sit and stop both horses, then press Enter to return to %s's riding lesson." % Names.PLAYER_NAME
	_refresh()

func _has_milestone(id: String) -> bool:
	for item in milestones:
		if item.id == id: return true
	return false

func _stamp(id: String) -> void:
	milestones.append({"id": id, "tick": lesson_tick})

func advance_lesson() -> void:
	if paused or _returned: return
	if not practice_mode.is_empty():
		_returned = true; set_paused(true); return_requested.emit(false); return
	if lesson_phase == "single" and _has_milestone("single_standing"):
		lesson_phase = "pair"
		# A new authored formation checkpoint resets practice bodies and reducer;
		# the lesson clock and earned evidence remain monotonic across chapters.
		super.restart_study()
		_set_pair_active(true)
		message = "Ride the two horses together. Rise across both saddles and hold balanced support while moving."
		_present(); _refresh()
	elif lesson_phase == "pair" and _has_milestone("paired_standing"):
		lesson_phase = "weapons"
		message = "Use each of the four separate matchlocks while standing. Slow the pair to reload each empty weapon, then sit and stop."
		_refresh()
	elif lesson_phase == "complete":
		if not _completion_ready():
			message = "Sit down and stop both horses before returning from the lesson."
			_refresh(); return
		_returned = true
		set_paused(true)
		return_requested.emit(true)
	else:
		message = "Finish this part of the lesson before continuing."
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			advance_lesson(); get_viewport().set_input_as_handled(); return
		if event.keycode == KEY_F1:
			if not _returned:
				_returned = true; set_paused(true); return_requested.emit(false)
			get_viewport().set_input_as_handled(); return
	super._unhandled_input(event)

func fire() -> Dictionary:
	if not practice_mode.is_empty():
		if not _has_practice_capability("mounted_matchlock"):
			message = "Mounted matchlock firing has not been learned."
			_refresh(); return {"accepted": false, "reason": message}
		return super.fire()
	if lesson_phase != "weapons":
		message = "Mounted firing follows the two balance exercises."
		_refresh()
		return {"accepted": false, "reason": message}
	return super.fire()

func reload() -> void:
	if not practice_mode.is_empty():
		if not _has_practice_capability("mounted_matchlock"):
			message = "Mounted matchlock firing has not been learned."
			_refresh(); return
		super.reload(); return
	if lesson_phase != "weapons":
		message = "The matchlock charge exercise follows the two balance exercises."
		_refresh(); return
	super.reload()

func toggle_stance() -> void:
	if not practice_mode.is_empty() and model.stance() == "seated":
		var ability := "single_standing" if practice_mode == "single" else "paired_standing"
		if not _has_practice_capability(ability):
			message = "This standing riding skill has not been learned."
			_refresh(); return
	super.toggle_stance()

func _has_practice_capability(id: String) -> bool:
	return typeof(_practice_capabilities.get(id)) == TYPE_BOOL and _practice_capabilities[id]

func _weapon_facts() -> Dictionary:
	var snapshot: Dictionary = model.snapshot()
	var volleys: Array = snapshot.volley_slots.duplicate()
	volleys.sort()
	var reloads: Array[int] = []
	for item in snapshot.reload_completions:
		if not item.slot in reloads: reloads.append(item.slot)
	return {"volley_slots": volleys, "reloaded_slots": reloads}

func training_proof() -> Dictionary:
	if not practice_mode.is_empty(): return {}
	if lesson_phase != "complete" or not _has_milestone("mounted_matchlock"): return {}
	var facts: Dictionary = _weapon_facts()
	facts.single_hold_ticks = max_single_hold_ticks
	facts.paired_hold_ticks = max_paired_hold_ticks
	return {"lesson_id": LESSON_ID, "subject_id": "ranjit_singh", "flashback_actor_id": "mahan_singh",
		"entry_tick": _entry_tick, "completed_tick": milestones[-1].tick,
		"milestones": milestones.duplicate(true), "facts": facts,
		"historical_status": "user-attributed-unverified"}

func completion_receipt() -> Dictionary:
	if not practice_mode.is_empty(): return {}
	if not _completion_ready(): return {}
	var proof: Dictionary = training_proof()
	if proof.is_empty(): return {}
	var receipt: Dictionary = proof.duplicate(true)
	receipt.schema = "1792.riding-training-receipt.v1"
	receipt.present_sha256 = _present_sha256
	receipt.completion_sha256 = JSON.stringify(proof, "", true, true).sha256_text()
	return receipt

func _completion_ready() -> bool:
	var support: Dictionary = observation()
	return lesson_phase == "complete" and model.snapshot().stage == "complete" and model.stance() == "seated" \
		and support.get("safe", false) and support.get("max_speed", 20.0) <= .15

func _refresh() -> void:
	if not is_instance_valid(hud) or not is_instance_valid(left): return
	var snapshot: Dictionary = model.snapshot()
	var support: Dictionary = observation()
	if not practice_mode.is_empty():
		var slots: Array[String] = []
		for i in range(4): slots.append("%s%d %s" % ["•" if i == snapshot.selected_slot else "", i + 1, "charged" if snapshot.slots[i] else "empty"])
		hud.text = "1792 · %s'S HORSECRAFT PRACTICE · %s\nW forward · A/D reins · S brake · Ctrl walk · Shift canter · Q/E balance · Space sit/stand\nMouse aim · Left click fire · 1–4 select · R reload · Enter return · Backspace retry · Esc pause · F1 return" % [Names.PLAYER_NAME.to_upper(), "ONE HORSE" if practice_mode == "single" else "TWO HORSES"]
		status.text = ("PAUSED · " if paused else "") + "%s · %.1f m/s · balance %d%% · %s\nPractice with borrowed horses and four separate matchlocks.\n%s" % [
			model.stance().to_upper(), support.get("mean_speed", 0.0), int(snapshot.balance * 100), " / ".join(slots), message]
		return
	var duration := float(HOLD_TICKS) / State.TICK_HZ
	var movement := "W forward · A/D reins · S brake · Q/E balance · Space sit/stand"
	var session_controls := "Ctrl walk · Backspace restart lesson · Esc pause · F1 leave"
	var title := "1 / 3 · ONE MOVING HORSE · STANDING BALANCE"
	var progress := "Moving standing hold: %.1f / %.1f s" % [float(single_standing_ticks) / State.TICK_HZ, duration]
	var detail := ""
	if lesson_phase == "single" and _has_milestone("single_standing"):
		progress = "Standing hold earned: %.1f / %.1f s" % [float(max_single_hold_ticks) / State.TICK_HZ, duration]
		session_controls = "Enter next exercise · " + session_controls
	if lesson_phase == "pair":
		title = "2 / 3 · TWO MOVING HORSES · STANDING BALANCE"
		progress = "Moving standing hold: %.1f / %.1f s" % [float(paired_standing_ticks) / State.TICK_HZ, duration]
		if _has_milestone("paired_standing"):
			progress = "Standing hold earned: %.1f / %.1f s" % [float(max_paired_hold_ticks) / State.TICK_HZ, duration]
			session_controls = "Enter mounted matchlocks · " + session_controls
	elif lesson_phase == "weapons":
		title = "3 / 3 · MOUNTED MATCHLOCKS · FIRE STANDING, RELOAD SLOWLY"
		var facts: Dictionary = _weapon_facts()
		progress = "Standing shots: %d / 4 · Weapons reloaded: %d / 4" % [facts.volley_slots.size(), facts.reloaded_slots.size()]
		var slots: Array[String] = []
		for i in range(4): slots.append("%s%d %s" % ["•" if i == snapshot.selected_slot else "", i + 1, "charged" if snapshot.slots[i] else "empty"])
		detail = " / ".join(slots)
		if snapshot.reload_slot >= 0:
			detail += " · Reload %d: %.1f / %.1f s%s" % [snapshot.reload_slot + 1, float(snapshot.reload_ticks) / State.TICK_HZ,
				float(State.RELOAD_TICKS) / State.TICK_HZ, " · paused: keep slow, aligned and steady" if snapshot.reload_paused else ""]
		movement += "\nMouse aim · Left click fire · 1–4 select · R reload"
	elif lesson_phase == "complete":
		title = "RIDING LESSON COMPLETE"
		progress = "Three skills earned · " + ("ready to return" if _completion_ready() else "sit and stop both horses")
		movement = "Enter return to the riding lesson" if _completion_ready() else "S brake · Space sit"
		session_controls = "Backspace restart lesson · Esc pause · F1 leave"
	hud.text = "1792 · %s'S RIDING LESSON · A TALE OF MAHA SINGH\n%s · %s\n%s\n%s" % [Names.PLAYER_NAME.to_upper(), title, progress, movement, session_controls]
	status.text = ("PAUSED · " if paused else "") + "%s · %.1f m/s · balance %d%%\n" % [
		model.stance().to_upper(), support.get("mean_speed", 0.0), int(snapshot.balance * 100)]
	if not detail.is_empty(): status.text += detail + "\n"
	status.text += message
