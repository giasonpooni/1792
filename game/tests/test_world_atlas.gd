# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Geo := preload("res://geography/geodesy.gd")
const Atlas := preload("res://geography/atlas.gd")
const Fortune := preload("res://geography/fortune_rules.gd")
const Exterior := preload("res://geography/sacred_exterior.gd")
const Player := preload("res://player/player.tscn")
const Launch := preload("res://childhood/home_launch.gd")
var passed := 0
var failed := 0
var observations: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("WORLD ATLAS FAIL: "+label)
func near(a: float, b: float, tolerance: float, label: String) -> void:
	check(absf(a-b)<=tolerance,label+" / "+str(a)+" vs "+str(b))
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func site(id: String="fixture_site", importance: int=3) -> Dictionary:
	return {"id":id,"importance":importance,"from":1780,"until":1800,
		"interior_enterable":false,"figures_embodied":false,
		"classification":"synthetic:qualification","evidence_scope":"Authored numerical/physical fixture; no actual religious site or ranking.",
		"frame_id":"qualification-local-metre","size_m":[10,6,10],"prayer_at_m":[0,0,8]}
func prayer(id: String="fixture_site", year: int=1792) -> Dictionary:
	return {"kind":"prayer","site_id":id,"year":year}

func geodesy_tests() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/geodesy_vectors.v1.json"))
	var max_ecef:=0.0;var max_local:=0.0
	for item in fixture.cases:
		var ecef:=Geo.ecef(item.point)
		var local:=Geo.to_local(item.point,item.origin)
		check(local.error.is_empty(),"reference frame accepted")
		if not local.error.is_empty(): continue
		for axis in range(3):
			near(ecef[axis],item.ecef[axis],0.000002,"independent PROJ ECEF")
			near(local.metres[axis],item.east_up_south[axis],0.000002,"independent PROJ local metres")
			max_ecef=maxf(max_ecef,absf(ecef[axis]-item.ecef[axis]))
			max_local=maxf(max_local,absf(local.metres[axis]-item.east_up_south[axis]))
		var inverse:=Geo.from_local(local.metres,item.origin)
		check(inverse.error.is_empty(),"inverse accepted")
		for axis in range(3): near(inverse.llh[axis],item.point[axis],0.000002 if axis==2 else 0.000000001,"inverse WGS84")
	var origin: Array=[74.2,32.1,230]
	for offset in [[1,0,0],[0,1,0],[0,0,1],[2048,0,0]]:
		var geographic:=Geo.from_local(offset,origin)
		check(geographic.error.is_empty(),"one-metre/edge metric point")
		# The exact radius boundary is tested in from_local; roundoff need not admit an outbound edge.
		if offset[0]!=2048:
			var roundtrip:=Geo.to_local(geographic.llh,origin)
			for axis in range(3): near(roundtrip.metres[axis],offset[axis],0.000002,"no scale compression")
	check(not Geo.from_local([2049,0,0],origin).error.is_empty(),"out-of-cell refuses rather than compresses")
	check(not Geo.to_local([77,28,100],origin).error.is_empty(),"faraway frame refuses")
	check(not Geo.from_local([0,0,0],origin,"EGM96").error.is_empty(),"vertical datum mismatch refuses")
	for invalid in [[true,32,0],[74,91,0],[181,32,0],[74,32,null],[74,32,NAN]]: check(Geo.ecef(invalid).is_empty(),"invalid geography refused")
	check(Geo.geographic_from_ecef([0,0,0]).is_empty(),"earth centre not a surface location")
	var other:=Geo.from_local([100,0,0],origin)
	var rebased:=Geo.reframe([150,2,-5],origin,other.llh)
	check(rebased.error.is_empty(),"coordinate-only reframe")
	var back:=Geo.reframe(rebased.metres,other.llh,origin)
	for axis in range(3): near(back.metres[axis],[150,2,-5][axis],0.000005,"reframe preserves physical point")
	check(Geo.cell_key(180,0)==Geo.cell_key(-180,0),"antimeridian ownership")
	check(Geo.cell_key(74,32)!=Geo.cell_key(73.999,32),"half-open index boundary")
	check(Geo.cell_key(0,90).is_empty(),"polar angular-cell refusal")
	observations.geodesy={"generator":fixture.generator,"max_ecef_error_m":max_ecef,"max_local_error_m":max_local,"local_radius_m":Geo.MAX_LOCAL_METRES}

