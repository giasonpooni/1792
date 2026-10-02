extends "res://tests/render_beginning_sequence.gd"
## Extends the unseeded beginning route through learned riding, the original
## course, practice, tracking, living return and household inquiry. Only real native input enters
## the existing reducers/motors; every retained camera is the production camera.
const OPENING_OUTPUT:="user://opening-chapter-images"
const SAVE:="user://opening-chapter-render-only.json"
const OpeningCheckpoint:=preload("res://childhood/checkpoint_store.gd")
const Aftermath:=preload("res://childhood/aftermath_state.gd")
const TerritoryRules:=preload("res://territory/misl_rules.gd")
const HouseholdCraft:=preload("res://workshops/workshop_rules.gd")
const HOUSEHOLD_CAPTURES:=["quartermaster-allowance","household-commission","smith-handover","smith-collection","household-task-complete"]
var learned_receipt: Dictionary={}
var shot_records: Array=[]
var midreturn_persistence: Dictionary={}
var final_manual_save: Dictionary={}
var inquiry_choice:="household_escort"
var independent_guard_refusal: Dictionary={}
var household_task:="none"
var household_task_persistence: Dictionary={}
var _household_body_ids: Array=[]
var _household_guard_observation: Dictionary={}
var _household_checkpoint_sha:=""

func _configure_inquiry_choice() -> bool:
	var supplied:=false
	var task_supplied:=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--through-household-task="):
			if task_supplied: return check(false,"duplicate opening through-household-task argument")
			task_supplied=true
			var task_value:=argument.trim_prefix("--through-household-task=")
			if task_value!="smith-commission": return check(false,"unsupported opening household task: "+task_value)
			household_task=task_value
			continue
		if not argument.begins_with("--inquiry-choice="):
			return check(false,"unknown opening qualification argument: "+argument)
		if supplied: return check(false,"duplicate opening inquiry-choice argument")
		supplied=true
		var value:=argument.trim_prefix("--inquiry-choice=")
		if value not in ["household_escort","independent_inquiry"]:
			return check(false,"unsupported opening inquiry choice: "+value)
		inquiry_choice=value
	return check(inquiry_choice in ["household_escort","independent_inquiry"],"opening qualification binds a whitelisted inquiry choice: "+inquiry_choice)

func note(id: String) -> void:
	super.note(id)
	var item: Dictionary=route.back()
	item.aftermath_phase=chapter.model.aftermath_phase()
	item.inquiry_choice=inquiry_choice
	item.aftermath=chapter.model.aftermath()
	item.escort_physical_position=point(chapter.escort.global_position)
	item.escort_observation=_escort_observation()
	item.journal_ids=chapter.model.journal().map(func(memory): return memory.id)
	item.riding_skills=chapter.model.snapshot().riding_skills
	item.avatar_velocity=point(chapter.avatar.velocity)
	item.avatar_global_rotation=point(chapter.avatar.global_rotation)
	item.camera_pivot_local_rotation=point(chapter.avatar.pivot.rotation)
	item.camera_pivot_global_rotation=point(chapter.avatar.pivot.global_rotation)
	item.household_task=household_task
	item.economy=chapter.model.economy()
	item.workshop_phase=chapter.model.workshop_phase()
	item.workshop=chapter.model.workshop()
	item.workshop_observation=_workshop_observation()

func _escort_observation() -> Dictionary:
	return {"visible":chapter.escort.visible,"collision_layer":chapter.escort.collision_layer,
		"position":point(chapter.escort.global_position),"yaw":chapter.escort.rotation.y,"velocity":point(chapter.escort.velocity)}

func _workshop_observation() -> Dictionary:
	return {"carried_visible":chapter.workplace.carried.visible,"tool_heads_visible":chapter.workplace.carried.get_node("ToolHeads").visible,
		"bench_tools_visible":chapter.workplace.finished.visible,"coal_visible":chapter.workplace.coal.visible,
		"external_speed_limit":chapter.avatar.external_speed_limit if is_finite(chapter.avatar.external_speed_limit) else "unbounded"}

func look_toward(target: Vector3) -> void:
	var offset: Vector3=target-chapter.avatar.global_position
	var desired: float=atan2(-offset.x,-offset.z)
	var turn: float=wrapf(desired-chapter.avatar.pivot.global_rotation.y,-PI,PI)
	mouse_motion(Vector2(-turn/chapter.avatar.mouse_sensitivity,0))
	await process_frame
	check(absf(wrapf(chapter.avatar.pivot.global_rotation.y-desired,-PI,PI))<.01,"native mouse look faces the actual world route target")

func walk_to(target: Vector3,radius: float=.45) -> bool:
	controls();await look_toward(target)
	var best: float=Base.distance(chapter.avatar.global_position,target)
	var stalled:=0
	# Correct the walk with ordinary mouse turns as a player would. A single
	# initial heading can miss a point after collision slides or unequal native
	# axis acceleration; no pose or controller state is injected to fix the route.
	for _i in range(900):
		var distance: float=Base.distance(chapter.avatar.global_position,target)
		if distance<=radius:
			controls();await frames(16)
			return check(Base.distance(chapter.avatar.global_position,target)<radius+1.0,"actual corrected walking reaches %s"%target)
		if distance<best-.03: best=distance;stalled=0
		else: stalled+=1
		if stalled>=120:
			controls();note("blocked-walking")
			for index in range(chapter.avatar.get_slide_collision_count()):
				var collision: KinematicCollision3D=chapter.avatar.get_slide_collision(index)
				print("OPENING WALK CONTACT: ",collision.get_collider().get_path()," normal=",collision.get_normal()," at=",collision.get_position())
			return check(false,"actual corrected walking stalls at %s toward %s; %s"%[chapter.avatar.global_position,target,chapter._message])
		var offset: Vector3=target-chapter.avatar.global_position
		var desired: float=atan2(-offset.x,-offset.z)
		var turn: float=wrapf(desired-chapter.avatar.pivot.global_rotation.y,-PI,PI)
		if absf(turn)>.005: mouse_motion(Vector2(-turn/chapter.avatar.mouse_sensitivity,0))
		controls(1);await frames(1)
	controls();note("walk-timeout")
	return check(false,"ordinary corrected input never reaches target %s"%target)

func physical_key(code: int,pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)

func primary_click() -> void:
	for pressed_flag in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed_flag
		if is_instance_valid(session): session._input(event)
		else: root.push_input(event,true)

