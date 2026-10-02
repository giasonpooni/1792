extends RefCounted
## Deterministic political reducer. Only the bounded input ledger is authoritative.
## The runtime below is a disposable projection of that ledger and the chapter tick.
const Registry := preload("res://politics/social_registry.gd")
const Social := preload("res://politics/social_field_rules.gd")
const SocialProfile := preload("res://politics/social_field_profile.gd")
const STEP := 60
const MAX_INPUTS := 256
const KINDS := ["raid","incursion","reparation","scout","discretion","gaze"]
const ROUTES := {"phulkian":["sandhawalia"], "sandhawalia":["phulkian","bhangi"], "bhangi":["sandhawalia","kanhaiya"], "kanhaiya":["bhangi"], "sukerchakia":[]}

static func initial(tick: int = 0) -> Dictionary:
	return {"schema_version":"politics.v1", "origin_tick":tick, "inputs":[]}

static func whole(v: Variant, low: int = 0) -> bool:
	return typeof(v) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(v)) and v == floor(v) and v >= low

static func validate(log: Variant, tick: int) -> String:
	if not log is Dictionary or log.size() != 3: return "Malformed political ledger."
	if log.get("schema_version") != "politics.v1" or not whole(log.get("origin_tick")) or log.origin_tick > tick: return "Invalid political origin."
	if not log.get("inputs") is Array or log.inputs.size() > MAX_INPUTS: return "Political input budget exceeded."
	var prior := int(log.origin_tick)
	var last: Dictionary = {}
	for i in range(log.inputs.size()):
		var e: Variant = log.inputs[i]
		if not e is Dictionary or e.size() != 7: return "Malformed political input."
		for key in ["id","tick","kind","source_id","target","strength","evidence_class"]:
			if not e.has(key): return "Missing political input field."
		if e.id != "input:%d" % (i+1) or not whole(e.tick,prior) or e.tick > tick: return "Reordered, duplicate or future input."
		if e.kind not in KINDS or not Registry.PEOPLE.has(e.source_id) or e.target not in Registry.FACTIONS: return "Unknown political actor or operation."
		var actor := Registry.faction(e.source_id)
		if actor.is_empty() or (actor == e.target and e.kind != "discretion"): return "Invalid actor/target relation."
		if e.kind == "discretion" and actor != e.target: return "Discretion changes only one's own surface area."
		if e.evidence_class != ("observed_geometry" if e.kind == "gaze" else "authored_game_operation"): return "Invalid evidence/operation classification."
		if typeof(e.strength) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(e.strength)) or e.strength <= 0 or e.strength > 1: return "Invalid incident strength."
		var cooldown := 600 if e.kind == "gaze" else 180
		if last.has(e.source_id) and e.tick-int(last[e.source_id]) < cooldown: return "Political input exceeds its rate limit."
		last[e.source_id] = int(e.tick)
		prior = int(e.tick)
	return ""

static func append(log: Dictionary, tick: int, kind: String, source: String, target: String, strength: float = 1.0) -> String:
	var candidate: Dictionary = log.duplicate(true)
	candidate.inputs.append({"id":"input:%d" % (candidate.inputs.size()+1), "tick":tick, "kind":kind,
		"source_id":source, "target":target, "strength":strength,
		"evidence_class":"observed_geometry" if kind == "gaze" else "authored_game_operation"})
	var error := validate(candidate,tick)
	if error.is_empty(): log.inputs = candidate.inputs
	return error

static func runtime(origin: int) -> Dictionary:
	var r := {"tick":origin,"cursor":0,"factions":{},"pairs":{},"coalitions":{},"queue":[],"trace":[],"player_reports":[],"social":Social.initial(SocialProfile.ACTORS,Registry.FACTIONS)}
	for faction in Registry.FACTIONS:
		r.factions[faction] = {"resources":100.0,"surface":0.0,"shield":0.0,"scouts":{}}
		for target in Registry.FACTIONS:
			if faction == target: continue
			r.pairs[faction+":"+target] = {"grievance":0.0,"attention":0.0,"fear":0.0,
				"phase":"quiet","last_seen":-1000000,"last_raid":-1000000,"last_plot":-1000000,"plot_due":-1}
	return r

static func advance(r: Dictionary, log: Dictionary, to_tick: int) -> void:
	while int(r.tick)+STEP <= to_tick:
		r.tick = int(r.tick)+STEP
		while int(r.cursor) < log.inputs.size() and log.inputs[int(r.cursor)].tick <= r.tick:
			_apply(r,log.inputs[int(r.cursor)])
			r.cursor = int(r.cursor)+1
		_deliver(r)
		for faction in Registry.FACTIONS:
			var f: Dictionary = r.factions[faction]
			f.resources = minf(100.0,float(f.resources)+0.05)
			f.surface = float(f.surface)*0.993
			f.shield = float(f.shield)*0.998
		for key in r.pairs:
			var pair: Dictionary = r.pairs[key]
			pair.grievance = float(pair.grievance)*0.996
			pair.attention = float(pair.attention)*0.975
			pair.fear = float(pair.fear)*0.99
			var names: PackedStringArray = str(key).split(":")
			_response(r,names[0],names[1],pair)
		_coalitions(r)

