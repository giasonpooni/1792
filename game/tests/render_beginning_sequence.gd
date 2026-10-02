extends SceneTree
## A true new-game beginning driven only by native mouse/key events and ordinary
## game actions. Route coordinates are automation targets, never character map
## knowledge, pose restoration or evidence of a human playtest.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const Stance:=preload("res://mounts/horsecraft_state.gd")
const OUTPUT:="user://beginning-sequence-images"
var home: Node3D
var chapter: Node3D
var session: Node
var lesson: Node3D
var captures: Array[Dictionary]=[]
var route: Array[Dictionary]=[]
var failures:=0
var checks:=0
var _binding_sha: String
var _initial_snapshot: Dictionary
var _art_id: int

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> bool:
	checks+=1
	if not value: failures+=1;push_error("BEGINNING SEQUENCE RENDER: "+message)
	return value

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0.0,steering: float=0.0,brake: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if steering<0: Input.action_press("move_left",absf(steering))
	if steering>0: Input.action_press("move_right",steering)
	if brake: Input.action_press("move_backward")

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	if is_instance_valid(session): session._input(event)
	else: root.push_input(event,true)

func mouse_motion(relative: Vector2) -> void:
	var event:=InputEventMouseMotion.new();event.relative=relative
	root.push_input(event,true)

func click_button(button: Button) -> void:
	var at: Vector2=button.get_global_rect().get_center()
	for pressed_flag in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed_flag
		event.position=at;event.global_position=at;root.push_input(event,true)

func point(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func observable(value: Variant) -> Variant:
	if value is Vector3: return point(value)
	if value is Vector2: return [value.x,value.y]
	if value is Dictionary:
		var result: Dictionary={}
		for field in value: result[field]=observable(value[field])
		return result
	if value is Array:
		var result: Array=[]
		for item in value: result.append(observable(item))
		return result
	return value

func digest(bytes: PackedByteArray) -> String:
	var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(bytes)
	return hashing.finish().hex_encode()

func note(id: String) -> void:
	var progress: Dictionary=chapter.model.progress()
	route.append({"id":id,"home_tick":progress.tick,"home_stage":chapter.model.stage(),"position":point(chapter.avatar.global_position),
		"mounted":chapter.model.mounted(),"walked":progress.walked,"looked":progress.looked,"ride_gate":progress.ride_gate,
		"letter_seen":progress.letter_seen,"heard":progress.heard,"state_sha256":chapter.model.present_sha256(),"message":chapter._message})
	print("BEGINNING ROUTE: ",id," tick=",progress.tick," stage=",chapter.model.stage()," at=",chapter.avatar.global_position)

func hud_observation() -> Dictionary:
	var compact: Node=chapter.art.detail.hud
	return {"compact_visible":compact.visible,"title":compact.title.text,"task":compact.task.text,"words":compact.words.text,
		"progress":compact.narrator.text,"controls":compact.controls.text,"legacy_visible":chapter._hud.is_visible_in_tree(),"legacy_text":chapter._hud.text,
		"dialogue_visible":chapter._panel.is_visible_in_tree(),"dialogue_text":chapter._panel_text.text}

func capture(id: String,purpose: String,visit: Node=null) -> void:
	controls()
	var viewport: Viewport=root
	var prior_process_mode: int=home.process_mode
	var before: Dictionary=chapter.model.snapshot()
	var body_transform: Transform3D=chapter.avatar.global_transform
	var horse_transform: Transform3D=chapter.horse.global_transform
	var prior_disable: bool=root.disable_3d
	var local_snapshot: Dictionary={}
	var story_presentation: Dictionary={}
	var prior_paused:=false
	if visit!=null:
		viewport=session.viewport
		if visit.has_method("presentation_snapshot"):
			for _i in range(30):
				if visit.presentation_snapshot().get("settled",false): break
				await process_frame
			story_presentation=visit.presentation_snapshot()
			check(story_presentation.get("settled",false),"production story presentation settles naturally before capture "+id)
		if visit.has_method("set_paused"):
			prior_paused=visit.paused;visit.set_paused(true);local_snapshot=visit.model.snapshot()
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	else:
		home.process_mode=Node.PROCESS_MODE_DISABLED;root.disable_3d=false
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera3D=viewport.get_camera_3d()
	var image:=viewport.get_texture().get_image()
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"native1280x720 frame "+id)
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	var path:=OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"retain native gameplay-camera frame "+id)
	check(chapter.model.snapshot()==before and chapter.avatar.global_transform==body_transform and chapter.horse.global_transform==horse_transform,"capture preserves Home authority and both physical bodies "+id)
	var record:={"id":id,"file":id+".png","purpose":purpose,"sha256":FileAccess.get_sha256(path),"pixel_sha256":digest(image.get_data()),
		"width":image.get_width(),"height":image.get_height(),"pixel_format":"rgba8","camera_kind":"production-gameplay",
		"inspection_camera_only":false,"camera_pose_injected":false,"camera_position":point(camera.global_position),
		"camera_rotation":point(camera.global_rotation),"fov":camera.fov,"state_sha256":chapter.model.present_sha256(),
		"home_tick":before.childhood.tick,"home_stage":chapter.model.stage(),"riding_gate":before.childhood.ride_gate,
		"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==_art_id,
		"hud":hud_observation(),"capabilities":chapter.model.capabilities(),"capture_execution_paused":true}
	if visit!=null:
		record["separate_world_3d"]=viewport.own_world_3d
		if visit.has_method("story_beats"):
			record["story_beat"]=visit.current_beat;record["story_beat_id"]=visit.story_beats()[visit.current_beat].id
			if visit.has_method("presentation_snapshot"):
				check(visit.presentation_snapshot()==story_presentation,"settled production story presentation remains unchanged across captured frames "+id)
				record["story_presentation"]=story_presentation
		elif visit.has_method("rider_support_points"):
			check(visit.model.snapshot()==local_snapshot,"capture preserves local lesson reducer "+id)
			record["lesson_phase"]=visit.lesson_phase;record["single_hold_ticks"]=visit.max_single_hold_ticks
			record["rider_pose"]=observable(visit.rider.pose_observation());record["support"]=visit.observation()
			visit.set_paused(prior_paused)
		viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	else:
		home.process_mode=prior_process_mode;root.disable_3d=prior_disable
	captures.append(record)

