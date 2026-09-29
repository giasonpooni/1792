# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Isolated authoring fixture. No campaign clock, player-save or release authority.
const MANIFEST := "res://data/fall_of_empire.v1.json"
const MODEL := "fall-of-empire.settlement-fixture.v1"
const OPERATION := "fall-of-empire.fixture-command.v1"
const ROLES := ["company_courier", "rebel_courier", "resident"]
const ANCHORS := ["crown_transfer_1858_08_02", "crown_proclamation_1858_11_01", "formal_peace_1859_07_08"]
const DATES := ["1858-08-02", "1858-11-01", "1859-07-08"]
const LIMIT := 64
const DELAY := 120

static func binding() -> String:
	return (FileAccess.get_file_as_string(MANIFEST)+"\n"+FileAccess.get_file_as_string("res://dlc/fall_of_empire/rules.gd")).sha256_text()

static func production_refusal() -> String:
	# A completed base game alone cannot turn a qualification desk into a shipped DLC.
	return "DLC production requires the complete Ranjit narrative AND separately qualified campaign content. This desk admits neither."

static func initial(execution_id: String) -> Dictionary:
	if execution_id.is_empty() or execution_id.length()>100: return {}
	return {"schema":"fall-of-empire.fixture-state.v1", "model_id":MODEL,
		"binding":binding(), "execution_id":execution_id, "tick":0, "history":[],
		"world":{"date":"1857-09-14", "anchors":[], "road_open":false,
			"muster":"unresolved", "household":"unresolved", "market":false, "closed":false},
		"knowledge":{"company_courier":[], "rebel_courier":[], "resident":[]}, "reports":[]}

static func integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v==floor(float(v)) and v>=0 and v<=100000000

static func fail(reason: String) -> Dictionary:
	return {"error":reason, "state":{}}

static func observation(state: Dictionary, actor: String) -> void:
	state.knowledge[actor].append({"id":"observation:%d" % state.history.size(),
		"event_id":"fixture.shared_road", "origin":actor, "tick":state.tick,
		"road_open":state.world.road_open})

static func _apply(state: Dictionary, actor: String, action: String, value: String, tick: int) -> String:
	if state.world.closed: return "The fixture is closed. Restore a prior checkpoint to explore another branch."
	if actor not in ROLES and actor!="host": return "Unknown actor."
	if tick<state.tick: return "Chronological rewind requires whole-state restore."
	if state.history.size()>=LIMIT: return "Receipt budget exhausted."
	# No mutation below is promoted unless this complete command succeeds.
	state.tick=tick
	match action:
		"anchor":
			var index: int=state.world.anchors.size()
			if actor!="host" or index>=ANCHORS.size() or value!=ANCHORS[index]: return "Anchor must be host-authored, unique and chronological."
			state.world.anchors.append(value);state.world.date=DATES[index]
		"observe":
			if actor not in ROLES or not value.is_empty(): return "An embodied role must make the observation."
			observation(state,actor)
		"send":
			if actor not in ROLES or value not in ROLES or actor==value or tick+DELAY>100000000: return "Invalid report recipient."
			var own: Array=state.knowledge[actor]
			var latest: Dictionary={}
			for item in own:
				if item.origin==actor: latest=item
			if latest.is_empty(): return "No personal observation to report."
			for report in state.reports:
				if report.to==value and report.observation.id==latest.id: return "Duplicate report root to the same recipient."
			state.reports.append({"from":actor,"to":value,"due":tick+DELAY,"delivered":false,"observation":latest.duplicate(true)})
		"receive":
			if actor not in ROLES or not value.is_empty(): return "Invalid receiving role."
			var found:=false
			for report in state.reports:
				if report.to==actor and not report.delivered and tick>=report.due:
					report.delivered=true;found=true
					var seen:=false
					for item in state.knowledge[actor]: seen=seen or item.id==report.observation.id
					if not seen: state.knowledge[actor].append(report.observation.duplicate(true))
					break
			if not found: return "No report has arrived for this role."
		"muster":
			if actor!="rebel_courier" or value not in ["dispersed","detained","left_region"] or state.world.anchors.is_empty() or state.world.muster!="unresolved": return "Record one postwar disposition for the rebel-associated fixture."
			state.world.muster=value
		"inspect_road":
			if actor!="company_courier" or not value.is_empty() or state.world.anchors.size()!=3 or state.world.muster=="unresolved" or state.world.road_open: return "Road reopening requires formal peace, an accounted local armed group and a fresh inspection."
			state.world.road_open=true;observation(state,actor)
		"market":
			if actor!="resident" or not value.is_empty() or not state.world.road_open or state.world.market: return "Delivery cannot precede road access or occur twice."
			var knows:=false
			for item in state.knowledge[actor]: knows=knows or item.road_open
			if not knows: return "This resident has not observed or received news of the open road."
			state.world.market=true
		"household":
			if actor!="resident" or value not in ["returned","displaced","missing"] or state.world.anchors.size()<2 or state.world.household!="unresolved": return "Record one household account after the proclamation."
			state.world.household=value
		"close":
			if actor!="host" or not value.is_empty() or state.world.anchors.size()!=3 or not state.world.road_open or state.world.muster=="unresolved" or not state.world.market or state.world.household=="unresolved": return "Formal peace alone does not finish the local settlement."
			state.world.closed=true
		_: return "Unknown operation."
	return ""

