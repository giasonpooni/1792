# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## Pure interpolation and labelled spatial fixtures; original journeys run separately.
const Attention:=preload("res://youth/performance/bazaar_attention.gd")
const Gaze:=preload("res://youth/performance/bazaar_gaze_track.gd")
var retained: Dictionary={}
func _initialize() -> void: run.call_deferred()
func pure_checks() -> void:
	var frame:=Transform3D.IDENTITY
	var a:=Attention.angles(frame,Vector3(.2,.15,-1))
	check(a.x<0 and a.y>0,"right/up target produces correctly signed -Z head rotations")
	check(Attention.eyes(a).x>0 and Attention.eyes(a).y>0,"pupils travel toward right/up target, not away")
	check(not Attention.eligible(frame,Vector3(0,0,1)),"behind-actor target cannot attract a new glance")
	check(not Attention.eligible(frame,Vector3(0,0,-9)),"distant target is refused")
	check(not Attention.eligible(frame,Vector3(INF,0,-1)),"nonfinite target is refused")
	check(Attention.eligible(frame,Vector3(.2,.1,-2)),"near front target remains eligible")
	var g=Gaze.new();g.sample(0,Vector2(.4,.12),true,3)
	var first: Dictionary=g.sample(1,Vector2(.4,.12),true,3)
	check(first.head.x>0 and first.head.x<.4 and first.eye.x<0,"eyes lead a partial head turn")
	var once: Dictionary=g.snapshot()
	for _i in range(40): g.sample(1,Vector2(.4,.12),true,3)
	check(g.snapshot()==once,"multiple same-tick refreshes neither accelerate nor accumulate gaze")
	var jiva=Gaze.new();jiva.sample(0,Vector2(.4,.12),true,4)
	var slower: Dictionary=jiva.sample(1,Vector2(.4,.12),true,4)
	check(slower.head.x<first.head.x,"Jiva takes longer to turn than Mela")
	var motion: Array=[]
	for tick in range(2,31):
		var pose: Dictionary=g.sample(tick,Vector2(.4,.12),true,3)
		motion.append(g.snapshot())
		check(absf(pose.head.x)<=Attention.MAX_HEAD_YAW and absf(pose.head.y)<=Attention.MAX_HEAD_PITCH,"head stays bounded tick "+str(tick))
	check(g.head.is_equal_approx(Vector2(.4,.12)),"head settles on the target without oscillation")
	check(g.eye.length()<.00001,"pupils recenter as head arrives")
	var saved: Dictionary=g.snapshot();var copy=Gaze.new()
	check(copy.restore(saved) and copy.snapshot()==saved,"transient visual record reopens exactly")
	var invalid: Dictionary=saved.duplicate(true);invalid.head=[99,0]
	check(not copy.restore(invalid) and copy.snapshot()==saved,"malformed playback data refuses atomically")
	var release: Dictionary=g.sample(31,Vector2.ZERO,false,3)
	check(release.head.x>0 and release.head.x<.4 and release.eye==Vector2.ZERO,"lost target releases head and immediately stops pupil tracking")
	for tick in range(32,61): g.sample(tick,Vector2.ZERO,false,3)
	check(g.head==Vector2.ZERO and g.eye==Vector2.ZERO,"unseen subject is not followed through a wall")
	g.sample(62,Vector2(.4,.12),true,3);g.sample(20,Vector2(.4,.12),true,3)
	check(g.head==Vector2.ZERO and g.tick_seen==20,"rewind clears future presentation history")
	var line: Dictionary={"actor":4,"until":210}
	check(Attention.listening_nod(54,line,3)<0,"Mela acknowledges a line with an early small nod")
	check(Attention.listening_nod(54,line,4)==0,"current speaker does not perform the listener nod")
	check(Attention.listening_nod(300,line,3)==0,"old dialogue cannot retain a listening reaction")
	retained["turn_samples"]=motion

