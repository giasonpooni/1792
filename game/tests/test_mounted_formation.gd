# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared native physics fixtures. No fixture pose is represented as played travel.
const Formation := preload("res://warband/mounted_formation.gd")
const Horse := preload("res://mounts/horse.tscn")
const Navigation := preload("res://patrol/patrol_navigator.gd")
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

func place_on_support(mount: CharacterBody3D, z: float, yaw: float) -> void:
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(0,30,z),Vector3(0,-1,z),1,[mount.get_rid()])
	var hit:=course.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty(),"declared terrain fixture has real support")
	if hit.is_empty(): return
	mount.apply_record({"position":[0,hit.position.y+.28,z],"yaw":yaw,"speed":0.0,"vertical_speed":0.0,"rider_id":"terrain-fixture"})
	for _i in range(20):
		await physics_frame;mount.step(1.0/60,0,0,false,false,true)

func terrain() -> void:
	await setup([Vector3(0,0,4)])
	var slope:=box(Vector3(0,5,0),Vector3(8,.3,18));slope.rotation.x=deg_to_rad(30)
	await frames();await place_on_support(mounts[0],4,0)
	var low:=mounts[0].position;var air:=0
	for _i in range(480):
		await tick([Vector3(0,0,-4)],false);air+=int(not mounts[0].is_on_floor())
	check(mounts[0].position.z< -3.3 and mounts[0].position.y>low.y+3.5,"follower climbs actual 30-degree support: "+str(mounts[0].position))
	check(air==0 and mounts[0].speed<.08,"slope following and arrival remain grounded")
	for _i in range(540): await tick([Vector3(0,0,4)],false)
	check(mounts[0].position.z>3.3 and mounts[0].position.y<low.y+.6,"follower turns and descends the same support")
	check(mounts[0].is_on_floor() and maximum_step<=.12,"slope movement remains within motor displacement budget")
	await finish()
	await setup([Vector3(0,0,7)])
	box(Vector3(0,2,5),Vector3(8,.4,10));await frames();await place_on_support(mounts[0],7,0)
	air=0
	for _i in range(360):
		await tick([Vector3(0,0,-6)],false);air+=int(not mounts[0].is_on_floor())
	check(mounts[0].position.z>.2 and mounts[0].position.y>2.1,"follower brakes on upper platform before a two-metre drop")
	check(mounts[0].speed<.08 and air==0,"unsupported edge does not become an automatic fall")
	await finish()
	await setup([Vector3(0,0,6)])
	# A 20 cm ledge is within existing floor-snap support; no step teleport is added.
	box(Vector3(0,-.1,5),Vector3(8,.6,10));await frames();await place_on_support(mounts[0],6,0)
	for _i in range(360): await tick([Vector3(0,0,-6)],false)
	check(mounts[0].position.z< -5.3 and mounts[0].is_on_floor(),"bounded small descent reaches the lower floor: "+str(mounts[0].position)+" / "+str(Formation.Terrain.inspect(mounts[0],Vector3.FORWARD,1)))
	await finish()
	await setup([Vector3(0,0,7)])
	var steep:=box(Vector3(0,3.064,0),Vector3(8,.3,8));steep.rotation.x=deg_to_rad(50)
	await frames()
	for _i in range(300): await tick([Vector3(0,0,-4)],false)
	check(mounts[0].position.z>2.7 and mounts[0].position.y<.3 and mounts[0].speed<.08,"follower refuses a 50-degree climb")
	await finish()
	await setup([Vector3(0,0,7)])
	box(Vector3(0,2,7),Vector3(8,.4,6))
	box(Vector3(0,2,0),Vector3(1,.4,8));await frames();await place_on_support(mounts[0],7,0)
	for _i in range(360): await tick([Vector3(0,0,-3)],false)
	check(mounts[0].position.z>4 and mounts[0].position.y>2.1 and mounts[0].speed<.08,"centre-only support cannot admit a bridge narrower than the horse footprint")
	await finish()

