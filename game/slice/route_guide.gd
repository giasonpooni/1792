# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only composition of existing received/task state; creates no receipts or rewards.
static func inspect(model) -> Dictionary:
	var inquiry: bool=model.aftermath_phase()=="complete"
	var allowance: bool=model.has_economy()
	var water_done: bool=model.has_water_round() and model.water_round().ledger.phase=="complete"
	var smith_done: bool=model.workshop_phase()=="complete"
	var outing_done: bool=model.brawl_phase()=="reported"
	var smith_closed: bool=model.workshop_phase() in ["complete","cancelled"]
	var rows: Array=[
		{"id":"inquiry","label":"Learn the yard and bring the household an observed account","complete":inquiry},
		{"id":"allowance","label":"Hear the quartermaster's limited allowance","complete":allowance},
		{"id":"water","label":"Bring both water loads back to the household","complete":water_done},
		{"id":"smith","label":"Return the smith's two tool bundles","complete":smith_done},
		{"id":"bazaar","label":"Walk with Mela and Jiva, then bring everyone and the account home","complete":outing_done}]
	var next:="Follow the current lesson in the yard. The household inquiry opens the errands."
	var active:="inquiry"
	if inquiry:
		active="allowance";next="Speak to the quartermaster in the home courtyard [E]."
	if allowance:
		active="water";next="Ask the quartermaster for the two-load water round [E]."
		# Current custody and company take priority over the suggested sequence.
		if model.brawl_busy():
			active="bazaar"
			next={"invited":"Walk with both friends to the bazaar and hear the nearby challenger.",
				"challenged":"Answer the challenge. Walking away and standing your ground are both choices.",
				"fighting":"Make distance or guard and counter. Bring both friends back to the household approach.",
				"leaving":"Withdraw together to the household approach; wait for both friends.",
				"returning":"Give the quartermaster the bazaar account with both friends present [E].",
				"caught":"Restore the pre-confrontation world from the existing Retry action."}.get(model.brawl_phase(),"")
		elif model.carrying_workshop():
			active="smith";next="Carry the fuel and assigned payment to the smith in the western courtyard [E]." if model.workshop_phase()=="fuel" else "Carry both tool bundles back to the quartermaster [E]."
		elif model.has_water_round() and model.water_round().ledger.phase in ["drawing","carrying"]:
			active="water"
			next={"ready":"Walk to the east-side well. Face it and draw a load [E].",
				"drawing":"Stay beside the well until the draw finishes. Leaving cancels the draw.",
				"carrying":"Walk the open water carrier back to the quartermaster and deposit it [E]."}.get(model.water_round().ledger.phase,"")
		elif model.has_economy() and model.economy().ledger.caravan=="active":
			active="other";next="Stay close to the active caravan and bring it to the quartermaster before another errand."
		elif model.has_economy() and model.economy().ledger.delivery=="outbound":
			active="other";next="Finish the carried supply delivery at the market before another errand."
		elif model.service_reserved():
			active="other";next="Finish the active household service and its return before taking another errand."
		elif model.has_water_round() and not water_done:
			active="water";next="Walk to the east-side well. Face it and draw a load [E]."
		elif not smith_closed and model.workshop_phase() in ["working","ready"]:
			active="smith";next="The order was left with the smith. Return to his court to ask about it [E]."
		elif water_done and not smith_closed:
			active="smith";next="Ask the quartermaster for the smith's two-tool commission [E]."
		elif water_done and smith_closed and not outing_done:
			active="bazaar";next="Speak to Mela and Jiva at the market about a short walk [E]."
		elif water_done and smith_closed and outing_done:
			active="settled";next="The household round and outing are settled. Explore the courtyard or review the accounts."
	return {"schema":"1792.gujranwala-route.v0.1","rows":rows,"active":active,"next":next,
		"settled":inquiry and allowance and water_done and smith_closed and outing_done,"smith_cancelled":model.workshop_phase()=="cancelled"}

static func text(model) -> String:
	var guide:=inspect(model)
	var body:="A route through the existing Home chapter. You can choose other errands; current cargo and company come first.\n\n"
	for row in guide.rows:
		var status: String="[cancelled] " if row.id=="smith" and guide.smith_cancelled else "[done] " if row.complete else "[open] "
		body+=status+row.label+"\n"
	if guide.smith_cancelled: body+="The unused smith commission was cancelled and refunded; no tools were produced.\n"
	body+="\nNEXT · "+guide.next+"\n\nF5 keeps a manual save for this run; F9 restores it. Continue keeps your visit between sessions. Conversations pause the world."
	return body