static func project(log: Dictionary, tick: int) -> Dictionary:
	var r := runtime(int(log.origin_tick))
	advance(r,log,tick)
	return r

static func cost(kind: String) -> float:
	match kind:
		"raid": return 12.0
		"incursion": return 6.0
		"reparation": return 15.0
		"scout": return 8.0
		"discretion": return 5.0
	return 0.0

static func _apply(r: Dictionary, e: Dictionary) -> void:
	var actor := Registry.faction(e.source_id)
	var own: Dictionary = r.factions[actor]
	if e.kind == "gaze":
		var pair: Dictionary = r.pairs[actor+":"+str(e.target)]
		pair.attention = minf(1.0,float(pair.attention)+0.25*float(e.strength))
		pair.last_seen = r.tick
		r.factions[e.target].surface = minf(1.0,float(r.factions[e.target].surface)+0.12*float(e.strength))
		_emit(r,"observed",actor,e.target,e.id)
		return
	if float(own.resources) < cost(e.kind):
		_emit(r,"operation_refused",actor,e.target,e.id)
		return
	own.resources = float(own.resources)-cost(e.kind)
	match e.kind:
		"raid", "incursion":
			_incident(r,e.id,actor,e.target,e.kind,float(e.strength))
		"reparation":
			_report(r,e.id,e.target,actor,"reparation",0.38*float(e.strength),1.0,120,e.source_id)
			_emit(r,"reparation_sent",actor,e.target,e.id)
		"scout":
			own.scouts[e.target] = int(r.tick)+18000
			var pair: Dictionary = r.pairs[str(e.target)+":"+actor]
			_report(r,e.id,actor,e.target,"scout_report",float(pair.grievance),0.65,300,"fictional_courier")
			_emit(r,"scout_dispatched",actor,e.target,e.id)
		"discretion":
			own.surface = float(own.surface)*0.35
			own.shield = 1.0
			_emit(r,"discretion",actor,actor,e.id)

static func _incident(r: Dictionary, root: String, actor: String, target: String, kind: String, strength: float) -> void:
	var severity := (0.34 if kind == "raid" else 0.19)*strength
	r.factions[actor].surface = minf(1.0,float(r.factions[actor].surface)+severity)
	r.factions[target].resources = maxf(0.0,float(r.factions[target].resources)-severity*30.0)
	_emit(r,kind,actor,target,root)
	# Damage is world state; knowledge of the perpetrator arrives through a report.
	_report(r,root,target,actor,kind,severity,1.0,120,"fictional_local_witness")
	if kind == "raid":
		for neighbour in ROUTES[target]:
			if neighbour != actor:
				_report(r,root,neighbour,actor,kind,severity*0.65,0.65,420,"relayed_local_witness")

static func _report(r: Dictionary, root: String, recipient: String, accused: String, kind: String, strength: float, confidence: float, delay: int, source: String) -> void:
	var report := {"id":root+":"+recipient+":"+kind,"event_id":root,"recipient":recipient,
		"accused":accused,"kind":kind,"strength":strength,"confidence":confidence,"source_id":source,
		"sent_tick":int(r.tick),"received_tick":int(r.tick)+delay}
	r.queue.append(report)
	r.queue.append_array(Social.route(report,SocialProfile.ACTORS))

static func _deliver(r: Dictionary) -> void:
	var pending: Array = []
	for report in r.queue:
		if int(report.received_tick) > int(r.tick):
			pending.append(report)
			continue
		if report.has("observer_id"):
			var error := Social.receive(r.social,report,int(r.tick))
			if not error.is_empty(): push_error(error)
			continue # Local receipt never increments faction grievance a second time.
		var key: String = str(report.recipient)+":"+str(report.accused)
		if r.pairs.has(key):
			var pair: Dictionary = r.pairs[key]
			if report.kind in ["raid","incursion"]:
				pair.grievance = clampf(float(pair.grievance)+float(report.strength)*float(report.confidence),0.0,1.0)
				pair.attention = minf(1.0,float(pair.attention)+float(report.strength))
				pair.fear = minf(1.0,float(pair.fear)+0.1*float(report.strength))
				if report.confidence == 1.0: pair.last_seen = r.tick
			elif report.kind == "reparation": pair.grievance = maxf(0.0,float(pair.grievance)-float(report.strength))
		if report.recipient == "sukerchakia":
			r.player_reports.append(report.duplicate(true))
			if r.player_reports.size() > 64: r.player_reports.pop_front()
	r.queue = pending

