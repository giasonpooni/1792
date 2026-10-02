# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original dramatic presentation of existing lesson timing and inspected traces.
## No save data, second clock, rewards, or historical quotations.
const TRACE_DETAILS := {
	"track_1": "Buddh · Two shallow prints, close together. The trail leaves the hard yard here.",
	"track_2": "Buddh · These reeds are bent across the prints. I can follow where the stems were pushed aside.",
	"track_3": "Buddh · The grass is pressed low ahead. I will slow down before I reach the open ground."
}
const TRACE_NAMES := ["Shallow prints", "Bent reeds", "Pressed grass"]

static func practice_phase(tick: int) -> String:
	var phase := posmod(tick, 150)
	if phase < 60: return "ready"
	if phase < 90: return "preparation"
	if phase < 120: return "windup"
	return "recovery"

static func swing_feedback(phase: int, parries: int, facing: bool) -> String:
	phase = posmod(phase, 150)
	if not facing: return "Trainer · Face me. Keep the raised arm in view."
	if parries < 2: return "Trainer · Two guards first. Learn when to answer."
	if phase <= 89: return "Trainer · Too late. Settle your feet; watch the next raised arm."
	if phase <= 120: return "Trainer · Too early. Wait until my arm falls."
	return "Trainer · There. Look first, then answer. Take that patience onto the trail."

static func trail_task(tracks: int) -> String:
	return "Examine the " + str(TRACE_NAMES[tracks]).to_lower() if tracks < 3 else "Reach the quarry quietly"

static func gate_reaction(completed: int) -> String:
	match completed:
		1: return "Buddh · Through the first gate. Look toward the next turn before asking for more speed."
		2: return "Buddh · Two turns. Bring the horse back under control for the gate into the yard."
		3: return "Trainer · All three. Bring him to a walk, stop on clear ground, and come to me on foot."
	return ""

static func transition_line(previous: String, current: String) -> String:
	# Internal reactions use only a completed transition. No hidden enemy cue,
	# invented report, attributed quotation or automatic historical conclusion.
	match previous + ">" + current:
		"letter>riding": return "Buddh · A horse may be easier to understand than two men telling different stories."
		"sparring>tracking": return "Buddh · Look first, then answer. Perhaps a trail can be read the same way."
		"active>escaped:accounts": return "Buddh · The same gate. I did not expect to be so glad to see it."
		"escaped:return>escaped:complete": return "Buddh · I wanted a name to bring home. I brought what I could see."
	return ""
