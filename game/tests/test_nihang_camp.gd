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
const Guidance:=preload("res://presentation/beginning_guidance.gd")
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
	check(R.handoff_echo(R.initial()).is_empty(),"unvisited camp supplies no childhood handoff echo")
	refused(model,model.camp_action.bind("meet",true,true),"remote introduction")
	ok(model.restore(fixture()),"old save no changes")
	refused(model,model.camp_action.bind("meet",false,true),"blocked conversation")
	refused(model,model.camp_action.bind("meet",true,false),"airborne conversation")
	refused(model,model.camp_action.bind("invite_two_terms",true,true),"invitation before learning")
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
	ok(model.camp_action("invite_one_terms",true,true),"select one rider on stated terms")
	check(model.nihang_camp().selected==[R.RIDERS[0]],"finite selected roster")
	check(R.terms_required(model.nihang_camp()),"new invitation records the low-ground term")
	var obligation: Dictionary=R.obligation(model.nihang_camp())
	check(obligation.title.begins_with("LOW GROUND") and obligation.source_id==R.ELDER and obligation.text.contains("no one crosses"),"active low-ground obligation derives from the received invitation")
	refused(model,model.camp_action.bind("invite_two_terms",true,true),"no duplicate recruitment")
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
	refused(model,model.camp_action.bind("turn",true,true),"marker refuses an unkept low-ground term")
	var halted:=at_camp.duplicate(true)
	halted.player.position=Base.coords(R.HALT);halted.actors[Names.HERO_ID].position=Base.coords(R.HALT)
	halted.nihang_camp.mounts[0].position=Base.coords(R.HALT+Vector3(1.5,0,0))
	ok(model.restore(halted),"declared complete group at the low ground")
	ok(model.camp_action("halt",true,true),"dismounted count keeps the stated term")
	obligation=R.obligation(model.nihang_camp())
	check(obligation.title.begins_with("NORTH MARKER") and obligation.source_id==R.RIDERS[0] and obligation.text.contains("jatha home together"),"witnessed halt advances the derived obligation without another receipt")
	refused(model,model.camp_action.bind("halt",true,true),"low-ground witness cannot duplicate")
	var turn_ready:=model.snapshot()
	turn_ready.player.position=Base.coords(R.TURN);turn_ready.actors[Names.HERO_ID].position=Base.coords(R.TURN)
	turn_ready.riding.horse.position=Base.coords(R.TURN);turn_ready.riding.horse.rider_id=Names.HERO_ID
	turn_ready.nihang_camp.mounts[0].position=Base.coords(R.TURN+Vector3(1.5,0,0))
	ok(model.restore(turn_ready),"declared mounted group after the witnessed halt")
	ok(model.camp_action("turn",true,true),"kept term admits the practice-marker turn")
	obligation=R.obligation(model.nihang_camp())
	check(obligation.title.begins_with("CAMP RETURN") and obligation.text.contains("every horse"),"marker turn derives the physical return obligation")
	var home_ready:=model.snapshot()
	home_ready.player.position=Base.coords(R.CAMP);home_ready.actors[Names.HERO_ID].position=Base.coords(R.CAMP)
	home_ready.riding.horse.position=Base.coords(R.CAMP+Vector3(-3,0,0));home_ready.riding.horse.rider_id=""
	for i in range(home_ready.nihang_camp.mounts.size()):
		home_ready.nihang_camp.mounts[i].position=Base.coords(R.HORSE_LINES[i]);home_ready.nihang_camp.mounts[i].speed=0.0
	ok(model.restore(home_ready),"declared returned group after the kept term")
	ok(model.camp_action("return",true,true),"completed first undertaking records its homecoming")
	check(R.handoff_echo(model.nihang_camp())==R.FIRST_HANDOFF_ECHO,"witnessed first return derives the group-discipline handoff")
	check(R.kept_first_terms(model.nihang_camp()),"second-outing willingness derives from halt and homecoming history")
	ok(model.camp_action("second_ready",true,true),"veteran agrees to a farther road after the kept undertaking")
	check(model.journal().any(func(e): return e.id=="nihang_second_ready" and e.source_id==R.RIDERS[0] and e.text.begins_with("Little rider")),"readiness remains received veteran testimony")
	refused(model,model.camp_action.bind("second_ready",true,true),"farther-road answer cannot repeat")
	refused(model,model.camp_action.bind("second_turn",true,true),"farther road cannot turn before its stated term begins")
	ok(model.camp_action("second_begin",true,true),"accepted answer begins the farther-road undertaking")
	check(model.nihang_camp().phase=="second_outbound" and model.nihang_camp().selected==[R.RIDERS[0]],"second outing selects only the veteran")
	obligation=R.obligation(model.nihang_camp())
	check(obligation.title.begins_with("FARTHER ROAD") and obligation.source_id==R.RIDERS[0] and obligation.text.contains("horse is still"),"farther-road obligation preserves the veteran's full-stop term")
	var farther:=model.snapshot()
	farther.player.position=Base.coords(R.FARTHER);farther.actors[Names.HERO_ID].position=Base.coords(R.FARTHER)
	farther.riding.horse.position=Base.coords(R.FARTHER);farther.riding.horse.rider_id=Names.HERO_ID
	farther.nihang_camp.mounts[0].position=Base.coords(R.FARTHER+Vector3(1.5,0,0));farther.nihang_camp.mounts[0].speed=.4
	ok(model.restore(farther),"declared mounted pair reaches the farther stone while the veteran is moving")
	refused(model,model.camp_action.bind("second_turn",true,true),"farther stone enforces the veteran's full-stop term")
	farther.nihang_camp.mounts[0].speed=0.0
	ok(model.restore(farther),"declared veteran settles at the farther stone")
	ok(model.camp_action("second_turn",true,true),"settled veteran witnesses the farther-road turn")
	obligation=R.obligation(model.nihang_camp())
	check(obligation.title.begins_with("FARTHER RETURN") and obligation.text.contains("witness the return"),"farther turn derives the horse-and-rider return obligation")
	var second_home:=model.snapshot()
	second_home.player.position=Base.coords(R.CAMP);second_home.actors[Names.HERO_ID].position=Base.coords(R.CAMP)
	second_home.riding.horse.position=Base.coords(R.CAMP+Vector3(-3,0,0));second_home.riding.horse.rider_id=""
	second_home.nihang_camp.mounts[0].position=Base.coords(R.HORSE_LINES[0]);second_home.nihang_camp.mounts[0].speed=0.0
	ok(model.restore(second_home),"declared farther-road pair returns to camp")
	ok(model.camp_action("second_return",true,true),"veteran witnesses the completed second outing")
	check(R.handoff_echo(model.nihang_camp())==R.SECOND_HANDOFF_ECHO,"witnessed farther return derives the patient-stop handoff")
	check(R.obligation(model.nihang_camp()).is_empty(),"settled second outing exposes no stale active obligation")
	check(model.nihang_camp().phase=="second_complete" and model.journal().any(func(e): return e.id=="nihang_second_return" and e.source_id==R.RIDERS[0] and e.text.begins_with("Little rider")),"farther-road payoff is finite received veteran testimony")
	refused(model,model.camp_action.bind("second_begin",true,true),"completed second outing cannot repeat")
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
	ok(model.camp_action("second_deferred",true,true),"unfinished first ride receives a readable not-yet answer")
	check(model.journal().any(func(e): return e.id=="nihang_second_deferred" and e.source_id==R.RIDERS[0] and e.text.begins_with("Little rider")),"deferred willingness is received veteran testimony")
	refused(model,model.camp_action.bind("second_ready",true,true),"unfinished ride cannot invent veteran willingness")
	refused(model,model.camp_action.bind("second_begin",true,true),"deferred answer exposes no farther-road access")
	ok(model.restore(before_invitation),"earlier save discards later invitation")
	check(model.nihang_camp().selected.is_empty() and not model.nihang_active(),"rollback removes future companions")
	var legacy:=prepared()
	ok(legacy.camp_action("invite_one",true,true),"pre-terms invitation remains readable")
	check(not R.obligation(legacy.nihang_camp()).text.contains("low ground"),"legacy invitation does not acquire the later low-ground obligation")
	var legacy_turn:=legacy.snapshot()
	legacy_turn.player.position=Base.coords(R.TURN);legacy_turn.actors[Names.HERO_ID].position=Base.coords(R.TURN)
	legacy_turn.riding.horse.position=Base.coords(R.TURN);legacy_turn.riding.horse.rider_id=Names.HERO_ID
	legacy_turn.nihang_camp.mounts[0].position=Base.coords(R.TURN+Vector3(1.5,0,0))
	ok(legacy.restore(legacy_turn),"pre-terms active save remains valid")
	ok(legacy.camp_action("turn",true,true),"pre-terms save keeps its original direct marker contract")
	check(R.handoff_echo(legacy.nihang_camp()).is_empty(),"legacy direct-marker ride supplies no invented jatha testimony echo")
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
	ok(model.camp_action("invite_one_terms",true,true),"funded Home admits camp outing")
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

