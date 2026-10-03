extends SceneTree
## Domain and scene fixtures are explicitly synthetic, not a claim of human playtesting.
const Rules := preload("res://politics/exposure_rules.gd")
const Vision := preload("res://perception/vision_rules.gd")
const Registry := preload("res://politics/social_registry.gd")
const Campaign := preload("res://politics/political_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const Checkpoint := preload("res://childhood/checkpoint_store.gd")
const World := preload("res://world/political_home.tscn")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: "+message)

func wire(value: Variant) -> Variant:
	# JSON has one number type; compare full serialized values rather than Variant type tags.
	return JSON.parse_string(JSON.stringify(value,"",true,true))

func _complete() -> Campaign:
	var m := Campaign.new()
	check(m.restore(Fixture.survived()).is_empty(),"import survived fixture")
	check(Fixture.pose(m,Campaign.SITES.steward+Vector3.RIGHT).is_empty(),"steward fixture pose")
	check(m.hear_return("steward").is_empty(),"hear return steward")
	check(Fixture.pose(m,Campaign.SITES.courier+Vector3.RIGHT).is_empty(),"courier fixture pose")
	check(m.hear_return("courier").is_empty(),"hear return courier")
	check(Fixture.pose(m,Campaign.MOTHER+Vector3.FORWARD*2.0).is_empty(),"mother fixture pose")
	check(m.hear_offer().is_empty(),"hear protection offer")
	check(m.decide_protection("independent_inquiry").is_empty(),"independent inquiry")
	check(Fixture.pose(m,Campaign.CLUE+Vector3.FORWARD).is_empty(),"clue fixture pose")
	check(m.inspect_bend().is_empty(),"observe clue")
	check(Fixture.pose(m,Campaign.MOTHER+Vector3.FORWARD*2.0).is_empty(),"report fixture pose")
	check(m.report_home().is_empty(),"complete inquiry by existing operation")
	return m

func _run() -> void:
	check(Registry.validate_records(Registry.RELATIONS).is_empty(),"registry provenance and intervals")
	check(Registry.faction("raj_kaur") == "phulkian","Raj Kaur uses designated gameplay bloc")
	check(Registry.faction("raj_kaur",1793).is_empty(),"do not extrapolate 1792 alignment")
	var unresolved := {"subject":"raj_kaur","predicate":"kin_of","object":"ranjit_singh","from":null,"until":null,"sources":["design:1792"]}
	check(Registry.active_relations(1792,[unresolved]).is_empty(),"unknown chronology never activates")
	check(not Registry.validate_records([unresolved]).is_empty(),"undated research candidates refused as canon")
	var duplicate: Array = Registry.RELATIONS.duplicate(true)
	duplicate.append(duplicate[0])
	check(not Registry.validate_records(duplicate).is_empty(),"duplicate relationship refused")

	var vision := Vision.initial()
	var last_loss := -1.0
	for t in range(0,Vision.DURATION+1,180):
		var p := Vision.parameters(vision,t)
		check(p.loss >= last_loss and p.loss <= 1.0,"monotone bounded progression")
		check(p.right_acuity == 1.0,"unaffected eye retained")
		last_loss = p.loss
	check(Vision.parameters(vision,Vision.DURATION*2).left_acuity == 0.0,"progression stops at left eye loss")
	check(Vision.visible(vision,Vision.DURATION,0.0,3.0,4.0,true),"central vision survives")
	check(not Vision.visible(vision,Vision.DURATION,deg_to_rad(-70),1.0,4.0,true),"affected peripheral sector narrowed")
	check(Vision.visible(vision,Vision.DURATION,deg_to_rad(70),1.0,4.0,true),"healthy-side sector retained")
	check(not Vision.visible(vision,0,0.0,1.0,4.0,false),"walls block perception")
	check(not Vision.visible(vision,0,NAN,1.0,4.0,true),"nonfinite bearing refused")
	check(Vision.bearing(Vector3.FORWARD,Vector3.LEFT) < 0.0,"character-left has negative bearing")
	check(Vision.bearing(Vector3.FORWARD,Vector3.RIGHT) > 0.0,"character-right has positive bearing")
	var mirrored := Vision.initial(0,"stable_right_monocular")
	check(not Vision.visible(mirrored,0,deg_to_rad(70),1.0,4.0,true),"right-eye profile mirrors perception")

	var log := Rules.initial()
	check(Rules.append(log,0,"raid","ranjit_singh","bhangi").is_empty(),"record raid")
	var early := Rules.project(log,60)
	check(early.factions.bhangi.resources < 100.0,"damage is world state")
	check(early.pairs["bhangi:sukerchakia"].grievance == 0.0,"attributed grievance waits for report")
	check(early.player_reports.is_empty(),"no player omniscience")
	var later := Rules.project(log,180)
	check(later.pairs["bhangi:sukerchakia"].grievance > 0.3,"delayed attribution updates victim")
	check(later.pairs["sandhawalia:sukerchakia"].grievance == 0.0,"relay has a separate delay")
	var relay := Rules.project(log,480)
	check(relay.pairs["sandhawalia:sukerchakia"].grievance > 0.0,"rumour travels along declared route")
	var before := JSON.stringify(log)
	check(not Rules.append(log,1,"raid","ranjit_singh","sandhawalia").is_empty(),"rate-limited operation")
	check(JSON.stringify(log) == before,"refused input is atomic")
	var bad := log.duplicate(true)
	bad.inputs[0].tick = 9999
	check(not Rules.validate(bad,180).is_empty(),"future input refused")
	bad = log.duplicate(true)
	bad.inputs[0].evidence_class = "verified_history"
	check(not Rules.validate(bad,180).is_empty(),"game operation cannot masquerade as historical evidence")
	bad = log.duplicate(true)
	bad.inputs[0].strength = INF
	check(not Rules.validate(bad,180).is_empty(),"nonfinite incident refused")

	# 1,000 actual reducer steps, with retained telemetry. No alternate Python simulator.
	var campaign_log := Rules.initial()
	var runtime := Rules.runtime(0)
	var seen: Dictionary = {}
	var trace := FileAccess.open("user://political-1000.jsonl",FileAccess.WRITE)
	check(trace != null,"trace output opened")
	for step in range(1,1001):
		var tick := step*60
		if step <= 22 and (step-1)%3 == 0:
			var target := "bhangi" if ((step-1)/3)%2 == 0 else "sandhawalia"
			check(Rules.append(campaign_log,tick,"raid","ranjit_singh",target).is_empty(),"campaign input accepted")
		Rules.advance(runtime,campaign_log,tick)
		for event in runtime.trace: seen[event.kind] = true
		for f in runtime.factions.values():
			check(f.resources >= 0.0 and f.resources <= 100.0 and f.surface >= 0.0 and f.surface <= 1.0,"resource and exposure bounds")
		if trace != null:
			trace.store_line(JSON.stringify({"step":step,"tick":runtime.tick,"bhangi_grievance":runtime.pairs["bhangi:sukerchakia"].grievance,"sandhawalia_grievance":runtime.pairs["sandhawalia:sukerchakia"].grievance,"surface":runtime.factions.sukerchakia.surface,"coalitions":runtime.coalitions.size(),"pending_reports":runtime.queue.size()}))
	if trace != null: trace.close()
	check(seen.has("rally"),"repeated raids produce rally")
	check(seen.has("muster"),"escalation reaches muster")
	check(seen.has("retaliatory_incursion"),"opponents initiate responses")
	check(seen.has("coalition_formed"),"common pressure forms coalition")
	check(seen.has("coalition_dissolved"),"coalition can dissolve")
	check(seen.has("covert_warning"),"exposure can create a covert opportunity")
	check(runtime.coalitions.is_empty(),"cooling-off has no permanent coalition flag")
	check(runtime.pairs["bhangi:sukerchakia"].grievance < 0.1,"grievance cools without further raids")
	check(Rules.project(campaign_log,60000) == runtime,"full replay equals incremental execution")
	var json_log: Variant = JSON.parse_string(JSON.stringify(campaign_log,"",true,true))
	check(Rules.project(json_log,60000) == runtime,"JSON roundtrip preserves reducer replay")

	# Deliberate high-exposure kernel fixture tests mitigation, not a played encounter.
	var guarded := Rules.runtime(0)
	var threat: Dictionary = guarded.pairs["phulkian:sukerchakia"]
	threat.grievance = 0.95
	threat.attention = 1.0
	threat.last_seen = 0
	guarded.factions.sukerchakia.surface = 1.0
	guarded.factions.sukerchakia.shield = 1.0
	Rules.advance(guarded,Rules.initial(),420)
	var guarded_kinds: Array = guarded.trace.map(func(e): return e.kind)
	check("plot_disrupted" in guarded_kinds,"precautions can disrupt abstract plot")
	check("poisoning_attempt" not in guarded_kinds and "assassination_attempt" not in guarded_kinds,"mitigation not ignored")

	var full := Rules.initial()
	for i in range(Rules.MAX_INPUTS):
		check(Rules.append(full,i*600,"gaze","raj_kaur","sukerchakia",0.5).is_empty(),"bounded input entry")
	before = JSON.stringify(full)
	check(not Rules.append(full,Rules.MAX_INPUTS*600,"gaze","raj_kaur","sukerchakia",0.5).is_empty(),"ledger capacity fails closed")
	check(JSON.stringify(full) == before,"capacity refusal preserves ledger")

	var m := _complete()
	check(m.snapshot().vision.profile == "stable_left_monocular","legacy import does not manufacture renewed eye loss")
	var saved := m.snapshot()
	check(not m.record_gaze("raj_kaur",false,0.8).is_empty(),"occluded gaze rejected")
	check(m.snapshot() == saved,"occluded observation has no political effect")
	check(m.record_gaze("raj_kaur",true,0.8).is_empty(),"geometry executor can submit sighting")
	check(not m.order_political("raid","bhangi").is_empty(),"cannot raid an outpost remotely from household")
	check(Fixture.pose(m,Campaign.OUTPOSTS.bhangi+Vector3.BACK*2.0).is_empty(),"outpost fixture pose")
	check(m.order_political("raid","bhangi").is_empty(),"site-bound raid accepted")
	for i in range(600): m.advance()
	check(m.validate(m.snapshot()).is_empty(),"extended snapshot validates")
	var clone := Campaign.new()
	check(clone.restore(wire(m.snapshot())).is_empty(),"restore extended world")
	check(clone.political_debug() == m.political_debug(),"restored hidden state is reproduced, not merged")
	check(clone.journal() == m.journal(),"restored knowledge is reproduced")
	before = JSON.stringify(m.snapshot())
	bad = m.snapshot()
	bad.erase("vision")
	check(not m.restore(bad).is_empty() and JSON.stringify(m.snapshot()) == before,"missing extended identity refused atomically")
	bad = m.snapshot()
	bad.erase("aftermath")
	check(not m.restore(bad).is_empty() and JSON.stringify(m.snapshot()) == before,"missing household identity refused atomically")
	bad = m.snapshot()
	bad.vision.onset_tick = -1
	check(not m.restore(bad).is_empty() and JSON.stringify(m.snapshot()) == before,"invalid vision refused atomically")
	check(m.restore(saved).is_empty(),"earlier snapshot restoration")
	check(m.political_inputs().is_empty(),"discarded raid and sighting do not survive restoration")
	check(m.political_journal().is_empty(),"discarded political knowledge does not survive restoration")
	var cp := Campaign.new()
	check(cp.restore(Fixture.precursor()).is_empty(),"checkpoint precursor")
	check(cp.observe_quarry(true).is_empty(),"actual quarry observation")
	check(Checkpoint.write("user://test-political-checkpoint.json",cp.snapshot(),Vector3.ZERO,"return_trail",Campaign).is_empty(),"shared checkpoint store accepts declared authority")
	var envelope := Checkpoint.read("user://test-political-checkpoint.json",Campaign)
	check(envelope.error.is_empty(),"extended checkpoint read")
	if envelope.error.is_empty():
		check(envelope.envelope.snapshot == wire(cp.snapshot()),"checkpoint retains every serialized field and value")
		var recovered := Campaign.new()
		check(recovered.restore(envelope.envelope.snapshot).is_empty(),"checkpoint actually restores through authority")
		check(wire(recovered.snapshot()) == wire(cp.snapshot()),"restored checkpoint preserves complete serialized world")
		check(recovered.perception() == cp.perception(),"checkpoint preserves perception semantics")
		check(recovered.political_debug() == cp.political_debug(),"checkpoint preserves reducer semantics")
		check(recovered.journal() == cp.journal(),"checkpoint preserves received knowledge")

	var world: Node3D = World.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var chapter = world.get_node("ChildhoodChapter")
	chapter.set_physics_process(false)
	chapter.avatar.set_physics_process(false)
	check(chapter.model == chapter.campaign,"controller aliases one authority")
	check(chapter._eye_level,"extended chapter starts eye-level")
	check(chapter.avatar.get_node("CameraPivot/SpringArm3D").spring_length == 0.0,"eye camera is not a distant chase camera")
	var foot_eye: Vector3 = chapter._eye_origin()
	chapter.avatar.pivot.position.y = 2.5
	var riding_eye: Vector3 = chapter._eye_origin()
	check(is_equal_approx(riding_eye.y-foot_eye.y,1.1),"perception follows inherited riding height")
	chapter.avatar.pivot.position.y = 1.4
	check(is_equal_approx(chapter.avatar.get_node("CameraPivot/SpringArm3D").position.x,0.032),"functional-eye offset lives on spring arm")
	check(chapter.campaign.restore(saved).is_empty(),"scene uses completed-inquiry fixture")
	chapter._apply()
	chapter.avatar.set_physics_process(false)
	chapter.avatar.pivot.rotation = Vector3(0,PI,0)
	var obstacle: MeshInstance3D = chapter._box(Vector3(1.0,3.0,0.3),Vector3(-5,1.5,8),Color.GRAY,true)
	await physics_frame
	await process_frame
	check(not chapter._seen(Campaign.MOTHER+Vector3.UP,4.0),"real collider blocks protagonist recognition")
	chapter._sample_observers()
	check(chapter.campaign.political_inputs().is_empty(),"real collider blocks Raj Kaur surveillance")
	obstacle.get_parent().queue_free()
	await process_frame
	await physics_frame
	chapter._sample_observers()
	check(chapter.campaign.political_inputs().size() == 1,"unblocked physical gaze enters ledger")
	check(chapter._attention_cue.contains("Raj Kaur"),"perceived watcher yields local cue")
	check(chapter.campaign.restore(saved).is_empty(),"reset geometry fixture")
	chapter.avatar.pivot.rotation = Vector3.ZERO
	chapter._sample_observers()
	check(chapter.campaign.political_inputs().size() == 1,"looking away does not erase rival observation")
	check(not chapter._attention_cue.contains("Raj Kaur"),"unperceived watcher does not yield omniscient cue")
	check(chapter.campaign.restore(saved).is_empty(),"reset UI dispatch fixture")
	chapter.avatar.pivot.rotation = Vector3(0,PI,0)
	chapter._interact()
	check(chapter._paused and chapter._panel_text.text.contains("PHULKIAN"),"physical household interaction opens policy choices")
	chapter._run_after_action("policy:scout:bhangi")
	check(chapter.campaign.political_inputs().size() == 1,"UI dispatch enters the same event ledger")
	var parameters: Dictionary = chapter.campaign.perception()
	chapter._subjective = false
	chapter._veil.visible = false
	check(chapter.campaign.perception() == parameters,"clear rendering does not restore eyesight")

	# Focus is hosted by the production extended chapter, but the existing
	# character-eye policy remains the only visual admission authority. These are
	# declared geometry fixtures, not an earned player journey or medical measure.
	var focus=chapter.ground_focus
	focus.clear();focus._targets.clear()
	var eye: Vector3=chapter._eye_origin()
	var forward: Vector3=-chapter.avatar.pivot.global_basis.z
	var right: Vector3=chapter.avatar.pivot.global_basis.x
	var affected_at:=eye+(forward*cos(deg_to_rad(70.0))-right*sin(deg_to_rad(70.0)))*2.5
	var healthy_at:=eye+(forward*cos(deg_to_rad(70.0))+right*sin(deg_to_rad(70.0)))*2.5
	var affected: Node3D=chapter._box(Vector3(.18,.18,.18),affected_at,Color.RED)
	var healthy: Node3D=chapter._box(Vector3(.18,.18,.18),healthy_at,Color.GREEN)
	check(Vision.bearing(forward,affected_at-eye)<0.0 and Vision.bearing(forward,healthy_at-eye)>0.0,
		"vision fixtures occupy the authored affected and healthy sides")
	focus.register_target("affected_fixture",affected,"Affected-side fixture")
	var camera: Camera3D=chapter.get_viewport().get_camera_3d()
	camera.look_at(affected_at)
	var z:=InputEventKey.new();z.keycode=KEY_Z;z.pressed=true
	chapter._unhandled_input(z)
	check(focus.active,"actual Z input starts Focus in the extended chapter")
	for _i in range(50):
		chapter.campaign.advance();focus.sample(int(chapter.campaign.progress().tick))
	check(not chapter._seen(affected_at,18.0) and focus.acquisitions().is_empty() and focus.observations().is_empty() and focus.overlay.marks.is_empty(),
		"camera-visible affected-side fixture cannot create acquisition, evidence or overlay")
	focus.clear();focus._targets.clear()
	focus.register_target("healthy_fixture",healthy,"Healthy-side fixture")
	chapter._unhandled_input(z)
	for _i in range(50):
		chapter.campaign.advance();focus.sample(int(chapter.campaign.progress().tick))
	check(chapter._seen(healthy_at,18.0) and focus.observations().size()==1,
		"the same Focus observer admits a healthy-side target through the existing policy")
	check(focus.overlay.marks.is_empty(),"character evidence outside the displayed camera creates no marker")
	camera.look_at(healthy_at);focus.sample(int(chapter.campaign.progress().tick))
	check(focus.overlay.marks.size()==1,"an admitted observation becomes presentable only when the camera can display it")
	focus.clear()
	chapter._open_journal()
	check(chapter._panel_text.text.contains("authored"),"journal marks authored progression")
	world.queue_free()
	await process_frame
	print("POLITICAL_EXPOSURE: %d assertions; %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
