# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Presentation-only emotional beat between authoritative regroup and report.
const WINDOW := 360
static func beat(outcome: String,elapsed: int) -> Dictionary:
	if elapsed<0 or elapsed>WINDOW:return {}
	var p:=clampf(float(elapsed)/WINDOW,0,1)
	var settle:=1.0-p
	match outcome:
		"stood_ground":
			return {"mela":"energized","jiva":"checking","amount":settle,
				"caption":"The shouting falls behind. Mela is still carrying the fight; Jiva counts heads before he says anything."}
		"withdrew":
			return {"mela":"restless","jiva":"relieved","amount":settle,
				"caption":"Nobody speaks for a few steps. The road home is suddenly louder than the quarrel."}
		"walked_away":
			return {"mela":"questioning","jiva":"easy","amount":settle,
				"caption":"The insult remains in the bazaar. All three of you keep walking."}
	return {}
static func latest_regroup(events: Array) -> int:
	for i in range(events.size()-1,-1,-1):
		if events[i].kind=="regroup":return int(events[i].tick)
	return -1