func check_guidance(scene,task: String,target: Vector3,expected_riders: int=2) -> void:
	var before: Dictionary=scene.model.snapshot()
	var hud: Node=scene.art.detail.hud
	for _i in range(4): hud.sample()
	check(hud.visible and hud.title.text.contains("NIHANGS") and hud.task.text==task,"accepted outing appears in the visible objective HUD: "+task)
	check(scene._marker.visible and scene._marker.position.is_equal_approx(target+Vector3.UP*2.1),"camp guidance points at the agreed destination")
	check(hud.narrator.text.contains("/ %d riders nearby"%expected_riders),"visible guidance reports the actual selected group")
	var obligation: Dictionary=R.obligation(scene.model.nihang_camp())
	check(not obligation.is_empty() and hud.narrator.text.contains(obligation.text),"visible guidance projects the same derived jatha obligation")
	check(scene.model.snapshot()==before,"camp guidance sampling changes no authoritative state")

func check_obligation_journal(scene,expected_title: String,expected_address: String) -> void:
	var before: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
	var obligation: Dictionary=R.obligation(scene.model.nihang_camp())
	check(not obligation.is_empty() and obligation.title==expected_title,"active obligation has the expected phase title")
	scene._open_journal();await frames(2)
	var text: String=scene._panel_text.text
	var active_at:=text.find("ACTIVE JATHA UNDERTAKING")
	var first_memory:=text.find("[heard ·")
	check(scene._paused and active_at>=0 and (first_memory<0 or active_at<first_memory),"active undertaking receives the journal's first attention field")
	check(text.contains(obligation.title) and text.contains(obligation.text) and text.contains("Remembered address · "+expected_address),"journal projects the received term and relationship address")
	check(scene.model.snapshot()==before and scene.model.journal()==journal,"opening the obligation journal changes no state or testimony")
	await press(scene,"Resume")
	check(not scene._paused,"resume returns from the ordinary journal authority")

