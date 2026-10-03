# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Pure, bounded account-transmission reducer. No canonical verdict or reward score.
const VERSION := "1792.oral-memory.v1"
const MODEL_ID := "situated-oral-memory.v1"
const CONTENT := "res://narrative/oral_memory/borrowed_rope.v1.json"
const MAX_EVENTS := 32
const RECALL_TICKS := 300 # Authored delay on the existing clock, not historical duration.
const Economy := preload("res://territory/misl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")
const SITES := {"quartermaster": Economy.QUARTERMASTER, "market": Economy.MARKET,
	"trace": Vector3(14,0.14,-4), "listener": Vector3(24,0.14,21)}
const OP_IDS := {"hear":"oral-memory.hear.v1", "observe":"oral-memory.observe.v1",
	"compare":"oral-memory.compare.v1", "ask":"oral-memory.ask-recall.v1", "retell":"oral-memory.retell.v1"}
const ENTRY_KEYS := ["speaker_id","speaker","site","channel","root_id","lineage","claim","text"]
static var _cached_content: Dictionary={}
static var _cached_digest: String=""
const EVENT_KEYS := ["seq","tick","kind","operation_id","subject_id","parent_seq","actor_id","position"]

static func content() -> Dictionary:
	if _cached_digest.is_empty():
		var text:=FileAccess.get_file_as_string(CONTENT)
		var value: Variant=JSON.parse_string(text)
		_cached_content=value if value is Dictionary else {}
		_cached_digest=text.sha256_text()
	return _cached_content.duplicate(true)

static func content_digest() -> String:
	if _cached_digest.is_empty(): content()
	return _cached_digest

static func content_error(c: Dictionary) -> String:
	if c.size()!=7 or c.get("schema")!="1792.oral-memory-content.v1" or c.get("episode_id")!="borrowed_rope" or c.get("historical_class")!="authored_fiction":
		return "Unrecognized oral-memory content identity."
	# The title and note are authoring data, never evidence that a story happened.
	for key in ["title","authoring_note"]:
		if not c.get(key) is String or c[key].is_empty(): return "Missing oral-memory authoring metadata."
	if not c.get("tellings") is Dictionary or c.tellings.size()!=4: return "Invalid telling catalogue."
	for id in ["quartermaster_account","trader_account","well_echo","quartermaster_reflection"]:
		if not c.tellings.get(id) is Dictionary: return "Missing declared telling."
		var t: Dictionary=c.tellings[id]
		if t.size()!=ENTRY_KEYS.size(): return "Unexpected telling fields."
		for key in ENTRY_KEYS:
			if not t.has(key): return "Incomplete telling."
			if key!="lineage" and (not t[key] is String or t[key].is_empty() or t[key].length()>1500): return "Invalid telling text."
		if not SITES.has(t.site) or t.channel not in ["remembered_testimony","attributed_hearsay"]: return "Invalid telling channel or site."
		if not t.lineage is Array or t.lineage.is_empty() or t.lineage.size()>8: return "Invalid source lineage."
		for label in t.lineage:
			if not label is String or label.is_empty() or label.length()>160: return "Invalid lineage label."
	if c.tellings.trader_account.root_id!=c.tellings.well_echo.root_id: return "An echo must retain its original source root."
	if c.tellings.quartermaster_account.root_id!=c.tellings.quartermaster_reflection.root_id: return "A recollection must retain its original source root."
	if not c.get("trace") is Dictionary or c.trace.size()!=3 or c.trace.get("id")!="rope_trace" or c.trace.get("site")!="trace" or not c.trace.get("text") is String: return "Invalid material trace."
	return ""

static func initial() -> Dictionary:
	return {"heard":{},"trace_seq":0,"compared_seq":0,"requested_seq":0,"requested_tick":-1,"retellings":{}}

static func site(kind: String, subject: String, c: Dictionary) -> String:
	match kind:
		"hear": return str(c.tellings[subject].site) if c.tellings.has(subject) else ""
		"observe": return "trace" if subject=="rope_trace" else ""
		"ask": return "quartermaster" if subject=="quartermaster_reflection" else ""
		"retell": return "listener" if subject in ["quartermaster_account","comparison"] else ""
	return ""

static func near(p: Vector3, site_id: String) -> bool:
	if not SITES.has(site_id): return false
	var at: Vector3=SITES[site_id]
	return Base.distance(p,at)<=3.0 and absf(p.y-at.y)<=0.65

