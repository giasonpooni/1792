extends Node3D
## Original dialogue for an authored family recollection, never a historical quotation.
## The caller owns the suspended Home and its return. This scene has no campaign model.
signal return_requested(completed: bool)

const INTRO_ID := "charat_singh.family_intro.v1"
const SPEAKER_ID := "mahan_singh"
const LISTENER_ID := "ranjit_singh"
const Names := preload("res://characters/character_names.gd")
const MaterialFidelity := preload("res://presentation/gujranwala_material_fidelity.gd")
const PRESENTATION_VERSION := "1792.charat-intro-presentation.v1"
const PRESENTATION_BLEND_SECONDS := 0.28
const GESTURE_WEIGHTS := [0.46,0.12,0.57,0.68,0.04,0.18,0.48,0.62,0.52,0.08]
const CAMERA_POSITION := Vector3(1.15,2.60,5.60)
const CAMERA_TARGET := Vector3(0,1.12,-0.15)
const PLASTER_MESHES := ["FarPlasterWall","SidePlasterWall","WallBase","HighCornice","QuietPlasterRepair"]
const TIMBER_MESHES := ["TimberOpeningLeft","TimberOpeningRight",
	"RecessLattice_-4_0_0","RecessLattice_-4_0_1","RecessLattice_-4_0_2","RecessLattice_-4_0_3","RecessLattice_-4_0_4",
	"RecessLattice_3_7_0","RecessLattice_3_7_1","RecessLattice_3_7_2","RecessLattice_3_7_3","RecessLattice_3_7_4",
	"LowSeatFather","LowSeatChild"]
const WOVEN_MESHES := ["WovenMat","MatWeft_0","MatWeft_1","MatWeft_2","MatWeft_3","MatWeft_4",
	"MatWeft_5","MatWeft_6","MatWeft_7","MatWeft_8","MatWeft_9"]
const COSTUME_MESHES := ["ClothedTorso","WaistSash","LeftUpperArm","LeftForearm","RightUpperArm","RightForearm",
	"ThighLeft","ShinLeft","ThighRight","ShinRight","HeadAttentionPivot/HeadWrap","HeadAttentionPivot/WrapFold"]
