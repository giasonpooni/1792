# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Diagnostic views of the actual composed Home, not gameplay-camera or survey evidence.
const Launch := preload("res://childhood/home_launch.gd")
var failed := 0
var records: Array[Dictionary] = []
var chapter: Node3D
var camera: Camera3D
var caption: Label
var output := ""

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok: failed += 1; push_error("ECOLOGY RENDER: " + label)
func digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()
func frames(n: int = 3) -> void:
	for _i in range(n): await process_frame
	await RenderingServer.frame_post_draw

func capture(id: String, season: String, at: Vector3, target: Vector3, title: String, fov: float = 49.0) -> void:
	var before: Dictionary = chapter.model.snapshot()
	check(chapter.art.ecology.set_season(season).is_empty(), "set season")
	camera.position = at
	camera.fov = fov
	camera.look_at(target)
	camera.make_current()
	caption.text = title + "\n" + season.capitalize() + " visual study · authored exterior scenery · gameplay unchanged"
	await frames(2)
	var pixels := root.get_texture().get_image()
	pixels.convert(Image.FORMAT_RGBA8)
	var filename := id + ".png"
	check(pixels.save_png(output.path_join(filename)) == OK, "capture " + filename)
	check(chapter.model.snapshot() == before, "state frozen during capture")
	records.append({"id":id,"season":season,"file":filename,"png_sha256":FileAccess.get_sha256(output.path_join(filename)),"rgba_sha256":digest(pixels.get_data()),"width":pixels.get_width(),"height":pixels.get_height(),"camera_position":[at.x,at.y,at.z],"target":[target.x,target.y,target.z],"camera_kind":"diagnostic_inspection","tick":int(chapter.model.progress().tick),"state_unchanged":chapter.model.snapshot()==before,"catalog_sha256":chapter.art.ecology.catalog.digest})

func run() -> void:
	output = OS.get_environment("ECOLOGY_CAPTURE_OUTPUT")
	if output.is_empty(): push_error("ECOLOGY_CAPTURE_OUTPUT is required."); quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280,720)
	var home := Launch.make_world()
	root.add_child(home)
	chapter = home.get_node("ChildhoodChapter")
	await frames(8)
	chapter.open_art_study()
	for node in home.find_children("*","Node",true,false):
		node.set_physics_process(false)
		node.set_process(false)
		if node is CanvasLayer: node.hide()
		if node is Label3D: node.hide()
	chapter.art.set_preset("golden_hour")
	camera = Camera3D.new()
	camera.far = 230
	home.add_child(camera)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(26,24)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(caption)
	await capture("mosaic-dry","dry",Vector3(95,37,83),Vector3(44,0,20),"1792 · Gujranwala ecological mosaic",58)
	await capture("mosaic-monsoon","monsoon",Vector3(95,37,83),Vector3(44,0,20),"1792 · Gujranwala ecological mosaic",58)
	await capture("cultivated-margin","dry",Vector3(76,9,37),Vector3(58,.7,21),"Cultivated settlement edge",56)
	await capture("grazing-scrub","dry",Vector3(64,7,-7),Vector3(48,.6,-25),"Grazing country · patchy grass and thorn scrub",58)
	await capture("riverine-thicket","monsoon",Vector3(76,7,50),Vector3(58,1,43),"Riverine thicket · regional habitat analogue",60)
	await capture("wetland-dry","dry",Vector3(57,7,66),Vector3(43,.2,52),"Seasonal wetland margin",53)
	await capture("wetland-monsoon","monsoon",Vector3(57,7,66),Vector3(43,.2,52),"Seasonal wetland margin",53)
	await capture("wetland-receding","receding",Vector3(57,7,66),Vector3(43,.2,52),"Seasonal wetland margin",53)
	var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
	check(file != null,"capture manifest writable")
	if file:
		file.store_string(JSON.stringify({"schema":"1792.ecology-captures.v1","operation_id":"1792.ecology-visual-study.v1","execution_id":OS.get_environment("ECOLOGY_EXECUTION_ID"),"source_commit":OS.get_environment("ECOLOGY_SOURCE_COMMIT"),"captures":records,"failures":failed,"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"historical_authentication":false,"hardware_performance_qualified":false},"\t",true,true))
		file.close()
	print("PUNJAB_ECOLOGY_RENDER: %d captures; %d failures" % [records.size(),failed])
	home.queue_free()
	overlay.queue_free()
	await process_frame
	quit(1 if failed else 0)
