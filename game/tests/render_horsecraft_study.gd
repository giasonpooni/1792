extends SceneTree
## Native rendered evidence of actual input-driven horsecraft; inspection views are labeled.
const Study:=preload("res://mounts/horsecraft_study.tscn")
const State:=preload("res://mounts/horsecraft_state.gd")
const OUTPUT:="user://horsecraft-study-images"
var scene: Node3D
var inspection: Camera3D
var captures: Array[Dictionary]=[]
var failures:=0
var started_ms: int=0

func _initialize() -> void:
	started_ms=Time.get_ticks_msec()
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if not value:
		failures+=1
		push_error("HORSECRAFT RENDER: "+message)

func frames(count: int) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0.0,brake: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if brake: Input.action_press("move_backward")

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;scene._unhandled_input(event)

func click() -> void:
	var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=MOUSE_BUTTON_LEFT;scene._unhandled_input(event)

func digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()

func capture_progress(id: String,boundary: String) -> void:
	print("HORSECRAFT_CAPTURE: %s %s tick=%d native_physics_frame=%d elapsed_wall_ms=%d"%
		[id,boundary,scene.model.snapshot().tick,Engine.get_physics_frames(),Time.get_ticks_msec()-started_ms])

func capture(id: String,purpose: String,offset: Vector3=Vector3(8,4.6,7.0)) -> void:
	capture_progress(id,"start")
	scene.set_paused(true)
	var before: Dictionary=scene.model.snapshot()
	var left_pose: Transform3D=scene.left.global_transform
	var right_pose: Transform3D=scene.right.global_transform
	var middle: Vector3=(scene.left.global_position+scene.right.global_position)*.5
	var target:=middle+Vector3.UP*1.9
	inspection.global_position=middle+offset;inspection.fov=48.0;inspection.look_at(target,Vector3.UP);inspection.current=true
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(not image.is_empty(),"native frame exists "+id)
	check(image.get_width()==1280 and image.get_height()==720,"1280x720 viewport "+id)
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	var path:=OUTPUT.path_join(id+".png")
	check(image.save_png(path)==OK,"PNG retained "+id)
	var frozen: bool=scene.model.snapshot()==before and scene.left.global_transform==left_pose and scene.right.global_transform==right_pose
	check(frozen,"render pause freezes both bodies and study state "+id)
	captures.append({"id":id,"purpose":purpose,"file":id+".png","sha256":FileAccess.get_sha256(path),
		"pixel_sha256":digest(image.get_data()),"pixel_format":"rgba8","width":image.get_width(),"height":image.get_height(),
		"tick":before.tick,"stance":before.stance,"stage":before.stage,"slots":before.slots,"selected_slot":before.selected_slot,
		"reload_ticks":before.reload_ticks,"accepted_shots":before.shots.size(),"acknowledged_hits":before.hits.size(),
		"observation_count":scene.observations.size(),"pair_observation":scene.observation(),
		"frozen_state":frozen,"state_sha256":digest(JSON.stringify(before,"",true,true).to_utf8_buffer()),
		"camera_position":[inspection.global_position.x,inspection.global_position.y,inspection.global_position.z],
		"target":[target.x,target.y,target.z],"fov":inspection.fov,"camera_kind":"explicit-mechanics-inspection",
		"gameplay_camera":false,"motion_source":"shared horse motors with actual game input actions","campaign_admission":false})
	capture_progress(id,"end")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	scene=Study.instantiate();root.add_child(scene);await frames(5)
	inspection=Camera3D.new();inspection.name="HorsecraftInspectionCamera";inspection.far=160;scene.add_child(inspection)
	check(scene.observation().safe,"initial independent horses settle on native floor")
	await capture("seated-pair","Two independent existing horse bodies and one seated rider")
	scene.set_paused(false);controls(1.0);await frames(35);key(KEY_SPACE)
	await frames(State.RISE_TICKS+State.STAND_OBJECTIVE_TICKS+5)
	check(scene.model.stance()=="standing" and scene.model.snapshot().stage=="volley","actual straight ride achieves stable standing objective")
	await capture("standing-pair","Single standing rider supported by two independently moving horses",Vector3(7.3,4.1,6.5))
	scene.set_paused(false)
	for slot in range(4): key(KEY_1+slot);click()
	check(scene.model.snapshot().slots==[false,false,false,false] and scene.shot_observations.size()==4,"four distinct accepted charges are spent")
	await capture("four-spent","Four separate spent matchlocks; native shot presentation and charge HUD",Vector3(6.5,4.5,7.0))
	scene.set_paused(false);controls(0,true);await frames(45);key(KEY_R);await frames(60)
	check(scene.model.snapshot().reload_slot==3 and scene.model.snapshot().reload_ticks>0,"real stopped pair advances selected charge cycle")
	await capture("slow-reload","Stopped aligned horses retain standing support while one selected charge advances")
	scene.set_paused(false);controls();await frames(State.RELOAD_TICKS)
	check(scene.model.snapshot().slots==[false,false,false,true] and scene.model.snapshot().stage=="reload","first charge cycle cannot finish four-weapon reload objective")
	for slot in range(3):
		key(KEY_1+slot);key(KEY_R);await frames(State.RELOAD_TICKS+1)
	key(KEY_SPACE);await frames(State.RECOVER_TICKS+5)
	check(scene.model.stance()=="seated" and scene.model.snapshot().stage=="complete","real settling completes local study")
	check(scene.model.snapshot().slots==[true,true,true,true],"four separate completed cycles restore four individual charges")
	await capture("study-complete","Seated stopped pair and completed isolated objective",Vector3(7.5,4.6,6.5))
	check(captures.size()==5,"five native inspection captures")
	for i in range(captures.size()):
		for j in range(i): check(captures[i].pixel_sha256!=captures[j].pixel_sha256,"distinct native images "+captures[i].id+" / "+captures[j].id)
	var manifest:={"schema":"1792.horsecraft-study-render.v1","captures":captures,"failures":failures,
		"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),"physics_hz":Engine.physics_ticks_per_second,
		"inspection_camera_only":true,"historical_status":"user-attributed-unverified","historical_authentication":false,
		"campaign_admission":false,"human_playtest":false,"shot_observations":scene.shot_observations}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"manifest retained")
	if file:
		file.store_string(JSON.stringify(manifest,"\t",true,true));file.close()
	controls();scene.queue_free();scene=null;inspection=null;await process_frame
	print("HORSECRAFT_RENDER: %d captures; %d failures"%[captures.size(),failures])
	quit(1 if failures else 0)
