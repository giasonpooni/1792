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
	if not facing: return "Trainer · Face me. A blow behind your shoulder teaches neither of us anything."
	if parries < 2: return "Trainer · Hold your guard through two blows first. You are learning when to answer."
	if phase <= 89: return "Trainer · Too late for the last opening. Settle your feet and watch the next raised arm."
	if phase <= 120: return "Trainer · Too early. My guard is still up. Wait until the blow has passed."
	return "Trainer · There. You waited, then answered. Now take that patience onto the trail."

static func trail_task(tracks: int) -> String:
	return "Examine the " + str(TRACE_NAMES[tracks]).to_lower() if tracks < 3 else "Reach the quarry quietly"

static func gate_reaction(completed: int) -> String:
	match completed:
		1: return "Buddh · Through the first gate. Look toward the next turn before asking for more speed."
		2: return "Buddh · Two turns. Bring the horse back under control for the gate into the yard."
		3: return "Trainer · All three. Bring him to a walk, stop on clear ground, and come to me on foot."
	return ""
