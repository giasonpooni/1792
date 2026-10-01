# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit research/qualification presentation fixtures, not a historical-map showcase.
const Launch := preload("res://childhood/home_launch.gd")
const Exterior := preload("res://geography/sacred_exterior.gd")
var captures := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int=8) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func capture(name: String, controls: Array=[]) -> void:
	await frames();await RenderingServer.frame_post_draw
	var viewport:=Rect2(Vector2.ZERO,Vector2(root.size))
	for control in controls:
		if not viewport.encloses(control.get_global_rect()):
			failures+=1;push_error("Atlas UI outside viewport: "+str(control.get_global_rect()));return
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty() or image.save_png("user://historical-world-"+name+".png")!=OK:
		failures+=1;return
	captures+=1
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var home:=Launch.make_world();root.add_child(home);await frames()
	var chapter=home.get_node("ChildhoodChapter");chapter.open_atlas();await frames()
	chapter.atlas_panel.select_place("rohtas");chapter.atlas_panel.slider.value=1792
	await capture("atlas-wide",[chapter.atlas_panel.panel,chapter.atlas_panel.close_button,chapter.atlas_panel.detail])
	root.size=Vector2i(800,450);chapter.atlas_panel.slider.value=1420
	await capture("atlas-compact",[chapter.atlas_panel.panel,chapter.atlas_panel.close_button,chapter.atlas_panel.detail])
	root.remove_child(home);home.queue_free();await frames()
	root.size=Vector2i(1280,720)
	var world:=Node3D.new();root.add_child(world)
	var exterior:=Exterior.new();world.add_child(exterior)
	var definition: Dictionary={"id":"fixture","importance":3,"from":1780,"until":1800,"interior_enterable":false,"figures_embodied":false,"classification":"synthetic:qualification","evidence_scope":"Authored fixture only","frame_id":"qualification-local-metre","size_m":[10,6,10],"prayer_at_m":[0,0,8]}
	if not exterior.build(definition,true).is_empty(): failures+=1
	var mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(36,36);mesh.mesh=plane;world.add_child(mesh)
	var material:=StandardMaterial3D.new();material.albedo_color=Color("5b675c");mesh.material_override=material
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.light_energy=1.2;world.add_child(light)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(14,12,19);camera.look_at(Vector3(0,2,3));camera.current=true
	var layer:=CanvasLayer.new();world.add_child(layer)
	var label:=Label.new();label.position=Vector2(24,24);label.text="EXTERIOR ACCESS QUALIFICATION - SYNTHETIC GEOMETRY\n10 x 6 x 10 metres; solid non-enterable volume. Exterior prayer point.\nNo actual religious building, figure, historical placement or sacred-importance ranking."
	label.add_theme_font_size_override("font_size",20);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_y",2);layer.add_child(label)
	await capture("exterior-fixture",[label])
	root.remove_child(world);world.queue_free();await frames()
	print("WORLD_ATLAS_RENDER: %d captures; %d failures"%[captures,failures]);quit(1 if failures else 0)
