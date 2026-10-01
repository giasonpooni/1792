# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original, bounded nonlethal bazaar encounter. All timings and actors are authored.
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Fields := preload("res://misl/service_rules.gd")
const Catalogue := preload("res://youth/catalogue.gd")
const VERSION := "1792.bazaar-brawl.v1"
const STORY_ID := "bhangi_market_brawl"
const MAX_EVENTS := 96
const SPEED := 3.2
const RING := Vector3(-12,0.14,-19)
const REGROUP := Vector3(2,0.14,-10)
const IDS := ["fictional_bazaar_challenger","fictional_bazaar_second","fictional_bazaar_third","fictional_youth_mela","fictional_youth_jiva"]
const POSITIONS := [Vector3(-12,0.14,-20.5),Vector3(-15,0.14,-22),Vector3(-9,0.14,-22),Vector3(-25,0.14,-12),Vector3(-25,0.14,-14)]
const PHASES := ["none","invited","challenged","fighting","leaving","returning","reported","caught"]
static func initial() -> Dictionary:
	return {"phase":"none","start_tick":-1,"hits":0,"down":[false,false,false],"stun_until":[-1,-1,-1],"last_attack":[-1,-1,-1],"outcome":"","memories":[]}
static func actors() -> Array:
	var out: Array=[]
	for i in range(5): out.append({"id":IDS[i],"position":Base.coords(POSITIONS[i]),"yaw":0.0,"velocity":[0.0,0.0,0.0]})
	return out
static func attack_phase(tick: int,start: int,index: int) -> int: return posmod(tick-start-index*45,180)
static func whole(value: Variant,lo: int=-1,hi: int=10000000) -> bool:
	return Supply.finite_number(value) and value==floor(value) and value>=lo and value<=hi
static func valid_velocity(value: Variant) -> bool:
	if not value is Array or value.size()!=3: return false
	for n in value:
		if not Supply.finite_number(n): return false
	return value[1]>=-50 and value[1]<=0 and Vector2(value[0],value[2]).length()<=SPEED+0.02
static func valid_actor(a: Variant,index: int) -> bool:
	return Fields.fields(a,["id","position","yaw","velocity"]) and a.id==IDS[index] and Base.valid_point(a.position) and valid_velocity(a.velocity) and Supply.finite_number(a.yaw) and absf(a.yaw)<=PI and Vector2(a.velocity[0],a.velocity[2]).length()<=SPEED+0.02
static func memory(s: Dictionary,id: String,tick: int,source: String,channel: String,text: String) -> void:
	s.memories.append({"id":"youth-bazaar-"+id,"received_tick":tick,"source_id":source,"channel":channel,"text":text})
