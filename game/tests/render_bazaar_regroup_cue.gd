# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_bazaar_regroup_cue.gd"
## Inspection-only camera over an explicit spatial fixture, never an in-game cutaway.
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var home: Node3D=await waiting_fixture();var scene=home.get_node("ChildhoodChapter")
	var camera:=Camera3D.new();camera.fov=44;home.add_child(camera)
	var center: Vector3=scene.youths[3].global_position+Vector3.UP
	camera.global_position=center+Vector3(.5,.8,-4.8);camera.look_at(center);camera.current=true
	var label_layer:=CanvasLayer.new();label_layer.layer=30;home.add_child(label_layer)
	var label:=Label.new();label.position=Vector2(24,24);label.add_theme_font_size_override("font_size",19)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);label_layer.add_child(label)
	var target:="user://bazaar-regroup-images"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target))
	for view in ["waiting","together"]:
		if view=="together": scene.youths[4].global_position=R.REGROUP+Vector3(1,0,1)
		scene.bazaar_performance.sample(false)
		label.text="1792 / BAZAAR REGROUP\n"+("Wait for Jiva" if view=="waiting" else "The hand lowers when all are close")+"\nInspection fixture · original prototype art"
		await frames(3);await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		check(not image.is_empty() and image.save_png(target.path_join(view+".png"))==OK,"capture "+view)
	print("BAZAAR_REGROUP_CUE_RENDER: 2 captures; %d failures"%failed)
	home.queue_free();await frames(3);quit(1 if failed else 0)
