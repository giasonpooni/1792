# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only source -> observation -> reconstruction -> placement graph.
const PATH := "res://data/punjab_ecology.v1.json"
const HABITATS := ["settlement_cultivated", "dry_scrub_grazing", "riverine_thicket", "seasonal_wetland"]
const SEASONS := ["dry", "monsoon", "receding"]
var manifest: Dictionary = {}
var digest := ""

static func _number(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(value) and value >= low and value <= high

static func _date(value: Variant) -> bool:
	if not value is Dictionary or not value.get("label") is String or value.label.is_empty(): return false
	for key in ["start_year", "end_year"]:
		if not value.has(key): return false
		if value[key] != null and (not _number(value[key], 1, 2100) or value[key] != floor(value[key])): return false
	return value.start_year == null or value.end_year == null or value.start_year <= value.end_year

static func _records(value: Variant) -> bool:
	if not value is Array or value.is_empty(): return false
	var ids: Array = []
	for row in value:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or row.id in ids: return false
		ids.append(row.id)
	return true

static func _index(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for row in rows: result[row.id] = row
	return result

static func _refs(value: Variant, index: Dictionary) -> bool:
	if not value is Array or value.is_empty(): return false
	for id in value:
		if not id is String or not index.has(id): return false
	return true

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.get("schema") != "1792.punjab-ecology.v1": return "Unknown ecology schema."
	if value.get("target_year") != 1792 or value.get("georeferenced") != false or value.get("frame") != "gujranwala-compressed-local-metres": return "Ecology cannot admit a survey or change the epoch."
	for key in ["sources", "observations", "habitats", "reconstruction_decisions", "placements", "taxonomic_corrections", "evidence_issues"]:
		if not _records(value.get(key)): return "Missing or duplicate ecology records: " + key
	var sources := _index(value.sources)
	var observations := _index(value.observations)
	var habitats := _index(value.habitats)
	var decisions := _index(value.reconstruction_decisions)
	if habitats.size() != HABITATS.size(): return "Expected four distinct habitats."
	for id in HABITATS:
		if not habitats.has(id): return "Missing habitat."
	for source in value.sources:
		for key in ["title", "role", "location", "locator", "review", "limits"]:
			if not source.get(key) is String or source[key].is_empty(): return "Source needs scope and review limits."
		if not _date(source.get("observation_period")): return "Invalid source observation period."
		if not source.has("publication_year"): return "Publication date must be explicit, including unknown."
		if source.publication_year != null and (not _number(source.publication_year, 1, 2100) or source.publication_year != floor(source.publication_year)): return "Invalid publication year."
	for observation in value.observations:
		if not sources.has(observation.get("source_id", "")) or not _date(observation.get("observation_date")): return "Observation needs its own source and date."
		for key in ["location", "habitat", "identification_confidence", "kind", "statement", "locator"]:
			if not observation.get(key) is String or observation[key].is_empty(): return "Incomplete observation."
	for habitat in value.habitats:
		var proposal: Variant = habitat.get("gameplay_proposal")
		if not proposal is Dictionary or proposal.get("status") != "proposed_not_active" or not proposal.get("effects") is Array or proposal.effects.is_empty(): return "Habitat mechanics remain proposals."
	for decision in value.reconstruction_decisions:
		if decision.get("target_year") != 1792 or decision.get("classification") != "reconstruction_inference" or decision.get("canonical_admission") != false: return "Reconstruction must remain an inference."
		if not habitats.has(decision.get("habitat_id", "")) or not _refs(decision.get("observation_ids"), observations): return "Unbound reconstruction."
		for key in ["decision", "identification_confidence", "placement_confidence"]:
			if not decision.get(key) is String or decision[key].is_empty(): return "Missing reconstruction decision/confidence."
		for id in decision.observation_ids:
			var observation: Dictionary = observations[id]
			if observation.kind != "historical_environment" or sources[observation.source_id].role not in ["historical_synthesis", "retrospective_account"]: return "Reference-only evidence cannot establish an opening habitat."
	var placed: Array = []
	for placement in value.placements:
		var location: Variant = placement.get("location")
		if not location is Dictionary or location.get("georeferenced") != false or location.get("frame") != value.frame: return "Placement is not georeferenced."
		if not location.get("position") is Array or location.position.size() != 3 or not location.get("footprint") is Array or location.footprint.size() != 2: return "Invalid placement geometry."
		for n in location.position:
			if not _number(n, -180, 180): return "Invalid position."
		for n in location.footprint:
			if not _number(n, 1, 30): return "Unbounded footprint."
		# Every mesh stays in its pocket (including crowns); leave a two-metre buffer outside the wall.
		if absf(location.position[0]) - location.footprint[0]/2 < 32 and absf(location.position[2]) - location.footprint[1]/2 < 32: return "Ecology pocket intrudes into the qualified playable cell."
		if not _number(placement.get("seed"), 0, 1000000) or placement.seed != floor(placement.seed): return "Invalid visual seed."
		for key in ["collision", "navigation", "gameplay_active"]:
			if placement.get(key) != false: return "Scenery cannot introduce gameplay authority."
		if not decisions.has(placement.get("reconstruction_decision_id", "")): return "Missing placement decision."
		if placement.get("habitat_id") != decisions[placement.reconstruction_decision_id].habitat_id: return "Placement/decision habitat mismatch."
		placed.append(placement.habitat_id)
	for id in HABITATS:
		if id not in placed: return "Mosaic is missing a placed habitat."
	for correction in value.taxonomic_corrections:
		if not observations.has(correction.get("observation_id", "")) or not sources.has(correction.get("authority_source_id", "")): return "Unbound taxonomic correction."
		if sources[correction.authority_source_id].role != "taxonomy_authority": return "Correction needs a taxonomic authority."
		for key in ["original_wording", "corrected_scientific_name", "corrected_common_name", "identification_confidence", "decision"]:
			if not correction.get(key) is String or correction[key].is_empty(): return "Preserve both original and corrected names."
	for issue in value.evidence_issues:
		if not _refs(issue.get("source_ids"), sources) or issue.get("opening_admission") != false or issue.get("status") != "unresolved_original_report_needed": return "Do not silently resolve conflicting chronology."
	var wildlife: Variant = value.get("wildlife_policy")
	if not wildlife is Dictionary or wildlife.get("placement_status") != "deferred" or wildlife.get("spawn_records") != [] or wildlife.get("abundance_claims") != []: return "No local wildlife placement or abundance has been established."
	if not _refs(wildlife.get("captive_observation_ids"), observations): return "Retain captive evidence limitation."
	for id in wildlife.captive_observation_ids:
		if observations[id].kind != "captive_animal": return "Captive evidence kind mismatch."
	var dolphin: Variant = wildlife.get("dolphin")
	if not dolphin is Dictionary or dolphin.get("local_placement_supported") != false or not observations.has(dolphin.get("observation_id", "")): return "Dolphin range is not local placement."
	if not dolphin.get("required_before_placement") is Array: return "Missing dolphin habitat requirements."
	for key in ["located_river_reach", "dated_range_evidence", "depth_evidence", "flow_evidence", "channel_connectivity_evidence"]:
		if key not in dolphin.required_before_placement: return "Missing dolphin habitat requirement."
	if value.get("default_season") not in SEASONS or value.get("season_authority") != "manual_visual_preview_only": return "Season is an explicit visual preview."
	if not value.get("season_profiles") is Dictionary or value.season_profiles.size() != SEASONS.size(): return "Missing season profiles."
	for id in SEASONS:
		var profile: Variant = value.season_profiles.get(id)
		if not profile is Dictionary: return "Missing season."
		for key in ["grass_color", "scrub_color", "soil_color", "water_color"]:
			if not profile.get(key) is String or profile[key].length() != 6 or not Color.html_is_valid(profile[key]): return "Invalid season color."
		for key in ["grass_height_scale", "vegetation_fraction", "water_extent"]:
			if not _number(profile.get(key), 0.1, 1.0): return "Invalid authored season parameter."
	return ""

func load_catalog() -> String:
	var text := FileAccess.get_file_as_string(PATH)
	var candidate: Variant = JSON.parse_string(text)
	var error := validate(candidate)
	if not error.is_empty(): return error
	manifest = candidate.duplicate(true)
	digest = text.sha256_text()
	return ""

func placement_evidence(id: String) -> Dictionary:
	for placement in manifest.get("placements", []):
		if placement.id != id: continue
		var decision: Dictionary = _index(manifest.reconstruction_decisions)[placement.reconstruction_decision_id]
		var sources := _index(manifest.sources)
		var observations := _index(manifest.observations)
		var records: Array = []
		for observation_id in decision.observation_ids:
			var observation: Dictionary = observations[observation_id]
			records.append({"source":sources[observation.source_id].duplicate(true), "observation":observation.duplicate(true)})
		return {"placement":placement.duplicate(true), "reconstruction_decision":decision.duplicate(true), "evidence":records}
	return {}

func notebook() -> String:
	var lines: PackedStringArray = ["PUNJAB ECOLOGY · RECONSTRUCTION STUDY", "Cultivated settlements, pasture, thorn scrub, grasslands and wet ground form a mosaic. Uncultivated land supported livelihoods.", "Exterior pockets use compressed scenery coordinates. They are not mapped 1792 sites; seasonal previews do not change the calendar or gameplay."]
	for placement in manifest.placements:
		var record := placement_evidence(placement.id)
		var habitat: Dictionary = _index(manifest.habitats)[placement.habitat_id]
		lines.append("\n" + habitat.label.to_upper() + "\n" + record.reconstruction_decision.decision)
		for evidence in record.evidence:
			var o: Dictionary = evidence.observation
			lines.append("Source: %s · %s\nObservation: %s · %s\nIdentification: %s" % [evidence.source.title, o.locator, o.observation_date.label, o.location, o.identification_confidence.replace("_", " ")])
		lines.append("Proposed mechanics (inactive): " + ", ".join(habitat.gameplay_proposal.effects))
	lines.append("\nNair: published 1978; principal fieldwork 1961-1966 in Indian Punjab/Haryana. Identification reference, not a local 1792 record.")
	lines.append("Original appendix: willow azadirachta indica. Kew identifies the scientific name as neem; the historical specimen remains unresolved.")
	lines.append("Captive tigers do not establish wild abundance. Dolphins require a located, connected river reach with suitable depth/flow and dated range evidence. No wildlife is spawned.")
	lines.append("Gujrat governance stays in the 1849-1947 layer. Fourth settlement report: article says 1918, BL catalogue says 1916; original report still needed.")
	return "\n\n".join(lines)
