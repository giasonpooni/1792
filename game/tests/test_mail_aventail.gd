# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Mail:=preload("res://presentation/mail_aventail.gd")
const Defence:=preload("res://presentation/service_defence.gd")
const Gate:=preload("res://presentation/gate_passage.gd")
const Study:=preload("res://presentation/equipment_study.tscn")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("MAIL FAIL: "+label)

func run() -> void:
	var helmet:=Defence.helmet()
	root.add_child(helmet)
	var mail: Node3D=helmet.get_node("MailAventail")
	var batch: MultiMesh=mail.links.multimesh
	var shell: Transform3D=helmet.get_node("RigidShell").transform
	check(batch.instance_count==512,"bounded 512 rigid ring instances")
	check(mail.get_child_count()==1 and mail.links is MultiMeshInstance3D,"one batched ring draw rather than hundreds of scene nodes")
	check(batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<512,"one shared low-poly ring mesh")
	var first: Array[Transform3D]=mail.ring_transforms.duplicate()
	var ring_bound: AABB=batch.mesh.get_aabb()
	var observed_motion:=false
	for strength in [0.0,.2,1.0]:
		for tick in [0,30,120,240,360,479,480,901,Mail.MAX_TICK,30,0]:
			check(mail.sample_tick(tick,strength),"admit bounded source tick and amplitude")
			var rigid:=true
			var lengths:=true
			var pinned:=true
			var bounded:=true
			for column in range(Mail.COLUMNS):
				var previous:=Vector3.ZERO
				for row in range(Mail.ROWS):
					var pose: Transform3D=mail.ring_transforms[column*Mail.ROWS+row]
					rigid=rigid and pose.basis.is_equal_approx(pose.basis.orthonormalized()) and is_equal_approx(pose.basis.determinant(),1.0)
					if row==0: pinned=pinned and pose.origin.is_equal_approx(Mail.anchor(column)) and pose.basis==first[column*Mail.ROWS].basis
					else: lengths=lengths and absf(pose.origin.distance_to(previous)-Mail.PITCH)<.000001
					previous=pose.origin
					for k in range(8): bounded=bounded and Mail.BOUNDS.has_point(pose*ring_bound.get_endpoint(k))
			check(rigid,"all ring transforms preserve length, angles and handedness")
			check(lengths,"all strip segments retain fixed length")
			check(pinned,"upper ring row stays on helmet anchors")
			check(bounded,"all actual transformed ring bounds fit visibility envelope")
			check(helmet.get_node("RigidShell").transform==shell,"mail motion never deforms the rigid shell")
			if strength>0 and tick==120: observed_motion=observed_motion or mail.ring_transforms!=first
	check(observed_motion,"articulated lower rows visibly change")
	mail.sample_tick(60,1.0)
	var replay: Array[Transform3D]=mail.ring_transforms.duplicate()
	mail.sample_tick(479,.2)
	mail.sample_tick(60,1.0)
	check(mail.ring_transforms==replay,"rewind recovers identical ring transforms")
	await process_frame
	await process_frame
	check(mail.ring_transforms==replay,"render frames alone do not advance the mail")
	for invalid in [[-1,1.0],[Mail.MAX_TICK+1,1.0],[60,-.1],[60,1.1],[60,NAN],[60,INF]]:
		check(not mail.sample_tick(invalid[0],invalid[1]) and mail.ring_transforms==replay,"invalid sampling is atomic and preserves the last pose")
	check(helmet.find_children("*","CollisionObject3D",true,false).is_empty(),"mail adds no physics body")
	helmet.queue_free()
	await process_frame
	var gate:=Gate.new()
	gate.build(Vector3(3,0,-8))
	root.add_child(gate)
	for tick in [0,120,240,360,480]:
		gate.sample(tick,Vector3.ZERO,true,"riding")
		batch=gate.guard_mail.links.multimesh
		var clear:=true
		for i in range(batch.instance_count):
			var pose: Transform3D=gate.guard_mail.links.global_transform*gate.guard_mail.ring_transforms[i]
			for k in range(8):
				var p: Vector3=gate.to_local(pose*ring_bound.get_endpoint(k))
				clear=clear and p.x>Gate.LANE_HALF_WIDTH and p.y>0
		check(clear,"animated guard ring geometry clears the passage and ground")
	check(gate.records.size()==7,"mail remains part of existing guard, with seven gate records")
	gate.queue_free()
	await process_frame
	var study:=Study.instantiate()
	root.add_child(study)
	await process_frame
	study.helmet_toggle.button_pressed=true
	check(study.close_view and not study.service.visible and study.helmet.visible,"close-up isolates the helmet while retaining the same asset")
	study.mail_slider.grab_focus()
	var key:=InputEventKey.new()
	key.keycode=KEY_RIGHT
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key.pressed=false
	Input.parse_input_event(key)
	check(study.mail_slider.value==1 and study.helmet.get_node("MailAventail")._last_tick==1,"keyboard scrub is connected to native mail sampling")
	study.turn_slider.value=120
	check(study.camera.global_position.distance_to(study.helmet.global_position)<1,"close camera follows the turning display")
	key=InputEventKey.new()
	key.keycode=KEY_R
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key.pressed=false
	Input.parse_input_event(key)
	check(study.mail_slider.value==0 and study.helmet.get_node("MailAventail")._last_tick==0,"reset returns the mail to tick zero")
	study.helmet_toggle.button_pressed=false
	check(study.service.visible and study.shield.visible,"overview restores original equipment")
	study.queue_free()
	await process_frame
	print("MAIL_AVENTAIL_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
