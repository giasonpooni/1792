extends RefCounted
## One authority for the command sandbox; scenes submit actions, never outcomes.

const SEED_PATH := "res://data/command_sandbox.json"
const RANJIT := "ranjit_singh"
const CAPTAIN := "patrol_captain"
const PACKAGES := {
	"scout": {"riders": 2, "supplies": 3, "treasury": 10},
	"patrol": {"riders": 4, "supplies": 6, "treasury": 20}
}
const REPORT_DELAY := 4
const SAVE_LIMIT := 1048576
var _state: Dictionary

func _init() -> void:
	_state = JSON.parse_string(FileAccess.get_file_as_string(SEED_PATH))

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func actor_id() -> String:
	return _state.player.character_id

func actor_position(id: String) -> Vector3:
	var p: Array = _state.actors[id].position
	return Vector3(p[0], p[1], p[2])

func place(id: String) -> Dictionary:
	for item in _state.places:
		if item.id == id:
			return item.duplicate(true)
	return {}

func near_site(id: String) -> bool:
	var site := place(id)
	if site.is_empty():
		return false
	var p: Array = site.position
	var delta := actor_position(actor_id()) - Vector3(p[0], p[1], p[2])
	delta.y = 0.0
	return delta.length() <= 4.0

func record_position(position: Vector3) -> void:
	if not position.is_finite():
		return
	var p := [position.x, position.y, position.z]
	_state.actors[actor_id()].position = p
	_state.player.position = p.duplicate()

func issue(package_id: String) -> String:
	if actor_id() != RANJIT or not near_site("lahore_darbar"):
		return "Issue orders as Ranjit at the courtyard table."
	if _state.order.status != "available" or not PACKAGES.has(package_id):
		return "No available order or unknown allocation."
	var allocation: Dictionary = PACKAGES[package_id].duplicate()
	for key in allocation:
		if _state.resources[key] < allocation[key]:
			return "Insufficient " + key + "."
	for key in allocation:
		_state.resources[key] -= allocation[key]
	_state.order.id = "road_patrol_%04d" % int(_state.next_order)
	_state.next_order += 1
	_state.order.allocation = allocation
	_state.order.status = "assigned"
	_event("order_issued", RANJIT)
	return ""

func cancel() -> String:
	if actor_id() != RANJIT or _state.order.status != "assigned":
		return "Only an unstarted order can be cancelled."
	for key in _state.order.allocation:
		_state.resources[key] += _state.order.allocation[key]
	_event("order_cancelled", RANJIT)
	_state.order.id = ""
	_state.order.status = "available"
	_state.order.allocation = {"riders": 0, "supplies": 0, "treasury": 0}
	return ""

func play_commander() -> String:
	if actor_id() != RANJIT or _state.order.status not in ["assigned", "active"]:
		return "Assign an order before taking command."
	_state.order.status = "active"
	_state.order.mode = "manual"
	_switch(CAPTAIN)
	_event("control_taken", CAPTAIN)
	return ""

func delegate() -> String:
	if actor_id() != RANJIT or _state.order.status != "assigned":
		return "Only an assigned order can be delegated here."
	_state.order.status = "active"
	_state.order.mode = "delegated"
	_event("order_delegated", RANJIT)
	return ""

func return_to_darbar() -> String:
	if actor_id() != CAPTAIN or _state.order.status != "active":
		return "No playable command is active."
	_state.order.mode = "delegated"
	_switch(RANJIT)
	_event("control_released", CAPTAIN)
	return ""

func visit(site_id: String) -> String:
	if actor_id() != CAPTAIN or _state.order.status != "active":
		return "Only the assigned captain can conduct this patrol."
	if not near_site(site_id):
		return "Move closer to the marked location."
	return _visit(site_id)

func resolve(choice: String) -> String:
	if actor_id() != CAPTAIN or _state.order.status != "active":
		return "No player-controlled patrol is active."
	if choice == "secure" and not near_site("outpost"):
		return "Reach the outpost before organizing its patrol."
	return _resolve(choice)

