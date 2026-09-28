# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Same 180 physics-tick command stream at multiple render schedules.
const Course := preload("res://mechanics/course.gd")
const Motion := preload("res://player/locomotion_rules.gd")
var course: Node3D
var tick := 0
var trace: Array=[]
var label := ""
func _initialize() -> void: start.call_deferred()
func start() -> void:
	label=OS.get_environment("LOCOMOTION_RATE_LABEL")
	if label not in ["30","60","144"]: push_error("Declare the render-schedule label.");quit(1);return
	course=Course.new();root.add_child(course)
	# One declared initial fixture. No later injected pose/progress.
	course.avatar.global_position=Vector3(-5,0.04,10)
	course.avatar.set_physics_process(false);course.set_physics_process(false)
	await process_frame
	physics_frame.connect(step)
func step() -> void:
	tick+=1
	var stick:=Vector2.ZERO;var sprint:=false
	if tick>=13 and tick<=42: stick=Vector2(0,-0.5)
	elif tick>=43 and tick<=82: stick=Vector2(0,-1);sprint=true
	elif tick>=83 and tick<=110: stick=Vector2(1,0)
	var error: String=course.avatar.step_motion(1.0/60,stick,sprint,tick==62,false)
	if not error.is_empty(): push_error(error);quit(1);return
	trace.append({"tick":tick,"position":Motion.array(course.avatar.global_position),"velocity":Motion.array(course.avatar.velocity),"mode":course.avatar.motion_mode_name})
	if tick==180:
		physics_frame.disconnect(step)
		var encoded:=JSON.stringify(trace)
		var f:=FileAccess.open("user://locomotion-rate-"+label+".json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"operation_id":"locomotion-rate-replay.v1","render_schedule_fps":int(label),"physics_hz":Engine.physics_ticks_per_second,"motor_digest":course.motor_digest(),"geometry_digest":course.geometry_digest(),"trace_digest":encoded.sha256_text(),"trace":trace},"\t"));f.close()
		print("LOCOMOTION_RATE_FILE: ",ProjectSettings.globalize_path("user://locomotion-rate-"+label+".json"))
		print("LOCOMOTION_RATE: ",label," / 180 ticks / ",encoded.sha256_text())
		quit(0)
