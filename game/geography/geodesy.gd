# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## WGS84 -> scalar-double ECEF -> bounded East/Up/South Godot coordinates.
## Angular indexing is NOT a metric projection. Never store global ECEF in Vector3.
const A := 6378137.0
const F := 1.0 / 298.257223563
const E2 := F * (2.0 - F)
const MAX_LOCAL_METRES := 2048.0
const DATUM := "WGS84-ellipsoidal-metres"

static func number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))

static func integer(v: Variant, lo: int, hi: int) -> bool:
	return number(v) and float(v) == floor(float(v)) and float(v) >= lo and float(v) <= hi

static func triple(v: Variant) -> bool:
	return v is Array and v.size() == 3 and number(v[0]) and number(v[1]) and number(v[2])

static func geographic(v: Variant) -> bool:
	return triple(v) and absf(float(v[0])) <= 180 and absf(float(v[1])) <= 90 and float(v[2]) >= -1000 and float(v[2]) <= 20000

static func ecef(llh: Array) -> Array:
	if not geographic(llh): return []
	var lon: float = deg_to_rad(float(llh[0]))
	var lat: float = deg_to_rad(float(llh[1]))
	var h: float = float(llh[2])
	var n: float = A / sqrt(1.0 - E2 * sin(lat) * sin(lat))
	return [(n + h) * cos(lat) * cos(lon), (n + h) * cos(lat) * sin(lon), (n * (1.0 - E2) + h) * sin(lat)]

static func geographic_from_ecef(xyz: Array) -> Array:
	if not triple(xyz): return []
	var x: float = float(xyz[0])
	var y: float = float(xyz[1])
	var z: float = float(xyz[2])
	var p: float = sqrt(x*x + y*y)
	if sqrt(p*p + z*z) < A - 100000: return []
	if p < 0.000001:
		var pole: Array = [0.0, 90.0 if z >= 0 else -90.0, absf(z) - A * (1.0-F)]
		return pole if geographic(pole) else []
	var lat: float = atan2(z, p * (1.0-E2))
	for _i in range(12):
		var n: float = A / sqrt(1.0-E2*sin(lat)*sin(lat))
		lat = atan2(z + E2*n*sin(lat), p)
	var n: float = A / sqrt(1.0-E2*sin(lat)*sin(lat))
	var h: float = p*cos(lat) + z*sin(lat) - n*(1.0-E2*sin(lat)*sin(lat))
	var result: Array = [rad_to_deg(atan2(y,x)), rad_to_deg(lat), h]
	return result if geographic(result) else []

static func frame_error(origin: Variant, datum: String) -> String:
	if datum != DATUM: return "An explicit ellipsoidal height is required; EGM96/unknown heights are not interchangeable."
	return "Invalid longitude, latitude or ellipsoidal height." if not geographic(origin) else ""

static func to_local(llh: Array, origin: Array, datum: String = DATUM) -> Dictionary:
	var error := frame_error(origin, datum)
	if not error.is_empty() or not geographic(llh): return {"error": error if not error.is_empty() else "Invalid point."}
	var p := ecef(llh)
	var o := ecef(origin)
	var dx: float = p[0]-o[0]
	var dy: float = p[1]-o[1]
	var dz: float = p[2]-o[2]
	var lon: float = deg_to_rad(origin[0])
	var lat: float = deg_to_rad(origin[1])
	var east: float = -sin(lon)*dx + cos(lon)*dy
	var north: float = -sin(lat)*cos(lon)*dx - sin(lat)*sin(lon)*dy + cos(lat)*dz
	var up: float = cos(lat)*cos(lon)*dx + cos(lat)*sin(lon)*dy + sin(lat)*dz
	if sqrt(east*east + north*north + up*up) > MAX_LOCAL_METRES:
		return {"error":"Point requires another local frame; no compressed or imprecise fallback."}
	return {"error":"", "metres":[east,up,-north]}

static func from_local(metres: Array, origin: Array, datum: String = DATUM) -> Dictionary:
	var error := frame_error(origin, datum)
	if not error.is_empty() or not triple(metres): return {"error":error if not error.is_empty() else "Invalid metric point."}
	var e: float = metres[0]
	var u: float = metres[1]
	var n: float = -float(metres[2])
	if sqrt(e*e + n*n + u*u) > MAX_LOCAL_METRES: return {"error":"Outside qualified local frame."}
	var lon: float = deg_to_rad(origin[0])
	var lat: float = deg_to_rad(origin[1])
	var p := ecef(origin)
	p[0] += -sin(lon)*e - sin(lat)*cos(lon)*n + cos(lat)*cos(lon)*u
	p[1] += cos(lon)*e - sin(lat)*sin(lon)*n + cos(lat)*sin(lon)*u
	p[2] += cos(lat)*n + sin(lat)*u
	var result := geographic_from_ecef(p)
	return {"error":"", "llh":result} if not result.is_empty() else {"error":"Unrepresentable geographic result."}

static func reframe(metres: Array, old_origin: Array, new_origin: Array) -> Dictionary:
	var result := from_local(metres, old_origin)
	return result if not result.error.is_empty() else to_local(result.llh, new_origin)

static func cell_key(lon: float, lat: float, divisions: int = 1) -> String:
	if not is_finite(lon) or not is_finite(lat) or absf(lon)>180 or absf(lat)>=90 or divisions not in [1,4,16,64]: return ""
	# Half-open ownership; +180 is the same meridian as -180. Not a distance metric.
	var wrapped: float = -180.0 if lon == 180.0 else lon
	return "ll%d:%d:%d" % [divisions, int(floor((wrapped+180)*divisions)), int(floor((lat+90)*divisions))]
