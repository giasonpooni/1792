# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit whole-Home fixtures qualify native composition and local actions.
## Domain route suites establish mission travel; the riding journey separately
## establishes the completed lesson. This suite does not relabel fixtures as play.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const Oral:=preload("res://narrative/oral_memory/memory_rules.gd")
const Remounts:=preload("res://remounts/remount_rules.gd")
const Actions:=preload("res://presentation/household_action_priority.gd")
const SAVE:="user://rope-remount-integration-only.json"
var passed:=0
var failed:=0
var captures:=0
var home: Node3D
var scene: Node3D
var baseline: Dictionary

func _initialize() -> void: _run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("ROPE REMOUNT INTEGRATION: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(count: int=3) -> void:
	for i in range(count): await physics_frame
	await process_frame
func look(at: Vector3) -> void:
	var toward: Vector3=at-scene.avatar.global_position
	scene.avatar.pivot.rotation=Vector3(0,atan2(-toward.x,-toward.z),0)
func pose(at: Vector3,face: Vector3) -> void:
	ok(Pose.pose(scene.model,at),"declared integration pose fixture")
	scene._apply();scene._paused=false;scene.avatar.velocity=Vector3.ZERO;look(face)
	scene._refresh();scene.art.detail.hud.sample()
	await frames(3)
func press(action: String) -> bool:
	for button in scene._actions.get_children():
		if button is Button and Actions.action_id(button)==action:
			button.pressed.emit();scene._physics_process(1.0/60.0)
			await frames(2);return true
	check(false,"actual dialog offers "+action);return false
func receipt_fixture(model) -> Dictionary:
	# Synthetic domain fixture: validates retention, never claims physical work.
	var receipt:={"schema":Skills.RECEIPT_SCHEMA,"lesson_id":Skills.LESSON_ID,
		"subject_id":"ranjit_singh","flashback_actor_id":"mahan_singh",
		"present_sha256":model.present_sha256(),"completion_sha256":"",
		"entry_tick":model.progress().tick,"completed_tick":1200,
		"milestones":[{"id":"single_standing","tick":120},{"id":"paired_standing","tick":240},{"id":"mounted_matchlock","tick":241}],
		"historical_status":Skills.ATTRIBUTION,"facts":{"single_hold_ticks":60,"paired_hold_ticks":60,"volley_slots":[0,1,2,3],"reloaded_slots":[3,0,1,2]}}
	receipt.completion_sha256=Skills.proof_sha256(receipt);return receipt
func retained() -> Dictionary:
	return {"state":scene.model.snapshot(),"camera":scene.avatar.pivot.transform,"player":scene.avatar.global_transform,"horse":scene.horse.global_transform,
		"art":scene.art.get_instance_id(),"workplace":scene.workplace.get_instance_id()}
func capture(label: String,modal: bool=false,scroll_end: bool=false) -> void:
	# A presentation-only refresh can select changed frames without re-exporting
	# unrelated scenes. The ordinary native qualification leaves this unset.
	var selection:=OS.get_environment("ROPE_REMOUNT_CAPTURE_FILTER")
	if not selection.is_empty() and label not in selection.split(","): return
	var before:=retained()
	for size in [Vector2i(1280,720),Vector2i(800,450)]:
		root.size=size;scene._layout();scene.art.detail.hud.sample();await frames(3)
		if scroll_end:
			scene._journal_scroll.scroll_vertical=100000;await frames(2)
		scene.art.detail.hud.sample();await process_frame
		var screen:=root.get_visible_rect()
		check(screen.size==Vector2(size),"native logical viewport matches requested size "+label)
		var hud: CanvasLayer=scene.art.detail.hud
		if modal:
			check(scene._panel.is_visible_in_tree() and screen.encloses(scene._panel.get_global_rect()),"modal fits "+label+" at "+str(size))
			check(not hud.visible,"modal owns the foreground "+label)
			if scroll_end:
				var action: Control=scene._actions.get_child(scene._actions.get_child_count()-1)
				check(scene._journal_scroll.get_global_rect().encloses(action.get_global_rect()),"final Return button is reachable after actual reflow "+str(size))
		else:
			check(hud.visible and screen.encloses(hud.top.get_global_rect()),"single task fits "+label+" at "+str(size))
			check(screen.encloses(hud.control_strip.get_global_rect()),"current controls fit "+label+" at "+str(size))
			check(not scene._hud.is_visible_in_tree(),"legacy HUD yields "+label)
			if hud.bottom.visible: check(not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()),"task and received words do not overlap "+label)
		if OS.get_environment("ROPE_REMOUNT_RENDER")=="1":
			await RenderingServer.frame_post_draw
			var picture:=root.get_texture().get_image()
			check(not picture.is_empty() and picture.save_png("user://rope-remount-%s-%dx%d.png"%[label,size.x,size.y])==OK,"native capture "+label)
			captures+=1
	check(retained()==before,"rendering preserves authority and native bodies "+label)