func capture(id: String,purpose: String,visit: Node=null) -> void:
	controls()
	var viewport: Viewport=root
	var prior_process: int=home.process_mode
	var before: Dictionary=chapter.model.snapshot()
	var avatar_transform: Transform3D=chapter.avatar.global_transform
	var horse_transform: Transform3D=chapter.horse.global_transform
	var threat_transform: Transform3D=chapter.attacker.global_transform
	var escort_transform: Transform3D=chapter.escort.global_transform
	var prior_disable: bool=root.disable_3d
	var local_snapshot: Dictionary={}
	var presentation: Dictionary={}
	var prior_paused:=false
	if visit!=null:
		viewport=session.viewport
		if visit.has_method("presentation_snapshot"):
			for _i in range(30):
				if visit.presentation_snapshot().get("settled",false): break
				await process_frame
			presentation=visit.presentation_snapshot()
			check(presentation.get("settled",false),"story settles naturally for "+id)
		if visit.has_method("set_paused"):
			prior_paused=visit.paused;visit.set_paused(true);local_snapshot=visit.model.snapshot()
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	else:
		home.process_mode=Node.PROCESS_MODE_DISABLED;root.disable_3d=false
		if id=="household-return":
			# Exercise the actual read-only HUD projection while authority is parked.
			chapter.art.detail.hud.sample();chapter.art.detail.hud.sample()
			var actual_hud: Dictionary=hud_observation()
			check(actual_hud.compact_visible and actual_hud.task=="Hear the accounts after your return","actual escaped endpoint presents the current household account task")
			check(chapter._marker.visible and chapter._marker.text=="Steward · E" and chapter._marker.global_position.is_equal_approx(Base.SITES.steward+Vector3.UP*2.1),"actual escaped endpoint names and locates the existing steward objective")
			check(not actual_hud.legacy_visible,"actual escaped endpoint keeps the dense legacy HUD hidden")
			check(chapter.model.snapshot()==before and chapter.avatar.global_transform==avatar_transform and chapter.horse.global_transform==horse_transform and chapter.attacker.global_transform==threat_transform and chapter.escort.global_transform==escort_transform,"paused household guidance projection preserves whole authority, clock and all physical bodies")
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera3D=viewport.get_camera_3d()
	var image:=viewport.get_texture().get_image()
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"native1280x720 production-camera frame "+id)
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	var path:=OPENING_OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"retain chapter boundary "+id)
	check(chapter.model.snapshot()==before and chapter.avatar.global_transform==avatar_transform and chapter.horse.global_transform==horse_transform and chapter.attacker.global_transform==threat_transform and chapter.escort.global_transform==escort_transform,"capture freezes authority, rider, horse, threat and escort "+id)
	var record:={"id":id,"file":id+".png","purpose":purpose,"sha256":FileAccess.get_sha256(path),"pixel_sha256":digest(image.get_data()),
		"width":1280,"height":720,"pixel_format":"rgba8","camera_kind":"production-gameplay","camera_pose_injected":false,"inspection_camera_only":false,
		"camera_position":point(camera.global_position),"camera_rotation":point(camera.global_rotation),"fov":camera.fov,
		"state_sha256":chapter.model.present_sha256(),"home_tick":before.childhood.tick,"home_stage":chapter.model.stage(),
		"progress":before.childhood,"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==_art_id,
		"hud":hud_observation(),"capabilities":chapter.model.capabilities(),"home_execution_suspended_for_capture":true,
		"input_mouse_mode":Input.mouse_mode,"home_avatar_input_enabled":chapter.avatar.input_enabled,
		"aftermath_phase":chapter.model.aftermath_phase(),"aftermath":before.aftermath,
		"inquiry_choice":inquiry_choice,"escort_visible":chapter.escort.visible,"escort_collision_layer":chapter.escort.collision_layer,
		"escort_physical_position":point(chapter.escort.global_position),
		"escort_observation":_escort_observation(),
		"escort_pose_frozen_for_capture":true,"journal_ids":chapter.model.journal().map(func(memory): return memory.id),
		"objective_marker":{"visible":chapter._marker.visible,"text":chapter._marker.text,"position":point(chapter._marker.global_position)}}
	record.household_task=household_task
	record.economy=chapter.model.economy();record.workshop_phase=chapter.model.workshop_phase()
	record.workshop=chapter.model.workshop();record.workshop_observation=_workshop_observation()
	if id in HOUSEHOLD_CAPTURES: record.snapshot=before
	if visit!=null:
		record["separate_world_3d"]=viewport.own_world_3d
		if visit.has_method("story_beats"):
			record["camera_kind"]="production-story-presentation"
			check(visit.presentation_snapshot()==presentation,"settled story presentation stays unchanged across capture "+id)
			record["story_beat_id"]=visit.story_beats()[visit.current_beat].id;record["story_presentation"]=presentation
		else:
			check(visit.model.snapshot()==local_snapshot,"capture freezes local horsecraft reducer "+id)
			record["lesson_phase"]=visit.lesson_phase;record["lesson_tick"]=visit.lesson_tick
			record["single_hold_ticks"]=visit.max_single_hold_ticks;record["paired_hold_ticks"]=visit.max_paired_hold_ticks
			record["lesson_state"]=local_snapshot;record["rider_pose"]=observable(visit.rider.pose_observation())
			record["lesson_hud"]=visit.hud.text;record["lesson_status"]=visit.status.text
			record["rider_weapons"]=observable(visit.rider.weapon_observation())
			record["support"]=visit.observation();record["lesson_execution_paused_for_capture"]=true
			visit.set_paused(prior_paused)
		viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	else:
		home.process_mode=prior_process;root.disable_3d=prior_disable
	captures.append(record)

func finish() -> void:
	physical_key(KEY_Q,false);physical_key(KEY_C,false);controls()
	var checkpoint: String=chapter.checkpoint_path() if is_instance_valid(chapter) else SAVE+".checkpoint.json"
	var manifest:={"schema":"1792.opening-chapter-render.v2","inquiry_choice":inquiry_choice,"household_task":household_task,"captures":captures,"route":route,"failures":failures,"checks":checks,
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
		"physics_hz":Engine.physics_ticks_per_second,"entry":"actual HomeLaunch.enter","prologue_route":"explicit F2 skip; separately qualified playable route","entry_state_sha256":_binding_sha,
		"human_playtest":false,"camera_pose_injected":false,"progress_seeded":false,"saved_pose_restored":not midreturn_persistence.is_empty(),"startup_save_seeded":false,"capability_receipt_seeded":false,
		"save_restore_route":"actual F5/F9 after freshly earned clue and report; no startup save seed",
		"midreturn_persistence":midreturn_persistence,"final_manual_save":final_manual_save,
		"household_task_persistence":household_task_persistence,
		"independent_guard_refusal":independent_guard_refusal,
		"input_source":"native routed mouse/key events, physically held guard/quiet keys, ordinary game actions and actual dialog controls",
		"between_capture_3d_rendering_disabled":true,"historical_authentication":false,"earned_training_receipt":learned_receipt,
		"native_shot_observations":shot_records,"final_snapshot":chapter.model.snapshot() if is_instance_valid(chapter) else {},
		"production_automatic_checkpoint":{ "file":checkpoint,"sha256":FileAccess.get_sha256(checkpoint) if FileAccess.file_exists(checkpoint) else "absent",
			"isolation":"renderer-specific save slot; generated by the unchanged production checkpoint path"}}
	var file:=FileAccess.open(OPENING_OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"retain opening chapter manifest");manifest.checks=checks;manifest.failures=failures
	if file: file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	current_scene=null
	if is_instance_valid(home): home.queue_free()
	home=null;chapter=null;session=null;lesson=null;await process_frame
	print("OPENING_CHAPTER_RENDER: %d captures; %d checks; %d failures"%[captures.size(),checks,failures]);quit(1 if failures else 0)

func ride_to(target: Vector3,expected_gate: int=0,radius: float=1.5) -> bool:
	var best: float=Base.distance(chapter.horse.global_position,target)
	var stalled:=0
	for _i in range(900):
		var distance: float=Base.distance(chapter.horse.global_position,target)
		if (expected_gate>0 and chapter.model.progress().ride_gate>=expected_gate) or (expected_gate==0 and distance<=radius):
			controls(0,0,true);await frames(45);controls()
			return check(chapter.model.progress().ride_gate>=expected_gate and chapter.horse.speed<=.15,"native horse input reaches %s / gate%d"%[target,expected_gate])
		var offset: Vector3=target-chapter.horse.global_position
		var desired: float=atan2(-offset.x,-offset.z)
		var angle: float=wrapf(desired-chapter.horse.rotation.y,-PI,PI)
		var steering: float=clampf(-angle*2.5,-1.0,1.0)
		var throttle: float=clampf(distance/6.0,.2,1.0) if absf(angle)<.5 else 0.0
		controls(throttle,steering,absf(angle)>.65)
		if distance<best-.03: best=distance;stalled=0
		elif absf(angle)<.15: stalled+=1
		if stalled>=150:
			controls();note("blocked-riding")
			return check(false,"native riding blocked at %s toward %s; yaw=%s; %s"%[chapter.horse.global_position,target,chapter.horse.rotation.y,chapter._message])
		await frames(1)
	controls();note("riding-timeout")
	return check(false,"native horse input did not reach %s"%target)

