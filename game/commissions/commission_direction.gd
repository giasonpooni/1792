# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original scene words and read-only foregrounding. No historical quotation,
## rewards, ledger mutations, camera control or remotely received testimony.
const R := preload("res://commissions/commission_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
const RESERVATION := "Quartermaster · A purse is a promise, Buddh. Keep something for the days after he arrives.\n\nChoose an offer only when the household has the uncommitted funds. The agent, journey and signing are paid separately from the wage reserve."
const INTRODUCTION := "Agent · I can introduce you. I cannot promise what he will agree to.\n\nMeet the candidate at the receiving place north of this market."
const CANDIDATE := "Instructor · Keep a place ready for the pupil. A hungry boy watches the meal, not the hand.\nBuddh · We have a yard.\nInstructor · A yard is a beginning. Walk back with me; let us see what your household can spare.\n\nTravel is paid when you accept. Signing and the wage reserve remain separate."
const SIGNING := "Quartermaster · You brought him here. Enter his name, then keep the promise for the days he stays.\nInstructor · Keep a place ready, boy. Then we can begin."
const AFTER := "Buddh · I thought paying you was enough.\nInstructor · It brought me here. Keeping the place is another part.\nBuddh · And after one practice?\nInstructor · Tomorrow asks again.\n\nBuddh looks back at the practice place beside the instructor."

static func line(kind: String) -> String:
	return {
		"reserve":"Quartermaster · Keep something for the days after he arrives. Carry the reserved purse to the market agent.",
		"broker":"Agent · He is waiting north of the market. Hear his terms yourself.",
		"engage":"Instructor · Walk with me, Buddh. Keep a place ready when we arrive.",
		"appoint":"Quartermaster · His name is entered. Keep the promise for the days he stays.",
		"cancel":"Quartermaster · The unspent balance is back. Work already paid remains paid.",
		"lesson_start":"Instructor · Set your feet. First we see whether you can wait for the next movement.",
		"separated":"Instructor · Bring us together, boy. A lesson cannot cross the yard on its own.",
		"rejoined":"Instructor · There. We have a place again. Stay with me.",
		"drill_paused":"Instructor · Keep a place ready for the pupil. We will wait.",
		"drill_resumed":"Instructor · There. We have a place again. From the last movement.",
		"lesson_complete":"Instructor · That is one practice, boy. Tomorrow asks again.",
		"control_instructor":"The instructor takes his own view. Buddh remains where he stood.",
		"control_buddh":"Buddh returns to his own view. The instructor remains beside the practice place.",
		"release_reserve":"Quartermaster · The reserve is released. The next wages still come due.",
		"pay_arrears":"Quartermaster · The accrued wages are settled.",
		"dismiss":"Instructor · Then my service ends here. What I have already earned remains due."
	}.get(kind, "")

static func read(chapter: Node3D, moving: bool=false) -> Dictionary:
	var model=chapter.model
	if not is_instance_valid(chapter.specialist_body): return {}
	if not model.commissioned() or model.brawl_busy() or model.remount_busy(): return {}
	var c: Dictionary=model.commission()
	if c.phase in ["cancelled","dismissed"]: return {}
	# A settled appointment may coexist with a later household responsibility.
	if c.phase=="appointed" and not model.controlling_specialist() and c.lesson!="active": return {}
	var actor: Vector3=chapter.specialist_body.global_position
	var result:={"title":"GUJRANWALA  /  KEEP A PLACE", "task":"", "progress":"", "controls":"E  Speak     WASD  Walk     Mouse  Look     J  Journal", "target":R.HOME,"marker":"Quartermaster · E","show_target":true,"attention_mode":"moving" if moving else "rest","show_progress":not moving}
	if model.controlling_specialist(): result.title="INSTRUCTOR  /  KEEP A PLACE"
	match c.phase:
		"reserved":
			result.task="Carry the reserved purse to the agent";result.progress="The money is committed. Meet the hiring agent in the western market."
			result.target=R.BROKER;result.marker="Hiring agent · E"
		"introduced":
			result.task="Hear the candidate's terms";result.progress="He waits at the receiving place north of the market."
			result.target=actor;result.marker="Candidate · E"
		"escorting":
			if Base.distance(model.position(),actor)>9.0 or not chapter._visible_from(chapter.specialist_body,model.position(),10,false):
				result.task="Return to the waiting instructor";result.progress="He waits when you leave his sight or move too far away."
				result.target=actor;result.marker="Waiting instructor"
			elif R.near(actor,R.HOME,4):
				result.task="Sign with the instructor present";result.progress="Both of you are here. Speak to the quartermaster to enter the agreement."
			else:
				result.task="Walk home with the instructor";result.progress="Keep him in sight. Arriving alone does not sign the agreement."
		"appointed":
			if c.lesson=="active":
				result.task=drill_requirement(chapter)
				result.progress="Stay together. A pause does not erase the practice already done."
				result.controls="WASD  Position     Mouse  Look     J  Participation / pause"
				var s: Dictionary=model.economy().ledger
				var household_repair: bool=c.arrears>0 or not c.fed or s.duty_guards<=c.guard_slot
				if model.controlling_specialist() and household_repair and chapter._drill_contact() and R.near(actor,R.HOME,4):
					result.controls="E  Return to Buddh     WASD  Position     J  Own participation"
				result.marker="Practice place"
			else:
				result.title="GUJRANWALA  /  INSTRUCTOR'S VIEW"
				result.task="Return to the quartermaster beside Buddh"
				result.progress="Your appointment grants this work. Your journal contains your own participation."
				result.controls="E  Speak / return view     WASD  Walk     Mouse  Look     J  Own participation"
	return result

static func drill_requirement(chapter: Node3D) -> String:
	var model=chapter.model;var c: Dictionary=model.commission();var s: Dictionary=model.economy().ledger
	if not R.near(chapter.specialist_body.global_position,R.HOME,4): return "Bring the instructor back to the practice place"
	if not R.near(model.position(),R.HOME,4): return "Return beside the instructor"
	if not chapter._drill_contact(): return "Stand together in clear sight"
	if model.controlling_specialist():
		if c.arrears>0: return "Return to Buddh to settle the wages"
		if not c.fed or s.duty_guards<=c.guard_slot: return "Return to Buddh to arrange the next supplied watch"
	if c.arrears>0: return "Settle the instructor's accrued wages"
	if not c.fed:
		return "Supply food for the next watch" if s.stock.food<1+s.workers+s.guards+1 else "Wait for the next supplied watch"
	if s.duty_guards<=c.guard_slot:
		return "Supply the assigned pupil for the next watch" if s.stock.food<1+s.workers+s.guards else "Wait for the pupil's next supplied watch"
	return "Stay together for the next movement"
