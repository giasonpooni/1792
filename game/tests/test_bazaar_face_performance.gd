# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_bazaar_direction.gd"
## Scene-level face tests plus the original three input journeys; no fabricated human review.
const FaceScore := preload("res://youth/performance/bazaar_expression.gd")
const Attention := preload("res://youth/performance/bazaar_attention.gd")
var performances: Dictionary={}
var face_checks := 0

func facial(value: bool,label: String) -> void:
	face_checks+=1;check(value,"face: "+label)

func view_faces(chapter: Node3D) -> Array:
	var result: Array=[]
	for figure in chapter.bazaar_performance.figures:
		result.append({"expression":figure.expression_name,"head":Base.coords(figure.head.rotation),
			"eyes":figure.eyes.map(func(e):return {"position":Base.coords(e.position),"scale":Base.coords(e.scale)}),
			"brows":figure.brows.map(func(e):return {"position":Base.coords(e.position),"rotation":Base.coords(e.rotation)}),
			"mouth":figure.mouth.map(func(e):return {"position":Base.coords(e.position),"rotation":Base.coords(e.rotation)})})
	return result

func record_frame() -> void:
	super.record_frame()
	if not is_instance_valid(current_chapter) or current_chapter._paused: return
	var d: Node=current_chapter.bazaar_performance
	var tick:=int(current_chapter.model.progress().tick)
	if tick!=d.last_tick: return
	if current_chapter.model.brawl_phase()=="fighting":
		for cast_index in [0,3,4]:
			var cast_name: String=d.figures[cast_index].expression_name
			var cast_key:="%d-%s"%[cast_index,cast_name]
			if not performances.has(cast_key):
				var cast_observation:=snapshot_view(current_chapter)
				cast_observation.actor=cast_index;cast_observation.faces=view_faces(current_chapter)
				performances[cast_key]=cast_observation
	if d.speech.is_empty(): return
	var age:=tick-int(d.speech.get("started",tick))
	if age<24 or age>150: return
	var index:=int(d.speech.actor)
	var name: String=d.figures[index].expression_name
	var key:="%d-%s"%[index,name]
	if not performances.has(key):
		var observation:=snapshot_view(current_chapter)
		observation.actor=index;observation.faces=view_faces(current_chapter)
		performances[key]=observation

