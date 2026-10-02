# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Rigid-ring presentation on inextensible authored strips, not a contact solver.
## Same input tick -> same pose; no simulation clock or integration history.
const Meshes:=preload("res://presentation/equipment_mesh.gd")
const COLUMNS:=32
const ROWS:=16
const PITCH:=.014
const RING_RADIUS:=.0095
const WIRE_RADIUS:=.00135
const MAX_TICK:=10000000
const BOUNDS:=AABB(Vector3(-.21,-.25,-.21),Vector3(.42,.27,.42))
var links: MultiMeshInstance3D
var ring_transforms: Array[Transform3D]=[]
var _last_tick: int=-1
var _last_strength: float=-1.0

func build() -> void:
	name="MailAventail"
	set_meta("historical_claim",false)
	set_meta("gameplay_authority",false)
	set_meta("contact_simulation",false)
	var ring:=TorusMesh.new()
	ring.inner_radius=RING_RADIUS-WIRE_RADIUS
	ring.outer_radius=RING_RADIUS+WIRE_RADIUS
	ring.rings=12
	ring.ring_segments=6
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=ring
	batch.instance_count=COLUMNS*ROWS
	batch.custom_aabb=BOUNDS
	ring_transforms.resize(COLUMNS*ROWS)
	links=MultiMeshInstance3D.new()
	links.name="RigidRings"
	links.multimesh=batch
	links.material_override=Meshes.material("84908b",.8,.44)
	add_child(links)
	sample_tick(0,0.0)

static func anchor(column: int) -> Vector3:
	# A front opening is an authored visibility choice, not attribution to the reference object.
	var azimuth:=lerpf(deg_to_rad(56),deg_to_rad(304),float(column)/(COLUMNS-1))
	return Vector3(.119*sin(azimuth),-.005,.132*cos(azimuth))

func sample_tick(tick: int, strength: float=1.0) -> bool:
	if tick<0 or tick>MAX_TICK or not is_finite(strength) or strength<0 or strength>1 or not is_instance_valid(links): return false
	if tick==_last_tick and strength==_last_strength: return true
	for column in range(COLUMNS):
		var azimuth:=lerpf(deg_to_rad(56),deg_to_rad(304),float(column)/(COLUMNS-1))
		var radial:=Vector3(sin(azimuth),0,cos(azimuth))
		var point:=anchor(column)
		for row in range(ROWS):
			var depth:=float(row)/(ROWS-1)
			# Fixed-length segments articulate outwards. The top row never receives motion.
			var bend:=.13+.10*depth+strength*.10*depth*sin(float(tick%480)*TAU/480.0-depth*1.4+column*.12)
			if row>0: point+=(radial*sin(bend)+Vector3.DOWN*cos(bend))*PITCH
			var weave_tilt:=.48 if row%2==0 else -.48
			var basis:=Basis(Vector3.UP,azimuth)*Basis(Vector3.RIGHT,PI/2-bend)*Basis(Vector3.BACK,weave_tilt)
			var index:=column*ROWS+row
			ring_transforms[index]=Transform3D(basis,point)
			links.multimesh.set_instance_transform(index,ring_transforms[index])
	_last_tick=tick
	_last_strength=strength
	return true
