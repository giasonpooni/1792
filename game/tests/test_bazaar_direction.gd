# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## Reuse the three actual input-driven journeys; additional checks are presentation-only.
const Direction := preload("res://youth/performance/bazaar_director.gd")
const Dialogue := preload("res://youth/performance/bazaar_script.gd")
var current_chapter: Node3D
var snapshots: Dictionary={}
var clip: Array=[]
var outcomes: Dictionary={}
var route_name := ""
var new_checks := 0
func _initialize() -> void:
	physics_frame.connect(record_frame)
	run.call_deferred()
func ensure(value: bool,label: String) -> void:
	new_checks+=1;check(value,"direction: "+label)
func snapshot_view(scene: Node3D) -> Dictionary:
	var d: Node=scene.bazaar_performance
	return {"state":scene.model.snapshot(),"velocity":Base.coords(scene.avatar.velocity),"camera_pivot":Base.coords(scene.avatar.pivot.rotation),
		"message":scene._message,"speech":d.speech.duplicate(true),"guard":d._guard,"report_until":d.report_until,
		"prompt":d.prompt.text,"phase":scene.model.brawl_phase(),"tick":int(scene.model.progress().tick)}
func record_frame() -> void:
	if not is_instance_valid(current_chapter) or not is_instance_valid(current_chapter.bazaar_performance): return
	var scene:=current_chapter;var d: Node=scene.bazaar_performance
	if scene._paused or not scene.model.has_brawl(): return
	if not d.speech.is_empty() and not snapshots.has("friends-walking"): snapshots["friends-walking"]=snapshot_view(scene)
	if not d.speech.is_empty():
		var text: String=String(d.speech.text)
		if text.begins_with("Mind the baskets") and not snapshots.has("approach-goods"): snapshots["approach-goods"]=snapshot_view(scene)
		if text.begins_with("Look at that one") and not snapshots.has("approach-animal"): snapshots["approach-animal"]=snapshot_view(scene)
	if route_name=="fight" and scene.model.brawl_phase()=="fighting":
		for i in range(3):
			var pose: String=d.figures[i].pose_name
			if pose in ["windup","checked","down"] and not snapshots.has(pose): snapshots[pose]=snapshot_view(scene)
		if d._guard and int(scene.model.progress().tick)%4==0 and clip.size()<120: clip.append(snapshot_view(scene))
func press(scene,prefix: String) -> void:
	current_chapter=scene
	if prefix=="Stand with" or prefix=="Walk away":
		var before: Dictionary=scene.model.snapshot()
		var camera: Transform3D=scene.avatar.pivot.transform
		await super.press(scene,"Hear Mela")
		ensure(scene._panel_text.text=="BETWEEN FRIENDS\n\n"+Dialogue.FRIENDS,"optional companion exchange appears")
		ensure(scene.model.snapshot()==before,"listening adds no receipts, money, knowledge or time")
		ensure(scene.avatar.pivot.transform==camera,"listening does not seize camera")
		if not snapshots.has("friends-dialogue"):
			snapshots["friends-dialogue"]=snapshot_view(scene)
		await super.press(scene,"Back to the challenger")
		ensure(scene._panel_text.text=="AT THE BAZAAR · A SHORT WALK\n\n"+Dialogue.CHALLENGE,"return to the same unresolved challenge")
		ensure(scene.model.snapshot()==before,"returning from optional dialogue does not choose an outcome")
	await super.press(scene,prefix)
	if prefix=="Give the bazaar account":
		var outcome: String=scene.model.brawl().ledger.outcome
		ensure(scene._message==Dialogue.REPORT[outcome],"different written debrief for "+outcome)
		ensure(scene.model.journal().filter(func(m):return m.id=="youth-bazaar-report").size()==1,"one authoritative report remains")
		snapshots["ending-"+route_name]=snapshot_view(scene)
		outcomes[route_name]={"state":scene.model.snapshot(),"heard":scene.bazaar_performance.heard.duplicate(true),"sound_cues":scene.bazaar_performance.played.duplicate(true)}
