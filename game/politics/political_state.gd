extends "res://childhood/aftermath_state.gd"
## Extends the existing world state, clock, custody and save/restore authority.
const Politics := preload("res://politics/exposure_rules.gd")
const Vision := preload("res://perception/vision_rules.gd")
const Registry := preload("res://politics/social_registry.gd")
const POLITICAL_SAVE := "user://1792-political-vision-v1.json"
const OUTPOSTS := {"bhangi":Vector3(-14,0.14,-26), "sandhawalia":Vector3(17,0.14,-26), "kanhaiya":Vector3(-24,0.14,-8)}
const OBSERVERS := ["raj_kaur","fictional_household_guard","fictional_north_observer"]
var _projection: Dictionary = {} # Disposable reducer cache, never a parallel world authority.

func _init() -> void:
	super._init()
	_state.profile = "childhood.politics.v1"
	_state.politics = Politics.initial()
	_state.vision = Vision.initial()

func advance() -> void:
	super.advance()
	_derive()

func _derive() -> Dictionary:
	if _projection.is_empty(): _projection = Politics.runtime(int(_state.politics.origin_tick))
	Politics.advance(_projection,_state.politics,int(_state.childhood.tick))
	return _projection

func political_debug() -> Dictionary:
	# Privileged headless/test telemetry. Do not bind this to the ordinary HUD.
	return _derive().duplicate(true)

func social_debug(observer: String) -> Dictionary:
	# Privileged actor inspection, excluded from the journal and ordinary HUD.
	return Politics.Social.sample(_derive().social,observer,Politics.SocialProfile.HERO_SUBJECT,int(_state.childhood.tick))

func local_social_response(observer: String, perceived: bool) -> Dictionary:
	# A scene-provided physical observation plus authority-owned proximity is required.
	if not perceived or aftermath_phase()!="complete" or mounted(): return {}
	var sites: Dictionary = Politics.SocialProfile.SITES
	var at: Vector3 = MOTHER if observer=="raj_kaur" else sites.get(observer,Vector3(INF,INF,INF))
	if not Politics.SocialProfile.ACTORS.has(observer) or distance(position(),at)>3.0: return {}
	var response := social_debug(observer)
	if response.is_empty(): return {}
	# Whitelist: no score, root, queue, other actor or hidden culprit escapes here.
	return {"speaker_id":observer, "speaker":Registry.PEOPLE[observer].name,
		"text":Politics.SocialProfile.TEXT[response.stance], "channel":"local_conversation"}

func political_inputs() -> Array:
	return _state.politics.inputs.duplicate(true)

func perception() -> Dictionary:
	return Vision.parameters(_state.vision,int(_state.childhood.tick))

func can_perceive(bearing: float, range_metres: float, reach: float, clear: bool) -> bool:
	return Vision.visible(_state.vision,int(_state.childhood.tick),bearing,range_metres,reach,clear)

func record_gaze(observer: String, clear: bool, signature: float) -> String:
	if not clear: return "No observation: line of sight or field of view is blocked."
	if stage() != "escaped" or observer not in OBSERVERS: return "Observer is not active in this chapter."
	return Politics.append(_state.politics,int(_state.childhood.tick),"gaze",observer,"sukerchakia",signature)

func order_political(kind: String, target: String) -> String:
	if aftermath_phase() != "complete" or mounted(): return "Finish the household inquiry and act on foot."
	if kind not in ["raid","incursion","reparation","scout","discretion"]: return "Unknown player order."
	if kind in ["raid","incursion"]:
		if not OUTPOSTS.has(target) or distance(position(),OUTPOSTS[target]) > 3.0: return "Approach that authored outpost node."
	elif distance(position(),MOTHER) > 3.0:
		return "Return to the household to arrange this order."
	if kind == "discretion": target = "sukerchakia"
	if target not in Registry.FACTIONS or (target == "sukerchakia" and kind != "discretion"): return "Invalid order target."
	var current := _derive()
	if float(current.factions.sukerchakia.resources) < Politics.cost(kind): return "Insufficient command resources."
	return Politics.append(_state.politics,int(_state.childhood.tick),kind,Names.HERO_ID,target)