func catalogue_tests() -> void:
	var atlas:=Atlas.new();check(atlas.load_catalogue().is_empty(),"packaged catalogues load")
	var data:=atlas.snapshot();check(data.places.size()==41 and data.theatres.size()==12,"catalogue inventory")
	check(atlas.plan().campaigns.size()==31,"editorial module inventory")
	var before:=atlas.snapshot();data.places[0].label="changed"
	check(atlas.snapshot()==before,"detached read-only world")
	check(atlas.summary("rohtas",1500).contains("not established"),"no pre-construction presence")
	check(atlas.summary("rohtas",1792).contains("broad period presence"),"source-bound broad period")
	check(atlas.summary("lahore",1792).contains("NOT ADMITTED"),"map label not a historical mesh")
	for field in ["scale","datum","source","geometry","importance","policy","terrain","epoch"]:
		var bad:=atlas.snapshot()
		match field:
			"scale": bad.metres_per_unit=100
			"datum": bad.geodetic_datum="EGM96"
			"source": bad.places[0].source_ids=["missing"]
			"geometry": bad.places[0].geometry={"fake":true}
			"importance": bad.places[0].importance=[5]
			"policy": bad.religious_policy.site_interiors=true
			"terrain": bad.terrain_assets=["invented"]
			"epoch": bad.epoch.until=1100
		check(not Atlas.validate(bad).is_empty(),"catalogue refusal: "+field)
	observations.catalogue={"content_sha256":atlas.digest,"plan_sha256":atlas.plan_digest,"loaded_terrain_assets":0}

func fortune_tests() -> void:
	var sites: Dictionary={}
	for importance in range(1,6): sites["site_"+str(importance)]=site("site_"+str(importance),importance)
	var digest:=Fortune.content_digest(sites)
	check(digest.length()==64,"site/rule content digest")
	var initial:=Fortune.initial(digest)
	var previous:=-1.0
	for importance in range(1,6):
		var result:=Fortune.append(initial,prayer("site_"+str(importance)),sites,digest,0)
		check(result.error.is_empty(),"valid outside-prayer rule")
		if not result.error.is_empty(): continue
		check(result.ledger.luck>previous,"importance increases bounded benefit")
		check(result.ledger.luck<=0.1,"benefit cap")
		previous=result.ledger.luck
	check(initial.events.is_empty(),"operation does not mutate source state")
	var first:=Fortune.append(initial,prayer("site_5"),sites,digest,0)
	check(not Fortune.append(first.state,prayer("site_4"),sites,digest,1).error.is_empty(),"global cross-site cooldown")
	check(not Fortune.append(first.state,prayer("site_5"),sites,digest,Fortune.COOLDOWN).error.is_empty(),"same-site cooldown")
	var weaker:=Fortune.append(first.state,prayer("site_1"),sites,digest,Fortune.COOLDOWN)
	check(weaker.error.is_empty(),"other site after global cooldown")
	check(weaker.ledger.expires==first.ledger.expires,"weaker visit cannot extend stronger luck")
	var repeat_visit:=Fortune.append(first.state,prayer("site_5"),sites,digest,Fortune.SITE_COOLDOWN)
	near(repeat_visit.ledger.luck,0.05,0.00000001,"repeat diminishing returns")
	near(Fortune.luck(first.ledger,Fortune.DURATION),0,0,"effect expires on the supplied world tick")
	for year in [1779,1800]: check(not Fortune.append(initial,prayer("site_1",year),sites,digest,0).error.is_empty(),"out-of-period significance refuses")
	var value:=initial
	for i in range(5):
		var bad_conduct:=Fortune.append(value,{"kind":"conduct","delta":-20,"reason_id":"qualification_broken_oath"},sites,digest,i)
		check(bad_conduct.error.is_empty(),"conduct operation")
		value=bad_conduct.state
	var observed:=Fortune.append(value,prayer("site_5"),sites,digest,5)
	check(Fortune.karma(observed.ledger)<-90,"prayer does not erase serious conduct")
	var low_grievance:=Fortune.probability("betrayal",0.2,observed.ledger,5,1,0)
	var high_grievance:=Fortune.probability("betrayal",0.2,observed.ledger,5,1,1)
	check(high_grievance.probability>low_grievance.probability,"concrete grievances remain independent")
	near(Fortune.probability("assassination",0.2,observed.ledger,5,0).probability,0,0,"no opportunity means no invented attempt")
	for endpoint in [0.0,1.0]: near(Fortune.probability("warning",endpoint,first.ledger,0).probability,endpoint,0,"impossible/certain events fixed")
	near(Fortune.probability("assassination",0.2,first.ledger,0,1,1,true).probability,0.2,0,"fixed history is not rewritten")
	check(not Fortune.probability("sword_damage",0.2,first.ledger,0).error.is_empty(),"no damage buff")
	check(not Fortune.probability("warning",NAN,first.ledger,0).error.is_empty(),"nonfinite probability refuses")
	var changed_sites: Dictionary=sites.duplicate(true);changed_sites.site_5.importance=1
	check(not Fortune.replay(first.state,changed_sites,digest,0).error.is_empty(),"changed site weight invalidates old receipts")
	check(Fortune.content_digest(changed_sites)!=digest,"actual site definitions bind the content digest")
	check(Fortune.content_digest(JSON.parse_string(JSON.stringify(sites)))==digest,"site digest stable across JSON number types")
	var forged_ledger: Dictionary=first.ledger.duplicate(true);forged_ledger.luck=2.0
	check(not Fortune.probability("warning",0.2,forged_ledger,0).error.is_empty(),"out-of-range effect refuses")
	var roundtrip: Variant=JSON.parse_string(JSON.stringify(first.state))
	check(Fortune.replay(roundtrip,sites,digest,0).error.is_empty(),"receipt JSON roundtrip")
	check(not Fortune.replay(first.state,sites,"b".repeat(64),0).error.is_empty(),"changed content refuses")
	for kind in ["seq","future","extra","importance","reason"]:
		var bad: Dictionary=first.state.duplicate(true)
		match kind:
			"seq": bad.events[0].seq=true
			"future": bad.events[0].tick=1
			"extra": bad.events[0].magic=1
			"importance": bad.events[0].importance=5
			"reason": bad.events[0]={"seq":1,"tick":0,"kind":"conduct","delta":20,"unknown":true}
		check(not Fortune.replay(bad,sites,digest,0).error.is_empty(),"receipt refusal: "+kind)
	var bounded:=initial
	for i in range(Fortune.MAX_EVENTS):
		var result:=Fortune.append(bounded,{"kind":"conduct","delta":1,"reason_id":"qualification_only"},sites,digest,i)
		if not result.error.is_empty(): check(false,"bounded receipt setup");break
		bounded=result.state
	check(not Fortune.append(bounded,prayer("site_1"),sites,digest,Fortune.MAX_EVENTS).error.is_empty(),"bounded receipt capacity")
	observations.fortune={"model_id":Fortune.VERSION,"operation_id":"exterior-prayer.v1","first_luck":first.ledger.luck,"repeat_luck":repeat_visit.ledger.luck,"negative_karma_after_prayer":Fortune.karma(observed.ledger),"campaign_save_integration":false}

