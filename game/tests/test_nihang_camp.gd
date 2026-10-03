# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Domain fixtures are labelled; the journey uses physical input after one declared start.
const State:=preload("res://warband/nihang_state.gd")
const R:=preload("res://warband/nihang_rules.gd")
const Names:=preload("res://characters/character_names.gd")
const Prior:=preload("res://mounts/riding_skill_state.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Launch:=preload("res://childhood/home_launch.gd")
const Store:=preload("res://childhood/checkpoint_store.gd")
const InstructorFixture:=preload("res://tests/instructor_story_fixture.gd")
const SAVE:="user://nihang-camp-test-only.json"
var passed:=0
var failed:=0
var watched: Node3D
var closest_horses:=INF

func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("NIHANG CAMP: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func refused(model,operation: Callable,label: String) -> void:
	var before: Dictionary=model.snapshot()
	check(not String(operation.call()).is_empty(),label+" refused")
	check(model.snapshot()==before,label+" atomic")
func frames(n: int=3) -> void:
	for _i in range(n):
		await physics_frame;observe_spacing()
	await process_frame

func observe_spacing() -> void:
	if not is_instance_valid(watched): return
	var bodies: Array=[watched.horse,watched.camp_horses[0],watched.camp_horses[1]]
	for i in range(bodies.size()):
		for j in range(i+1,bodies.size()):
			closest_horses=minf(closest_horses,Base.distance(bodies[i].position,bodies[j].position))

func same_saved(a: Variant,b: Variant) -> bool:
	# Only floating-point transport gets tolerance. Identity, keys, flags and counts stay exact.
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_saved(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same_saved(a[i],b[i]): return false
		return true
	if typeof(a) in [TYPE_INT,TYPE_FLOAT]:
		return Base.Riding.finite_number(b) and (a==b if a==floor(a) else absf(a-b)<1e-12)
	return typeof(a)==typeof(b) and a==b

func fixture() -> Dictionary:
	var model:=Prior.new()
	ok(Pose.pose(model,Base.SITES.letter),"fixture reaches letter")
	ok(model.inspect_letter(),"fixture letter")
	ok(model.hear("courier"),"fixture courier")
	ok(Pose.pose(model,Base.SITES.steward),"fixture reaches steward")
	ok(model.hear("steward"),"fixture steward")
	var value:=model.snapshot()
	value.childhood.walked=6.0;value.childhood.looked=1.0;value.childhood.ride_gate=1
	value.player.position=Base.coords(R.CAMP+Vector3(0,0,2));value.actors[Names.HERO_ID].position=value.player.position.duplicate()
	value.riding.horse.position=[15.0,.14,-15.0]
	ok(model.restore(value),"declared first-gate childhood fixture")
	return model.snapshot()

func prepared() -> State:
	var model:=State.new();ok(model.restore(fixture()),"legacy childhood imports")
	ok(model.camp_action("meet",true,true),"elder introduction")
	ok(Pose.pose(model,R.HORSE_LINES[0]+Vector3.RIGHT),"domain approaches horse")
	ok(model.camp_action("care",true,true),"horse-care account")
	ok(Pose.pose(model,R.CAMP+Vector3(0,0,2)),"domain returns to elder")
	return model

func domain() -> void:
	var model:=State.new()
	var old:=model.snapshot()
	check(not old.has("nihang_camp"),"unvisited Home invents no camp history")
	refused(model,model.camp_action.bind("meet",true,true),"remote introduction")
	ok(model.restore(fixture()),"old save no changes")
	refused(model,model.camp_action.bind("meet",false,true),"blocked conversation")
	refused(model,model.camp_action.bind("meet",true,false),"airborne conversation")
	refused(model,model.camp_action.bind("invite_two",true,true),"invitation before learning")
	ok(model.camp_action("meet",true,true),"received introduction")
	for id in [R.ELDER,R.RIDERS[0],R.RIDERS[1]]:
		check(model.nihang_address(id,Names.BEFORE_ACCESSION)==model.nihang_address(id,Names.AFTER_ACCESSION,true),"childhood moniker survives formal accession: "+id)
	check(model.nihang_address("unfamiliar_nihang",Names.AFTER_ACCESSION,true)=="Maharaja Ranjit Singh","no affiliation-wide automatic intimacy")
	check(Names.relationship_address(R.ELDER,"other_person",true,Names.AFTER_ACCESSION).is_empty(),"address cannot rename another subject")
	check(model.nihang_address(R.ELDER,"invented").is_empty(),"unknown phase grants no name")
	refused(model,model.camp_action.bind("meet",true,true),"duplicate introduction")
	var early:=fixture();early.childhood.ride_gate=0
	ok(model.restore(early),"before riding skill fixture")
	ok(model.camp_action("meet",true,true),"introduction before riding")
	ok(Pose.pose(model,R.HORSE_LINES[0]),"approach horse")
	ok(model.camp_action("care",true,true),"care before riding permitted")
	ok(Pose.pose(model,R.CAMP),"return to elder")
	refused(model,model.camp_action.bind("invite_one",true,true),"riding gate required")
	model=prepared()
	var before_invitation:=model.snapshot()
	ok(model.camp_action("invite_one",true,true),"select one rider")
	check(model.nihang_camp().selected==[R.RIDERS[0]],"finite selected roster")
	refused(model,model.camp_action.bind("invite_two",true,true),"no duplicate recruitment")
	refused(model,model.camp_action.bind("return",true,true),"no completion before marker")
	refused(model,model.begin_brawl,"no competing outing")
	refused(model,model.service_action.bind("dispatch","market"),"no competing service dispatch")
	refused(model,model.water_action.bind("draw"),"no concurrent water custody")
	refused(model,model.rest_watch,"no skipped escort movement")
	var camp:=model.nihang_camp();camp.selected.append(R.RIDERS[1])
	check(model.nihang_camp().selected.size()==1,"detached roster query")
	model.advance()
	var motion: Array=model.nihang_camp().mounts
	motion[1].position[0]+=.01
	refused(model,model.record_nihang_motion.bind(motion,1.0/60),"unselected rider cannot move")
	motion=model.nihang_camp().mounts;motion[0].position[0]+=2.0
	refused(model,model.record_nihang_motion.bind(motion,1.0/60),"no rider teleport")
	motion=model.nihang_camp().mounts
	ok(model.record_nihang_motion(motion,1.0/60),"one actual tick motion sample")
	refused(model,model.record_nihang_motion.bind(motion,1.0/60),"duplicate tick motion")
	# Isolated position fixture tests absent-companion refusal, not travelled distance.
	var at_camp:=model.snapshot()
	var separated:=at_camp.duplicate(true)
	separated.riding.horse.position=Base.coords(R.TURN)
	separated.riding.horse.rider_id=Names.HERO_ID
	separated.player.position=Base.coords(R.TURN)
	separated.actors[Names.HERO_ID].position=Base.coords(R.TURN)
	ok(model.restore(separated),"declared separated mounted rider fixture")
	refused(model,model.camp_action.bind("turn",true,true),"no marker completion with missing invited rider")
	ok(model.restore(at_camp),"restore full domain fixture")
	ok(model.save_to(SAVE),"save active relationship and poses")
	var loaded:=State.new();ok(loaded.load_from(SAVE),"load active camp")
	check(same_saved(loaded.nihang_camp(),model.nihang_camp()),"active selected roster and familiar address persist")
	for kind in ["phase","identity","future","extra","nan","unselected","text"]:
		var bad:=model.snapshot()
		match kind:
			"phase": bad.nihang_camp.phase="complete"
			"identity": bad.nihang_camp.mounts[0].id="mahan_singh"
			"future": bad.nihang_camp.events[0].tick=10000001
			"extra": bad.nihang_camp.extra=true
			"nan": bad.nihang_camp.mounts[0].yaw=NAN
			"unselected": bad.nihang_camp.mounts[1].position[0]+=.01
			"text": bad.nihang_camp.events[0].text="Maharaja"
		refused(model,model.restore.bind(bad),"malformed camp "+kind)
	ok(model.camp_action("cancel",true,true),"bounded undertaking ends together at camp")
	check(model.nihang_camp().phase=="cancelled","cancel does not grant completed ride")
	ok(model.restore(before_invitation),"earlier save discards later invitation")
	check(model.nihang_camp().selected.is_empty() and not model.nihang_active(),"rollback removes future companions")
	# Checkpoint extension must coexist with the original pre-encounter checkpoint contract.
	var checkpoint:=Pose.precursor()
	checkpoint.nihang_camp=model.nihang_camp()
	ok(model.restore(checkpoint),"declared pre-encounter checkpoint fixture")
	ok(model.observe_quarry(true),"checkpoint-ready quarry")
	ok(Store.write(SAVE+".checkpoint",model.snapshot(),Vector3.ZERO,"return_trail",State),"whole Home checkpoint retains relationships")
	ok(Store.read(SAVE+".checkpoint",State).error,"checkpoint read with explicit authority")

func mixed_authority() -> void:
	# Domain fixtures exercise admission and restore across the composed state
	# ladder; the separate journey continues to qualify actual camp travel.
	var model:=State.new()
	ok(model.restore(InstructorFixture.make("available")),"current Home retains instructor-capable state")
	ok(Pose.pose(model,R.CAMP),"domain reaches camp with funded household")
	ok(model.camp_action("meet",true,true),"funded Home hears the elder")
	ok(Pose.pose(model,R.HORSE_LINES[0]),"funded Home reaches horses")
	ok(model.camp_action("care",true,true),"funded Home hears horse care")
	ok(Pose.pose(model,R.CAMP),"funded Home returns to elder")
	ok(model.camp_action("invite_one",true,true),"funded Home admits camp outing")
	var active:=model.nihang_camp()
	ok(Pose.pose(model,model.Commission.HOME),"declared household contact during camp outing")
	refused(model,model.commission_action.bind("reserve","standard"),"camp prevents concurrent instructor reservation")
	refused(model,model.begin_remounts,"camp prevents concurrent remount inquiry")
	var reserved:=InstructorFixture.make("reserved")
	reserved.nihang_camp=active
	refused(model,model.restore.bind(reserved),"loaded instructor reservation cannot overlap camp")
	model=State.new()
	ok(model.restore(InstructorFixture.make("reserved")),"valid reserved instructor remains accepted")
	ok(Pose.pose(model,R.CAMP),"declared camp contact during instructor reservation")
	ok(model.camp_action("meet",true,true),"introduction does not reserve another outing")
	ok(Pose.pose(model,R.HORSE_LINES[0]),"reserved Home reaches horses")
	ok(model.camp_action("care",true,true),"care does not reserve another outing")
	ok(Pose.pose(model,R.CAMP),"reserved Home returns to elder")
	refused(model,model.camp_action.bind("invite_one",true,true),"instructor reservation prevents camp undertaking")

func look(scene,at: Vector3) -> void:
	var delta: Vector3=at-scene.avatar.global_position
	scene.avatar.pivot.rotation.y=atan2(-delta.x,-delta.z)
func release() -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
func tap(scene,key: Key) -> void:
	var event:=InputEventKey.new();event.keycode=key;event.pressed=true;scene._unhandled_input(event);await frames(2)
func press(scene,prefix: String) -> void:
	for button in scene._actions.get_children():
		if button.text.begins_with(prefix): button.pressed.emit();await frames(2);return
	check(false,"missing button: "+prefix+" / "+scene._message)
func walk(scene,at: Vector3) -> void:
	var reached:=false
	for _i in range(900):
		if Base.distance(scene.avatar.global_position,at)<.28: reached=true;break
		look(scene,at);Input.action_press("move_forward");await physics_frame;observe_spacing()
	release();await frames(6)
	check(reached,"physical walking: "+str(at)+" actual "+str(scene.avatar.global_position))
func ride(scene,at: Vector3) -> void:
	var reached:=false
	for _i in range(1500):
		var offset: Vector3=at-scene.horse.global_position
		var angle:=wrapf(atan2(-offset.x,-offset.z)-scene.horse.rotation.y,-PI,PI)
		release()
		if Base.distance(at,scene.horse.global_position)<.9:
			Input.action_press("move_backward")
			if scene.horse.speed<.1: reached=true;break
		elif absf(angle)<.6: Input.action_press("move_forward",.55)
		if absf(angle)>.03: Input.action_press("move_left" if angle>0 else "move_right",minf(absf(angle)*2,1))
		await physics_frame;observe_spacing()
	release();await frames(10)
	check(reached,"physical riding: "+str(at)+" actual "+str(scene.horse.global_position)+" / "+scene._message)

func check_guidance(scene,task: String,target: Vector3) -> void:
	var before: Dictionary=scene.model.snapshot()
	var hud: Node=scene.art.detail.hud
	for _i in range(4): hud.sample()
	check(hud.visible and hud.title.text.contains("NIHANGS") and hud.task.text==task,"accepted outing appears in the visible objective HUD: "+task)
	check(scene._marker.visible and scene._marker.position.is_equal_approx(target+Vector3.UP*2.1),"camp guidance points at the agreed destination")
	check(hud.narrator.text.contains("/ 2 riders nearby"),"visible guidance reports the actual selected group")
	check(scene.model.snapshot()==before,"camp guidance sampling changes no authoritative state")

func capture_snapshot(scene,filename: String) -> void:
	var output:=OS.get_environment("NIHANG_CAPTURE_OUTPUT")
	if output.is_empty(): return
	var file:=FileAccess.open(output.path_join(filename),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(scene.model.snapshot(),"",true,true));file.close()

func journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(fixture()),"one declared childhood start before native journey")
	root.add_child(home);await frames(8)
	watched=scene;closest_horses=INF
	ok(scene._candidate_error(scene.model),"initial Home including camp has standing room")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._paused and scene._camp_choices.has("meet"),"local E opens camp")
	var paused: Dictionary=scene.model.snapshot();await frames(10)
	check(scene.model.snapshot()==paused,"conversation pauses original Home clock")
	await press(scene,"Greet the elder")
	check(scene.model.nihang_camp().phase=="acquainted","native greeting establishes familiar relationship")
	await walk(scene,R.HORSE_LINES[0]+Vector3(-1.4,0,0));look(scene,R.HORSE_LINES[0]);await tap(scene,KEY_E)
	await press(scene,"Inspect the tack")
	check(scene.model.nihang_camp().phase=="prepared","native horse-care lesson")
	await walk(scene,R.CAMP+Vector3(1.8,0,0));look(scene,R.CAMP);await tap(scene,KEY_E)
	await press(scene,"Invite both")
	check(scene.model.nihang_camp().selected==R.RIDERS,"two mounted companions selected")
	check_guidance(scene,"Mount the household horse",R.Ride.position(scene.model.horse_record()))
	await walk(scene,Vector3(17,0,-15));await tap(scene,KEY_F)
	check(scene.model.mounted(),"existing household mount action")
	if not scene.model.mounted(): home.queue_free();await frames();return
	check_guidance(scene,"Ride to the north marker together",R.TURN)
	await ride(scene,Vector3(15,0,-25))
	await ride(scene,R.TURN)
	await frames(300)
	await tap(scene,KEY_E)
	check(scene.model.nihang_camp().phase=="returning","marker requires both real companions")
	check_guidance(scene,"Return together to the camp",R.CAMP)
	await tap(scene,KEY_F5)
	check(FileAccess.get_file_as_string(SAVE).contains("nihang_camp"),"F5 includes current camp state")
	var saved: Dictionary=scene.model.nihang_camp()
	await ride(scene,Vector3(9,0,-25))
	await tap(scene,KEY_F9)
	check(scene.model.nihang_camp().phase==saved.phase and scene.model.nihang_camp().selected==saved.selected,"F9 restores accepted undertaking")
	check(scene._message=="Whole Home and riding skills restored.","native F9 retains the original successful-load cue")
	check_guidance(scene,"Return together to the camp",R.CAMP)
	capture_snapshot(scene,"active-outing.json")
	ok(scene.model.validate(scene.model.snapshot()),"mid-ride whole-world state valid")
	var prior_world: Dictionary=scene.model.snapshot()
	var bad_world:=prior_world.duplicate(true)
	bad_world.nihang_camp.mounts[0].position=bad_world.nihang_camp.mounts[1].position.duplicate()
	var staged:=State.new();ok(staged.restore(bad_world),"declared internally valid overlapping pose fixture")
	check(not scene._candidate_error(staged).is_empty(),"physical restore refuses overlapping camp horses")
	bad_world=prior_world.duplicate(true)
	bad_world.nihang_camp.mounts[0].position=bad_world.riding.horse.position.duplicate()
	ok(staged.restore(bad_world),"declared internally valid leader-overlap fixture")
	check(not scene._candidate_error(staged).is_empty(),"physical restore refuses overlap with household mount")
	check(scene.model.snapshot()==prior_world,"preflight refusal leaves played world unchanged")
	await ride(scene,Vector3(15,0,-25))
	await ride(scene,Vector3(16,0,-18))
	await tap(scene,KEY_F)
	check(not scene.model.mounted(),"physical dismount at camp")
	# Walk around the household horse, whose actual body remains parked after dismount.
	for at in [Vector3(14,0,-15),Vector3(20.8,0,-15)]: await walk(scene,at)
	await walk(scene,R.CAMP+Vector3(1.8,0,0));await frames(400)
	look(scene,R.CAMP);await tap(scene,KEY_E)
	await press(scene,"Return together")
	check(scene.model.nihang_camp().phase=="complete","whole escort checked in without remote completion")
	scene.art.detail.hud.sample()
	check(not scene.art.detail.hud.title.text.contains("NIHANGS") and scene.camp_guidance().is_empty(),"settled undertaking yields to the original lesson guidance")
	check(closest_horses>=1.575,"native outing keeps all horses physically separate: "+str(closest_horses))
	ok(scene.model.validate(scene.model.snapshot()),"complete native outing validates")
	check(scene.model.journal().any(func(e): return e.source_id==R.RIDERS[0] and e.text.begins_with("Little rider")),"received companion voice retained")
	# Capture actual executed state for separate native rendering, not a replacement scene.
	var output:=OS.get_environment("NIHANG_CAPTURE_OUTPUT")
	capture_snapshot(scene,"completed-outing.json")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains("Buddh, everyone is home"),"familiar homecoming shown in real UI")
	await frames(2)
	if not output.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		ok("" if root.get_texture().get_image().save_png(output.path_join("camp-homecoming.png"))==OK else "capture failed","native screenshot")
	release();watched=null;home.queue_free();await frames()

func stale_menu() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(fixture()),"declared access-test fixture");root.add_child(home);await frames(8)
	look(scene,R.CAMP);await tap(scene,KEY_E)
	var before: Dictionary=scene.model.snapshot()
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(3,3,.2)
	collision.shape=box;wall.add_child(collision);wall.position=R.CAMP+Vector3(0,1,1)
	home.add_child(wall);await frames(3)
	await press(scene,"Greet the elder")
	check(not scene.model.snapshot().has("nihang_camp"),"wall invalidates already-open conversation")
	check(scene.model.journal()==State.new().journal() or scene.model.journal()==_journal_for(before),"blocked choice grants no testimony")
	home.queue_free();await frames()
func _journal_for(snapshot: Dictionary) -> Array:
	var m:=State.new();m.restore(snapshot);return m.journal()

func run() -> void:
	domain();mixed_authority();await journey();await stale_menu()
	for suffix in ["",".tmp",".checkpoint"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("NIHANG_CAMP_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