func presentation_boundaries() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path="user://bazaar-direction-only.json"
	var seed=fresh();ok(Pose.pose(seed,Vector3(-12,.14,-18)),"direction explicit spatial fixture")
	var initial: Dictionary=seed.snapshot()
	for i in [3,4]: initial.youth_brawl.actors[i].position=Base.coords(Vector3(-13 if i==3 else -11,.14,-16))
	ok(scene.model.restore(initial),"direction fixture restore")
	root.add_child(home);await frames(8);look(scene,scene.youths[0].global_position);await tap(scene,KEY_E)
	await super.press(scene,"Stand with")
	scene._paused=true;scene.avatar.set_physics_process(false)
	var d: Node=scene.bazaar_performance
	var before: Dictionary=scene.model.snapshot()
	var poses: Array=[];var shapes: Array=[]
	for actor in scene.youths:
		poses.append(actor.global_transform)
		shapes.append(actor.get_child(0).shape.get_rid())
	for i in range(5): d.figures[i].sample(100,2.0,"windup",.8,true)
	d.sample(false)
	ensure(scene.model.snapshot()==before,"poses and HUD cannot mutate whole-world state")
	for i in range(5):
		ensure(scene.youths[i].global_transform==poses[i],"visual rig does not move actor "+str(i))
		ensure(scene.youths[i].get_child(0).shape.get_rid()==shapes[i],"original actor collider retained "+str(i))
	ensure(not d.canvas.visible,"modal hides performance HUD")
	d.sample(false);var sounds_before: int=d.played.size();d.rehydrate();d.sample(false)
	ensure(d.played.size()==sounds_before and d.speech.is_empty(),"load/hydration cannot replay old sound or a prior conversation")
	ensure(scene.model.snapshot()==before,"hydration creates no new memory")
	scene._paused=false
	ensure(d.audible(3),"friend initially has nearby visual contact")
	var a: Vector3=scene.youths[3].global_position;var p: Vector3=scene.avatar.global_position
	var wall=scene._box(Vector3(4,3,.2),(a+p)*.5+Vector3.UP,Color.GRAY,true)
	scene._paused=true;await frames(4)
	ensure(not d.audible(3),"new obstruction suppresses spoken cue")
	d.speech={"actor":3,"text":"discarded blocked fixture","until":int(scene.model.progress().tick)+99}
	scene._paused=false;d.sample()
	ensure(d.speech.is_empty(),"blocked line cannot persist as an offscreen subtitle")
	scene._paused=true;wall.get_parent().queue_free();await frames(4)
	var plain: Dictionary=scene.model.snapshot();d.toggle_sound();ensure(scene.model.snapshot()==plain,"sound toggle changes no game state")
	ensure(not d.sound_enabled,"sound toggle actually mutes this encounter")
	for sound in d.sounds: ensure(not sound.playing,"mute stops current foley")
	for kind in d._streams:
		var audio: AudioStreamWAV=d._streams[kind]
		ensure(audio.format==AudioStreamWAV.FORMAT_16_BITS and audio.mix_rate==22050 and not audio.stereo,"declared mono PCM "+kind)
		var peak:=0
		for i in range(0,audio.data.size(),2): peak=maxi(peak,absi(audio.data.decode_s16(i)))
		ensure(peak>0 and peak<32767,"nonempty unclipped foley "+kind)
	home.queue_free();await frames(4)
func run() -> void:
	await presentation_boundaries()
	for route in ["fight","leave","withdraw"]:
		route_name=route;await _journey(route)
	ensure(snapshots.has("windup") and snapshots.has("checked") and snapshots.has("down"),"actual fight produces windup, check and defeated poses")
	ensure(clip.size()>12,"actual fight yields motion observations")
	ensure(outcomes.fight.sound_cues.any(func(e):return e.kind=="check"),"actual checked strike emits foley cue")
	ensure(snapshots.has("approach-goods") and snapshots.has("approach-animal"),"actual physical approach triggers two ambient companion observations")
	ensure(outcomes.fight.heard.size()>0 and outcomes.leave.heard.size()>0,"nearby friends speak on both routes")
	var report: Dictionary={"schema":"1792.bazaar-direction.v1","engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,
		"new_assertions":new_checks,"passed":passed,"failed":failed,"snapshots":snapshots,"motion":clip,"outcomes":outcomes,
		"setup":"original three input-driven journeys after one completed-inquiry fixture each; separate spatial boundary fixture",
		"human_playtested":false,"voice_recorded":false,"historical_quotes":false}
	var file:=FileAccess.open("user://bazaar-direction.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	print("BAZAAR_DIRECTION_TESTS: %d passed, %d failed (%d new checks)"%[passed,failed,new_checks]);quit(1 if failed else 0)