func look_toward(target: Vector3) -> void:
	var offset: Vector3=target-chapter.avatar.global_position
	var desired: float=atan2(-offset.x,-offset.z)
	var turn: float=wrapf(desired-chapter.avatar.pivot.rotation.y,-PI,PI)
	mouse_motion(Vector2(-turn/chapter.avatar.mouse_sensitivity,0))
	await process_frame
	check(absf(wrapf(chapter.avatar.pivot.rotation.y-desired,-PI,PI))<.01,"native mouse look faces the actual route target")

func walk_to(target: Vector3,radius: float=.45) -> bool:
	controls();await look_toward(target)
	var best: float=Base.distance(chapter.avatar.global_position,target)
	var stalled:=0
	for _i in range(600):
		var distance: float=Base.distance(chapter.avatar.global_position,target)
		if distance<=radius:
			controls();await frames(16)
			return check(Base.distance(chapter.avatar.global_position,target)<radius+1.0,"actual walking reaches %s"%target)
		if distance<best-.03: best=distance;stalled=0
		else: stalled+=1
		if stalled>=100:
			controls();note("blocked-walking")
			return check(false,"actual walking stalls at %s toward %s; %s"%[chapter.avatar.global_position,target,chapter._message])
		controls(1);await frames(1)
	controls();note("walk-timeout")
	return check(false,"ordinary input never reaches target %s"%target)

