# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only presentation of the existing childhood lessons and their thresholds.
const Childhood:=preload("res://childhood/childhood_state.gd")
const Riding:=preload("res://mounts/riding_rules.gd")
const Aftermath:=preload("res://childhood/aftermath_state.gd")
const Household:=preload("res://territory/misl_rules.gd")

static func household_uncommitted(model) -> bool:
	# Match the existing workshop's custody exclusions without reserving anything.
	if model.brawl_busy() or model.service_reserved(): return false
	if model.has_water_round():
		var water: Dictionary=model.water_round().ledger
		if water.carried>0 or water.phase=="drawing": return false
	var ledger: Dictionary=model.economy().ledger
	return ledger.caravan!="active" and ledger.delivery!="outbound"

static func read(chapter: Node3D) -> Dictionary:
	var model=chapter.model
	var state: Dictionary=model.progress()
	var stage: String=model.stage()
	if stage not in ["active","caught"] and chapter.has_method("camp_guidance"):
		var camp: Dictionary=chapter.camp_guidance()
		if not camp.is_empty(): return camp
	var result:={"title":"GUJRANWALA  /  LEARNING HOME","task":"","progress":"","controls":"","target":Vector3.ZERO,"marker":"","show_target":false}
	match stage:
		"orientation":
			result.task="Explore the courtyard"
			result.progress="Walk through the yard%s\nTurn your view left and right%s"%["  ·  done" if state.walked>=5.0 else "", "  ·  done" if state.looked>=0.6 else ""]
			result.controls="WASD  Walk     Mouse  Look     J / Esc  Journal and menu"
		"letter":
			result.controls="E  Speak / examine     WASD  Walk     Mouse  Look     J / Esc  Journal and menu"
			if not state.letter_seen:
				result.task="Take the sealed message"
				result.progress="Approach the courier on foot and press E."
				result.target=Childhood.SITES.courier;result.marker="Courier · E"
			elif "courier" not in state.heard:
				result.task="Hear the courier's account"
				result.progress="Speak to the courier again. He carried the message."
				result.target=Childhood.SITES.courier;result.marker="Courier · E"
			else:
				result.task="Take the message to the steward"
				result.progress="Hear what the steward says. An account is not its confirmation."
				result.target=Childhood.SITES.steward;result.marker="Steward · E"
			result.show_target=true
		"riding":
			result.title="GUJRANWALA  /  LEARNING TO RIDE"
			if model.mounted():
				result.task="Ride through gate %d of 3"%[int(state.ride_gate)+1]
				result.controls="W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped"
				result.target=Childhood.GATES[state.ride_gate];result.marker="Riding gate %d / 3"%[int(state.ride_gate)+1]
				if model.has_method("has_riding_skill") and model.has_riding_skill("single_standing"):
					result.controls+="     X  Sit / stand"
			else:
				result.task="Mount the household horse"
				result.controls="F  Mount     WASD  Walk     Mouse  Look     J / Esc  Journal and menu"
				result.target=Riding.position(model.horse_record());result.marker="Household horse · F"
			result.progress="%d / 3 gates reached. Ride between the poles in order."%state.ride_gate
			if state.ride_gate>0 and model.has_method("has_riding_skill") and not model.has_riding_skill("single_standing"):
				result.progress+="\nThe stable trainer now offers standing riding and mounted matchlock lessons. Stop, dismount, and speak to him with E."
			result.show_target=true
		"sparring":
			result.task="Stop and dismount for practice" if model.mounted() else "Practise with the trainer"
			result.progress="The riding course is complete. Stop on clear ground, then dismount with F." if model.mounted() else "Guard %d / 2 raised blows. After two guards, counter during his recovery."%state.parries
			result.controls="S / Space  Brake     F  Dismount when stopped" if model.mounted() else "Q  Hold guard while facing the trainer     Left click  Counter during recovery"
			result.target=Childhood.SITES.spar;result.marker="Practice trainer";result.show_target=true
		"tracking":
			result.task="Follow the trail" if state.tracks<3 else "Approach the quarry quietly"
			result.progress="%d / 3 traces examined. Face each nearby trace before pressing E."%state.tracks if state.tracks<3 else "You have followed the traces. Hold C as you approach, then observe with E."
			result.controls="E  Examine     C  Hold for quiet approach     WASD  Walk     Mouse  Look"
			result.target=Childhood.SITES["track_%d"%(int(state.tracks)+1)] if state.tracks<3 else Childhood.SITES.quarry
			result.marker="Trace %d / 3"%(int(state.tracks)+1) if state.tracks<3 else "Quarry";result.show_target=true
			if model.mounted():
				result.task="Stop and dismount to follow the trail" if state.tracks<3 else "Stop and dismount to observe the quarry"
				result.progress="Stop on clear ground, then continue on foot.\n"+result.progress
				result.controls="W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped"
		"ready":
			result.task="Return toward home"
			result.progress="Follow the marked bend. Keep looking and listening."
			result.controls="WASD  Walk     Mouse  Look     Q  Guard     Left click  Counter"
			result.target=Childhood.SITES.bend;result.marker="Return bend";result.show_target=true
			if model.mounted():
				result.task="Ride toward home"
				result.controls="W  Forward     A / D  Steer     Shift  Canter     S / Space  Brake     F  Dismount when stopped"
		"active":
			result.title="GUJRANWALA  /  RETURN HOME"
			result.task="Reach the courtyard alive"
			result.progress="Make distance, or face the attacker and defend yourself."
			result.controls="WASD  Move     Shift  Run     Q  Guard     Left click  Counter"
			result.target=Childhood.SITES.home;result.marker="Home";result.show_target=true
			if model.mounted():
				result.task="Ride back to the courtyard"
				result.progress="Make distance on horseback. Stop and dismount before guarding or countering."
				result.controls="W  Forward     A / D  Steer     Shift  Canter     S / Space  Brake     F  Dismount when stopped"
		"caught":
			result.task="This attempt has ended"
			result.progress="Restore your last checkpoint or load a manual save from the journal."
			result.controls="R  Restore checkpoint     F9  Load manual save     J / Esc  Journal and menu"
		"escaped":
			result.title="GUJRANWALA  /  BACK IN THE HOUSEHOLD"
			result.controls="E  Speak / examine     WASD  Walk     Mouse  Look     J / Esc  Journal and menu"
			var after: Dictionary=model.aftermath()
			match model.aftermath_phase():
				"accounts":
					result.task="Hear the accounts after your return"
					result.progress="Hear the steward and courier, then speak to Raj Kaur. Their accounts do not identify a culprit."
					if "return_steward" not in after.heard:
						result.target=Childhood.SITES.steward;result.marker="Steward · E"
					elif "return_courier" not in after.heard:
						result.target=Childhood.SITES.courier;result.marker="Courier · E"
					else:
						result.target=Aftermath.MOTHER;result.marker="Raj Kaur · E"
				"choice":
					result.task="Answer Raj Kaur's offer"
					result.progress="Speak to Raj Kaur about protection. Company has obligations; independence has costs."
					result.target=Aftermath.MOTHER;result.marker="Raj Kaur · E"
				"inspect":
					result.task="Examine the disturbed ground"
					result.progress="Revisit the bend on foot. Face the ground before pressing E."
					if after.escort.active: result.progress+=" Bring the household guard close enough to witness it."
					result.target=Aftermath.CLUE;result.marker="Disturbed ground · E"
				"return":
					result.task="Give Raj Kaur your account"
					result.progress="Return on foot and report what you observed. A trace is not a name."
					if after.escort.active: result.progress+=" Bring the household guard with you."
					result.target=Aftermath.MOTHER;result.marker="Raj Kaur · E"
				"complete":
					if not model.has_method("has_economy"): return {}
					result.title="GUJRANWALA  /  HOUSEHOLD RESPONSIBILITY"
					if model.has_economy():
						if not model.has_method("workshop_phase") or not household_uncommitted(model): return {}
						match model.workshop_phase():
							"unassigned":
								result.task="Ask about the smith's commission"
								result.progress="Ask the quartermaster about two tool bundles.\nThis optional errand uses 2 timber and 4 household coins. No order is placed until you choose it."
							"complete":
								result.task="First household responsibility complete"
								result.progress="Both tool bundles were returned. The commission is settled. Speak to the quartermaster to choose another responsibility."
							_: return {}
					else:
						result.task="Speak to the quartermaster"
						result.progress="You gave your observed account. The culprit remains unidentified.\nHear the quartermaster before accepting the household allowance."
					result.controls="E  Speak     WASD  Walk     Mouse  Look     B  Accounts     F5 / F9  Save / Load     J / Esc  Journal and menu"
					result.target=Household.QUARTERMASTER;result.marker="Quartermaster · E"
				_:
					# The established workshop HUD takes over after the inquiry.
					return {}
			if model.mounted():
				match model.aftermath_phase():
					"accounts": result.task="Stop and dismount to hear the household"
					"choice": result.task="Stop and dismount to answer Raj Kaur"
					"inspect": result.task="Stop and dismount to examine the ground"
					"return": result.task="Stop and dismount to give your account"
					"complete": result.task="Stop and dismount to hear the quartermaster"
				result.progress="Stop on clear ground, then continue on foot.\n"+result.progress
				result.controls="W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped"
				result.marker=result.marker.replace(" · E"," · dismount first")
			if after.escort.active:
				result.controls+="     G  Guard follow / hold within 10 m"
			result.show_target=true
		_:
			return {}
	return result
