extends SceneTree
## Actual production entry, action-driven traversal, and protected Home return.
const Launch:=preload("res://childhood/home_launch.gd")
const OUTPUT:="user://sobraon-opening-images"
var failures:=0
var checks:=0
var home: Node3D
var chapter: Node
var session: Node
var scene: Node
var initial: Dictionary
var initial_files: Dictionary
var home_pose: Transform3D
var home_horse_pose: Transform3D
var snapshots: Array[Dictionary]=[]
var captures: Array[Dictionary]=[]
var capture_enabled:=false
var binding:=""

func _initialize() -> void: run.call_deferred()
func check(condition: bool,detail: String) -> bool:
	checks+=1
	if not condition: failures+=1;printerr("FAIL: "+detail)
	return condition
func frames(count: int=2) -> void:
	for _i in range(count): await physics_frame
func controls(x: float=0,z: float=0) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if x<0: Input.action_press("move_left",-x)
	if x>0: Input.action_press("move_right",x)
	if z<0: Input.action_press("move_forward",-z)
	if z>0: Input.action_press("move_backward",z)
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		root.push_input(event,true)
func files() -> Dictionary:
	var result: Dictionary={}
	for path in ["user://1792-childhood-v1.json","user://1792-childhood-aftermath-v1.json","user://1792-gujranwala-v1.json","user://1792-companions-v1.json","user://1792-home-workshop-v2.json","user://1792-home-workshop-v2.json.checkpoint.json"]:
		result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return result
func frozen() -> void:
	check(chapter.model.snapshot()==initial and chapter.model.present_sha256()==binding,"outer-frame play preserves the exact childhood authority: phase=%s home_tick=%s entry_tick=%s"%[scene.phase if is_instance_valid(scene) else "family",chapter.model.progress().tick,initial.get("progress",{}).get("tick",-1)])
	check(files()==initial_files,"outer-frame play writes no campaign saves")
	check(home.process_mode==Node.PROCESS_MODE_DISABLED,"Home remains suspended throughout both later dates")
	check(chapter.avatar.global_transform==home_pose and chapter.horse.global_transform==home_horse_pose,"retained childhood bodies never follow the veteran's motion")
func walk(target: Vector3) -> bool:
	for _i in range(1800):
		var delta: Vector3=target-scene.avatar.position;delta.y=0
		if delta.length()<.36:
			controls();await frames(4);return true
		if scene.failed: controls();check(false,"route unexpectedly failed: "+scene._caption.text);return false
		var heading:=delta.normalized();controls(heading.x,heading.z);await physics_frame
	controls();check(false,"route could not reach "+str(target));return false
func capture(id: String) -> void:
	snapshots.append(scene.observation())
	if not capture_enabled: return
	controls();var mode: int=scene.process_mode;scene.process_mode=Node.PROCESS_MODE_DISABLED
	session.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	await frames(3);await RenderingServer.frame_post_draw
	var img: Image=session.viewport.get_texture().get_image()
	var path:=OUTPUT.path_join(id+".png")
	check(not img.is_empty() and img.save_png(path)==OK,"native image retained: "+id)
	captures.append({"file":id+".png","sha256":FileAccess.get_sha256(path),"phase":scene.phase,"camera":"production","state_sha256":chapter.model.present_sha256()})
	scene.process_mode=mode;session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
func launch() -> void:
	controls();Launch.enter(self);home=current_scene;chapter=home.get_node("ChildhoodChapter")
	initial=chapter.model.snapshot();binding=chapter.model.present_sha256();initial_files=files()
	home_pose=chapter.avatar.global_transform;home_horse_pose=chapter.horse.global_transform
	await frames(3);session=chapter.intro_session;scene=session.lesson
	session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	check(session.prologue_active and scene.phase=="escape","default production entry begins at Sobraon")
	check(scene.avatar.get_script().resource_path=="res://player/player.gd","veteran reuses the shared player motor")
	check(scene.get_world_3d()!=chapter.get_world_3d(),"outer frame stays in the retained session's isolated world")
func clean() -> void:
	controls();current_scene=null;home.queue_free();await frames(4)
	check(not root.disable_3d,"scene teardown restores parent viewport rendering")
