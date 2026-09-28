# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authoring inventory, never player knowledge or an executable provider registry.
const PATH := "res://youth/story_catalogue.json"
static func data() -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return value if value is Dictionary else {}
static func digest() -> String: return FileAccess.get_file_as_string(PATH).sha256_text()
static func notebook() -> String:
	var out: String="YOUTH CAMPAIGN · AUTHORING VIEW, NOT BUDDH'S MEMORY\n\nAll 28 story entries are required playable work. Only the Bhangi Bazaar Brawl is added as a playable episode here. Existing seeds are not completed adaptations.\n\n"
	for s in data().get("stories",[]):
		out+="%s [%s]\n%s\nCompletion: %s\nFallout: %s\nEvidence: %s / %s\n\n"%[s.title,s.implementation,s.player_actions,s.completion,s.fallout,s.source_id,s.evidence_status]
	out+="Variant rules\n"
	for group in data().get("variant_groups",[]): out+=group.rule+"\n\n"
	out+="Sources actually consulted\n"
	for source in data().get("sources",[]): out+="%s: %s\n%s\n%s\n\n"%[source.id,source.consulted,source.supports,str(source.url)]
	return out
