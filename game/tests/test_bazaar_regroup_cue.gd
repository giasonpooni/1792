# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## Labelled spatial fixtures for a gesture. Existing input-driven journeys cover outcomes.
const Cue := preload("res://youth/performance/bazaar_regroup_cue.gd")

func _initialize() -> void: run.call_deferred()

func pure_checks() -> void:
	var positions: Array=[R.RING,R.RING,R.RING,R.REGROUP+Vector3(-1,0,1),R.REGROUP+Vector3(-5,0,0)]
	var speeds: Array=[Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO]
	var down: Array=[false,false,false]
	var found:=Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true])
	check(found.get("actor",-1)==3 and found.get("other",-1)==4,"nearby Mela signals for lagging Jiva")
	check(float(found.amount)>.74 and float(found.amount)<.96,"signal remains restrained")
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true])==found,"same world tick gives the same pose")
	for phase in ["none","invited","challenged","returning","reported","caught"]:
		check(Cue.read(phase,100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"no wait cue during "+phase)
	check(Cue.read("leaving",100,R.RING,positions,speeds,down,[true,true]).is_empty(),"no regroup signal on the outward walk")
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[false,true]).is_empty(),"a blocked companion cannot signal unseen knowledge")
	speeds[3]=Vector3(1,0,0)
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"running friend retains locomotion rather than hand signal")
	speeds[3]=Vector3.ZERO
	positions[0]=R.REGROUP+Vector3(3,0,0)
	check(Cue.read("fighting",100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"nearby active attacker takes precedence")
	down[0]=true
	check(not Cue.read("fighting",100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"a downed attacker does not suppress the retreat cue")
	positions[4]=R.REGROUP+Vector3(-4.5,0,0)
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"existing 4.5 metre regroup boundary ends the gesture")
	positions[4]=R.REGROUP+Vector3(-12,0,0)
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true]).is_empty(),"distant companion is not tracked")
	positions[4]=R.REGROUP+Vector3(1,0,1);positions[3]=R.REGROUP+Vector3(-5,0,0)
	check(Cue.read("leaving",100,R.REGROUP,positions,speeds,down,[true,true]).get("actor",-1)==4,"Jiva can be the waiting companion")
	check(Cue.read("leaving",100,R.REGROUP,[],speeds,down,[true,true]).is_empty(),"incomplete cast yields no cue")

func waiting_fixture() -> Node3D:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	var seed=fresh();ok(Pose.pose(seed,R.RING),"labelled pre-challenge fixture")
	var staged: Dictionary=seed.snapshot()
	for i in [3,4]: staged.youth_brawl.actors[i].position=Base.coords(R.RING+Vector3(i-3,0,1))
	ok(seed.restore(staged),"fixture companions at challenge")
	ok(seed.brawl_action("challenge"),"fixture accepts challenge")
	ok(seed.brawl_action("leave"),"fixture chooses departure")
	ok(Pose.pose(seed,R.REGROUP),"labelled arrival fixture")
	staged=seed.snapshot()
	staged.youth_brawl.actors[3].position=Base.coords(R.REGROUP+Vector3(-1,0,1))
	staged.youth_brawl.actors[4].position=Base.coords(R.REGROUP+Vector3(-5,0,0))
	ok(scene.model.restore(staged),"fixture leaves one companion behind")
	scene.set_physics_process(false)
	root.add_child(home)
	scene.set_physics_process(false);scene.avatar.set_physics_process(false);scene._paused=true
	await frames(4)
	scene.bazaar_performance.sample(false)
	return home

func native_checks() -> void:
	var home: Node3D=await waiting_fixture();var scene=home.get_node("ChildhoodChapter");var d: Node=scene.bazaar_performance
	var before: Dictionary=scene.model.snapshot();var camera: Transform3D=scene.avatar.pivot.transform
	var roots: Array=[];var shapes: Array=[]
	for actor in scene.youths:
		roots.append(actor.global_transform);shapes.append(actor.get_child(0).shape.get_rid())
	check(d.regroup_cue.get("actor",-1)==3,"native geometry admits waiting friend")
	check(d.figures[3].pose_name=="gather" and d.figures[4].pose_name=="idle","only waiting friend performs signal")
	var arm: Vector3=d.figures[3].elbows[0].rotation
	check(arm.x<-.8,"wait gesture raises existing forearm visibly")
	for i in range(20): d.sample(false)
	check(d.figures[3].elbows[0].rotation==arm,"same-tick refresh does not accumulate arm rotations")
	check(scene.model.snapshot()==before,"gesture creates no world time, memory, payment or event")
	check(scene.avatar.pivot.transform==camera,"gesture never directs player camera")
	for i in range(5):
		check(scene.youths[i].global_transform==roots[i],"actor root unchanged "+str(i))
		check(scene.youths[i].get_child(0).shape.get_rid()==shapes[i],"original collision retained "+str(i))
	var between: Vector3=(scene.youths[3].global_position+scene.youths[4].global_position)*.5+Vector3.UP
	var wall=scene._box(Vector3(.20,3,4),between,Color.GRAY,true)
	await frames(4);d.sample(false)
	check(d.regroup_cue.is_empty() and d.figures[3].pose_name!="gather","real wall suppresses gesture through blocked sight")
	wall.get_parent().queue_free();await frames(4);d.sample(false)
	check(d.regroup_cue.get("actor",-1)==3,"clear sight restores present-tense signal")
	scene.youths[4].hide();d.sample(false)
	check(d.regroup_cue.is_empty(),"hidden companion cannot trigger visual knowledge")
	scene.youths[4].show();d.sample(false)
	d.rehydrate()
	check(scene.model.snapshot()==before and d.speech.is_empty(),"rehydration derives geometry without replayed dialogue or receipts")
	var position: Vector3=scene.youths[4].global_position
	scene.youths[4].global_position=R.REGROUP+Vector3(1,0,1);d.sample(false)
	check(d.regroup_cue.is_empty() and d.figures[3].pose_name=="idle","both friends back in range releases the signal")
	scene.youths[4].global_position=position
	d.enabled=false;d.sample(false)
	check(d.regroup_cue.is_empty(),"disabled performance clears cue")
	home.queue_free();await frames(4)

func run() -> void:
	pure_checks();await native_checks()
	print("BAZAAR_REGROUP_CUE_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
