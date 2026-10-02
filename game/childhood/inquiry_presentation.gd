extends RefCounted
## Original dramatic dialogue projected from received events. This does not create
## memories or change the legacy report. Saved prose is never parsed as evidence.

static func report_body(model) -> String:
	var progress: Dictionary = model.progress()
	var after: Dictionary = model.aftermath()
	var ambush: Dictionary = progress.get("ambush", {})
	var lines: Array[String] = []
	if ambush.get("seen", false):
		lines.append("I saw the man who attacked me at the bend. I cannot name him.")
	elif ambush.get("status", "") == "escaped":
		lines.append("I came back from the bend alive. I did not get a clear look at whoever was there.")
	else:
		lines.append("I have no returned account of the bend to give you yet.")
	if ambush.get("deflected", false):
		lines.append("I turned a blow aside and made room to get away.")
	if int(ambush.get("hits", 0)) > 0:
		lines.append("I was struck. I remember that much without anyone telling me.")
	var callback := _message_callback(model)
	if not callback.is_empty(): lines.append(callback)
	if "return_courier" in after.get("heard", []):
		lines.append("The courier says he heard riders beyond the grove. He cannot connect them to the attack.")
	if int(after.get("clue_tick", -1)) >= 0:
		lines.append("Fresh hoof marks cross the older trail at the bend. I examined them myself; they give me no rider's name.")
	else:
		lines.append("I have not examined the ground at the bend yet.")
	lines.append("I cannot tell you who sent an attacker, or whether anyone did.")
	return "BUDDH\n" + "\n\n".join(lines)

static func acknowledgment(model) -> String:
	var after: Dictionary = model.aftermath()
	var returned := int(after.get("reported_tick", -1)) >= 0
	match str(after.get("decision", "")):
		"household_escort":
			if returned:
				return "RAJ KAUR\nYou brought the guard home with you. Good. I have heard your account; he will answer for his own. Leave the unanswered part unanswered for now. Come inside."
			return "RAJ KAUR\nThen take him with you. Let him come close enough to see the ground you examine, and bring him back when you return. I need you home, Buddh."
		"independent_inquiry":
			if returned:
				return "RAJ KAUR\nYou chose to go alone, and you have come back to answer for what you saw. I am listening. I am still your mother, even when you would rather I were not afraid."
			return "RAJ KAUR\nI hear you. The guard stays here. Look carefully, then come straight back and tell me yourself. Do not make me learn where you went from someone at the gate."
	return "RAJ KAUR\nTell me whether you will take the guard before you go. I will hear your answer."

static func protection_body(model) -> String:
	var ambush: Dictionary = model.progress().get("ambush", {})
	var opening := "You are here. Let me look at you."
	if int(ambush.get("hits", 0)) > 0:
		opening = "You have been struck. Come closer; let me look at you."
	elif ambush.get("seen", false):
		opening = "You saw someone come at you, and you came home. Let me look at you."
	return "RAJ KAUR\n" + opening + "\n\nIf you must return to the bend, take a household guard. Wait for him when you examine the ground, and bring him home with you. You will each have your own account to give.\n\nIf you insist on going alone, say it plainly. I will keep the guard here. But you will return to me yourself.\n\nI cannot keep fear out of this house by giving it a name. Tell me what you know."

static func return_caption(model) -> String:
	var after: Dictionary = model.aftermath()
	if int(after.get("reported_tick", -1)) >= 0:
		return "The account is given. The questions remain."
	if int(after.get("clue_tick", -1)) >= 0:
		if after.get("decision", "") == "household_escort" and after.get("escort", {}).get("active", false):
			return "Bring the guard home. Raj Kaur is waiting for your account."
		return "Return to Raj Kaur. Tell her what you found."
	if not str(after.get("decision", "")).is_empty():
		return "The bend is waiting. Look before you give an answer."
	return "Home again. Hear the household before returning to the bend."

static func _message_callback(model) -> String:
	if not model.has_method("message_followup"): return ""
	var message: Dictionary = model.message_followup()
	if message.is_empty(): return ""
	var phase: String = str(model.message_phase()) if model.has_method("message_phase") else ""
	var confirmed := false
	for receipt in message.get("receipts", []):
		if receipt.get("kind", "") == "confirm": confirmed = true
	if message.get("choice", "") == "direct":
		if phase == "complete":
			return "Earlier, I gave the trainer both accounts without claiming the road was safe."
		return "I meant to carry both morning accounts to the trainer. I had not given that report."
	if message.get("choice", "") == "clarify":
		if confirmed and phase == "complete":
			return "I asked the courier again and told the trainer his answer: hooves heard, no faces seen."
		if confirmed:
			return "I asked the courier again: hooves heard, no faces seen. I had not taken his answer to the trainer."
		return "I meant to question the courier again. I had not heard his answer."
	return ""
