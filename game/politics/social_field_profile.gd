# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored 1792 scenario configuration; no reconstructed genealogy or measured delays.
const VERSION := "1792.local-social-profile.v1"
const HERO_SUBJECT := "sukerchakia"
const ACTORS := {
	"raj_kaur":{"faction":"phulkian", "node":"household", "delay":60, "reliability":0.85},
	"fictional_household_guard":{"faction":"phulkian", "node":"household_retinue", "delay":180, "reliability":0.75},
	"fictional_north_observer":{"faction":"sandhawalia", "node":"north_lane", "delay":60, "reliability":0.90},
	"fictional_market_keeper":{"faction":"bhangi", "node":"market", "delay":60, "reliability":1.0},
	"fictional_gate_keeper":{"faction":"sandhawalia", "node":"gate", "delay":180, "reliability":0.80}
}
# Scene-local positions, not a survey or the separate household economy's trader.
const SITES := {
	"fictional_market_keeper":Vector3(15,0.14,1),
	"fictional_gate_keeper":Vector3(-12,0.14,-18),
	"fictional_north_observer":Vector3(-18,0.14,-20)
}
const ADDED_RESIDENTS := ["fictional_market_keeper", "fictional_gate_keeper"]
const TEXT := {
	"open":"The conversation continues easily. No troubling account has reached this speaker; that is not proof that the roads are safe.",
	"reserved":"The speaker lowers their voice. Reports have arrived, but they will not offer a firm account of what happened.",
	"guarded":"The greeting is brief. The speaker says reports of armed incursions have made them unwilling to vouch for your party.",
	"reassured":"The speaker's manner softens. Word of reparations has arrived, though they make no promise on anyone else's behalf."
}
