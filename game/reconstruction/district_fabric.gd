# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends Node3D
## Original primitive geometry. Research admission is separate from game-state authority.
const PATH := "res://data/gujranwala_reconstruction.v1.json"
const KINDS := ["arcade","courtyard","ground","stall","well","sacks","field"]
var manifest: Dictionary = {}
var digest := ""
var built_features: Array[String] = []
var _ambient: Array[Node3D] = []
var _materials: Dictionary = {}

static func vector(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

static func _vec(value: Variant, positive: bool = false) -> bool:
	if not value is Array or value.size()!=3: return false
	for n in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)) or absf(n)>500: return false
		if positive and n<=0: return false
	return true

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.get("schema")!="1792.gujranwala-reconstruction.v1": return "Unknown reconstruction contract."
	if value.get("year")!=1792 or value.get("georeferenced")!=false: return "Wrong epoch or invented georeferencing."
	if value.get("id")!="gujranwala-fabric.v1" or value.get("frame")!="gujranwala-compressed-local-metres": return "Unsupported model frame."
	var bounds: Variant=value.get("extent")
	if not bounds is Array or bounds.size()!=4: return "Invalid bounds."
	# JSON numbers are floats in Godot; Array equality is type-sensitive.
	var expected: Array[float]=[-28.0,28.0,-28.0,28.0]
	for i in range(4):
		if typeof(bounds[i]) not in [TYPE_INT,TYPE_FLOAT] or float(bounds[i])!=expected[i]: return "Unsupported bounds."
	for key in ["features","claims","sources","exclusions","routes","ambient"]:
		if not value.get(key) is Array: return "Missing reconstruction collection: "+key
	var sources: Array=[]
	for source in value.sources:
		if not source is Dictionary or not source.get("id") is String or source.id in sources: return "Duplicate or malformed source."
		if not source.get("locator") is String or source.locator.is_empty() or not source.get("evidence_scope") is String or source.evidence_scope.is_empty(): return "Source limits and locator required."
		sources.append(source.id)
	var claims: Array=[]
	for claim in value.claims:
		if not claim is Dictionary or not claim.get("id") is String or claim.id in claims or not claim.get("source_ids") is Array or claim.source_ids.is_empty(): return "Malformed claim."
		for source in claim.source_ids:
			if source not in sources: return "Unresolved source."
		claims.append(claim.id)
	var excluded: Array=[]
	for item in value.exclusions:
		if not item is Dictionary or not item.get("id") is String: return "Malformed temporal exclusion."
		if item.id in excluded: return "Duplicate exclusion."
		excluded.append(item.id)
	if "mahan_singh_samadhi" not in excluded or "sheranwala_baradari" not in excluded: return "Missing mandatory temporal exclusions."
	var seen: Array=[]
	for feature in value.features:
		if not feature is Dictionary or not feature.get("id") is String or feature.id in seen or feature.id in excluded: return "Duplicate or excluded feature."
		seen.append(feature.id)
		if feature.get("kind") not in KINDS or not _vec(feature.get("position")) or not _vec(feature.get("size"),true): return "Invalid geometry."
		if not feature.get("collision") is bool or feature.get("placement_class")!="B" or feature.get("geometry_class")!="C": return "Unsupported representation claim."
		if feature.collision and (feature.kind!="well" or absf(feature.position[0])+feature.size[0]/2>28 or absf(feature.position[2])+feature.size[2]/2>28): return "Unqualified collision geometry."
		if feature.get("earliest_year")!=null and (typeof(feature.earliest_year) not in [TYPE_INT,TYPE_FLOAT] or feature.earliest_year>1792): return "Future structure rejected."
		if not feature.get("claim_ids") is Array or feature.claim_ids.is_empty(): return "Feature has no evidence binding."
		for claim in feature.claim_ids:
			if claim not in claims: return "Unresolved feature claim."
		if feature.kind=="arcade" and (not feature.get("bays") is int and not feature.get("bays") is float): return "Invalid arcade bays."
		if feature.kind=="arcade" and (feature.bays!=floor(feature.bays) or feature.bays<1 or feature.bays>12): return "Invalid arcade bays."
	var routes: Array=[]
	for route in value.routes:
		if not route is Dictionary or route.get("id") not in ["caravan_return","well_approach"] or route.id in routes: return "Invalid route identity."
		if not route.get("points") is Array or route.points.size()<2: return "Invalid route."
		if typeof(route.get("clearance")) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(route.clearance) or route.clearance<1: return "Invalid clearance."
		for point in route.points:
			if not _vec(point): return "Invalid route coordinate."
		routes.append(route.id)
	if routes.size()!=2: return "Missing protected route."
	var people: Array=[]
	for person in value.ambient:
		if not person is Dictionary or not person.get("points") is Array or person.points.size()!=2: return "Invalid ambient path."
		if not person.get("id") is String or person.id in people: return "Invalid ambient identity."
		people.append(person.id)
		if not _vec(person.points[0]) or not _vec(person.points[1]): return "Invalid ambient coordinates."
		if typeof(person.get("period_ticks")) not in [TYPE_INT,TYPE_FLOAT] or person.period_ticks<120 or person.period_ticks!=floor(person.period_ticks): return "Invalid ambient period."
	return ""