func finish() -> void:
	var manifest:={"schema":"1792.beginning-sequence-render.v1","captures":captures,"route":route,"failures":failures,"checks":checks,
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
		"physics_hz":Engine.physics_ticks_per_second,"entry":"actual HomeLaunch.enter","entry_state_sha256":_binding_sha,"human_playtest":false,
		"input_source":"native mouse/key events, real scene dialog controls and ordinary game actions","progress_seeded":false,
		"capability_receipt_seeded":false,"saved_pose_restored":false,"camera_pose_injected":false,
		"between_capture_3d_rendering_disabled":true,"historical_authentication":false}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"retain beginning sequence manifest")
	manifest.checks=checks;manifest.failures=failures
	if file: file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	controls();current_scene=null
	if is_instance_valid(home): home.queue_free()
	home=null;chapter=null;session=null;lesson=null;await process_frame
	print("BEGINNING_SEQUENCE_RENDER: %d captures; %d checks; %d failures"%[captures.size(),checks,failures]);quit(1 if failures else 0)

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	controls();Launch.enter(self);home=current_scene;chapter=home.get_node("ChildhoodChapter")
	_art_id=chapter.art.get_instance_id();_initial_snapshot=chapter.model.snapshot()
	await process_frame;await process_frame
	session=chapter.intro_session
	if not check(is_instance_valid(session),"true production launch opens the family introduction"): await finish();return
	lesson=session.lesson;session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	_binding_sha=session.present_sha256
	await capture("family-opening","Production family opening before any childhood progress",lesson)
	for _i in range(lesson.story_beats().size()-1): key(KEY_ENTER);await process_frame
	await capture("family-final","Final family narration page before guarded Home return",lesson)
	var returned: Dictionary={}
	session.tree_exiting.connect(func(): returned.snapshot=chapter.model.snapshot())
	key(KEY_ENTER);await process_frame;await process_frame
	if not check(returned.get("snapshot")==_initial_snapshot,"completed introduction returns an unchanged new-game authority"): await finish();return
	session=null;lesson=null;root.disable_3d=true
	note("new-game-courtyard");await capture("courtyard-start","Actual Home walking camera and onboarding at the start")
	# Two opposite ordinary mouse movements practise viewing without leaving a
	# synthetic camera pose. All subsequent facing also uses the existing player.
	mouse_motion(Vector2(160,0));mouse_motion(Vector2(-160,0))
	if not await walk_to(Vector3(-4.8,.14,1.0)): await finish();return
	if not await walk_to(Vector3(-5.2,.14,2.0)): await finish();return
	if not check(chapter.model.stage()=="letter","actual walking and mouse looking complete orientation"): await finish();return
	note("orientation-earned");await capture("orientation-complete","Ordinary walking and viewing earn the first lesson transition")
	await look_toward(Base.SITES.courier);key(KEY_E);await frames(3);key(KEY_E);await frames(3)
	if not check(chapter.model.progress().letter_seen and "courier" in chapter.model.progress().heard,"actual courier interaction collects the note and hears his account"): await finish();return
	note("courier-account");await capture("courier-account","Actual courier interaction and remembered oral account")
	if not await walk_to(Vector3(-10.6,.14,4.0)): await finish();return
	await look_toward(Base.SITES.steward);key(KEY_E);await frames(3)
	if not check(chapter.model.stage()=="riding" and chapter.model.progress().heard.size()==2,"actual steward interaction opens the original riding lesson"): await finish();return
	note("steward-account");await capture("riding-unlocked","Two actually heard accounts open ordinary riding")
	for waypoint in [Vector3(-8,.14,-.7),Vector3(4,.14,-2.5),Vector3(6.8,.14,-4.0)]:
		if not await walk_to(waypoint): await finish();return
	await look_toward(chapter.horse.global_position);key(KEY_F);await frames(5)
	if not check(chapter.model.mounted(),"actual F mounts the existing household horse"): await finish();return
	note("household-mounted");await capture("first-mount","Actual shared Home riding camera on the existing household horse")
	controls(1)
	for _i in range(300):
		if chapter.model.progress().ride_gate>=1: break
		await frames(1)
	controls(0,0,true);await frames(45)
	if not check(chapter.model.progress().ride_gate==1 and chapter.horse.speed<=.15,"actual W crosses only the first original gate then S stops"): await finish();return
	note("first-riding-gate");await capture("first-riding-gate","First gate earned through the unmodified native horse motor")
	key(KEY_F);await frames(5)
	if not check(not chapter.model.mounted(),"actual F dismounts on native clear ground"): await finish();return
	if not await walk_to(Vector3(7.4,.14,-4.4)): await finish();return
	await look_toward(Skills.TRAINING_SITE);key(KEY_E);await frames(3)
	if not check(chapter._paused and chapter._panel_text.text.begins_with("RIDING LESSON"),"actual E opens the trainer's remembered-feat choice"): await finish();return
	note("trainer-dialogue");await capture("trainer-choice","Actual trainer dialogue reached from unseeded first-gate progress")
	click_button(chapter._actions.get_child(0));await frames(3)
	session=chapter.training_session
	if not check(is_instance_valid(session),"actual scene dialog enters bound riding training"): await finish();return
	lesson=session.lesson;session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	var frozen_home: Dictionary=chapter.model.snapshot()
	controls(1);await frames(35);key(KEY_SPACE);await frames(Stance.RISE_TICKS+60+5);controls()
	if not check(lesson.single_standing_ticks>=60 and lesson.model.stance()=="standing" and lesson.lesson_phase=="single","ordinary W and Space earn the first one-horse standing hold"): await finish();return
	check(chapter.model.snapshot()==frozen_home and chapter.art.get_instance_id()==_art_id,"first training exercise freezes its actually earned Home and retains original art")
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false},"first balance exercise alone grants no advanced skills")
	await capture("first-standing-exercise","First single-horse standing exercise reached from the true new-game sequence",lesson)
	key(KEY_F1);await process_frame;await process_frame;session=null;lesson=null
	check(chapter.model.progress().ride_gate==1 and chapter.model.snapshot().riding_skills.lesson_receipts.is_empty(),"canceled first exercise retains genuine first-gate progress without a forged skill receipt")
	note("returned-from-first-exercise");await capture("returned-courtyard","Original Home retained after actually reaching and trying the first standing lesson")
	check(chapter.model.journal().map(func(memory): return memory.id)==["letter","courier","steward"],"only actually collected and heard beginning memories are present")
	await finish()
