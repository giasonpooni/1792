# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored game rules, not theology or validated social science. No RNG or clock owner.
const Geo := preload("res://geography/geodesy.gd")
const VERSION := "exterior-fortune.v1"
const MAX_EVENTS := 128
const COOLDOWN := 3600
const SITE_COOLDOWN := 216000
const DURATION := 18000
const MAX_TICK := 9007199254720000
const BENEFITS := ["help","warning","supply_find","wound_recovery"]
const HAZARDS := ["betrayal","assassination","desertion"]

static func site_error(s: Variant) -> String:
	if not s is Dictionary or not s.get("id") is String or s.id.is_empty(): return "Invalid site identity."
	if s.get("interior_enterable")!=false or s.get("figures_embodied")!=false: return "Religious sites are exterior-only without embodied religious figures."
	if not Geo.integer(s.get("importance"),1,5) or not Geo.integer(s.get("from"),1200,1873) or not Geo.integer(s.get("until"),1201,1874) or s.from>=s.until: return "Invalid importance or epoch."
	if not s.get("evidence_scope") is String or s.evidence_scope.is_empty() or s.get("classification") not in ["synthetic:qualification","reviewed:gameplay"]: return "Missing significance provenance."
	if not s.get("frame_id") is String or s.frame_id.is_empty() or not Geo.triple(s.get("size_m")) or not Geo.triple(s.get("prayer_at_m")): return "Missing metric frame/geometry."
	for axis in s.size_m:
		if axis<=0 or axis>100: return "Unsupported exterior test volume."
	if s.size_m[1]<3: return "A protected enclosure must cover the actor capsule."
	if absf(s.prayer_at_m[0])<=s.size_m[0]/2.0 and absf(s.prayer_at_m[2])<=s.size_m[2]/2.0: return "Prayer anchor must lie outside the footprint."
	return ""

static func content_digest(sites: Dictionary) -> String:
	# Stable semantic site records plus exact rule source. This is compatibility, not authentication.
	if sites.is_empty() or sites.size()>128: return ""
	for key in sites:
		if not key is String or not site_error(sites[key]).is_empty() or sites[key].id!=key: return ""
	var ids: Array=sites.keys();ids.sort()
	var records: Array=[]
	for id in ids:
		var s: Dictionary=sites[id]
		var size_m: Array=[];var at: Array=[]
		for axis in range(3): size_m.append(float(s.size_m[axis]));at.append(float(s.prayer_at_m[axis]))
		records.append([id,int(s.importance),int(s.from),int(s.until),false,false,s.classification,s.evidence_scope,s.frame_id,size_m,at])
	var source:=FileAccess.get_file_as_string("res://geography/fortune_rules.gd")
	if source.is_empty(): return ""
	return JSON.stringify([VERSION,source.sha256_text(),records]).sha256_text()

static func initial(content_digest: String) -> Dictionary:
	return {"schema":VERSION,"content_digest":content_digest,"events":[]}

static func empty_ledger() -> Dictionary:
	return {"conduct":0,"prayer_credit":0,"last_prayer":-SITE_COOLDOWN,"site_visits":{},"luck":0.0,"expires":0}

