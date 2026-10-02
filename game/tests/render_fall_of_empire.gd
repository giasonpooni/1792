# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Original authoring UI, not historical environments or a played physical journey.
const Desk := preload("res://dlc/fall_of_empire/desk.tscn")
const Rules := preload("res://dlc/fall_of_empire/rules.gd")
var captures:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func frames(count: int=8) -> void:
	for _i in range(count): await physics_frame
	await process_frame
func capture(name: String, controls: Array) -> void:
	await frames();await RenderingServer.frame_post_draw
	var bounds:=Rect2(Vector2.ZERO,Vector2(root.size))
	for control in controls:
		if not bounds.encloses(control.get_global_rect()):
			failures+=1;push_error("DLC control outside viewport: "+str(control.get_global_rect()));return
	var image:=root.get_texture().get_image()
	if image==null or image.is_empty() or image.save_png("user://fall-of-empire-"+name+".png")!=OK: failures+=1;return
	captures+=1
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	var desk:=Desk.instantiate();root.add_child(desk);current_scene=desk;await frames()
	desk.tabs.current_tab=0
	await capture("campaign-contract",[desk.tabs])
	desk.tabs.current_tab=1
	desk.command("company_courier","observe")
	desk.command("company_courier","send","resident")
	desk.role_picker.select(2);desk.role_picker.item_selected.emit(2)
	await frames(125);desk.buttons.receive.pressed.emit()
	await capture("perspective-wide",[desk.tabs,desk.role_picker,desk.notebook,desk.buttons.household])
	for anchor in Rules.ANCHORS: desk.command("host","anchor",anchor)
	desk.command("rebel_courier","muster","left_region")
	desk.command("company_courier","inspect_road")
	desk.command("company_courier","send","resident")
	desk.command("resident","household","missing")
	await frames(125);desk.command("resident","receive");desk.command("resident","market");desk.command("host","close")
	if not desk.state.world.closed: failures+=1
	root.size=Vector2i(800,450);desk.tabs.current_tab=2
	await capture("settlement-compact",[desk.tabs,desk.timeline_label,desk.closure_label,desk.buttons.restore])
	desk.queue_free();await frames()
	print("FALL_OF_EMPIRE_RENDER: %d captures; %d failures" % [captures,failures]);quit(1 if failures else 0)
