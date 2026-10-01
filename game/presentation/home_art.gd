# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Reversible dressing of the qualified Home. It never edits the domain model.
const Kit := preload("res://presentation/workshop_kit.gd")
const Costume := preload("res://presentation/costume_proxy.gd")
const PATH := "res://data/home_art.v1.json"
var kit := Kit.new()
var manifest: Dictionary = {}
var digest := ""
var enabled := false
var preset := "daylight"
var last_tick := -1
var _changes: Array[Dictionary] = []
var _roots: Array[Node3D] = []
var _hero_proxy: Node3D
var _hero_mesh: MeshInstance3D
var _home: Node3D
var _environment: WorldEnvironment
var _original_environment: Environment
var _sun: DirectionalLight3D
var _original_sun: Dictionary

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.get("schema")!="1792.home-art.v1" or value.get("id")!="home-material-study.v1": return "Unknown art study."
	if value.get("frame")!="gujranwala-compressed-local-metres" or value.get("year")!=1792 or value.get("georeferenced")!=false: return "Art is not geographic or epoch admission."
	if value.get("classification")!="original-authoring-study" or value.get("evidence_ref")!="res://data/gujranwala_reconstruction.v1.json": return "Missing reconstruction boundary."
	var seed_value: Variant=value.get("seed")
	if typeof(seed_value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(seed_value) or seed_value!=floor(seed_value) or seed_value<0 or seed_value>1000000: return "Invalid visual seed."
	if not value.get("presets") is Dictionary or value.presets.size()!=3: return "Expected three visual presets."
	for id in ["daylight","golden_hour","evening"]:
		var p: Variant=value.presets.get(id)
		if not p is Dictionary: return "Missing preset."
		var angles: Variant=p.get("sun_rotation")
		if not angles is Array or angles.size()!=3: return "Invalid light direction."
		for n in angles:
			if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(n) or absf(n)>180: return "Invalid light direction."
		for key in ["sun_energy","ambient"]:
			var n: Variant=p.get(key)
			if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(n) or n<0 or n>2: return "Unbounded light energy."
		for key in ["sun_color","sky_top","sky_horizon","fog"]:
			if not p.get(key) is String or p[key].length()!=6 or not Color.html_is_valid(p[key]): return "Invalid color."
	if not value.get("limits") is Array or value.limits.is_empty(): return "Missing limits."
	return ""

func _root(parent: Node3D, label: String) -> Node3D:
	var n:=Node3D.new();n.name=label;parent.add_child(n);_roots.append(n)
	n.set_meta("classification","original-authoring-study")
	return n

func _remember(v: MeshInstance3D) -> void:
	for record in _changes:
		if record.node==v: return
	_changes.append({"node":v,"old_mesh":v.mesh,"old_material":v.material_override,"old_scale":v.scale,"old_layers":v.layers})

func _replace_material(v: MeshInstance3D, material: Material) -> void:
	_remember(v);v.material_override=material

func _round(v: MeshInstance3D, size: Vector3) -> void:
	_remember(v)
	var sphere:=SphereMesh.new();sphere.radius=0.5;sphere.height=1;sphere.radial_segments=16;sphere.rings=8
	v.mesh=sphere;v.scale*=size

func build(chapter: Node3D) -> String:
	if not manifest.is_empty(): return "Art study already built."
	var text:=FileAccess.get_file_as_string(PATH)
	var candidate: Variant=JSON.parse_string(text)
	var error:=validate(candidate)
	if not error.is_empty(): return error
	_home=chapter.get_parent();_environment=_home.get_node_or_null("WorldEnvironment");_sun=_home.get_node_or_null("Sun")
	if _environment==null or _sun==null or chapter.get("fabric")==null: return "Requires the existing researched Home scene."
	manifest=candidate.duplicate(true);digest=text.sha256_text()
	_original_environment=_environment.environment
	_original_sun={"rotation":_sun.rotation_degrees,"energy":_sun.light_energy,"color":_sun.light_color}
	# Enumerate original meshes before adding any kit geometry; do not recursively restyle the kit.
	var meshes: Array[Node]=_home.find_children("*","MeshInstance3D",true,false)
	for item in meshes:
		var v: MeshInstance3D=item
		if chapter.horse.is_ancestor_of(v) or chapter.avatar.is_ancestor_of(v): continue
		_style_static(v,chapter)
	_build_hero(chapter)
	_style_mobile(chapter.horse)
	_style_mobile(chapter.avatar)
	_style_mobile(chapter.escort)
	_style_mobile(chapter.merchant)
	for youth in chapter.youths: _style_mobile(youth)
	_build_veranda(chapter)
	_build_stable(chapter)
	_build_market(chapter)
	for record in _changes:
		record.new_mesh=record.node.mesh;record.new_material=record.node.material_override
		record.new_scale=record.node.scale;record.new_layers=record.node.layers
	enabled=true
	set_preset("daylight")
	sample(int(chapter.model.progress().tick))
	return ""

func _style_static(v: MeshInstance3D, chapter: Node3D) -> void:
	if v.mesh==chapter.cell.terrain_mesh:
		_replace_material(v,kit.surface("969a71",3));return
	if not v.mesh is BoxMesh: return
	var size: Vector3=v.mesh.size
	# Replace only the two noncolliding roof slabs; otherwise their faces occlude the cloth.
	var stable_roof: bool=size.is_equal_approx(Vector3(6,0.3,6)) and v.global_position.distance_to(Vector3(9,3.6,-4))<0.01
	var market_roof: bool=size.is_equal_approx(Vector3(4,0.2,3)) and v.global_position.distance_to(Vector3(-24,3.14,-17.6))<0.01
	if stable_roof or market_roof:
		_remember(v);v.layers=0;return
	var color: String=v.material_override.albedo_color.to_html(false) if v.material_override is StandardMaterial3D else ""
	# Existing crowns are scenery. Replace their silhouettes, not the retained trunk collision.
	if color in ["506248","556746"] and size.x>3 and size.z>3:
		_remember(v);v.layers=0
		var n:=_root(v.get_parent(),"CanopyStudy")
		kit.crown(n,v.position,size,int(manifest.seed)+_roots.size());return
	# Keep actual actor roots, ownership and collision; replace only static box proxies.
	if size.x>=0.48 and size.x<=0.60 and size.y>=1.5 and size.y<=1.71 and size.z<=0.55:
		_remember(v);v.layers=0
		var n:=_root(v,"CostumeStudy")
		kit.person(n,-Vector3.UP*size.y/2.0,color if not color.is_empty() else "aea17a",size.y)
		return
	var palette: Dictionary={
		"b48b65":["c0ad86",0],"ac8861":["bdaa83",0],"ab845b":["bdaa83",0],"986443":["ac7856",1],
		"b3986e":["b7a279",3],"baa37c":["bda982",3],"ac976e":["b3a17f",3],"ad956c":["b7a27d",3],"a78f69":["b5a181",3],
		"906942":["806950",2],"735b43":["766049",2],"6c5139":["79624b",2],"6c5139ff":["79624b",2],"705a40":["776048",2],"69533e":["776048",2],
		"765b40":["806950",2],"b09872":["baa680",0],"715c43":["77634b",2],
		"9a8566":["a98a63",1],"c3b68a":["b7a985",4],"b59867":["b4a07b",4],"ab8454":["b19c73",4],
		"65734c":["8b916c",3],"506248":["67734f",3],"91a063":["819061",3],"b29b71":["a18d64",3]}
	if palette.has(color): _replace_material(v,kit.surface(palette[color][0],palette[color][1]))

func _build_hero(chapter: Node3D) -> void:
	_hero_mesh=chapter.avatar.get_node("MeshInstance3D")
	_remember(_hero_mesh);_hero_mesh.layers=0
	_hero_proxy=Costume.new();_hero_proxy.name="ChildhoodCostumeStudy"
	chapter.avatar.add_child(_hero_proxy);_roots.append(_hero_proxy)
	var head:=BoneAttachment3D.new();head.bone_name="head";_hero_proxy.skeleton.add_child(head)
	kit.ellipsoid(head,Vector3(0,0.255,0.015),Vector3(0.32,0.16,0.31),kit.surface("bbaa86",4))
	var waist:=BoneAttachment3D.new();waist.bone_name="pelvis";_hero_proxy.skeleton.add_child(waist)
	var hem:=CylinderMesh.new();hem.top_radius=0.20;hem.bottom_radius=0.245;hem.height=0.32;hem.radial_segments=16
	kit.mesh_at(waist,hem,Vector3(0,-0.09,0),kit.surface("c2b287",4))

func _style_mobile(actor: Node3D) -> void:
	for child in actor.find_children("*","MeshInstance3D",true,false):
		var v: MeshInstance3D=child
		if not v.mesh is BoxMesh: continue
		var size: Vector3=v.mesh.size
		# Preserve eye/direction markers, saddles and shields. Round the body/limb proxies only.
		if minf(size.x,minf(size.y,size.z))<0.09: continue
		if size.x>0.6 and size.y<0.25: continue
		_round(v,size)
		if v.material_override is StandardMaterial3D:
			var color: String=v.material_override.albedo_color.to_html(false)
			_replace_material(v,kit.surface(color,4))

func _build_veranda(chapter: Node3D) -> void:
	var old: Node3D=chapter.fabric.get_node("household_veranda")
	for child in old.find_children("*","MeshInstance3D",true,false):
		_remember(child);child.layers=0
	var n:=_root(self,"VerandaKit")
	n.position=old.position
	var plaster:=kit.surface("bda984");var timber:=kit.surface("776049",2)
	for i in range(9):
		var x: float=-17+i*4.25
		kit.box(n,Vector3(x,1.30,0),Vector3(0.35,2.60,0.35),plaster)
		kit.box(n,Vector3(x,0.20,0),Vector3(0.51,0.40,0.51),kit.surface("a58b67",1))
		kit.box(n,Vector3(x,2.06,0),Vector3(0.57,0.16,0.51),plaster)
	for i in range(8):
		var x: float=-17+(i+0.5)*4.25
		kit.arch(n,Vector3(x,2.1,0),2.125,1.10,0.17)
		kit.shutter(n,Vector3(x,1.34,0.37))
	kit.box(n,Vector3(0,3.61,0.4),Vector3(35,0.20,2.5),timber)
	kit.box(n,Vector3(0,3.40,-0.90),Vector3(35,0.12,0.20),plaster)
	kit.box(n,Vector3(0,3.84,0.65),Vector3(34.4,0.28,0.30),plaster)
	for i in range(24): kit.box(n,Vector3(-16.5+i*1.44,3.43,0.4),Vector3(0.11,0.12,2.7),timber)
	# Flush trim is on the existing solid walls. No new freestanding blocker is implied.
	for x in [-20.0,20.0]:
		kit.box(self,Vector3(x,2.74,2),Vector3(0.62,0.15,19),plaster)
		for z in [-5.0,0.0,5.0,10.0]:
			kit.box(self,Vector3(x,1.4,z),Vector3(0.54,2.6,0.48),kit.surface("b5a07c"))

func _build_stable(chapter: Node3D) -> void:
	var n:=_root(self,"StableKit");var timber:=kit.surface("75614a",2)
	for i in range(12): kit.box(n,Vector3(6.15+i*0.52,3.38,-4),Vector3(0.11,0.14,6),timber)
	# Cloth lies above the existing roof; support locations are unchanged.
	kit.canopy(n,Vector3(9,3.84,-4),Vector2(6.20,6.20),"bca984","79765d")
	for z in [-7.0,-1.0]:
		kit.rod(n,Vector3(6,2.8,z),Vector3(6.75,3.37,z),0.065,timber)
		kit.rod(n,Vector3(12,2.8,z),Vector3(11.25,3.37,z),0.065,timber)
	# Fine rope bindings hug existing posts rather than introducing noncolliding props in paths.
	for x in [6.0,12.0]:
		for z in [-7.0,-1.0]:
			for y in [2.85,2.91,2.97]:
				var torus:=TorusMesh.new();torus.inner_radius=0.12;torus.outer_radius=0.145;torus.rings=12;torus.ring_segments=6
				kit.mesh_at(n,torus,Vector3(x,y,z),kit.surface("ab9a77",4))
	# Existing rider and horse still supply all transformations and movement.
	var tack:=_root(chapter.horse,"TackStudy")
	kit.box(tack,Vector3(0,1.55,0.15),Vector3(0.93,0.08,0.9),kit.surface("69786e",4))
	for x in [-0.39,0.39]:
		kit.rod(tack,Vector3(x,1.85,-1.15),Vector3(x,2.05,-0.88),0.015,kit.plain("514232"))

func _build_market(chapter: Node3D) -> void:
	var n:=_root(self,"MarketKit");var timber:=kit.surface("7c6146",2)
	kit.canopy(n,Vector3(-24,3.30,-17.6),Vector2(4.15,3.1),"b19b77","6c7770")
	# These objects sit entirely on the existing solid market counter: no lane intrusion.
	for i in range(5):
		kit.pot(n,Vector3(-25.12+i*0.53,1.24,-17.62),0.43+0.05*(i%3),"946747" if i%2 else "aa7d51")
	for i in range(6): kit.box(n,Vector3(-24,0.96,-18.13+i*0.17),Vector3(2.9,0.11,0.09),timber)
	# Weathered closed shutters on the existing store wall; not newly enterable doors.
	var shutter:=_root(self,"StoreShutter");shutter.position=Vector3(-22.97,1.3,1.8);shutter.rotation.y=-PI/2
	kit.shutter(shutter,Vector3.ZERO,1.15)
	# Research marker remains in the inherited F2 notebook; no knowledge or inventory reward.
	var well: Node3D=chapter.fabric.get_node("household_well")
	for child in well.find_children("*","MeshInstance3D",true,false):
		if child.mesh is CylinderMesh: _replace_material(child,kit.surface("a38a65",1))

func set_enabled(value: bool) -> void:
	if manifest.is_empty(): return
	enabled=value
	for record in _changes:
		if not is_instance_valid(record.node): continue
		var prefix: String="new_" if value else "old_"
		record.node.mesh=record[prefix+"mesh"];record.node.material_override=record[prefix+"material"]
		record.node.scale=record[prefix+"scale"];record.node.layers=record[prefix+"layers"]
	for n in _roots:
		if is_instance_valid(n): n.visible=value
	# Self-owned free trim and attached roots must both follow the switch.
	visible=value
	if is_instance_valid(_hero_proxy): _hero_proxy.visible=value and _hero_mesh.visible
	if value: set_preset(preset)
	else:
		if is_instance_valid(_environment): _environment.environment=_original_environment
		if is_instance_valid(_sun):
			_sun.rotation_degrees=_original_sun.rotation;_sun.light_energy=_original_sun.energy;_sun.light_color=_original_sun.color

func set_preset(id: String) -> String:
	if manifest.is_empty() or not manifest.presets.has(id): return "Unknown lighting preset."
	preset=id
	if not enabled: return ""
	var p: Dictionary=manifest.presets[id]
	var environment:=_original_environment.duplicate(true)
	var sky:=Sky.new();var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color(p.sky_top);sky_material.sky_horizon_color=Color(p.sky_horizon)
	sky_material.ground_bottom_color=Color("6e745b");sky_material.ground_horizon_color=Color(p.sky_horizon)
	sky_material.sun_angle_max=8.0;sky.sky_material=sky_material
	environment.background_mode=Environment.BG_SKY;environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color(p.sky_horizon)
	environment.ambient_light_energy=float(p.ambient);environment.ambient_light_sky_contribution=0.0
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled=true;environment.fog_mode=Environment.FOG_MODE_DEPTH;environment.fog_sky_affect=0.2
	environment.fog_density=0.65;environment.fog_depth_begin=70;environment.fog_depth_end=260;environment.fog_light_color=Color(p.fog)
	_environment.environment=environment
	_sun.rotation_degrees=Vector3(p.sun_rotation[0],p.sun_rotation[1],p.sun_rotation[2])
	_sun.light_energy=float(p.sun_energy);_sun.light_color=Color(p.sun_color)
	return ""

func sample(tick: int) -> void:
	if tick<0: return
	last_tick=tick;kit.sample(tick)
	if is_instance_valid(_hero_proxy):
		_hero_proxy.visible=enabled and _hero_mesh.visible
		_hero_proxy.sample_tick(tick)

func report() -> Dictionary:
	return {"schema":"1792.home-art-observation.v1","model_id":manifest.get("id",""),"manifest_sha256":digest,
		"enabled":enabled,"preset":preset,"sampled_tick":last_tick,"replaced_meshes":_changes.size(),
		"new_mesh_instances":kit.mesh_count,"foliage_instances":kit.foliage_instances,"cloth_materials":kit.cloth_materials.size(),
		"georeferenced":false,"historical_truth_verified":false,"physical_gpu_qualified":false}

func _exit_tree() -> void:
	# Restore inherited resources and remove attachments even when only this component is removed.
	set_enabled(false)
	for n in _roots:
		if is_instance_valid(n) and not is_ancestor_of(n): n.queue_free()
