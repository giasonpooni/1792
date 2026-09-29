# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Source-side conformance. Real native execution is separately bound in CI evidence.
const Bridge := preload("res://platform/steam_services.gd")
const Probe := preload("res://platform/steam_native_probe.gd")
const Fixtures := preload("res://tests/test_store_integration.gd")
var passed:=0
var failed:=0
func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("FAIL: "+label)
func _run() -> void:
	var fake:=Fixtures.FakeClient.new()
	for value in [false,null,0,1,"true"]:
		fake.running=value
		check(not Bridge.client_preflight_error(fake).is_empty(),"nontrue client presence refused")
		check(fake.init_args.is_empty() and fake.shutdowns==0,"preflight invokes neither init nor shutdown")
	fake.running=true
	check(Bridge.client_preflight_error(fake).is_empty(),"matching synthetic client passes preflight only")
	check(fake.init_args.is_empty(),"successful preflight is not SDK initialization")
	check(not Bridge.client_preflight_error(null).is_empty(),"missing native API refused")
	check(not Bridge.client_preflight_error(RefCounted.new()).is_empty(),"invalid API shape refused")
	for args in [PackedStringArray(),PackedStringArray(["--steam-native-probe","--hardware-session"]),PackedStringArray(["--steam-native-probe","--steam-app-id=1234567"])]:
		var record:=Probe.observe(args)
		check(not record.errors.is_empty() and not record.sdk_session_initialized,"incompatible probe flags do not initialize SDK")
		check(not record.live_client_qualified and not record.physical_hardware_qualified and not record.store_uploaded,"probe cannot grant qualification or upload")
	var previous_root:=OS.get_environment("CG_NATIVE_PROBE_USER_ROOT")
	OS.set_environment("CG_NATIVE_PROBE_USER_ROOT",OS.get_user_data_dir().path_join("not-the-parent"))
	var wrong_root:=Probe.observe(PackedStringArray(["--steam-native-probe"]))
	check(not wrong_root.isolated_user_storage and not wrong_root.errors.is_empty(),"wrong storage environment refused before any SDK session")
	if previous_root.is_empty(): OS.unset_environment("CG_NATIVE_PROBE_USER_ROOT")
	else: OS.set_environment("CG_NATIVE_PROBE_USER_ROOT",previous_root)
	var observation:=Probe.observe(PackedStringArray(["--steam-native-probe"]))
	if Engine.has_singleton("Steam"):
		check(observation.errors.is_empty(),"real native no-client ABI probe passes")
		check(observation.native_module_loaded and observation.adapter_contract_matches,"native module supplies required ABI")
		check(observation.client_running==false and observation.adapter_preflight_refused_without_client,"real native client preflight refuses absence")
	else:
		check(not observation.native_module_loaded and not observation.errors.is_empty(),"standard runtime never claims native test success")
		check(not observation.adapter_contract_matches and observation.client_running==null,"no invented native metadata")
		check(not observation.adapter_preflight_refused_without_client,"absence of module is different from absence of client")
	print("NATIVE_STEAM_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