func advance(ticks: int = 1) -> void:
	# One tick = one game minute. No wall clock or unseeded randomness.
	for _i in range(clampi(ticks, 0, 10000)):
		_state.campaign_tick += 1
		_advance_calendar()
		if _state.order.status == "active" and _state.order.mode == "delegated":
			_delegate_tick()
		for report in _state.reports:
			if not report.delivered and _state.campaign_tick >= report.arrives_at:
				report.delivered = true
				for site_id in _state.order.visited:
					if site_id not in _state.actors[RANJIT].known_places:
						_state.actors[RANJIT].known_places.append(site_id)
				_switch(RANJIT)
				_state.resources.riders += _state.order.allocation.riders
				_state.order.status = "completed"
				_event("report_received", RANJIT)

func received_reports() -> Array:
	var received: Array = []
	for report in _state.reports:
		if report.delivered:
			received.append(report.duplicate(true))
	return received

func _visit(site_id: String) -> String:
	var expected := "village" if _state.order.visited.is_empty() else "outpost"
	if site_id != expected or site_id in _state.order.visited:
		return "Visit the village, then the outpost; each observation counts once."
	_state.order.visited.append(site_id)
	if site_id not in _state.actors[CAPTAIN].known_places:
		_state.actors[CAPTAIN].known_places.append(site_id)
	if actor_id() == CAPTAIN:
		_state.player.known_places = _state.actors[CAPTAIN].known_places.duplicate()
	_event("site_observed:" + site_id, CAPTAIN)
	return ""

func _resolve(choice: String) -> String:
	if choice not in ["secure", "withdraw"]:
		return "Unknown patrol decision."
	if choice == "secure":
		if _state.order.visited != ["village", "outpost"]:
			return "Observe both locations first."
		if _state.order.allocation.riders < 3:
			return "Two scouts cannot hold this road. Withdraw and report instead."
	var secured := choice == "secure"
	for item in _state.places:
		if item.id == "outpost":
			item.security = clampf(item.security + (0.25 if secured else -0.10), 0.0, 1.0)
	_state.relationships[0].trust = clampf(
		_state.relationships[0].trust + (0.10 if secured else -0.05), 0.0, 1.0)
	_state.order.status = "reporting"
	_state.order.mode = ""
	_state.reports.append({
		"id": _state.order.id + ".report", "order_id": _state.order.id,
		"observer_id": CAPTAIN, "observed_at": _state.campaign_tick,
		"arrives_at": _state.campaign_tick + REPORT_DELAY, "delivered": false,
		"outcome": choice, "road_security": place("outpost").security if "outpost" in _state.order.visited else null
	})
	_event("patrol_resolved:" + choice, CAPTAIN)
	_switch(RANJIT)
	return ""

func _delegate_tick() -> void:
	# Deliberately simple policy, not general commander AI. Same visit/resolve rules.
	if _state.order.visited.size() == 2:
		_resolve("secure" if _state.order.allocation.riders >= 3 else "withdraw")
		return
	var target_id := "village" if _state.order.visited.is_empty() else "outpost"
	var p: Array = place(target_id).position
	var target := Vector3(p[0], p[1], p[2])
	var next := actor_position(CAPTAIN).move_toward(target, 5.0)
	_state.actors[CAPTAIN].position = [next.x, next.y, next.z]
	if next.distance_to(target) < 0.1:
		_visit(target_id)

func _switch(id: String) -> void:
	_state.player.character_id = id
	_state.player.position = _state.actors[id].position.duplicate()
	_state.player.known_places = _state.actors[id].known_places.duplicate()

func _event(kind: String, actor: String) -> void:
	_state.events.append({"sequence": _state.events.size() + 1,
		"tick": _state.campaign_tick, "kind": kind, "actor_id": actor,
		"order_id": _state.order.id})

