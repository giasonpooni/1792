# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original companion observations during the physical market approach.
## Session-local presentation only: no receipt, memory, relationship score or historical claim.
const ZONES := [
	{"id":"goods","center":Vector3(-22.0,.14,-12.3),"radius":2.8,
	 "lines":[[4,"Mind the baskets. If you knock one over, I am leaving you to explain it."]]},
	{"id":"animal","center":Vector3(-18.2,.14,-14.5),"radius":2.9,
	 "lines":[[3,"Look at that one. I would take him over your pony."],[4,"You say that about every animal you have not fallen off yet."]]},
	{"id":"cart","center":Vector3(-14.8,.14,-16.0),"radius":2.7,
	 "lines":[[4,"Make way. The whole bazaar was here before we decided to stroll through it."]]}
]
static func available(position: Vector3,phase: String,seen: Dictionary) -> Dictionary:
	if phase!="invited": return {}
	for zone in ZONES:
		if seen.has(zone.id): continue
		if position.distance_to(zone.center)<=zone.radius: return zone.duplicate(true)
	return {}