func run() -> void:
	capture_enabled="--capture" in OS.get_cmdline_user_args()
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await launch();frozen()
	check(chapter.model.progress().tick==0,"production entry parks Home before its first simulation tick")
	key(KEY_F5);key(KEY_F9);await frames();frozen()
	check(not scene.can_complete() and not session.finish(true).is_empty(),"escape cannot grant an early completed return")
	key(KEY_E);await frames();check(scene.phase=="escape","interact from far away cannot board the wreckage")
	key(KEY_ESCAPE);await frames();var before: int=scene.tick;var position: Vector3=scene.avatar.position
	controls(0,-1);await frames(30);controls()
	check(scene.tick==before and scene.avatar.position==position,"pause freezes local movement and narrative time")
	key(KEY_ESCAPE);await frames(45)
	await capture("01-sobraon-earthworks")
	if not await walk(Vector3(3.8,0,3)): await finish();return
	key(KEY_E);await frames()
	check(scene.helped and scene._carry.visible and not scene.wounded.visible,"nearby action picks up the comrade")
	check(scene.avatar.external_speed_limit==2.3,"carrying constrains the original motor")
	await capture("02-helping-comrade")
	if not await walk(Vector3(1,0,-16.5)): await finish();return
	check(scene._bank_seen,"ordinary traversal reaches the river checkpoint")
	await capture("03-broken-crossing")
	# Walk into the actual unsupported river: this is not a seeded failure flag.
	if not await walk(Vector3(6,0,-16.5)): await finish();return
	controls(0,-1)
	for _i in range(260):
		await physics_frame
		if scene.failed: break
	controls();check(scene.failed and not scene.escaped,"river has no invisible walkable bridge or floor")
	key(KEY_R);await frames(5)
	check(not scene.failed and scene.retries==1 and scene.helped,"retry restores the bank and retained rescue choice")
	frozen();key(KEY_E);await frames(3)
	check(scene.phase=="crossing" and not scene.avatar.is_physics_processing(),"boarding hands movement to local wreckage transport")
	for _i in range(300):
		controls(clampf((1.0-scene.raft.position.x)*.8-.12/1.8,-.7,.7),-1);await physics_frame
	controls();await capture("04-crossing-the-sutlej")
	for _i in range(1100):
		if scene.phase!="crossing": break
		controls(clampf((1.0-scene.raft.position.x)*.8-.12/1.8,-.7,.7),-1);await physics_frame
	controls();await frames(95)
	if not check(scene.phase=="escaped" and scene.escaped,"steered crossing physically reaches the far bank: "+str(scene.raft.position)): await finish();return
	await capture("05-far-bank");frozen()
	key(KEY_E);await frames(5)
	check(scene.phase=="surrender" and "1849" in scene._title.text,"surrender is explicitly dated to 1849")
	check(scene.avatar.name=="SobraonVeteran" and scene.veteran.has_node("RecognizableSleeveRepair"),"the same survivor carries into the coda")
	key(KEY_E);await frames();check(scene.phase=="surrender","distant interaction cannot trigger the laying down of arms")
	if not await walk(scene.surrender.position+Vector3(0,0,4.5)): await finish();return
	key(KEY_E);await frames(220);await capture("06-laying-down-arms")
	await frames(240)
	check(scene.phase=="lament" and scene.drop_count==7,"seven soldiers visibly lay down their weapons before the lament")
	check(scene._caption.text==scene.LAMENT and scene._speaker.text=="An old Khalsa veteran","reported lament belongs to a veteran, not an invented Shah quotation")
	await capture("07-ranjit-singh-lament");frozen()
	await frames(125);key(KEY_E);await frames(65);key(KEY_E);await frames(100)
	check(scene.can_complete() and scene._caption.text==scene.HANDOFF,"both historical scenes reach the authored oral transition")
	await capture("08-shah-muhammad-handoff")
	key(KEY_E)
	for _i in range(150):
		await process_frame
		if not session.prologue_active: break
	if not check(not session.prologue_active,"complete sequence enters the existing family scene"): await finish();return
	check(session.prologue_record.completed and session.prologue_record.escaped,"session retains local completion evidence without campaign grants")
	check(session.lesson.oral_handoff and session.lesson._dialogue.text.begins_with("…he rode out"),"Maha Singh completes the sentence begun by Shah Muhammad")
	check(session.lesson.get_node("MahaSingh").get_meta("actor_id")=="mahan_singh","existing father identity is preserved")
	frozen()
	if capture_enabled:
		session.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;await frames(30);await RenderingServer.frame_post_draw
		var path:=OUTPUT.path_join("09-maha-singh-handoff.png");var img: Image=session.viewport.get_texture().get_image()
		check(img.save_png(path)==OK,"native family handoff retained")
		captures.append({"file":"09-maha-singh-handoff.png","sha256":FileAccess.get_sha256(path),"phase":"family","camera":"production","state_sha256":chapter.model.present_sha256()})
		session.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	var boundary: Dictionary={};session.tree_exiting.connect(func(): boundary.state=chapter.model.snapshot())
	for _i in range(session.lesson.story_beats().size()): key(KEY_ENTER);await process_frame
	await frames(3)
	check(boundary.get("state")==initial,"completed family telling restores the identical childhood state")
	check(chapter.intro_session==null and chapter.avatar.input_enabled,"full opening returns working childhood controls")
	check(not chapter.model.has_riding_skill("single_standing") and chapter.model.journal().is_empty(),"1846 and 1849 events grant no child knowledge or skills")
	await clean()
	# Explicit skip is a distinct route, never passed off as completed play.
	await launch();key(KEY_F2);await frames(4)
	check(not session.prologue_active and not session.prologue_record.completed,"F2 reaches family as an explicit skip")
	check(not session.lesson.oral_handoff,"a skipped battle does not claim an earned narration handoff")
	frozen();key(KEY_ESCAPE);await frames(4)
	check(chapter.intro_session==null and chapter.avatar.input_enabled,"skipping both presentations restores original Home")
	await clean();await finish()
func finish() -> void:
	controls()
	if is_instance_valid(home) and home.is_inside_tree(): await clean()
	var manifest:={"schema":"1792.sobraon-route-evidence.v1","entry":"actual HomeLaunch.enter",
		"route_kind":"action-driven route with explicit river failure and retry; no seeded progress or pose",
		"engine":Engine.get_version_info().string,"checks":checks,"failures":failures,"capture_enabled":capture_enabled,
		"captures":captures,"observations":snapshots,"narration_delivery":"captions and original procedural ambience; no voice recording",
		"human_playtest":false}
	var file:=FileAccess.open(OUTPUT.path_join("manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"  "));file.close()
	print("SOBRAON_PROLOGUE_TESTS: %d passed, %d failed"%[checks-failures,failures])
	quit(1 if failures else 0)
