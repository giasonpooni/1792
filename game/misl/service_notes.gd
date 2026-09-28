# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
const PATH:="res://data/sukerchakia_service.v1.json"
const Rules:=preload("res://misl/service_rules.gd")
static func validate(v: Variant) -> String:
	if not Rules.fields(v,["schema","year","sources","claims","nodes","relations","limits"]): return "Invalid Misl catalogue."
	if v.schema!="sukerchakia-context.v1" or typeof(v.year) not in [TYPE_INT,TYPE_FLOAT] or v.year!=1792: return "Unsupported period."
	for key in ["sources","claims","nodes","relations","limits"]:
		if not v[key] is Array or v[key].is_empty() or v[key].size()>32: return "Unbounded/missing context."
	var sources: Array=[];var claims: Array=[];var nodes: Dictionary={}
	for s in v.sources:
		if not Rules.fields(s,["id","title","url","scope"]): return "Invalid source fields."
		for key in s:
			if not s[key] is String or s[key].is_empty() or s[key].length()>1500: return "Invalid source text."
		if s.id in sources or not s.url.begins_with("https://"): return "Duplicate/unsupported source."
		sources.append(s.id)
	for c in v.claims:
		if not Rules.fields(c,["id","source_id","statement","limit"]) or not c.id is String or c.id.is_empty() or c.id in claims or c.source_id not in sources: return "Invalid claim reference."
		for key in ["statement","limit"]:
			if not c[key] is String or c[key].is_empty() or c[key].length()>2000: return "Invalid claim text."
		claims.append(c.id)
	for n in v.nodes:
		if not Rules.fields(n,["id","kind","label"]) or not n.id is String or n.id.is_empty() or n.id in nodes: return "Invalid node."
		if n.kind not in ["person","household","misl","place","service_detail"] or not n.label is String or n.label.is_empty(): return "Invalid node kind."
		nodes[n.id]=n.kind
	if nodes.get("ranjit_singh")!="person" or nodes.get("sukerchakia")!="household" or nodes.get("sukerchakia_misl")!="misl": return "Person, household and Misl must remain distinct."
	for r in v.relations:
		if not Rules.fields(r,["from","to","relation","claim_id","basis"]) or not nodes.has(r.from) or not nodes.has(r.to) or r.claim_id not in claims: return "Dangling relation."
		if r.basis not in ["source_context","authored_model"] or r.relation not in ["home_context","headquarters_context","service_context"]: return "Unsupported relation claim."
		var pair: Array=[nodes[r.from],nodes[r.to]]
		if r.relation=="headquarters_context" and pair!=["misl","place"]: return "Misl headquarters is not kinship."
		if r.relation=="home_context" and pair!=["person","household"]: return "Home relation type mismatch."
		if r.relation=="service_context" and (pair!=["household","misl"] and pair!=["service_detail","household"]): return "Service does not imply identity."
	for item in v.limits:
		if not item is String or item.is_empty() or item.length()>1500: return "Invalid limitation."
	return ""
static func notebook() -> String:
	var file:=FileAccess.open(PATH,FileAccess.READ)
	if file==null or file.get_length()>32768: return "Misl catalogue missing or exceeds budget."
	var raw:=file.get_as_text()
	var v: Variant=JSON.parse_string(raw)
	var error:=validate(v)
	if not error.is_empty(): return error
	var out: Array[String]=["SUKERCHAKIA · DEVELOPMENT RESEARCH, NOT BUDDH'S KNOWLEDGE","Catalogue SHA256: "+raw.sha256_text(),""]
	for n in v.nodes: out.append(n.kind+": "+n.label+" ["+n.id+"]")
	for r in v.relations: out.append(r.from+" --"+r.relation+"--> "+r.to+" ("+r.basis+")")
	for c in v.claims: out.append("\n"+c.statement+"\nLimit: "+c.limit)
	for text in v.limits: out.append("\nNOT CLAIMED: "+text)
	for source in v.sources: out.append("\n"+source.title+"\n"+source.url+"\n"+source.scope)
	return "\n".join(out)