static func apply(s: Dictionary,e: Dictionary) -> String:
	if not Fields.fields(e,["seq","tick","kind","index","at","positions"]): return "Malformed bazaar receipt."
	if not whole(e.seq,1,MAX_EVENTS) or not whole(e.tick,0) or not whole(e.index,-1,2) or not e.kind is String or not Base.valid_point(e.at): return "Invalid bazaar receipt values."
	if not e.positions is Array or e.positions.size()!=5: return "Missing encounter participants."
	for p in e.positions:
		if not Base.valid_point(p): return "Invalid participant position."
	var at:=Base.point(e.at)
	var tick:=int(e.tick)
	var i:=int(e.index)
	if e.kind not in ["parry","hit","counter"] and i!=-1: return "Unexpected combat target."
	match e.kind:
		"invite":
			if s.phase!="none" or Base.distance(at,Supply.MARKET)>3: return "Hear the friends at the market once."
			s.phase="invited"
			memory(s,"invite",tick,"fictional_youth_mela","spoken","Mela asked me to walk with him and Jiva to the open ground beside the bazaar.")
		"challenge":
			if s.phase!="invited" or Base.distance(at,Base.point(e.positions[0]))>3.2: return "Approach the challenger on foot."
			for friend in [3,4]:
				if Base.distance(at,Base.point(e.positions[friend]))>5: return "Bring both friends to the encounter."
			s.phase="challenged"
			memory(s,"challenge",tick,IDS[0],"spoken","The challenger named the Bhangi party and mocked my eye and our small company.")
		"stand","leave":
			if s.phase!="challenged" or Base.distance(at,Base.point(e.positions[0]))>3.2: return "Answer the nearby challenger."
			s.phase="fighting" if e.kind=="stand" else "leaving"
			if e.kind=="stand": s.start_tick=tick
		"parry","hit","counter":
			if s.phase!="fighting" or i<0 or s.down[i] or Base.distance(at,Base.point(e.positions[i]))>2.85: return "No nearby active combat target."
			if e.kind=="counter":
				if s.stun_until[i]<tick or s.stun_until[i]<0 or tick<=s.last_attack[i]: return "Counter only a checked strike."
				s.down[i]=true;s.stun_until[i]=-1
			else:
				if attack_phase(tick,int(s.start_tick),i)!=105 or s.last_attack[i]>=tick or s.stun_until[i]>=tick: return "No new strike in this tick."
				s.last_attack[i]=tick
				if e.kind=="parry": s.stun_until[i]=tick+75
				else:
					s.hits+=1
					if s.hits==3: s.phase="caught"
		"regroup":
			if s.phase not in ["fighting","leaving"] or Base.distance(at,REGROUP)>3.2: return "Reach the home approach with both friends."
			for friend in [3,4]:
				if Base.distance(at,Base.point(e.positions[friend]))>4.5: return "A friend is still behind. Return for him."
			s.phase="returning"
			s.outcome="stood_ground" if s.down.count(true)>=2 else "withdrew" if s.start_tick>=0 else "walked_away"
			memory(s,"regroup",tick,"self","observed","All three of us reached the household approach. "+{"stood_ground":"I checked the attackers and broke their advance.","withdrew":"I got us out rather than continuing the fight.","walked_away":"We left the challenge unanswered."}[s.outcome])
		"report":
			if s.phase!="returning" or Base.distance(at,Supply.QUARTERMASTER)>3: return "Give the account at the household."
			for friend in [3,4]:
				if Base.distance(at,Base.point(e.positions[friend]))>5: return "Wait for both companions before the account."
			s.phase="reported"
			memory(s,"report",tick,"fictional_quartermaster","spoken",{"stood_ground":"Your friends say you held your ground. This household will hear of the fight again. For now, you have all come home.","withdrew":"You found a way out and brought both friends back. Tell me where the challengers stopped following.","walked_away":"You left together before the quarrel became a fight. I have heard your account."}[s.outcome])
		_: return "Unknown bazaar transition."
	return ""
static func replay(value: Variant,tick: int) -> Dictionary:
	if not Fields.fields(value,["schema","story_id","variant","origin_tick","events","ledger","actors"]): return {"error":"Malformed bazaar state."}
	if value.schema!=VERSION or value.story_id!=STORY_ID or value.variant!="authored_bazaar_v1" or not whole(value.origin_tick,0,tick): return {"error":"Unknown bazaar identity or time."}
	if not value.events is Array or value.events.is_empty() or value.events.size()>MAX_EVENTS or not value.actors is Array or value.actors.size()!=5: return {"error":"Invalid bazaar history or cast."}
	var s:=initial();var prior:=int(value.origin_tick)
	for n in range(value.events.size()):
		var e: Variant=value.events[n]
		if not e is Dictionary or not whole(e.get("tick"),prior,tick) or e.get("seq")!=n+1: return {"error":"Unordered bazaar receipt."}
		if n==0 and (e.get("kind")!="invite" or e.tick!=value.origin_tick): return {"error":"Missing initial invitation."}
		var error:=apply(s,e)
		if not error.is_empty(): return {"error":error}
		prior=int(e.tick)
	if not Supply._equal(value.ledger,s): return {"error":"Bazaar outcome or memory differs from receipts."}
	for i in range(5):
		if not valid_actor(value.actors[i],i): return {"error":"Invalid bazaar participant."}
		if i<3 and s.start_tick<0 and Base.distance(Base.point(value.actors[i].position),POSITIONS[i])>0.001: return {"error":"A challenger moved before the fight."}
	return {"error":"","ledger":s}