func _beginning() -> bool:
	controls();Launch.enter(self);home=current_scene;chapter=home.get_node("ChildhoodChapter");chapter.save_path=SAVE
	_art_id=chapter.art.get_instance_id();_initial_snapshot=chapter.model.snapshot()
	await process_frame;await process_frame;session=chapter.intro_session
	if not check(is_instance_valid(session),"production new game opens the family story"): return false
	# Childhood route explicitly skips the outer frame through its real F2 control.
	if session.prologue_active:
		key(KEY_F2);await process_frame;await process_frame
	lesson=session.lesson;session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;_binding_sha=session.present_sha256
	await capture("family-opening","Actual family introduction before gameplay",lesson)
	for _i in range(lesson.story_beats().size()): key(KEY_ENTER);await process_frame
	await process_frame;session=null;lesson=null;root.disable_3d=true
	if not check(chapter.model.stage()=="orientation" and chapter.model.progress().ride_gate==0 and chapter.model.journal().is_empty(),"story returns to an unseeded childhood beginning"): return false
	mouse_motion(Vector2(160,0));mouse_motion(Vector2(-160,0))
	for target in [Vector3(-4.8,.14,1),Vector3(-5.2,.14,2)]:
		if not await walk_to(target): return false
	await look_toward(Base.SITES.courier);key(KEY_E);await frames(3);key(KEY_E);await frames(3)
	if not await walk_to(Vector3(-10.6,.14,4)): return false
	await look_toward(Base.SITES.steward);key(KEY_E);await frames(3)
	if not check(chapter.model.stage()=="riding" and chapter.model.progress().heard.size()==2,"real walking and two heard accounts open ordinary riding"): return false
	note("oral-briefing-earned");await capture("riding-ready","Original riding lesson earned by collecting and hearing the message")
	for target in [Vector3(-8,.14,-.7),Vector3(4,.14,-2.5),Vector3(6.8,.14,-4)]:
		if not await walk_to(target): return false
	await look_toward(chapter.horse.global_position);key(KEY_F);await frames(5)
	if not check(chapter.model.mounted(),"actual F mounts the original Home horse"): return false
	if not await ride_to(Base.GATES[0],1): return false
	note("first-gate-earned");await capture("first-gate","First gate earned through the unchanged horse motor")
	key(KEY_F);await frames(5)
	if not check(not chapter.model.mounted(),"actual F dismounts beside the first course gate"): return false
	if not await walk_to(Vector3(7.4,.14,-4.4)): return false
	await look_toward(Skills.TRAINING_SITE);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter._panel_text.text.begins_with("RIDING LESSON"),"real first-gate progress opens the stable trainer dialogue"): return false
	click_button(chapter._actions.get_child(0));await frames(3);session=chapter.training_session
	if not check(is_instance_valid(session),"actual trainer UI enters protected horsecraft learning"): return false
	lesson=session.lesson;session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	return true

func _learn_horsecraft() -> bool:
	var retained: Dictionary=chapter.model.snapshot()
	controls(1);await frames(35);key(KEY_SPACE);await frames(Stance.RISE_TICKS+60+5)
	if not check(lesson.single_standing_ticks>=60 and lesson.model.stance()=="standing","native one-horse standing earns the single hold"): return false
	await capture("single-standing","Actual one-horse balance exercise",lesson)
	key(KEY_ENTER);await frames(5)
	controls(1);await frames(35);key(KEY_SPACE);await frames(Stance.RISE_TICKS+60+5)
	if not check(lesson.paired_standing_ticks>=60 and lesson.model.stance()=="standing","native independent horse pair earns the paired hold"): return false
	await capture("paired-standing","Actual independently moving paired-horse balance exercise",lesson)
	key(KEY_ENTER);await frames(2)
	for slot in range(4): key(KEY_1+slot);primary_click()
	if not check(lesson.model.snapshot().slots==[false,false,false,false] and lesson.shot_observations.size()==4,"four selected mounted weapons spend four distinct real charges"): return false
	shot_records=lesson.shot_observations.duplicate(true)
	var fired_slots: Array=[]
	var fired_identities: Dictionary={}
	for shot in shot_records:
		fired_slots.append(shot.slot);fired_identities[shot.shot_id]=true
	if not check(fired_slots==[0,1,2,3] and fired_identities.size()==4,"native volley records four separately selected weapon slots and shot identities"): return false
	await capture("four-matchlocks-spent","Four separately selected mounted discharges",lesson)
	controls(0,0,true);await frames(45);key(KEY_1);key(KEY_R);await frames(60)
	if not check(lesson.model.snapshot().reload_slot==0 and lesson.model.snapshot().reload_ticks>0,"first exclusive reload advances at actual safe gait"): return false
	await capture("mounted-reload","Actual selected mounted reload at a stopped gait",lesson)
	await frames(Stance.RELOAD_TICKS)
	for slot in range(1,4): key(KEY_1+slot);key(KEY_R);await frames(Stance.RELOAD_TICKS+1)
	key(KEY_SPACE);await frames(Stance.RECOVER_TICKS+5)
	learned_receipt=lesson.completion_receipt()
	if not check(not learned_receipt.is_empty() and lesson.model.snapshot().slots==[true,true,true,true],"actual four reload cycles and safe recovery earn a real bound receipt"): return false
	if not check(chapter.model.snapshot()==retained,"complete native learning leaves parked Home exact until return"): return false
	var returned: Dictionary={}
	session.tree_exiting.connect(func(): returned.snapshot=chapter.model.snapshot())
	key(KEY_ENTER);await process_frame;await process_frame;session=null;lesson=null
	if not check(chapter.model.capabilities()=={"single_standing":true,"paired_standing":true,"mounted_matchlock":true},"guarded native return admits all three learned capabilities"): return false
	var admitted: Dictionary=returned.get("snapshot",{});admitted.erase("riding_skills")
	var original: Dictionary=retained.duplicate(true);original.erase("riding_skills")
	if not check(admitted==original and chapter.model.snapshot().riding_skills.lesson_receipts.size()==1,"actual admission changes only one riding skill extension"): return false
	note("horsecraft-learned");await capture("horsecraft-return","All three actually learned skills admitted into the original Home")
	if not check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and chapter.avatar.input_enabled,"native learned return restores Home pointer capture and avatar input after isolated lesson disposal"): return false
	return true

