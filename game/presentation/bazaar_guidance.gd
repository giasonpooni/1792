# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only current responsibility for the existing outing. Recovery points to
## the same physical friends; guidance neither moves them nor resolves the fight.
const Brawl := preload("res://youth/brawl_rules.gd")
const Supply := preload("res://territory/misl_rules.gd")

static func read(chapter: Node3D, moving: bool = false) -> Dictionary:
	var phase: String = chapter.model.brawl_phase()
	if phase not in ["invited", "challenged", "fighting", "leaving", "returning"]: return {}
	var result := {"task":"", "detail":"", "controls":"WASD  Walk    E  Speak    J  Journal", "show_detail":not moving, "show_title":not moving, "recover_index":-1}
	match phase:
		"invited":
			result.task = "Walk with Mela and Jiva to the bazaar"
			result.detail = "Take the southeast lane together. Face the challenger to hear him."
		"challenged":
			result.task = "Answer the challenge with both friends"
			result.detail = "Hear Mela and Jiva, stand your ground, or walk away together."
		"fighting":
			result.task = "Guard and counter, or withdraw together"
			result.detail = "The open household approach is northeast of the bazaar. Bring both friends there to regroup."
			result.controls = "WASD  Move    Q  Face and guard    Left click  Counter"
		"leaving":
			result.task = "Bring both friends to the open approach"
			result.detail = "Walk northeast toward the household. All three of you must reach the regroup point."
		"returning":
			result.task = "Give the account with both friends"
			result.detail = "Return to the quartermaster. You can stop beside Mela or Jiva to talk on the way."
	# During combat, the actual strike tell remains the immediate concern. In a
	# safe travel phase, a named recovery is clearer than another destination.
	if phase != "fighting":
		var threshold := 7.0
		var at_destination := false
		if phase == "invited" or phase == "challenged":
			at_destination = chapter.model.position().distance_to(chapter.youths[0].global_position) <= 3.2
			if at_destination: threshold = 5.0
		elif phase == "leaving":
			at_destination = chapter.model.position().distance_to(Brawl.REGROUP) <= 3.2
			if at_destination: threshold = 4.5
		elif phase == "returning":
			at_destination = chapter.model.position().distance_to(Supply.QUARTERMASTER) <= 3.0
			if at_destination: threshold = 5.0
		var farthest := threshold
		for index in [3,4]:
			var actor: Node3D = chapter.youths[index]
			var distance: float = chapter.model.position().distance_to(actor.global_position)
			if not chapter._contact(actor) or distance > farthest:
				result.recover_index = index
				farthest = maxf(farthest, distance)
		if result.recover_index >= 0:
			var name: String = "Mela" if result.recover_index == 3 else "Jiva"
			var contact: bool = chapter._contact(chapter.youths[result.recover_index])
			result.task = "Wait for %s before continuing" % name if at_destination and contact else "Go back for %s" % name
			result.detail = "He is still coming. Let him close the gap before you speak." if at_destination and contact else "Return along the lane and regain clear contact. The same friend must walk back with you."
	return result