func build() -> String:
	if not manifest.is_empty(): return "District already built."
	var text:=FileAccess.get_file_as_string(PATH)
	var candidate: Variant=JSON.parse_string(text)
	var error:=validate(candidate)
	if not error.is_empty(): return error
	manifest=candidate.duplicate(true)
	digest=text.sha256_text()
	for feature in manifest.features:
		var root:=Node3D.new()
		root.name=feature.id
		root.position=vector(feature.position)
		root.set_meta("claim_ids",feature.claim_ids.duplicate())
		root.set_meta("placement_class",feature.placement_class)
		add_child(root)
		_build_feature(root,feature)
		built_features.append(feature.id)
	for person in manifest.ambient:
		var root:=Node3D.new()
		root.name=person.id
		root.set_meta("role","ambient_only_not_a_witness")
		add_child(root)
		box(root,Vector3(0,0.8,0),Vector3(0.5,1.5,0.45),"7a7564")
		box(root,Vector3(0,1.65,0),Vector3(0.4,0.4,0.4),"b0a088")
		_ambient.append(root)
	update_from_tick(0)
	return ""

func material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var m:=StandardMaterial3D.new()
		m.albedo_color=Color(color)
		m.roughness=1
		_materials[color]=m
	return _materials[color]

func box(root: Node3D, at: Vector3, size: Vector3, color: String, solid: bool=false) -> void:
	var n: Node3D=StaticBody3D.new() if solid else Node3D.new()
	n.position=at
	root.add_child(n)
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new()
	shape.size=size
	mesh.mesh=shape
	mesh.material_override=material(color)
	n.add_child(mesh)
	if solid:
		var c:=CollisionShape3D.new()
		var b:=BoxShape3D.new()
		b.size=size
		c.shape=b
		n.add_child(c)

