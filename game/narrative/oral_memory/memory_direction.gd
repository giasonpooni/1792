# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original optional scene framing. Never edits the received telling or its digest.
const Rules := preload("res://narrative/oral_memory/memory_rules.gd")
const TITLES := {
	"quartermaster_account":"THE HAND THAT HELD",
	"trader_account":"BORROWED BECOMES STOLEN",
	"well_echo":"THE THIRD VOICE",
	"quartermaster_reflection":"A DIFFERENT MOMENT",
	"rope_trace":"THE REPAIRED LOOP",
	"borrowed_rope":"TWO ACCOUNTS, ONE ROPE"
}
const FRAMING := {
	"quartermaster_account":"The quartermaster remembers the hand that held on.",
	"trader_account":"The word has changed on its way across the market.",
	"well_echo":"The neighbour names the voice that brought the story here.",
	"quartermaster_reflection":"This time, the quartermaster remembers a question.",
	"rope_trace":"A worn length. A repaired loop. An ordinary thing carrying an argument.",
	"borrowed_rope":"You hold the two accounts beside each other. Neither disappears."
}

static func receipt_heading(row: Dictionary) -> String:
	var channels: Dictionary={"remembered_testimony":"Remembered account",
		"attributed_hearsay":"Heard from another","direct_observation":"What you saw",
		"reflection":"Your thoughts","attributed_retelling":"Your retelling"}
	var speakers: Dictionary={"household_quartermaster":"Quartermaster","market_trader":"Trader",
		"well_neighbour":"Neighbour","ranjit_singh":"Buddh"}
	return String(channels.get(row.channel,"Remembered words"))+" · "+String(speakers.get(row.source_id,"Speaker"))

static func title(kind: String,subject: String) -> String:
	if kind=="ask": return "LET HIM REMEMBER"
	if kind=="retell": return "WHAT TRAVELS WITH YOUR WORDS"
	return String(TITLES.get(subject,"THE BORROWED ROPE"))

static func body(kind: String,subject: String,receipt: String,response: String="") -> String:
	if kind=="ask": return "Quartermaster · Give me a moment, Buddh. I remember the rope coming back. Let me think about the asking.\n\nReturn to your walk. You can come back and listen after a little time."
	if kind=="retell": return receipt+"\n\n"+response
	return String(FRAMING.get(subject,""))+"\n\n"+receipt

static func next_beat(progress: Dictionary,tick: int) -> String:
	if progress.retellings.has("comparison"): return "You kept both accounts in the telling. The neighbour knows where they came from."
	if progress.compared_seq>0 and progress.trace_seq>0:
		if progress.requested_seq==0: return "You can ask the quartermaster about the moment of borrowing, or tell the neighbour what you have heard."
		if not progress.heard.has("quartermaster_reflection"):
			return "Let the quartermaster think while you continue your walk. Return to hear his answer." if tick<progress.requested_tick+Rules.RECALL_TICKS else "The quartermaster has had time to think. His answer still has to be heard in person."
		return "The neighbour can hear both accounts, with the disagreement left open."
	if progress.compared_seq>0: return "The rope is beside the stable. Its wear may show you something the voices cannot."
	if progress.heard.has("quartermaster_account") and progress.heard.has("trader_account"): return "Two accounts now disagree. You can put their words side by side here."
	if progress.heard.has("quartermaster_account"): return "The trader has a story about this rope too. You can hear it when you next visit the market."
	if progress.heard.has("trader_account") or progress.heard.has("well_echo"): return "The quartermaster may remember the borrowing. His voice has not reached you yet."
	if progress.trace_seq>0: return "The repaired loop has a story. Ask about it at the household or market when you wish."
	return "An optional story waits with the quartermaster, the trader and a rope beside the stable."
