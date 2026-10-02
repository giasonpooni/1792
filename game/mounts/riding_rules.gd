extends RefCounted
## Stateless rules for one shared household horse. Campaign owns the dictionary.
## Coordinates are metres in the existing compressed sandbox, not historical data.

const VERSION := "riding.v1"
const HORSE_ID := "household_horse_01"
const MAX_SPEED := 11.0
const MAX_FALL := 50.0
const MOUNT_DISTANCE := 2.7
const DISMOUNT_SPEED := 0.6
# The trusted scene adapter admits a 2.1 m longitudinal exit on at most a
# 40-degree floor plus its bounded standing-shape lift. This remains local to
# the opt-in riding slice; it is not arbitrary vertical traversal authority.
const MAX_DISMOUNT_VERTICAL := 2.0

static func initial() -> Dictionary:
	return {"schema_version": VERSION, "horse": {
		"id": HORSE_ID, "rider_id": "", "position": [8.0, 0.04, -5.0],
		"yaw": 0.0, "speed": 0.0, "vertical_speed": 0.0, "grounded": true}}

static func position(horse: Dictionary) -> Vector3:
	var p: Array = horse.position
	return Vector3(p[0], p[1], p[2])

static func finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_FLOAT, TYPE_INT] and is_finite(float(value))

static func valid_position(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for coordinate in value:
		if not finite_number(coordinate):
			return false
	# This is the finite prototype's geometry envelope, NOT a territorial border.
	return absf(value[0]) <= 62.0 and value[1] >= -1.0 and value[1] <= 20.0 and value[2] >= -87.0 and value[2] <= 37.0

static func validate(value: Variant, world: Dictionary) -> String:
	if not value is Dictionary or value.size() != 2 or value.get("schema_version") != VERSION:
		return "Unsupported riding snapshot."
	var h = value.get("horse")
	var template: Dictionary = initial().horse
	if not h is Dictionary or h.size() != template.size():
		return "Malformed horse record."
	for key in template:
		if not h.has(key):
			return "Missing horse field: " + key
	if h.id != HORSE_ID or not h.rider_id is String or not h.grounded is bool:
		return "Invalid horse identity, rider or grounding flag."
	if not valid_position(h.position):
		return "Horse position is outside this prototype or not finite."
	for key in ["yaw", "speed", "vertical_speed"]:
		if not finite_number(h[key]):
			return "Expected finite horse " + key
	if absf(h.yaw) > PI or h.speed < 0.0 or h.speed > MAX_SPEED or h.vertical_speed < -MAX_FALL or h.vertical_speed > 0.0:
		return "Horse motion is out of bounds."
	if h.grounded and h.vertical_speed != 0.0:
		return "A grounded horse cannot be falling."
	if h.rider_id == "":
		if h.speed != 0.0 or h.vertical_speed != 0.0 or not h.grounded:
			return "A parked horse must be stopped and grounded."
	else:
		if h.rider_id not in ["ranjit_singh", "patrol_captain"] or h.rider_id != world.player.character_id:
			return "Only the active character may own mounted control."
		if world.actors[h.rider_id].position != h.position or world.player.position != h.position:
			return "Mounted actor and horse positions disagree."
		if h.rider_id == "patrol_captain" and (world.order.status != "active" or world.order.mode != "manual"):
			return "Delegated or inactive captains cannot control the horse."
	return ""

static func normalize(value: Dictionary) -> void:
	var h: Dictionary = value.horse
	for i in range(3):
		h.position[i] = float(h.position[i])
	for key in ["yaw", "speed", "vertical_speed"]:
		h[key] = float(h[key])
