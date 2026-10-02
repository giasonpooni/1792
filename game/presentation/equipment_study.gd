# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Native inspection scene using exactly the same modules attached to the Home guard.
const Sword:=preload("res://presentation/service_sword.gd")
const Defence:=preload("res://presentation/service_defence.gd")
const Meshes:=preload("res://presentation/equipment_mesh.gd")
var service: Node3D
var fitted: Node3D
var display_root: Node3D
var camera: Camera3D
var draw_slider: HSlider
var turn_slider: HSlider
var status: Label

func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var world:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("162224")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c3d1cf")
	environment.ambient_light_energy=.65
	world.environment=environment
	add_child(world)
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-36,-35,0)
	key.light_color=Color("ffe1b1")
	key.light_energy=1.35
	add_child(key)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(25,145,0)
	fill.light_color=Color("a6ceda")
	fill.light_energy=.8
	add_child(fill)
	display_root=Node3D.new()
	display_root.name="EquipmentDisplay"
	add_child(display_root)
	service=Sword.new()
	service.build()
	service.position=Vector3(-.95,.0,0)
	service.rotation.y=PI/2
	display_root.add_child(service)
	fitted=Sword.new()
	fitted.build(true)
	fitted.name="FittedSword"
	fitted.position=Vector3(-.12,0,0)
	fitted.rotation.y=PI/2
	display_root.add_child(fitted)
	var shield:=Defence.shield()
	shield.position=Vector3(1.08,-.44,.0)
	display_root.add_child(shield)
	var helmet:=Defence.helmet()
	helmet.position=Vector3(1.08,.06,0)
	display_root.add_child(helmet)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.05
	camera.position=Vector3(1.55,1.1,5)
	add_child(camera)
	camera.look_at(Vector3(.1,-.10,0))
	camera.current=true
	_build_ui()
	refresh()

func _build_ui() -> void:
	var canvas:=CanvasLayer.new()
	add_child(canvas)
	var header:=VBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left=24
	header.offset_top=20
	header.offset_right=-24
	canvas.add_child(header)
	var title:=Label.new()
	title.text="1792  /  SERVICE EQUIPMENT"
	title.add_theme_font_size_override("font_size",26)
	header.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Curved sidearm · independent sheath · dished shield · rigid helmet"
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subtitle)
	var panel:=VBoxContainer.new()
	panel.name="Controls"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=24
	panel.offset_right=-24
	panel.offset_top=-144
	panel.offset_bottom=-16
	canvas.add_child(panel)
	status=Label.new()
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	draw_slider=HSlider.new()
	draw_slider.name="DrawSlider"
	draw_slider.max_value=1
	draw_slider.step=.01
	draw_slider.custom_minimum_size.y=24
	draw_slider.value_changed.connect(set_draw)
	panel.add_child(draw_slider)
	turn_slider=HSlider.new()
	turn_slider.name="TurnSlider"
	turn_slider.min_value=-180
	turn_slider.max_value=180
	turn_slider.custom_minimum_size.y=24
	turn_slider.value_changed.connect(func(value: float): display_root.rotation.y=deg_to_rad(value))
	panel.add_child(turn_slider)
	var note:=Label.new()
	note.text="Upper slider: draw / resheathe · Lower: turn · R reset · F1 menu\nAuthored dimensions and fittings; historical attribution unverified."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)

func set_draw(value: float) -> void:
	service.sample_draw(value)
	fitted.sample_draw(value)
	refresh()

func refresh() -> void:
	if is_instance_valid(status):
		status.text="%s  ·  Plain service / fitted study  ·  Blade and hilt travel together; sheath stays put"%service.presentation_state().capitalize()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F1:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	elif event.keycode==KEY_R:
		draw_slider.value=0
		turn_slider.value=0
