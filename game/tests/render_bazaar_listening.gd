# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/render_bazaar_direction.gd"
## Close inspection cameras over recorded real journey poses, not a cinematic in the game.
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	output="user://bazaar-listening-images"
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bazaar-direction.json"))
	if not data is Dictionary or data.get("failed")!=0:
		push_error("Successful recorded journey required for listening views");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	home=Launch.make_world();root.add_child(home);scene=home.get_node("ChildhoodChapter")
	scene.set_physics_process(false);scene.avatar.set_physics_process(false);await frames(8)
	var inspection:=Camera3D.new();inspection.fov=32;home.add_child(inspection)
	var panel:=CanvasLayer.new();panel.layer=30;root.add_child(panel)
	var label:=Label.new();label.position=Vector2(24,24);label.add_theme_font_size_override("font_size",19)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);panel.add_child(label)
	var views: Array=[]
	for spec in [[3,"Mela","listener-mela"],[4,"Jiva","listener-jiva"],[0,"Challenger","windup"]]:
		var key: String=spec[2] if data.snapshots.has(spec[2]) else "friends-walking"
		apply(data.snapshots[key])
		var figure: Node3D=scene.bazaar_performance.figures[spec[0]]
		var point: Vector3=figure.head.global_position+Vector3.UP*.07
		inspection.global_position=point+figure.global_basis*Vector3(.28,.12,-1.20)
		inspection.look_at(point,Vector3.UP);inspection.current=true
		scene.bazaar_performance.canvas.hide();scene._hud.hide();scene._caption.hide();scene._narrator_label.hide()
		label.text="1792 / CHARACTER PERFORMANCE\n"+spec[1]+" — observed "+key+" pose\nInspection camera · prototype art · no voice performance"
		await frames(3);await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		var name: String=String(spec[1]).to_lower()+".png"
		check(not image.is_empty() and image.save_png(output.path_join(name))==OK,"captured "+name)
		views.append({"file":name,"source_snapshot":key,"tick":data.snapshots[key].tick,"camera":"inspection, not player controlled","attention":data.snapshots[key].attention})
	# The ordinary gameplay view is retained separately, with its real camera unchanged.
	inspection.current=false;panel.hide()
	apply(data.snapshots["checked"])
	# The original player camera is discovered by its node type; do not change its transform.
	for camera in scene.avatar.find_children("*","Camera3D",true,false): camera.current=true
	await capture("player-view")
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":"1792.listening-views.v1","failed":failed,"views":views,"source":"retained actual bazaar journeys","additional_player_view":"player-view.png"},"\t",true,true));file.close()
	print("BAZAAR_LISTENING_RENDER: 4 captures; %d failures"%failed)
	home.queue_free();panel.queue_free();await frames(2);quit(1 if failed else 0)
