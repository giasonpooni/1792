# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Invoked by the offline runner in separate producer and consumer processes.
const Course := preload("res://mechanics/course.gd")
const M := preload("res://player/locomotion_rules.gd")
var course: Node3D
func _initialize() -> void: run.call_deferred()
func fail(message: String) -> void: push_error(message);quit(1)
func step() -> void:
	# CharacterBody3D.move_and_slide obtains its integration delta from the
	# engine physics frame; each command must run in that frame, not render time.
	await physics_frame
	var error: String=course.avatar.step_motion(1.0/60,Vector2.ZERO,false)
	if not error.is_empty(): fail(error)
	course.tick+=1
func run() -> void:
	var mode:=OS.get_environment("CONTACT_RESTART_MODE")
	var kind:=OS.get_environment("CONTACT_RESTART_KIND")
	var index_text:=OS.get_environment("CONTACT_RESTART_SEGMENT")
	var rate:=OS.get_environment("CONTACT_RESTART_RATE")
	if mode not in ["produce","resume"] or kind not in ["vault","mantle"] or index_text not in ["0","1","2"] or rate not in ["30","60","144"]:
		fail("Declare producer/consumer, traversal kind, segment and render schedule.");return
	var key:=kind+"-"+index_text
	course=Course.new();course.save_path="user://test-contact-restart-"+key+".json";root.add_child(course)
	course.set_physics_process(false);course.set_paused(true);course.avatar.input_enabled=true
	await physics_frame;await process_frame
	if mode=="produce":
		# Explicit initial setup only, followed by the actual shared motor.
		course.avatar.global_position=Vector3(0,.04,.95) if kind=="vault" else Vector3(0,.04,-2.7)
		course.avatar.velocity=Vector3.ZERO;course.avatar._grounded=false
		for _i in range(10): await step()
		await physics_frame
		var error: String=course.avatar.step_motion(1.0/60,Vector2.ZERO,false,false,true);course.tick+=1
		if not error.is_empty(): fail(error);return
		for _i in range(120):
			if course.avatar._route.is_empty() or course.avatar._route_index==int(index_text): break
			await step()
		if course.avatar._route.is_empty(): fail("Traversal completed before requested save segment.");return
		if not course.save_course().begins_with("Course motion saved"): fail("Producer could not save actual contact.");return
	else:
		var result: String=course.load_course()
		if not result.begins_with("Course motion restored"): fail(result);return
		if course.avatar._route.is_empty(): fail("Consumer silently discarded remaining traversal.");return
	var start: Dictionary=course.snapshot()
	var trace: Array=[]
	for _i in range(80):
		await step();trace.append(course.snapshot())
	var report: Dictionary={"operation_id":"traversal-process-resume.v1","mode":mode,"kind":kind,"segment":int(index_text),"render_schedule_fps":int(rate),"engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,"start":start,"trace":trace,"completed":course.avatar._route.is_empty() and course.avatar._grounded}
	var path: String="user://contact-restart-"+key+"-"+mode+"-"+rate+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CONTACT_RESTART_FILE: ",ProjectSettings.globalize_path(path))
	print("CONTACT_RESTART: ",key," / ",mode," / 80 ticks")
	quit(0)