func _course_and_practice() -> bool:
	var beside: Vector3=chapter.horse.global_position+Vector3(1.6,0,1.2)
	if not await walk_to(beside): return false
	await look_toward(chapter.horse.global_position);key(KEY_F);await frames(5)
	if not check(chapter.model.mounted(),"actual F remounts the same parked course horse"): return false
	# Gates share north/south-oriented poles. Approach gate2 along its front
	# through visible open ground using the unchanged horse motor.
	for target in [Vector3(2,.14,-13.3),Vector3(-8,.14,-13.3)]:
		if not await ride_to(target): return false
	if not await ride_to(Base.GATES[1],2): return false
	note("second-gate-earned")
	if not await ride_to(Base.GATES[2],3): return false
	if not check(chapter.model.stage()=="sparring" and chapter.model.progress().ride_gate==3,"all three actual course gates open the original sparring lesson"): return false
	note("course-complete");await capture("riding-course-complete","Actual three-gate course completed on the existing Home horse")
	key(KEY_F);await frames(5)
	if not check(not chapter.model.mounted(),"actual F dismounts after completing the riding course"): return false
	if not await walk_to(Vector3(-14.4,.14,-3.0)): return false
	await look_toward(Base.SITES.spar);physical_key(KEY_Q,true)
	for _i in range(360):
		if chapter.model.progress().parries>=2: break
		await frames(1)
	if not check(chapter.model.progress().parries==2,"genuinely held Q guards two raised practice blows"): physical_key(KEY_Q,false);return false
	for _i in range(150):
		if int(chapter.model.progress().tick)%150>120: break
		await frames(1)
	primary_click();await frames(2);physical_key(KEY_Q,false)
	if not check(chapter.model.progress().counters==1 and chapter.model.stage()=="tracking","actual click in trainer recovery earns the counter and tracking lesson"): return false
	note("practice-earned");await capture("practice-complete","Two real timed guards and a recovery counter open the hunting trail")
	return true

func _track_and_return() -> bool:
	for index in range(1,4):
		var site: Vector3=Base.SITES["track_%d"%index]
		if not await walk_to(site+Vector3(1.2,0,1.2)): return false
		await look_toward(site);key(KEY_E);await frames(3)
		if not check(chapter.model.progress().tracks==index,"actual sight and E examine trace%d in order"%index): return false
		note("trace-%d-earned"%index)
	await capture("tracking-trail","Three actually reached, faced and examined traces")
	physical_key(KEY_C,true)
	if not await walk_to(Vector3(9,.14,-23)): physical_key(KEY_C,false);return false
	await look_toward(Base.SITES.quarry);key(KEY_E);await frames(3);physical_key(KEY_C,false)
	if not check(chapter.model.progress().quarry_seen and chapter.model.stage()=="ready","genuinely held C and actual E quietly observe the quarry"): return false
	note("quarry-observed");await capture("quarry-observed","Actual quiet approach and observed quarry conclude tracking")
	if not await walk_to(Base.SITES.bend): return false
	if not check(chapter.model.stage()=="active","ordinary return through the actual bend starts the encounter"): return false
	await look_toward(chapter.attacker.global_position);await frames(2)
	if not check(chapter.model.progress().ambush.seen,"actual view witnesses the approaching unknown assailant"): return false
	note("return-encounter");await capture("return-encounter","Actual witnessed threat on the unmodified return trail")
	if not await walk_to(Base.SITES.home): return false
	if not check(chapter.model.stage()=="escaped" and chapter.model.progress().ambush.hits<3,"ordinary movement reaches the courtyard alive"): return false
	if not check(chapter.model.snapshot().riding_skills.lesson_receipts.size()==1 and chapter.model.capabilities().mounted_matchlock,"earned riding receipt survives the original course and return encounter"): return false
	if not check(chapter.model.validate(chapter.model.snapshot()).is_empty(),"actual opening chapter endpoint remains a valid whole Home state"): return false
	var checkpoint_result: Dictionary=OpeningCheckpoint.read(chapter.checkpoint_path(),chapter.model.get_script())
	if not check(checkpoint_result.error.is_empty(),"unchanged production path generates a valid isolated opening checkpoint"): return false
	# Checkpoint.read returns raw JSON integral floats; compare both saved-data
	# projections with the same numeric representation after production validation.
	var saved_projection: Dictionary=JSON.parse_string(JSON.stringify(chapter.model.snapshot().riding_skills))
	if not check(checkpoint_result.envelope.reason=="courtyard_return" and checkpoint_result.envelope.snapshot.riding_skills==saved_projection and checkpoint_result.envelope.snapshot.childhood.ambush.status=="escaped","production courtyard checkpoint retains the genuinely earned riding receipt and living return"): return false
	note("living-household-return");await capture("household-return","Actual living return to the household after learning, riding, practice and tracking")
	return true

func _dialog_click(prefix: String) -> bool:
	var selected: Button
	for button in chapter._actions.get_children():
		if button is Button and button.text.begins_with(prefix): selected=button;break
	if not check(is_instance_valid(selected) and chapter._paused,"actual displayed dialogue offers "+prefix): return false
	click_button(selected);await frames(3)
	return true

func _wait_for_guard(target: Vector3,radius: float) -> bool:
	controls()
	for _i in range(360):
		if Base.distance(chapter.escort.global_position,target)<=radius:
			return check(chapter.model.aftermath().escort.active and chapter.model.aftermath().escort.instruction=="follow" and chapter.escort.global_position.distance_to(Base.point(chapter.model.aftermath().escort.position))<.01,"same physical household guard reaches the existing witness radius")
		await frames(1)
	return check(false,"native household guard did not reach %s within %s; actual=%s; %s"%[target,radius,chapter.escort.global_position,chapter._message])

func _guard_undeployed(boundary: String) -> bool:
	var guard: Dictionary=chapter.model.aftermath().escort
	return check(guard.id=="fictional_household_guard" and not guard.active and guard.instruction=="hold"
		and Base.point(guard.position)==Aftermath.ESCORT_HOME and guard.yaw==0.0 and Base.point(guard.velocity)==Vector3.ZERO
		and not chapter.escort.visible and chapter.escort.collision_layer==0
		and chapter.escort.global_position==Aftermath.ESCORT_HOME and chapter.escort.rotation.y==0.0 and chapter.escort.velocity==Vector3.ZERO,
		"independent inquiry retains the existing undeployed guard at its unchanged home pose: "+boundary)

func _return_to_raj() -> bool:
	for target in [Vector3(3,.14,-8),Vector3(2,.14,1),Aftermath.MOTHER+Vector3(0,0,-1.8)]:
		if not await walk_to(target): return false
	if inquiry_choice=="household_escort":
		if not await _wait_for_guard(Aftermath.MOTHER,6.5): return false
	elif not _guard_undeployed("physical return to Raj Kaur"): return false
	await look_toward(Aftermath.MOTHER);key(KEY_E);await frames(3)
	return check(chapter._paused and chapter._panel_text.text.begins_with("RAJ KAUR · THE ACCOUNT YOU BRING BACK"),"actual returned player and guard open Raj Kaur's spoken-report dialogue" if inquiry_choice=="household_escort" else "actual independently returned player opens Raj Kaur's spoken-report dialogue")

func _native_reload_boundary(saved_snapshot: Dictionary) -> bool:
	# Observe the ordinary F9 load after native processing, before a resumed
	# physics tick. The temporary execution park only records this boundary;
	# the live Home is never restored or repositioned by this renderer.
	controls();key(KEY_F9)
	for _i in range(300):
		await process_frame
		if chapter._message=="Whole Home and riding skills restored.":
			var prior_process: int=home.process_mode
			home.process_mode=Node.PROCESS_MODE_DISABLED
			var restored: Dictionary=chapter.model.snapshot()
			midreturn_persistence.restored_snapshot=restored
			midreturn_persistence.restored_tick=restored.childhood.tick
			midreturn_persistence.restored_state_sha256=chapter.model.present_sha256()
			var exact:=check(restored==saved_snapshot,"actual F9 restores the exact whole saved Home at its native load boundary")
			check(chapter.avatar.global_position.is_equal_approx(Base.point(restored.player.position)) and chapter.escort.global_position.is_equal_approx(Base.point(restored.aftermath.escort.position)),"actual F9 applies saved player and household guard poses to the same existing native bodies")
			check(restored.aftermath.reported_tick==-1 and restored.aftermath.decision==inquiry_choice and restored.aftermath.escort.active==(inquiry_choice=="household_escort") and chapter.model.aftermath_phase()=="return" and chapter.model.journal().back().id=="bend_trace","F9 removes the later spoken-report knowledge and restores the outstanding escort obligation" if inquiry_choice=="household_escort" else "F9 removes later report knowledge and preserves the independent agreement without deploying a guard")
			if inquiry_choice=="independent_inquiry": exact=_guard_undeployed("exact native F9 load boundary") and exact
			check(restored.riding_skills.lesson_receipts==[learned_receipt] and chapter.model.capabilities()=={"single_standing":true,"paired_standing":true,"mounted_matchlock":true},"whole-state rollback preserves the genuinely earned horsecraft receipt and all learned capabilities")
			home.process_mode=prior_process
			note("midreturn-native-reload")
			return exact
	return check(false,"actual F9 never exposed the successful production whole-Home load boundary")

