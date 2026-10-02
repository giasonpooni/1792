extends "res://mahan/mahan_state.gd"
## Mahan-only adapter around the existing riding.v1 library contract.
## Base Mahan and Lahore/house authorities remain unchanged.
const Riding := preload("res://mounts/riding_rules.gd")
const HOUSEHOLD_ID := "sukerchakia"
var _riding: Dictionary = {}

func enable_riding() -> void:
	if _riding.is_empty():
		_riding = Riding.initial()
		_riding.horse.position = [3.5, 0.04, 1.5]
		_riding.horse.yaw = -0.4

func snapshot() -> Dictionary:
	var out: Dictionary = super.snapshot()
	out.mahan.household_id = HOUSEHOLD_ID
	if not _riding.is_empty():
		out.riding = _riding.duplicate(true)
	return out

func horse_state() -> Dictionary:
	return _riding.horse.duplicate(true) if not _riding.is_empty() else {}

func is_mounted() -> bool:
	return not _riding.is_empty() and _riding.horse.rider_id != ""

func mount_horse() -> String:
	if _riding.is_empty() or is_mounted():
		return "No available field horse."
	var h: Dictionary = _riding.horse
	if distance(position(), Riding.position(h)) > Riding.MOUNT_DISTANCE:
		return "Walk closer to the field horse."
	if not h.grounded or h.speed != 0.0:
		return "The horse must be stopped on the ground."
	h.rider_id = ACTOR_ID
	_set_position(Riding.position(h))
	return ""

func dismount_horse(landing: Vector3) -> String:
	if not is_mounted():
		return "You are not mounted."
	var h: Dictionary = _riding.horse
	if h.speed > Riding.DISMOUNT_SPEED or not h.grounded:
		return "Stop on solid ground before dismounting."
	if not landing.is_finite():
		return "No clear dismount position."
	var offset := landing - Riding.position(h)
	var horizontal := Vector2(offset.x, offset.z).length()
	if horizontal < 1.2 or horizontal > 2.8 or absf(offset.y) > 0.7 or not valid_point(coords(landing)):
		return "No clear dismount position."
	h.rider_id = ""
	h.speed = 0.0
	h.vertical_speed = 0.0
	_set_position(landing)
	return ""

func record_position(p: Vector3, delta: float) -> String:
	return "Dismount before walking samples." if is_mounted() else super.record_position(p, delta)

func record_ride(motion: Dictionary, delta: float) -> String:
	if not is_mounted() or not is_finite(delta) or delta <= 0.0 or delta > 0.25:
		return "No valid mounted physics step."
	if motion.size() != 5:
		return "Malformed horse motion."
	var next := _riding.duplicate(true)
	for key in ["position", "yaw", "speed", "vertical_speed", "grounded"]:
		if not motion.has(key):
			return "Incomplete horse motion."
		next.horse[key] = motion[key]
	if not valid_point(next.horse.position):
		return "Invalid horse position."
	var travelled := Riding.position(next.horse) - Riding.position(_riding.horse)
	if Vector2(travelled.x, travelled.z).length() > Riding.MAX_SPEED * delta + 0.1 or absf(travelled.y) > Riding.MAX_FALL * delta + 0.1:
		return "Horse step exceeds the movement envelope."
	var error := _validate_riding(next, next.horse.position, next.horse.position)
	if not error.is_empty():
		return error
	_riding = next
	_set_position(Riding.position(next.horse))
	return ""

func dispatch_scout(target: String) -> String:
	return "Dismount before dispatching a scout detachment." if is_mounted() else super.dispatch_scout(target)

func decide_column(choice: String) -> String:
	return "Dismount before issuing a column order." if is_mounted() else super.decide_column(choice)

func march_to(next: String) -> String:
	return "Dismount before committing the horse column." if is_mounted() else super.march_to(next)

func acknowledge_fixed_endpoint() -> String:
	return "Dismount before closing the interlude beat." if is_mounted() else super.acknowledge_fixed_endpoint()

func validate(value: Variant) -> String:
	if not value is Dictionary:
		return "Malformed Mahan cavalry snapshot."
	var core: Dictionary = value.duplicate(true)
	var riding = core.get("riding")
	core.erase("riding")
	if core.has("mahan"):
		if core.mahan.get("household_id") != HOUSEHOLD_ID:
			return "Sukerchakia must remain a Household graph object."
		core.mahan.erase("household_id")
	var base_error := super.validate(core)
	if not base_error.is_empty():
		return base_error
	return "" if riding == null else _validate_riding(riding, value.player.position, value.actors[ACTOR_ID].position)

func _validate_riding(value: Variant, player_pos: Variant, actor_pos: Variant) -> String:
	if not value is Dictionary or value.get("schema_version") != Riding.VERSION:
		return "Unsupported riding snapshot."
	var h = value.get("horse")
	var template: Dictionary = Riding.initial().horse
	if not h is Dictionary or h.size() != template.size():
		return "Malformed horse record."
	for key in template:
		if not h.has(key):
			return "Missing horse field: " + key
	if h.id != Riding.HORSE_ID or not h.rider_id is String or not h.grounded is bool or not valid_point(h.position):
		return "Invalid field-horse identity, rider, grounding, or position."
	for key in ["yaw", "speed", "vertical_speed"]:
		if not Riding.finite_number(h[key]):
			return "Expected finite horse motion."
	if absf(h.yaw) > PI or h.speed < 0.0 or h.speed > Riding.MAX_SPEED or h.vertical_speed < -Riding.MAX_FALL or h.vertical_speed > 0.0:
		return "Horse motion is out of bounds."
	if h.grounded and h.vertical_speed != 0.0:
		return "A grounded horse cannot be falling."
	if h.rider_id == "":
		return "" if h.speed == 0.0 and h.vertical_speed == 0.0 and h.grounded else "A parked horse must be stopped and grounded."
	if h.rider_id != ACTOR_ID or player_pos != h.position or actor_pos != h.position:
		return "Only Mahan Singh may own mounted control in this interlude."
	return ""

func restore(value: Variant) -> String:
	var error := validate(value)
	if not error.is_empty():
		return error
	var core: Dictionary = value.duplicate(true)
	var riding = core.get("riding")
	core.erase("riding")
	error = super.restore(core)
	if error.is_empty():
		_riding = {} if riding == null else riding.duplicate(true)
		if not _riding.is_empty():
			Riding.normalize(_riding)
	return error

func save_to(path: String = SAVE_PATH) -> String:
	var value := snapshot()
	var error := validate(value)
	if not error.is_empty():
		return error
	var text := JSON.stringify(value, "", true, true)
	if text.to_utf8_buffer().size() > LIMIT:
		return "Save too large."
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return "Cannot open temporary save."
	f.store_string(text)
	f.flush()
	var result := f.get_error()
	f.close()
	if result != OK:
		return "Save write failed."
	result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	return "" if result == OK else "Save replacement failed."

func load_from(path: String = SAVE_PATH) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "No Mahan save found."
	if f.get_length() > LIMIT:
		f.close()
		return "Save too large."
	var text := f.get_as_text()
	f.close()
	var parser := JSON.new()
	return "Malformed Mahan JSON." if parser.parse(text) != OK else restore(parser.data)
