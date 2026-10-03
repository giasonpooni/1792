# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dialogue for an attributed tale and a read-only view of the lesson.
## No historic quotation, ability grant, clock, input or horse authority.
static func line(beat: String) -> String:
	match beat:
		"single": return "Maha, in the tale: Feel the horse's step, Buddh. Rise with it."
		"single_earned": return "Maha, in the tale: There. You listened to the horse before asking more of it."
		"pair": return "Maha, in the tale: Two horses now. Neither can be forgotten."
		"pair_earned": return "Maha, in the tale: You kept both beneath you. Now keep your attention when the smoke comes."
		"weapons": return "Maha, in the tale: Four matchlocks. Fire standing, charge them slowly, then bring us home."
		"complete": return "Maha, in the tale: Good. A feat ends when horse and rider are safely home."
	return ""

static func return_line(completed: bool, practice: String) -> String:
	if completed: return "Trainer: You brought the horses home, Buddh. Standing riding, paired standing and mounted matchlocks learned."
	if not practice.is_empty(): return "Trainer: Enough for today, Buddh. Your learned riding skills are retained."
	return "Trainer: Leave it there, Buddh. We can begin again. No new riding skills learned."

static func read(phase: String, snapshot: Dictionary, support: Dictionary, earned: bool) -> Dictionary:
	var result := {"task": "", "controls": "W forward · A/D reins · S brake · Space sit/stand", "urgent": false}
	if snapshot.get("brake_required", false) or snapshot.stance == "recovering":
		result.task = "Settle into the saddle and let the horses stop."
		result.controls = "S brake · wait for seated recovery"
		result.urgent = true
		return result
	if not support.get("safe", false):
		result.task = "Steady the horse before rising." if phase == "single" else "Bring both horses together before continuing."
		result.controls = "S brake · A/D reins · stay seated"
		result.urgent = true
		return result
	if phase == "complete":
		result.task = "Return to the trainer with all three skills." if snapshot.stance == "seated" and support.get("max_speed", 20.0) <= .15 else "Sit and stop both horses before returning."
		result.controls = "Enter return to the riding lesson" if snapshot.stance == "seated" and support.get("max_speed", 20.0) <= .15 else "S brake · Space sit"
	elif phase in ["single", "pair"]:
		if earned:
			result.task = "Hold earned. Continue when you are ready."
			result.controls = ("Enter next exercise" if phase == "single" else "Enter mounted matchlocks") + " · S brake · Space sit"
		elif snapshot.stance == "rising":
			result.task = "Keep a steady line as you rise."
			result.controls = "W forward · A/D reins · Q/E balance · S brake"
		elif snapshot.stance == "standing":
			result.task = "Keep moving and hold your balance for one second."
			result.controls = "W forward · A/D reins · Q/E balance · Space sit · S brake"
		else:
			result.task = "Ride forward, then rise onto the saddle." if phase == "single" else "Ride the pair forward, then rise across both saddles."
	elif phase == "weapons":
		result.controls = "Mouse aim · Left click fire · 1–4 select · R reload"
		if snapshot.reload_slot >= 0:
			result.task = "Slow and steady: finish recharging matchlock %d." % [snapshot.reload_slot + 1]
			if snapshot.reload_paused:
				result.task = "Reload waiting. Slow the horses and steady your support."
				result.urgent = true
			result.controls = "S brake · A/D reins · wait for the charge"
		elif snapshot.volley_slots.size() == 4 and not false in snapshot.slots:
			result.task = "Four charged again. Sit and bring both horses to a stop."
			result.controls = "S brake · Space sit"
		elif snapshot.volley_slots.size() == 4:
			result.task = "All four fired standing. Slow down and reload each empty matchlock."
			result.controls = "S brake · 1–4 select empty matchlock · R reload"
		elif not snapshot.slots[snapshot.selected_slot]:
			result.task = "Matchlock %d is empty. Select a charged one, or slow down to reload." % [snapshot.selected_slot + 1]
		elif snapshot.stance != "standing":
			result.task = "Rise before firing: seated shots do not earn the standing exercise."
			result.controls = "Space stand · " + result.controls
		else:
			result.task = "Fire each of the four matchlocks while standing."
	return result
