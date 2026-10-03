extends RefCounted
## Copyright (c) 2026 Cartesian Graphics. All rights reserved.
## Original fictional encounter rules, not a reconstruction of a recorded incident.
## Pure bounded transitions; the scene supplies actual collision/motion observations.
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const VERSION := "missing-remounts.v1"
const MAX_EVENTS := 48
const PICKUP_DELAY := 60
const REPORT_DELAY := 120
const SEARCH_TICKS := 600
const SPEED := 2.4
const POST := Vector3(24,0.14,10)
const RUNNER_START := Vector3(13,0.14,23)
const NOTE := Vector3(-5.5,0.14,22.5)
const HITCH := Vector3(4,0.14,24)
const OBSERVERS := {
	"yard_gatekeeper":{"position":Vector3(11,0.14,21),"forward":Vector3.LEFT,"familiar":true},
	"yard_keeper":{"position":Vector3(-7,0.14,25.5),"forward":Vector3.FORWARD,"familiar":false}}
const WORDS := {
	"begin":{"source_id":"fictional_quartermaster","channel":"spoken_request","text":"Two expected remounts have not reached our store. Ask the market handler about the yard behind the southern wall. Bring an account, not an accusation."},
	"introduction":{"source_id":"fictional_market_handler","channel":"testimony","text":"The horses may be waiting in the southern yard. Tell the gatekeeper I sent you. I did not see who ordered the delay."},
	"permission":{"source_id":"yard_gatekeeper","channel":"spoken_permission","text":"You have the handler's introduction. You may examine the horses and bring the sealed tally to your quartermaster."},
	"note":{"source_id":"self","channel":"observed","text":"I took the sealed transfer tally. I cannot read its words; I must hear them read aloud."},
	"horses":{"source_id":"self","channel":"observed","text":"I saw two tethered horses carrying the expected cord marks. Their presence does not tell me who caused the delay."},
	"resolve":{"source_id":"fictional_quartermaster","channel":"read_aloud","text":"The tally says the horses were held after a cart axle failed. That is the yard's account, not independent proof. You located the batch; collection remains the adults' responsibility. No culprit has been established."}}

static func agent(id: String,at: Vector3) -> Dictionary:
	return {"id":id,"position":Base.coords(at),"yaw":0.0,"velocity":[0.0,0.0,0.0]}

static func initial() -> Dictionary:
	var contacts: Dictionary={}
	for id in OBSERVERS:
		contacts[id]={"heard_tick":-1,"seen_tick":-1,"identified_tick":-1,"place":[]}
	return {"introduced":false,"permission":false,"note":false,"horses":false,"resolved":false,
		"contacts":contacts,"recipient_knowledge":[],
		"report":{"stage":"none","sender":"","root_event":0,"opened_tick":-1,
			"collected_tick":-1,"delivered_tick":-1,"subject":"","place":[]},
		"response":{"stage":"reserve","reserve":1,"target":[],"arrived_tick":-1},
		"relations":{"market_handler":{"trust":0,"obligation":0},"yard_custodians":{"trust":0,"grievance":0,"recognition":0}},
		"resolution_context":"","memories":[]}

static func in_yard(p: Vector3) -> bool:
	return p.x>-10 and p.x<10 and p.z>17 and p.z<27

static func sense(id: String,p: Vector3,speed: float,clear: bool) -> Dictionary:
	# A ray alone neither recognizes a face nor grants social access.
	var o: Dictionary=OBSERVERS[id]
	var offset: Vector3=p-o.position
	offset.y=0
	var distance: float=offset.length()
	var seen: bool=clear and distance<=12 and (distance<0.01 or o.forward.dot(offset.normalized())>=0.35)
	return {"heard":speed>3.0 and distance<=(5.0 if clear else 1.5),
		"seen":seen,"identified":seen and o.familiar and distance<=6.0}

static func _keys(d: Variant,names: Array) -> bool:
	if not d is Dictionary or d.size()!=names.size(): return false
	for key in names:
		if not d.has(key): return false
	return true

static func _remember(s: Dictionary,kind: String,tick: int) -> void:
	var m: Dictionary=WORDS[kind].duplicate(true)
	m.id="remounts_"+kind
	m.received_tick=tick
	s.memories.append(m)