func check_care_guidance(scene) -> void:
	var before: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
	var bodies: Array=[scene.avatar.global_transform,scene.horse.global_transform,scene.camp_horses[0].global_transform,scene.camp_horses[1].global_transform]
	var hud: Node=scene.art.detail.hud
	for _i in range(4): hud.sample()
	check(hud.visible and hud.task.text=="Listen beside the horse lines" and hud.narrator.text.contains("Optional"),"received greeting directs optional local care in the real compact HUD")
	check(scene._marker.visible and scene._marker.position.is_equal_approx(R.HORSE_LINES[0]+Vector3.UP*2.1) and scene._marker.text=="Veteran's horse · E","care guidance points to the actual veteran's horse")
	check(scene.model.snapshot()==before and scene.model.journal()==journal,"care guidance invents no progress or testimony")
	check(bodies==[scene.avatar.global_transform,scene.horse.global_transform,scene.camp_horses[0].global_transform,scene.camp_horses[1].global_transform],"guidance sampling moves no physical body")

func care_priority() -> void:
	# Explicit domain fixtures isolate threat priority; they are not a played route.
	var known:=State.new();ok(known.restore(fixture()),"priority fixture starts at declared camp")
	ok(known.camp_action("meet",true,true),"priority fixture supplies a received elder greeting")
	var threat:=Base.new();ok(threat.restore(Pose.precursor()),"declared priority threat precursor")
	ok(threat.observe_quarry(true),"declared precursor observes the quarry")
	ok(Pose.pose(threat,Base.SITES.bend),"declared priority arrival at the bend")
	ok(threat.start_ambush(),"declared priority encounter begins")
	ok(Pose.pose(threat,R.CAMP),"declared threat-side position tests the nearby camp HUD")
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	root.add_child(home);await frames(4);home.process_mode=Node.PROCESS_MODE_DISABLED
	for stage in ["active","caught"]:
		if stage=="caught":
			for _i in range(3): threat.take_hit()
		var value: Dictionary=threat.snapshot();value.nihang_camp=known.nihang_camp()
		ok(scene.model.restore(value),"declared acquainted "+stage+" fixture")
		scene._apply();scene._refresh();scene.art.detail.hud.sample()
		var before: Dictionary=scene.model.snapshot();var journal: Array=scene.model.journal()
		var visible: Dictionary=Guidance.read(scene)
		check(scene.camp_guidance().is_empty() and not visible.title.contains("NIHANG"),"optional care yields to "+stage+" guidance")
		check(scene.art.detail.hud.task.text==visible.task and scene.art.detail.hud.visible,"actual compact HUD retains "+stage+" priority")
		check(scene.model.snapshot()==before and scene.model.journal()==journal,"priority sampling grants no camp progress in "+stage)
	home.queue_free();await frames()

