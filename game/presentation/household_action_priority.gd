# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Only orders existing dialog buttons. No new offer, receipt or game authority.
const Guidance := preload("res://presentation/household_guidance.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Delivery := preload("res://territory/delivery_presentation.gd")

static func preferred(chapter: Node3D, speaker: String) -> String:
	var model = chapter.model
	if model.has_method("brawl_busy") and model.brawl_busy():
		return "youth:report" if speaker == "home" and model.brawl_phase() == "returning" else "resume"
	if not model.has_economy(): return "econ:begin" if speaker == "home" else "resume"
	var foreground: Dictionary = Guidance.read(chapter)
	match str(foreground.get("kind", "")):
		"caravan":
			var carrier := Base.point(model.economy().merchant.position)
			return "econ:checkin" if speaker == "home" and Base.distance(carrier, Supply.QUARTERMASTER) <= 4.5 else "resume"
		"delivery": return "econ:deliver" if speaker == "market" else "resume"
		"water": return "water:deposit" if speaker == "home" and model.water_round().ledger.phase == "carrying" else "resume"
		"service": return "service:debrief" if speaker == "home" and model.service().ledger.stage == "awaiting_account" else "resume"
	if model.has_method("workshop_phase"):
		match model.workshop_phase():
			"tools": return "smith:deliver" if speaker == "home" else "resume"
			"fuel", "working", "ready": return "resume"
	var ledger: Dictionary = model.economy().ledger
	if speaker == "home" and ledger.delivery == "available": return "econ:accept_delivery"
	if speaker == "market" and ledger.caravan == "available": return "econ:accept_escort"
	return ""

static func briefing(chapter: Node3D, speaker: String, action: String) -> String:
	var model = chapter.model
	match action:
		"water:deposit":
			return "Quartermaster · The second load. Set it beside the first; that will finish the round." if model.water_round().ledger.stored > 0 else "Quartermaster · Set the full vessel here. One load to count in, and one still to bring."
		"smith:deliver": return "Quartermaster · Both tool bundles? Lay them here. We will count them into the household stock."
		"service:debrief": return "Quartermaster · The guard has returned. Hear what he saw before giving another order."
		"youth:report": return "Quartermaster · An account from all three of you. Bring both friends close enough to be heard."
		"econ:begin", "econ:accept_delivery", "econ:deliver", "econ:checkin", "econ:accept_escort": return Delivery.briefing(model, speaker == "market")
		"resume":
			if model.has_method("brawl_busy") and model.brawl_busy(): return "Finish the outing with your friends before taking on household orders."
			var task: Dictionary = Guidance.read(chapter)
			if not task.is_empty(): return "The account can wait.\n\n" + str(task.progress)
			if model.has_method("workshop_phase") and model.workshop_phase() in ["fuel", "working", "ready", "tools"]:
				return "Quartermaster · Finish the smith's commission when you are ready. The other orders can wait."
	return ""

static func action_id(button: Button) -> String:
	# All inherited speaker menus bind their existing action ID to pressed.
	# Reading the binding avoids a second, possibly divergent label dictionary.
	for connection in button.get_signal_connection_list("pressed"):
		var args: Array = connection.callable.get_bound_arguments()
		if args.size() == 1 and args[0] is String: return str(args[0])
	return ""

static func promote(chapter: Node3D, speaker: String) -> Button:
	var action := preferred(chapter, speaker)
	if action.is_empty(): return null
	for child in chapter._actions.get_children():
		if child is Button and action_id(child) == action:
			chapter._actions.move_child(child, 0)
			return child
	return null