func _build_feature(root: Node3D, f: Dictionary) -> void:
	var s:=vector(f.size)
	match f.kind:
		"ground", "field":
			box(root,Vector3.ZERO,s,"ac976e" if f.kind=="ground" else "91a063")
			if f.kind=="field":
				for i in range(1,9): box(root,Vector3(-s.x/2+s.x*i/9,0.04,0),Vector3(0.15,0.04,s.z),"b29b71")
		"courtyard":
			for x in [-s.x/2,s.x/2]: box(root,Vector3(x,s.y/2,0),Vector3(0.5,s.y,s.z),"ac8861")
			box(root,Vector3(0,s.y/2,s.z/2),Vector3(s.x,s.y,0.5),"ac8861")
			for side in [-1,1]: box(root,Vector3(side*(s.x/4+0.65),s.y/2,-s.z/2),Vector3(s.x/2-1.3,s.y,0.5),"ac8861")
			box(root,Vector3(0,0.05,0),Vector3(s.x,0.1,s.z),"baa37c")
			box(root,Vector3(0,s.y,s.z/2-1),Vector3(s.x+0.5,0.2,3),"765b40")
		"arcade":
			var step: float=s.x/float(f.bays)
			for i in range(int(f.bays)+1): box(root,Vector3(-s.x/2+i*step,1.3,0),Vector3(0.35,2.6,0.35),"ab845b")
			for i in range(int(f.bays)):
				var center: float=-s.x/2+(i+0.5)*step
				for j in range(12):
					var angle: float=PI*(j+0.5)/12
					var segment:=Node3D.new()
					segment.position=Vector3(center+cos(angle)*step/2,2.1+sin(angle)*1.1,0)
					segment.rotation.z=angle-PI/2
					root.add_child(segment)
					box(segment,Vector3.ZERO,Vector3(step*0.16,0.2,0.4),"986443")
			box(root,Vector3(0,s.y,0.4),Vector3(s.x+1,0.2,s.z),"6c5139")
		"stall":
			for x in [-s.x/2,s.x/2]: box(root,Vector3(x,s.y/2,0),Vector3(0.15,s.y,0.15),"6c5139")
			box(root,Vector3(0,s.y,0),Vector3(s.x+0.4,0.13,s.z),"b59867")
			box(root,Vector3(0,0.5,0),Vector3(s.x*0.8,1,s.z*0.6),"926c43")
		"sacks":
			for i in range(3): box(root,Vector3((i-1)*0.7,0.35,0),Vector3(0.6,0.7,0.7),"c3b68a")
		"well":
			var body:=StaticBody3D.new()
			root.add_child(body)
			var mesh:=MeshInstance3D.new()
			var cylinder:=CylinderMesh.new()
			cylinder.top_radius=s.x/2
			cylinder.bottom_radius=s.x/2
			cylinder.height=s.y
			mesh.mesh=cylinder
			mesh.position.y=s.y/2
			mesh.material_override=material("9a8566")
			body.add_child(mesh)
			if f.collision:
				var collision:=CollisionShape3D.new()
				var shape:=CylinderShape3D.new()
				shape.radius=s.x/2
				shape.height=s.y
				collision.shape=shape
				collision.position.y=s.y/2
				body.add_child(collision)
			box(root,Vector3(0,s.y+0.01,0),Vector3(s.x*0.65,0.02,s.z*0.65),"586f6b")
			for x in [-s.x/2,s.x/2]: box(root,Vector3(x,1.4,0),Vector3(0.13,2.8,0.13),"705a40")
			box(root,Vector3(0,2.8,0),Vector3(s.x+0.2,0.15,0.15),"705a40")
			box(root,Vector3(0,2,0),Vector3(0.04,1.5,0.04),"c3b68a")

func update_from_tick(tick: int) -> void:
	# Presentation is a pure sample of the existing clock: no new agents, memories or timers.
	for i in range(_ambient.size()):
		var record: Dictionary=manifest.ambient[i]
		var phase: float=float(posmod(tick,int(record.period_ticks)))/float(record.period_ticks)
		var amount: float=1.0-absf(2.0*phase-1.0)
		_ambient[i].position=vector(record.points[0]).lerp(vector(record.points[1]),amount)

func notebook() -> String:
	return "RECONSTRUCTION NOTEBOOK — development reference, not Buddh's knowledge\n\nCourtyards, verandahs and an open forecourt use a published architectural study as comparison. Exact placements, proportions and trade fixtures are authored.\n\nMahan Singh's later samadhi is excluded. Sheranwala's pavilion is deferred because construction attributions conflict. A surviving building is not a complete 1792 plan.\n\nThe playable bounds, actors, saves and caravan routes are retained. Peripheral houses and fields are scenery; ambient figures do not report, trade or become witnesses.\n\nLayout: %s\nContent SHA-256: %s\n\nRead docs/GUJRANWALA_1792.md and the source/claim records for evidence limits." % [manifest.id,digest]