func _oral_contacts() -> void:
	await pose(Supply.QUARTERMASTER+Vector3(0,0,-1.7),Supply.QUARTERMASTER)
	scene._interact()
	check(scene._paused,"actual quartermaster contact opens retained menu")
	await press("oral:hear|quartermaster_account")
	check(scene.model.oral_progress().heard.has("quartermaster_account"),"actual local callback receives source account")
	check(scene.model.snapshot().riding_skills==baseline.riding_skills,"oral receipt preserves riding receipt")
	await capture("first-telling",true)
	var paused:=retained()
	for i in range(8): scene._physics_process(1.0/60.0)
	check(retained()==paused,"oral dialog freezes the single Home clock and bodies")
	scene._resume()
	await pose(Supply.MARKET+Vector3(0,0,1.8),Supply.MARKET)
	scene._interact()
	var agreed: Vector3=scene.avatar.global_position
	scene.avatar.global_position+=Vector3.RIGHT
	var before: Dictionary=scene.model.snapshot()
	await press("oral:hear|trader_account")
	check(scene.model.snapshot()==before and not scene.model.oral_progress().heard.has("trader_account"),"queued oral callback rejects native/recorded pose disagreement")
	scene.avatar.global_position=agreed;scene._resume();scene._interact()
	look(agreed+Vector3(0,0,10));var away: Transform3D=scene.avatar.pivot.transform
	await press("oral:hear|trader_account")
	check(scene.model.snapshot()==before and scene.avatar.pivot.transform==away,"queued oral callback rejects a turned-away listener without steering the camera")
	scene._resume();look(Supply.MARKET);scene._interact()
	var wall=scene._box(Vector3(3,3,.2),(agreed+Supply.MARKET)*.5+Vector3.UP,Color.GRAY,true)
	wall.get_parent().disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE;await frames(3)
	await press("oral:hear|trader_account")
	check(scene.model.snapshot()==before,"queued oral callback rechecks actual intervening collision before receiving testimony")
	wall.get_parent().queue_free();await frames(3)
	scene._resume();scene._interact()
	await press("oral:hear|trader_account")
	check(scene.model.oral_progress().heard.has("trader_account"),"restored local contact can receive second source")
	scene._resume();scene._open_journal()
	await press("oral_view")
	await press("oral:compare|borrowed_rope")
	check(scene.model.oral_progress().compared_seq>0,"journal compares only accounts actually received")
	await capture("comparison",true)
	scene._resume()
	before=scene.model.snapshot()
	scene._menu_action("oral:hear|well_echo");scene._menu_action("remount:begin")
	check(scene._oral_action.is_empty() and scene._remount_action.is_empty() and scene.model.snapshot()==before,"unoffered callbacks cannot queue a remote story or investigation")

func _remount_foreground() -> void:
	await pose(Supply.QUARTERMASTER+Vector3(0,0,-1.7),Supply.QUARTERMASTER)
	scene._interact();await press("remount:brief")
	check(not scene.model.has_remounts(),"briefing alone creates no investigation receipt")
	await capture("briefing",true)
	await press("remount:begin")
	check(scene.model.remount_busy(),"real quartermaster offer starts composed investigation")
	var hud: CanvasLayer=scene.art.detail.hud
	scene._refresh();hud.sample()
	check(hud.visible and not scene.foreground_guidance().is_empty(),"accepted investigation owns current Home foreground")
	check(not scene._hud.visible and not scene.bazaar_performance.canvas.visible,"no second active household or bazaar task panel")
	await capture("inquiry")
	var before:=retained();var task: String=hud.task.text
	scene.avatar.velocity=Vector3(2,0,0);hud.sample()
	check(hud.task.text==task and not hud.narrator.visible and hud.controls.visible,"moving keeps current task and controls while retiring secondary detail")
	scene.avatar.velocity=Vector3.ZERO;hud.sample()
	check(retained()==before,"attention changes do not advance evidence or camera")
	scene._open_journal();hud.sample();before=retained()
	for i in range(8): scene._physics_process(1.0/60.0)
	check(retained()==before and not hud.visible,"journal freezes remount agents and owns foreground")
	scene._resume()
	await pose(Skills.TRAINING_SITE+Vector3(-.5,0,0),Skills.TRAINING_SITE)
	before=retained()
	check(not scene.open_riding_training("single").is_empty(),"active remount responsibility refuses isolated riding visit")
	check(retained()==before and not root.disable_3d,"refused riding visit preserves composed Home")
	await pose(Supply.MARKET+Vector3(0,0,1.8),Supply.MARKET)
	scene._interact()
	check(Actions.action_id(scene._actions.get_child(0))=="remount:introduction","existing market menu prioritizes current mission continuation")
	await press("remount:introduction")
	check(scene.model.remounts().ledger.introduced,"local handler callback receives introduction")
	scene._refresh();hud.sample();await capture("introduction")