func _after_save_projection(value: Dictionary) -> Dictionary:
	# Guard motion originated in native Vector3/rotation values. Reconcile only
	# those declared physical fields with their binary32 representation. Exact
	# JSON projection still compares all event, knowledge and identity fields.
	var copy: Dictionary=value.duplicate(true)
	for field in ["position","velocity"]:
		copy.escort[field]=Array(PackedFloat32Array(copy.escort[field]))
	copy.escort.yaw=PackedFloat32Array([copy.escort.yaw])[0]
	return JSON.parse_string(JSON.stringify(copy,"",true,true))

func _household_inquiry() -> bool:
	var checkpoint_sha:=FileAccess.get_sha256(chapter.checkpoint_path())
	for target in [Vector3(-10,.14,2),Vector3(-10.5,.14,5)]:
		if not await walk_to(target): return false
	await look_toward(Base.SITES.steward);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter.model.aftermath().heard==["return_steward"],"fresh earned living return physically hears the steward's account through actual E"): return false
	if not await _dialog_click("Remember"): return false
	for target in [Vector3(-7,.14,2),Vector3(-5.6,.14,3)]:
		if not await walk_to(target): return false
	await look_toward(Base.SITES.courier);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter.model.aftermath().heard==["return_steward","return_courier"],"actual second speaker adds his distinct returned account"): return false
	if not await _dialog_click("Remember"): return false
	note("returned-accounts-earned")
	if not await walk_to(Aftermath.MOTHER+Vector3(0,0,-1.8)): return false
	await look_toward(Aftermath.MOTHER);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter.model.aftermath_phase()=="choice" and chapter._panel_text.text.begins_with("RAJ KAUR · PROTECTION AND ITS PRICE"),"physically reached Raj Kaur offers the original household protection choice"): return false
	note("household-offer-earned");await capture("household-offer","Actual Raj Kaur protection offer after two returned accounts")
	if not await _dialog_click("Accept the household guard" if inquiry_choice=="household_escort" else "Insist on an independent inquiry"): return false
	if inquiry_choice=="household_escort":
		if not check(chapter.model.aftermath().decision=="household_escort" and chapter.model.aftermath().escort.active and chapter.escort.visible,"actual displayed acceptance deploys one existing physical household guard"): return false
		await frames(50);key(KEY_G);await frames(3)
		if not check(chapter.model.aftermath().escort.instruction=="hold","actual nearby G commands the agreed guard to hold"): return false
		var held_position: Vector3=chapter.escort.global_position
		if not await walk_to(Vector3(-1,.14,3)): return false
		if not check(Base.distance(chapter.escort.global_position,held_position)<.001,"actual walking does not move a held household guard"): return false
		if not await walk_to(Vector3(-4,.14,5)): return false
		key(KEY_G);await frames(3)
		if not check(chapter.model.aftermath().escort.instruction=="follow","actual nearby G regroups the same held guard"): return false
	else:
		if not check(chapter.model.aftermath().decision=="independent_inquiry" and chapter.model.household_disposition()=="Strained independence","actual displayed independent choice earns its original household consequence"): return false
		if not _guard_undeployed("actual independent agreement"): return false
		var before_refusal: Dictionary=chapter.model.aftermath()
		var before_tick: int=chapter.model.progress().tick
		var before_position: Vector3=chapter.avatar.global_position
		var before_guard: Dictionary=_escort_observation()
		controls();key(KEY_G);await frames(3)
		independent_guard_refusal={"input":"actual native G after the independent agreement","before_aftermath":before_refusal,
			"after_aftermath":chapter.model.aftermath(),"before_tick":before_tick,"after_tick":chapter.model.progress().tick,
			"before_player_position":point(before_position),"after_player_position":point(chapter.avatar.global_position),
			"before_guard":before_guard,"after_guard":_escort_observation(),"message":chapter._message,"world_paused":chapter._paused}
		if not check(chapter._message=="No deployed household escort." and chapter.model.aftermath()==before_refusal
			and _escort_observation()==before_guard and Base.distance(chapter.avatar.global_position,before_position)<.001
			and chapter.model.progress().tick>before_tick and not chapter._paused,
			"actual G refuses an undeployed guard without changing the independent aftermath while the ordinary world clock runs"): return false
		if not _guard_undeployed("actual refused G input"): return false
		note("independent-guard-order-refused")
	for target in [Vector3(2,.14,-2),Vector3(3,.14,-12),Aftermath.CLUE+Vector3(0,0,2)]:
		if not await walk_to(target): return false
	if inquiry_choice=="household_escort":
		if not await _wait_for_guard(Aftermath.CLUE,5.5): return false
	else:
		if not _guard_undeployed("independent arrival at the bend"): return false
		if not check(Base.distance(chapter.escort.global_position,Aftermath.CLUE)>6.0,"independent bend inspection has no household guard within the existing witness radius"): return false
	await look_toward(Aftermath.CLUE);key(KEY_E);await frames(3)
	if not check(chapter.model.aftermath_phase()=="return" and chapter.model.journal().back().id=="bend_trace","actual facing and E observe the bend with the agreed physical witness present" if inquiry_choice=="household_escort" else "actual facing and E independently observe the bend without a household witness"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("earned independent bend observation"): return false
	note("bend-trace-earned");await capture("bend-observed","Actually examined bend and physically attending household guard" if inquiry_choice=="household_escort" else "Actually examined bend without a household guard")
	key(KEY_F5);await frames(3)
	var saved_authority=chapter.model.get_script().new()
	if not check(saved_authority.load_from(SAVE).is_empty(),"actual F5 writes a production-validated complete Home save during the inquiry return"): return false
	var saved_snapshot: Dictionary=saved_authority.snapshot()
	var save_bytes:=FileAccess.get_file_as_bytes(SAVE)
	var retained_file:=FileAccess.open(OPENING_OUTPUT.path_join("midreturn-save.json"),FileAccess.WRITE)
	if not check(retained_file!=null,"retain exact native midreturn save bytes for independent evidence verification"): return false
	retained_file.store_buffer(save_bytes);retained_file.close()
	midreturn_persistence={"file":SAVE,"retained_file":"midreturn-save.json","save_sha256":FileAccess.get_sha256(SAVE),
		"saved_snapshot":saved_snapshot,"saved_tick":saved_snapshot.childhood.tick,"saved_state_sha256":saved_authority.present_sha256(),
		"declared_saved_pose_restored":true,"input":"actual native F5 and F9 after unseeded earned progress"}
	if not check(saved_snapshot.aftermath.clue_tick>=saved_snapshot.aftermath.decision_tick and saved_snapshot.aftermath.reported_tick==-1 and saved_snapshot.aftermath.decision==inquiry_choice and saved_snapshot.aftermath.escort.active==(inquiry_choice=="household_escort") and saved_snapshot.riding_skills.lesson_receipts==[learned_receipt],"midreturn save retains causal clue knowledge, outstanding report, attending guard and exact earned horsecraft receipt" if inquiry_choice=="household_escort" else "midreturn save retains the independent choice, clue knowledge and learned receipt without a free guard"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("actual independent midreturn save"): return false
	note("midreturn-native-save")
	if not await _return_to_raj(): return false
	note("observed-report-offered");await capture("household-report","Actual spoken-report dialogue after the player and guard return to Raj Kaur" if inquiry_choice=="household_escort" else "Actual spoken-report dialogue after the player's independent return")
	if not await _dialog_click("Give the observed account"): return false
	if not check(chapter.model.aftermath_phase()=="complete" and chapter.model.journal().back().id=="oral_return" and not chapter.model.aftermath().escort.active,"first actually spoken report completes the inquiry and retires its guard obligation" if inquiry_choice=="household_escort" else "first actually spoken independent report completes the inquiry without deploying a guard"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("first actual independent report"): return false
	midreturn_persistence.progressed_snapshot=chapter.model.snapshot()
	if not check(FileAccess.get_sha256(SAVE)==midreturn_persistence.save_sha256,"later earned reporting leaves the independent manual save unchanged"): return false
	note("first-report-earned-before-reload")
	if not await _native_reload_boundary(saved_snapshot): return false
	if not await _return_to_raj(): return false
	if not await _dialog_click("Give the observed account"): return false
	var final_snapshot: Dictionary=chapter.model.snapshot()
	if not check(chapter.model.aftermath_phase()=="complete" and final_snapshot.aftermath.memories.map(func(memory): return memory.id)==["return_steward","return_courier","protection_offer",inquiry_choice,"bend_trace","oral_return"],"replayed physical return completes exactly one report after the whole knowledge rollback"): return false
	if not check(not final_snapshot.aftermath.escort.active and final_snapshot.aftermath.escort.instruction=="hold" and Base.point(final_snapshot.aftermath.escort.velocity)==Vector3.ZERO,"completed inquiry retires and holds the same household guard without a duplicate actor"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("replayed independent report"): return false
	if not check(chapter.model.validate(final_snapshot).is_empty() and final_snapshot.riding_skills.lesson_receipts==[learned_receipt] and not chapter.model.has_economy(),"completed unseeded beginning validates with its earned skills and no premature household allowance"): return false
	if not check(FileAccess.get_sha256(chapter.checkpoint_path())==checkpoint_sha,"inquiry, actual manual save and native reload preserve the original pre-inquiry automatic checkpoint"): return false
	key(KEY_J);await frames(3)
	var journal_snapshot: Dictionary=chapter.model.snapshot()
	var journal_guard: Transform3D=chapter.escort.global_transform
	await frames(15)
	if not check(chapter._paused and chapter._panel.visible and not chapter.art.detail.hud.visible and chapter._panel_text.text.contains(Aftermath.AFTER_ACCOUNTS.oral_return.text),"actual final journal presents the earned spoken report and suppresses compact world guidance"): return false
	if not check(chapter.model.snapshot()==journal_snapshot and chapter.escort.global_transform==journal_guard,"completed inquiry journal freezes whole knowledge, clock and physical guard"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("actual completed independent journal"): return false
	key(KEY_ESCAPE);await frames(3)
	var final_hud: Dictionary=hud_observation()
	if not check(final_hud.compact_visible and final_hud.task=="Speak to the quartermaster" and not final_hud.legacy_visible and chapter._marker.visible and chapter._marker.global_position.is_equal_approx(TerritoryRules.QUARTERMASTER+Vector3.UP*2.1),"completed inquiry continues with compact guidance and the actual quartermaster objective"): return false
	var prior_process: int=home.process_mode
	home.process_mode=Node.PROCESS_MODE_DISABLED
	var layout_snapshot: Dictionary=chapter.model.snapshot()
	var layout_guard: Transform3D=chapter.escort.global_transform
	var hud: Node=chapter.art.detail.hud
	for size in [Vector2i(800,600),Vector2i(1280,720)]:
		root.size=size;hud.sample();await process_frame;hud.sample();await process_frame
		var screen:=root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.bottom.get_global_rect()) and not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()),"completed inquiry compact objective and actual words fit without overlap at %dx%d"%[size.x,size.y])
	check(chapter.model.snapshot()==layout_snapshot and chapter.escort.global_transform==layout_guard,"final guidance resizing preserves whole authority and physical witness")
	home.process_mode=prior_process
	key(KEY_F5);await frames(3)
	var final_authority=chapter.model.get_script().new()
	if not check(final_authority.load_from(SAVE).is_empty(),"actual final F5 saves the completed beginning through the unchanged production save authority"): return false
	var saved_final: Dictionary=final_authority.snapshot()
	final_manual_save={"file":SAVE,"sha256":FileAccess.get_sha256(SAVE),"snapshot":saved_final,"state_sha256":final_authority.present_sha256()}
	if not check(final_authority.aftermath_phase()=="complete","final native manual save validates as a completed household inquiry"): return false
	if not check(_after_save_projection(saved_final.aftermath)==_after_save_projection(chapter.model.aftermath()),"final native manual save retains exact inquiry knowledge and the same binary32 physical guard pose"): return false
	if not check(saved_final.riding_skills.lesson_receipts==[learned_receipt],"final native manual save preserves the exact earned horsecraft receipt"): return false
	if inquiry_choice=="independent_inquiry" and not _guard_undeployed("actual final independent save"): return false
	final_manual_save.comparison={"exact_fields":"all aftermath identity, decision, knowledge and event fields; earned receipt",
		"physical_fields":"escort.position, escort.velocity, escort.yaw reconcile by native binary32 equality",
		"raw_save_bytes_modified":false}
	note("household-inquiry-complete");await capture("inquiry-complete","Complete earned inquiry with actual quartermaster handoff and native manual save")
	return check(captures.size()==18,"complete fresh opening retains exactly eighteen production-camera boundaries")

func _household_native_ids() -> Array:
	return [home.get_instance_id(),chapter.get_instance_id(),chapter.avatar.get_instance_id(),chapter.horse.get_instance_id(),
		chapter.attacker.get_instance_id(),chapter.escort.get_instance_id(),chapter.merchant.get_instance_id(),
		chapter.service_agent.get_instance_id(),chapter.workplace.get_instance_id(),chapter.art.get_instance_id()]

func _household_continuity(boundary: String) -> bool:
	var value: Dictionary=chapter.model.snapshot()
	var intact:=check(chapter.model.validate(value).is_empty() and value.riding_skills.lesson_receipts==[learned_receipt]
		and chapter.model.capabilities()=={"single_standing":true,"paired_standing":true,"mounted_matchlock":true},"first household responsibility preserves the validated earned horsecraft receipt at "+boundary)
	intact=check(_after_save_projection(value.aftermath)==_after_save_projection(household_task_persistence.inquiry_snapshot.aftermath)
		and chapter.model.aftermath_phase()=="complete" and not value.aftermath.escort.active
		and _escort_observation()==_household_guard_observation,"first household responsibility preserves the completed inquiry and the same stationary retired guard at "+boundary) and intact
	intact=check(_household_native_ids()==_household_body_ids and FileAccess.get_sha256(chapter.checkpoint_path())==_household_checkpoint_sha,
		"first household responsibility retains every native Home body and the original automatic checkpoint at "+boundary) and intact
	if inquiry_choice=="independent_inquiry": intact=_guard_undeployed(boundary) and intact
	return intact

func _native_household_reload_boundary(saved_snapshot: Dictionary) -> bool:
	controls();key(KEY_F9)
	for _i in range(300):
		await process_frame
		if chapter._message!="Whole Home and riding skills restored.": continue
		var prior_process: int=home.process_mode
		home.process_mode=Node.PROCESS_MODE_DISABLED
		var restored: Dictionary=chapter.model.snapshot()
		household_task_persistence.restored_snapshot=restored
		household_task_persistence.restored_tick=restored.childhood.tick
		household_task_persistence.restored_state_sha256=chapter.model.present_sha256()
		household_task_persistence.restored_native_body_ids=_household_native_ids()
		var exact:=check(restored==saved_snapshot,"actual household F9 restores the exact whole carried-fuel save at its native load boundary")
		exact=check(chapter.model.workshop_phase()=="fuel" and chapter.workplace.carried.visible and not chapter.workplace.carried.get_node("ToolHeads").visible
			and chapter.avatar.external_speed_limit==HouseholdCraft.CARRY_SPEED and chapter.avatar.global_position.is_equal_approx(Base.point(restored.player.position)),
			"actual household F9 restores fuel custody, its original speed cap and saved pose to the existing native player") and exact
		exact=check(restored.misl.events.map(func(event): return event.kind)==["smith.reserve"]
			and chapter.model.journal().back().id=="workshop_reserve","actual household F9 removes the later smith handover and its learned journal account") and exact
		exact=_household_continuity("exact carried-fuel native F9 boundary") and exact
		home.process_mode=prior_process
		note("household-fuel-native-reload")
		return exact
	return check(false,"actual household F9 never exposed its successful whole-Home load boundary")

func _walk_to_smith() -> bool:
	for target in [Vector3(3,.14,1),Vector3(-15,.14,1),Vector3(-15,.14,5.7)]:
		if not await walk_to(target): return false
	await look_toward(HouseholdCraft.SITE);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter._panel_text.text.begins_with("HOUSEHOLD SMITH"),"actual fuel carrier physically reaches and faces the original household smith through native E"): return false
	var frozen: Dictionary=chapter.model.snapshot()
	var guard: Transform3D=chapter.escort.global_transform
	await frames(15)
	return check(chapter.model.snapshot()==frozen and chapter.escort.global_transform==guard,
		"actual smith conversation freezes household custody, common clock and retired guard before handover")

func _household_objective(target: Vector3,label: String,boundary: String) -> bool:
	var before: Dictionary=chapter.model.snapshot()
	chapter.art.detail.hud.sample()
	return check(chapter._marker.visible and chapter._marker.text==label
		and chapter._marker.global_position.is_equal_approx(target+Vector3.UP*2.1)
		and chapter.model.snapshot()==before,"read-only compact objective locates the actual speaker without changing household authority at "+boundary)

func _first_household_responsibility() -> bool:
	if not check(household_task=="smith-commission" and captures.size()==18 and not chapter.model.has_economy(),
		"optional first household responsibility starts only after the complete freshly earned inquiry"): return false
	var inquiry_bytes:=FileAccess.get_file_as_bytes(SAVE)
	var retained_inquiry:=FileAccess.open(OPENING_OUTPUT.path_join("inquiry-manual-save.json"),FileAccess.WRITE)
	if not check(retained_inquiry!=null,"retain exact inquiry final F5 bytes before the first household responsibility overwrites its manual slot"): return false
	retained_inquiry.store_buffer(inquiry_bytes);retained_inquiry.close()
	_household_body_ids=_household_native_ids();_household_guard_observation=_escort_observation()
	_household_checkpoint_sha=FileAccess.get_sha256(chapter.checkpoint_path())
	household_task_persistence={"inquiry_snapshot":final_manual_save.snapshot,"inquiry_save_sha256":digest(inquiry_bytes),
		"inquiry_retained_file":"inquiry-manual-save.json","file":SAVE,"retained_file":"household-fuel-save.json",
		"declared_saved_pose_restored":true,"input":"actual native E and displayed allowance/commission/handover/collect/deliver buttons; actual F5/F9 after earned carried fuel",
		"initial_native_body_ids":_household_body_ids,"initial_escort_observation":_household_guard_observation,"final_task_completed":false}
	for target in [Vector3(-2,.14,5),Vector3(3,.14,4)]:
		if not await walk_to(target): return false
	await look_toward(TerritoryRules.QUARTERMASTER);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter._panel_text.text.begins_with("QUARTERMASTER"),"actual returned player physically reaches and faces the quartermaster's allowance conversation"): return false
	var allowance_dialog: Dictionary=chapter.model.snapshot()
	await frames(15)
	if not check(chapter.model.snapshot()==allowance_dialog and not chapter.model.has_economy(),"hearing the actual quartermaster alone grants no funds and freezes the whole Home clock"): return false
	if not await _dialog_click("Accept the limited household allowance"): return false
	var allowance: Dictionary=chapter.model.economy()
	if not check(chapter.model.has_economy() and allowance.events.is_empty() and TerritoryRules._equal(allowance.ledger,TerritoryRules.initial())
		and allowance.origin_tick>=household_task_persistence.inquiry_snapshot.aftermath.reported_tick,"actual allowance acceptance creates the single original120 household coins and separate18 personal coins after the observed report"): return false
	var allowance_hud: Dictionary=hud_observation()
	if not check(allowance_hud.compact_visible and allowance_hud.task=="Ask about the smith's commission" and not allowance_hud.legacy_visible
		and chapter._marker.visible and chapter._marker.global_position.is_equal_approx(TerritoryRules.QUARTERMASTER+Vector3.UP*2.1),
		"actual allowance acceptance keeps one compact unassigned commission task and the existing quartermaster marker"): return false
	if not _household_continuity("actual allowance acceptance"): return false
	note("household-allowance-earned");await capture("quartermaster-allowance","Actual allowance accepted after the complete earned inquiry; the original household ledger begins once")
	key(KEY_E);await frames(3)
	if not await _dialog_click("Commission two tool bundles"): return false
	var reserved: Dictionary=chapter.model.economy().ledger
	if not check(chapter.model.workshop_phase()=="fuel" and reserved.treasury==116 and reserved.purse==18 and reserved.stock.timber==6 and reserved.stock.tools==2
		and chapter.model.workshop().fuel_carried==2 and chapter.model.workshop().fee_held==4 and chapter.workplace.carried.visible
		and not chapter.workplace.carried.get_node("ToolHeads").visible and chapter.avatar.external_speed_limit==HouseholdCraft.CARRY_SPEED,
		"actual displayed commission reserves exactly two timber and four household coins with native carried fuel and the existing walking cap"): return false
	if not _household_continuity("actual first commission reservation"): return false
	if not _household_objective(HouseholdCraft.SITE,"Smith · E","carried fuel"): return false
	note("household-commission-earned");await capture("household-commission","Actual first smith commission and physically carried household fuel/payment")
	key(KEY_F5);await frames(3)
	var saved_authority=chapter.model.get_script().new()
	if not check(saved_authority.load_from(SAVE).is_empty(),"actual household F5 saves carried fuel through the production whole-Home authority"): return false
	var saved_snapshot: Dictionary=saved_authority.snapshot()
	var fuel_bytes:=FileAccess.get_file_as_bytes(SAVE)
	var retained_fuel:=FileAccess.open(OPENING_OUTPUT.path_join("household-fuel-save.json"),FileAccess.WRITE)
	if not check(retained_fuel!=null,"retain exact native carried-fuel save bytes for independent verification"): return false
	retained_fuel.store_buffer(fuel_bytes);retained_fuel.close()
	household_task_persistence.saved_snapshot=saved_snapshot;household_task_persistence.saved_tick=saved_snapshot.childhood.tick
	household_task_persistence.save_sha256=digest(fuel_bytes);household_task_persistence.saved_state_sha256=saved_authority.present_sha256()
	if not check(saved_authority.workshop_phase()=="fuel" and saved_snapshot.riding_skills.lesson_receipts==[learned_receipt]
		and saved_snapshot.misl.events.map(func(event): return event.kind)==["smith.reserve"],"carried-fuel native save retains its only earned reservation receipt and genuinely learned horsecraft"): return false
	note("household-fuel-native-save")
	if not await _walk_to_smith(): return false
	if not await _dialog_click("Hand over fuel and payment"): return false
	if not check(chapter.model.workshop_phase()=="working" and chapter.model.workshop().fuel_used==2 and chapter.model.workshop().fee_paid==4
		and not chapter.workplace.carried.visible and is_inf(chapter.avatar.external_speed_limit),"actual physical smith handover consumes the reserved fuel/payment once and releases the original player motor"): return false
	household_task_persistence.progressed_snapshot=chapter.model.snapshot()
	household_task_persistence.progressed_tick=chapter.model.progress().tick
	if not check(FileAccess.get_sha256(SAVE)==household_task_persistence.save_sha256,"actual later smith custody leaves the retained carried-fuel manual save unchanged"): return false
	if not _household_continuity("actual smith handover before rollback"): return false
	if not _household_objective(HouseholdCraft.SITE,"Smith · E","working smith order"): return false
	note("smith-handover-earned-before-reload");await capture("smith-handover","Actual physical smith handover before the carried-fuel native save is restored")
	if not await _native_household_reload_boundary(saved_snapshot): return false
	if not await _walk_to_smith(): return false
	if not await _dialog_click("Hand over fuel and payment"): return false
	var started: int=chapter.model.workshop().started_tick
	var deadline: int=started+HouseholdCraft.WORK_TICKS
	var work_journal: Array=chapter.model.journal()
	var work_hint: String=chapter.workshop_hint()
	if not check(chapter.model.workshop_phase()=="working" and chapter.model.economy().events.map(func(event): return event.kind)==["smith.reserve","smith.start"],
		"replayed physical handover leaves one reservation and one smith custody receipt after the whole-state rollback"): return false
	while chapter.model.progress().tick<deadline-1: await frames(1)
	if not check(chapter.model.progress().tick==deadline-1 and chapter.model.workshop_phase()=="working","the original smith clock cannot produce output before its600th active tick"): return false
	await frames(1)
	if not check(chapter.model.workshop_phase()=="ready" and chapter.model.workshop().ready_tick==deadline and chapter.workplace.finished.visible
		and chapter.model.economy().ledger.stock.tools==2 and chapter.model.journal()==work_journal and chapter.workshop_hint()==work_hint,
		"the existing600-tick deadline creates bench tools once without premature household stock or remotely delivered knowledge"): return false
	await look_toward(HouseholdCraft.SITE);key(KEY_E);await frames(3)
	if not await _dialog_click("Collect both tool bundles"): return false
	if not check(chapter.model.workshop_phase()=="tools" and chapter.model.workshop().tools_carried==2 and chapter.workplace.carried.visible
		and chapter.workplace.carried.get_node("ToolHeads").visible and not chapter.workplace.finished.visible and chapter.avatar.external_speed_limit==HouseholdCraft.CARRY_SPEED,
		"actual local smith collection transfers two tools to the existing player with the original loaded walking cap"): return false
	if not _household_continuity("actual smith tool collection"): return false
	if not _household_objective(TerritoryRules.QUARTERMASTER,"Quartermaster · E","carried tools"): return false
	note("smith-tools-physically-collected");await capture("smith-collection","Actual local collection of completed tools; the player carries them before the household store receives them")
	for target in [Vector3(-15,.14,1),Vector3(3,.14,1),Vector3(3,.14,4)]:
		if not await walk_to(target): return false
	await look_toward(TerritoryRules.QUARTERMASTER);key(KEY_E);await frames(3)
	if not await _dialog_click("Return both tool bundles to household stock"): return false
	var settled: Dictionary=chapter.model.economy()
	if not check(chapter.model.workshop_phase()=="complete" and settled.ledger.treasury==116 and settled.ledger.purse==18 and settled.ledger.stock.timber==6
		and settled.ledger.stock.tools==4 and settled.ledger.favor==53 and chapter.model.workshop().tools_carried==0
		and not chapter.workplace.carried.visible and is_inf(chapter.avatar.external_speed_limit),"physical household return settles exactly two tools and three standing once without personal payout or duplicate costs"): return false
	if not check(settled.events.map(func(event): return event.kind)==["smith.reserve","smith.start","smith.ready","smith.collect","smith.deliver"]
		and chapter.model.journal().filter(func(memory): return memory.id.begins_with("workshop_")).map(func(memory): return memory.id)==["workshop_reserve","workshop_start","workshop_collect","workshop_deliver"],
		"complete first responsibility has exactly five causal receipts and four locally heard custody accounts"): return false
	if not _household_continuity("actual completed first responsibility"): return false
	key(KEY_F5);await frames(3)
	var final_authority=chapter.model.get_script().new()
	if not check(final_authority.load_from(SAVE).is_empty() and final_authority.workshop_phase()=="complete", "final actual F5 saves the complete first household responsibility through the original whole-Home authority"): return false
	var saved_final: Dictionary=final_authority.snapshot()
	final_manual_save={"file":SAVE,"sha256":FileAccess.get_sha256(SAVE),"snapshot":saved_final,"state_sha256":final_authority.present_sha256()}
	if not check(TerritoryRules._equal(saved_final.misl,chapter.model.economy()) and saved_final.riding_skills.lesson_receipts==[learned_receipt]
		and _after_save_projection(saved_final.aftermath)==_after_save_projection(chapter.model.aftermath()),"completed first-responsibility native save preserves exact economy receipts, learned horsecraft and inquiry knowledge with only native guard precision reconciliation"): return false
	if not _household_continuity("actual final first-responsibility save"): return false
	if not check(hud_observation().compact_visible and hud_observation().task=="First household responsibility complete"
		and not hud_observation().legacy_visible,"actual first-responsibility completion keeps one compact settled-task handoff"): return false
	if not _household_objective(TerritoryRules.QUARTERMASTER,"Quartermaster · E","settled first responsibility"): return false
	household_task_persistence.final_task_completed=true
	household_task_persistence.final_snapshot=chapter.model.snapshot();household_task_persistence.final_tick=chapter.model.progress().tick
	household_task_persistence.final_native_body_ids=_household_native_ids()
	note("household-first-responsibility-complete");await capture("household-task-complete","Actual completed smith commission after physical return and final production F5 save")
	return check(captures.size()==23,"complete optional first responsibility retains the original eighteen and five new production-camera boundaries")

func _run() -> void:
	if not _configure_inquiry_choice(): quit(2);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OPENING_OUTPUT))
	if not await _beginning(): await finish();return
	if not await _learn_horsecraft(): await finish();return
	if not await _course_and_practice(): await finish();return
	if not await _track_and_return(): await finish();return
	if not await _household_inquiry(): await finish();return
	if household_task=="smith-commission" and not await _first_household_responsibility(): await finish();return
	await finish()
