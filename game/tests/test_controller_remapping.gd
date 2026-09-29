# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_platform.gd"
## Reuse actual joypad navigation helpers, not the parent's tests or result counts.
const BINDINGS := "user://controller-remapping-test-only.json"

func event_signature(action: String, exclude_buttons: bool=false) -> Array:
	var result: Array=[]
	for e in InputMap.action_get_events(action):
		if not exclude_buttons or not e is InputEventJoypadButton: result.append(e.as_text())
	return result

func _binding_domain() -> void:
	Profile.install()
	var preserved: Dictionary={}
	for action in Profile.BUTTON_DEFAULTS: preserved[action]=event_signature(action,true)
	var ui: Dictionary={}
	for action in ["ui_accept","ui_cancel","pause_game","open_memories","move_forward","sprint","look_up"]:
		ui[action]=event_signature(action)
	var initial:=Profile.binding_record()
	ok(Profile.validate_bindings(initial),"default layout is valid")
	var proposal:=Profile.binding_proposal("interact",JOY_BUTTON_Y)
	check(proposal.swapped_action=="mount","collision proposes a specific swap")
	check(Profile.binding_record()==initial,"proposal is detached and never applies itself")
	ok(Profile.set_bindings(proposal.record,BINDINGS),"persist and apply explicit swap")
	check(Profile.button_name("interact")=="Y" and Profile.button_name("mount")=="X","both changed labels match mapping")
	check(Profile.controller_text("[E] [F] [hold Q]")=="[Y] [X] [hold LB]","swapped prompts do not cascade")
	check(Profile.hints().contains("Y interact · X mount"),"controls summary follows saved layout")
	for action in preserved: check(event_signature(action,true)==preserved[action],"retain keyboard/mouse events "+action)
	for action in ui: check(event_signature(action)==ui[action],"retain recovery/analog control "+action)
	var before:=Profile.binding_record()
	var old_bytes:=FileAccess.get_file_as_bytes(BINDINGS)
	for code in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_START,JOY_BUTTON_BACK,JOY_BUTTON_GUIDE,-1,100,NAN,INF,2.5,true,"2"]:
		var bad:=before.duplicate(true);bad.buttons.interact=code
		check(not Profile.set_bindings(bad,BINDINGS).is_empty(),"reserved or malformed code refused "+str(code))
		check(Profile.binding_record()==before and FileAccess.get_file_as_bytes(BINDINGS)==old_bytes,"rejected layout preserves memory and disk")
	var bad:=before.duplicate(true);bad.buttons.erase("guard")
	check(not Profile.validate_bindings(bad).is_empty(),"cannot remove a required action")
	bad=before.duplicate(true);bad.buttons.extra=15
	check(not Profile.validate_bindings(bad).is_empty(),"unknown action rejected")
	bad=before.duplicate(true);bad.extra="hidden"
	check(not Profile.validate_bindings(bad).is_empty(),"extra top-level field rejected")
	bad=before.duplicate(true);bad.buttons.mount=bad.buttons.interact
	check(not Profile.validate_bindings(bad).is_empty(),"duplicate action button rejected")
	bad=before.duplicate(true);bad.schema="next_version"
	check(not Profile.validate_bindings(bad).is_empty(),"unknown version rejected")
	check(not Profile.set_bindings(initial,"user://missing-remapping-folder/bindings.json").is_empty(),"failed persistence is refused")
	check(Profile.binding_record()==before,"failed write never installs unsaved controls")
	ok(Profile.load_bindings(BINDINGS),"JSON layout roundtrip")
	check(Profile.binding_record()==before,"layout roundtrip is equivalent")
	var detached:=Profile.binding_record();detached.buttons.interact=99
	check(Profile.binding_record()==before,"returned binding record is detached")
	button(JOY_BUTTON_LEFT_SHOULDER,true)
	check(Input.is_action_pressed("guard"),"guard is held before reassignment")
	proposal=Profile.binding_proposal("guard",JOY_BUTTON_RIGHT_STICK)
	ok(Profile.set_bindings(proposal.record,BINDINGS),"assign unused R3 without conflicting action")
	check(not Input.is_action_pressed("guard"),"remapping clears held gameplay state")
	button(JOY_BUTTON_LEFT_SHOULDER,false)
	check(Profile.binding_record().buttons.guard==JOY_BUTTON_RIGHT_STICK,"unused button assignment installed")
	for action in preserved:
		var count:=0
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton: count+=1
		check(count==1,"exactly one controller binding for "+action)
	ok(Storage.new().write_bytes(BINDINGS,"{broken".to_utf8_buffer(),4096),"explicit corrupt layout fixture")
	before=Profile.binding_record()
	check(not Profile.load_bindings(BINDINGS).is_empty() and Profile.binding_record()==before,"corrupt persisted layout does not partially apply")
	ok(Profile.set_bindings(initial,BINDINGS),"restore defaults for UI journey")

