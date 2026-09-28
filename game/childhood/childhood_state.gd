extends RefCounted
## One active home-scenario authority. Presentation and physics submit observations/actions.
## Extends world-state.v1 without changing the original seed, schemas or Lahore authorities.
const Names := preload("res://characters/character_names.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const LIMIT := 131072
const SAVE_PATH := "user://1792-childhood-v1.json"
const SITES := {
	"letter": Vector3(-4, 0.14, 3), "steward": Vector3(-12, 0.14, 5),
	"courier": Vector3(-4, 0.14, 3), "spar": Vector3(-16, 0.14, -3),
	"track_1": Vector3(-16, 0.14, -14), "track_2": Vector3(-8, 0.14, -22),
	"track_3": Vector3(0, 0.14, -24), "quarry": Vector3(13, 0.14, -23),
	"bend": Vector3(8, 0.14, -13), "home": Vector3(0, 0.14, 4),
	"reflection": Vector3(16, 0.14, 7)
}
const GATES := [Vector3(8, 0.14, -18), Vector3(-8, 0.14, -18), Vector3(-8, 0.14, -4)]
# These are original, fictional lines, NOT translations or quotations from the historical sources.
const ACCOUNTS := {
	"steward": {"source_id": "fictional_steward", "channel": "read_aloud", "claim": "The north trail was clear at dawn. The note says nothing about now."},
	"courier": {"source_id": "fictional_courier", "channel": "testimony", "claim": "I carried that note; I did not scout the trail. I heard riders beyond the grove later."}
}
const PERSONAL_MEMORIES := {
	"letter": "I have a sealed written message. Its words have not been read to me.",
	"track_1": "I examined the next set of tracks; the trail continues toward the grove.",
	"track_2": "I examined the next set of tracks; the trail continues toward the grove.",
	"track_3": "I examined the next set of tracks; the trail continues toward the grove.",
	"quarry": "I reached the quarry quietly. I know this trail by travelling it.",
	"reflection": "I return to the prayers I have heard. Others can name me; my conduct is still mine.",
	"assault": "Someone attacked me on the return trail. I do not know who sent him.",
	"return": "I returned alive. The attack does not tell me which household, if any, ordered it."
}
var _state: Dictionary

func _init() -> void:
	_state = _initial()

func _initial() -> Dictionary:
	var p := [0.0, 0.14, 0.0]
	var riding := Riding.initial()
	riding.horse.position = [8.0, 0.14, -5.0]
	return {"schema_version": "world-state.v1", "profile": "childhood.v1",
		"scenario_id": "home_childhood_reconstruction", "historical_class": "authored_source_informed_prototype",
		"game_time": {"year": 1792, "day": 1, "hour": 7.0},
		"player": {"character_id": Names.HERO_ID, "position": p.duplicate(), "known_places": ["sukerchakia_home"]},
		"actors": {Names.HERO_ID: {"position": p.duplicate()}},
		"places": [{"id": "sukerchakia_home", "disposition": "friendly"}], "relationships": [],
		"riding": riding,
		"childhood": {"tick": 0, "walked": 0.0, "looked": 0.0, "letter_seen": false,
			"heard": [], "ride_gate": 0, "parries": 0, "counters": 0,
			"tracks": 0, "quarry_seen": false, "reflected": false,
			"ambush": {"status": "locked", "start_tick": -1, "end_tick": -1, "hits": 0,
				"deflected": false, "stun_until": -1, "position": [16.0, 0.14, -13.0], "seen": false},
			"memories": []}}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func progress() -> Dictionary:
	return _state.childhood.duplicate(true)

func horse_record() -> Dictionary:
	return _state.riding.horse.duplicate(true)

func position() -> Vector3:
	return point(_state.player.position)

static func point(p: Array) -> Vector3:
	return Vector3(p[0], p[1], p[2])

static func coords(p: Vector3) -> Array:
	return [p.x, p.y, p.z]

static func distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func near(id: String, radius: float = 3.0) -> bool:
	return SITES.has(id) and distance(position(), SITES[id]) <= radius

func mounted() -> bool:
	return _state.riding.horse.rider_id != ""

func stage() -> String:
	var s: Dictionary = _state.childhood
	if s.walked < 5.0 or s.looked < 0.6: return "orientation"
	if not s.letter_seen or s.heard.size() < 2: return "letter"
	if s.ride_gate < GATES.size(): return "riding"
	if s.parries < 2 or s.counters < 1: return "sparring"
	if not s.quarry_seen: return "tracking"
	return str(s.ambush.status) # ready -> active -> escaped -> complete, or caught

func advance() -> void:
	if _state.childhood.tick >= 10000000: return
	_state.childhood.tick += 1 # Exactly one simulation tick per Godot physics transition.
	var hours: float = 7.0 + _state.childhood.tick / 216000.0
	_state.game_time.day = 1 + int(hours / 24.0)
	_state.game_time.hour = fmod(hours, 24.0)
	if stage() == "locked": _state.childhood.ambush.status = "ready"

func record_look(radians: float) -> void:
	if not is_finite(radians): return
	_state.childhood.looked = minf(1.0, _state.childhood.looked + minf(absf(radians), 0.3))

func record_position(p: Vector3, delta: float) -> String:
	if not valid_player_point(coords(p)) or not is_finite(delta) or delta <= 0.0 or delta > 0.1:
		return "Invalid motion sample."
	if mounted(): return "Mounted pose belongs to horse motion."
	var d := distance(position(), p)
	if d > 9.0 * delta + 0.08: return "Walking motion exceeded the declared bound."
	_state.childhood.walked = minf(6.0, _state.childhood.walked + d)
	_set_position(p)
	return ""

func _set_position(p: Vector3) -> void:
	_state.player.position = coords(p)
	_state.actors[Names.HERO_ID].position = coords(p)

func mount() -> String:
	var h: Dictionary = _state.riding.horse
	if mounted() or distance(position(), Riding.position(h)) > Riding.MOUNT_DISTANCE: return "Move beside the horse."
	if stage() in ["orientation", "letter"]: return "Listen to the two accounts before the riding lesson."
	if stage() == "caught": return "Reload a save or restart the chapter."
	h.rider_id = Names.HERO_ID
	_set_position(Riding.position(h))
	return ""

func dismount(p: Vector3) -> String:
	var h: Dictionary = _state.riding.horse
	if not mounted() or h.speed > Riding.DISMOUNT_SPEED or not h.grounded: return "Stop on solid ground first."
	if not valid_player_point(coords(p)) or distance(Riding.position(h), p) > 2.5: return "Invalid dismount position."
	h.rider_id = ""
	h.speed = 0.0
	_set_position(p)
	return ""

func record_ride(motion: Dictionary, delta: float) -> String:
	if not mounted() or delta <= 0 or delta > 0.1 or not is_finite(delta): return "No mounted executor."
	var candidate := snapshot()
	for key in motion:
		if key not in ["position", "yaw", "speed", "vertical_speed", "grounded"]: return "Unknown horse motion field."
		candidate.riding.horse[key] = motion[key]
	if not valid_player_point(candidate.riding.horse.position): return "Horse left the bounded home scene."
	var p := point(candidate.riding.horse.position)
	if distance(position(), p) > Riding.MAX_SPEED * delta + 0.08: return "Horse motion exceeds the declared bound."
	candidate.player.position = coords(p)
	candidate.actors[Names.HERO_ID].position = coords(p)
	var error := Riding.validate(candidate.riding, candidate)
	if not error.is_empty(): return error
	_state = candidate
	var gate: int = _state.childhood.ride_gate
	if stage() == "riding" and distance(p, GATES[gate]) <= 2.5:
		_state.childhood.ride_gate += 1
	return ""

func inspect_letter() -> String:
	if mounted() or not near("letter") or stage() not in ["letter", "orientation"]: return "Approach the courier on foot."
	if not _state.childhood.letter_seen:
		_state.childhood.letter_seen = true
		_remember("letter", "self", "observed", "I have a sealed written message. Its words have not been read to me.")
	return ""

func hear(reader: String) -> String:
	if not ACCOUNTS.has(reader) or mounted() or not near(reader) or not _state.childhood.letter_seen:
		return "Take the message to this speaker on foot."
	if reader in _state.childhood.heard: return "This is the same account, not new corroboration."
	_state.childhood.heard.append(reader)
	var a: Dictionary = ACCOUNTS[reader]
	_remember(reader, a.source_id, a.channel, a.claim)
	return ""

func spar_result(kind: String) -> String:
	if stage() != "sparring" or mounted() or not near("spar", 3.3): return "Enter the practice circle on foot."
	# Physics/presentation evaluates the visible telegraph and actual guard/counter window.
	if kind == "parry": _state.childhood.parries = mini(2, _state.childhood.parries + 1)
	elif kind == "counter" and _state.childhood.parries >= 2: _state.childhood.counters = 1
	else: return "Guard two practice blows before countering."
	return ""

func inspect_track(id: String) -> String:
	var expected := "track_%d" % (int(_state.childhood.tracks) + 1)
	if stage() != "tracking" or mounted() or id != expected or not near(id): return "Follow and examine the trail in order."
	_state.childhood.tracks += 1
	_remember(id, "self", "observed", "I examined the next set of tracks; the trail continues toward the grove.")
	return ""

func observe_quarry(slow: bool) -> String:
	if stage() != "tracking" or _state.childhood.tracks != 3 or mounted() or not near("quarry", 6.0) or not slow:
		return "Follow all three tracks, then approach quietly [C] and observe [E]."
	_state.childhood.quarry_seen = true
	_state.childhood.ambush.status = "ready"
	_remember("quarry", "self", "observed", "I reached the quarry quietly. I know this trail by travelling it.")
	return ""

func reflect() -> String:
	if mounted() or not near("reflection") or stage() in ["active", "caught"]: return "Find a quiet moment beneath the courtyard tree."
	if _state.childhood.reflected: return "The moment is already remembered."
	_state.childhood.reflected = true
	_remember("reflection", "self", "inner_voice", "I return to the prayers I have heard. Others can name me; my conduct is still mine.")
	return "" # No truth revelation, alignment change, health or combat bonus.

func start_ambush() -> String:
	if stage() != "ready" or not near("bend", 3.0): return "The return encounter is not ready here."
	_state.childhood.ambush.status = "active"
	_state.childhood.ambush.start_tick = _state.childhood.tick
	return ""

func record_threat(p: Vector3, delta: float) -> String:
	var a: Dictionary = _state.childhood.ambush
	if stage() != "active" or not valid_point(coords(p)) or delta <= 0 or delta > 0.1 or not is_finite(delta): return "Invalid encounter motion."
	if distance(point(a.position), p) > 3.2 * delta + 0.08: return "Encounter motion exceeds bound."
	a.position = coords(p)
	return ""

func witness_threat() -> void:
	if stage() != "active" or _state.childhood.ambush.seen: return
	_state.childhood.ambush.seen = true
	_remember("assault", "self", "observed", "Someone attacked me on the return trail. I do not know who sent him.")

func take_hit() -> void:
	if stage() != "active": return
	_state.childhood.ambush.hits += 1
	if _state.childhood.ambush.hits >= 3: _state.childhood.ambush.status = "caught"

func parry_threat() -> void:
	if stage() == "active": _state.childhood.ambush.stun_until = _state.childhood.tick + 90

func deflect() -> void:
	if stage() == "active" and _state.childhood.ambush.stun_until >= _state.childhood.tick:
		_state.childhood.ambush.deflected = true

func reach_home() -> String:
	if stage() != "active" or not near("home", 5.0): return "Return to the courtyard."
	_state.childhood.ambush.status = "escaped"
	_state.childhood.ambush.end_tick = _state.childhood.tick
	_remember("return", "self", "observed", "I returned alive. The attack does not tell me which household, if any, ordered it.")
	return ""

func _remember(id: String, source: String, channel: String, text: String) -> void:
	_state.childhood.memories.append({"id": id, "source_id": source, "channel": channel,
		"received_tick": _state.childhood.tick, "text": text})

func journal() -> Array:
	return _state.childhood.memories.duplicate(true)

static func valid_point(p: Variant) -> bool:
	if not p is Array or p.size() != 3: return false
	for value in p:
		if not Riding.finite_number(value): return false
	return absf(p[0]) <= 28.0 and absf(p[2]) <= 28.0 and p[1] >= -0.5 and p[1] <= 10.0

## Trusted subclass hook for a declared player/horse map, not an input-selected validator.
## Encounter, caravan and escort domains keep the original static valid_point contract.
func valid_player_point(p: Variant) -> bool:
	return valid_point(p)

func _shape(value: Variant, reference: Variant) -> bool:
	if reference is Dictionary:
		if not value is Dictionary or value.size() != reference.size(): return false
		for key in reference:
			if not value.has(key) or not _shape(value[key], reference[key]): return false
		return true
	if reference is Array: return value is Array
	if typeof(reference) in [TYPE_FLOAT, TYPE_INT]: return Riding.finite_number(value)
	return typeof(value) == typeof(reference)

func validate(value: Variant) -> String:
	var seed := _initial()
	if not _shape(value, seed): return "Malformed childhood snapshot."
	for key in ["schema_version", "profile", "scenario_id", "historical_class", "places", "relationships"]:
		if value[key] != seed[key]: return "Unsupported childhood identity or static data."
	if value.player.character_id != Names.HERO_ID or value.player.known_places != ["sukerchakia_home"]:
		return "Unknown protagonist or invented map knowledge."
	if not valid_player_point(value.player.position) or value.actors[Names.HERO_ID].position != value.player.position:
		return "Invalid or inconsistent protagonist pose."
	var s: Dictionary = value.childhood
	for key in ["tick", "ride_gate", "parries", "counters", "tracks"]:
		if s[key] != floor(s[key]) or s[key] < 0: return "Fractional or negative progress."
	if s.tick > 10000000 or s.ride_gate > 3 or s.parries > 2 or s.counters > 1 or s.tracks > 3:
		return "Progress exceeds profile."
	if s.walked < 0 or s.walked > 6 or s.looked < 0 or s.looked > 1: return "Invalid practice totals."
	var hours: float = 7.0 + s.tick / 216000.0
	if value.game_time.year != 1792 or value.game_time.day != 1 + int(hours / 24) or absf(value.game_time.hour - fmod(hours, 24)) > 1e-10:
		return "Clock does not agree with the scenario tick."
	if s.heard not in [[], ["steward"], ["courier"], ["steward", "courier"], ["courier", "steward"]]:
		return "Unknown or duplicate account."
	if not s.heard.is_empty() and not s.letter_seen: return "Account without acquired message."
	if s.ride_gate > 0 and (s.heard.size() != 2 or s.walked < 5 or s.looked < 0.6): return "Riding before orientation and oral briefing."
	if s.parries > 0 and s.ride_gate != 3: return "Sparring before riding."
	if s.counters > 0 and s.parries != 2: return "Counter before guard practice."
	if s.tracks > 0 and s.counters != 1: return "Tracking before sparring."
	if s.quarry_seen and s.tracks != 3: return "Quarry before tracking."
	var a: Dictionary = s.ambush
	if a.status not in ["locked", "ready", "active", "escaped", "caught"]: return "Invalid encounter status."
	if (a.status != "locked") != s.quarry_seen: return "Encounter before lessons."
	if not valid_point(a.position) or a.hits != floor(a.hits) or a.hits < 0 or a.hits > 3: return "Invalid encounter pose/damage."
	for key in ["start_tick", "end_tick"]:
		if a[key] != floor(a[key]) or a[key] < -1 or a[key] > s.tick: return "Invalid encounter time."
	if a.status in ["locked", "ready"] and (a.start_tick != -1 or a.end_tick != -1 or a.hits != 0 or a.seen or a.deflected):
		return "Encounter effects before encounter."
	if a.status in ["active", "escaped", "caught"] and a.start_tick < 0: return "Encounter has no start."
	if a.status == "escaped":
		if a.end_tick < a.start_tick or a.hits >= 3: return "Invalid escaped outcome."
	elif a.end_tick != -1: return "Unfinished encounter has end time."
	if a.stun_until != floor(a.stun_until) or a.stun_until < -1 or a.stun_until > s.tick + 90: return "Invalid stagger time."
	if a.status in ["locked", "ready"] and a.stun_until != -1: return "Stagger before encounter."
	if (a.status == "caught") != (a.hits == 3): return "Caught state and damage disagree."
	var error := Riding.validate(value.riding, value)
	if not error.is_empty(): return error
	if not valid_player_point(value.riding.horse.position): return "Horse left the home scene."
	var expected: Array = []
	if s.letter_seen: expected.append("letter")
	expected.append_array(s.heard)
	for i in range(int(s.tracks)): expected.append("track_%d" % (i + 1))
	if s.quarry_seen: expected.append("quarry")
	if s.reflected: expected.append("reflection")
	if a.seen: expected.append("assault")
	if a.status == "escaped": expected.append("return")
	if s.memories.size() != expected.size(): return "Memory and experienced events disagree."
	var prior := -1
	for memory in s.memories:
		if not _shape(memory, {"id":"", "source_id":"", "channel":"", "received_tick":0, "text":""}): return "Malformed memory."
		if memory.id not in expected or memory.received_tick != floor(memory.received_tick) or memory.received_tick < prior or memory.received_tick > s.tick:
			return "Duplicate, future or unsupported memory."
		expected.erase(memory.id)
		prior = int(memory.received_tick)
		if ACCOUNTS.has(memory.id):
			var account: Dictionary = ACCOUNTS[memory.id]
			if memory.source_id != account.source_id or memory.channel != account.channel or memory.text != account.claim: return "Attributed testimony was rewritten."
		elif not PERSONAL_MEMORIES.has(memory.id) or memory.source_id != "self" or memory.channel != ("inner_voice" if memory.id == "reflection" else "observed") or memory.text != PERSONAL_MEMORIES[memory.id]:
			return "Invalid firsthand memory."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty(): return error
	_state = value.duplicate(true)
	for key in ["tick", "ride_gate", "parries", "counters", "tracks"]: _state.childhood[key] = int(_state.childhood[key])
	for key in ["start_tick", "end_tick", "hits", "stun_until"]: _state.childhood.ambush[key] = int(_state.childhood.ambush[key])
	for memory in _state.childhood.memories: memory.received_tick = int(memory.received_tick)
	Riding.normalize(_state.riding)
	return ""

func save_to(path: String = SAVE_PATH) -> String:
	var error := validate(_state)
	if not error.is_empty(): return error
	var text := JSON.stringify(_state, "", true, true)
	if text.to_utf8_buffer().size() > LIMIT: return "Save too large."
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null: return "Cannot open temporary save."
	f.store_string(text)
	f.flush()
	var result := f.get_error()
	f.close()
	if result != OK: return "Save write failed."
	result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	return "" if result == OK else "Save replacement failed."

func load_from(path: String = SAVE_PATH) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return "No childhood save found."
	if f.get_length() > LIMIT:
		f.close()
		return "Save too large."
	var text := f.get_as_text()
	f.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return "Malformed childhood JSON."
	return restore(parser.data)