static func replay(value: Variant, sites: Dictionary, digest: String, now: int) -> Dictionary:
	if not value is Dictionary or value.size()!=3 or value.get("schema")!=VERSION or value.get("content_digest")!=digest or digest!=content_digest(sites) or (digest.length()!=64 or not digest.is_valid_hex_number()) or not value.get("events") is Array or value.events.size()>MAX_EVENTS or now<0 or now>MAX_TICK:
		return {"error":"Malformed or incompatible fortune receipt stream."}
	var ledger := empty_ledger()
	var previous := -1
	for i in range(value.events.size()):
		var event: Variant = value.events[i]
		if not event is Dictionary or not Geo.integer(event.get("seq"),1,MAX_EVENTS) or event.get("seq")!=i+1 or not Geo.integer(event.get("tick"),0,now) or event.tick<previous: return {"error":"Invalid fortune receipt ordering."}
		previous=int(event.tick)
		if event.get("kind")=="conduct":
			if event.size()!=5 or not Geo.integer(event.get("delta"),-20,20) or event.delta==0 or not event.get("reason_id") is String or event.reason_id.is_empty(): return {"error":"Invalid conduct operation."}
			ledger.conduct=clampi(ledger.conduct+int(event.delta),-100,100)
		elif event.get("kind")=="prayer":
			if event.size()!=5 or not event.get("site_id") is String or not sites.has(event.site_id) or not Geo.integer(event.get("year"),1200,1873): return {"error":"Invalid site operation."}
			var site: Variant = sites[event.site_id]
			var error := site_error(site)
			if not error.is_empty() or site.id!=event.site_id: return {"error":"Unknown or invalid site definition."}
			if event.year<site.from or event.year>=site.until: return {"error":"Site significance does not belong to this epoch."}
			var last: Dictionary = ledger.site_visits.get(site.id,{"tick":-SITE_COOLDOWN,"count":0})
			if event.tick-ledger.last_prayer<COOLDOWN or event.tick-last.tick<SITE_COOLDOWN: return {"error":"Prayer recovery is not available yet."}
			var repeats: float = 1.0/(1.0+last.count)
			var consistency: float = clampf(1.0+ledger.conduct/200.0,0.5,1.5)
			var benefit: float = minf(0.10,0.02*site.importance*repeats*consistency)
			if event.tick>=ledger.expires or benefit>=ledger.luck:
				ledger.luck=benefit;ledger.expires=int(event.tick)+DURATION
			# A weaker visit does NOT extend a stronger site's effect.
			ledger.last_prayer=int(event.tick)
			ledger.site_visits[site.id]={"tick":int(event.tick),"count":int(last.count)+1}
			ledger.prayer_credit=mini(10,ledger.prayer_credit+1)
		else: return {"error":"Unknown fortune operation."}
	return {"error":"","ledger":ledger}

static func append(value: Dictionary, operation: Dictionary, sites: Dictionary, digest: String, now: int) -> Dictionary:
	var before := replay(value,sites,digest,now)
	if not before.error.is_empty(): return before
	if value.events.size()>=MAX_EVENTS: return {"error":"Fortune receipt budget exhausted."}
	var candidate: Dictionary = value.duplicate(true)
	var event: Dictionary = operation.duplicate(true)
	event.seq=candidate.events.size()+1;event.tick=now
	candidate.events.append(event)
	var after := replay(candidate,sites,digest,now)
	return after if not after.error.is_empty() else {"error":"","state":candidate,"ledger":after.ledger}

static func karma(ledger: Dictionary) -> int:
	return clampi(int(ledger.conduct)+int(ledger.prayer_credit),-100,100)

static func luck(ledger: Dictionary, now: int) -> float:
	return float(ledger.luck) if now<int(ledger.expires) else 0.0

static func ledger_error(ledger: Dictionary, now: int) -> String:
	if now<0 or now>MAX_TICK or not Geo.integer(ledger.get("conduct"),-100,100) or not Geo.integer(ledger.get("prayer_credit"),0,10): return "Invalid conduct/time ledger."
	if not Geo.number(ledger.get("luck")) or ledger.luck<0 or ledger.luck>0.1 or not Geo.integer(ledger.get("expires"),0,MAX_TICK+DURATION): return "Invalid effect ledger."
	return ""

static func probability(kind: String, base: float, ledger: Dictionary, now: int, opportunity: float=1.0, grievance: float=0.0, fixed_history: bool=false) -> Dictionary:
	var error:=ledger_error(ledger,now)
	if not error.is_empty(): return {"error":error}
	if kind not in BENEFITS and kind not in HAZARDS: return {"error":"No luck modifier for this event class."}
	for v in [base,opportunity,grievance]:
		if not is_finite(v) or v<0 or v>1: return {"error":"Invalid probability input."}
	# Impossible/certain or fixed historical events remain unchanged. Luck does not make weather or assassins appear.
	if fixed_history or base==0 or base==1: return {"error":"","probability":base}
	var adjustment: float = luck(ledger,now)
	var k: float = karma(ledger)/100.0
	var result: float
	if kind in HAZARDS:
		result=base*opportunity*clampf(1.0-0.25*k+0.5*grievance-adjustment,0.5,1.75)
	else: result=base+(1.0-base)*adjustment
	return {"error":"","probability":clampf(result,0.0,1.0)}