func face_boundaries() -> void:
	var home:=Launch.make_world();var scene: Node3D=home.get_node("ChildhoodChapter")
	scene.save_path="user://face-performance-boundary.json"
	var seed=fresh();ok(Pose.pose(seed,Vector3(-12,.14,-18)),"face explicit spatial setup")
	var initial: Dictionary=seed.snapshot()
	for i in [3,4]: initial.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,.14,-16))
	ok(scene.model.restore(initial),"face setup restore")
	root.add_child(home);await frames(8);look(scene,scene.youths[0].global_position);await tap(scene,KEY_E)
	await super.press(scene,"Stand with")
	scene._paused=true;scene.avatar.set_physics_process(false);scene.set_physics_process(false)
	var d: Node=scene.bazaar_performance
	var before: Dictionary=scene.model.snapshot()
	var bodies: Array=scene.youths.map(func(body):return body.global_transform)
	var camera: Transform3D=scene.avatar.pivot.transform
	var figure: Node3D=d.figures[3]
	for name in FaceScore.POSES:
		figure.sample(120,0,"idle")
		figure.apply_attention(.1,0,Vector2(.003,0),.3)
		figure.apply_expression(name)
		facial(figure.expression_name==name,"named authored face is rendered: "+name)
		for i in range(2):
			facial(figure.eyes[i].scale.y<=figure.eye_scales[i].y+1e-7 and figure.eyes[i].scale.y>=figure.eye_scales[i].y*.12-1e-7,"eye stays at original anatomical scale")
			facial(figure.brows[i].position.distance_to(figure.brow_origins[i])<.007,"brow displacement bounded in metres")
	figure.sample(120,0,"idle");figure.apply_attention(0,0,Vector2.ZERO,0);figure.apply_expression("neutral")
	for i in range(2):
		facial(figure.eyes[i].scale.is_equal_approx(figure.eye_scales[i]),"open blink returns original eye scale")
		facial(figure.brows[i].position==figure.brow_origins[i],"neutral restores brow")
	for i in range(3): facial(figure.mouth[i].position==figure.mouth_origins[i],"neutral restores mouth")
	figure.apply_attention(.3,.1,Vector2(.003,.002),1)
	var first: Vector3=figure.head.rotation
	for i in range(10): figure.apply_attention(.3,.1,Vector2(.003,.002),1)
	facial(figure.head.rotation==first,"repeated same-tick attention is idempotent")
	facial(is_equal_approx(figure.eyes[0].scale.y,figure.eye_scales[0].y*.12),"closed blink shrinks rather than enlarges original eye")
	facial(Attention.angles(Transform3D.IDENTITY,Vector3(0,1,-3)).y>0,"an above-head target pitches upward")
	facial(Attention.angles(Transform3D.IDENTITY,Vector3(1,0,-3)).x<0,"right target turns head right with negative-Z forward")
	facial(Attention.eyes(Vector2(-.3,.1)).x>0,"right target shifts pupils right")
	facial(Attention.angles(Transform3D.IDENTITY,Vector3(0,0,3))==Vector2.ZERO,"no through-the-back tracking")
	var old_tick:=int(scene.model.progress().tick)
	d.speech={"actor":3,"text":"Explicit fixture: not played dialogue.","started":old_tick-30,"until":old_tick+120,"duration":150}
	d.sample(false)
	var fixed_faces:=view_faces(scene)
	for i in range(12): d.sample(false)
	facial(view_faces(scene)==fixed_faces,"render sampling cannot accumulate expression or advance acting time")
	facial(scene.model.snapshot()==before and scene.avatar.pivot.transform==camera,"performance cannot change state or camera")
	facial(scene.youths.map(func(body):return body.global_transform)==bodies,"performance cannot move physical actors")
	var from: Vector3=figure.torso.global_transform*figure.head.position
	var target: Vector3=scene.avatar.global_position+Vector3.UP*1.35
	facial(d.gaze_clear(from,target),"nearby eye-line begins unobstructed")
	var block=scene._box(Vector3(4,3,.2),(from+target)*.5,Color.GRAY,true)
	await frames(4)
	facial(not d.gaze_clear(from,target),"wall interrupts eye-line")
	d.sample(false)
	facial(figure.gaze_rotation==Vector2.ZERO,"occluded speaker cannot track through wall")
	block.get_parent().queue_free();await frames(4)
	facial(not d.gaze_clear(from,from+Vector3.FORWARD*20),"distant actor cannot be silently tracked")
	var heard_before: int=d.heard.size();d.rehydrate();d.sample(false)
	facial(d.speech.is_empty() and d.heard.size()==heard_before,"hydration does not replay delivery or invent dialogue")
	facial(scene.model.snapshot()==before,"rehydration preserves whole-world state")
	var line: Dictionary={"actor":3,"started":100,"until":200,"duration":100}
	facial(FaceScore.delivery(line,99).speaker==-1 and FaceScore.delivery(line,200).speaker==-1,"speech emphasis only inside delivery interval")
	facial(FaceScore.delivery(line,124).nod>0 and absf(FaceScore.delivery(line,190).nod)<1e-6,"one early emphasis settles instead of endlessly moving mouth")
	facial(FaceScore.choose(3,"returning","stood_ground",false,"idle",{"performance_beat":"regroup:stood_ground:1"})=="chastened","Mela's victory boast changes when Jiva notices his concern")
	facial(FaceScore.choose(3,"returning","stood_ground",false,"idle",{"performance_beat":"regroup:stood_ground:2"})=="relieved","Mela's admission settles into relief")
	home.queue_free();await frames(4)

func run() -> void:
	await presentation_boundaries()
	await face_boundaries()
	for route in ["fight","leave","withdraw"]:
		route_name=route;await _journey(route)
	facial(performances.has("3-amused"),"actual walk supplies Mela's amusement")
	facial(performances.has("4-wry"),"actual walk supplies Jiva's dry reply")
	facial(performances.has("3-resolute"),"actual fight supplies Mela's resolve")
	facial(performances.has("4-relieved"),"actual departure or homecoming supplies Jiva's relief")
	var report: Dictionary={"schema":"1792.bazaar-face-performance.v1","passed":passed,"failed":failed,
		"face_assertions":face_checks,"performances":performances,"outcomes":outcomes,
		"source":"original three input-driven journeys plus explicit isolated boundary fixtures",
		"human_playtest":false,"recorded_voice":false,"lip_sync":false}
	var file:=FileAccess.open("user://bazaar-face-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	print("BAZAAR_FACE_TESTS: %d passed, %d failed (%d face checks)"%[passed,failed,face_checks]);quit(1 if failed else 0)
