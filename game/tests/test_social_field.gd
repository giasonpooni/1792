# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Synthetic domain and scene fixtures. Not a historical calibration or human playtest.
const Rules := preload("res://politics/exposure_rules.gd")
const Social := preload("res://politics/social_field_rules.gd")
const Profile := preload("res://politics/social_field_profile.gd")
const Registry := preload("res://politics/social_registry.gd")
const Campaign := preload("res://politics/political_state.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const World := preload("res://world/political_home.tscn")
var checks := 0
var failures := 0
var observations: Array = []

func _initialize() -> void: _run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)
func wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"",true,true))
func actor(runtime: Dictionary, id: String, tick: int) -> Dictionary:
	return Social.sample(runtime.social,id,"sukerchakia",tick)
func receipt() -> Dictionary:
	return {"id":"receipt:a", "event_id":"event:a", "observer_id":"fictional_market_keeper",
		"accused":"sukerchakia", "kind":"raid", "strength":0.34, "confidence":0.5,
		"source_id":"local_witness", "sent_tick":60, "received_tick":240,
		"parent_receipt_id":"parent:a", "path":["bhangi:report_node","market"]}

func _run() -> void:
	check(Social.validate_profiles(Profile.ACTORS,Registry.FACTIONS).is_empty(),"declared graph admitted")
	check(Registry.validate_records(Registry.RELATIONS).is_empty(),"new fictional identities retain registry provenance")
	for id in Profile.ACTORS:
		check(Registry.PEOPLE.has(id) and Registry.faction(id)==Profile.ACTORS[id].faction,"profile resolves to canonical registry: "+id)
	var bad_profile := Profile.ACTORS.duplicate(true)
	bad_profile.raj_kaur.delay = -1
	check(not Social.validate_profiles(bad_profile,Registry.FACTIONS).is_empty(),"negative delay refused")
	bad_profile = Profile.ACTORS.duplicate(true)
	bad_profile.raj_kaur.reliability = NAN
	check(Social.initial(bad_profile,Registry.FACTIONS).is_empty(),"nonfinite profile fails closed")
	check(not Social.validate_profiles(Profile.ACTORS,["sukerchakia","sukerchakia"]).is_empty(),"duplicate subjects refused")
	var generic := {"observer":{"faction":"harbour", "node":"dock", "delay":10, "reliability":0.8}}
	check(not Social.initial(generic,["harbour","village"]).is_empty(),"kernel accepts non-1792 identities")

	var log := Rules.initial()
	check(Rules.append(log,0,"raid","ranjit_singh","bhangi").is_empty(),"raid admitted through existing ledger")
	var early := Rules.project(log,60)
	check(early.factions.bhangi.resources<100.0,"world damage precedes local knowledge")
	for id in Profile.ACTORS:
		check(actor(early,id,60).event_roots.is_empty(),"no instantaneous observer knowledge: "+id)
	check(Rules.project(log,180).pairs["bhangi:sukerchakia"].grievance>0.3,"existing faction delivery unchanged")
	check(actor(Rules.project(log,180),"fictional_market_keeper",180).stance=="open","local market link has its own delay")
	var market := Rules.project(log,240)
	check(actor(market,"fictional_market_keeper",240).stance=="guarded","market hears and changes response")
	check(actor(market,"fictional_gate_keeper",240).stance=="open","distant gate has not heard")
	check(actor(Rules.project(log,480),"fictional_north_observer",480).stance=="open","faction relay does not instantly inform retainer")
	var north := Rules.project(log,540)
	check(not actor(north,"fictional_north_observer",540).event_roots.is_empty(),"north-lane receipt arrives")
	check(actor(north,"fictional_gate_keeper",540).event_roots.is_empty(),"same-bloc gate keeper still waits")
	var gate := Rules.project(log,660)
	check(actor(gate,"fictional_gate_keeper",660).stance=="reserved","attenuated gate report produces different response")
	check(actor(gate,"raj_kaur",660).event_roots.is_empty(),"no route means no knowledge")
	check(gate.player_reports.is_empty(),"NPC beliefs never become player reports")
	observations = [actor(early,"fictional_market_keeper",60),actor(market,"fictional_market_keeper",240),actor(gate,"fictional_gate_keeper",660)]

	var repaired := log.duplicate(true)
	check(Rules.append(repaired,180,"reparation","ranjit_singh","bhangi").is_empty(),"reparation is an existing positive operation")
	check(actor(Rules.project(repaired,300),"fictional_market_keeper",300).stance=="guarded","reparation is not instant forgiveness")
	var repair := actor(Rules.project(repaired,360),"fictional_market_keeper",360)
	check(repair.stance=="reassured" and repair.field.obligation>0.0,"received reparation restores some trust and obligation")
	check(actor(Rules.project(repaired,660),"fictional_gate_keeper",660)==actor(gate,"fictional_gate_keeper",660),"one local repair cannot clear another actor's memory")
	observations.append(repair)
	var cooled := actor(Rules.project(log,7260),"fictional_market_keeper",7260)
	check(cooled.stance=="open" and cooled.event_roots.is_empty(),"finite memory horizon is explicit")

	var state := Social.initial(Profile.ACTORS,Registry.FACTIONS)
	var r := receipt()
	var before := state.duplicate(true)
	check(not Social.receive(state,r,239).is_empty() and state==before,"early receipt refuses atomically")
	check(Social.receive(state,r,240).is_empty(),"due receipt accepted")
	before = state.duplicate(true)
	check(Social.receive(state,r,240).is_empty() and state==before,"exact duplicate has no extra effect")
	var echo := r.duplicate(true)
	echo.id = "receipt:echo"
	echo.source_id = "another_teller"
	check(Social.receive(state,echo,240).is_empty() and state==before,"same root is not independent corroboration")
	echo.confidence = 0.9
	check(Social.receive(state,echo,240).is_empty(),"better confidence replaces, not adds")
	check(state.actors.fictional_market_keeper.memory.size()==1,"one retained claim per event root")
	check(is_equal_approx(Social.sample(state,"fictional_market_keeper","sukerchakia",240).field.grievance,0.34*0.9*0.975),"replacement uses one age-weighted contribution")
	before = state.duplicate(true)
	for key in ["confidence", "strength"]:
		var invalid := r.duplicate(true)
		invalid[key] = NAN
		check(not Social.receive(state,invalid,240).is_empty() and state==before,"nonfinite receipt fails atomically: "+key)
	var conflict := r.duplicate(true)
	conflict.accused = "phulkian"
	check(not Social.receive(state,conflict,240).is_empty() and state==before,"event identity cannot change accused")
	conflict = r.duplicate(true)
	conflict.sent_tick = 61
	check(not Social.receive(state,conflict,240).is_empty() and state==before,"echo cannot refresh original incident age")
	conflict = r.duplicate(true)
	conflict.observer_id = "unknown"
	check(not Social.receive(state,conflict,240).is_empty() and state==before,"unregistered observer refused")
	check(Social.sample(state,"unknown","sukerchakia",240).is_empty(),"unknown observer query has no fallback")
	check(Social.sample(state,"fictional_market_keeper","sukerchakia",180).event_roots.is_empty(),"query before receipt does not leak future memory")
	for i in range(Social.MAX_MEMORY+3):
		var item := receipt()
		item.event_id = "bounded:%d"%i
		item.id = "bounded-receipt:%d"%i
		item.sent_tick = 300+i
		item.received_tick = 500+i
		check(Social.receive(state,item,500+i).is_empty(),"bounded receipt admitted")
		check(state.actors.fictional_market_keeper.memory.size()<=Social.MAX_MEMORY,"memory capacity enforced")
	before = state.duplicate(true)
	check(not Social.receive(state,r,900).is_empty() and state==before,"evicted old event cannot be replayed as new")

	var incremental := Rules.runtime(0)
	for tick in range(60,3601,60):
		Rules.advance(incremental,repaired,tick)
		for id in Profile.ACTORS:
			for value in actor(incremental,id,tick).field.values(): check(is_finite(value) and value>=0 and value<=1,"bounded field component")
	check(incremental==Rules.project(repaired,3600),"incremental and full reducer replay agree")
	check(incremental==Rules.project(wire(repaired),3600),"JSON input roundtrip has identical field projection")
	var snapshot := incremental.duplicate(true)
	for id in Profile.ACTORS: actor(incremental,id,3600)
	check(incremental==snapshot,"observation queries do not alter memory")

	var m := Campaign.new()
	check(m.restore(Fixture.complete()).is_empty(),"import existing completed-inquiry fixture")
	var clean := m.snapshot()
	check(Pose.pose(m,Campaign.OUTPOSTS.bhangi+Vector3.BACK*2).is_empty(),"site-bound raid fixture")
	check(m.order_political("raid","bhangi").is_empty(),"world authority accepts raid")
	for _i in range(120): m.advance()
	var pending: Dictionary = wire(m.snapshot())
	var restored := Campaign.new()
	check(restored.restore(pending).is_empty(),"save with pending receipts restores")
	for _i in range(600):
		m.advance()
		restored.advance()
	check(m.political_debug()==restored.political_debug(),"pending deliveries reproduced on same clock")
	check(not m.snapshot().has("social") and not m.snapshot().politics.has("social"),"no second authoritative saved social state")
	check(m.local_social_response("fictional_market_keeper",true).is_empty(),"remote dialogue cannot expose response")
	check(Pose.pose(m,Profile.SITES.fictional_market_keeper+Vector3.BACK*2).is_empty(),"market conversation fixture")
	before = m.snapshot()
	check(m.local_social_response("fictional_market_keeper",false).is_empty(),"occluded conversation returns no cue")
	var cue := m.local_social_response("fictional_market_keeper",true)
	check(cue.size()==4 and cue.channel=="local_conversation" and cue.text.contains("brief"),"public projection only exposes situated dialogue")
	for key in ["field", "stance", "event_roots", "queue", "confidence", "accused"]: check(not cue.has(key),"private field excluded: "+key)
	check(m.snapshot()==before,"hearing presentation does not mutate saves or economy")
	check(m.restore(clean).is_empty(),"rewind to pre-incident snapshot")
	check(m.social_debug("fictional_market_keeper").event_roots.is_empty(),"rewind discards future social knowledge")

	var world: Node3D = World.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var scene = world.get_node("ChildhoodChapter")
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	check(scene.model==scene.campaign,"scene retains one world authority")
	check(scene._social_visuals.size()==2,"two new local residents exist")
	check(scene.campaign.restore(restored.snapshot()).is_empty(),"scene admits incident fixture")
	check(Pose.pose(scene.campaign,Profile.SITES.fictional_market_keeper+Vector3.BACK*2).is_empty(),"scene moves fixture to market")
	scene._apply()
	scene.avatar.set_physics_process(false)
	scene.avatar.pivot.rotation = Vector3.ZERO
	await physics_frame
	check(scene._candidate_error(scene.campaign).is_empty(),"resident does not block existing standing geometry")
	check(scene._seen(Profile.SITES.fictional_market_keeper+Vector3.UP,4),"physical scene permits local sightline")
	scene._interact()
	check(scene._paused and scene._panel_text.text.contains("LOCAL CONVERSATION") and scene._panel_text.text.contains("brief"),"actual interaction opens received-response dialogue")
	check(not scene._panel_text.text.contains("grievance") and not scene._hud.text.contains("grievance"),"HUD/dialogue do not expose hidden scores")
	before = scene.campaign.snapshot()
	await physics_frame
	check(before==scene.campaign.snapshot(),"dialogue pauses existing clock")
	scene._resume()
	scene.set_physics_process(false)
	scene.avatar.set_physics_process(false)
	var wall = scene._box(Vector3(1.0,3.0,0.25),Profile.SITES.fictional_market_keeper+Vector3(0,1.3,1),Color.GRAY,true)
	await physics_frame
	check(not scene._seen(Profile.SITES.fictional_market_keeper+Vector3.UP,4),"real wall blocks reading the local response")
	wall.get_parent().queue_free()
	world.queue_free()
	await process_frame
	_write_evidence()
	print("SOCIAL_FIELD_TESTS: %d assertions; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

func _write_evidence() -> void:
	var path := "user://social-field-observation.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-out="): path = arg.trim_prefix("--evidence-out=")
	var hashes: Dictionary = {}
	for source in ["politics/social_field_rules.gd","politics/social_field_profile.gd","politics/social_registry.gd","politics/exposure_rules.gd","politics/political_state.gd","politics/political_chapter.gd","tests/test_social_field.gd"]:
		hashes[source] = FileAccess.get_file_as_string("res://"+source).sha256_text()
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file!=null,"evidence output opened")
	if file==null: return
	var execution := OS.get_environment("GITHUB_RUN_ID")+":"+OS.get_environment("GITHUB_RUN_ATTEMPT")
	if execution==":": execution = "local:%d:%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	var report := {"schema":"1792.social-field-observation.v1", "model_id":Profile.VERSION,
		"operation_id":"1792.social-field.conformance.v1", "execution_id":execution,
		"source_commit":OS.get_environment("GITHUB_SHA"), "engine":Engine.get_version_info().string,
		"audience":"privileged_test_observer", "evidence_class":"synthetic_conformance",
		"verification_policy":"1792.social-field.tests.v1", "historical_truth_verified":false,
		"rules_sha256":hashes, "observations":observations, "assertions":checks, "failures":failures}
	report.evidence_id = JSON.stringify(report,"",true,true).sha256_text()
	file.store_string(JSON.stringify(report,"\t",true,true))
	file.close()
