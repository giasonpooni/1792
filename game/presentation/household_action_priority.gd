# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Only orders existing dialog buttons. No new offer, receipt or game authority.
const Guidance := preload("res://presentation/household_guidance.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Delivery := preload("res://territory/delivery_presentation.gd")
const BazaarStory := preload("res://youth/performance/bazaar_story.gd")
const Commission := preload("res://commissions/commission_rules.gd")

static func preferred(chapter: Node3D, speaker: String) -> String:
	var model = chapter.model
	if model.has_method("brawl_busy") and model.brawl_busy():
		return "youth:report" if speaker == "home" and model.brawl_phase() == "returning" else "resume"
	if model.has_method("remount_busy") and model.remount_busy():
		var remount: Dictionary=model.remounts().ledger
		if speaker=="home" and remount.note and remount.horses: return "remount:resolve"
		if speaker=="market" and not remount.introduced: return "remount:introduction"
		return "resume"
	if model.has_method("commission_busy") and model.commission_busy():
		var contract: Dictionary=model.commission()
		if speaker=="market" and contract.phase=="reserved": return "commission:broker"
		if speaker=="home" and contract.phase=="escorting" and Commission.near(model.position(),Commission.HOME,4) and Commission.near(Base.point(model.specialist().position),Commission.HOME,4):
			return "commission:appoint"
		return "resume"
	if model.has_method("commission_drilling") and model.commission_drilling():
		return "commission:pay_arrears" if speaker=="home" and model.commission().arrears>0 else "resume"
	if not model.has_economy():
		if speaker == "home": return "econ:begin"
		return "youth:invite" if not model.has_brawl() else "resume"
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
		"commission:broker": return "Agent · I can introduce you. I cannot promise what he will agree to. Hear his terms yourself."
		"commission:appoint": return "Quartermaster · Both of you are here. Enter his name, and keep a place ready for the days he stays."
		"commission:pay_arrears": return "Quartermaster · His work has earned these wages. Settle them before asking for the next movement."
		"remount:resolve": return "Quartermaster · Two horses seen, and the tally brought back. Tell me where you found them."
		"remount:introduction": return "Handler · You can ask at the southern yard. Take my introduction to its gatekeeper."
		"youth:invite": return BazaarStory.INVITATION
		"water:deposit":
			return "Quartermaster · The second load. Set it beside the first; that will finish the round." if model.water_round().ledger.stored > 0 else "Quartermaster · Set the full vessel here. One load to count in, and one still to bring."
		"smith:deliver": return "Quartermaster · Both tool bundles? Lay them here. We will count them into the household stock."
		"service:debrief": return "Quartermaster · The guard has returned. Hear what he saw before giving another order."
		"youth:report": return "Quartermaster · An account from all three of you. Bring both friends close enough to be heard."
		"econ:begin", "econ:accept_delivery", "econ:deliver", "econ:checkin", "econ:accept_escort": return Delivery.briefing(model, speaker == "market")
		"resume":
			if model.has_method("commission_busy") and model.commission_busy():
				return "Quartermaster · Bring the instructor back with you before we enter his name." if speaker=="home" else "Agent · Hear the candidate's terms and accompany him home."
			if model.has_method("commission_drilling") and model.commission_drilling(): return "The practice is waiting. Return to the teaching place to continue."
			if model.has_method("remount_busy") and model.remount_busy():
				return "Quartermaster · Find the horses and bring back their tally. We can settle the other orders afterward." if speaker=="home" else "Handler · You have my introduction. Take it to the gatekeeper; the other business can wait."
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
