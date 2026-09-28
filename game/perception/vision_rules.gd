extends RefCounted
## Authored perception model, not an ophthalmic simulation or historical disease schedule.
## The unaffected eye remains functional. Monocular vision is not half a black screen.
const DURATION := 18000 # Five minutes of active 60 Hz play; a design parameter, not historical time.
const PROFILES := ["authored_progressive_left", "stable_left_monocular", "stable_right_monocular"]

static func initial(tick: int = 0, profile: String = "authored_progressive_left") -> Dictionary:
	return {"schema_version":"vision.v1", "profile":profile, "onset_tick":tick}

static func validate(v: Variant, tick: int) -> String:
	if not v is Dictionary or v.size() != 3: return "Malformed vision profile."
	if v.get("schema_version") != "vision.v1" or v.get("profile") not in PROFILES: return "Unknown vision profile."
	var onset: Variant = v.get("onset_tick")
	if typeof(onset) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(onset)) or onset != floor(onset) or onset < 0 or onset > tick:
		return "Invalid vision onset."
	return ""

static func parameters(v: Dictionary, tick: int) -> Dictionary:
	var progressive: bool = v.profile == "authored_progressive_left"
	var progress := clampf(float(tick - int(v.onset_tick)) / DURATION, 0.0, 1.0)
	var loss := 0.2 + 0.8 * progress * progress if progressive else 1.0
	var left: bool = v.profile != "stable_right_monocular"
	return {"loss":loss, "affected_left":left,
		"left_acuity":1.0-loss if left else 1.0,
		"right_acuity":1.0 if left else 1.0-loss,
		"affected_half_angle":80.0-28.0*loss, "healthy_half_angle":80.0,
		"healthy_eye_offset":0.032 if left else -0.032,
		"stage":"monocular" if loss >= 0.999999 else "narrowing"}

static func visible(v: Dictionary, tick: int, bearing_radians: float, distance_metres: float, reach: float, unobstructed: bool) -> bool:
	if not unobstructed or not is_finite(bearing_radians) or not is_finite(distance_metres) or not is_finite(reach): return false
	if distance_metres < 0.0 or reach <= 0.0: return false
	var p := parameters(v,tick)
	var affected: bool = bearing_radians < 0.0 if p.affected_left else bearing_radians > 0.0
	var angle := absf(rad_to_deg(bearing_radians))
	var limit: float = p.affected_half_angle if affected else p.healthy_half_angle
	if angle > limit: return false
	var peripheral := clampf((angle-25.0)/55.0,0.0,1.0)
	var effective_reach := reach * (1.0-0.35*float(p.loss)*peripheral if affected else 1.0)
	return distance_metres <= effective_reach

static func bearing(forward: Vector3, toward: Vector3) -> float:
	var f := Vector2(forward.x,forward.z).normalized()
	var t := Vector2(toward.x,toward.z).normalized()
	# With forward = -Z, world -X is character-left and has a negative angle.
	return f.angle_to(t)
