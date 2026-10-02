# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Sword:=preload("res://presentation/service_sword.gd")
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
		push_error("EQUIPMENT FAIL: "+label)

func run() -> void:
	var item:=Sword.new()
	item.build()
	root.add_child(item)
	var blade: MeshInstance3D=item.sword.get_node("Blade")
	var original_mesh:=blade.mesh
	var original_sheath:=item.scabbard.transform
	var original_hilt: Transform3D=item.sword.get_node("Grip").transform
	check(item.scabbard.get_parent()==item and item.sword.get_parent()==item,"blade/hilt and scabbard have independent attachment roots")
	check(item.scabbard.has_node("SuspensionRing0") and item.scabbard.has_node("SuspensionRing1"),"scabbard includes both suspension fittings")
	check(blade.mesh.get_aabb().size.y>.70 and blade.mesh.get_aabb().size.z>.30,"blade has authored length and curved envelope")
	for fraction in [0.0,.25,.5,.75,1.0,.5,0.0]:
		check(item.sample_draw(fraction),"admit finite reversible draw pose")
		check(item.scabbard.transform==original_sheath,"scabbard remains attached during extraction and return")
		check(blade.mesh==original_mesh and blade.visible,"same blade mesh retained through every phase")
		check(item.sword.get_node("Grip").transform==original_hilt,"hilt remains rigidly attached to blade")
		# A blade segment still inside the sheath lies on the original curved path.
		var turn: float=(Sword.ARC+.06)*fraction
		if turn<Sword.ARC:
			var remaining: float=(turn+Sword.ARC)/2
			var actual: Vector3=item.sword.transform*Sword.centreline(remaining)
			check(actual.distance_to(Sword.centreline(remaining-turn))<.000001,"partially extracted blade follows sheath curvature")
	check(item.sword.transform==Transform3D.IDENTITY and item.presentation_state()=="SHEATHED","reverse scrub returns exact initial transform")
	item.sample_draw(1.0)
	check(item.presentation_state()=="DRAWN","draw endpoint is explicit")
	for i in range(41):
		check((item.sword.transform*Sword.centreline(Sword.ARC*i/40.0)).y>.04,"fully drawn blade centreline clears throat")
	var before: Transform3D=item.sword.transform
	for invalid in [-.01,1.01,NAN,INF,-INF]:
		check(not item.sample_draw(invalid),"invalid draw parameter refused")
		check(item.sword.transform==before and item.fraction==1.0,"refusal leaves existing presentation untouched")
	var decorated:=Sword.new()
	decorated.build(true)
	root.add_child(decorated)
	check(decorated.sword.get_node("Blade").mesh.get_aabb()==blade.mesh.get_aabb(),"fittings do not alter blade geometry")
	var shield:=Defence.shield()
	root.add_child(shield)
	check(shield.find_children("Boss*","MeshInstance3D",true,false).size()==4,"four separate shield bosses")
	check(shield.get_node("DishedShell").mesh.get_aabb().size.z>.05,"shield is a dish with depth")
	check(shield.find_children("BackGrip*","MeshInstance3D",true,false).size()==2,"shield has independent back grips")
	var helmet:=Defence.helmet()
	root.add_child(helmet)
	check(helmet.has_node("RigidShell") and helmet.has_node("Finial"),"helmet shell and finial are separate rigid components")
	var shell_arrays: Array=helmet.get_node("RigidShell").mesh.surface_get_arrays(0)
	var outward:=true
	for i in range(shell_arrays[Mesh.ARRAY_VERTEX].size()):
		outward=outward and shell_arrays[Mesh.ARRAY_VERTEX][i].dot(shell_arrays[Mesh.ARRAY_NORMAL][i])>0
	check(outward,"helmet shell normals face outward so the front remains opaque")
	var passage:=Gate.new()
	passage.build(Vector3.ZERO)
	root.add_child(passage)
	var guard: Node3D=passage.guard_root
	var attached: Node3D=guard.sidearm
	var attachments: Array[Transform3D]=[]
	for part in [guard.sidearm,guard.shield,guard.helmet]:
		attachments.append(part.transform)
	check(attachments.size()==3 and passage.records.size()==7,"equipment attaches to the same seven-record passage")
	for phase in ["riding","caught"]:
		for mounted in [false,true]:
			passage.sample(460,Vector3.ZERO,mounted,phase)
			var index:=0
			for part in [guard.sidearm,guard.shield,guard.helmet]:
				check(part.transform==attachments[index],"equipment retains its socket-local fit during approach/caught choreography")
				index+=1
	check(attached.presentation_state()=="SHEATHED","production guard retains sheathed equipment")
	for part in [attached,guard.shield,guard.helmet]:
		for mesh in part.find_children("*","MeshInstance3D",true,false):
			var bounds: AABB=mesh.mesh.get_aabb()
			var clear:=true
			for k in range(8):
				var corner: Vector3=mesh.global_transform*bounds.get_endpoint(k)
				clear=clear and corner.x>Gate.LANE_HALF_WIDTH and corner.y>=0
			check(clear,"actual attached mesh bound remains outside passage and above ground: "+str(mesh.name))
	for part in [item,decorated,shield,helmet,passage]:
		check(part.find_children("*","CollisionObject3D",true,false).is_empty() and part.find_children("*","NavigationRegion3D",true,false).is_empty(),"equipment does not supply collision or navigation authority")
		part.queue_free()
	await process_frame
	var study:=Study.instantiate()
	root.add_child(study)
	await process_frame
	study.draw_slider.grab_focus()
	var key:=InputEventKey.new()
	key.keycode=KEY_END
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key.pressed=false
	Input.parse_input_event(key)
	check(study.service.fraction==1.0 and study.fitted.fraction==1.0,"keyboard slider input drives both native sword poses")
	study.turn_slider.value=35
	check(is_equal_approx(study.display_root.rotation.y,deg_to_rad(35.0)),"turn control rotates shared presentation")
	key=InputEventKey.new()
	key.keycode=KEY_R
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key.pressed=false
	Input.parse_input_event(key)
	check(study.service.fraction==0 and study.display_root.rotation==Vector3.ZERO,"actual reset input restores sheathed view")
	study.queue_free()
	await process_frame
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(800,450)
	var menu: Control=load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	for _i in range(3): await process_frame
	var scroll: ScrollContainer=menu.find_children("*","ScrollContainer",true,false)[0]
	var buttons: Array[Node]=menu.find_children("*","Button",true,false)
	var equipment_button: Button
	for destination in ["res://world/home_territory.tscn","res://world/political_home.tscn",
		"res://world/command_sandbox.tscn","res://world/house_sandbox.tscn",
		"res://mechanics/course.tscn","res://presentation/equipment_study.tscn"]:
		var matches: Array[Node]=buttons.filter(func(button: Node) -> bool:
			return button.get_meta("destination_scene", "")==destination)
		check(matches.size()==1,"existing menu destination remains unique: "+destination)
		if destination=="res://presentation/equipment_study.tscn" and matches.size()==1:
			equipment_button=matches[0] as Button
	if is_instance_valid(equipment_button):
		scroll.ensure_control_visible(equipment_button)
		await process_frame
		check(scroll.get_global_rect().encloses(equipment_button.get_global_rect()),"equipment entry remains fully reachable at 800 by 450")
	menu.queue_free()
	await process_frame
	print("SERVICE_EQUIPMENT_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