func political_journal() -> Array:
	var entries: Array = []
	for e in _state.politics.inputs:
		if e.source_id != Names.HERO_ID: continue
		entries.append({"id":e.id,"source_id":"self","channel":"command_sent","received_tick":int(e.tick),
			"text":"I issued %s concerning %s. This does not tell me how others have responded." % [e.kind,e.target]})
	var current := _derive()
	for report in current.player_reports:
		var subject := "an unidentified source" if report.accused == "unknown" else str(report.accused)
		var text := "A delayed account describes %s associated with %s. This is reported, not independently confirmed." % [str(report.kind).replace("_"," "),subject]
		if report.kind == "scout_report":
			var description := "quiet" if report.strength < 0.2 else "unease" if report.strength < 0.46 else "calls to gather"
			text = "A scout reported %s around %s when the report was sent. Its information may now be stale." % [description,subject]
		entries.append({"id":report.id,"source_id":report.source_id,"channel":"reported",
			"received_tick":int(report.received_tick),"text":text,
			"event_id":report.event_id,"confidence":report.confidence,"sent_tick":int(report.sent_tick)})
	return entries

func journal() -> Array:
	var all := super.journal()
	all.append_array(political_journal())
	var indexed: Array = []
	for i in range(all.size()): indexed.append({"record":all[i],"index":i})
	indexed.sort_custom(func(a,b): return a.record.received_tick < b.record.received_tick if a.record.received_tick != b.record.received_tick else a.index < b.index)
	return indexed.map(func(item): return item.record)

func validate(value: Variant) -> String:
	if not value is Dictionary: return "Malformed political world."
	var profile: Variant = value.get("profile")
	if profile not in ["childhood.v1","childhood.politics.v1"]: return "Unknown chapter profile."
	var extended: bool = profile == "childhood.politics.v1"
	if extended and (not value.has("politics") or not value.has("vision") or not value.has("aftermath")):
		return "Extended save lost its politics, perception or household identity."
	if not extended and (value.has("politics") or value.has("vision")): return "Ambiguous legacy profile."
	var base: Dictionary = value.duplicate(true)
	base.erase("politics")
	base.erase("vision")
	base.profile = "childhood.v1"
	var error := super.validate(base)
	if not error.is_empty() or not extended: return error
	error = Vision.validate(value.vision,int(value.childhood.tick))
	if not error.is_empty(): return error
	error = Politics.validate(value.politics,int(value.childhood.tick))
	if not error.is_empty(): return error
	for e in value.politics.inputs:
		if value.childhood.ambush.status != "escaped" or e.tick < value.childhood.ambush.end_tick: return "Political incident before this actor experienced the return."
		if e.kind == "gaze":
			if e.source_id not in OBSERVERS: return "Unknown surveillance executor."
		else:
			if e.source_id != Names.HERO_ID or value.get("aftermath",{}).get("reported_tick",-1) < 0 or e.tick < value.aftermath.reported_tick:
				return "Command before inquiry completion or from an unauthorised actor."
	return ""

func restore(value: Variant) -> String:
	var error := super.restore(value)
	if not error.is_empty(): return error
	if _state.profile == "childhood.v1":
		# Explicit old-save import: do not manufacture past incidents or reset a lost eye.
		_state.profile = "childhood.politics.v1"
		_state.politics = Politics.initial(int(_state.childhood.tick))
		_state.vision = Vision.initial(int(_state.childhood.tick),"stable_left_monocular")
	_projection = {}
	return ""

func save_to(path: String = POLITICAL_SAVE) -> String:
	return super.save_to(path)

func load_from(path: String = POLITICAL_SAVE) -> String:
	return super.load_from(path)