func narrow_passage() -> void:
	await setup([Vector3(0,0,7),Vector3(-2.2,0,10.8),Vector3(2.2,0,10.8)])
	box(Vector3(-3.1,1.7,0),Vector3(3.8,3.4,8))
	box(Vector3(3.1,1.7,0),Vector3(3.8,3.4,8));await frames()
	var riders: Array[CharacterBody3D]=[mounts[1],mounts[2]]
	var ignored: Array[RID]=[]
	for mount in mounts: ignored.append(mount.get_rid())
	var navigation:=Navigation.new();Formation.configure_navigation(navigation)
	navigation.bind(course.get_world_3d(),ignored)
	var file_ticks:=0;var last_mode:="";var gap:=INF
	for _i in range(1500):
		await physics_frame
		var leader:=mounts[0]
		leader.step(1.0/60,.35 if leader.position.z> -13 else 0,0,false,false,leader.position.z<= -13)
		var plan:=Formation.layout(leader,riders,func(body,goal): return Formation.Terrain.path_clear(body,goal,ignored))
		last_mode=plan.mode;file_ticks+=int(last_mode=="single file")
		for i in range(2):
			var goal: Vector3=plan.goals[i]
			if plan.mode=="paired": goal=Formation.traffic_goal(riders[i],goal,mounts)
			if not Formation.Terrain.path_clear(riders[i],goal,ignored): goal=navigation.waypoint(riders[i].position,goal)
			Formation.step(riders[i],goal,1.0/60)
		for i in range(3):
			for j in range(i+1,3): gap=minf(gap,Formation.horizontal(mounts[i].position-mounts[j].position).length())
	check(file_ticks>60,"jatha adopts single file for a 2.4-metre passage")
	check(riders[0].position.z< -5 and riders[1].position.z< -5,"both riders pass through the real narrow corridor: "+str([riders[0].position,riders[1].position]))
	check(gap>=1.575,"single file maintains physical horse separation: "+str(gap))
	check(last_mode=="paired","group opens back out after clearing the walls")
	await finish()

func stop_start_column(hz: int) -> Vector2:
	Engine.physics_ticks_per_second=hz
	await setup([Vector3(0,0,12),Vector3(0,0,15.4),Vector3(0,0,18.8)])
	var riders: Array[CharacterBody3D]=[mounts[1],mounts[2]]
	var starts: Array[Vector3]=[riders[0].position,riders[1].position]
	var restart: Array[Vector3]=[]
	var peaks: Array[float]=[0.0,0.0]
	var yaws: Array[float]=[0.0,0.0]
	var rest_speed:=0.0
	var gap:=INF
	var largest_step:=0.0
	for i in range(hz*15):
		await physics_frame
		var t:=float(i)/hz
		var before: Array[Vector3]=[mounts[0].position,riders[0].position,riders[1].position]
		var moving:=t<3 or (t>=8 and t<10)
		mounts[0].step(1.0/hz,.8 if moving else 0,0,false,false,not moving)
		var plan:=Formation.layout(mounts[0],riders,func(_body,_goal): return false)
		for j in range(2):
			Formation.step(riders[j],plan.goals[j],1.0/hz)
			peaks[j]=maxf(peaks[j],riders[j].speed)
			yaws[j]=maxf(yaws[j],absf(riders[j].rotation.y))
			if t>=7 and t<8: rest_speed=maxf(rest_speed,riders[j].speed)
		for j in range(3):
			largest_step=maxf(largest_step,Formation.horizontal(mounts[j].position-before[j]).length())
			for k in range(j+1,3):
				gap=minf(gap,Formation.horizontal(mounts[j].position-mounts[k].position).length())
		if i==hz*8-1: restart=[riders[0].position,riders[1].position]
	for j in range(2):
		check(Formation.horizontal(riders[j].position-starts[j]).length()>15,"column rider %d travels more than 15 metres at %d Hz"%[j,hz])
		check(peaks[j]>3,"column rider %d reaches riding speed at %d Hz"%[j,hz])
		check(Formation.horizontal(riders[j].position-restart[j]).length()>5,"column rider %d resumes after waiting at %d Hz"%[j,hz])
		check(riders[j].speed<.08 and absf(riders[j].rotation.y)<.1 and yaws[j]<.1,"column rider %d settles facing forward without reversing at %d Hz"%[j,hz])
	check(gap>=3,"column preserves three-metre spacing during both stops at %d Hz: %f"%[hz,gap])
	check(rest_speed<.08,"column holds a steady rest between seven and eight seconds at %d Hz: %f"%[hz,rest_speed])
	check(largest_step<=6.0/hz+.015,"column movement uses only bounded motor steps at %d Hz: %f"%[hz,largest_step])
	var gaps:=Vector2(Formation.horizontal(mounts[0].position-riders[0].position).length(),Formation.horizontal(riders[0].position-riders[1].position).length())
	await finish();return gaps

func run() -> void:
	var leader:=Vector3(0,.04,0)
	check(Formation.slot(leader,0,0).z>leader.z,"northward rider follows behind leader")
	check(Formation.slot(leader,PI/2,0).x>leader.x,"formation rotates behind westward leader")
	check(Formation.slot(Vector3(27,0,27),PI/2,1).x<=26.5,"formation respects yard boundary")
	var stop60:=await braking(60);var stop30:=await braking(30)
	check(absf(stop60-stop30)<.12,"braking stand-off stable across 30 and 60 Hz")
	Engine.physics_ticks_per_second=60
	await crossing(true);await crossing(false);await obstacles()
	await terrain();await narrow_passage()
	var column60:=await stop_start_column(60);var column30:=await stop_start_column(30)
	check(column60.distance_to(column30)<.3,"rested column gaps remain stable at 30 and 60 Hz: %s / %s"%[column60,column30])
	Engine.physics_ticks_per_second=60
	print("MOUNTED_FORMATION_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