func _whole_home_restore() -> void:
	# Both domains and an existing skill receipt must cross the same load boundary.
	ok(scene.model.save_to(SAVE),"composed snapshot saved through existing Home store")
	var saved: Dictionary=scene.model.snapshot()
	var camera: Vector3=scene.avatar.pivot.rotation
	# Checkpoints remain the original early-story boundaries. A later manual
	# save retains both optional stories; an earlier checkpoint erases them.
	ok(scene.model.restore(Pose.survived()),"explicit pre-aftermath checkpoint fixture")
	ok(Pose.pose(scene.model,Skills.TRAINING_SITE),"checkpoint skill fixture at trainer")
	var early_certificate:=receipt_fixture(scene.model)
	ok(scene.model.accept_riding_training(early_certificate,early_certificate.present_sha256),"earlier checkpoint keeps its own qualified skill fixture")
	ok(Pose.pose(scene.model,Base.SITES.home),"existing courtyard checkpoint boundary")
	var earlier: Dictionary=scene.model.snapshot();scene._apply()
	scene.avatar.pivot.rotation=Vector3(.1,.4,0)
	scene._capture_checkpoint("courtyard_return")
	check(FileAccess.file_exists(scene.checkpoint_path()),"legal earlier checkpoint written through composed authority")
	ok(scene.model.restore(saved),"return to later explicit whole-Home fixture")
	scene._apply();scene.avatar.pivot.rotation=camera
	await pose(Oral.SITES.trace+Vector3(0,0,1.6),Oral.SITES.trace)
	scene._interact();await press("oral:observe|rope_trace")
	check(scene.model.oral_progress().trace_seq>0,"post-save local material observation exists before rollback")
	scene._resume();scene._load()
	check(Supply._equal(scene.model.snapshot(),saved),"manual load atomically restores oral, remount, riding and household state")
	check(scene._oral_action.is_empty() and scene._remount_action.is_empty(),"manual restore discards both pending dialog actions")
	scene._interact()
	# A callback retained from a replaced dialog must not run after a checkpoint.
	scene._oral_action="hear|trader_account";scene._remount_action="introduction"
	scene.avatar.pivot.rotation+=Vector3(0,.7,0)
	scene._restore_checkpoint()
	check(Supply._equal(scene.model.snapshot(),earlier) and not scene.model.has_oral_memory() and not scene.model.has_remounts(),"earlier checkpoint atomically removes both future story domains")
	check(scene.avatar.pivot.rotation.is_equal_approx(Vector3(.1,.4,0)),"checkpoint restores actual camera orientation")
	check(scene._oral_action.is_empty() and scene._remount_action.is_empty(),"checkpoint clears stale callbacks from both domains")
	check(scene.model.snapshot().riding_skills.lesson_receipts.size()==1,"restoring stories cannot duplicate riding grants")
	scene._load()
	check(Supply._equal(scene.model.snapshot(),saved),"manual save can return from earlier checkpoint to both retained story domains")
	var broken:=saved.duplicate(true)
	broken.oral_memory.content_digest="0".repeat(64)
	var file:=FileAccess.open(SAVE,FileAccess.WRITE);file.store_string(JSON.stringify(broken));file.close()
	var before:=retained();scene._load()
	check(retained()==before,"invalid oral digest refuses the whole composed save without partial remount replacement")
	ok(scene.model.save_to(SAVE),"restore qualified saved fixture")
	# Declared domain observations put the inquiry at its local report boundary;
	# physical route coverage lives in test_remounts rather than this fixture.
	for pair in [["note",Remounts.NOTE],["horses",Remounts.HITCH]]:
		ok(Pose.pose(scene.model,pair[1]),"declared final remount observation pose")
		ok(scene.model.remount_action(pair[0]),"declared final remount observation receipt")
	await pose(Supply.QUARTERMASTER+Vector3(0,0,-1.7),Supply.QUARTERMASTER)
	scene._interact();await press("remount:resolve")
	check(scene.model.remounts().ledger.resolved,"native report settles composed investigation")
	check(scene._paused,"heard tally has a readable optional ending")
	await capture("sealed-account",true)
	await press("remount:after");await capture("horses-stay",true)
	scene._resume();scene.art.detail.hud.sample()
	check(scene.foreground_guidance().is_empty() and scene.art.detail.hud.visible,"settled remount account returns household foreground")
	await pose(Skills.TRAINING_SITE+Vector3(-.5,0,0),Skills.TRAINING_SITE)
	before=retained()
	ok(scene.open_riding_training("single"),"settled story allows retained learned riding practice")
	var session: Node=scene.training_session
	check(is_instance_valid(session) and root.disable_3d,"existing isolated riding session owns execution and rendering")
	await frames(5)
	check(retained()==before,"both story domains and same Home bodies remain parked during practice")
	ok(session.finish(false),"optional practice returns without another receipt")
	await frames(3)
	check(retained()==before and not root.disable_3d,"practice restores the exact composed Home without replay or grants")

