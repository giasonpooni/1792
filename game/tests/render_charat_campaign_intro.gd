extends SceneTree
## Frames of the actual opening camera/UI and its guarded return to the retained Home.
const Launch:=preload("res://childhood/home_launch.gd")
const OUTPUT:="user://charat-intro-images"
var home: Node3D
var chapter: Node3D
var session: Node
var story: Node3D
var captures: Array[Dictionary]=[]
var failures:=0
var binding: String
var art_id: int
var returned_sha: String

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if not value: failures+=1;push_error("CHARAT INTRO RENDER: "+message)

func frames(count: int=3) -> void:
	for _i in range(count): await process_frame

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;session._input(event)

func vector(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	return hash.finish().hex_encode()

func retain(image: Image,id: String) -> Dictionary:
	check(not image.is_empty() and image.get_size()==Vector2i(1280,720),"native opening frame "+id)
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	var path:=OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"frame retained "+id)
	return {"id":id,"file":id+".png","sha256":FileAccess.get_sha256(path),
		"pixel_sha256":digest(image.get_data()),"pixel_format":"rgba8",
		"width":1280,"height":720,"human_playtest":false}

func capture_story(id: String) -> void:
	# Observe the end of the ordinary production page transition before freezing
	# the camera/pose evidence; no inspection camera or forced pose is substituted.
	for _i in range(30):
		if story.presentation_snapshot().settled: break
		await process_frame
	check(story.presentation_snapshot().settled,"production story transition settles before "+id)
	var beat: Dictionary=story.story_beats()[story.current_beat]
	var camera: Camera3D=story.get_node("StoryCamera")
	var camera_pose: Transform3D=camera.global_transform
	var father: Node3D=story.get_node("MahaSingh")
	var child: Node3D=story.get_node("YoungBuddhSingh")
	session.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	await frames();await RenderingServer.frame_post_draw
	var capture:=retain(session.viewport.get_texture().get_image(),id)
	var frozen: bool=chapter.model.present_sha256()==binding and camera.global_transform==camera_pose
	check(frozen,"story image keeps original Home binding and authored camera "+id)
	check(chapter.art.get_instance_id()==art_id and home.is_inside_tree(),"story image retains Home art "+id)
	capture.merge({"beat_id":beat.id,"beat_index":story.current_beat,"beat_count":story.story_beats().size(),
		"dialogue_sha256":beat.dialogue.sha256_text(),"period_caption":beat.period,
		"camera_kind":"production-story-camera","production_story_camera":true,"inspection_camera_only":false,
		"camera_position":vector(camera.global_position),"camera_target_offset":camera.v_offset,"fov":camera.fov,
		"narrator_id":father.get_meta("actor_id"),"listener_id":child.get_meta("actor_id"),"campaign_subject_id":"charat_singh",
		"child_scale":vector(child.scale),"present_sha256":binding,"frozen_state":frozen,
		"separate_world_3d":session.viewport.own_world_3d,"home_in_tree":home.is_inside_tree(),
		"home_art_instance_retained":chapter.art.get_instance_id()==art_id,"dialogue_status":"original-authored-dialogue"})
	capture["presentation"]=story.presentation_snapshot()
	captures.append(capture)
	session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	Launch.enter(self, false);home=current_scene;chapter=home.get_node("ChildhoodChapter")
	await frames(3)
	check(is_instance_valid(chapter.intro_session),"explicit family-only entry opens the family story")
	if not is_instance_valid(chapter.intro_session): home.queue_free();quit(1);return
	session=chapter.intro_session;story=session.lesson;binding=session.present_sha256;art_id=chapter.art.get_instance_id()
	check(root.disable_3d and session.viewport.own_world_3d,"production opening owns isolated rendering")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"story pointer buttons are available")
	await capture_story("father-and-child")
	while story.story_beats()[story.current_beat].id!="kup": key(KEY_RIGHT)
	await capture_story("kup-recollection")
	while story.current_beat<story.story_beats().size()-1: key(KEY_RIGHT)
	await capture_story("family-closing")
	check(story.can_complete(),"all original story beats permit guarded return")
	session.tree_exiting.connect(func():
		returned_sha=chapter.model.present_sha256())
	key(KEY_ENTER);await frames(3)
	check(returned_sha==binding,"complete opening returns the exact Home authority")
	check(not root.disable_3d and not is_instance_valid(chapter.intro_session),"return restores Home drawing and closes story")
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and chapter.avatar.input_enabled,"real display restores playable Home pointer and movement input")
	check(not chapter.model.has_riding_skill("single_standing"),"opening grants no riding skills")
	# Let the production SpringArm resolve against Home geometry after return.
	# The exact return authority was recorded at the lifecycle boundary above;
	# these ordinary resumed physics ticks are separately reported in the frame.
	for _i in range(6): await physics_frame
	home.process_mode=Node.PROCESS_MODE_DISABLED
	await frames(2)
	await RenderingServer.frame_post_draw
	var capture:=retain(root.get_texture().get_image(),"returned-home")
	capture.merge({"camera_kind":"production-home-camera","inspection_camera_only":false,
		"present_sha256":chapter.model.present_sha256(),"returned_boundary_sha256":returned_sha,
		"return_boundary_unchanged":returned_sha==binding,"resumed_home_tick":chapter.model.progress().tick,
		"capture_processing_paused":home.process_mode==Node.PROCESS_MODE_DISABLED,
		"home_in_tree":home.is_inside_tree(),"home_art_instance_retained":chapter.art.get_instance_id()==art_id,
		"capabilities":chapter.model.capabilities(),"opening_completed":chapter._intro_shown})
	captures.append(capture)
	check(captures.size()==4,"four native opening/return frames")
	var manifest:={"schema":"1792.charat-intro-render.v1","captures":captures,"failures":failures,
		"entry":"HomeLaunch.enter family-only qualification","engine":Engine.get_version_info().string,
		"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
		"historical_conversation_authenticated":false,"dialogue_status":"original-authored-dialogue",
		"campaigns_playable_reconstruction":false,"human_playtest":false,"returned_home_sha256":returned_sha}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"opening render manifest retained")
	if file: file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	current_scene=null;home.queue_free();home=null;chapter=null;session=null;story=null;await frames()
	print("CHARAT_INTRO_RENDER: %d captures; %d failures"%[captures.size(),failures]);quit(1 if failures else 0)