static func _emit(r: Dictionary, kind: String, actor: String, target: String, root: String) -> void:
	r.trace.append({"tick":int(r.tick),"kind":kind,"actor":actor,"target":target,"event_id":root})
	if r.trace.size() > 128: r.trace.pop_front()

static func _signal(r: Dictionary, kind: String, actor: String, target: String, root: String) -> void:
	_emit(r,kind,actor,target,root)
	# A scout is an explicitly paid observation channel, not omniscient player knowledge.
	if int(r.factions[target].scouts.get(actor,-1)) >= int(r.tick):
		_report(r,root,target,actor,kind,0.0,0.7,180,"fictional_courier")

static func _response(r: Dictionary, actor: String, target: String, p: Dictionary) -> void:
	var pressure := float(p.grievance)*(1.0-0.2*float(p.fear))
	var phase := "muster" if pressure >= 0.70 else "rally" if pressure >= 0.46 else "watch" if pressure >= 0.20 else "quiet"
	if phase != p.phase:
		p.phase = phase
		_signal(r,"stand_down" if phase == "quiet" else phase,actor,target,"phase:%d:%s:%s" % [r.tick,actor,target])
	var own: Dictionary = r.factions[actor]
	if phase == "muster" and int(r.tick)-int(p.last_raid) >= 900 and own.resources >= 20.0:
		p.last_raid = r.tick
		p.grievance = float(p.grievance)*0.62
		own.resources = float(own.resources)-20.0
		var root := "retaliation:%d:%s:%s" % [r.tick,actor,target]
		_signal(r,"retaliatory_incursion",actor,target,root)
		_incident(r,root,actor,target,"incursion",0.8)
	var exposure := float(r.factions[target].surface)
	var opportunity: bool = int(r.tick)-int(p.last_seen) <= 600
	var hazard := float(p.grievance)*float(p.attention)*exposure
	if int(p.plot_due) < 0 and hazard > 0.18 and opportunity and int(r.tick)-int(p.last_plot) >= 1800 and own.resources >= 10.0:
		p.last_plot = r.tick
		p.plot_due = int(r.tick)+300
		own.resources = float(own.resources)-10.0
		_signal(r,"covert_warning",actor,target,"plot:%d:%s:%s" % [r.tick,actor,target])
	if int(p.plot_due) >= 0 and int(r.tick) >= int(p.plot_due):
		var kind := "plot_disrupted" if float(r.factions[target].shield) > 0.3 else "poisoning_attempt" if (int(r.tick)/STEP)%2 == 0 else "assassination_attempt"
		var root := "plot-outcome:%d:%s:%s" % [r.tick,actor,target]
		_emit(r,kind,actor,target,root)
		# V1 emits an encounter hook, never an unavoidable or medically simulated death.
		if kind != "plot_disrupted": r.factions[target].resources = maxf(0.0,float(r.factions[target].resources)-5.0)
		_report(r,root,target,"unknown",kind,0.0,0.5,120,"fictional_courier")
		p.plot_due = -1

static func _coalitions(r: Dictionary) -> void:
	var keep: Dictionary = {}
	for target in Registry.FACTIONS:
		for i in range(Registry.FACTIONS.size()):
			var a: String = Registry.FACTIONS[i]
			if a == target: continue
			for j in range(i+1,Registry.FACTIONS.size()):
				var b: String = Registry.FACTIONS[j]
				if b == target: continue
				var shared := minf(float(r.pairs[a+":"+target].grievance),float(r.pairs[b+":"+target].grievance))
				var friction := 0.1+0.3*maxf(float(r.pairs[a+":"+b].grievance),float(r.pairs[b+":"+a].grievance))
				var score := shared-friction
				var id: String = a+":"+b+":"+str(target)
				var threshold := 0.22 if r.coalitions.has(id) else 0.44
				if score >= threshold and r.factions[a].resources >= 5.0 and r.factions[b].resources >= 5.0:
					keep[id] = r.coalitions[id] if r.coalitions.has(id) else {"members":[a,b],"target":target,"formed_tick":int(r.tick)}
					if not r.coalitions.has(id): _signal(r,"coalition_formed",a,target,"coalition:%d:%s" % [r.tick,id])
	for id in r.coalitions:
		if not keep.has(id):
			var c: Dictionary = r.coalitions[id]
			_signal(r,"coalition_dissolved",c.members[0],c.target,"coalition-end:%d:%s" % [r.tick,id])
	r.coalitions = keep
