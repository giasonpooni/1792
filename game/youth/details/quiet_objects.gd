# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Three authored inspectable objects, not historical artefacts or resource inventory.
## Reading/turning an inspection copy never changes a saved object or a receipt.
const CLOTH := Vector3(-10,.14,9)
const REIN := Vector3(-6,.14,9)
const PAN := Vector3(-21.8,.14,-14.7)
const RECORDS := {
	"cloth":{"at":CLOTH,"title":"SAFFRON IN THE FOLD","hint":"Examine the mended cloth",
		"first":"Sun has paled the outside almost to straw. Under the fold, the colour is still warm. An ivory thread crosses the old tear; the last few stitches are smaller than the first.",
		"turn":"The underside is the brighter side. Whoever folded this put the repair inward, but kept the good cloth. There is no crest or gold border. Its distinction is in the work.",
		"notice":"Three thread colours, not one. Someone has repaired the repair. Your thumb finds the knot before your eye does."},
	"rein":{"at":REIN,"title":"THE HOLE THAT WAS NOT USED","hint":"Examine the repaired cheekpiece",
		"first":"A short piece of old harness rests beside a brass-coloured fitting. Two holes are stretched smooth. A third has been punched cleanly, but its edges have not yet darkened.",
		"turn":"The patch sits on the outside. The side that would touch an animal is smoother. Not the neatest side. The kinder one.",
		"notice":"The newer holes are closer together. This was adjusted, not merely shortened. A small object keeps the shape of several decisions."},
	"pan":{"at":PAN,"title":"A PAN WITH TWO ENDINGS","hint":"Examine the patched pan",
		"first":"A small, dark pan. Its handle shines where a thumb would rest; its bowl does not. A rough patch on the bottom has outlasted the fine edge around it.",
		"turn":"The patch is not gold. The pan has been made useful again. Bring Mela and Jiva close to hear what each of them makes of it.",
		"notice":"A repair in plain sight. No maker's story survives on the metal; the people beside it will supply their own."}
}
const TALE := "MELA\nA poor woman heard that a king could turn iron into gold. She brought him her pan.\n\nJIVA\nAnd he could?\n\nMELA\nHe could fill it with gold. Which is near enough.\n\nJIVA\nNot if she still needed to cook."
const OTHER_END := "JIVA\nIn my version, he asks why she has only one pan. Then he finds the man who can mend it.\n\nMELA\nThat is a poor ending for a king.\n\nJIVA\nA useful one for a woman waiting to make supper.\n\nTwo tellings. No name, date, or witness."
var chapter: Node3D
var objects: Dictionary={}
var turnables: Dictionary={}
var active_id := ""
var allowed: Array[String]=[]
var pending := ""
var request_open := false
var opened_ids: Array[String]=[] # diagnostic observation only, never saved or used to select content
var hint_layer: CanvasLayer
var hint: Label
func build(owner_chapter: Node3D) -> void:
	chapter=owner_chapter;name="QuietObjectStories"
	set_meta("classification","original-environmental-fiction")
	for id in RECORDS:
		var stand:=Node3D.new();stand.name=String(id);stand.position=RECORDS[id].at;add_child(stand);objects[id]=stand
		box(stand,Vector3(1.2,.09,.62),Vector3(0,.64,0),Color("75604a"))
		for x in [-.46,.46]:
			for z in [-.21,.21]: box(stand,Vector3(.07,.60,.07),Vector3(x,.30,z),Color("564535"))
		var body:=StaticBody3D.new();body.name="InspectionStandCollision";stand.add_child(body)
		var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(1.2,.70,.62)
		collision.shape=shape;collision.position.y=.35;body.add_child(collision)
		var object:=Node3D.new();object.name="Object";object.position.y=.72;stand.add_child(object);turnables[id]=object
		match id:
			"cloth": cloth(object)
			"rein": rein(object)
			"pan": pan(object)
	hint_layer=CanvasLayer.new();add_child(hint_layer)
	hint=Label.new();hint.add_theme_font_size_override("font_size",18);hint.add_theme_color_override("font_shadow_color",Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x",2);hint.add_theme_constant_override("shadow_offset_y",2)
	hint_layer.add_child(hint);hint_layer.hide()
func material(color: Color,metal: float=0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.84;m.metallic=metal;return m
func box(parent: Node3D,size: Vector3,p: Vector3,color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;node.mesh=m;node.position=p;node.material_override=material(color);parent.add_child(node);return node
func ring(parent: Node3D,p: Vector3,inner: float,outer: float,color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new();var m:=TorusMesh.new();m.inner_radius=inner;m.outer_radius=outer;m.rings=32;m.ring_segments=8
	node.mesh=m;node.position=p;node.material_override=material(color,.5);parent.add_child(node);return node
func cloth_height(x: float,z: float) -> float:
	return .012*sin((x+.24)*9.0)+.005*sin(z*22+x*11)-.018*pow(maxf(0,(z-.10)/.11),2)
func cloth_surface(parent: Node3D,reverse: bool) -> void:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	const NX:=48
	const NZ:=32
	for j in range(NZ+1):
		var z:=-.21+.42*float(j)/NZ
		for i in range(NX+1):
			var x:=-.34+.68*float(i)/NX;var h:=cloth_height(x,z)
			var slope_x:=(cloth_height(x+.0001,z)-cloth_height(x-.0001,z))/.0002
			var slope_z:=(cloth_height(x,z+.0001)-cloth_height(x,z-.0001))/.0002
			vertices.append(Vector3(x,h-(.008 if reverse else 0.0),z))
			normals.append(Vector3(-slope_x,1,-slope_z).normalized()*(-1 if reverse else 1))
			var dye:=Color("b97930") if reverse else Color("c4a475")
			if x>.19:dye=Color("ded1b1")
			var weave:=sin(float(i)*2.4)*cos(float(j)*2.2)*.025
			colors.append(dye.lightened(maxf(0,weave)).darkened(maxf(0,-weave)))
			if i<NX and j<NZ:
				var k:=j*(NX+1)+i
				if reverse:indices.append_array(PackedInt32Array([k,k+1,k+NX+1,k+1,k+NX+2,k+NX+1]))
				else:indices.append_array(PackedInt32Array([k,k+NX+1,k+1,k+1,k+NX+1,k+NX+2]))
	var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var cloth_material:=StandardMaterial3D.new();cloth_material.vertex_color_use_as_albedo=true;cloth_material.roughness=1.0
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=cloth_material;parent.add_child(node)
func cloth(parent: Node3D) -> void:
	cloth_surface(parent,false);cloth_surface(parent,true)
	# An interrupted, slightly uneven mend, not a repeating ornamental motif.
	for i in range(13):
		var x:=-.20+i*.021;var z:=.045+sin(i*1.7)*.005
		var thread:=box(parent,Vector3(.023,.002,.0025),Vector3(x,cloth_height(x,z)+.0015,z),Color("e5d6ad") if i<8 else Color("a78757"))
		thread.rotation.y=.65 if i%2==0 else -.45
	for i in range(14):
		var x:=-.29+i*.043
		box(parent,Vector3(.002,.001,.025),Vector3(x,cloth_height(x,-.21),-.217),Color("a68a62"))

func rein(parent: Node3D) -> void:
	box(parent,Vector3(.74,.025,.075),Vector3.ZERO,Color("64432f"))
	box(parent,Vector3(.18,.004,.08),Vector3(-.08,.016,0),Color("8d6744"))
	for i in range(7):
		box(parent,Vector3(.009,.004,.008),Vector3(-.15+i*.025,.020,-.024),Color("c2a980"))
		box(parent,Vector3(.009,.004,.008),Vector3(-.15+i*.025,.020,.024),Color("c2a980"))
	for x in [.16,.21,.245]: ring(parent,Vector3(x,.013,0),.004,.008,Color("30241c"))
	var buckle:=ring(parent,Vector3(-.36,.015,0),.034,.046,Color("9e875d"));buckle.scale.z=.73
func pan(parent: Node3D) -> void:
	var bowl:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=.19;m.bottom_radius=.14;m.height=.025;m.radial_segments=40
	bowl.mesh=m;bowl.material_override=material(Color("4a4339"),.6);parent.add_child(bowl)
	var rim:=ring(parent,Vector3(0,.018,0),.17,.19,Color("796751"));rim.scale.y=.35
	box(parent,Vector3(.29,.026,.035),Vector3(.30,0,0),Color("675b48"))
	box(parent,Vector3(.08,.027,.036),Vector3(.40,.001,0),Color("a18c69"))
	var patch:=box(parent,Vector3(.12,.008,.09),Vector3(-.04,-.018,.015),Color("948170"));patch.rotation.y=.22
	for x in [-.09,.012]:
		for z in [-.018,.051]: ring(parent,Vector3(x,-.024,z),.003,.007,Color("b29a75"))
func available() -> bool:
	return chapter.model.aftermath_phase()=="complete" and not chapter.model.mounted() and chapter.model.brawl_phase() not in ["challenged","fighting","leaving","caught"]
func access(id: String) -> bool:
	if not RECORDS.has(id) or not available(): return false
	var p: Vector3=chapter.avatar.global_position;var at: Vector3=RECORDS[id].at
	if p.distance_to(chapter.model.position())>.25 or absf(p.y-at.y)>.28 or Vector2(p.x-at.x,p.z-at.z).length()>2.1:return false
	if not chapter._facing(at):return false
	var target:=at+Vector3(0,.80,-.08)
	var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*1.35,target,1,[chapter.avatar.get_rid(),chapter.horse.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func nearest() -> String:
	for id in RECORDS:
		if access(id):return id
	return ""
func friends_here() -> bool:
	if not chapter.model.has_brawl():return false
	for i in [3,4]:
		if not chapter.bazaar_performance.audible(i,4.5):return false
	return true
func show_page(id: String,page: String="first") -> void:
	if not access(id):close();return
	var text: String=RECORDS[id].get(page,RECORDS[id].first)
	if page in ["tale","other"]:
		if not friends_here():close();return
		text=TALE if page=="tale" else OTHER_END
	text+="\n\nOriginal environmental scene. The fable names no historical ruler. No item, money, or documented historical claim is awarded."
	var choices: Array=[["Turn it over","quiet:turn"],["Notice the small work","quiet:notice"],["Leave it as found","resume"]]
	if id=="pan" and friends_here():
		choices.push_front(["Hear Mela's ending","quiet:tale"]);choices.insert(1,["Ask Jiva for another ending","quiet:other"])
	chapter._show_dialog(RECORDS[id].title,text,choices)
	active_id=id;allowed=["turn","notice"]
	if id=="pan" and friends_here():allowed.append_array(["tale","other"])
	turnables[id].rotation.x=PI if page=="turn" else 0.0
	if id not in opened_ids:opened_ids.append(id)
func consume(action: String) -> void:
	if chapter._paused and not active_id.is_empty() and action in allowed and pending.is_empty():pending=action
func step() -> bool:
	if request_open:
		request_open=false
		if not chapter._paused:
			var id:=nearest()
			if not id.is_empty():show_page(id)
		return true
	if not pending.is_empty():
		var id:=active_id;var action:=pending;pending=""
		if not chapter._paused or not access(id) or not action in allowed:
			close();return true
		show_page(id,action);return true
	return false
func reset() -> void:
	active_id="";pending="";allowed.clear();request_open=false
	for object in turnables.values():object.rotation=Vector3.ZERO
	if is_instance_valid(hint_layer):hint_layer.hide()
func close() -> void:
	reset();chapter._resume()
func sample() -> void:
	if not is_instance_valid(hint_layer):return
	var id:="" if chapter._paused else nearest()
	hint_layer.visible=not id.is_empty()
	if not id.is_empty():
		hint.text="V  ·  "+RECORDS[id].hint
		var size:=get_viewport().get_visible_rect().size;hint.position=Vector2(maxf(20,(size.x-hint.size.x)*.5),size.y-70)