func capture_snapshot(scene,filename: String) -> void:
	var output:=OS.get_environment("NIHANG_CAPTURE_OUTPUT")
	if output.is_empty(): return
	var file:=FileAccess.open(output.path_join(filename),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(scene.model.snapshot(),"",true,true));file.close()

func wait_for_camp_riders(scene,center: Vector3=R.CAMP,label: String="camp") -> void:
	# Observe the actual horses; a fixed dialogue delay cannot imply arrival.
	var settled:=false
	for _i in range(600):
		await frames(1)
		var camp: Dictionary=scene.model.nihang_camp()
		settled=R.together(camp.selected,camp.mounts,center,7.0)
		for id in camp.selected:
			if camp.mounts[R.RIDERS.find(id)].speed>.08: settled=false
		if settled: break
	check(settled,"both actual riders settle at "+label+" within ten seconds")

func care_pages(scene) -> void:
	var before: Dictionary=scene.model.snapshot()
	var journal: Array=scene.model.journal()
	check(scene._paused and scene._care_page==0 and scene._panel_text.text.contains("BRIDLE"),"horse-care begins with the player's first attention beat")
	capture_snapshot(scene,"before-care.json")
	scene._menu_action("camp:care");await frames(3)
	check(scene.model.snapshot()==before and scene._care_page==0,"unavailable final care choice cannot skip the conversation")
	await press(scene,"Inspect the tack")
	check(scene._paused and scene._care_page==1 and scene._panel_text.text.contains("FOOTING"),"actual button advances from tack to footing")
	await frames(10)
	check(scene.model.snapshot()==before and scene.model.journal()==journal,"partial pages pause Home and grant no completion receipt")
	await tap(scene,KEY_F5)
	check(scene._care_page== -1 and not scene._paused,"manual save retains Home's established resume behavior and clears transient pages")
	check(scene.model.nihang_camp().phase=="acquainted" and scene.model.journal()==journal,"saving a partial conversation grants no horse-care receipt")
	look(scene,R.HORSE_LINES[0]);await tap(scene,KEY_E)
	check(scene._care_page==0,"conversation restarts after leaving through manual save")
	before=scene.model.snapshot()
	await press(scene,"Inspect the tack")
	await press(scene,"Look at the footing")
	check(scene._paused and scene._care_page==2 and scene._panel_text.text.contains("THE RETURN"),"return obligation follows the physical lesson")
	scene._menu_action("camp:care_footing");await frames(3)
	check(scene._care_page==2 and scene.model.snapshot()==before,"stale earlier-page action cannot replay a beat")
	await tap(scene,KEY_F9)
	check(scene._care_page== -1 and not scene._paused and scene.model.nihang_camp().phase=="acquainted","F9 discards future dialogue pages and restores the unfinished lesson")
	check(scene.model.journal()==journal,"restored partial lesson invents no care testimony")
	look(scene,R.HORSE_LINES[0]);await tap(scene,KEY_E)
	check(scene._care_page==0,"reopened horse-care starts at its first beat")
	await press(scene,"Inspect the tack");await press(scene,"Look at the footing")
	await press(scene,"I will bring the horse home")
	check(scene._care_page== -1 and not scene._paused,"accepted care closes and clears its transient pages")