static func apply(s: Dictionary,e: Dictionary) -> String:
	var kind: String=e.kind
	var d: Dictionary=e.detail
	var tick: int=int(e.tick)
	if kind in ["begin","introduction","permission","note","horses","resolve","response_return"] and not d.is_empty():
		return "Unexpected action payload."
	match kind:
		"begin":
			if not s.memories.is_empty(): return "Investigation already begun."
		"introduction":
			if s.introduced: return "This is the same introduction, not another witness."
			s.introduced=true
			s.relations.market_handler.obligation=1
		"permission":
			if not s.introduced or s.permission: return "The gatekeeper needs the handler's introduction; permission is granted once."
			s.permission=true
			s.relations.yard_custodians.trust=1
		"note", "horses":
			if s[kind] or s.resolved: return "This observation is already retained."
			s[kind]=true
		"resolve":
			if not s.note or not s.horses or s.resolved: return "Examine the horses and bring their sealed tally before giving your account."
			s.resolved=true
			s.resolution_context="introduced_visit" if s.permission else "unpermitted_visit"
			s.relations.market_handler.trust=1 if s.introduced else 0
		"heard", "seen", "identified":
			if not _keys(d,["observer","place"]) or not OBSERVERS.has(d.observer) or not Base.valid_point(d.place):
				return "Malformed local perception."
			var c: Dictionary=s.contacts[d.observer]
			var field: String=kind+"_tick"
			if c[field]>=0: return "Repeated perception is not independent corroboration."
			if kind!="heard":
				var at:=Base.point(d.place)
				var bounded:=sense(d.observer,at,0,true)
				if not in_yard(at) or not bounded.seen: return "Visual contact exceeds the authored sensor geometry."
				if kind=="identified" and (c.seen_tick<0 or not bounded.identified): return "No supported visual identification."
			c[field]=tick
			# Sound is stored as an approximate yard location, never a precise unseen actor pose.
			if kind=="heard" and d.place!=Base.coords(HITCH): return "Sound must retain the coarse yard location."
			if kind!="heard" or c.seen_tick<0: c.place=d.place.duplicate()
			if not s.permission and s.report.stage=="none":
				s.report.stage="queued"
				s.report.sender=d.observer
				s.report.opened_tick=tick
				s.report.root_event=int(e.seq)
		"collect":
			if not _keys(d,["position"]) or not Base.valid_point(d.position): return "Malformed messenger handover."
			if s.report.stage!="queued" or tick<s.report.opened_tick+PICKUP_DELAY: return "The witness has not handed the account over yet."
			if Base.distance(Base.point(d.position),OBSERVERS[s.report.sender].position)>2.2: return "Messenger must reach the actual witness."
			var c: Dictionary=s.contacts[s.report.sender]
			s.report.subject=Base.Names.HERO_ID if c.identified_tick>=0 else ""
			s.report.place=c.place.duplicate()
			s.report.collected_tick=tick
			s.report.stage="in_transit"
		"deliver":
			if not _keys(d,["position"]) or not Base.valid_point(d.position): return "Malformed report delivery."
			if s.report.stage!="in_transit" or tick<s.report.collected_tick+REPORT_DELAY: return "Report is still in transit."
			if Base.distance(Base.point(d.position),POST)>2.2: return "Report must physically reach the duty post."
			s.report.stage="delivered"
			s.report.delivered_tick=tick
			s.recipient_knowledge.append({"root_event":s.report.root_event,"sender":s.report.sender,"subject":s.report.subject,"place":s.report.place.duplicate(),"received_tick":tick})
			if s.report.subject!="":
				s.relations.yard_custodians.grievance=1
				s.relations.yard_custodians.recognition=1
			# One authored yard reserve, NOT the player's hired garrison or an infinite spawn.
			s.response.reserve=0
			s.response.stage="travelling"
			s.response.target=s.report.place.duplicate()
		"response_arrive":
			if not _keys(d,["position"]) or not Base.valid_point(d.position): return "Malformed search arrival."
			if s.response.stage!="travelling" or Base.distance(Base.point(d.position),Base.point(s.response.target))>2.2: return "Searcher has not reached the reported location."
			s.response.stage="searching"
			s.response.arrived_tick=tick
		"response_return":
			if s.response.stage!="searching" or tick<s.response.arrived_tick+SEARCH_TICKS: return "The bounded local search is not over."
			s.response.stage="returning"
		"response_home":
			if not _keys(d,["position"]) or not Base.valid_point(d.position): return "Malformed reserve return."
			if s.response.stage!="returning" or Base.distance(Base.point(d.position),POST)>2.2: return "Searcher must physically return to the duty post."
			s.response.stage="complete"
			s.response.reserve=1
		_:
			return "Unknown remount encounter event."
	if WORDS.has(kind): _remember(s,kind,tick)
	return ""

static func replay(events: Variant,origin: int,now: int) -> Dictionary:
	if not events is Array or events.is_empty() or events.size()>MAX_EVENTS: return {"error":"Missing or excessive encounter events."}
	var state:=initial()
	var prior:=origin
	for i in range(events.size()):
		var e: Variant=events[i]
		if not _keys(e,["seq","tick","kind","detail"]) or not e.kind is String or not e.detail is Dictionary:
			return {"error":"Malformed encounter event."}
		if not Supply.whole(e.seq,1) or e.seq!=i+1 or not Supply.whole(e.tick,prior,now): return {"error":"Unordered, fractional or future encounter event."}
		if i==0 and (e.kind!="begin" or e.tick!=origin): return {"error":"Encounter has no bound beginning."}
		if i>0 and e.kind=="begin": return {"error":"Repeated beginning."}
		var error:=apply(state,e)
		if not error.is_empty(): return {"error":error}
		prior=int(e.tick)
	return {"error":"","ledger":state}

static func valid_agent(value: Variant,id: String) -> bool:
	if not _keys(value,["id","position","yaw","velocity"]) or value.id!=id: return false
	return Base.valid_point(value.position) and Supply.valid_velocity(value.velocity) and Supply.finite_number(value.yaw) and absf(value.yaw)<=PI and Vector2(value.velocity[0],value.velocity[2]).length()<=SPEED+0.01

static func validate(value: Variant,now: int) -> String:
	if not _keys(value,["schema","origin_tick","events","ledger","runner","responder"]) or value.schema!=VERSION:
		return "Unsupported remount state."
	if not Supply.whole(value.origin_tick,0,now): return "Invalid remount beginning."
	var result:=replay(value.events,int(value.origin_tick),now)
	if not result.error.is_empty(): return result.error
	if not Supply._equal(value.ledger,result.ledger): return "Encounter outcomes do not match retained events."
	if not valid_agent(value.runner,"yard_runner") or not valid_agent(value.responder,"yard_reserve"):
		return "Invalid remount encounter motion."
	# Idle bodies may settle vertically onto their actual collision floor.
	if value.ledger.report.stage=="none" and Base.distance(Base.point(value.runner.position),RUNNER_START)>0.001: return "Undeployed messenger moved."
	if value.ledger.response.stage=="reserve" and Base.distance(Base.point(value.responder.position),POST)>0.001: return "Undeployed reserve moved."
	return ""
