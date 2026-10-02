# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Guard:=preload("res://presentation/service_guard.gd")
const Figure:=preload("res://youth/performance/bazaar_figure.gd")
const Gate:=preload("res://presentation/gate_passage.gd")
const Study:=preload("res://presentation/equipment_study.tscn")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		push_error("GUARD FIT FAIL: "+label)

func grip_error(guard: Node3D) -> float:
	return guard.shield.get_node("GripAnchor").global_position.distance_to(guard.figure.hands[1].global_position)

func poses(guard: Node3D) -> Array[Transform3D]:
	var result: Array[Transform3D]=[]
	for node in guard.find_children("*","Node3D",true,false): result.append(node.transform)
	return result

func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event.pressed=false
	Input.parse_input_event(event)

func run() -> void:
	var guard:=Guard.new()
	guard.build()
	guard.position=Vector3(2.40,0,-.25)
	root.add_child(guard)
	check(guard.figure.get_script()==Figure,"reuse existing articulated supporting-character figure")
	check(guard.figure.hips.size()==2 and guard.figure.knees.size()==2 and guard.figure.feet.size()==2,"guard has the shared two-leg joint hierarchy")
	check(guard.shield.get_parent()==guard.shield_socket and guard.shield_socket.get_parent()==guard.figure.elbows[1],"shield is actually parented to the supporting forearm")
	check(guard.sidearm.get_parent()==guard.hip_socket and guard.hip_socket.get_parent()==guard.figure.torso,"sidearm is actually parented to the torso socket")
	check(guard.helmet.get_parent()==guard.head_socket and guard.head_socket.get_parent()==guard.figure.head,"helmet follows the head socket")
	var feet: Array[Transform3D]=[guard.figure.feet[0].global_transform,guard.figure.feet[1].global_transform]
	var initial_shield: Transform3D=guard.shield.global_transform
	var shield_moved:=false
	for sample in [[0,0.0],[60,.35],[120,1.0],[480,.5],[Guard.MAX_TICK,1.0],[60,.35],[0,0.0]]:
		check(guard.sample_pose(sample[0],sample[1]),"sample existing tick and bounded signal pose")
		check(grip_error(guard)<.000001,"actual hand centre remains in shield grip across poses")
		check(guard.shield.global_basis.is_equal_approx(guard.shield.global_basis.orthonormalized()),"shield remains rigid through the articulated hierarchy")
		check(guard.figure.feet[0].global_transform==feet[0] and guard.figure.feet[1].global_transform==feet[1],"both planted feet remain fixed during the signal")
		check(guard.sidearm.presentation_state()=="SHEATHED","passage gesture does not draw the sword")
		var straps_joined:=guard.suspension.size()==2
		for binding in guard.suspension:
			var strap: MeshInstance3D=binding.strap
			var half: float=strap.mesh.size.y/2
			straps_joined=straps_joined and (strap.global_transform*Vector3(0,-half,0)).distance_to(binding.anchor.global_position)<.000001
			straps_joined=straps_joined and (strap.global_transform*Vector3(0,half,0)).distance_to(binding.ring.global_position)<.000001
		check(straps_joined,"both strap endpoints meet the belt anchor and actual scabbard ring")
		var clear:=true
		for mesh in guard.find_children("*","MeshInstance3D",true,false):
			for k in range(8):
				var corner: Vector3=mesh.global_transform*mesh.mesh.get_aabb().get_endpoint(k)
				clear=clear and corner.x>Gate.LANE_HALF_WIDTH and corner.y>=0
		check(clear,"all body and equipment mesh bounds clear passage and ground")
		shield_moved=shield_moved or not guard.shield.global_transform.is_equal_approx(initial_shield)
	check(shield_moved,"shield visibly follows the supporting arm")
	check(guard.shield.global_transform.is_equal_approx(initial_shield),"rewind restores exact original shield pose")
	var saved: Array[Transform3D]=poses(guard)
	var mail: Array[Transform3D]=guard.helmet.get_node("MailAventail").ring_transforms.duplicate()
	for invalid in [[-1,0.0],[Guard.MAX_TICK+1,0.0],[0,-.1],[0,1.1],[0,NAN],[0,INF]]:
		check(not guard.sample_pose(invalid[0],invalid[1]) and poses(guard)==saved and guard.helmet.get_node("MailAventail").ring_transforms==mail,"invalid pose leaves joints and mail untouched")
	var fit: Transform3D=guard.shield.transform
	guard.shield.position.x+=.1
	check(grip_error(guard)>.09,"detached shield counterexample is detected")
	guard.shield.transform=fit
	guard.rotation.y=.7
	guard.position+=Vector3(2,1,-3)
	check(grip_error(guard)<.000001,"attachment remains correct after guard world relocation and rotation")
	check(guard.find_children("*","CollisionObject3D",true,false).is_empty(),"articulated support adds no collision body")
	guard.queue_free()
	await process_frame
	var ordinary:=Figure.new()
	ordinary.build(4)
	root.add_child(ordinary)
	var headwear:=0
	for child in ordinary.head.get_children():
		if child is MeshInstance3D and child.mesh is TorusMesh: headwear+=1
	check(headwear==3,"existing bazaar figures retain their default headwear")
	ordinary.queue_free()
	await process_frame
	var study:=Study.instantiate()
	root.add_child(study)
	await process_frame
	await key(KEY_G)
	check(study.guard_view and study.guard.visible and not study.helmet.visible and not study.service.visible,"G opens native equipped-guard inspection")
	study.draw_slider.grab_focus()
	await key(KEY_END)
	check(study.guard.signal_amount==1.0 and study.pose_label.text=="Signal","keyboard slider drives the articulated guard signal")
	check(grip_error(study.guard)<.000001,"interactive signal retains the physical hand/grip fit")
	await key(KEY_H)
	check(study.close_view and not study.guard_view and not study.guard_toggle.button_pressed,"helmet and guard views are mutually exclusive")
	await key(KEY_G)
	check(study.guard_view and not study.close_view and not study.helmet_toggle.button_pressed,"guard view replaces helmet close-up")
	await key(KEY_R)
	check(study.guard.signal_amount==0 and study.mail_slider.value==0 and study.display_root.rotation==Vector3.ZERO,"R restores guard pose, mail tick and display turn")
	await key(KEY_G)
	check(not study.guard_view and study.service.visible and study.shield.visible,"G returns to the existing equipment overview")
	study.queue_free()
	await process_frame
	print("SERVICE_GUARD_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
