extends RefCounted
## Game taxonomy, NOT a completed genealogy or a claim about historical allegiance.
## Unknown/undated research candidates must not be activated as 1792 relationships.
const FACTIONS := ["sukerchakia", "phulkian", "sandhawalia", "bhangi", "kanhaiya"]
const SOURCES := {"design:1792": "Authored simulation design; not historical evidence"}
const PEOPLE := {
	"ranjit_singh": {"name":"Buddh Singh", "class":"historical_character_portrayal"},
	"raj_kaur": {"name":"Raj Kaur", "class":"historical_character_portrayal"},
	"fictional_household_guard": {"name":"Household guard", "class":"authored_placeholder"},
	"fictional_north_observer": {"name":"Northern retainer", "class":"authored_placeholder"},
	"fictional_courier": {"name":"Courier", "class":"authored_placeholder"}
}
const RELATIONS := [
	{"subject":"ranjit_singh", "predicate":"gameplay_alignment", "object":"sukerchakia", "from":1792, "until":1793, "sources":["design:1792"]},
	{"subject":"raj_kaur", "predicate":"gameplay_alignment", "object":"phulkian", "from":1792, "until":1793, "sources":["design:1792"]},
	{"subject":"fictional_household_guard", "predicate":"retainer_of", "object":"raj_kaur", "from":1792, "until":1793, "sources":["design:1792"]},
	{"subject":"fictional_household_guard", "predicate":"gameplay_alignment", "object":"phulkian", "from":1792, "until":1793, "sources":["design:1792"]},
	{"subject":"fictional_north_observer", "predicate":"gameplay_alignment", "object":"sandhawalia", "from":1792, "until":1793, "sources":["design:1792"]},
	{"subject":"fictional_courier", "predicate":"gameplay_alignment", "object":"sukerchakia", "from":1792, "until":1793, "sources":["design:1792"]}
]

static func active_relations(year: int, records: Array = RELATIONS) -> Array:
	var out: Array = []
	for relation in records:
		# Half-open validity; no guessing the validity of undated associations.
		if not relation is Dictionary: continue
		if relation.get("from") == null or relation.get("until") == null: continue
		if not _whole(relation["from"]) or not _whole(relation.until): continue
		if relation["from"] <= year and year < relation.until:
			out.append(relation.duplicate(true))
	return out

static func faction(person: String, year: int = 1792) -> String:
	for relation in active_relations(year):
		if relation.subject == person and relation.predicate == "gameplay_alignment":
			return relation.object
	return ""

static func validate_records(records: Variant) -> String:
	if not records is Array or records.size() > 2048: return "Invalid relationship collection."
	var seen: Dictionary = {}
	for r in records:
		if not r is Dictionary or r.size() != 6: return "Malformed relationship."
		for key in ["subject","predicate","object","from","until","sources"]:
			if not r.has(key): return "Missing relationship field."
		if not PEOPLE.has(r.subject): return "Unknown subject; preserve unresolved identities outside the active registry."
		if not PEOPLE.has(r.object) and r.object not in FACTIONS: return "Unknown relationship object."
		if r.predicate not in ["gameplay_alignment","retainer_of","kin_of","household_member"]: return "Unknown predicate."
		if not _whole(r["from"]) or not _whole(r.until) or r.until <= r["from"]: return "A research candidate needs a supported validity interval before activation."
		if not r.sources is Array or r.sources.is_empty(): return "Relationship has no provenance."
		for source in r.sources:
			if not SOURCES.has(source): return "Unregistered source."
		var key := JSON.stringify([r.subject,r.predicate,r.object,r["from"],r.until])
		if seen.has(key): return "Duplicate relationship."
		seen[key] = true
	return ""

static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(v)) and v == floor(v)
