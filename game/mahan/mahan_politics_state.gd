extends "res://mahan/mahan_logistics_state.gd"
const PoliticsValidate := preload("res://mahan/mahan_politics_validate.gd")
## Mahan-only clan/subordinate politics adapter.
## Subordinates are separate Person actors with time-bounded household alignments —
## not faction tags on people. Does not rewrite house_command_state or antagonists.
const POLITICS_DELAY := 90
const DISPOSITIONS := ["steady", "strained", "aligned"]
const STANCES := ["prefer_hold", "prefer_advance", "counsel_noted"]
## Authored fiction for field-camp counsel pressure; not documentary names.
const SUBORDINATE_DEFS := {
	"fictional_camp_retainer": {
		"role": "camp_retainer",
		"household_relation": "retainer_of",
		"serves_person": "mahan_singh",
		"serves_household": "sukerchakia",
		"initial_loyalty": 2,
		"advice": "hold_for_corroboration",
		"initial_stance": "prefer_hold",
		"label": "camp retainer"
	},
	"fictional_horse_jemadar": {
		"role": "horse_jemadar",
		"household_relation": "subordinate_commander",
		"serves_person": "mahan_singh",
		"serves_household": "sukerchakia",
		"initial_loyalty": 3,
		"advice": "advance_scouts",
		"initial_stance": "prefer_advance",
		"label": "horse jemadar"
	}
}
const RUMOR_TEXTS := {
	"household_pressure": {
		"source_id": "fictional_camp_courier",
		"channel": "delayed_household_word",
		"text": "A courier from the household tents arrived late. Elder retainers counsel holding the horse line until the fort road is better known. This is camp counsel under the Sukerchakia household graph, not a change of Person or Faction identity."
	}
}
const CONSULT_TEXT := "I heard the camp retainer urge holding for corroboration, while the horse jemadar pressed to advance on delivered scout custody. Counsel is subordinate advice under the household graph, not a Faction tag on any Person."
const PRESSURE_ACK_TEXT := "I acknowledged clan-house pressure on the column. March willingness returns only after this acknowledgment while disposition remains strained; the fixed historical endpoint is unchanged."

func _init() -> void:
	super._init()
	_ensure_politics()

func _ensure_politics() -> Dictionary:
	if not _state.mahan.has("politics") or not _state.mahan.politics is Dictionary:
		_state.mahan.politics = _fresh_politics()
	var pol: Dictionary = _state.mahan.politics
	for key in ["consulted", "disposition", "pressure_acknowledged", "loyalty", "alignments", "rumors"]:
		if not pol.has(key):
			_state.mahan.politics = _fresh_politics()
			return _state.mahan.politics
	return pol

func _fresh_politics() -> Dictionary:
	var loyalty := {}
	var alignments := {}
	for sid in SUBORDINATE_DEFS:
		var def: Dictionary = SUBORDINATE_DEFS[sid]
		loyalty[sid] = int(def.initial_loyalty)
		alignments[sid] = {
			"stance": def.initial_stance,
			"valid_from": 0,
			"valid_until": -1
		}
	return {
		"consulted": false,
		"disposition": "steady",
		"pressure_acknowledged": false,
		"loyalty": loyalty,
		"alignments": alignments,
		"rumors": []
	}

func politics() -> Dictionary:
	return _ensure_politics().duplicate(true)

func disposition() -> String:
	return str(_ensure_politics().disposition)

func consulted() -> bool:
	return bool(_ensure_politics().consulted)

func pressure_acknowledged() -> bool:
	return bool(_ensure_politics().pressure_acknowledged)

func subordinate_ids() -> Array:
	return SUBORDINATE_DEFS.keys()

func subordinate_loyalty(sid: String) -> int:
	return int(_ensure_politics().loyalty.get(sid, -1))

func subordinate_alignment(sid: String) -> Dictionary:
	var raw = _ensure_politics().alignments.get(sid)
	return {} if raw == null else raw.duplicate(true)

func active_stance(sid: String) -> String:
	var aln := subordinate_alignment(sid)
	if aln.is_empty():
		return ""
	var until: int = int(aln.valid_until)
	if until >= 0 and int(_state.mahan.tick) > until:
		return ""
	if not (int(_state.mahan.tick) >= int(aln.valid_from)):
		return ""
	return str(aln.stance)

