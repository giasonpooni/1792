extends SceneTree
## Native input-driven riding lesson and retained Home; cameras are inspection views.
const Launch:=preload("res://childhood/home_launch.gd")
const Native:=preload("res://tests/test_riding_training.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const State:=preload("res://mounts/horsecraft_state.gd")
const OUTPUT:="user://riding-training-images"
var home: Node3D
var chapter: Node3D
var session: Node
var lesson: Node3D
var inspection: Camera3D
var captures: Array[Dictionary]=[]
var failures:=0
var retained_sha: String
var art_id: int

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if not value:
		failures+=1;push_error("RIDING TRAINING RENDER: "+message)

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0.0,brake: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if brake: Input.action_press("move_backward")

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;session._input(event)

func click() -> void:
	var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=MOUSE_BUTTON_LEFT;session._input(event)

func digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()

func vector(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func observable(value: Variant) -> Variant:
	if value is Vector3: return vector(value)
	if value is Dictionary:
		var result: Dictionary={}
		for key in value: result[key]=observable(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for item in value: result.append(observable(item))
		return result
	return value

func label(parent: Node) -> void:
	var layer:=CanvasLayer.new();layer.layer=90;parent.add_child(layer)
	var caption:=Label.new();caption.position=Vector2(16,467);caption.text="INSPECTION CAMERA · input-driven engine scene"
	caption.add_theme_font_size_override("font_size",15)
	caption.add_theme_color_override("font_color",Color("e9d1a2"));layer.add_child(caption)

func retain(image: Image,id: String) -> Dictionary:
	check(not image.is_empty(),"native frame exists "+id)
	check(image.get_width()==1280 and image.get_height()==720,"1280x720 viewport "+id)
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	var path:=OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"PNG retained "+id)
	return {"id":id,"file":id+".png","sha256":FileAccess.get_sha256(path),
		"pixel_sha256":digest(image.get_data()),"pixel_format":"rgba8","width":image.get_width(),"height":image.get_height(),
		"camera_kind":"explicit-mechanics-inspection","inspection_camera_only":true,"gameplay_camera":false,
		"motion_source":"native shared horse motors with game actions and session viewport input router"}

func capture_lesson(id: String,purpose: String,offset: Vector3=Vector3(6.0,3.6,5.0),focus_height: float=1.9) -> void:
	lesson.set_paused(true)
	var before: Dictionary=lesson.model.snapshot()
	var before_tick: int=lesson.lesson_tick
	var left_pose: Transform3D=lesson.left.global_transform
	var right_pose: Transform3D=lesson.right.global_transform
	var rider_pose: Dictionary=lesson.rider.pose_observation()
	var middle: Vector3=lesson.left.global_position if lesson.lesson_phase=="single" else (lesson.left.global_position+lesson.right.global_position)*.5
	var target:=middle+Vector3.UP*focus_height
	inspection.global_position=middle+offset;inspection.fov=48.0;inspection.look_at(target,Vector3.UP);inspection.current=true
	session.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var capture:=retain(session.viewport.get_texture().get_image(),id)
	var frozen: bool=lesson.model.snapshot()==before and lesson.lesson_tick==before_tick and lesson.left.global_transform==left_pose and lesson.right.global_transform==right_pose
	check(frozen,"capture pause freezes local state and independent bodies "+id)
	check(lesson.rider.pose_observation()==rider_pose,"inspection preserves sampled hand, weapon and foot presentation "+id)
	check(chapter.model.present_sha256()==retained_sha and home.is_inside_tree() and chapter.art.get_instance_id()==art_id,"capture retains exact Home authority and art "+id)
	capture.merge({"purpose":purpose,"lesson_phase":lesson.lesson_phase,"lesson_tick":before_tick,"state_tick":before.tick,
		"stance":before.stance,"slots":before.slots,"reload_ticks":before.reload_ticks,"selected_slot":before.selected_slot,
		"accepted_shots":before.shots.size(),"support":lesson.observation(),"single_hold_ticks":lesson.max_single_hold_ticks,
		"paired_hold_ticks":lesson.max_paired_hold_ticks,"frozen_state":frozen,"separate_world_3d":session.viewport.own_world_3d,
		"state_sha256":digest(JSON.stringify(before,"",true,true).to_utf8_buffer()),"retained_home_sha256":retained_sha,
		"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==art_id,
		"capabilities_admitted":false,"camera_position":vector(inspection.global_position),"target":vector(target),"fov":inspection.fov})
	capture.merge({"rider_pose":observable(rider_pose),"reins":observable(lesson.rider.rein_observation()),
		"weapons":observable(lesson.rider.weapon_observation()),"procedural_presentation_only":true})
	captures.append(capture)
	session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

func capture_home_standing() -> void:
	root.disable_3d=true
	home.process_mode=Node.PROCESS_MODE_INHERIT
	var mount:=InputEventKey.new();mount.keycode=KEY_F;mount.pressed=true;chapter._unhandled_input(mount)
	await frames(3)
	check(chapter.model.mounted(),"learned rider remounts the actual household horse")
	for _i in range(30):
		if chapter._horse_support().safe: break
		await frames(1)
	# Leave the stable seated through actual motor input before standing.
	controls(1);await frames(85);controls(0,true);await frames(45);controls()
	var stand:=InputEventKey.new();stand.keycode=KEY_X;stand.pressed=true;chapter._unhandled_input(stand)
	await frames(50)
	check(chapter.single_stance()=="standing","learned X input stands on the observed Home horse")
	home.process_mode=Node.PROCESS_MODE_DISABLED
	var before: Dictionary=chapter.model.snapshot()
	var horse_pose: Transform3D=chapter.horse.global_transform
	var rider_pose: Dictionary=chapter._riding_visual.pose_observation()
	var target: Vector3=chapter.horse.global_position+Vector3.UP*2.2
	# Inspect from the open courtyard below the existing stable canopy.
	inspection.global_position=target+Vector3(-4.6,.55,2.8);inspection.fov=48;inspection.look_at(target,Vector3.UP)
	var prior_hud_visible: bool=chapter._hud.visible;chapter._hud.hide()
	var prior_compact_visible: bool=chapter.art.detail.hud.visible;chapter.art.detail.hud.hide()
	root.disable_3d=false
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var capture:=retain(root.get_texture().get_image(),"home-standing")
	chapter._hud.visible=prior_hud_visible
	chapter.art.detail.hud.visible=prior_compact_visible
	var frozen: bool=chapter.model.snapshot()==before and chapter.horse.global_transform==horse_pose and chapter._riding_visual.pose_observation()==rider_pose
	check(frozen,"Home standing inspection freezes authority, horse and shared rig")
	check(not rider_pose.equipped,"Home shared rider has reins and no borrowed weapons")
	capture.merge({"purpose":"Learned standing on the actual Home horse with both hands on reins and no practice weapons",
		"home_tick":before.childhood.tick,"capabilities":chapter.model.capabilities(),"frozen_state":frozen,
		"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==art_id,
		"capabilities_admitted":true,"camera_position":vector(inspection.global_position),"target":vector(target),"fov":inspection.fov,
		"rider_pose":observable(rider_pose),"reins":observable(chapter._riding_visual.rein_observation()),
		"weapons":observable(chapter._riding_visual.weapon_observation()),"procedural_presentation_only":true,
		"home_hud_hidden_for_inspection":true,"seated_stable_departure_with_native_input":true})
	captures.append(capture)

func capture_return(receipt: Dictionary) -> void:
	home.process_mode=Node.PROCESS_MODE_DISABLED
	check(not root.disable_3d,"guarded return restores actual Home viewport rendering")
	var before: Dictionary=chapter.model.snapshot()
	var body_pose: Transform3D=chapter.avatar.global_transform
	inspection=Camera3D.new();inspection.name="RetainedHomeInspectionCamera";inspection.far=160;home.add_child(inspection)
	var target: Vector3=chapter.avatar.global_position+Vector3.UP*1.35
	inspection.global_position=target+Vector3(7,4.0,8.5);inspection.fov=55;inspection.look_at(target,Vector3.UP);inspection.current=true
	label(home)
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var capture:=retain(root.get_texture().get_image(),"returned-home")
	var frozen: bool=chapter.model.snapshot()==before and chapter.avatar.global_transform==body_pose
	check(frozen,"Home inspection capture preserves admitted authority and bodies")
	check(chapter.art.get_instance_id()==art_id and home.is_inside_tree(),"returned Home has original live art")
	capture.merge({"purpose":"Guarded return to the existing Home with all three learned capabilities and its retained art",
		"home_tick":before.childhood.tick,"capabilities":chapter.model.capabilities(),"receipt_count":before.riding_skills.lesson_receipts.size(),
		"receipt_completion_sha256":receipt.completion_sha256,"four_reloaded_slots":receipt.facts.reloaded_slots,
		"frozen_state":frozen,"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==art_id,
		"capabilities_admitted":true,"camera_position":vector(inspection.global_position),"target":vector(target),"fov":inspection.fov})
	captures.append(capture)

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	# Lesson draws only requested inspection frames; intervening motion is native physics.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	controls();home=Launch.make_world();root.add_child(home);current_scene=home
	chapter=home.get_node("ChildhoodChapter");chapter.save_path="user://riding-training-render-only.json";await frames(6)
	check(chapter.model.restore(Native.legacy_riding_seed()).is_empty(),"explicit legacy entry fixture restores")
	chapter._apply()
	var toward: Vector3=Skills.TRAINING_SITE-chapter.avatar.global_position
	chapter.avatar.pivot.rotation.y=atan2(-toward.x,-toward.z);chapter.avatar.pivot.rotation.x=0.0
	retained_sha=chapter.model.present_sha256();art_id=chapter.art.get_instance_id()
	check(chapter.open_riding_training().is_empty(),"bound training opens in retained Home")
	session=chapter.training_session;lesson=session.lesson
	check(root.disable_3d and not session.viewport.disable_3d,"production session hides Home drawing while its own world can render")
	session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;await frames(6)
	inspection=Camera3D.new();inspection.name="TrainingInspectionCamera";inspection.far=160;lesson.add_child(inspection);label(lesson)
	controls(1);await frames(35);key(KEY_SPACE);await frames(State.RISE_TICKS+60+4)
	check(lesson.model.stance()=="standing" and lesson.max_single_hold_ticks>=60,"input-driven single standing hold passes")
	await capture_lesson("single-standing","One active moving horse supports both rider feet; the second horse is disabled",Vector3(4.7,3.5,4.2))
	lesson.set_paused(false);key(KEY_ENTER);await frames(5)
	controls(1);await frames(35);key(KEY_SPACE);await frames(State.RISE_TICKS+60+4)
	check(lesson.model.stance()=="standing" and lesson.max_paired_hold_ticks>=60,"input-driven pair standing hold passes")
	await capture_lesson("paired-standing","Two independently moving horses support one standing rider")
	lesson.set_paused(false);key(KEY_ENTER);await frames(2)
	for slot in range(4): key(KEY_1+slot);click()
	check(lesson.model.snapshot().slots==[false,false,false,false] and lesson.shot_observations.size()==4,"four individually charged matchlocks are discharged")
	await capture_lesson("four-spent","Four distinct mounted weapons spent through the actual input router",Vector3(3.3,2.1,3.5),2.65)
	lesson.set_paused(false);controls(0,true);await frames(45);key(KEY_1);key(KEY_R);await frames(60)
	check(lesson.model.snapshot().reload_slot==0 and lesson.model.snapshot().reload_ticks>0,"selected exclusive reload cycle advances at a stopped gait")
	await capture_lesson("slow-reload","A stopped aligned pair supports an exclusive mounted reload cycle",Vector3(3.6,2.0,3.3),2.55)
	lesson.set_paused(false);controls();await frames(State.RELOAD_TICKS)
	check(lesson.model.snapshot().slots==[true,false,false,false],"first recharge cannot complete all four weapons")
	for slot in range(1,4): key(KEY_1+slot);key(KEY_R);await frames(State.RELOAD_TICKS+1)
	key(KEY_SPACE);await frames(State.RECOVER_TICKS+5)
	check(lesson.lesson_phase=="complete" and lesson.model.snapshot().slots==[true,true,true,true],"all four recharge cycles and safe seated recovery complete training")
	var receipt: Dictionary=lesson.completion_receipt()
	var shot_observations: Array=lesson.shot_observations.duplicate(true)
	check(not receipt.is_empty(),"real lesson produces bound completion receipt")
	controls();key(KEY_ENTER);await frames(3)
	check(chapter.model.capabilities()=={"single_standing":true,"paired_standing":true,"mounted_matchlock":true},"actual guarded return admits all three skills")
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and chapter.avatar.input_enabled,"disposed lesson preserves Home mouse capture and playable input")
	await capture_return(receipt)
	await capture_home_standing()
	check(captures.size()==6,"six native inspection captures")
	for i in range(captures.size()):
		for j in range(i): check(captures[i].pixel_sha256!=captures[j].pixel_sha256,"distinct native images "+captures[i].id+" / "+captures[j].id)
	var manifest:={"schema":"1792.riding-training-render.v1","captures":captures,"failures":failures,
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),"physics_hz":Engine.physics_ticks_per_second,
		"inspection_camera_only":true,"historical_status":"user-attributed-unverified","historical_authentication":false,
		"human_playtest":false,"entry_fixture":"explicit admitted legacy first-riding-gate state",
		"between_capture_3d_rendering_disabled":true,"retained_home_render_suppressed_in_training":true,
		"return_receipt":receipt,"shot_observations":shot_observations,"final_capabilities":chapter.model.capabilities()}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"manifest retained")
	if file: file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	controls();current_scene=null;home.queue_free();home=null;chapter=null;session=null;lesson=null;inspection=null;await process_frame
	print("RIDING_TRAINING_RENDER: %d captures; %d failures"%[captures.size(),failures]);quit(1 if failures else 0)