func _remapping_journey() -> void:
	# Starts at the real title. Only joypad events, no pose/camera/progress injection.
	var menu=load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu);current_scene=menu;await frames(4)
	await tap(JOY_BUTTON_A);await frames(4)
	var scene=current_scene.get_node("ChildhoodChapter")
	scene.save_path=SAVE;scene.controller_bindings_path=BINDINGS
	await tap(JOY_BUTTON_START);await choose("Controller settings")
	var paused: Dictionary=scene.model.snapshot()
	await choose("Reassign gameplay buttons")
	check(scene._controller_page=="bindings","D-pad reaches button editor")
	await choose("Interact / listen");await choose("Y ·")
	check(scene._controller_page=="confirm" and scene._panel_text.text.contains("Mount / dismount: Y → X"),"proposed conflict is displayed before commit")
	await tap(JOY_BUTTON_B)
	check(scene._controller_page=="choices" and Profile.button_name("interact")=="X","B cancels proposal without resuming the world")
	await choose("Y ·");await choose("Save button layout")
	check(Profile.button_name("interact")=="Y" and Profile.button_name("mount")=="X","actual GUI confirms persisted swap")
	check(scene.model.snapshot()==paused,"editing never changes clock, character state or evidence")
	# Save failure through the real editor retains the exact old file and live InputMap.
	scene.controller_bindings_path="user://missing-remapping-folder/bindings.json"
	await choose("Interact / listen");await choose("R3 ·");await choose("Save button layout")
	check(scene._panel_text.text.contains("Not saved") and Profile.button_name("interact")=="Y","GUI reports failed write without changing controls")
	scene.controller_bindings_path=BINDINGS
	# Restore/save defaults is a separate explicit confirmation. B also cancels that dialog.
	await choose("Restore default gameplay buttons");await tap(JOY_BUTTON_B)
	check(scene._controller_page=="bindings" and Profile.button_name("interact")=="Y","B cancels reset confirmation")
	# Lifecycle invalidates a prepared confirmation before it can reach persistence.
	await choose("Interact / listen");await choose("R3 ·")
	scene.controls.set_focus(false);await frames(3)
	check(scene._binding_candidate.is_empty() and scene._controller_page.is_empty(),"focus loss discards prepared remapping")
	await tap(JOY_BUTTON_A)
	check(scene._paused and Profile.button_name("interact")=="Y","background confirm cannot commit or resume")
	scene.controls.set_focus(true);await tap(JOY_BUTTON_A)
	check(not scene._paused,"deliberate resume remains available after remapping")
	axis(JOY_AXIS_RIGHT_X,1);await frames(32);axis(JOY_AXIS_RIGHT_X,0)
	await walk(scene,Vector3(0,0,-7))
	check(scene.model.stage()=="letter","unchanged analog movement starts real lesson")
	await walk(scene,Vector3(-2.5,0,3));await look(scene,Base.SITES.letter)
	await tap(JOY_BUTTON_Y);await tap(JOY_BUTTON_Y)
	check(scene.model.progress().heard==["courier"],"remapped Y hears through original physical interaction")
	check(scene._hud.text.contains("[Y]") and not scene._hud.text.contains("[E]"),"live tutorial hints use remapped button")
	await tap(JOY_BUTTON_START);await choose("Save chapter")
	var saved:=FileAccess.get_file_as_bytes(SAVE)
	check(not saved.get_string_from_utf8().contains("controller-bindings"),"binding preferences are outside saved world")
	await tap(JOY_BUTTON_START);await choose("Controller settings");await choose("Reassign gameplay buttons")
	await choose("Restore default gameplay buttons");await choose("Save default button layout")
	check(Profile.bindings==Profile.BUTTON_DEFAULTS,"explicit GUI reset restores original buttons")
	check(FileAccess.get_file_as_bytes(SAVE)==saved,"layout reset never rewrites game save")
	await tap(JOY_BUTTON_B);await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_START);await choose("Load chapter")
	check(Profile.bindings==Profile.BUTTON_DEFAULTS,"loading story cannot restore stale remap preferences")
	await tap(JOY_BUTTON_START);await choose("Main menu")
	check(current_scene.scene_file_path=="res://ui/main_menu.tscn","return to title with fixed recovery controls")
	current_scene.queue_free();current_scene=null;await frames(3)

func _run() -> void:
	Input.use_accumulated_input=false
	_binding_domain()
	neutral();await frames(2)
	await _remapping_journey()
	var audit: Dictionary={"schema":"cg.controller-remapping-conformance.v1",
		"source_commit":OS.get_environment("SOURCE_COMMIT"),"execution_id":OS.get_environment("GITHUB_RUN_ID"),
		"verification_id":"controller-remapping-native.v1","model_id":Profile.BINDINGS_SCHEMA,
		"operation_id":"synthetic-remapping-journey.v1","engine":Engine.get_version_info().string,
		"os":OS.get_name(),"joy_events":joy_events,"physical_controller_test":false,
		"journey_fixture":false,"keyboard_or_mouse_events_in_journey":0}
	var file:=FileAccess.open("user://platform-remapping-audit.json",FileAccess.WRITE)
	check(file!=null,"retain remapping observation")
	if file!=null:
		audit.passed=passed;audit.failed=failed
		file.store_string(JSON.stringify(audit,"\t"));file.close()
	for path in [BINDINGS,SAVE,SAVE+".checkpoint.json"]: DirAccess.remove_absolute(path)
	print("CONTROLLER_REMAPPING_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
