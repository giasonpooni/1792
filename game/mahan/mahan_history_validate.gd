extends RefCounted
## Shared historical-event / location validators for the Mahan history adapter.
const FORBIDDEN_TOKENS := [
	"raj_kaur", "Raj Kaur", "phulkian", "Phulkian", "sandhawalia", "Sandhawalia"
]

static func validate_authored_location(value: Variant) -> String:
	if not value is Dictionary:
		return "Historical location must be an object."
	for key in ["schema_version", "location_id", "kind", "label", "region", "evidence", "canon_class", "gameplay"]:
		if not value.has(key):
			return "Historical location missing %s." % key
	if value.schema_version != "historical-location.v1":
		return "Unsupported historical-location schema_version."
	if value.kind not in ["settlement", "road", "fort", "camp", "ford", "landmark"]:
		return "Invalid location kind."
	if value.canon_class not in ["source_attested", "reconstructed", "game_canon", "authored_fiction"]:
		return "Invalid location canon_class."
	if not value.evidence is Array or value.evidence.is_empty():
		return "Location evidence required."
	for ev in value.evidence:
		if not ev is Dictionary:
			return "Malformed location evidence."
		for k in ["source", "confidence", "evidence_class"]:
			if not ev.has(k):
				return "Malformed location evidence."
		if ev.evidence_class not in ["A", "B", "C", "D"]:
			return "Invalid location evidence_class."
	var gp = value.gameplay
	if not gp is Dictionary or not gp.has("profile_scope") or not gp.has("role"):
		return "Malformed location gameplay."
	if gp.get("profile_scope", "mahan.v1") != "mahan.v1":
		return "Location profile_scope must stay mahan.v1 in this slice."
	if gp.role not in ["home_ground", "approach", "column_node", "reference_only"]:
		return "Invalid location gameplay role."
	if value.has("household_context") and str(value.household_context) not in ["", "sukerchakia"]:
		return "Location household_context must stay sukerchakia in this Mahan slice."
	var blob := JSON.stringify(value).to_lower()
	for token in ["raj_kaur", "phulkian", "sandhawalia"]:
		if blob.contains(token):
			return "Forbidden ontology token in historical location payload."
	return ""

static func validate_authored_event(value: Variant) -> String:
	if not value is Dictionary:
		return "Historical event must be an object."
	for key in [
		"schema_version", "event_id", "date_range", "location", "actors",
		"evidence", "canon_class", "historical_outcome", "knowledge", "gameplay"
	]:
		if not value.has(key):
			return "Historical event missing %s." % key
	if value.schema_version != "historical-event.v1":
		return "Unsupported historical-event schema_version."
	if typeof(value.event_id) != TYPE_STRING or str(value.event_id).is_empty():
		return "Invalid event_id."
	if value.canon_class not in ["source_attested", "reconstructed", "game_canon", "authored_fiction"]:
		return "Invalid canon_class."
	var dr = value.date_range
	if not dr is Dictionary or not dr.has("start_year") or not dr.has("end_year"):
		return "Malformed date_range."
	var loc = value.location
	if not loc is Dictionary or not loc.has("place_id"):
		return "Malformed location."
	if loc.has("related_place_ids") and not loc.related_place_ids is Array:
		return "Malformed related_place_ids."
	if not value.actors is Array or value.actors.is_empty():
		return "Actors required."
	var seen_kinds := {}
	for actor in value.actors:
		if not actor is Dictionary:
			return "Malformed actor."
		for k in ["id", "role", "kind"]:
			if not actor.has(k):
				return "Malformed actor."
		if actor.kind not in ["person", "household", "faction"]:
			return "Invalid actor kind."
		var aid: String = str(actor.id)
		if seen_kinds.has(aid) and seen_kinds[aid] != actor.kind:
			return "Ontology collapse: id used under conflicting kinds."
		seen_kinds[aid] = actor.kind
		for token in FORBIDDEN_TOKENS:
			if aid.to_lower().contains(token.to_lower()) or str(actor.role).to_lower().contains(token.to_lower()):
				return "Forbidden ontology token in historical actors."
	if not value.evidence is Array or value.evidence.is_empty():
		return "Evidence required."
	for ev in value.evidence:
		if not ev is Dictionary:
			return "Malformed evidence."
		for k in ["source", "confidence", "evidence_class"]:
			if not ev.has(k):
				return "Malformed evidence."
		if ev.evidence_class not in ["A", "B", "C", "D"]:
			return "Invalid evidence_class."
		if ev.confidence not in ["high", "medium", "low", "none"]:
			return "Invalid evidence confidence."
	var outcome = value.historical_outcome
	if not outcome is Dictionary or not outcome.has("fixed") or typeof(outcome.fixed) != TYPE_BOOL:
		return "Malformed historical_outcome."
	var knowledge = value.knowledge
	if not knowledge is Dictionary:
		return "Malformed knowledge."
	for k in ["direct_observers", "report_routes", "propagation_delay", "player_knowledge"]:
		if not knowledge.has(k):
			return "Malformed knowledge."
	if not knowledge.direct_observers is Array or not knowledge.report_routes is Array:
		return "Malformed knowledge collections."
	if typeof(knowledge.propagation_delay) not in [TYPE_INT, TYPE_FLOAT] or int(knowledge.propagation_delay) < 0:
		return "Invalid propagation_delay."
	if typeof(knowledge.player_knowledge) != TYPE_BOOL:
		return "player_knowledge must be boolean."
	if knowledge.player_knowledge:
		var observers: Array = knowledge.direct_observers
		if "mahan_singh" not in observers:
			return "Refuse authored player_knowledge=true when mahan_singh is not a direct observer."
	var gp = value.gameplay
	if not gp is Dictionary:
		return "Malformed gameplay."
	for k in ["playable", "intervention_scope", "historical_invariants"]:
		if not gp.has(k):
			return "Malformed gameplay."
	if typeof(gp.playable) != TYPE_BOOL:
		return "playable must be boolean."
	if gp.intervention_scope not in ["none", "observe", "report", "order_around", "alter_outcome"]:
		return "Invalid intervention_scope."
	if not gp.historical_invariants is Array:
		return "historical_invariants must be an array."
	if gp.get("profile_scope", "mahan.v1") != "mahan.v1":
		return "Historical event profile_scope must stay mahan.v1 in this slice."
	if outcome.fixed and gp.intervention_scope == "alter_outcome":
		return "Fixed historical_outcome cannot allow alter_outcome."
	var blob := JSON.stringify(value)
	for token in FORBIDDEN_TOKENS:
		if blob.contains(token):
			return "Forbidden ontology token in historical event payload."
	return ""
