# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Native inspection scene using exactly the same modules attached to the Home guard.
const Sword:=preload("res://presentation/service_sword.gd")
const Defence:=preload("res://presentation/service_defence.gd")
const Guard:=preload("res://presentation/service_guard.gd")
const Meshes:=preload("res://presentation/equipment_mesh.gd")
var service: Node3D
var fitted: Node3D
var display_root: Node3D
var camera: Camera3D
var draw_slider: HSlider
var turn_slider: HSlider
var status: Label
var helmet: Node3D
var shield: Node3D
var mail_slider: HSlider
var helmet_toggle: CheckButton
var guard: Node3D
var guard_toggle: CheckButton
var pose_label: Label
var note: Label
var close_view:=false
var guard_view:=false

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
	shield=Defence.shield()
	shield.position=Vector3(1.08,-.44,.0)
	display_root.add_child(shield)
	helmet=Defence.helmet()
	helmet.position=Vector3(1.08,.06,0)
	display_root.add_child(helmet)
	guard=Guard.new()
	guard.build()
	guard.visible=false
	display_root.add_child(guard)
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
	subtitle.text="Curved sidearm · independent sheath · dished shield · helmet and ring mail"
	subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subtitle)
	var panel:=VBoxContainer.new()
	panel.name="Controls"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=24
	panel.offset_right=-24
	panel.offset_top=-214
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
	pose_label=slider_row(panel,"Draw",draw_slider)
	turn_slider=HSlider.new()
	turn_slider.name="TurnSlider"
	turn_slider.min_value=-180
	turn_slider.max_value=180
	turn_slider.custom_minimum_size.y=24
	turn_slider.value_changed.connect(func(value: float):
		display_root.rotation.y=deg_to_rad(value)
		update_camera())
	slider_row(panel,"Turn",turn_slider)
	mail_slider=HSlider.new()
	mail_slider.name="MailSlider"
	mail_slider.max_value=480
	mail_slider.step=1
	mail_slider.custom_minimum_size.y=24
	mail_slider.value_changed.connect(func(value: float):
		helmet.get_node("MailAventail").sample_tick(int(value))
		guard.sample_pose(int(value),draw_slider.value))
	slider_row(panel,"Mail motion",mail_slider)
	var views:=HBoxContainer.new()
	panel.add_child(views)
	helmet_toggle=CheckButton.new()
	helmet_toggle.text="Helmet close-up [H]"
	helmet_toggle.toggled.connect(func(enabled: bool): set_view("helmet" if enabled else "overview"))
	views.add_child(helmet_toggle)
	guard_toggle=CheckButton.new()
	guard_toggle.text="Equipped guard [G]"
	guard_toggle.toggled.connect(func(enabled: bool): set_view("guard" if enabled else "overview"))
	views.add_child(guard_toggle)
	note=Label.new()
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(note)
	helmet_initial_pose()

func slider_row(parent: Control,caption: String,slider: HSlider) -> Label:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var label:=Label.new()
	label.text=caption
	label.custom_minimum_size.x=110
	row.add_child(label)
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return label

func set_view(mode: String) -> void:
	close_view=mode=="helmet"
	guard_view=mode=="guard"
	helmet_toggle.set_pressed_no_signal(close_view)
	guard_toggle.set_pressed_no_signal(guard_view)
	guard.visible=guard_view
	helmet.visible=not guard_view
	service.visible=not close_view and not guard_view
	fitted.visible=service.visible
	shield.visible=service.visible
	draw_slider.editable=not close_view
	update_camera()
	refresh()

func helmet_initial_pose() -> void:
	helmet.get_node("MailAventail").sample_tick(0)
	update_camera()

func update_camera() -> void:
	if guard_view:
		camera.size=3.7
		camera.global_position=guard.global_position+Vector3(2.2,1.65,-4)
		camera.look_at(guard.global_position+Vector3(0,.7,0))
	elif close_view:
		camera.size=.95
		camera.global_position=helmet.global_position+Vector3(.47,.15,.60)
		camera.look_at(helmet.global_position+Vector3(0,-.13,0))
	else:
		camera.size=3.5
		camera.position=Vector3(1.55,1.0,5)
		camera.look_at(Vector3(.1,-.25,0))

func set_draw(value: float) -> void:
	service.sample_draw(value)
	fitted.sample_draw(value)
	guard.sample_pose(int(mail_slider.value) if is_instance_valid(mail_slider) else 0,value)
	refresh()

func refresh() -> void:
	if is_instance_valid(status):
		status.text="Equipped guard · forearm support · belt suspension" if guard_view else ("Rigid rings · attached upper row · articulated strips" if close_view else "%s  ·  Plain service / fitted study"%service.presentation_state().capitalize())
		pose_label.text="Signal" if guard_view else "Draw"
		note.text="R reset · H helmet · G guard · F1 menu\nAuthored forms and motion; historical attribution unverified."

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F1:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	elif event.keycode==KEY_R:
		draw_slider.value=0
		turn_slider.value=0
		mail_slider.value=0
		helmet.get_node("MailAventail").sample_tick(0)
		guard.sample_pose(0,0.0)
	elif event.keycode==KEY_H:
		helmet_toggle.button_pressed=not helmet_toggle.button_pressed
	elif event.keycode==KEY_G:
		guard_toggle.button_pressed=not guard_toggle.button_pressed
