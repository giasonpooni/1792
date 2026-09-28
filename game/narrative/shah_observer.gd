# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Retrospective player-facing narration. Never writes to the supplied snapshot.
## Original English development copy, NOT historical verse or a Punjabi translation.
const VOICE := "Shah Muhammad · original development narration"
const LINES := {
	"oral_first":"A rope can return to its peg while its story continues down the road.",
	"oral_compare":"Two voices did not leave the same shape in memory. The difference, too, had to be carried.",
	"oral_retell":"He passed on what he had heard, and named the mouths from which it came. The next telling would have a witness to its telling, not to the old event.",
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
	var base_key: String="home"
	var base_tick: int=-1
	if snapshot.has("misl"):
		var ledger: Dictionary=snapshot.misl.ledger
		base_key="return" if ledger.caravan=="complete" else "market" if ledger.delivery=="delivered" else "allowance"
		base_tick=int(snapshot.misl.origin_tick)
		for receipt in snapshot.misl.events:
			if (base_key=="return" and receipt.kind=="checkin") or (base_key=="market" and receipt.kind=="deliver"):
				base_tick=int(receipt.tick)
	if snapshot.has("oral_memory"):
		var kinds: Array=[]
		var oral_tick: int=-1
		for event in snapshot.oral_memory.events:
			kinds.append(event.kind)
			if event.kind in ["hear","compare","retell"]: oral_tick=int(event.tick)
		# A finished oral episode must not suppress later inherited supply/return cues.
		if oral_tick>=base_tick:
			if "retell" in kinds: return "oral_retell"
			if "compare" in kinds: return "oral_compare"
			if "hear" in kinds: return "oral_first"
	return base_key

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
