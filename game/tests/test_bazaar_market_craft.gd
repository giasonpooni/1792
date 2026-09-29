# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Market:=preload("res://youth/performance/bazaar_market_stage.gd")
const Choreo:=preload("res://youth/performance/bazaar_choreography.gd")
const Decompression:=preload("res://youth/performance/bazaar_decompression.gd")
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
	var events: Array=[{"kind":"parry","tick":100,"index":0}]
	var beat: Dictionary=Choreo.contact_pose(events,110)
	check(beat.kind=="parry" and beat.amount>0,"contact beat derives from retained event without authoring one")
	var mela: Dictionary=Choreo.friend_pose(events,110,3);var jiva: Dictionary=Choreo.friend_pose(events,110,4)
	check(mela.action=="watch" and jiva.action=="watch","both friends react to same authoritative parry")
	check(Choreo.friend_pose(events,200,3).is_empty(),"reaction expires instead of becoming persistent knowledge")
	var hit_events: Array=[{"kind":"hit","tick":300,"index":1}]
	check(Choreo.friend_pose(hit_events,310,3).action=="brace","landed blow has distinct friend reaction")
	var counter_events: Array=[{"kind":"counter","tick":400,"index":2}]
	check(Choreo.friend_pose(counter_events,410,4).action=="urge","counter has distinct friend reaction")
	stage.sample(110,true,beat)
	check(scene.model.snapshot()==before,"market witness-like reaction creates no testimony or state")
	var figure: Node3D=scene.bazaar_performance.figures[0]
	var offsets: Dictionary={}
	for action in ["windup","strike","checked","recover"]:
		figure.sample(200,0,action,.8,false)
		check(figure.position.length()<.22,"visual-only footwork stays inside bounded presentation envelope "+action)
		offsets[action]=figure.position
	check(offsets.windup.z>0 and offsets.strike.z<0,"wind-up loads backward before strike steps through")
	check(offsets.checked.z>0 and offsets.recover.z<0,"checked recoil and recovery are directionally distinct")
	for friend_index in [3,4]:
		var friend_figure: Node3D=scene.bazaar_performance.figures[friend_index]
		friend_figure.sample(110,0,"brace",.8,false)
		check(friend_figure.position==Vector3.ZERO,"friend reaction never becomes root motion "+str(friend_index))
	var outcomes: Dictionary={}
	for outcome in ["stood_ground","withdrew","walked_away"]:
		var beat: Dictionary=Decompression.beat(outcome,30);outcomes[outcome]=beat
		check(not beat.is_empty() and beat.amount>0,"post-conflict beat exists for "+outcome)
	check(outcomes.stood_ground.caption!=outcomes.withdrew.caption and outcomes.withdrew.caption!=outcomes.walked_away.caption,"three outcomes decompress differently")
	check(Decompression.beat("stood_ground",Decompression.WINDOW+1).is_empty(),"decompression expires instead of becoming persistent state")
	check(Decompression.latest_regroup([{"kind":"invite","tick":1},{"kind":"regroup","tick":40}])==40,"decompression anchors to authoritative regroup receipt")
	check(scene.bazaar_performance.departure.marks.size()==5,"five visual road-wear marks connect encounter and home approach")
	check(scene.bazaar_performance.departure.find_children("*","CollisionShape3D",true,false).is_empty(),"departure dressing adds no collision")
	check(scene.model.snapshot()==before,"decompression and departure dressing create no world state")
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
