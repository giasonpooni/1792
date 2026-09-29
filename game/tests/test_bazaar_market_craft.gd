# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Market:=preload("res://youth/performance/bazaar_market_stage.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("BAZAAR CRAFT FAIL: "+label)
func frames(n:=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func run() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	root.add_child(home);await frames(8)
	var stage: Node3D=scene.bazaar_performance.market_stage
	check(is_instance_valid(stage),"market stage attached to shipped Home scene")
	check(stage.get_meta("classification","")=="original-prototype-market-dressing","stage identifies authored status")
	check(stage.awnings.size()==2 and stage.hanging.size()==8 and stage.vendor_roots.size()==3,"bounded composition inventory")
	check(stage.find_children("*","CollisionShape3D",true,false).is_empty(),"market dressing adds no gameplay collision")
	check(stage.find_children("*","StaticBody3D",true,false).is_empty(),"market dressing adds no hidden physics body")
	var before: Dictionary=scene.model.snapshot();var actor_poses: Array=[]
	for actor in scene.youths: actor_poses.append(actor.global_transform)
	for tick in [0,60,240,600]:
		stage.sample(tick,true);scene.bazaar_performance.sample(false)
	check(scene.model.snapshot()==before,"market/pose sampling changes no world state")
	for i in range(scene.youths.size()): check(scene.youths[i].global_transform==actor_poses[i],"visual craft never moves actor "+str(i))
	var figure: Node3D=scene.bazaar_performance.figures[0]
	for action in ["windup","strike","checked","recover"]:
		figure.sample(200,0,action,.8,false)
		check(figure.position.length()<.22,"visual-only footwork stays inside bounded presentation envelope "+action)
	check(scene.bazaar_performance.ambience.stream is AudioStreamWAV,"market ambience uses local generated WAV")
	var audio: AudioStreamWAV=scene.bazaar_performance.ambience.stream
	check(audio.loop_mode==AudioStreamWAV.LOOP_FORWARD and audio.mix_rate==22050 and not audio.stereo,"ambience is bounded looping mono PCM")
	var peak:=0
	for i in range(0,audio.data.size(),2): peak=maxi(peak,absi(audio.data.decode_s16(i)))
	check(peak>0 and peak<32767,"ambience is nonempty and unclipped")
	scene.bazaar_performance.sound_enabled=true
	scene.bazaar_performance.ambience.play();scene.bazaar_performance.toggle_sound()
	check(not scene.bazaar_performance.ambience.playing and not scene.bazaar_performance.sound_enabled,"mute stops ambient bed immediately")
	check(scene.model.snapshot()==before,"mute changes no game authority")
	home.queue_free();await frames(3)
	print("BAZAAR_MARKET_CRAFT_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