func floor_for(parent: Node3D) -> StaticBody3D:
	var floor_body:=StaticBody3D.new();floor_body.position.y=-0.5;parent.add_child(floor_body)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(40,1,40);collision.shape=shape;floor_body.add_child(collision)
	return floor_body

func physical_tests() -> void:
	var world:=Node3D.new();root.add_child(world);floor_for(world)
	var exterior:=Exterior.new();world.add_child(exterior)
	var definition:=site();var sites: Dictionary={definition.id:definition}
	var digest:=Fortune.content_digest(sites)
	check(not exterior.build(definition).is_empty(),"qualification requires explicit admission")
	check(exterior.build(definition,true).is_empty(),"metric fixture builds")
	check(not exterior.build(definition,true).is_empty(),"no duplicate geometry")
	var actual:=Exterior.new();world.add_child(actual)
	var counterfeit:=site();counterfeit.classification="reviewed:gameplay"
	check(not actual.build(counterfeit,true).is_empty(),"generic box cannot impersonate a surveyed religious site")
	var actor: CharacterBody3D=Player.instantiate();actor.position=Vector3(0,0.04,12);world.add_child(actor)
	actor.menu_shortcut=false;actor.pivot.rotation=Vector3.ZERO
	await frames(12)
	check(not exterior.access_error(actor,Vector3.FORWARD,definition.frame_id,1792).is_empty(),"remote interaction refused")
	# Actual shared-player input journey after labelled spawn; no later pose injection on this route.
	Input.action_press("move_forward")
	for _i in range(150):
		await physics_frame
		if actor.global_position.z<=8.8: break
	Input.action_release("move_forward");await frames(20)
	var receipt:=exterior.pray(actor,Vector3.FORWARD,definition.frame_id,1792,Fortune.initial(digest),sites,digest,int(Engine.get_physics_frames()))
	check(receipt.error.is_empty(),"actual physical exterior approach admits prayer")
	check(not exterior.access_error(actor,Vector3.BACK,definition.frame_id,1792).is_empty(),"must face exterior")
	check(not exterior.access_error(actor,Vector3.FORWARD,"another_frame",1792).is_empty(),"frame mismatch")
	check(not exterior.access_error(actor,Vector3.FORWARD,definition.frame_id,1792,true).is_empty(),"mounted refusal")
	# A new wall invalidates access previously admitted: execution rechecks physical evidence.
	var blocker:=StaticBody3D.new();blocker.position=Vector3(0,1.2,7.4);world.add_child(blocker)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2,2,0.2);collision.shape=shape;blocker.add_child(collision)
	await frames(3)
	check(not exterior.pray(actor,Vector3.FORWARD,definition.frame_id,1792,Fortune.initial(digest),sites,digest,0).error.is_empty(),"late occluder refuses queued action")
	world.remove_child(blocker);blocker.queue_free();await frames(3)
	check(exterior.access_error(actor,Vector3.FORWARD,definition.frame_id,1792).is_empty(),"removing actual wall restores access")
	Input.action_press("move_forward");await frames(140);Input.action_release("move_forward");await frames(15)
	check(actor.global_position.z>5.3,"solid exterior blocks original capsule")
	observations.physical={"setup":"authored 10x6x10 metre enclosure; original player; no historical site mesh","final_position":[actor.global_position.x,actor.global_position.y,actor.global_position.z],"input_driven_approach":true}
	# Explicit adversarial transform fixture, separate from the input journey.
	actor.position=Vector3(0,0,0);await frames(1)
	check(not exterior.access_error(actor,Vector3.FORWARD,definition.frame_id,1792).is_empty(),"injected interior pose cannot pray")
	root.remove_child(world);world.queue_free();await frames(3)

