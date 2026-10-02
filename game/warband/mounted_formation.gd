# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Steering only. The existing horse motor owns acceleration, gravity and collision.
const Motor := preload("res://mounts/horse.gd")
const TRAFFIC_LAYER := 4
const ARRIVAL := 0.45
const PASS_CLEARANCE := 2.6

static func configure(mount: CharacterBody3D) -> void:
	mount.collision_layer=TRAFFIC_LAYER;mount.collision_mask=1|TRAFFIC_LAYER
	mount.safe_margin=.06

static func horizontal(v: Vector3) -> Vector3:
	return Vector3(v.x,0,v.z)

static func bounded(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x,-26.5,26.5),point.y,clampf(point.z,-26.5,26.5))

static func slot(leader: Vector3, yaw: float, index: int) -> Vector3:
	var offset := Basis(Vector3.UP,yaw)*Vector3(-2.2 if index==0 else 2.2,0,3.8)
	# The Home yard is bounded. A formation slot must remain inside its walls.
	return bounded(leader+offset)

static func traffic_goal(mount: CharacterBody3D, goal: Vector3, others: Array[CharacterBody3D]) -> Vector3:
	var offset := horizontal(goal-mount.global_position)
	if offset.length()<ARRIVAL: return goal
	var direction := offset.normalized()
	var right := direction.cross(Vector3.UP)
	var nearest: CharacterBody3D=null
	var ahead := minf(maxf(6.0,mount.speed*1.25+PASS_CLEARANCE),offset.length())
	for other in others:
		if other==mount or other.collision_layer==0: continue
		var relative := horizontal(other.global_position-mount.global_position)
		var along := relative.dot(direction)
		if along>0 and along<ahead and absf(relative.dot(right))<1.75:
			nearest=other;ahead=along
	if nearest==null: return goal
	# Keep the side already occupied; exact head-on meetings pass to their own right.
	var lateral := horizontal(mount.global_position-nearest.global_position).dot(right)
	var side := -1.0 if lateral<-.2 else 1.0
	# Approach the near-side flank first. A point beyond the other horse cuts
	# across its hull at close range and leaves both riders waiting nose-to-nose.
	return bounded(nearest.global_position+right*side*PASS_CLEARANCE-direction*PASS_CLEARANCE)

static func free_distance(mount: CharacterBody3D, direction: Vector3, reach: float) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=mount.get_node("Hull").shape
	query.transform=Transform3D(Basis.IDENTITY,mount.global_position+Vector3.UP*1.65)
	query.collision_mask=mount.collision_mask;query.exclude=[mount.get_rid()]
	var space := mount.get_world_3d().direct_space_state
	# cast_motion permits leaving an existing contact. Treating every initial
	# contact as zero clearance deadlocks two touching horses even when turning away.
	# The real motor still resolves contact on every step; saved overlaps are refused.
	query.motion=direction*reach
	var hit := space.cast_motion(query)
	return reach*hit[0] if hit.size()==2 else 0.0

static func step(mount: CharacterBody3D, waypoint: Vector3, delta: float) -> Dictionary:
	var offset := horizontal(waypoint-mount.global_position)
	var difference := wrapf(atan2(-offset.x,-offset.z)-mount.rotation.y,-PI,PI) if offset.length()>.05 else 0.0
	var speed_limit: float=mount.gait_speed_limit
	# v²/(2a), with one integration step and a small stand-off reserved before impact.
	var reach: float=maxf(1.0,mount.speed*mount.speed/(2*Motor.BRAKING)+mount.speed*delta+.5)
	var clear := free_distance(mount,-mount.global_basis.z,reach)
	var usable := maxf(0.0,clear-.22-mount.speed*delta)
	var target := minf(speed_limit,sqrt(2*Motor.BRAKING*maxf(0,offset.length()-ARRIVAL)))
	target=minf(target,sqrt(2*Motor.BRAKING*usable))
	if absf(difference)>.25: target=minf(target,2.0)
	if absf(difference)>.7 or offset.length()<ARRIVAL: target=0.0
	# Fractional throttle avoids repeatedly accelerating to full speed near a slot.
	return mount.step(delta,target/speed_limit,clampf(-difference*2,-1,1),false,false,target<.05)

static func separated(a: Vector3,b: Vector3,radius_sum: float) -> bool:
	return absf(a.y-b.y)>=3.2 or horizontal(a-b).length()>=radius_sum-.025