func _long_optional_reading() -> void:
	await pose(Oral.SITES.trace+Vector3(0,0,1.6),Oral.SITES.trace)
	scene._interact();await press("oral:observe|rope_trace");scene._resume()
	await pose(Supply.QUARTERMASTER+Vector3(0,0,-1.7),Supply.QUARTERMASTER)
	scene._interact();await press("oral:ask|quartermaster_reflection")
	check(not scene.model.oral_progress().heard.has("quartermaster_reflection"),"asking for recall does not automatically receive it")
	scene._resume()
	# Explicit clock fixture supplies the authored recall delay. The optional
	# physical travel and wait are qualified by test_oral_memory_current.
	for i in range(Oral.RECALL_TICKS): scene.model.advance()
	scene._interact();await press("oral:hear|quartermaster_reflection")
	check(scene.model.oral_progress().heard.has("quartermaster_reflection"),"returned local callback hears the delayed recollection")
	await capture("further-recollection",true);scene._resume()
	await pose(Oral.SITES.listener+Vector3(2,0,-1),Oral.SITES.listener)
	scene._interact();await press("oral:hear|well_echo");scene._resume()
	scene._interact();await press("oral:retell|comparison")
	check(scene.model.oral_view().distinct_reported_origins==2,"a heard echo retains its source instead of creating a third witness")
	await capture("retelling",true);scene._resume()
	scene._open_journal();await press("oral_view")
	await capture("remembered-stories",true)
	var before:=retained()
	scene._journal_scroll.scroll_vertical=100000;await frames(3)
	check(scene._journal_scroll.scroll_vertical>0 and retained()==before,"long remembered stories scroll without advancing evidence or changing camera")
	await capture("remembered-stories-end",true,true)

func _run() -> void:
	if DisplayServer.get_name()=="headless": printerr("ROPE REMOUNT INTEGRATION requires native Xvfb/gl_compatibility.");quit(2);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter");scene.save_path=SAVE
	root.add_child(home);current_scene=home;await frames(6)
	check(scene.model.has_method("oral_progress") and scene.model.has_method("remount_busy") and scene.model.has_method("has_riding_skill"),"production launch composes both new domains with existing riding authority")
	for body in home.find_children("*","CollisionObject3D",true,false): body.disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	home.process_mode=Node.PROCESS_MODE_DISABLED
	ok(scene.model.restore(Fixture.complete()),"explicit completed inquiry seed migrates")
	ok(Pose.pose(scene.model,Skills.TRAINING_SITE),"explicit skill retention fixture stands at trainer")
	var certificate:=receipt_fixture(scene.model)
	ok(scene.model.accept_riding_training(certificate,certificate.present_sha256),"synthetic domain skill fixture admitted for retention checks")
	ok(Pose.pose(scene.model,Supply.QUARTERMASTER+Vector3(0,0,-1.7)),"explicit allowance entry pose")
	ok(scene.model.begin_allowance(),"household allowance remains available")
	baseline=scene.model.snapshot();scene._apply()
	await _oral_contacts();await _remount_foreground();await _whole_home_restore();await _long_optional_reading()
	ok(scene.model.validate(scene.model.snapshot()),"final composed snapshot validates")
	home.queue_free();await frames(3)
	for suffix in ["",".tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("ROPE_REMOUNT_INTEGRATION_TESTS: %d passed, %d failed; %d native captures"%[passed,failed,captures]);quit(1 if failed else 0)
