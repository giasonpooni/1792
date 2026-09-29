# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node
## Opt-in local observations and attributed operator reports. NEVER certifies hardware or stores.
const Storage := preload("res://platform/local_storage.gd")
const IDENTITY := "res://platform/build_identity.json"
const LIMIT := 65536
const MAX_SAMPLES := 3600
const CHECKS := {
	"controller":"Physical controller: complete interaction and menu navigation",
	"disconnect":"Unplug/replug the active controller: remains paused until Resume",
	"focus":"Switch away and back: no background input or automatic resume",
	"restart_save":"Save, exit the process, restart and Continue the same chapter",
	"readability":"Read dialogue and navigate 200% text at your actual viewing distance",
	"rendering":"Inspect movement, camera and scene rendering on this machine"}
var automated := false # Explicit code-side test injection, never a game-save value.
var transport: RefCounted=Storage.new()
var session_id := ""
var _folder := ""
var _started := 0
var _last_frame := 0
var _samples: Array[float]=[]
var _sample_cursor := 0
var _counts := {"joypad_buttons":0,"joypad_axes":0,"connections":0,"disconnections":0,"focus_losses":0,"focus_returns":0}
var _operator: Dictionary={}
var _image: Dictionary={}
var _build: Dictionary={}
var _last_result := ""

func _ready() -> void:
	session_id=Crypto.new().generate_random_bytes(12).hex_encode()
	_folder="user://1792-qualification/"+session_id+"/"
	_started=Time.get_ticks_usec();_last_frame=_started
	automated=automated or OS.has_environment("GITHUB_ACTIONS") or DisplayServer.get_name()=="headless"
	for arg in OS.get_cmdline_args():
		if arg=="--fixed-fps": automated=true
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(IDENTITY))
	_build=parsed if parsed is Dictionary else {}
	for id in CHECKS: _operator[id]="not_tested"
	Input.joy_connection_changed.connect(_connection)

func _input(event: InputEvent) -> void:
	# Aggregate only; no text/key logging, raw IDs, account names, locations or device GUIDs.
	if event is InputEventJoypadButton and event.pressed: _increment("joypad_buttons")
	elif event is InputEventJoypadMotion: _increment("joypad_axes")

func _connection(_device: int, connected: bool) -> void:
	_increment("connections" if connected else "disconnections")

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: _increment("focus_losses")
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN: _increment("focus_returns")

func _increment(key: String) -> void:
	_counts[key]=mini(100000000,int(_counts[key])+1)

func _process(_delta: float) -> void:
	var now:=Time.get_ticks_usec()
	var ms: float=float(now-_last_frame)/1000.0
	_last_frame=now
	if ms<=0 or not is_finite(ms): return
	if _samples.size()<MAX_SAMPLES: _samples.append(ms)
	else:
		_samples[_sample_cursor]=ms
		_sample_cursor=(_sample_cursor+1)%MAX_SAMPLES

func record_operator(check_id: String, result: String) -> String:
	if automated: return "Automated/headless sessions cannot record a human hardware pass or fail."
	if not CHECKS.has(check_id) or result not in ["pass","fail","not_tested"]: return "Unknown checklist response."
	_operator[check_id]=result
	return ""

func report() -> Dictionary:
	var sorted:=_samples.duplicate();sorted.sort()
	var timings: Dictionary={"sample_count":sorted.size(),"window":"last_at_most_3600_process_frames",
		"measurement":"wall-clock frame intervals including menus and focus stalls; NOT GPU timings","p50_ms":null,"p95_ms":null,"p99_ms":null}
	if not sorted.is_empty():
		for pair in [["p50_ms",0.5],["p95_ms",0.95],["p99_ms",0.99]]:
			timings[pair[0]]=sorted[clampi(int(ceil(sorted.size()*pair[1]))-1,0,sorted.size()-1)]
	var adapter:=RenderingServer.get_video_adapter_name().left(160)
	var lower:=adapter.to_lower()
	var software_hint:=false
	for hint in ["llvmpipe","softpipe","software","basic render","swiftshader"]:
		if lower.contains(hint): software_hint=true
	var renderer: Dictionary={"display_server":DisplayServer.get_name(),"adapter_name":adapter,
		"adapter_vendor":RenderingServer.get_video_adapter_vendor().left(160),
		"api_version":RenderingServer.get_video_adapter_api_version().left(160),
		"software_name_hint":software_hint,"consumer_gpu_qualified":false}
	var runtime:=get_tree().root.get_node_or_null("PlatformRuntime")
	var platform: Dictionary={"provider_id":"cg.local-pc.v1","native_client_observed":false}
	if runtime!=null and runtime.provider!=null: platform=runtime.provider.diagnostic_status()
	return {"schema":"cg.hardware-session.v1","game_id":"1792","execution_id":session_id,
		"evidence_kind":"automated_observation" if automated else "interactive_observation_and_operator_self_report",
		"source":_build.duplicate(true),"engine":Engine.get_version_info().string,"os":OS.get_name(),
		"elapsed_seconds":float(Time.get_ticks_usec()-_started)/1000000.0,
		"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],
		"renderer":renderer,"input_counts":_counts.duplicate(),"connected_pad_count":Input.get_connected_joypads().size(),
		"input_origin":"OS-delivered events may be physical, virtual or injected; not authenticated",
		"operator_results":_operator.duplicate(),"operator_evidence":"self_report_not_independently_verified",
		"frame_intervals":timings,"platform":platform,"screenshot":_image.duplicate(),
		"certified":false,"human_accessibility_study":false,"uploaded":false}

func write_report() -> String:
	if DirAccess.make_dir_recursive_absolute(_folder)!=OK: return "Cannot create local qualification folder."
	var bytes:=JSON.stringify(report(),"\t").to_utf8_buffer()
	var error: Variant=transport.write_bytes(_folder+"report.json",bytes,LIMIT)
	if not error is String or not error.is_empty():
		_last_result="Report not saved. Local provider refused the bounded write."
	else: _last_result="Saved locally: "+_folder+"report.json. Nothing uploaded."
	return _last_result

func capture_view() -> String:
	if DisplayServer.get_name()=="headless": return "No screenshot: this session is headless."
	if DirAccess.make_dir_recursive_absolute(_folder)!=OK: return "Cannot create local qualification folder."
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	if image.is_empty() or image.save_png(_folder+"view.png")!=OK: return "Screenshot was not saved."
	_image={"file":"view.png","width":image.get_width(),"height":image.get_height(),
		"sha256":FileAccess.get_sha256(_folder+"view.png"),"scope":"current_game_viewport_only"}
	return "Current game view saved locally. Export the report again to include its digest."

func text() -> String:
	var value:=report()
	var body: String="OPT-IN LOCAL HARDWARE SESSION\nNo data is uploaded. Reports include OS, renderer description, aggregate controller/focus counts and frame intervals; no text input or account IDs.\n\n"
	body+="Session: "+session_id+"\nEvidence: "+value.evidence_kind+"\n"
	body+="Renderer: "+str(value.renderer.adapter_name)+" / "+str(value.renderer.display_server)+"\n"
	body+="OS-delivered input is not proof of a physical controller. Checklist entries are your self-report, never certification.\n\n"
	for id in CHECKS: body+=CHECKS[id]+": "+str(_operator[id])+"\n\n"
	return body+_last_result
