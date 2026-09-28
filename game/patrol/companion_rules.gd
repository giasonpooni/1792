extends RefCounted
## Optional patrol profile; quantities are authored gameplay rules, not historical data.
## Allocation includes the captain: 2 scouts -> 1 companion; 4 riders -> 3 companions.

const VERSION := "companions.v1"
const SPEED := 6.0
const ASSEMBLY_RADIUS := 7.0
const CALL_RADIUS := 30.0
const HOME := Vector3(0, 0.04, 3)
const OFFSETS := [Vector3(-1.4, 0, 2.4), Vector3(1.4, 0, 2.4), Vector3(0, 0, 4.2)]

static func initial(order: Dictionary, captain: Vector3) -> Dictionary:
	var result := {"schema_version": VERSION, "order_id": order.id,
		"phase": "mustered", "instruction": "follow", "pending_outcome": "",
		"decision_tick": -1, "return_tick": -1, "members": []}
	for i in range(int(order.allocation.riders) - 1):
		var p: Vector3 = captain + OFFSETS[i]
		result.members.append({"id": order.id + ".trooper.%d" % (i + 1),
			"position": [p.x, p.y, p.z], "yaw": 0.0, "velocity": [0.0, 0.0, 0.0]})
	return result

static func number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func whole(value: Variant, minimum: int) -> bool:
	return number(value) and value >= minimum and float(value) == floorf(float(value))

static func vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and number(value[0]) and number(value[1]) and number(value[2])

static func point(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

static func horizontal(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

static func valid_member(member: Variant, expected_id: String) -> bool:
	if not member is Dictionary or member.size() != 4 or member.get("id") != expected_id:
		return false
	if not vector(member.get("position")) or not vector(member.get("velocity")) or not number(member.get("yaw")):
		return false
	var p := point(member.position)
	var v := point(member.velocity)
	return absf(p.x) <= 62.0 and p.z >= -87.0 and p.z <= 37.0 and p.y >= -1.0 and p.y <= 20.0 and absf(member.yaw) <= PI and Vector2(v.x, v.z).length() <= SPEED + 0.01 and v.y >= -50.0 and v.y <= 0.01

static func validate(value: Variant, world: Dictionary) -> String:
	if not value is Dictionary or value.size() != 8 or value.get("schema_version") != VERSION:
		return "Unsupported companion snapshot."
	for key in ["order_id", "phase", "instruction", "pending_outcome"]:
		if not value.get(key) is String:
			return "Malformed companion " + key
	if value.order_id != world.order.id or world.order.status == "available":
		return "Companions must belong to the currently allocated order."
	if value.instruction not in ["follow", "hold"] or value.pending_outcome not in ["", "secure", "withdraw"]:
		return "Invalid companion instruction or decision."
	if not whole(value.get("decision_tick"), -1) or not whole(value.get("return_tick"), -1):
		return "Invalid companion decision or return time."
	if not value.get("members") is Array or value.members.size() != int(world.order.allocation.riders) - 1:
		return "Companions disagree with the original allocation."
	for i in range(value.members.size()):
		if not valid_member(value.members[i], world.order.id + ".trooper.%d" % (i + 1)):
			return "Invalid companion identity, position or motion."
	var allowed := {"assigned": ["mustered"], "active": ["outbound", "returning"], "reporting": ["reporting"], "completed": ["completed"]}
	if value.phase not in allowed.get(world.order.status, []):
		return "Companion phase and command lifecycle disagree."
	if value.phase in ["mustered", "outbound"]:
		if value.pending_outcome != "" or value.decision_tick != -1 or value.return_tick != -1:
			return "An undecided patrol contains an outcome."
	else:
		if value.pending_outcome == "" or value.decision_tick < 0 or value.decision_tick > world.campaign_tick:
			return "A returning patrol needs a dated field decision."
		if value.pending_outcome == "secure":
			if world.order.visited != ["village", "outpost"] or world.order.allocation.riders < 3:
				return "A securing decision lacks observations or allocated strength."
			var politics = world.get("house_conflict")
			if not politics is Dictionary or not politics.get("phase") is String or not politics.get("decision") is String:
				return "Malformed house commission."
			if politics.phase != "dormant" and politics.decision not in ["respect_claim", "assert_authority", "reconcile"]:
				return "Companions cannot bypass an observation-only commission."
		if value.phase == "returning":
			if value.return_tick != -1:
				return "Returning companions have not checked in yet."
		else:
			if value.return_tick < value.decision_tick or value.return_tick > world.campaign_tick or world.reports.size() != 1:
				return "Invalid patrol check-in."
			if world.reports[0].observed_at != value.return_tick or world.reports[0].outcome != value.pending_outcome:
				return "Companion check-in and report disagree."
			if horizontal(point(world.actors.patrol_captain.position), HOME) > 3.5:
				return "The captain did not return to the courtyard."
			for member in value.members:
				if horizontal(point(member.position), HOME) > ASSEMBLY_RADIUS:
					return "A checked-in patrol still has a missing companion."
	return ""

static func normalize(value: Dictionary) -> void:
	value.decision_tick = int(value.decision_tick)
	value.return_tick = int(value.return_tick)
	for member in value.members:
		member.yaw = float(member.yaw)
		for field in ["position", "velocity"]:
			for i in range(3):
				member[field][i] = float(member[field][i])
