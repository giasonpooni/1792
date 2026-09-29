# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_platform.gd"
## Reuses joypad helpers only. Storage/lifecycle faults are explicitly injected fixtures.
const Recovery := preload("res://platform/save_recovery.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const SLOT := "user://save-recovery-test-only.json"
const PREVIOUS := SLOT+Recovery.PREVIOUS_SUFFIX

class SelectiveFailure extends "res://platform/local_storage.gd":
	var fail_path: String=""
	var writes: Array=[]
	func write_bytes(path: String, bytes: PackedByteArray, limit: int) -> String:
		writes.append(path)
		if path==fail_path: return "Injected write failure."
		return super.write_bytes(path,bytes,limit)

func clean() -> void:
	for path in [SLOT,PREVIOUS,SLOT+".tmp",PREVIOUS+".tmp"]: DirAccess.remove_absolute(path)

func _save_domain() -> void:
	clean()
	var s:=State.new()
	var storage:=Storage.new()
	var live:=s.snapshot()
	check(Recovery.inspect(s,SLOT).status=="missing","missing save is distinct from invalid data")
	ok(Recovery.save(s,SLOT),"first manual save")
	var first:=FileAccess.get_file_as_bytes(SLOT)
	check(not FileAccess.file_exists(PREVIOUS),"first save invents no previous progress")
	check(s.snapshot()==live,"saving does not advance or mutate world")
	s.advance();live=s.snapshot()
	ok(Recovery.save(s,SLOT),"second manual save")
	var second:=FileAccess.get_file_as_bytes(SLOT)
	check(first!=second and FileAccess.get_file_as_bytes(PREVIOUS)==first,"valid prior primary retained byte-for-byte")
	ok(Recovery.save(s,SLOT),"identical repeated save")
	check(FileAccess.get_file_as_bytes(PREVIOUS)==first,"identical save does not displace useful previous snapshot")
	var info:=Recovery.inspect(s,SLOT)
	check(info.status=="valid" and info.tick==1 and info.stage=="orientation","summary derives from validated original state")
	check(not info.has("snapshot") and not info.has("bytes"),"overview does not expose or serialize a second world")
	var selected:=Recovery.read_selected(s,SLOT,info.digest)
	ok(selected.error,"selected digest can be read")
	selected.snapshot.player.known_places.append("invented")
	check(s.snapshot()==live,"selected candidate detached from live authority")
	check(not Recovery.read_selected(s,SLOT,"0".repeat(64)).error.is_empty(),"stale selection refused")
	var broken:=SelectiveFailure.new()
	s.platform_services.storage=broken
	s.advance();live=s.snapshot()
	broken.fail_path=PREVIOUS
	check(not Recovery.save(s,SLOT).is_empty(),"failed backup blocks primary replacement")
	check(broken.writes==[PREVIOUS] and FileAccess.get_file_as_bytes(SLOT)==second and FileAccess.get_file_as_bytes(PREVIOUS)==first,"backup-write failure preserves both destinations")
	broken.writes=[];broken.fail_path=SLOT
	check(not Recovery.save(s,SLOT).is_empty(),"failed primary write propagates")
	check(broken.writes==[PREVIOUS,SLOT] and FileAccess.get_file_as_bytes(SLOT)==second and FileAccess.get_file_as_bytes(PREVIOUS)==second,"primary failure retains valid old primary and completed backup")
	check(s.snapshot()==live,"I/O failures never mutate live world")
	s.platform_services.storage=storage
	ok(Recovery.save(s,SLOT),"retry uses same world without extra clock")
	var previous:=FileAccess.get_file_as_bytes(PREVIOUS)
	ok(storage.write_bytes(SLOT,"{truncated".to_utf8_buffer(),s.LIMIT),"explicit corrupt-primary fault")
	var corrupt:=FileAccess.get_file_as_bytes(SLOT)
	check(Recovery.inspect(s,SLOT).status=="invalid","bounded malformed data is identified")
	check(not Recovery.save(s,SLOT).is_empty(),"ordinary save cannot silently overwrite invalid primary")
	check(FileAccess.get_file_as_bytes(SLOT)==corrupt and FileAccess.get_file_as_bytes(PREVIOUS)==previous and s.snapshot()==live,"refusal preserves files and live progress")
	var ticket: Dictionary={"primary_digest":Recovery.digest(corrupt),"world_digest":Recovery.world_digest(s)}
	s.advance()
	check(not Recovery.save(s,SLOT,ticket).is_empty(),"confirmation binds exact live snapshot")
	ticket.world_digest=Recovery.world_digest(s)
	ok(storage.write_bytes(SLOT,"{changed".to_utf8_buffer(),s.LIMIT),"explicit external edit fault")
	check(not Recovery.save(s,SLOT,ticket).is_empty(),"confirmation binds exact invalid primary bytes")
	ticket.primary_digest=Recovery.inspect(s,SLOT).digest
	ok(Recovery.save(s,SLOT,ticket),"explicit reviewed replacement accepted")
	check(Recovery.inspect(s,SLOT).status=="valid" and FileAccess.get_file_as_bytes(PREVIOUS)==previous,"replacement never backs up corrupt bytes")
	check(not Recovery.save(s,SLOT,ticket).is_empty(),"confirmation cannot be replayed against now-valid primary")
	DirAccess.remove_absolute(SLOT)
	ok(Recovery.save(s,SLOT),"missing primary can be recreated without modifying previous")
	check(FileAccess.get_file_as_bytes(PREVIOUS)==previous,"recreation preserves recovery candidate")
	var bad:=s.snapshot();bad.schema="future.schema"
	ok(storage.write_bytes(SLOT,JSON.stringify(bad).to_utf8_buffer(),s.LIMIT),"unknown version fixture")
	check(Recovery.inspect(s,SLOT).status=="invalid" and not Recovery.save(s,SLOT).is_empty(),"unknown schema fails existing validator")
	ok(storage.write_bytes(SLOT,"x".repeat(s.LIMIT+1).to_utf8_buffer(),s.LIMIT+2),"oversize file fixture")
	check(Recovery.inspect(s,SLOT).status=="unavailable" and not Recovery.save(s,SLOT).is_empty(),"oversize content is not buffered, replaced or presented as recoverable")
	for path in ["res://project.godot","user://../file.json","user://nested/file.json","user://.hidden.json","user://bad\\file.json","user://a.json.previous.previous"]:
		check(not Recovery.save(s,path).is_empty(),"path refused "+path)
	s.platform_services.storage=RefusingTransport.new()
	check(Recovery.inspect(s,SLOT).status=="unavailable" and not Recovery.save(s,SLOT).is_empty(),"unsupported inspection transport never falls back")
	clean()
	# Whole-state rollback retains no income, water ledger or testimony from discarded future.
	s=State.new();ok(s.restore(Fixture.complete()),"labelled completed-inquiry fixture")
	ok(Recovery.save(s,SLOT),"pre-economy fixture saved")
	var old:=s.snapshot()
	ok(s.begin_allowance(),"future allowance fixture")
	ok(s.begin_water_round(),"future water fixture")
	ok(s.oral_operation("hear","quartermaster_account"),"future received account fixture")
	ok(Recovery.save(s,SLOT),"future coupled state saved")
	selected=Recovery.read_selected(s,PREVIOUS,Recovery.inspect(s,PREVIOUS).digest)
	ok(selected.error,"previous coupled state read")
	ok(s.restore(selected.snapshot),"existing validator promotes whole old state")
	check(Equality._equal(s.snapshot(),old) and not s.has_economy() and not s.has_water_round() and not s.has_oral_memory(),"no merge of future knowledge or resources")
	clean()

func _save_journey() -> void:
	# Real title/input/collision journey. No player pose, camera or story progress injection.
	var settings_before:=Profile.settings.duplicate(true)
	var bindings_before:=Profile.binding_record()
	var menu=load("res://ui/main_menu.tscn").instantiate()
	menu.home_save_path=SLOT
	root.add_child(menu);current_scene=menu;await frames(4)
	await tap(JOY_BUTTON_A);await frames(3)
	var scene=current_scene.get_node("ChildhoodChapter")
	scene.save_path=SLOT
	axis(JOY_AXIS_RIGHT_X,1);await frames(32);axis(JOY_AXIS_RIGHT_X,0)
	await walk(scene,Vector3(0,0,-7))
	await walk(scene,Vector3(-2.5,0,3));await look(scene,Base.SITES.letter)
	await tap(JOY_BUTTON_START);await choose("Save chapter")
	var first:=FileAccess.get_file_as_bytes(SLOT)
	await tap(JOY_BUTTON_X);await tap(JOY_BUTTON_X)
	check(scene.model.progress().heard==["courier"],"real interaction changes remembered account")
	await tap(JOY_BUTTON_START);await choose("Save chapter")
	var second:=FileAccess.get_file_as_bytes(SLOT)
	check(FileAccess.get_file_as_bytes(PREVIOUS)==first,"controller save retains earlier actual play")
	await tap(JOY_BUTTON_START);await choose("Main menu")
	menu=current_scene;menu.home_save_path=SLOT
	await choose("Saved home chapter / recovery");await choose("Continue primary");await frames(5)
	check(current_scene!=menu and current_scene.has_node("ChildhoodChapter"),"title Continue enters selected home after actual geometry checks")
	if not current_scene.has_node("ChildhoodChapter"): return
	scene=current_scene.get_node("ChildhoodChapter")
	check(scene._paused and Equality._equal(scene.model.snapshot(),JSON.parse_string(second.get_string_from_utf8())),"Continue starts paused at exact serialized snapshot")
	check(scene.narrator.text.is_empty(),"Continue silently baselines retrospective narration")
	await tap(JOY_BUTTON_A)
	await tap(JOY_BUTTON_START);await choose("Saved chapter / recovery")
	var paused: Dictionary=scene.model.snapshot()
	await choose("Recover previous");await tap(JOY_BUTTON_B)
	check(scene.model.snapshot()==paused and scene._save_page=="browser","B cancels recovery without changing world")
	await choose("Recover previous")
	scene.controls.set_focus(false);await frames(2)
	check(scene._save_choice.is_empty() and scene._save_command.is_empty(),"focus interruption discards prepared recovery")
	await tap(JOY_BUTTON_A)
	check(scene.model.snapshot()==paused and scene._paused,"background confirmation cannot load or resume")
	scene.controls.set_focus(true);await tap(JOY_BUTTON_A)
	await tap(JOY_BUTTON_START);await choose("Saved chapter / recovery");await choose("Recover previous");await choose("Confirm load")
	check(scene._paused and Equality._equal(scene.model.snapshot(),JSON.parse_string(first.get_string_from_utf8())),"explicit recovery replaces whole current chapter")
	check(scene.model.progress().heard.is_empty(),"discarded courier telling does not survive recovery")
	check(FileAccess.get_file_as_bytes(SLOT)==second and FileAccess.get_file_as_bytes(PREVIOUS)==first,"loading never overwrites primary or previous")
	# Labelled filesystem fault while the actual player is paused; not fabricated game progress.
	ok(Storage.new().write_bytes(SLOT,"{broken".to_utf8_buffer(),scene.model.LIMIT),"UI corrupt-primary fault")
	await choose("Saved chapter / recovery");await choose("Replace invalid primary");await choose("Confirm replacement")
	check(Recovery.inspect(scene.model,SLOT).status=="valid" and FileAccess.get_file_as_bytes(PREVIOUS)==first,"explicit in-game repair retains previous save")
	await choose("Resume")
	check(scene._save_page.is_empty() and scene._save_choice.is_empty(),"resuming clears save-menu input context")
	await tap(JOY_BUTTON_B)
	check(scene._paused,"B again opens normal journal after leaving save manager")
	await choose("Main menu")
	menu=current_scene;menu.home_save_path=SLOT
	await choose("Saved home chapter / recovery");await choose("Review previous save");await tap(JOY_BUTTON_B)
	check(current_scene==menu and menu._saved_choice.is_empty(),"title previous-save confirmation can be cancelled")
	await choose("Review previous save");await choose("Confirm previous chapter");await frames(5)
	check(current_scene.has_node("ChildhoodChapter"),"title can explicitly recover previous snapshot")
	if current_scene.has_node("ChildhoodChapter"):
		scene=current_scene.get_node("ChildhoodChapter")
		check(scene._paused and Equality._equal(scene.model.snapshot(),JSON.parse_string(first.get_string_from_utf8())),"title previous selection restores exactly and remains paused")
	check(Profile.settings==settings_before and Profile.binding_record()==bindings_before,"save recovery cannot roll back controller preferences")
	# Explicit provider failure fixture, isolated from physical input journey above.
	var unchanged: Dictionary=scene.model.snapshot()
	scene.model.platform_services.storage=RefusingTransport.new()
	scene._load()
	check(scene.model.snapshot()==unchanged and scene._message.contains("Injected"),"legacy F9 load retains injected transport and cannot silently read local disk")
	scene.model.platform_services.storage=Storage.new()
	current_scene.queue_free();current_scene=null;await frames(4)
	clean()

func _title_refusals() -> void:
	# Explicit invalid-geometry fixture, separate from the real input journey above.
	var state:=State.new();ok(state.restore(Fixture.complete()),"geometry-test fixture")
	ok(Pose.pose(state,Vector3(-20,0.14,2)),"schema-valid pose inside original solid wall")
	ok(state.save_to(SLOT),"store blocked-position fixture via existing encoder")
	var menu=load("res://ui/main_menu.tscn").instantiate();menu.home_save_path=SLOT
	root.add_child(menu);current_scene=menu;await frames(4)
	await choose("Continue saved home chapter");await frames(5)
	check(current_scene==menu and menu._saved_box.visible,"geometry failure retains title rather than installing broken world")
	check(not menu._continue_busy,"failed staging releases input busy state")
	var worlds:=0
	for child in root.get_children():
		if child is Node3D: worlds+=1
	check(worlds==0,"rejected candidate world is freed")
	var view:=Recovery.inspect(state,SLOT)
	state.advance();ok(state.save_to(SLOT),"changed save fixture")
	var error: String=await Launch.enter_saved(self,SLOT,view.digest,SLOT,state.platform_services,func(): return true)
	check(not error.is_empty() and current_scene==menu,"stale title digest refused")
	var calls: Array=[0]
	var allowed:=func() -> bool:
		calls[0]+=1
		return calls[0]==1
	error=await Launch.enter_saved(self,SLOT,Recovery.inspect(state,SLOT).digest,SLOT,state.platform_services,allowed)
	await frames(3)
	check(not error.is_empty() and current_scene==menu,"interruption during frozen candidate staging cancels entry")
	current_scene.queue_free();current_scene=null;await frames(3)
	clean()

func _run() -> void:
	Input.use_accumulated_input=false
	Profile.install()
	_save_domain()
	neutral();await frames(2)
	await _save_journey()
	await _title_refusals()
	var audit: Dictionary={"schema":"cg.save-recovery-conformance.v1","model_id":Recovery.POLICY_ID,
		"verification_id":"save-recovery-native.v1","operation_id":"synthetic-save-recovery-journey.v1",
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"execution_id":OS.get_environment("GITHUB_RUN_ID"),
		"engine":Engine.get_version_info().string,"os":OS.get_name(),"joy_events":joy_events,
		"physical_controller_test":false,"journey_pose_injection":false,"fault_fixtures":true,"power_loss_qualified":false}
	var file:=FileAccess.open("user://platform-save-recovery-audit.json",FileAccess.WRITE)
	check(file!=null,"retain save recovery observation")
	if file!=null:
		audit.passed=passed;audit.failed=failed;file.store_string(JSON.stringify(audit,"\t"));file.close()
	print("SAVE_RECOVERY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
