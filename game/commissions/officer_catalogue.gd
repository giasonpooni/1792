# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Editorial candidates, not spawns, hired soldiers, or character knowledge.
const PATH := "res://commissions/officer_chapters.json"
static func data() -> Dictionary:
	var d: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return d if d is Dictionary else {}
static func eligible(id: String,year: Variant) -> bool:
	if typeof(year) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(year)) or year!=floor(year): return false
	for p in data().get("officers",[]):
		if p.id==id: return year>=p.source_service_window[0] and year<=p.source_service_window[1]
	return false
static func playable_now(id: String,year: Variant) -> bool:
	# Deliberately false until an executable chapter, save and control policy is bound.
	return false
static func notebook() -> String:
	var out: String="FUTURE OFFICER CHAPTERS · AUTHORING ONLY, NOT CHARACTER KNOWLEDGE\n\n"
	for p in data().get("officers",[]):
		out+="%s · reference service window %d–%d\nRequired playable chapter, not yet implemented.\n%s\n\n"%[p.display_name,p.source_service_window[0],p.source_service_window[1],p.proposed_focus]
	out+="Agent enquiries, contracts and wages are a gameplay requirement, not a claim that every historical officer followed the same recruitment route. Current home service uses an original fictional instructor."
	return out