const BEATS := [
	{"id":"grandfather", "title":"A grandfather's name", "period":"Gujranwala · an early childhood recollection",
		"dialogue":"Come closer, Buddh. You have heard your grandfather's name: Charat Singh. He was my father. Before these courtyards were familiar to you, he rode out from Gujranwala with men who had little certainty of returning. I will tell you how he fought, and how this became our home."},
	{"id":"desan_household", "title":"Desan Kaur and our home", "period":"1756 · the family in Gujranwala",
		"dialogue":"Charat Singh married Desan Kaur. She is your grandmother. They made their home in Gujranwala, and our family grew here. When I tell you of this house, Buddh, remember her name alongside his. She would one day carry its affairs through a great loss."},
	{"id":"chenab_sialkot", "title":"The river and the encircled town", "period":"1761 · Chenab and Sialkot",
		"dialogue":"After the great battle at Panipat, Durrani sent Nur-ud-din against the Sikhs. His march left Bhera, Miani and Chak Sanu in ruins. Your grandfather and other Sikh chiefs checked him by the Chenab. The Afghan force fell back to Sialkot, where the Sikhs surrounded it. Nur-ud-din escaped. His remaining men surrendered, and were allowed to leave safely. Charat Singh brought captured arms back to Gujranwala."},
	{"id":"gujranwala_relief", "title":"Help beyond the walls", "period":"1761 · Gujranwala",
		"dialogue":"The governor at Lahore, Khwajah Abed Khan, then came against this fort. Your grandfather held inside it. Outside, Jassa Singh Ahluwalia and the Bhangi and Kanhaiya chiefs gathered to help him. The governor faced more than the men behind these walls. He withdrew in the night, leaving guns, horses and camels. Gujranwala had held because other chiefs had come to its relief."},
	{"id":"kup", "title":"The terrible day at Kup", "period":"1762 · near Malerkotla",
		"dialogue":"The following year, Durrani returned. Near Kup, his army fell upon the Sikhs while families were with them. Many people were killed; we remember that calamity as the Vadda Ghalughara. Your grandfather fought among the defenders and helped keep them together. It was a terrible loss. When I speak his name, I remember that day as well as the days of victory."},
	{"id":"kasur", "title":"The campaign at Kasur", "period":"1763 · Kasur",
		"dialogue":"The next year, Sikh forces carried war into Kasur. Charat Singh joined Hari Singh Bhangi's expedition. The town was taken and plundered, and the forces came away with booty. This, too, belonged to your grandfather's campaigns: war carried through other towns, as well as the defence of our own walls."},
	{"id":"sirhind", "title":"The roads to Sirhind", "period":"1764 · Sirhind and the northwest",
		"dialogue":"In the following year, Sikh forces struck at Morinda and Sirhind. Charat Singh watched the road to Sirhind, then fought against Zain Khan. He took no share of the territory there. His attention lay farther northwest, around Gujranwala and its neighbouring parganahs. Other chiefs established themselves elsewhere. Your grandfather strengthened the country from which his own men rode."},
	{"id":"sutlej", "title":"An army that kept its formation", "period":"1765 · the Sutlej",
		"dialogue":"At the Sutlej, Charat Singh rode on the Sikh right while Jassa Singh Ahluwalia commanded the centre. They struck at Durrani's army again and again. The Afghan formations held. Fighting gave way to withdrawal, and fresh attacks followed as the army continued its march. Your grandfather could press an enemy hard without breaking him. A story of his campaigns must leave room for those days too."},
	{"id":"jhelum_rohtas", "title":"North toward Jhelum and Rohtas", "period":"1767 · the northwestern campaigns",
		"dialogue":"Later, Charat Singh and Gujjar Singh Bhangi moved upon Jhelum. Your grandfather entrusted the town to Dada Ram Singh. Rohtas also fell into his hands, and his reach grew through the northern country, towards Dhanni, Pothohar and Chakwal. So the roads from Gujranwala became longer, Buddh."},
	{"id":"jammu_desan_regency", "title":"A loss, and the command that remained", "period":"Jammu and Gujranwala · the next generation",
		"dialogue":"During the fighting over Jammu's succession, your grandfather's own matchlock burst, and he was killed. I was still young. Desan Kaur held the affairs of our misl until I could lead. My father's command came to me through that loss, with your grandmother carrying it while I grew. These roads are ours now, Buddh. One day you will learn to ride them. For now, sit with me a little longer."}
]

var current_beat := 0
var oral_handoff := false
var furthest_beat := 0
var _returned := false
var _heading: Label
var _period: Label
var _dialogue: Label
var _previous: Button
var _next: Button
var _skip: Button
var _return_error: Label
var _presentation_tween: Tween
var _presentation_phase := 1.0
var _presentation_from: Dictionary = {}
var _presentation_to: Dictionary = {}
var _projection_state: Dictionary = {}
var _story_camera: Camera3D
var material_projection
var _material_metadata: Dictionary = {}

func story_beats() -> Array:
	return BEATS.duplicate(true)

func presentation_snapshot() -> Dictionary:
	if not is_instance_valid(_story_camera): return {}
	var father: Node3D = get_node("MahaSingh/HeadAttentionPivot")
	var child: Node3D = get_node("YoungBuddhSingh/HeadAttentionPivot")
	var hand: Node3D = get_node("MahaSingh/RightHand")
	var camera_q := _story_camera.quaternion
	return {"schema":PRESENTATION_VERSION,"beat_id":BEATS[current_beat].id,
		"transition_phase":_presentation_phase,"settled":_presentation_phase >= 1.0,
		"transition_seconds":PRESENTATION_BLEND_SECONDS,
		"camera":{"production_camera":true,"position":_vector(_story_camera.position),
			"quaternion":[camera_q.x,camera_q.y,camera_q.z,camera_q.w],
			"target":_vector(_projection_state.camera_target),"fov":_story_camera.fov,
			"h_offset":_story_camera.h_offset,"v_offset":_story_camera.v_offset},
		"father_head_rotation":_vector(father.rotation),"child_head_rotation":_vector(child.rotation),
		"father_right_hand":_vector(hand.position),"dialogue_opacity":_dialogue.modulate.a,
		"material_projection":_material_metadata.duplicate(true)}

