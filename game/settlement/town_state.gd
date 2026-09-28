extends "res://remounts/remount_state.gd"
## One active world: inherited missions/economy plus bounded firsthand local-place receipts.
const Layout := preload("res://settlement/town_layout.gd")
const TOWN_SAVE := "user://1792-gujranwala-town-v1.json"

func report_home() -> String:
	var error:=super.report_home()
	if error.is_empty(): _state.settlement=Layout.initial()
	return error

func district_open() -> bool:
	return aftermath_phase()=="complete"

func settlement() -> Dictionary:
	return _state.settlement.duplicate(true) if _state.has("settlement") else Layout.initial()

func valid_player_point(p: Variant) -> bool:
	return Layout.valid_position(p)

func _permitted(p: Variant) -> bool:
	return valid_point(p) or district_open()

func record_position(p: Vector3,delta: float) -> String:
	if not _permitted(coords(p)): return "Finish the household inquiry before leaving through the town gates."
	return super.record_position(p,delta)

func record_ride(motion: Dictionary,delta: float) -> String:
	if not _permitted(motion.get("position",horse_record().position)): return "The town gates remain shut until the household inquiry is complete."
	return super.record_ride(motion,delta)

func dismount(p: Vector3) -> String:
	if not _permitted(coords(p)): return "No access beyond the household boundary yet."
	return super.dismount(p)

func observe_landmark(id: String) -> String:
	if not Layout.SITES.has(id): return "Unknown local landmark."
	if not district_open() or mounted(): return "Finish the inquiry and examine the place on foot."
	if distance(position(),Layout.SITES[id].point)>3.2: return "Move closer to examine the place."
	for v in settlement().visits:
		if v.id==id: return "This place is already in your remembered route."
	# Scene establishes facing and physics ray visibility. This receipt is consistency data,
	# not independently attested physical observation and not a resource or literacy grant.
	_state.settlement.visits.append({"id":id,"tick":int(_state.childhood.tick),"position":coords(position())})
	return ""

func journal() -> Array:
	var entries:=super.journal()
	for v in settlement().visits:
		entries.append({"id":"town_"+v.id,"source_id":"self","channel":"observed",
			"received_tick":int(v.tick),"text":Layout.SITES[v.id].title+" · "+Layout.SITES[v.id].description})
	# Stable tie ordering is explicit; derived text never trusts arbitrary save-file prose.
	var ordered: Array=[]
	for i in range(entries.size()): ordered.append({"index":i,"record":entries[i]})
	ordered.sort_custom(func(a,b): return a.record.received_tick<b.record.received_tick if a.record.received_tick!=b.record.received_tick else a.index<b.index)
	return ordered.map(func(item): return item.record)

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed town world."
	var base: Dictionary=value.duplicate(true)
	base.erase("settlement")
	var error:=super.validate(base)
	if not error.is_empty(): return error
	var old_space: bool=valid_point(value.player.position) and valid_point(value.riding.horse.position)
	if not value.has("settlement"):
		return "Legacy save exceeds its original playable space." if not old_space else ""
	var s: Variant=value.settlement
	if not _shape(s,Layout.initial()) or s.schema!=Layout.VERSION or s.map_id!=Layout.ID or s.seed!=Layout.SEED:
		return "Unsupported town map identity."
	var completed: bool=value.has("aftermath") and value.aftermath.reported_tick>=0
	if not completed and (not old_space or not s.visits.is_empty()): return "Town exploration predates the household inquiry."
	if s.visits.size()>Layout.SITES.size(): return "Too many landmark receipts."
	var seen: Array=[]
	var previous: int=int(value.aftermath.reported_tick) if completed else 0
	for v in s.visits:
		if not _shape(v,{"id":"","tick":0,"position":[]}): return "Malformed landmark receipt."
		if not Layout.SITES.has(v.id) or v.id in seen: return "Unknown or duplicate landmark."
		if v.tick!=floor(v.tick) or v.tick<previous or v.tick>value.childhood.tick: return "Invalid landmark time."
		if not Layout.valid_position(v.position) or distance(point(v.position),Layout.SITES[v.id].point)>3.2: return "Landmark receipt is not local."
		seen.append(v.id);previous=int(v.tick)
	return ""

func restore(value: Variant) -> String:
	var error:=super.restore(value)
	if not error.is_empty(): return error
	if district_open() and not _state.has("settlement"): _state.settlement=Layout.initial() # Empty local map only; no invented visits.
	if _state.has("settlement"):
		_state.settlement.seed=Layout.SEED
		for v in _state.settlement.visits: v.tick=int(v.tick)
	return ""
