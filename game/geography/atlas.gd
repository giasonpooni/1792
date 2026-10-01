# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only world/research registry. It neither owns a game clock nor admits scenery.
const Geo := preload("res://geography/geodesy.gd")
const PATH := "res://data/historical_world.v1.json"
const PLAN_PATH := "res://data/anthology.v1.json"
var _catalogue: Dictionary = {}
var _plan: Dictionary = {}
var digest := ""
var plan_digest := ""

static func interval(v: Variant) -> bool:
	return v is Dictionary and Geo.integer(v.get("from"), 1200, 1873) and Geo.integer(v.get("until"), 1201, 1874) and v.from < v.until

static func contains_year(v: Dictionary, year: int) -> bool:
	return interval(v) and year >= v.from and year < v.until

static func rectangle(v: Variant) -> bool:
	return v is Array and v.size()==4 and Geo.number(v[0]) and Geo.number(v[1]) and Geo.number(v[2]) and Geo.number(v[3]) and v[0]<v[2] and v[1]<v[3] and v[0]>=-180 and v[2]<=180 and v[1]>=-90 and v[3]<=90

static func validate(data: Variant) -> String:
	if not data is Dictionary or data.get("schema")!="historical-world.v1": return "Unsupported world catalogue."
	if data.get("metres_per_unit")!=1 or data.get("geodetic_datum")!=Geo.DATUM: return "One metre per unit and explicit WGS84 ellipsoidal heights are mandatory."
	if data.get("coordinate_order")!=["longitude","latitude","ellipsoidal_height_m"]: return "Ambiguous coordinate order."
	if not interval(data.get("epoch")) or not rectangle(data.get("bounds")): return "Invalid world extent."
	if data.get("macro_cell_degrees")!=1: return "Unsupported macro index (indexing is not distance)."
	if data.get("active_protagonist")!="ranjit_singh" or data.get("production_gate")!="childhood_to_lahore_prelude_then_full_life_before_dlc": return "Production boundary changed."
	var policy: Variant = data.get("religious_policy")
	if not policy is Dictionary or policy.get("figures_embodied")!=false or policy.get("site_interiors")!=false or policy.get("prayer")!="exterior_only": return "Religious presentation boundary changed."
	for key in ["sources","theatres","places","terrain_assets"]:
		if not data.get(key) is Array: return "Missing collection: "+key
	# This version records the acquisition gap, not pretend loaded terrain.
	if not data.terrain_assets.is_empty(): return "Raster promotion needs a separate verified asset receipt; this registry is not a terrain loader."
	var source_ids: Array = []
	for source in data.sources:
		if not source is Dictionary or not source.get("id") is String or source.id.is_empty() or source.id in source_ids: return "Duplicate/malformed source."
		for field in ["title","url","scope","rights"]:
			if not source.get(field) is String or (field!="url" and source[field].is_empty()): return "Source scope/rights required."
		source_ids.append(source.id)
	var theatres: Array = []
	for theatre in data.theatres:
		if not theatre is Dictionary or not theatre.get("id") is String or theatre.id in theatres or not rectangle(theatre.get("bounds")) or theatre.get("classification")!="authored_production_envelope_not_border": return "Malformed theatre or invented political boundary."
		theatres.append(theatre.id)
	var ids: Array = []
	for place in data.places:
		if not place is Dictionary or not place.get("id") is String or place.id.is_empty() or place.id in ids: return "Duplicate/malformed place identity."
		ids.append(place.id)
		if not place.get("label") is String or place.get("theatre") not in theatres or place.get("placement_class") not in ["A","B","C","D"]: return "Missing place classification."
		if place.get("kind") not in ["settlement","fort","crossing","route_node","battlefield","sacred_site"]: return "Unknown place kind."
		if not place.get("source_ids") is Array or place.source_ids.is_empty() or not place.get("periods") is Array or not place.get("importance") is Array: return "Unbound place record."
		for source in place.source_ids:
			if source not in source_ids: return "Unresolved place source."
		if place.get("uncertainty_m")!=null and (not Geo.number(place.uncertainty_m) or place.uncertainty_m<0): return "Invalid uncertainty."
		if place.get("anchor")!=null:
			var p: Variant = place.anchor
			if not p is Array or p.size()!=2 or not Geo.number(p[0]) or not Geo.number(p[1]): return "Malformed map anchor."
			if p[0]<data.bounds[0] or p[0]>=data.bounds[2] or p[1]<data.bounds[1] or p[1]>=data.bounds[3]: return "Anchor outside half-open production envelope."
		if place.get("geometry")!=null: return "No unverified geometry may be promoted by this point registry."
		for span in place.periods:
			if not interval(span) or not span.get("source_ids") is Array or span.source_ids.is_empty(): return "Unbound historical period."
			for source in span.source_ids:
				if source not in source_ids or source=="design": return "Design cannot verify historical presence."
		# Significance requires its own reviewed record; no invented default for famous sites.
		if not place.importance.is_empty(): return "Site-importance review is not yet admitted in this catalogue."
	return ""

func load_catalogue() -> String:
	var text := FileAccess.get_file_as_string(PATH)
	var candidate: Variant = JSON.parse_string(text)
	var error := validate(candidate)
	if not error.is_empty(): return error
	var plan_text := FileAccess.get_file_as_string(PLAN_PATH)
	var plan: Variant = JSON.parse_string(plan_text)
	if not plan is Dictionary or plan.get("schema")!="anthology-plan.v1" or not plan.get("campaigns") is Array: return "Malformed anthology plan."
	_catalogue=candidate.duplicate(true);_plan=plan.duplicate(true)
	digest=text.sha256_text();plan_digest=plan_text.sha256_text()
	return ""

func snapshot() -> Dictionary: return _catalogue.duplicate(true)
func plan() -> Dictionary: return _plan.duplicate(true)
func place(id: String) -> Dictionary:
	for item in _catalogue.get("places",[]):
		if item.id==id: return item.duplicate(true)
	return {}

func summary(id: String, year: int) -> String:
	var item := place(id)
	if item.is_empty(): return "Unknown place."
	var known := false
	for span in item.periods: known=known or contains_year(span,year)
	var text: String = item.label+" | "+item.kind+"\n"+item.note
	text += "\nYear %d: %s. Geometry: NOT ADMITTED. Site importance: NOT REVIEWED." % [year,"source supports broad period presence" if known else "period presence not established in this registry"]
	for source in _catalogue.sources:
		if source.id in item.source_ids: text += "\n"+source.title+": "+source.scope
	return text
