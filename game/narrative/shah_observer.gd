# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Retrospective player-facing narration. Never writes to the supplied snapshot.
## Original English development copy, NOT historical verse or a Punjabi translation.
const VOICE := "Shah Muhammad · original development narration"
const LINES := {
	"home":"Before the distant roads, there was this courtyard: familiar voices, a horse, and the work of returning home.",
	"allowance":"The coins were entrusted, not given away. A household continued only while someone counted what it consumed.",
	"market":"One small journey had joined the store to the market. The way home still had to be travelled.",
	"return":"The carrier returned with provisions. Responsibility was measured not only in departure, but in what came home."
}
var last_key := ""
var last_tick := -1
var until_tick := -1
var text := ""

static func key_for(snapshot: Dictionary) -> String:
	if snapshot.get("player",{}).get("character_id")!="ranjit_singh" or not snapshot.has("childhood"): return ""
	if snapshot.has("misl"):
		var ledger: Dictionary=snapshot.misl.ledger
		if ledger.caravan=="complete": return "return"
		if ledger.delivery=="delivered": return "market"
		return "allowance"
	return "home"

func observe(snapshot: Dictionary) -> String:
	var key:=key_for(snapshot)
	if key.is_empty(): return ""
	var tick: int=int(snapshot.childhood.tick)
	if tick<last_tick:
		# Rewind invalidates later presentation, never imports future narration into the past.
		last_key=key
		until_tick=-1
		text=""
	if key!=last_key:
		last_key=key
		until_tick=tick+540
		text=VOICE+"\n"+LINES[key]
	last_tick=tick
	return text if tick<until_tick else ""

func rebind(snapshot: Dictionary) -> void:
	# Save/load synchronizes the view silently; it does not replay a later cue.
	last_key=key_for(snapshot)
	last_tick=int(snapshot.get("childhood",{}).get("tick",0))
	until_tick=-1
	text=""
