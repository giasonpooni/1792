# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node
## Optional process-lifetime adapter owner. No game-state writer, world, timer or save sidecar.
const SteamServices := preload("res://platform/steam_services.gd")
const Hardware := preload("res://platform/hardware_session.gd")
signal gate_changed(blocked: bool, reason: String)
var provider: RefCounted
var recorder: Node
var steam_requested := false
var blocked := false
var reason := ""

static func ensure(tree: SceneTree, args: PackedStringArray) -> Node:
	var existing:=tree.root.get_node_or_null("PlatformRuntime")
	if existing!=null: return existing
	var requested:=false
	for arg in args:
		if arg.begins_with("--steam-app-id") or arg=="--hardware-session": requested=true
	if not requested: return null
	var host=load("res://platform/platform_runtime.gd").new()
	host.name="PlatformRuntime"
	tree.root.add_child(host)
	host.configure(args)
	return host

func configure(args: PackedStringArray, injected_api: Object=null, automated: bool=false) -> void:
	var values: Array=[]
	for arg in args:
		if arg.begins_with("--steam-app-id"):
			steam_requested=true
			values.append(arg.trim_prefix("--steam-app-id="))
	if steam_requested:
		provider=SteamServices.new()
		provider.gate_changed.connect(_gate)
		var app_id:=0
		if values.size()==1:
			var text: String=values[0]
			if text.is_valid_int() and str(int(text))==text: app_id=int(text)
		var error: String=provider.initialize(app_id,injected_api)
		if not error.is_empty(): _gate(true,error)
	if "--hardware-session" in args:
		recorder=Hardware.new()
		recorder.automated=automated
		add_child(recorder)

func _gate(value: bool, message: String) -> void:
	blocked=value;reason=message
	gate_changed.emit(value,message)

func _process(_delta: float) -> void:
	if provider!=null: provider.pump()

func _exit_tree() -> void:
	if provider!=null: provider.shutdown()

func can_enter() -> bool:
	return not steam_requested or (provider!=null and provider.check_session() and not blocked)

func status_text() -> String:
	if not steam_requested: return "Local PC provider. No native store integration selected."
	if blocked: return "STEAM SESSION BLOCKED\n"+reason
	return "Steam client session active. App/user-scoped local saves; no cloud or server authentication."
