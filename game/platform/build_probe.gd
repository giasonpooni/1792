# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Opt-in packaged boot check, no test fixtures, no player's save slot, no store requests.
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
	var notices:=FileAccess.open("user://platform-engine-notices.json",FileAccess.WRITE)
	if notices==null: errors.append("Cannot retain runtime licence notices.")
	else:
		notices.store_string(JSON.stringify({"schema":"cg.engine-notices.v1","engine":Engine.get_version_info().string,
			"godot_license":Engine.get_license_text(),"components":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"\t"))
		notices.close()
	print("PLATFORM_BOOT_RECORD: "+JSON.stringify({"schema":"cg.packaged-boot-observation.v1","os":OS.get_name(),
		"engine":Engine.get_version_info().string,"exported":not OS.has_feature("editor"),"provider_id":state.platform_services.IMPLEMENTATION_ID,
		"content_sha256":Memory.content_digest(),"errors":errors,"physical_controller_test":false,"console_certification":false}))
	DirAccess.remove_absolute(SAVE)
	home.queue_free()
	await tree.process_frame
	print("PLATFORM_BOOT_SMOKE: "+("pass" if errors.is_empty() else "fail"))
	tree.quit(0 if errors.is_empty() else 1)