func journey() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(fixture()),"one declared childhood start before native journey")
	root.add_child(home);await frames(8)
	watched=scene;closest_horses=INF
	ok(scene._candidate_error(scene.model),"initial Home including camp has standing room")
	check(scene.camp_guidance().is_empty(),"unmet camp supplies no premature care direction")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._paused and scene._camp_choices.has("meet"),"local E opens camp")
	var paused: Dictionary=scene.model.snapshot();await frames(10)
	check(scene.model.snapshot()==paused,"conversation pauses original Home clock")
	await press(scene,"Greet the elder")
	check(scene.model.nihang_camp().phase=="acquainted","native greeting establishes familiar relationship")
	check_care_guidance(scene)
	await tap(scene,KEY_F5)
	await walk(scene,Vector3(17,0,-15));await tap(scene,KEY_F)
	check(scene.model.mounted() and scene.camp_guidance().is_empty(),"native mount keeps the ordinary riding objective ahead of optional care")
	check(scene.art.detail.hud.task.text.begins_with("Ride through gate"),"mounted rider sees the next original household gate")
	await tap(scene,KEY_F9);check_care_guidance(scene)
	await walk(scene,R.CAMP+Vector3(-11,0,0))
	check(scene.camp_guidance().is_empty() and scene.art.detail.hud.task.text=="Mount the household horse","leaving camp on foot returns to the ordinary lesson")
	await tap(scene,KEY_F9);check_care_guidance(scene)
	await walk(scene,R.HORSE_LINES[0]+Vector3(-1.4,0,0));look(scene,R.HORSE_LINES[0]);await tap(scene,KEY_E)
	await care_pages(scene)
	check(scene.model.nihang_camp().phase=="prepared","native horse-care lesson")
	check(scene.camp_guidance().is_empty() and scene.art.detail.hud.task.text=="Mount the household horse","accepted care immediately hands attention back to household riding")
	capture_snapshot(scene,"after-care.json")
	await walk(scene,R.CAMP+Vector3(1.8,0,0));look(scene,R.CAMP);await tap(scene,KEY_E)
	await press(scene,"Invite both")
	check(scene.model.nihang_camp().selected==R.RIDERS,"two mounted companions selected")
	check(R.terms_required(scene.model.nihang_camp()),"native invitation retains the veteran's low-ground term")
	check_guidance(scene,"Mount the household horse",R.Ride.position(scene.model.horse_record()))
	await check_obligation_journal(scene,"LOW GROUND · COUNT BEFORE CROSSING","Buddh")
	await walk(scene,Vector3(17,0,-15));await tap(scene,KEY_F)
	check(scene.model.mounted(),"existing household mount action")
	if not scene.model.mounted(): home.queue_free();await frames();return
	check_guidance(scene,"Halt together at the low ground",R.HALT)
	await ride(scene,R.TURN)
	await wait_for_camp_riders(scene,R.TURN,"the north marker")
	await tap(scene,KEY_E)
	check(scene.model.nihang_camp().phase=="outbound" and not R.has_event(scene.model.nihang_camp(),"halt"),"riding past the term grants no turn")
	check(scene._message.contains("low ground"),"the veteran's refusal states the unkept obligation")
	check_guidance(scene,"Halt together at the low ground",R.HALT)
	await ride(scene,R.HALT)
	await tap(scene,KEY_F)
	check(not scene.model.mounted(),"native stop puts a foot down at the low ground")
	await wait_for_camp_riders(scene,R.HALT,"the low ground")
	look(scene,scene.camp_horses[0].global_position);await tap(scene,KEY_E)
	check(scene._paused and scene._camp_choices.has("halt") and scene._panel_text.text.contains("count aloud"),"local E opens the player-paced terms beat")
	await press(scene,"Count every rider")
	check(R.has_event(scene.model.nihang_camp(),"halt"),"native count records the witnessed halt")
	check(scene.model.journal().any(func(e): return e.id=="nihang_halt" and e.text==R.WORDS.halt),"veteran's answer becomes received testimony")
	check_guidance(scene,"Mount the household horse",R.Ride.position(scene.model.horse_record()))
	await check_obligation_journal(scene,"NORTH MARKER · KEEP THE JATHA TOGETHER","Little rider")
	await tap(scene,KEY_F)
	check(scene.model.mounted(),"native remount continues the agreed journey")
	check_guidance(scene,"Ride to the north marker together",R.TURN)
	await ride(scene,R.TURN)
	await wait_for_camp_riders(scene,R.TURN,"the north marker after the halt")
	await tap(scene,KEY_E)
	check(scene.model.nihang_camp().phase=="returning","marker requires both real companions")
	check_guidance(scene,"Return together to the camp",R.CAMP)
	await check_obligation_journal(scene,"CAMP RETURN · SETTLE EVERY HORSE","Little rider")
	await tap(scene,KEY_F5)
	check(FileAccess.get_file_as_string(SAVE).contains("nihang_camp"),"F5 includes current camp state")
	var saved: Dictionary=scene.model.nihang_camp()
	await ride(scene,Vector3(9,0,-25))
	await tap(scene,KEY_F9)
	check(scene.model.nihang_camp().phase==saved.phase and scene.model.nihang_camp().selected==saved.selected,"F9 restores accepted undertaking")
	check(R.has_event(scene.model.nihang_camp(),"halt"),"F9 retains the already witnessed low-ground term")
	check(scene._message=="Whole Home and riding skills restored.","native F9 retains the original successful-load cue: "+scene._message)
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
	await walk(scene,R.CAMP+Vector3(1.8,0,0));await wait_for_camp_riders(scene)
	look(scene,R.CAMP);await tap(scene,KEY_E)
	await press(scene,"Return together")
	check(scene.model.nihang_camp().phase=="complete","whole escort checked in without remote completion: "+scene._message+" / "+str(scene.model.nihang_camp().mounts))
	scene.art.detail.hud.sample()
	check(not scene.art.detail.hud.title.text.contains("NIHANGS") and scene.camp_guidance().is_empty(),"settled undertaking yields to the original lesson guidance")
	check(closest_horses>=1.575,"native outing keeps all horses physically separate: "+str(closest_horses))
	ok(scene.model.validate(scene.model.snapshot()),"complete native outing validates")
	check(scene.model.journal().any(func(e): return e.source_id==R.RIDERS[0] and e.text.begins_with("Little rider")),"received companion voice retained")
	check(scene.model.journal().any(func(e): return e.id=="nihang_halt"),"homecoming retains the veteran's low-ground witness")
	# Capture actual executed state for separate native rendering, not a replacement scene.
	var output:=OS.get_environment("NIHANG_CAPTURE_OUTPUT")
	capture_snapshot(scene,"completed-outing.json")
	# Let witnessed jatha conduct shape one existing childhood report. The player
	# still walks to both speakers and uses the original message receipt path.
	await walk(scene,Base.SITES.steward+Vector3(0,0,1.8));look(scene,Base.SITES.steward);await tap(scene,KEY_E)
	check(scene._paused and scene._panel_text.text.contains("What will you tell him?"),"returned rider opens the existing steward handoff")
	await press(scene,"Carry the uncertainty")
	check(scene.model.message_phase()=="report","existing direct route now awaits the trainer report")
	await walk(scene,Base.SITES.spar+Vector3(0,0,1.8));look(scene,Base.SITES.spar)
	capture_snapshot(scene,"jatha-handoff.json")
	var before_camp_events: Array=scene.model.nihang_camp().events.duplicate(true);var before_message: Dictionary=scene.model.message_followup()
	await tap(scene,KEY_E)
	check(scene._paused and scene._panel_text.text.contains(R.FIRST_HANDOFF_ECHO.account),"trainer report echoes the witnessed low-ground discipline")
	var paused_handoff: Dictionary=scene.model.snapshot();await frames(8)
	check(scene.model.snapshot()==paused_handoff and scene.model.message_followup()==before_message and scene.model.nihang_camp().events==before_camp_events,"open derived handoff freezes Home and grants no report or camp receipt")
	await press(scene,"Give the trainer")
	check(scene.model.message_phase()=="complete" and scene._message==R.FIRST_HANDOFF_ECHO.reply,"actual report receives the bounded trainer response")
	check(scene.model.nihang_camp().events==before_camp_events,"childhood handoff adds no camp testimony or receipt")
	await walk(scene,R.CAMP+Vector3(1.8,0,0))
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains("Buddh, everyone is home") and scene._panel_text.text.contains("stopped at the low ground"),"familiar homecoming shows the witnessed consequence")
	check(scene._camp_choices.has("second_ready"),"kept undertaking exposes one player-paced farther-road question")
	await press(scene,"Ask the veteran")
	check(R.has_event(scene.model.nihang_camp(),"second_ready"),"actual follow-up choice records the veteran's derived willingness")
	check(scene._message==R.WORDS.second_ready and scene._message.begins_with("Little rider"),"native answer retains the relationship moniker")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains(R.WORDS.second_ready) and not scene._camp_choices.has("second_ready") and scene._camp_choices.has("second_terms") and not scene._camp_choices.has("second_begin"),"reopened camp retains willingness without silently beginning the route")
	var before_terms: Dictionary=scene.model.snapshot();var journal_before_terms: Array=scene.model.journal()
	await press(scene,"Ask him to state")
	check(scene._paused and scene._panel_text.text.contains("Reaching it is not the turn") and scene._camp_choices.has("second_begin"),"farther-road term receives its own player-paced attention beat")
	check(scene.model.snapshot()==before_terms and scene.model.journal()==journal_before_terms,"hearing the term grants no route or testimony")
	scene._menu_action("camp:second_terms");await frames(2)
	check(scene.model.snapshot()==before_terms and scene._camp_choices.has("second_begin"),"stale willingness action cannot skip or repeat the term")
	await press(scene,"Accept the term")
	check(scene.model.nihang_camp().phase=="second_outbound" and scene.model.nihang_camp().selected==[R.RIDERS[0]],"actual choice begins the veteran-only second outing")
	check(scene._message==R.WORDS.second_begin and scene._message.begins_with("Little rider"),"second route states its physical term in the veteran's familiar voice")
	check_guidance(scene,"Mount the household horse",R.Ride.position(scene.model.horse_record()),1)
	await check_obligation_journal(scene,"FARTHER ROAD · WAIT FOR THE VETERAN'S HORSE","Little rider")
	capture_snapshot(scene,"active-second-outing.json")
	await walk(scene,scene.horse.global_position+Vector3(1.4,0,0));await tap(scene,KEY_F)
	check(scene.model.mounted(),"existing household mount begins the farther road")
	check_guidance(scene,"Ride to the farther stone with the veteran",R.FARTHER,1)
	await ride(scene,R.FARTHER)
	await wait_for_camp_riders(scene,R.FARTHER,"the farther stone")
	await tap(scene,KEY_E)
	check(scene.model.nihang_camp().phase=="second_returning" and R.has_event(scene.model.nihang_camp(),"second_turn"),"farther stone turns only after the actual veteran settles")
	check(scene._message==R.WORDS.second_turn and scene._message.begins_with("Little rider"),"farther turn names the kept term without a title")
	check_guidance(scene,"Return together to the camp",R.CAMP,1)
	await check_obligation_journal(scene,"FARTHER RETURN · BRING HORSE AND RIDER HOME","Little rider")
	await ride(scene,R.TURN)
	await ride(scene,Vector3(15,0,-25))
	await ride(scene,Vector3(16,0,-18))
	await tap(scene,KEY_F)
	check(not scene.model.mounted(),"farther-road return physically dismounts at camp")
	for at in [Vector3(14,0,-15),Vector3(20.8,0,-15)]: await walk(scene,at)
	await walk(scene,R.CAMP+Vector3(1.8,0,0));await wait_for_camp_riders(scene,R.CAMP,"camp after the farther road")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._camp_choices.has("second_return"),"settled physical return exposes the second outing witness")
	await press(scene,"Settle the farther road")
	check(scene.model.nihang_camp().phase=="second_complete","second outing completes through its witnessed homecoming")
	check(scene.model.journal().any(func(e): return e.id=="nihang_second_return" and e.text==R.WORDS.second_return),"second payoff persists as received veteran testimony")
	ok(scene.model.validate(scene.model.snapshot()),"complete farther-road Home validates")
	capture_snapshot(scene,"second-outing-complete.json")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains(R.WORDS.second_return) and scene._panel_text.text.contains("testimony rather than a prize"),"final camp beat gives the farther road a quiet witnessed payoff")
	check(scene._camp_choices.size()==0,"completed second outing offers no repeatable camp action")
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

