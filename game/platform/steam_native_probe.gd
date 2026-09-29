# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Opt-in native module load/ABI probe. Never initializes a successful SDK session.
## Run only in an isolated no-client environment, not as a live-store qualification.
const Bridge := preload("res://platform/steam_services.gd")

func _initialize() -> void: _probe_run.call_deferred()

static func observe(args: PackedStringArray) -> Dictionary:
	var source: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://platform/build_identity.json"))
	var errors: Array=[]
	var expected_root:=OS.get_environment("CG_NATIVE_PROBE_USER_ROOT").replace("\\","/").simplify_path()
	var actual_root:=OS.get_user_data_dir().replace("\\","/").simplify_path()
	var isolated:=not expected_root.is_empty() and actual_root.begins_with(expected_root.trim_suffix("/")+"/")
	var record: Dictionary={"schema":"cg.steam-native-probe.v1","os":OS.get_name(),
		"engine":Engine.get_version_info().string,"exported":not OS.has_feature("editor"),
		"source_commit":source.get("source_commit","") if source is Dictionary else "",
		"source_tree":source.get("source_tree","") if source is Dictionary else "",
		"build_execution_id":source.get("execution_id","") if source is Dictionary else "",
		"native_module_loaded":Engine.has_singleton("Steam"),"adapter_contract_matches":false,
		"isolated_user_storage":isolated,"client_running":null,"adapter_preflight_refused_without_client":false,"sdk_session_initialized":false,
		"live_client_qualified":false,"physical_hardware_qualified":false,"store_uploaded":false,"errors":errors}
	if args!=PackedStringArray(["--steam-native-probe"]):
		errors.append("The isolated native probe accepts no other application flags.")
		return record
	if not expected_root.is_empty() and not isolated:
		errors.append("The native probe did not receive its isolated user-storage environment.")
		return record
	if not Engine.has_singleton("Steam"):
		errors.append("Native Steam singleton absent; this is the ordinary local-PC runtime.")
		return record
	var api:=Engine.get_singleton("Steam")
	var contract_error:=Bridge.api_error(api)
	if not contract_error.is_empty():
		errors.append(contract_error)
		return record
	record.adapter_contract_matches=true
	if bool(ProjectSettings.get_setting("steam/initialization/initialize_on_startup",false)) or bool(ProjectSettings.get_setting("steam/initialization/embed_callbacks",false)):
		errors.append("Automatic SDK initialization/callbacks are not permitted in this probe.")
		return record
	var running: Variant=api.call("isSteamRunning")
	if not running is bool:
		errors.append("Native client-presence response was not boolean.")
		return record
	record.client_running=running
	if running:
		errors.append("A client is present. Refusing the no-client fixture without initializing a session.")
		return record
	# Exercise the SAME admission preflight used by initialize, without ever supplying
	# an app ID or calling SteamInit. A client starting between checks fails this
	# no-client fixture; it cannot cause a sample/unassigned app login attempt.
	var error:=Bridge.client_preflight_error(api)
	record.adapter_preflight_refused_without_client=error.begins_with("Steam client is not running")
	if not record.adapter_preflight_refused_without_client: errors.append("Native no-client preflight did not refuse; no initialization was attempted.")
	return record

func _probe_run() -> void:
	var record:=observe(OS.get_cmdline_user_args())
	print("STEAM_NATIVE_RECORD: "+JSON.stringify(record))
	print("STEAM_NATIVE_PROBE: "+("pass" if record.errors.is_empty() else "fail"))
	quit(0 if record.errors.is_empty() else 1)