func settle_presentation() -> void:
	_stop_presentation_tween()
	if not _presentation_to.is_empty(): _project_presentation(1.0)

func _vector(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _stop_presentation_tween() -> void:
	if _presentation_tween != null and _presentation_tween.is_valid(): _presentation_tween.kill()
	_presentation_tween = null

func _pose_for_beat(index: int) -> Dictionary:
	var weight: float = GESTURE_WEIGHTS[index]
	var intimate := index in [0,1,4,9]
	return {"elbow":Vector3(0.34,0.99,-0.14)+Vector3(0.045,0.10,-0.06)*weight,
		"hand":Vector3(0.20,0.84,-0.31)+Vector3(0.20,0.25,-0.13)*weight,
		"father_head":Vector3(0.04 if intimate else -0.015,0.045,0.0),
		"child_head":Vector3(-0.045 if intimate else -0.012,-0.035,0.018),
		"camera_position":CAMERA_POSITION+Vector3(0.03*weight,-0.03 if intimate else 0.0,-0.10 if intimate else 0.0),
		"camera_target":CAMERA_TARGET,
		"camera_fov":45.5 if intimate else 46.0}

func _start_presentation(animate: bool) -> void:
	_stop_presentation_tween()
	_presentation_to = _pose_for_beat(current_beat)
	_presentation_from = _presentation_to.duplicate(true) if _projection_state.is_empty() else _projection_state.duplicate(true)
	if not animate:
		_project_presentation(1.0)
		return
	_project_presentation(0.0)
	_presentation_tween = create_tween()
	_presentation_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_presentation_tween.tween_method(_project_presentation,0.0,1.0,PRESENTATION_BLEND_SECONDS)

func _project_presentation(phase: float) -> void:
	_presentation_phase = clampf(phase,0.0,1.0)
	_projection_state = {}
	for field in ["elbow","hand","father_head","child_head","camera_position","camera_target"]:
		var start: Vector3 = _presentation_from[field]
		var finish: Vector3 = _presentation_to[field]
		_projection_state[field] = start.lerp(finish,_presentation_phase)
	_projection_state.camera_fov = lerpf(_presentation_from.camera_fov,_presentation_to.camera_fov,_presentation_phase)
	var father: Node3D = get_node("MahaSingh")
	_position_limb(father.get_node("RightUpperArm"),Vector3(0.26,1.26,0),_projection_state.elbow)
	_position_limb(father.get_node("RightForearm"),_projection_state.elbow,_projection_state.hand)
	father.get_node("RightHand").position = _projection_state.hand
	father.get_node("HeadAttentionPivot").rotation = _projection_state.father_head
	get_node("YoungBuddhSingh/HeadAttentionPivot").rotation = _projection_state.child_head
	_story_camera.position = _projection_state.camera_position
	_story_camera.fov = _projection_state.camera_fov
	_story_camera.look_at(_projection_state.camera_target)
	# The whole page remains readable and usable throughout the short visual blend.
	_dialogue.modulate.a = lerpf(0.88,1.0,_presentation_phase)

func can_complete() -> bool:
	return current_beat == BEATS.size()-1 and furthest_beat == BEATS.size()-1

func reject_return(message: String) -> void:
	_returned = false
	if is_instance_valid(_return_error):
		_return_error.text = message
		_return_error.visible = not message.is_empty()
	if is_instance_valid(_skip): _skip.disabled = false
	if is_instance_valid(_next): _next.disabled = false
	_refresh(false)

func advance() -> void:
	if _returned: return
	if current_beat == BEATS.size() - 1:
		request_return(true)
		return
	current_beat += 1
	furthest_beat = maxi(furthest_beat,current_beat)
	_refresh()

func previous() -> void:
	if _returned: return
	if current_beat == 0: return
	current_beat = maxi(0,current_beat - 1)
	_refresh()

func request_return(completed: bool = false) -> void:
	if _returned: return
	if completed and not can_complete(): return
	settle_presentation()
	_returned = true
	if is_instance_valid(_previous): _previous.disabled = true
	if is_instance_valid(_next): _next.disabled = true
	if is_instance_valid(_skip): _skip.disabled = true
	return_requested.emit(completed)

func _ready() -> void:
	_build_courtyard()
	_build_material_projection()
	_build_interface()
	_refresh(false)
	_next.grab_focus()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _returned: return
	match event.keycode:
		KEY_ESCAPE: request_return(false)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT: advance()
		KEY_LEFT: previous()
		_: return
	get_viewport().set_input_as_handled()

func _refresh(animate: bool = true) -> void:
	if not is_instance_valid(_heading): return
	var beat: Dictionary = BEATS[current_beat]
	_heading.text = "%d / %d   %s" % [current_beat+1,BEATS.size(),beat.title]
	_period.text = beat.period
	_dialogue.text = beat.dialogue
	if oral_handoff and current_beat==0:
		_dialogue.text = "…he rode out from Gujranwala with men who had little certainty of returning.\n\nCome closer, Buddh. Charat Singh was my father, your grandfather. I will tell you how he fought, and how this became our home."
	_previous.disabled = current_beat == 0
	_next.text = "Continue to Home" if current_beat == BEATS.size()-1 else "Next"
	_start_presentation(animate)

func _exit_tree() -> void:
	_stop_presentation_tween()

func _material(colour: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = roughness
	return result

func _box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = node_name
	var shape := BoxMesh.new()
	shape.size = size
	result.mesh = shape
	result.material_override = material
	result.position = at
	parent.add_child(result)
	return result

func _sphere(parent: Node3D, node_name: String, at: Vector3, scale_size: Vector3, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = node_name
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 20
	shape.rings = 12
	result.mesh = shape
	result.material_override = material
	result.position = at
	result.scale = scale_size
	parent.add_child(result)
	return result

func _limb(parent: Node3D, node_name: String, start: Vector3, end: Vector3, width: float, material: Material) -> void:
	var result := MeshInstance3D.new()
	result.name = node_name
	var shape := CylinderMesh.new()
	shape.top_radius = width
	shape.bottom_radius = width*1.05
	shape.height = start.distance_to(end)
	shape.radial_segments = 12
	result.mesh = shape
	result.material_override = material
	result.position = (start+end)*0.5
	result.quaternion = Quaternion(Vector3.UP,(end-start).normalized())
	parent.add_child(result)

func _position_limb(node: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var shape := node.mesh as CylinderMesh
	shape.height = start.distance_to(end)
	node.position = (start+end)*0.5
	node.quaternion = Quaternion(Vector3.UP,(end-start).normalized())

func _finish_declared_meshes(paths: Array, kind: int) -> void:
	for path in paths:
		var mesh: MeshInstance3D = get_node(path)
		var horizontal: bool = mesh.mesh is BoxMesh and mesh.mesh.size.x > mesh.mesh.size.y
		material_projection.finish(mesh,kind,horizontal)

func _build_material_projection() -> void:
	# The existing projection supplies reversible shading only over this declared set.
	material_projection = MaterialFidelity.new()
	material_projection.name = "IntroMaterialFidelity"
	material_projection.set_meta("classification","original-material-appearance-study")
	material_projection.set_meta("historical_claim",false)
	material_projection.set_meta("gameplay_authority",false)
	add_child(material_projection)
	_finish_declared_meshes(PLASTER_MESHES,0)
	_finish_declared_meshes(TIMBER_MESHES,1)
	_finish_declared_meshes(WOVEN_MESHES,3)
	for actor in ["MahaSingh","YoungBuddhSingh"]:
		var paths: Array = []
		for part in COSTUME_MESHES: paths.append(actor+"/"+part)
		_finish_declared_meshes(paths,3)
	material_projection.set_enabled(true)
	var declared: Array = []
	for record in material_projection.records:
		declared.append({"mesh":str(get_path_to(record.node)),"finish":record.kind,
			"pigment":record.old.albedo_color.to_html(),
			"horizontal_grain":record.new.get_shader_parameter("horizontal_grain")})
	_material_metadata = {"classification":"original-material-appearance-study",
		"historical_evidence":false,"gameplay_authority":false,"added_geometry":0,
		"mesh_count":material_projection.records.size(),"cached_material_count":material_projection.materials.size(),
		"groups":[{"kind":"plaster","mesh_count":PLASTER_MESHES.size()},
			{"kind":"timber","mesh_count":TIMBER_MESHES.size()},
			{"kind":"woven_mat","mesh_count":WOVEN_MESHES.size()},
			{"kind":"costume_cloth","mesh_count":COSTUME_MESHES.size()*2}],
		"declared_meshes":declared,"shader":MaterialFidelity.SURFACE.resource_path,
		"sources":[{"role":"plaster_height","resource":MaterialFidelity.HEIGHT.resource_path,
			"provenance":"res://assets/surfaces/sources.json","license":"CC0-1.0"},
			{"role":"plaster_roughness","resource":MaterialFidelity.ROUGHNESS.resource_path,
			"provenance":"res://assets/surfaces/sources.json","license":"CC0-1.0"}]}

func _seated_person(node_name: String, actor_id: String, at: Vector3, facing: float, small: bool) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.set_meta("actor_id",actor_id)
	root.set_meta("authored_age_presentation","very_young_child" if small else "adult_father")
	root.position = at
	root.rotation.y = facing
	root.scale = Vector3.ONE*(0.66 if small else 1.0)
	add_child(root)
	var skin := _material(Color("9d704c"))
	var cloth := _material(Color("926442") if small else Color("283a49"))
	var trousers := _material(Color("cdb98e"))
	var wrap := _material(Color("6d8180") if small else Color("b08947"))
	var dark := _material(Color("282827"))
	var torso := _sphere(root,"ClothedTorso",Vector3(0,1.05,0),Vector3(0.48,0.67,0.35),cloth)
	torso.rotation.z = -0.04 if small else 0.025
	_box(root,"WaistSash",Vector3(0,0.85,-0.017),Vector3(0.46,0.13,0.32),wrap)
	var head := Node3D.new()
	head.name = "HeadAttentionPivot"
	head.position = Vector3(0,1.37,0)
	root.add_child(head)
	_sphere(head,"Head",Vector3(0,0.19,-0.025),Vector3(0.31,0.36,0.30),skin)
	_sphere(head,"HeadWrap",Vector3(0,0.34,0),Vector3(0.40,0.23,0.36),wrap)
	_sphere(head,"WrapFold",Vector3(0,0.39,-0.035),Vector3(0.36,0.11,0.34),_material(wrap.albedo_color.darkened(0.10)))
	_sphere(head,"Nose",Vector3(0,0.18,-0.183),Vector3(0.055,0.075,0.065),skin)
	for side in [-1.0,1.0]:
		_sphere(head,"EyeLeft" if side < 0 else "EyeRight",Vector3(side*0.071,0.23,-0.161),Vector3(0.019,0.014,0.012),dark)
	if not small:
		_sphere(head,"Beard",Vector3(0,0.07,-0.126),Vector3(0.28,0.27,0.115),dark)
	# Quiet listening and storytelling poses; no likeness or combat equipment.
	_limb(root,"LeftUpperArm",Vector3(-0.26,1.26,0),Vector3(-0.35,1.00,-0.12),0.085,cloth)
	_limb(root,"LeftForearm",Vector3(-0.35,1.00,-0.12),Vector3(-0.21,0.81,-0.31),0.07,cloth)
	_sphere(root,"LeftHand",Vector3(-0.21,0.81,-0.31),Vector3(0.13,0.10,0.15),skin)
	var elbow := Vector3(0.34,1.00,-0.12) if small else Vector3(0.38,1.07,-0.15)
	var hand := Vector3(0.20,0.81,-0.31) if small else Vector3(0.49,1.16,-0.38)
	_limb(root,"RightUpperArm",Vector3(0.26,1.26,0),elbow,0.085,cloth)
	_limb(root,"RightForearm",elbow,hand,0.07,cloth)
	_sphere(root,"RightHand",hand,Vector3(0.13,0.10,0.15),skin)
	for side in [-1.0,1.0]:
		_limb(root,"ThighLeft" if side < 0 else "ThighRight",Vector3(side*0.13,0.78,0),Vector3(side*0.23,0.60,-0.35),0.105,trousers)
		_limb(root,"ShinLeft" if side < 0 else "ShinRight",Vector3(side*0.23,0.60,-0.35),Vector3(side*0.22,0.22,-0.43),0.085,trousers)
		_box(root,"ShoeLeft" if side < 0 else "ShoeRight",Vector3(side*0.22,0.17,-0.49),Vector3(0.17,0.10,0.29),dark)

func _build_courtyard() -> void:
	var earth := _material(Color("a18b6c"))
	var plaster := _material(Color("b9a27e"))
	var ochre := _material(Color("8e6949"))
	var recess := _material(Color("3d3d3b"))
	var wood := _material(Color("493d32"))
	var mat := _material(Color("9d8062"))
	var green := _material(Color("536549"))
	_box(self,"CourtyardFloor",Vector3(0,-0.07,0),Vector3(14,0.14,12),earth)
	_box(self,"FarPlasterWall",Vector3(0,2.0,-5.3),Vector3(14,4.0,0.32),plaster)
	_box(self,"SidePlasterWall",Vector3(-6.7,1.8,0),Vector3(0.3,3.6,10.5),plaster)
	_box(self,"WallBase",Vector3(0,0.28,-5.08),Vector3(14,0.50,0.11),ochre)
	_box(self,"HighCornice",Vector3(0,3.85,-5.02),Vector3(14,0.18,0.45),ochre)
	for x in [-4.0,3.7]:
		_box(self,"TimberOpeningLeft" if x < 0 else "TimberOpeningRight",Vector3(x,1.9,-5.05),Vector3(1.6,1.9,0.09),wood)
		_box(self,"DarkRecessLeft" if x < 0 else "DarkRecessRight",Vector3(x,1.9,-4.985),Vector3(1.34,1.65,0.07),recess)
		for k in range(5):
			_box(self,"RecessLattice_%s_%d" % [str(x),k],Vector3(x-0.51+k*0.255,1.9,-4.92),Vector3(0.045,1.61,0.045),wood)
	_box(self,"QuietPlasterRepair",Vector3(1.48,0.90,-5.10),Vector3(1.23,0.80,0.09),_material(Color("c5b291")))
	_box(self,"LowSeatFather",Vector3(-0.82,0.37,0.22),Vector3(0.87,0.20,0.84),wood)
	_box(self,"LowSeatChild",Vector3(0.79,0.24,-0.04),Vector3(0.59,0.17,0.57),wood)
	_box(self,"WovenMat",Vector3(0.04,0.022,-0.18),Vector3(2.5,0.04,1.6),mat)
	for k in range(10):
		_box(self,"MatWeft_%d" % k,Vector3(-1.05+k*0.24,0.047,-0.18),Vector3(0.03,0.012,1.50),ochre)
	_seated_person("MahaSingh",SPEAKER_ID,Vector3(-0.82,0,0.22),-1.68,false)
	_seated_person("YoungBuddhSingh",LISTENER_ID,Vector3(0.79,0.03,-0.04),1.68,true)
	# A few planting masses soften the edge; all props are presentation only.
	for i in range(3):
		var x := -5.4+float(i)*0.36
		_sphere(self,"QuietPlant_%d" % i,Vector3(x,0.48,-3.9+float(i%2)*0.3),Vector3(0.85,0.90,0.70),green)
	var environment := WorldEnvironment.new()
	environment.name = "StoryEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("647580")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a8b8c6")
	settings.ambient_light_energy = 0.62
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "LateLight"
	sun.rotation_degrees = Vector3(-42,-30,0)
	sun.light_color = Color("ffdeac")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	_story_camera = Camera3D.new()
	_story_camera.name = "StoryCamera"
	_story_camera.position = CAMERA_POSITION
	_story_camera.fov = 46
	add_child(_story_camera)
	_story_camera.look_at(CAMERA_TARGET)
	# Place the seated pair in the upper field, clear of the subtitle panel.
	_story_camera.v_offset = -0.66
	_story_camera.current = true

func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "StoryInterface"
	add_child(canvas)
	var title := Label.new()
	title.name = "SceneTitle"
	title.position = Vector2(44,28)
	title.text = "A father's telling"
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",Color("f2e4c7"))
	title.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_x",2)
	title.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(title)
	var frame := Label.new()
	frame.name = "DramatizationLabel"
	frame.position = Vector2(46,68)
	frame.text = "Maha Singh and the young Buddh Singh · dramatized recollection"
	frame.add_theme_font_size_override("font_size",16)
	frame.add_theme_color_override("font_color",Color("ead7b3"))
	frame.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
	frame.add_theme_constant_override("shadow_offset_x",1)
	frame.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(frame)
	var panel := PanelContainer.new()
	panel.name = "Subtitles"
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 42
	panel.offset_right = -42
	panel.offset_top = -306
	panel.offset_bottom = -22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.095,0.105,0.94)
	style.border_color = Color("987c51")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 23
	style.content_margin_right = 23
	style.content_margin_top = 16
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel",style)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var heading_row := HBoxContainer.new()
	heading_row.name = "HeadingRow"
	column.add_child(heading_row)
	_heading = Label.new()
	_heading.name = "BeatTitle"
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.add_theme_font_size_override("font_size",20)
	_heading.add_theme_color_override("font_color",Color("dfba7d"))
	heading_row.add_child(_heading)
	_period = Label.new()
	_period.name = "Period"
	_period.add_theme_font_size_override("font_size",16)
	_period.add_theme_color_override("font_color",Color("c3c4bd"))
	heading_row.add_child(_period)
	var speaker := Label.new()
	speaker.name = "Speaker"
	speaker.text = "Maha Singh"
	speaker.add_theme_font_size_override("font_size",18)
	speaker.add_theme_color_override("font_color",Color("f0dfc2"))
	column.add_child(speaker)
	_dialogue = Label.new()
	_dialogue.name = "Dialogue"
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue.add_theme_font_size_override("font_size",21)
	_dialogue.add_theme_color_override("font_color",Color("f0ece2"))
	column.add_child(_dialogue)
	_return_error = Label.new()
	_return_error.name = "ReturnMessage"
	_return_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_return_error.add_theme_font_size_override("font_size",16)
	_return_error.add_theme_color_override("font_color",Color("f0c995"))
	_return_error.visible = false
	column.add_child(_return_error)
	var controls := HBoxContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("separation",12)
	column.add_child(controls)
	_previous = Button.new()
	_previous.name = "Previous"
	_previous.text = "Previous"
	_previous.custom_minimum_size = Vector2(132,37)
	_previous.add_theme_font_size_override("font_size",18)
	_previous.pressed.connect(previous)
	controls.add_child(_previous)
	_next = Button.new()
	_next.name = "Next"
	_next.text = "Next"
	_next.custom_minimum_size = Vector2(186,37)
	_next.add_theme_font_size_override("font_size",18)
	_next.pressed.connect(advance)
	controls.add_child(_next)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	var hint := Label.new()
	hint.name = "KeyboardHint"
	hint.text = "Enter / → next    ← previous"
	hint.add_theme_font_size_override("font_size",16)
	hint.add_theme_color_override("font_color",Color("b9bcb5"))
	controls.add_child(hint)
	_skip = Button.new()
	_skip.name = "Skip"
	_skip.text = "Skip · Esc"
	_skip.custom_minimum_size = Vector2(130,37)
	_skip.add_theme_font_size_override("font_size",18)
	_skip.pressed.connect(request_return.bind(false))
	controls.add_child(_skip)