func stale_care() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(fixture()),"declared horse-care access fixture")
	ok(scene.model.camp_action("meet",true,true),"fixture has the received introduction")
	root.add_child(home);await frames(8)
	await walk(scene,R.HORSE_LINES[0]+Vector3(-1.4,0,0));look(scene,R.HORSE_LINES[0]);await tap(scene,KEY_E)
	await press(scene,"Inspect the tack");await press(scene,"Look at the footing")
	var before: Dictionary=scene.model.nihang_camp();var journal: Array=scene.model.journal()
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.2,3,3)
	collision.shape=box;wall.add_child(collision);wall.position=R.HORSE_LINES[0]+Vector3(-.7,1,0)
	home.add_child(wall);await frames(3)
	await press(scene,"I will bring the horse home")
	check(scene.model.nihang_camp()==before and scene.model.journal()==journal,"new obstruction at the final beat refuses care without testimony")
	check(scene._care_page== -1 and not scene._paused,"failed final beat clears the transient conversation")
	home.queue_free();await frames()

func deferred_second_outing() -> void:
	# A declared settled fixture isolates the readable alternative; the separate
	# journey above remains the authority for physically completing the first ride.
	var model:=prepared()
	ok(model.camp_action("invite_two_terms",true,true),"deferred-answer fixture accepts the first undertaking")
	ok(model.camp_action("cancel",true,true),"deferred-answer fixture returns everyone without completing it")
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	ok(scene.model.restore(model.snapshot()),"declared unfinished ride imports for presentation")
	root.add_child(home);await frames(8)
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains("unfinished today") and scene._camp_choices.has("second_deferred"),"unfinished ride exposes the alternative farther-road question")
	await press(scene,"Ask the veteran")
	check(R.has_event(scene.model.nihang_camp(),"second_deferred"),"actual alternative choice records the not-yet answer")
	check(scene._message==R.WORDS.second_deferred and scene._message.begins_with("Little rider"),"deferred native answer retains the relationship moniker")
	look(scene,R.CAMP);await tap(scene,KEY_E)
	check(scene._panel_text.text.contains(R.WORDS.second_deferred) and not scene._camp_choices.has("second_deferred"),"reopened unfinished camp retains the answer without repetition")
	home.queue_free();await frames()

func run() -> void:
	domain();mixed_authority();await journey();await stale_menu();await stale_care();await deferred_second_outing();await care_priority()
	for suffix in ["",".tmp",".checkpoint"]:
		if FileAccess.file_exists(SAVE+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("NIHANG_CAMP_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