static func normalize_numbers(value: Variant) -> Variant:
	# JSON has one numeric type; this fixture has only integral ticks/ordinals.
	# Booleans remain booleans. Fractional/nonfinite values are never normalized.
	if value is float and integer(value): return int(value)
	if value is Array:
		var array: Array=[]
		for item in value: array.append(normalize_numbers(item))
		return array
	if value is Dictionary:
		var result: Dictionary={}
		for key in value: result[key]=normalize_numbers(value[key])
		return result
	return value

static func restore(candidate: Variant) -> Dictionary:
	if not candidate is Dictionary or not candidate.get("execution_id") is String: return fail("Malformed snapshot.")
	var state:=initial(candidate.execution_id)
	if state.is_empty() or candidate.get("binding")!=state.binding or candidate.get("model_id")!=MODEL or not candidate.get("history") is Array or candidate.history.size()>LIMIT: return fail("Unknown model, source binding or history.")
	for receipt in candidate.history:
		if not receipt is Dictionary or receipt.size()!=8: return fail("Malformed receipt shape.")
		for key in ["actor","action","value"]:
			if not receipt.get(key) is String: return fail("Malformed command.")
		if receipt.get("operation_id")!=OPERATION or receipt.get("execution_id")!=state.execution_id or receipt.get("event_id")!="fixture.shared_road" or not integer(receipt.get("seq")) or receipt.get("seq")!=state.history.size() or not integer(receipt.get("tick")): return fail("Receipt identity/chronology mismatch.")
		var error:=_apply(state,receipt.actor,receipt.action,receipt.value,int(receipt.tick))
		if not error.is_empty(): return fail(error)
		state.history.append(normalize_numbers(receipt))
	if state!=normalize_numbers(candidate): return fail("Derived world, knowledge or pending reports do not match replay.")
	return {"error":"", "state":state}

static func append(candidate: Variant, actor: String, action: String, value: String, tick: Variant) -> Dictionary:
	if not integer(tick): return fail("Invalid host tick.")
	var restored:=restore(candidate)
	if not restored.error.is_empty(): return restored
	var state: Dictionary=restored.state
	var error:=_apply(state,actor,action,value,int(tick))
	if not error.is_empty(): return fail(error)
	state.history.append({"seq":state.history.size(),"operation_id":OPERATION,
		"execution_id":state.execution_id,"event_id":"fixture.shared_road",
		"actor":actor,"action":action,"value":value,"tick":int(tick)})
	return {"error":"", "state":state}

static func view(candidate: Variant, actor: String) -> Dictionary:
	var restored:=restore(candidate)
	if not restored.error.is_empty() or actor not in ROLES: return {}
	var state: Dictionary=restored.state
	var personal: Dictionary={}
	if actor=="rebel_courier": personal["muster"]=state.world.muster
	if actor=="resident": personal={"household":state.world.household,"market":state.world.market}
	return {"actor":actor,"event_id":"fixture.shared_road",
		"observations":state.knowledge[actor].duplicate(true),"personal":personal}