func pending_rumors() -> Array:
	var out: Array = []
	for rumor in _ensure_politics().rumors:
		if not rumor.delivered:
			out.append(rumor.duplicate(true))
	return out

func received_rumors() -> Array:
	var out: Array = []
	for rumor in _ensure_politics().rumors:
		if rumor.delivered:
			out.append(rumor.duplicate(true))
	return out

func march_willingness() -> bool:
	## Strained disposition blocks march until pressure is acknowledged (or never strained).
	var pol := _ensure_politics()
	if pol.disposition != "strained":
		return true
	return bool(pol.pressure_acknowledged)

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.politics = _ensure_politics().duplicate(true)
	return out

func advance(ticks: int = 1) -> void:
	for _i in range(clampi(ticks, 0, 100000)):
		super.advance(1)
		_deliver_due_rumors()

func _deliver_due_rumors() -> void:
	var pol := _ensure_politics()
	for rumor in pol.rumors:
		if rumor.delivered or (not (_state.mahan.tick >= rumor.arrives_at)):
			continue
		rumor.delivered = true
		_remember(rumor.id, rumor.source_id, rumor.channel, rumor.text)
		_apply_rumor_alignment(rumor.target)

func _apply_rumor_alignment(target: String) -> void:
	if target != "household_pressure":
		return
	var pol := _ensure_politics()
	pol.alignments["fictional_camp_retainer"] = {
		"stance": "counsel_noted",
		"valid_from": int(_state.mahan.tick),
		"valid_until": -1
	}
	var loy: int = int(pol.loyalty.get("fictional_camp_retainer", 0))
	pol.loyalty["fictional_camp_retainer"] = maxi(0, loy - 1)
	if pol.disposition == "strained" and pol.pressure_acknowledged:
		pol.disposition = "aligned"

func consult_subordinates() -> String:
	if is_mounted():
		return "Dismount before consulting subordinates."
	if stage() != "decision" and stage() != "recon":
		return "Subordinate counsel is available before the column order is closed."
	if _state.mahan.decision != "":
		return "The column order is already given."
	if not near("camp_table"):
		return "Return to the camp table to hear subordinate counsel."
	var pol := _ensure_politics()
	if pol.consulted:
		return "Subordinate counsel has already been taken at this beat."
	pol.consulted = true
	_remember("consult_subordinates", "self", "subordinate_counsel", CONSULT_TEXT)
	return ""

func request_household_word() -> String:
	if is_mounted():
		return "Dismount before sending a household courier."
	if stage() != "decision" and stage() != "recon":
		return "Household word is not requested in this stage."
	if _state.mahan.decision != "":
		return "The column order is already given; no further household couriers."
	if not near("camp_table"):
		return "Return to the camp table to request household word."
	var pol := _ensure_politics()
	for rumor in pol.rumors:
		if rumor.target == "household_pressure":
			return "A household courier is already on the book."
	var authored: Dictionary = RUMOR_TEXTS.household_pressure
	pol.rumors.append({
		"id": "rumor_household_pressure.report",
		"target": "household_pressure",
		"observer_id": "camp_courier",
		"observed_at": _state.mahan.tick,
		"arrives_at": _state.mahan.tick + POLITICS_DELAY,
		"delivered": false,
		"source_id": authored.source_id,
		"channel": authored.channel,
		"text": authored.text
	})
	return ""

func acknowledge_clan_pressure() -> String:
	if is_mounted():
		return "Dismount before acknowledging clan-house pressure."
	if stage() != "march":
		return "Issue the column order before acknowledging clan-house pressure."
	if not near(_state.mahan.column_node) and not near("camp_table"):
		return "Stand with the column or at the camp table to acknowledge pressure."
	var pol := _ensure_politics()
	if pol.disposition != "strained":
		return "No strained clan-house pressure to acknowledge."
	if pol.pressure_acknowledged:
		return "Clan-house pressure is already acknowledged."
	pol.pressure_acknowledged = true
	_remember("clan_pressure_ack", "self", "command_acknowledgment", PRESSURE_ACK_TEXT)
	if not received_rumors().is_empty():
		pol.disposition = "aligned"
	return ""

