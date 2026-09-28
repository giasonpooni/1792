extends Node3D

# Gujranwala 1792 research-backed greybox.
# Geometry is a bounded reconstruction, not a surveyed historical plan.

var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var yaw := 0.0
var pitch := -0.38

func _ready() -> void:
	player = $Player
	_build_environment()
	_build_ground()
	_build_home()
	_build_settlement()
	_build_fields()
	_build_routes()
	_build_hud()
	_build_camera()

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m

func _box(at: Vector3, size: Vector3, color: Color, collision := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _mat(color)
	mesh.position = at
	add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		mesh.add_child(body)
	return mesh

func _label(text: String, at: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.font_size = 38
	l.pixel_size = 0.012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.72, 0.78)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.88, 0.82, 0.69)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _build_ground() -> void:
	_box(Vector3(0,-0.5,0), Vector3(180,1,180), Color(0.43,0.47,0.25))
	# Packed-earth paths: deliberately irregular rather than a later grid.
	_box(Vector3(0,0.02,0), Vector3(7,0.04,150), Color(0.55,0.43,0.29), false)
	_box(Vector3(-22,0.025,-8), Vector3(55,0.04,6), Color(0.55,0.43,0.29), false)
	_box(Vector3(23,0.025,12), Vector3(48,0.04,5), Color(0.55,0.43,0.29), false)

func _wall(at: Vector3, size: Vector3) -> void:
	_box(at,size,Color(0.61,0.48,0.33))

func _build_home() -> void:
	# Class B: courtyard-house type anchored to surviving birthplace haveli.
	var z := 24.0
	_wall(Vector3(-9,1.5,z),Vector3(1,3,26))
	_wall(Vector3(9,1.5,z),Vector3(1,3,26))
	_wall(Vector3(0,1.5,z+13),Vector3(19,3,1))
	_wall(Vector3(-5.5,1.5,z-13),Vector3(8,3,1))
	_wall(Vector3(5.5,1.5,z-13),Vector3(8,3,1))
	# room bars divide three courts while leaving central passages
	for cross_z in [z+4.0, z-5.0]:
		_wall(Vector3(-5.5,1.5,cross_z),Vector3(8,3,1))
		_wall(Vector3(5.5,1.5,cross_z),Vector3(8,3,1))
	_label("SUKERCHAKIA HOUSEHOLD\nClass B reconstruction",Vector3(0,4,z+8))

func _house(at: Vector3, sx: float, sz: float) -> void:
	_box(at + Vector3(0,1.35,0),Vector3(sx,2.7,sz),Color(0.64,0.50,0.34))

func _build_settlement() -> void:
	# Dispersed clusters leave open space; exact parcels/lanes are reconstructed.
	var homes := [
		[-18,-20,7,6],[-10,-30,6,5],[12,-25,8,5],[22,-18,6,7],
		[-25,3,7,5],[19,1,6,6],[-29,20,8,6],[28,25,7,5],
		[-18,35,6,5],[20,39,7,6],[-36,-10,6,5],[36,8,6,5]
	]
	for h in homes:
		_house(Vector3(h[0],0,h[1]),h[2],h[3])
	# Bazaar/workshop cluster: class B placement, class C density.
	for x in [-10.0,-5.0,5.0,10.0]:
		_house(Vector3(x,0,-10),4,5)
	_label("BAZAAR / WORKSHOPS\nreconstructed placement",Vector3(0,4,-10))
	# Simple well marker; location is not a historical claim.
	var well := CylinderMesh.new()
	well.top_radius = 1.2
	well.bottom_radius = 1.2
	well.height = 0.8
	var wm := MeshInstance3D.new()
	wm.mesh = well
	wm.material_override = _mat(Color(0.42,0.39,0.34))
	wm.position = Vector3(-14,0.4,4)
	add_child(wm)
	_label("WELL\nClass B/C",Vector3(-14,2,4))

func _build_fields() -> void:
	for x in [-65.0,-48.0,48.0,65.0]:
		for z in [-55.0,-35.0,40.0,60.0]:
			_box(Vector3(x,0.02,z),Vector3(12,0.04,18),Color(0.52,0.55,0.27),false)
	# sparse tree markers preserve the open-space reading
	for p in [Vector3(-42,0,25),Vector3(42,0,-28),Vector3(-54,0,-5),Vector3(52,0,18),Vector3(-25,0,55)]:
		_box(p+Vector3(0,1.5,0),Vector3(0.7,3,0.7),Color(0.29,0.20,0.12))
		var crown := SphereMesh.new()
		crown.radius = 2.2
		crown.height = 4.4
		var m := MeshInstance3D.new()
		m.mesh = crown
		m.material_override = _mat(Color(0.25,0.39,0.18))
		m.position = p+Vector3(0,4,0)
		add_child(m)
	_label("CULTIVATED / OPEN EDGE\nClass B reconstruction",Vector3(-55,4,50))

func _build_routes() -> void:
	_label("NORTH ROAD →\nknowledge: partial",Vector3(0,3,-72))
	_label("← WEST ROAD\nknowledge: partial",Vector3(-72,3,-8))
	_label("EAST ROAD →\nknowledge: partial",Vector3(72,3,12))
	_label("GUJRANWALA — 1792\nresearch-backed greybox",Vector3(0,7,0))

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.far = 220
	add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(18,16)
	hud.add_theme_font_size_override("font_size",18)
	hud.add_theme_color_override("font_shadow_color",Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x",2)
	hud.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(hud)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch - event.relative.y * 0.003,-0.95,-0.12)
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if player == null or camera == null:
		return
	var target := player.global_position + Vector3.UP * 1.5
	var offset := Vector3(0,0,9).rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
	camera.global_position = target + offset
	camera.look_at(target,Vector3.UP)
	var zone := "settlement"
	if player.global_position.z > 10 and abs(player.global_position.x) < 12:
		zone = "Sukerchakia household"
	elif player.global_position.z < -5 and abs(player.global_position.x) < 15:
		zone = "bazaar / workshops"
	elif abs(player.global_position.x) > 42:
		zone = "cultivated edge"
	hud.text = "1792 · GUJRANWALA · %s\n" % zone
	hud.text += "WASD move · Shift sprint · right mouse orbit\n"
	hud.text += "Greybox geometry = reconstruction; labels expose evidence class"