func _advance_calendar() -> void:
	_state.game_time.hour = (roundf(_state.game_time.hour * 60.0) + 1.0) / 60.0
	if _state.game_time.hour >= 24.0:
		_state.game_time.hour -= 24.0
		_state.game_time.day += 1
	var y := int(_state.game_time.year)
	var leap := y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)
	if _state.game_time.day > (366 if leap else 365):
		_state.game_time.day = 1
		_state.game_time.year += 1

func save_to(path: String) -> String:
	var error := validate(_state)
	if not error.is_empty():
		return error
	var payload := JSON.stringify(_state, "", true, true)
	if payload.to_utf8_buffer().size() > SAVE_LIMIT:
		return "Save exceeds the prototype size limit."
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "Cannot open save file: " + error_string(FileAccess.get_open_error())
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "Save write failed: " + error_string(write_error)
	var renamed := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	return "" if renamed == OK else "Save replacement failed: " + error_string(renamed)

func load_from(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "No readable command-sandbox save."
	if file.get_length() > SAVE_LIMIT:
		file.close()
		return "Save exceeds the prototype size limit."
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return "Malformed save JSON; current session was not changed."
	return restore(parser.data)

func restore(candidate: Variant) -> String:
	var error := validate(candidate)
	if error.is_empty():
		_state = candidate.duplicate(true)
	return error

func validate(candidate: Variant) -> String:
	var seed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SEED_PATH))
	var shape_error := _shape(candidate, seed, "state")
	if not shape_error.is_empty():
		return shape_error
	var s: Dictionary = candidate
	for key in ["schema_version", "command_schema_version", "scenario_id", "historical_class"]:
		if s[key] != seed[key]:
			return "Unsupported " + key
	if not _whole(s.campaign_tick, 0) or not _whole(s.next_order, 1):
		return "Invalid clock or order sequence."
	if s.campaign_tick > 1000000000 or s.next_order > 1000000:
		return "Clock or order sequence exceeds prototype bounds."
	if not _whole(s.game_time.year, 1801) or not _whole(s.game_time.day, 1):
		return "Invalid scenario date."
	var y := int(s.game_time.year)
	var days := 366 if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0) else 365
	if s.game_time.day > days or s.game_time.hour < 0 or s.game_time.hour >= 24:
		return "Invalid day or hour."
	if s.actors.size() != 2 or not s.actors.has(s.player.character_id):
		return "Unknown playable actor."
	for actor in s.actors.values():
		if not _position(actor.position):
			return "Invalid actor position."
	if s.player.position != s.actors[s.player.character_id].position:
		return "Player and actor position disagree."
	if s.player.known_places != s.actors[s.player.character_id].known_places:
		return "Player and actor knowledge disagree."
	if s.places.size() != 3 or s.relationships.size() != 1:
		return "Unexpected scenario entity count."
	for i in range(s.places.size()):
		if s.places[i].id != seed.places[i].id or not _position(s.places[i].position):
			return "Unknown place or invalid location."
		if s.places[i].security < 0 or s.places[i].security > 1:
			return "Invalid security."
	if s.relationships[0].actor_id != CAPTAIN or s.relationships[0].trust < 0 or s.relationships[0].trust > 1:
		return "Invalid relationship."
	for actor in s.actors.values():
		var known: Array = []
		for id in actor.known_places:
			if id not in ["lahore_darbar", "village", "outpost"] or id in known:
				return "Invalid known places."
			known.append(id)
	var order: Dictionary = s.order
	if order.issuer_id != RANJIT or order.commander_id != CAPTAIN:
		return "Invalid command authority."
	if order.status not in ["available", "assigned", "active", "reporting", "completed"]:
		return "Invalid order status."
	if order.visited not in [[], ["village"], ["village", "outpost"]]:
		return "Invalid observation sequence."
	if order.status == "active":
		if order.mode not in ["manual", "delegated"]:
			return "Active command has no executor."
	elif order.mode != "":
		return "Inactive command has an executor."
	var expected_actor := CAPTAIN if order.mode == "manual" else RANJIT
	if s.player.character_id != expected_actor:
		return "Control and command executor disagree."
	var allocation: Dictionary = order.allocation
	if order.status == "available":
		if allocation != seed.order.allocation or order.id != "" or not order.visited.is_empty():
			return "Available command holds an allocation or progress."
	elif allocation not in PACKAGES.values() or order.id != "road_patrol_%04d" % (int(s.next_order) - 1):
		return "Invalid allocation or order identity."
	if order.status == "assigned" and not order.visited.is_empty():
		return "Unstarted command has progress."
	for key in seed.resources:
		var reserved: int = allocation[key]
		if key == "riders" and order.status == "completed":
			reserved = 0
		if not _whole(s.resources[key], 0) or s.resources[key] != seed.resources[key] - reserved:
			return "Resource accounting mismatch: " + key
	var needs_report: bool = order.status in ["reporting", "completed"]
	if s.reports.size() != (1 if needs_report else 0):
		return "Report and order lifecycle disagree."
	for report in s.reports:
		var template := {"id": "", "order_id": "", "observer_id": "", "observed_at": 0,
			"arrives_at": 0, "delivered": false, "outcome": ""}
		if not _shape(report, template, "report").is_empty():
			return "Malformed report."
		if report.order_id != order.id or report.id != order.id + ".report" or report.observer_id != CAPTAIN:
			return "Report identity mismatch."
		if not _whole(report.observed_at, 0) or report.observed_at > s.campaign_tick:
			return "Invalid observation time."
		if report.arrives_at != report.observed_at + REPORT_DELAY:
			return "Invalid report delivery time."
		if report.delivered != (order.status == "completed") or report.delivered != (s.campaign_tick >= report.arrives_at):
			return "Invalid report delivery state."
		if report.outcome not in ["secure", "withdraw"] or not report.has("road_security"):
			return "Invalid report outcome."
		if "outpost" in order.visited:
			if report.road_security != s.places[2].security:
				return "Observed security and report disagree."
		elif report.road_security != null:
			return "Unobserved outpost cannot have reported security."
		if report.outcome == "secure" and (allocation.riders < 3 or order.visited.size() != 2):
			return "Unsupported successful outcome."
	if s.events.size() > 10000:
		return "Event limit exceeded."
	var previous_tick := 0
	for i in range(s.events.size()):
		var event = s.events[i]
		if not _shape(event, {"sequence": 0, "tick": 0, "kind": "", "actor_id": "", "order_id": ""}, "event").is_empty():
			return "Malformed event."
		if event.sequence != i + 1 or not _whole(event.tick, previous_tick) or event.tick > s.campaign_tick:
			return "Invalid event sequence."
		if not s.actors.has(event.actor_id):
			return "Unknown event actor."
		previous_tick = int(event.tick)
	return ""

func _shape(value: Variant, template: Variant, path: String) -> String:
	if typeof(template) in [TYPE_INT, TYPE_FLOAT]:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return "Expected finite number at " + path
	elif typeof(value) != typeof(template):
		return "Wrong type at " + path
	elif template is Dictionary:
		for key in template:
			if not value.has(key):
				return "Missing " + path + "." + key
			var error := _shape(value[key], template[key], path + "." + key)
			if not error.is_empty():
				return error
	elif template is Array and not template.is_empty():
		for item in value:
			var error := _shape(item, template[0], path + "[]")
			if not error.is_empty():
				return error
	return ""

func _whole(value: Variant, minimum: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value >= minimum and float(value) == floor(float(value))

func _position(value: Array) -> bool:
	if value.size() != 3:
		return false
	for coordinate in value:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)) or absf(float(coordinate)) > 1000000.0:
			return false
	return true
