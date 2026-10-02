# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/render_gujranwala_beauty.gd"
## Paired inspection views with only the daily-detail layer changed.

func run() -> void:
	output_dir = "user://gujranwala-daily-detail-images"
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	home = Launch.make_world()
	root.add_child(home)
	scene = home.get_node("ChildhoodChapter")
	await frames(8)
	# Freeze script callbacks while retaining the same live collider composition.
	for node in [home] + home.find_children("*", "Node", true, false):
		node.set_process(false)
		node.set_physics_process(false)
	var initial: Dictionary = scene.model.snapshot()
	camera = Camera3D.new()
	camera.name = "DailyDetailInspectionCamera"
	camera.far = 180.0
	home.add_child(camera)
	var views: Array = [
		["door", Vector3(-7.5, 1.60, 8.70), Vector3(-6.375, 1.30, 11.53), 45.0],
		["market", Vector3(-24.0, 2.2, -14.5), Vector3(-24.0, 1.30, -17.8), 58.0],
		["well", Vector3(27.6, 3.6, 11.4), Vector3(24, 1.72, 15), 52.0]
	]
	for view in views:
		for detail_enabled in [false, true]:
			scene.art.daily_detail.set_enabled(detail_enabled)
			await capture(view[0]+("-detail" if detail_enabled else "-baseline"), "daylight", view[1], view[2], view[3])
			var record: Dictionary = records.back()
			record["daily_detail_enabled"] = scene.art.daily_detail.is_visible_in_tree()
			record["comparison"] = view[0]
			check(record.daily_detail_enabled == detail_enabled, "only requested daily detail is visible")
			check(scene.art.enabled and scene.art.refinement_enabled and scene.art.material_fidelity.enabled, "retained art remains enabled during both comparisons")
			check(scene.model.snapshot() == initial, "comparison keeps the original frozen authority")
	check(records.size() == 6, "three baseline/detail pairs")
	for i in range(0, records.size(), 2):
		check(records[i].pixel_sha256 != records[i+1].pixel_sha256, "daily detail visibly changes "+records[i].comparison)
	var report := {
		"schema": "1792.gujranwala-daily-detail-render.v1",
		"captures": records, "failures": failures,
		"source_commit": OS.get_environment("SOURCE_COMMIT"),
		"source_tree": OS.get_environment("SOURCE_TREE"),
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"device": RenderingServer.get_video_adapter_name(),
		"historical_authentication": false, "human_art_approval": false,
		"inspection_camera_only": true
	}
	var file := FileAccess.open(output_dir.path_join("manifest.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t", true, true))
		file.close()
	else: check(false, "write comparison manifest")
	print("GUJRANWALA_DAILY_DETAIL_RENDER: %d captures; %d failures" % [records.size(), failures])
	home.queue_free()
	home = null
	scene = null
	camera = null
	await frames(8)
	quit(1 if failures else 0)