static func parent_for(s: Dictionary, kind: String, subject: String) -> int:
	if kind=="hear" and subject=="quartermaster_reflection": return int(s.requested_seq)
	if kind=="ask" or (kind=="retell" and subject=="comparison"): return int(s.compared_seq)
	if kind=="retell": return int(s.heard.get(subject,{}).get("seq",0))
	return 0

static func apply(s: Dictionary, e: Dictionary, c: Dictionary) -> String:
	# Caller supplies a detached candidate and a shape-checked receipt.
	var kind: String=e.kind
	var subject: String=e.subject_id
	if int(e.parent_seq)!=parent_for(s,kind,subject): return "Retelling or recall lost its source receipt."
	match kind:
		"hear":
			if not c.tellings.has(subject): return "Unknown telling."
			if s.heard.has(subject): return "This telling is already remembered; revisiting it adds no evidence."
			if subject=="quartermaster_reflection" and (s.requested_tick<0 or e.tick<s.requested_tick+RECALL_TICKS): return "The quartermaster has not recalled more yet. Return and listen after a little time."
			s.heard[subject]={"seq":int(e.seq),"tick":int(e.tick)}
		"observe":
			if subject!="rope_trace" or s.trace_seq!=0: return "No new trace to record."
			s.trace_seq=int(e.seq)
		"compare":
			if subject!="borrowed_rope" or s.compared_seq!=0: return "No new comparison to record."
			if not s.heard.has("quartermaster_account") or not s.heard.has("trader_account"): return "First hear both accounts from their speakers."
			s.compared_seq=int(e.seq)
		"ask":
			if subject!="quartermaster_reflection" or s.requested_seq!=0: return "This further recollection has already been requested."
			if s.compared_seq==0 or s.trace_seq==0: return "Compare the two accounts and inspect the rope before asking this question."
			if e.tick>10000000-RECALL_TICKS: return "The bounded chapter has insufficient time for this recollection."
			s.requested_seq=int(e.seq)
			s.requested_tick=int(e.tick)
		"retell":
			if subject not in ["quartermaster_account","comparison"] or s.retellings.has(subject): return "That telling has already reached this listener, or is unavailable."
			if int(e.parent_seq)==0: return "You cannot retell an account or comparison you have not received."
			s.retellings[subject]={"seq":int(e.seq),"tick":int(e.tick),"parent_seq":int(e.parent_seq)}
		_: return "Unsupported oral-memory operation."
	return ""

static func project(events: Array, c: Dictionary) -> Dictionary:
	var s:=initial()
	for e in events:
		if not apply(s,e,c).is_empty(): return {} # Never publish a partially replayed result.
	return s

static func validate(value: Variant, tick: int, earliest: int, c: Dictionary) -> String:
	var error:=content_error(c)
	if not error.is_empty(): return error
	if not value is Dictionary or value.size()!=5 or value.get("schema")!=VERSION or value.get("model_id")!=MODEL_ID or value.get("content_digest")!=content_digest(): return "Oral-memory version or content binding changed."
	if not Economy.whole(value.get("origin_tick"),earliest,tick) or not value.get("events") is Array or value.events.is_empty() or value.events.size()>MAX_EVENTS: return "Invalid oral-memory event bounds."
	var s:=initial()
	var previous: int=int(value.origin_tick)
	for index in range(value.events.size()):
		var e: Variant=value.events[index]
		if not e is Dictionary or e.size()!=EVENT_KEYS.size(): return "Malformed oral-memory receipt."
		for key in EVENT_KEYS:
			if not e.has(key): return "Missing oral-memory receipt field."
		if not Economy.whole(e.seq,index+1,index+1) or not Economy.whole(e.tick,previous,tick) or not Economy.whole(e.parent_seq,0,index): return "Oral-memory order, time or ancestry is invalid."
		if index==0 and e.tick!=value.origin_tick: return "Oral-memory origin does not match its first receipt."
		if not e.kind is String or not OP_IDS.has(e.kind) or e.operation_id!=OP_IDS[e.kind] or not e.subject_id is String or e.actor_id!="ranjit_singh": return "Oral-memory operation or actor identity changed."
		if not Base.valid_point(e.position): return "Invalid oral-memory receipt location."
		if e.kind!="compare" and not near(Base.point(e.position),site(e.kind,e.subject_id,c)): return "Oral-memory receipt did not occur at its speaker or trace."
		error=apply(s,e,c)
		if not error.is_empty(): return error
		previous=int(e.tick)
	return ""

static func roots(s: Dictionary, c: Dictionary) -> Array:
	var result: Array=[]
	for id in s.heard:
		var root: String=c.tellings[id].root_id
		if root not in result: result.append(root)
	return result # Distinct reported origins, NOT calibrated independent evidence.
