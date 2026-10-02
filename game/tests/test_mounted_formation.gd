# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared native physics fixtures. No fixture pose is represented as played travel.
const Formation := preload("res://warband/mounted_formation.gd")
const Horse := preload("res://mounts/horse.tscn")
var passed:=0
var failed:=0
var course: Node3D
var mounts: Array[CharacterBody3D]=[]
var minimum_gap:=INF
var maximum_step:=0.0

func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("MOUNTED FORMATION: "+label)
func frames(n: int=2) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func box(at: Vector3,size: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var geometry:=BoxShape3D.new()
	geometry.size=size;shape.shape=geometry;body.add_child(shape);body.position=at;course.add_child(body);return body
func setup(poses: Array) -> void:
	course=Node3D.new();root.add_child(course)
	box(Vector3(0,-.2,0),Vector3(64,.4,64))
	mounts.clear();minimum_gap=INF;maximum_step=0.0
	for pose in poses:
		var mount: CharacterBody3D=Horse.instantiate();course.add_child(mount)
		Formation.configure(mount)
		mount.gait_speed_limit=6.0
		mount.apply_record({"position":[pose.x,.04,pose.z],"yaw":pose.y,"speed":0.0,"vertical_speed":0.0,"rider_id":"fixture"})
		mounts.append(mount)
	await frames()
func finish() -> void:
	course.queue_free();await frames()
func tick(goals: Array,avoid: bool=true) -> void:
	await physics_frame
	for i in range(mounts.size()):
		if goals[i]==null: continue
		var mount:=mounts[i];var before:=mount.global_position
		var goal: Vector3=Formation.traffic_goal(mount,goals[i],mounts) if avoid else goals[i]
		Formation.step(mount,goal,1.0/Engine.physics_ticks_per_second)
		maximum_step=maxf(maximum_step,Formation.horizontal(mount.global_position-before).length())
	for a in range(mounts.size()):
		for b in range(a+1,mounts.size()):
			minimum_gap=minf(minimum_gap,Formation.horizontal(mounts[a].global_position-mounts[b].global_position).length())

func braking(hz: int) -> float:
	Engine.physics_ticks_per_second=hz
	await setup([Vector3(0,0,8),Vector3(0,0,0)])
	var top_speed:=0.0
	for _i in range(hz*6):
		await tick([Vector3(0,0,-8),null],false);top_speed=maxf(top_speed,mounts[0].speed)
	check(top_speed>5.5,"approach reaches normal trot at %d Hz"%hz)
	check(minimum_gap>=1.575,"stationary horse remains solid at %d Hz: %f"%[hz,minimum_gap])
	check(mounts[0].speed<.08,"follower brakes to rest before parked horse at %d Hz"%hz)
	check(mounts[0].position.z>1.7 and mounts[0].position.z<2.1,"bounded stand-off at %d Hz: %s"%[hz,mounts[0].position])
	check(maximum_step<=6.0/hz+.015,"no position recovery jump at %d Hz"%hz)
	var stopped: float=mounts[0].position.z
	await finish();return stopped

func crossing(head_on: bool) -> void:
	await setup([Vector3(0,0,8),Vector3(0,PI,-8)] if head_on else [Vector3(0,0,8),Vector3(-8,-PI/2,0)])
	var goals: Array=[Vector3(0,0,-9),Vector3(0,0,9) if head_on else Vector3(9,0,0)]
	for _i in range(1200): await tick(goals)
	var label:="head-on" if head_on else "crossing"
	check(minimum_gap>=1.575,label+" horses never interpenetrate: "+str(minimum_gap))
	for i in range(2):
		check(Formation.horizontal(mounts[i].position-goals[i]).length()<.65,label+" rider reaches destination: "+str(mounts[i].position))
		check(mounts[i].speed<.08,label+" rider settles without circling")
	check(maximum_step<=.115,label+" route contains only motor movement")
	await finish()

func obstacles() -> void:
	await setup([Vector3(0,0,8)])
	for _i in range(45): await tick([Vector3(0,0,-8)],false)
	var wall:=box(Vector3(0,1.7,2),Vector3(8,3.4,.3));await frames()
	for _i in range(180): await tick([Vector3(0,0,-8)],false)
	check(mounts[0].position.z>3.05,"new obstacle blocks existing approach")
	check(mounts[0].speed<.08,"new obstacle triggers braking")
	wall.queue_free();await frames()
	for _i in range(300): await tick([Vector3(0,0,-8)],false)
	check(mounts[0].position.z< -7.3,"removed obstacle releases stopped rider without teleport")
	await finish()
	await setup([Vector3(0,0,6)])
	box(Vector3(-2.8,1.7,0),Vector3(4.4,3.4,5))
	box(Vector3(2.8,1.7,0),Vector3(4.4,3.4,5));await frames()
	for _i in range(300): await tick([Vector3(0,0,-6)],false)
	check(mounts[0].position.z>3,"horse refuses a gap narrower than its hull")
	check(mounts[0].speed<.08,"narrow gap stops motion rather than repeated full throttle")
	await finish()

func run() -> void:
	var leader:=Vector3(0,.04,0)
	check(Formation.slot(leader,0,0).z>leader.z,"northward rider follows behind leader")
	check(Formation.slot(leader,PI/2,0).x>leader.x,"formation rotates behind westward leader")
	check(Formation.slot(Vector3(27,0,27),PI/2,1).x<=26.5,"formation respects yard boundary")
	var stop60:=await braking(60);var stop30:=await braking(30)
	check(absf(stop60-stop30)<.12,"braking stand-off stable across 30 and 60 Hz")
	Engine.physics_ticks_per_second=60
	await crossing(true);await crossing(false);await obstacles()
	print("MOUNTED_FORMATION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
