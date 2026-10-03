# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dramatic framing, separate from unchanged testimony and evidence.
## Read-only samples; no clock, inventory, camera or hidden-report disclosures.
const R:=preload("res://remounts/remount_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const BRIEF:="Quartermaster · Two empty places, and everyone has an explanation. Find the horses first.\n\nAsk the western market handler, or approach the southern yard. Bring back what you saw and the sealed tally."
const GATE:="Gatekeeper · The horses have a keeper. So does this gate.\n\nThe handler's introduction will let you examine the remounts and carry their tally home."
const AFTERMATH:="Buddh · Should I bring them back?\nQuartermaster · You found where they are. Now the adults must arrange their return.\nBuddh · Then I have finished only my part.\nQuartermaster · That is a useful thing to know."

static func action_line(kind: String) -> String:
	match kind:
		"begin": return "Quartermaster · Find the horses first. Bring their sealed tally home."
		"introduction": return "Handler · Use my name at the gate. I have not given you an explanation."
		"permission": return "Gatekeeper · Go on. The horses are inside; their tally is beside the screen."
		"horses": return "Buddh · Both here. Then why did no one tell us?"
		"note": return "Buddh · The tally, still sealed. I will hear it read at home."
	return ""

static func report(ledger: Dictionary) -> String:
	var arrival:="Buddh · The cord marks matched. I brought the sealed tally.\nQuartermaster · Set it here. Tell me what you saw first."
	var callback:="Buddh · The gatekeeper gave me permission." if ledger.permission else "Buddh · I went inside without asking."
	return arrival+"\n"+callback+"\n\nQuartermaster reads · "+R.WORDS.resolve.text

static func read(chapter: Node3D,moving: bool=false) -> Dictionary:
	var model=chapter.model
	if not model.has_remounts() or not model.remount_busy(): return {}
	var s: Dictionary=model.remounts().ledger
	var result:={"title":"GUJRANWALA  /  TWO EMPTY PLACES","task":"Find the missing remounts","progress":"Ask the western market handler, or find the southern yard.","controls":"E  Speak / examine     WASD  Walk     Mouse  Look     J  Journal", "target":Vector3.ZERO,"marker":"","show_target":false,"attention_mode":"moving" if moving else "rest","show_progress":not moving}
	if model.mounted():
		result.task="Stop and dismount before entering the yard"
		result.controls="S / Space  Brake     F  Dismount"
		result.show_progress=false
		return result
	if s.note and s.horses:
		result.task="Bring your account home"
		result.progress="Both remounts located. Bring the sealed tally to the quartermaster."
		result.target=Supply.QUARTERMASTER;result.marker="Quartermaster · E";result.show_target=true
	elif s.horses:
		result.task="Find the horses' sealed tally"
		result.progress="You have seen the cord marks. The tally waits beside the yard screen."
		result.target=R.NOTE;result.marker="Sealed tally · E";result.show_target=true
	elif s.note:
		result.task="Examine both tethered remounts"
		result.progress="You carry the sealed tally. Check the cord marks before returning."
		result.target=R.HITCH;result.marker="Remounts · E";result.show_target=true
	elif s.permission or R.in_yard(model.position()):
		result.task="Examine the two tethered horses"
		result.progress="Face the horses to check their cord marks. Their tally lies beside the screen."
		result.target=R.HITCH;result.marker="Remounts · E";result.show_target=true
	elif s.introduced:
		result.task="Present the introduction at the east gate"
		result.progress="The handler sent you. The gatekeeper still needs to hear it."
		result.target=R.OBSERVERS.yard_gatekeeper.position;result.marker="Gatekeeper · E";result.show_target=true
	return result