func integration_tests() -> void:
	var home:=Launch.make_world();root.add_child(home);await frames(12)
	var chapter=home.get_node("ChildhoodChapter")
	var before: Dictionary=chapter.model.snapshot()
	var key:=InputEventKey.new();key.keycode=KEY_F3;key.pressed=true
	chapter._unhandled_input(key);await frames(4)
	check(chapter._paused and is_instance_valid(chapter.atlas_panel),"F3 opens atlas in original home")
	var at_open: Dictionary=chapter.model.snapshot()
	check(before==at_open,"opening does not mutate world")
	chapter.atlas_panel.slider.value=1420;chapter.atlas_panel.select_place("rohtas");await frames(20)
	check(chapter.model.snapshot()==at_open,"inspection year changes no clock, supplies, story or knowledge")
	check(not chapter.atlas_panel.detail.text.is_empty(),"source/uncertainty details visible")
	chapter.atlas_panel.close_button.pressed.emit();await frames(2)
	check(not chapter._paused and not is_instance_valid(chapter.atlas_panel),"return resumes same controller")
	check(chapter.model.snapshot().childhood.tick>=at_open.childhood.tick,"same clock resumes")
	chapter._show_dialog("Existing dialogue","No nested atlas",[["Return","resume"]])
	chapter.open_atlas();check(not is_instance_valid(chapter.atlas_panel),"does not replace existing dialogue")
	root.remove_child(home);home.queue_free();await frames(3)

func run() -> void:
	geodesy_tests();catalogue_tests();fortune_tests();await physical_tests();await integration_tests()
	var source_hashes: Dictionary={}
	for path in ["res://geography/geodesy.gd","res://geography/atlas.gd","res://geography/fortune_rules.gd","res://geography/sacred_exterior.gd","res://tests/test_world_atlas.gd"]:
		source_hashes[path]=FileAccess.get_file_as_string(path).sha256_text()
	var report: Dictionary={"verification_id":"historical-world-native.v1","execution_id":OS.get_environment("GITHUB_RUN_ID") if not OS.get_environment("GITHUB_RUN_ID").is_empty() else "local-process-"+str(OS.get_process_id()),"engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,"passed":passed,"failed":failed,"source_sha256":source_hashes,"observations":observations,"human_playtested":false}
	var file:=FileAccess.open("user://historical-world-tests.json",FileAccess.WRITE)
	if file==null: check(false,"write qualification report")
	else: file.store_string(JSON.stringify(report,"\t"));file.close()
	print("WORLD_ATLAS_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
