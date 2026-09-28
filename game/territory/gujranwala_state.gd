extends "res://childhood/aftermath_state.gd"
## Additive economy in the inherited active world; all clocks derive from childhood.tick.
const Economy := preload("res://territory/misl_rules.gd")
const TERRITORY_SAVE := "user://1792-gujranwala-v1.json"

func has_economy() -> bool:
	return _state.has("misl")

func economy() -> Dictionary:
	return _state.misl.duplicate(true) if has_economy() else {}

func begin_allowance() -> String:
	if has_economy(): return "This allowance has already been released."
	if aftermath_phase() != "complete" or mounted() or distance(position(),Economy.QUARTERMASTER)>3:
		return "Finish the household inquiry, then hear the quartermaster on foot."
	_state.misl = {"schema":Economy.VERSION,"cell_id":Economy.CELL_ID,"seed":Economy.SEED,
		"origin_tick":int(_state.childhood.tick),"events":[],"ledger":Economy.initial(),"merchant":Economy.blank_merchant()}
	return ""

func advance() -> void:
	super.advance()
	if not has_economy(): return
	var m: Dictionary = _state.misl
	if int(_state.childhood.tick)==int(m.origin_tick)+(m.ledger.watch+1)*Economy.WATCH_TICKS:
		_post("watch","")

func operate(kind: String, arg: String = "") -> String:
	if not has_economy(): return "Hear the quartermaster's allowance first."
	if mounted(): return "Dismount to speak and settle a transaction."
	var place := Economy.MARKET if kind in ["buy","satchel","deliver","accept_escort"] else Economy.QUARTERMASTER
	if distance(position(),place)>3.0: return "Visit the market on foot." if place==Economy.MARKET else "Return to the quartermaster on foot."
	if kind == "watch": return "Upkeep is driven by the existing clock, not a spendable command."
	if kind == "checkin" and distance(point(_state.misl.merchant.position),Economy.QUARTERMASTER)>4.5: return "The caravan must physically arrive before check-in."
	return _post(kind,arg)

func _post(kind: String,arg: String) -> String:
	var m: Dictionary = _state.misl
	if m.events.size()>=Economy.MAX_EVENTS: return "This prototype's retained-receipt limit is reached. Start a new scenario."
	var candidate: Dictionary = m.ledger.duplicate(true)
	var error := Economy.apply(candidate,kind,arg)
	if not error.is_empty(): return error
	m.events.append({"seq":m.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,"arg":arg})
	m.ledger = candidate
	if kind=="checkin": m.merchant.velocity=[0.0,0.0,0.0]
	return ""

func rest_watch() -> String:
	if not has_economy() or mounted() or distance(position(),Economy.QUARTERMASTER)>3:
		return "Rest at the quartermaster on foot."
	if _state.misl.ledger.caravan=="active": return "Return the active caravan before resting."
	if _state.misl.events.size()>=Economy.MAX_EVENTS: return "Receipt limit reached."
	var remaining: int = int(_state.misl.origin_tick)+(_state.misl.ledger.watch+1)*Economy.WATCH_TICKS-int(_state.childhood.tick)
	for _i in range(remaining): advance() # Same clock, no offscreen merchant movement.
	return ""

func record_merchant(motion: Dictionary, delta: float) -> String:
	if not has_economy() or _state.misl.ledger.caravan!="active": return "No active caravan."
	if not Economy.finite_number(delta) or delta<=0 or delta>0.1: return "Invalid caravan timestep."
	if motion.size()!=4 or motion.get("id")!=Economy.CARAVAN_ID: return "Wrong caravan identity."
	if not valid_point(motion.get("position")) or not Economy.valid_velocity(motion.get("velocity")) or not Economy.finite_number(motion.get("yaw")) or absf(motion.yaw)>PI: return "Invalid caravan motion."
	var old := point(_state.misl.merchant.position)
	if distance(old,point(motion.position))>2.6*delta+0.08: return "Caravan cannot teleport."
	if distance(position(),old)>9 and distance(old,point(motion.position))>0.001: return "The escort left the caravan behind."
	if Vector2(motion.velocity[0],motion.velocity[2]).length()>2.61: return "Caravan exceeded its declared pace."
	_state.misl.merchant = motion.duplicate(true)
	return ""

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed home world."
	var base: Dictionary=value.duplicate(true)
	base.erase("misl")
	var error:=super.validate(base)
	if not error.is_empty(): return error
	if not value.has("misl"): return "" # Older saves invent no allowance, purchases or obligations.
	if not value.has("aftermath") or value.aftermath.reported_tick<0: return "Economy before the completed household inquiry."
	error=Economy.validate(value.misl,int(value.childhood.tick))
	if not error.is_empty(): return error
	if value.misl.origin_tick<value.aftermath.reported_tick: return "Allowance predates the household report."
	return ""

func restore(value: Variant) -> String:
	var error:=super.restore(value) # Uses this validator before mutation.
	if not error.is_empty(): return error
	if has_economy():
		_state.misl.origin_tick=int(_state.misl.origin_tick)
		_state.misl.seed=Economy.SEED
		for e in _state.misl.events:
			e.seq=int(e.seq)
			e.tick=int(e.tick)
		_state.misl.ledger=Economy.replay(_state.misl.events)
	return ""
