# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Opt-in packaged boot check, no test fixtures, no player's save slot, no store requests.
const Reading := preload("res://platform/reading_profile.gd")
const READING_PATH := "user://1792-reading-probe-test-only.json"
const Recovery := preload("res://platform/save_recovery.gd")
const State := preload("res://narrative/oral_memory/memory_state.gd")
const Launch := preload("res://childhood/home_launch.gd")
const Memory := preload("res://narrative/oral_memory/memory_rules.gd")
const Equality := preload("res://territory/misl_rules.gd")
const SAVE := "user://1792-platform-probe-test-only.json"

static func run(menu: Node) -> void:
	var errors: Array=[]
	var tree:=menu.get_tree()
	var home:=Launch.make_world()
	tree.root.add_child(home)
	for _i in range(3): await tree.physics_frame
	var chapter=home.get_node("ChildhoodChapter")
	var state: State=chapter.model
	var error:=state.save_to(SAVE)
	if not error.is_empty(): errors.append(error)
	# Actual existing-file replacement and JSON restoration on the host filesystem.
	error=state.save_to(SAVE)
	if not error.is_empty(): errors.append(error)
	var copy:=State.new()
	error=copy.load_from(SAVE)
	if not error.is_empty(): errors.append(error)
	# Compare every field against the declared JSON serialization, not raw float bit patterns.
	var serialized: Variant=JSON.parse_string(JSON.stringify(state.snapshot(),"",true,true))
	if not Equality._equal(copy.snapshot(),serialized): errors.append("Restored snapshot differs from serialized state.")
	error=Memory.content_error(Memory.content())
	if not error.is_empty(): errors.append(error)
	if not OS.has_feature("editor") and ResourceLoader.exists("res://tests/test_oral_memory.gd"): errors.append("Development tests leaked into packaged content.")
	if state.platform_services.entitlement().status!="not_checked": errors.append("Local provider claimed a store entitlement.")
	# The exported process also executes the same recovery policy used by F5/the UI.
	var before:=FileAccess.get_file_as_bytes(SAVE)
	state.advance()
	error=Recovery.save(state,SAVE)
	if not error.is_empty(): errors.append(error)
	if FileAccess.get_file_as_bytes(SAVE+Recovery.PREVIOUS_SUFFIX)!=before: errors.append("Exported previous save did not retain the old primary.")
	error=state.platform_services.storage.write_bytes(SAVE,"{interrupted".to_utf8_buffer(),state.LIMIT)
	if not error.is_empty(): errors.append(error)
	if Recovery.save(state,SAVE).is_empty(): errors.append("Exported save silently replaced invalid primary.")
	var previous:=Recovery.inspect(state,SAVE+Recovery.PREVIOUS_SUFFIX)
	var recovered:=Recovery.read_selected(state,previous.path,previous.digest)
	if not recovered.error.is_empty(): errors.append(recovered.error)
	else:
		error=state.restore(recovered.snapshot)
		if not error.is_empty(): errors.append(error)
	var invalid:=Recovery.inspect(state,SAVE)
	error=Recovery.save(state,SAVE,{"primary_digest":invalid.digest,"world_digest":Recovery.world_digest(state)})
	if not error.is_empty(): errors.append(error)
	if FileAccess.get_file_as_bytes(SAVE+Recovery.PREVIOUS_SUFFIX)!=before: errors.append("Exported repair modified the previous save.")
	# Dispose of the original probe world before preparing a frozen title-Continue candidate.
	home.queue_free()
	for _i in range(3): await tree.physics_frame
	error=await Launch.enter_saved(tree,SAVE,Recovery.inspect(state,SAVE).digest,SAVE,state.platform_services,func(): return true)
	if not error.is_empty(): errors.append(error)
	elif not tree.current_scene.get_node("ChildhoodChapter")._paused: errors.append("Exported Continue resumed without user choice.")
	# Probe the shipped reading provider and actual enlarged modal without player files.
	var old_reading:=Reading.snapshot()
	var large:=old_reading.duplicate(true)
	large.text_percent=200;large.high_contrast=true;large.narrator_captions=false
	error=Reading.set_preferences(large,READING_PATH,state.platform_services.storage)
	if not error.is_empty(): errors.append(error)
	error=Reading.load_preferences(READING_PATH,state.platform_services.storage)
	if not error.is_empty() or Reading.snapshot()!=large: errors.append("Exported reading preferences failed to reload.")
	if error.is_empty() and tree.current_scene.has_node("ChildhoodChapter"):
		var active=tree.current_scene.get_node("ChildhoodChapter")
		var world: Dictionary=active.model.snapshot()
		active._open_reading_settings()
		for _i in range(3): await tree.process_frame
		if active._panel_text.get_theme_font_size("font_size")!=34: errors.append("Exported modal did not apply 200 percent text.")
		if active.model.snapshot()!=world: errors.append("Reading presentation mutated exported chapter.")
	error=Reading.set_preferences(old_reading,READING_PATH,state.platform_services.storage)
	if not error.is_empty(): errors.append(error)
	DirAccess.remove_absolute(READING_PATH)
	var notices:=FileAccess.open("user://platform-engine-notices.json",FileAccess.WRITE)
	if notices==null: errors.append("Cannot retain runtime licence notices.")
	else:
		notices.store_string(JSON.stringify({"schema":"cg.engine-notices.v1","engine":Engine.get_version_info().string,
			"godot_license":Engine.get_license_text(),"components":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"\t"))
		notices.close()
	print("PLATFORM_BOOT_RECORD: "+JSON.stringify({"schema":"cg.packaged-boot-observation.v1","os":OS.get_name(),
		"engine":Engine.get_version_info().string,"exported":not OS.has_feature("editor"),"provider_id":state.platform_services.IMPLEMENTATION_ID,
		"content_sha256":Memory.content_digest(),"manual_save_policy":Recovery.POLICY_ID,"recovery_and_continue_probe":true,"reading_profile":Reading.SCHEMA,"reading_probe":true,"errors":errors,"physical_controller_test":false,"console_certification":false}))
	DirAccess.remove_absolute(SAVE)
	DirAccess.remove_absolute(SAVE+Recovery.PREVIOUS_SUFFIX)
	await tree.process_frame
	print("PLATFORM_BOOT_SMOKE: "+("pass" if errors.is_empty() else "fail"))
	tree.quit(0 if errors.is_empty() else 1)