func native_checks() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	var seed=fresh();ok(Pose.pose(seed,Vector3(-12,.14,-18)),"explicit pre-confrontation spatial fixture")
	var state: Dictionary=seed.snapshot()
	for i in [3,4]: state.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,.14,-16))
	ok(scene.model.restore(state),"fixture restore")
	root.add_child(home);await frames(8)
	scene._paused=true;scene.avatar.set_physics_process(false)
	var director: Node=scene.bazaar_performance
	var before: Dictionary=scene.model.snapshot();var camera: Transform3D=scene.avatar.pivot.transform
	var actor_root: Transform3D=scene.youths[3].global_transform
	var f: Node3D=director.figures[3]
	f.sample(200,0,"idle",0,false)
	f.apply_attention(.3,.1,Vector2(.025,.01),0)
	check(f.eyes[0].scale.is_equal_approx(Vector3(.035,.018,.018)),"open eyes preserve original millimetre-scale dimensions")
	check(absf(f.eyes[0].position.x-f.eye_origins[0].x)<=.003501,"pupils remain inside the authored eye socket")
	var head_pose: Vector3=f.head.rotation
	f.apply_attention(.3,.1,Vector2(.025,.01),0)
	check(f.head.rotation.is_equal_approx(head_pose),"repeated gaze application does not double head rotation")
	f.apply_attention(0,0,Vector2.ZERO,1)
	check(is_equal_approx(f.eyes[0].scale.y,.018*.12),"blink closes proportionally instead of stretching eye mesh")
	f.apply_attention(0,0,Vector2.ZERO,0)
	check(f.eyes[0].position==f.eye_origins[0] and f.eyes[0].scale==f.eye_scales[0],"blink releases to exact neutral face")
	var start: Vector3=scene.youths[3].global_position+Vector3.UP*1.5
	var target: Vector3=scene.avatar.global_position+Vector3.UP*1.35
	var gaze_frame:=Transform3D(Basis.looking_at(target-start),start)
	check(director._gaze_visible(gaze_frame,target,3),"nearby unobstructed conversational partner admitted")
	var wall=scene._box(Vector3(4,3,.2),(start+target)*.5,Color.GRAY,true)
	await frames(4)
	check(not director._gaze_visible(gaze_frame,target,3),"actual wall prevents new head/eye tracking")
	wall.get_parent().queue_free();await frames(4)
	var person: Node3D=scene.youths[0]
	var subject: Vector3=person.global_position+Vector3.UP*1.35
	gaze_frame=Transform3D(Basis.looking_at(subject-start),start)
	person.hide()
	check(not director._gaze_visible(gaze_frame,subject,3),"hidden cast member cannot attract attention")
	person.show()
	for i in range(10): director.sample(false)
	check(scene.avatar.pivot.transform==camera and scene.youths[3].global_transform==actor_root,"gaze changes neither player camera nor actor root")
	check(scene.model.snapshot()==before,"spatial and eye performance create no memories, costs or world-time changes")
	var visual: Dictionary=director.capture_attention()
	check(director.restore_attention(visual) and director.capture_attention()==visual,"whole cast transient attention reopens without game-state restore")
	var bad: Dictionary=visual.duplicate(true);bad.cast[0].eye=[100,100]
	check(not director.restore_attention(bad) and director.capture_attention()==visual,"bad cast playback cannot partly replace good gaze state")
	director.rehydrate()
	check(director.hero_gaze.head==Vector2.ZERO and director.gaze_tracks.all(func(t):return t.head==Vector2.ZERO),"F9 rehydration does not carry future glances across rewind")
	check(scene.model.snapshot()==before and scene.avatar.pivot.transform==camera,"presentation rehydration preserves world and camera")
	retained["native_fixture_state_unchanged"]=scene.model.snapshot()==before
	home.queue_free();await frames(4)

func run() -> void:
	pure_checks();await native_checks()
	retained.merge({"schema":"1792.bazaar-listening-checks.v1","passed":passed,"failed":failed,"engine":Engine.get_version_info().string,
		"fixture":"pure interpolation and labelled in-engine spatial/face checks, not a human playtest","human_playtested":false})
	var file:=FileAccess.open("user://bazaar-listening-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(retained,"\t",true,true));file.close()
	print("BAZAAR_LISTENING_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
