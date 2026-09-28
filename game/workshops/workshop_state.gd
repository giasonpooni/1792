extends "res://settlement/town_state.gd"
## No second inventory, clock or evidence log: workshop custody is in misl.ledger.
const Craft := preload("res://workshops/workshop_rules.gd")
const WORKSHOP_SAVE := "user://1792-gujranwala-workshop-v1.json"

func workshop_phase() -> String:
	return Craft.phase(_state.misl.ledger) if has_economy() else "unassigned"

func workshop() -> Dictionary:
	return _state.misl.ledger.workshop.duplicate(true) if workshop_phase()!="unassigned" else {}

func carrying_workshop() -> bool:
	return workshop_phase() in ["fuel","tools"]

func workshop_action(action: String) -> String:
	if not has_economy() or not district_open(): return "Complete the inquiry and hear the household allowance first."
	if action not in Craft.PLAYER_ACTIONS: return "Workshop completion belongs to the world clock, not a player command."
	if mounted(): return "Dismount to settle the workshop order."
	var at: Vector3=Craft.SITE if action in ["start","collect"] else Economy.QUARTERMASTER
	if distance(position(),at)>3.0: return "Reach the appropriate speaker before changing custody."
	if action=="reserve" and _state.misl.events.size()>Economy.MAX_EVENTS-6: return "Too little receipt capacity to begin another task."
	return _post("smith."+action,str(int(_state.childhood.tick)))

func operate(kind: String,arg: String="") -> String:
	if kind.begins_with("smith."): return "Use the local workshop interaction."
	if kind=="accept_delivery" and carrying_workshop(): return "Return the workshop load before accepting food cargo."
	return super.operate(kind,arg)

func advance() -> void:
	var previous: int=int(_state.childhood.tick)
	super.advance()
	if int(_state.childhood.tick)==previous: return
	if workshop_phase()=="working" and int(_state.childhood.tick)==int(_state.misl.ledger.workshop.started_tick)+Craft.WORK_TICKS:
		_post("smith.ready",str(int(_state.childhood.tick)))

func mount() -> String:
	if carrying_workshop(): return "Deliver or return the workshop load before mounting."
	return super.mount()

func record_position(p: Vector3,delta: float) -> String:
	if carrying_workshop() and distance(position(),p)>Craft.CARRY_SPEED*delta+0.08:
		return "The workshop load must be carried at a walk."
	return super.record_position(p,delta)

func _ledger_apply(ledger: Dictionary,kind: String,arg: String) -> String:
	return Craft.apply(ledger,kind,arg)

func _ledger_validate(value: Variant,tick: int) -> String:
	return Craft.validate(value,tick)

func _ledger_replay(events: Array) -> Dictionary:
	return Economy.replay(events,Craft.apply)

func validate(value: Variant) -> String:
	var error:=super.validate(value)
	if not error.is_empty(): return error
	if value.has("misl") and value.misl.ledger.has("workshop"):
		if not value.has("settlement"): return "Workshop order lacks its town map identity."
		if Craft.carrying(value.misl.ledger) and value.riding.horse.rider_id!="": return "Carried workshop cargo cannot also be mounted."
		if Craft.carrying(value.misl.ledger) and value.misl.ledger.delivery=="outbound": return "Two exclusive hand-carried loads in one save."
	return ""

func journal() -> Array:
	var entries:=super.journal()
	if not has_economy(): return entries
	for e in _state.misl.events:
		if not e.kind.begins_with("smith."): continue
		var action: String=e.kind.trim_prefix("smith.")
		if not Craft.WORDS.has(action): continue # Clock completion alone is not knowledge delivered to Buddh.
		entries.append({"id":"workshop_"+action,"received_tick":int(e.tick),"source_id":"town_smith" if action in ["start","collect"] else "quartermaster",
			"channel":"heard","text":Craft.WORDS[action]})
	var ordered: Array=[]
	for i in range(entries.size()): ordered.append({"index":i,"record":entries[i]})
	ordered.sort_custom(func(a,b): return a.record.received_tick<b.record.received_tick if a.record.received_tick!=b.record.received_tick else a.index<b.index)
	return ordered.map(func(item): return item.record)