func decide_column(choice: String) -> String:
	if is_mounted():
		return super.decide_column(choice)
	var before: String = _state.mahan.decision
	var err := super.decide_column(choice)
	if not err.is_empty() or before != "":
		return err
	_apply_decision_politics(choice)
	return ""

func _apply_decision_politics(choice: String) -> void:
	var pol := _ensure_politics()
	if not pol.consulted:
		pol.disposition = "steady"
		return
	var retainer_stance := active_stance("fictional_camp_retainer")
	if choice == "hold_for_corroboration":
		var loy: int = int(pol.loyalty.get("fictional_camp_retainer", 0))
		pol.loyalty["fictional_camp_retainer"] = mini(3, loy + 1)
		pol.disposition = "aligned"
		return
	if choice == "advance_scouts":
		if retainer_stance == "prefer_hold":
			pol.disposition = "strained"
			pol.pressure_acknowledged = false
			var loy2: int = int(pol.loyalty.get("fictional_camp_retainer", 0))
			pol.loyalty["fictional_camp_retainer"] = maxi(0, loy2 - 1)
		else:
			pol.disposition = "steady"

func march_to(next: String) -> String:
	if is_mounted():
		return super.march_to(next)
	if not march_willingness():
		return "Clan-house pressure strains march willingness; acknowledge the pressure before committing the column."
	return super.march_to(next)

func _politics_memory_id(id: String) -> bool:
	return id == "consult_subordinates" or id == "clan_pressure_ack" or str(id).begins_with("rumor_")

func validate(value: Variant) -> String:
	if not value is Dictionary or not value.get("mahan") is Dictionary:
		return "Malformed Mahan politics snapshot."
	var core: Dictionary = value.duplicate(true)
	var m: Dictionary = core.mahan
	var pol = m.get("politics")
	var stripped_parent_path := false
	if pol == null:
		for memory in m.memories:
			if _politics_memory_id(str(memory.id)):
				return "Mahan politics envelope missing."
		pol = _fresh_politics()
		stripped_parent_path = true
	elif not pol is Dictionary:
		return "Mahan politics envelope missing."
	var pol_err: String = PoliticsValidate.validate_ledger(self, value if not stripped_parent_path else {"mahan": {"politics": pol, "tick": m.tick, "decision": m.decision, "memories": []}}, pol, stripped_parent_path)
	if not pol_err.is_empty():
		return pol_err
	var kept: Array = []
	var politics_memories: Array = []
	for memory in m.memories:
		if _politics_memory_id(str(memory.id)):
			politics_memories.append(memory)
		else:
			kept.append(memory)
	core.mahan.memories = kept
	core.mahan.erase("politics")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	if stripped_parent_path:
		return ""
	return PoliticsValidate.validate_memories(self, value, politics_memories)

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var pol: Dictionary = core.mahan.politics.duplicate(true)
	var kept: Array = []
	for memory in core.mahan.memories:
		if not _politics_memory_id(str(memory.id)):
			kept.append(memory.duplicate(true))
	core.mahan.memories = kept
	core.mahan.erase("politics")
	error = super.restore(core)
	if not error.is_empty():
		return error
	_state.mahan.politics = {
		"consulted": bool(pol.consulted),
		"disposition": str(pol.disposition),
		"pressure_acknowledged": bool(pol.pressure_acknowledged),
		"loyalty": pol.loyalty.duplicate(true),
		"alignments": pol.alignments.duplicate(true),
		"rumors": []
	}
	for rumor in pol.rumors:
		var copy: Dictionary = rumor.duplicate(true)
		copy.observed_at = int(copy.observed_at)
		copy.arrives_at = int(copy.arrives_at)
		_state.mahan.politics.rumors.append(copy)
	for sid in _state.mahan.politics.loyalty:
		_state.mahan.politics.loyalty[sid] = int(_state.mahan.politics.loyalty[sid])
	for sid in _state.mahan.politics.alignments:
		var aln: Dictionary = _state.mahan.politics.alignments[sid]
		aln.valid_from = int(aln.valid_from)
		aln.valid_until = int(aln.valid_until)
	_state.mahan.memories = []
	for memory in value.mahan.memories:
		var mcopy: Dictionary = memory.duplicate(true)
		mcopy.received_tick = int(mcopy.received_tick)
		_state.mahan.memories.append(mcopy)
	return ""
