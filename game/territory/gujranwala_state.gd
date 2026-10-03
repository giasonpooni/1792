extends "res://childhood/aftermath_state.gd"
## Additive economy in the inherited active world; all clocks derive from childhood.tick.
const Economy := preload("res://territory/misl_rules.gd")
const Water := preload("res://territory/water_round_rules.gd")
const GuardRecruitment := preload("res://territory/guard_recruitment.gd")
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
	_advance_water()
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
	if kind == "hire" and GuardRecruitment.known(arg) and GuardRecruitment.used(_state.misl.events,arg):
		return "That individual appointment has already been settled in this run."
	if kind == "checkin" and distance(point(_state.misl.merchant.position),Economy.QUARTERMASTER)>4.5: return "The caravan must physically arrive before check-in."
	return _post(kind,arg)

func _post(kind: String,arg: String) -> String:
	var m: Dictionary = _state.misl
	if m.events.size()>=Economy.MAX_EVENTS: return "This prototype's retained-receipt limit is reached. Start a new scenario."
	var candidate: Dictionary = m.ledger.duplicate(true)
	var error := _ledger_apply(candidate,kind,arg)
	if not error.is_empty(): return error
	m.events.append({"seq":m.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,"arg":arg})
	m.ledger = candidate
	if kind=="checkin": m.merchant.velocity=[0.0,0.0,0.0]
	return ""

func rest_watch() -> String:
	if has_water_round() and water_round().ledger.phase=="drawing": return "Finish or cancel drawing before resting."
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
	base.erase("water_round")
	var error:=super.validate(base)
	if not error.is_empty(): return error
	if not value.has("misl"):
		return "Water round without an allowance." if value.has("water_round") else "" # Older saves invent no allowance, purchases or obligations.
	if not value.has("aftermath") or value.aftermath.reported_tick<0: return "Economy before the completed household inquiry."
	error=_ledger_validate(value.misl,int(value.childhood.tick))
	if not error.is_empty(): return error
	if value.misl.origin_tick<value.aftermath.reported_tick: return "Allowance predates the household report."
	if value.has("water_round"):
		return Water.validate(value.water_round,int(value.childhood.tick),int(value.misl.origin_tick),point(value.player.position),value.riding.horse.rider_id!="")
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
		_state.misl.ledger=_ledger_replay(_state.misl.events)
	if has_water_round():
		_state.water_round.origin_tick=int(_state.water_round.origin_tick)
		for e in _state.water_round.events:
			e.seq=int(e.seq)
			e.tick=int(e.tick)
		_state.water_round.ledger=Water.replay(_state.water_round.events)
	return ""

# Optional bounded household task; legacy saves and economy are unchanged until accepted.
func has_water_round() -> bool:
	return _state.has("water_round")

func water_round() -> Dictionary:
	return _state.water_round.duplicate(true) if has_water_round() else {}

func begin_water_round() -> String:
	if has_water_round(): return "The household water round was already assigned."
	if not has_economy() or mounted() or not Water.near_site(position(),Water.STORE): return "Hear the quartermaster after accepting the household allowance."
	_state.water_round={"schema":Water.VERSION,"model_id":Water.MODEL_ID,"origin_tick":int(_state.childhood.tick),"events":[],"ledger":Water.initial()}
	return ""

func water_action(kind: String) -> String:
	if kind not in ["draw","cancel","deposit"]: return "That water transition belongs to the clock, not the player."
	if not has_water_round() or mounted(): return "Accept the water round and dismount first."
	if kind=="draw" and _state.water_round.events.size()>Water.MAX_EVENTS-3: return "Water receipt budget exhausted; other missions remain available."
	return _post_water(kind)

func _post_water(kind: String) -> String:
	var w: Dictionary=_state.water_round
	if w.events.size()>=Water.MAX_EVENTS: return "Water receipt budget exhausted."
	var candidate: Dictionary=w.ledger.duplicate(true)
	var error:=Water.apply(candidate,kind,int(_state.childhood.tick),position())
	if not error.is_empty(): return error
	w.events.append({"seq":w.events.size()+1,"tick":int(_state.childhood.tick),"kind":kind,"actor_id":"ranjit_singh","position":coords(position())})
	w.ledger=candidate
	return ""

func _advance_water() -> void:
	if not has_water_round() or _state.water_round.ledger.phase!="drawing": return
	var s: Dictionary=_state.water_round.ledger
	if not Water.near_site(position(),Water.WELL) or mounted(): _post_water("cancel")
	elif _state.childhood.tick==s.started_tick+Water.DRAW_TICKS: _post_water("filled")

func record_position(p: Vector3, delta: float) -> String:
	# The renderer's speed cap is not authority: enforce it at the admitted motion seam too.
	if has_water_round() and _state.water_round.ledger.carried>0:
		if not is_finite(delta) or delta<=0 or delta>0.1 or distance(position(),p)>Water.CARRY_SPEED*delta+0.08:
			return "Walking too fast for an open water carrier."
	var error:=super.record_position(p,delta)
	if error.is_empty() and has_water_round() and _state.water_round.ledger.phase=="drawing" and not Water.near_site(position(),Water.WELL):
		_post_water("cancel")
	return error

func mount() -> String:
	if has_water_round() and (_state.water_round.ledger.carried>0 or _state.water_round.ledger.phase=="drawing"):
		return "Deposit the water or cancel the draw before mounting."
	return super.mount()

# Code-owned reducers: active subclasses select these, never a save-file callback.
func _ledger_apply(ledger: Dictionary,kind: String,arg: String) -> String:
	return Economy.apply(ledger,kind,arg)

func _ledger_validate(value: Variant,tick: int) -> String:
	return Economy.validate(value,tick)

func _ledger_replay(events: Array) -> Dictionary:
	return Economy.replay(events)
