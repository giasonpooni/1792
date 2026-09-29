# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Fixed title-owned build/probe. Test assertions are evaluated by the NET host.
const Scene := preload("res://workcells/smith_scene.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const Economy := preload("res://territory/misl_rules.gd")
# This file is created by the build stage, not a checked-in Resource dependency.
const COMPILED_NAME := "smith.scn"
var compiled_path: String = "res://" + COMPILED_NAME
var mode := ""
var report: Dictionary={}

func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1 or not args[0] in ["build","test","smoke"]: quit(2);return
	mode=args[0];run.call_deferred()

func own_descendants(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner=owner_node
		own_descendants(child,owner_node)

func inventory(node: Node) -> Dictionary:
	var counts={"nodes":0,"meshes":0,"triangles":0,"collision_shapes":0,"materials":0,"colliders":[],"workshop_extent":[]}
	var materials: Dictionary={}
	var pending: Array[Node]=[node]
	while not pending.is_empty():
		var current: Node=pending.pop_back();counts.nodes+=1
		pending.append_array(current.get_children())
		if current is CollisionShape3D:
			counts.collision_shapes+=1
			var at: Vector3=current.global_position
			var size: Vector3=current.shape.size if current.shape is BoxShape3D else Vector3.ZERO
			counts.colliders.append([at.x,at.y,at.z,size.x,size.y,size.z])
		if current is MeshInstance3D and current.mesh!=null:
			counts.meshes+=1
			for surface in range(current.mesh.get_surface_count()):
				var arrays: Array=current.mesh.surface_get_arrays(surface)
				var n: int=arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size()
				counts.triangles+=n/3
			if current.material_override!=null: materials[current.material_override.get_instance_id()]=true
	var bounds: AABB
	var first:=true
	for mesh in node.get_node("Workshop").find_children("*","MeshInstance3D",true,false):
		var local_bounds: AABB=mesh.global_transform*mesh.get_aabb()
		bounds=local_bounds if first else bounds.merge(local_bounds);first=false
	counts.workshop_extent=[bounds.size.x,bounds.size.y,bounds.size.z]
	counts.materials=materials.size()
	return counts

func summary(ledger: Dictionary) -> Dictionary:
	return {"phase":Craft.phase(ledger),"treasury":ledger.treasury,"purse":ledger.purse,"timber":ledger.stock.timber,"tools":ledger.stock.tools,"favor":ledger.favor}

func rules_probe() -> Dictionary:
	var ledger: Dictionary=Economy.initial();var stages: Array=[];var errors: Array=[]
	for item in [["reserve",0],["start",10]]:
		errors.append(Craft.apply(ledger,"smith."+item[0],str(item[1])));stages.append(summary(ledger))
	var before: Dictionary=ledger.duplicate(true)
	var early: String=Craft.apply(ledger,"smith.ready","609")
	var early_atomic: bool=ledger==before
	errors.append(Craft.apply(ledger,"smith.ready","610"));stages.append(summary(ledger))
	var restored: Dictionary=JSON.parse_string(JSON.stringify(ledger))
	var roundtrip: bool=Economy._equal(ledger,restored)
	ledger=restored
	for item in [["collect",611],["deliver",620]]:
		errors.append(Craft.apply(ledger,"smith."+item[0],str(item[1])));stages.append(summary(ledger))
	before=ledger.duplicate(true)
	var duplicate: String=Craft.apply(ledger,"smith.deliver","621")
	var duplicate_atomic: bool=Economy._equal(ledger,before)
	var refund: Dictionary=Economy.initial()
	var refund_errors: Array=[Craft.apply(refund,"smith.reserve","0"),Craft.apply(refund,"smith.refund","1")]
	return {"stages":stages,"errors":errors,"early_refused":not early.is_empty(),"early_atomic":early_atomic,
		"roundtrip_equal":roundtrip,"duplicate_refused":not duplicate.is_empty(),"duplicate_atomic":duplicate_atomic,
		"refund_errors":refund_errors,"refund":summary(refund)}

func snapshot_pose(scene: Node3D) -> Dictionary:
	var station=scene.get_node("Workshop")
	return {"tick":scene.tick,"phase":Craft.phase(scene.ledger),"arm_x":station.smith_arm.rotation.x,
		"coal":station.coal.visible,"finished":station.finished.visible,"carried":station.carried.visible}

func capture(scene: Node3D, id: String) -> Dictionary:
	scene.lighting(id=="evening")
	for _i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	if image==null or image.is_empty() or image.save_png("res://"+id+".png")!=OK:
		push_error("Native preview failed");quit(3);return {}
	var camera: Camera3D=scene.get_node("Camera")
	var at: Vector3=camera.position;var angles: Vector3=camera.rotation
	return {"id":id,"pose":snapshot_pose(scene),"width":image.get_width(),"height":image.get_height(),
		"image_sha256":"sha256:"+FileAccess.get_sha256("res://"+id+".png"),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"video_adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"camera_transform":[at.x,at.y,at.z,angles.x,angles.y,angles.z],"camera_kind":"fixed_asset_inspection_not_player_camera"}

func run() -> void:
	report={"schema":"1792.smith-workcell-observations.v1","mode":mode,"engine":Engine.get_version_info().string}
	var scene: Node3D
	if mode=="build": scene=Scene.new()
	else:
		var packed: PackedScene=load(compiled_path)
		if packed==null: quit(4);return
		scene=packed.instantiate()
	report["loaded_baked_scene"]=mode=="build" or (scene.baked and scene.has_node("Workshop"))
	root.add_child(scene);scene.running=false;scene.set_physics_process(false)
	report["inventory"]=inventory(scene)
	if mode=="build":
		own_descendants(scene,scene)
		var packed:=PackedScene.new()
		if packed.pack(scene)!=OK or ResourceSaver.save(packed,compiled_path)!=OK: quit(5);return
		report["compiled_scene_sha256"]="sha256:"+FileAccess.get_sha256(compiled_path)
	else:
		report["rules"]=rules_probe()
		report["scene_actions"]=[scene.action("reserve"),scene.action("start")]
		for _i in range(36): scene.step()
		report["pose"]=snapshot_pose(scene)
		if mode=="test":
			root.size=Vector2i(640,360)
			report["captures"]=[await capture(scene,"daylight"),await capture(scene,"evening")]
		else:
			for _i in range(564): scene.step()
			report["completion_phase"]=Craft.phase(scene.ledger)
	var output:=OS.get_environment("SMITH_REPORT")
	if output.is_empty():
		push_error("An explicit SMITH_REPORT output path is required");quit(6);return
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report));file.close()
	scene.queue_free();quit(0)
