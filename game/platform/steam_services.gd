# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Opt-in GodotSteam bridge. Native dependency is NOT supplied by the local-PC export.
## One caller pumps callbacks. No restart, overlay activation, achievements or network writes.
const CONTRACT_ID := "cg.platform-services.v1"
const IMPLEMENTATION_ID := "cg.steam-client.v1"
const ScopedStorage := preload("res://platform/steam_storage.gd")
const METHODS := {"steamInitEx":2,"steamShutdown":0,"run_callbacks":0,
	"isSteamRunning":0,"getAppID":0,"getSteamID":0,"isSubscribed":0,"loggedOn":0}
signal gate_changed(blocked: bool, reason: String)
var storage: RefCounted
var error := "Steam session has not been initialized."
var ready := false
var overlay_open := false
var _api: Object
var _owns_api := false
var _injected_api := false
var _attempted := false
var _app_id := 0
var _user_id := 0

static func valid_app_id(value: Variant) -> bool:
	return value is int and value>0 and value<=4294967295 and value!=480

static func api_error(api: Object) -> String:
	if api==null: return "GodotSteam is absent. This local-PC build cannot create a Steam client session."
	var found: Dictionary={}
	for method in api.get_method_list(): found[str(method.name)]=method.args.size()
	for method in METHODS:
		if found.get(method,-1)!=METHODS[method]: return "Unsupported GodotSteam method contract: "+method
	var signal_ok:=false
	for definition in api.get_signal_list():
		if str(definition.name)=="overlay_toggled" and definition.args.size()==3:
			signal_ok=definition.args[0].type==TYPE_BOOL and definition.args[1].type==TYPE_BOOL and definition.args[2].type==TYPE_INT
	if not signal_ok: return "GodotSteam requires the three-argument overlay_toggled signal."
	return ""

static func client_preflight_error(api: Object) -> String:
	# Shared native preflight. Never calls SteamInit or reads a platform-user ID.
	var shape_error:=api_error(api)
	if not shape_error.is_empty(): return shape_error
	if not _true_bool(api.call("isSteamRunning")): return "Steam client is not running; no local-profile fallback was selected."
	return ""

func initialize(app_id: Variant, api: Object=null) -> String:
	if _attempted: return "This Steam provider has already attempted initialization; create no concurrent owner."
	_attempted=true
	if not valid_app_id(app_id): return _fail("Supply the assigned, non-sample uint32 Steam app ID explicitly.")
	if bool(ProjectSettings.get_setting("steam/initialization/initialize_on_startup",false)) or bool(ProjectSettings.get_setting("steam/initialization/embed_callbacks",false)):
		return _fail("Disable GodotSteam automatic initialization and embedded callbacks; the platform runtime owns both.")
	_injected_api=api!=null
	_api=api if api!=null else (Engine.get_singleton("Steam") if Engine.has_singleton("Steam") else null)
	var preflight_error:=client_preflight_error(_api)
	if not preflight_error.is_empty(): return _fail(preflight_error)
	# GodotSteam's documented signature is app_id FIRST, embed_callbacks SECOND.
	var result: Variant=_api.call("steamInitEx",app_id,false)
	if not result is Dictionary or not result.get("status") is int or result.status!=0:
		return _fail("Steam initialization failed or returned an incompatible result. Check client, app assignment and native bridge.")
	_owns_api=true
	_app_id=app_id
	var user: Variant=_api.call("getSteamID")
	var current_app: Variant=_api.call("getAppID")
	if not user is int or user<=0 or not current_app is int or current_app!=_app_id:
		return _fail("Steam app/user identity does not match the requested session.")
	_user_id=user
	ready=true
	error=""
	if not check_session(): return error
	_api.connect("overlay_toggled",_overlay)
	storage=ScopedStorage.new()
	storage.configure(self,_app_id,_user_id)
	gate_changed.emit(false,"")
	return ""

func check_session() -> bool:
	if not ready or not is_instance_valid(_api): return false
	var app: Variant=_api.call("getAppID")
	var user: Variant=_api.call("getSteamID")
	if not _true_bool(_api.call("isSteamRunning")) or not app is int or app!=_app_id or not user is int or user!=_user_id:
		_fail("Steam client/app/user changed. Gameplay and scoped saves are blocked; restart the application deliberately.")
		return false
	if not _true_bool(_api.call("isSubscribed")):
		_fail("The current Steam client no longer reports access to this app. No account or entitlement was substituted.")
		return false
	# loggedOn=false may be legitimate offline single-player use, not a missing local licence.
	return true

func pump() -> void:
	if ready:
		_api.call("run_callbacks")
		check_session()

func _overlay(active: bool, _user_initiated: bool, _overlay_app_id: int) -> void:
	# Callback metadata is not a session/user identity assertion. SDK getters own that check.
	if not check_session(): return
	overlay_open=active
	gate_changed.emit(active,"Steam overlay is open. Resume deliberately after closing it." if active else "")

func _fail(message: String) -> String:
	ready=false
	error=message
	gate_changed.emit(true,message)
	# Cleanup happens at explicit shutdown, not re-entrantly inside an SDK callback.
	return message

func shutdown() -> void:
	ready=false
	if is_instance_valid(_api) and _api.is_connected("overlay_toggled",_overlay): _api.disconnect("overlay_toggled",_overlay)
	if _owns_api and is_instance_valid(_api): _api.call("steamShutdown")
	_owns_api=false
	overlay_open=false

func identity() -> Dictionary:
	return {"provider_id":IMPLEMENTATION_ID,"scope":"steam-app-user-local",
		"platform_user_id":str(_user_id) if ready else null,"app_id":_app_id if ready else null}

func capabilities() -> Dictionary:
	return {"local_save":ready,"cloud_save":false,"platform_sign_in":false,
		"achievements":false,"entitlement_verification":false,"console_lifecycle":false}

func entitlement() -> Dictionary:
	var valid:=check_session()
	return {"status":"client_reported_subscribed" if valid else "unavailable","provider_id":IMPLEMENTATION_ID,
		"server_authenticated":false}

func unlock_achievement(_achievement_id: String) -> Dictionary:
	return {"ok":false,"code":"unavailable","provider_id":IMPLEMENTATION_ID}

func diagnostic_status() -> Dictionary:
	# Deliberately excludes user IDs, persona names, tokens and local account paths.
	return {"provider_id":IMPLEMENTATION_ID,"ready":ready,"overlay_open":overlay_open,
		"native_client_observed":ready and not _injected_api,"client_contract_observed":ready,
		"dependency_evidence":"injected_test_double" if _injected_api else "runtime_singleton","cloud_enabled":false,"server_authenticated":false}

func reading_storage() -> RefCounted:
	# Reading/controller preferences remain OS-user preferences, not account state.
	return preload("res://platform/local_storage.gd").new()

static func _true_bool(value: Variant) -> bool:
	return value is bool and value
