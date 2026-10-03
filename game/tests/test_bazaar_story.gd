# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## The inherited input journeys physically walk all three outcomes. The final
## contact fixture reuses their admitted world; it does not claim new travel.
const StoryLines := preload("res://youth/performance/bazaar_story.gd")
var return_fixture: Dictionary={}
var return_snapshots: Dictionary={}
var seen_outcomes: Array[String]=[]
var cast_ids: Array[int]=[]

func press(scene,prefix: String) -> void:
	if prefix=="Walk with Mela":
		check(scene._panel_text.text.contains(StoryLines.INVITATION),"market invitation establishes the all-three-home promise")
		check(scene._actions.get_child(0).text.begins_with("Walk with Mela"),"available bazaar invitation leads the market choices")
		check(scene._actions.get_child(0).has_focus(),"the available invitation owns keyboard focus")
		var prior: Dictionary=scene.model.snapshot()
		scene._menu_action("youth:stand")
		await frames(2)
		check(scene.model.snapshot()==prior and scene._youth_action.is_empty(),"unoffered stand callback cannot start the encounter")
		cast_ids.clear()
		for actor in scene.youths: cast_ids.append(actor.get_instance_id())
	if prefix=="Give the bazaar account":
		var prior: Dictionary=scene.model.snapshot()
		var outcome: String=scene.model.brawl().ledger.outcome
		var camera: Transform3D=scene.avatar.pivot.transform
		var positions: Array=[]
		for actor in scene.youths: positions.append(actor.global_transform)
		await super.press(scene,"Hear Mela and Jiva before")
		check(scene._panel_text.text=="ON THE WAY HOME\n\n"+StoryLines.return_exchange(outcome),"own exchange for "+outcome)
		check(scene._youth_choices.is_empty(),"return conversation offers no state-changing youth callback")
		await frames(25)
		check(scene.model.snapshot()==prior,"optional return exchange pauses without receipts or remembered evidence: "+outcome)
		check(scene.avatar.pivot.transform==camera,"optional exchange preserves the player camera")
		for i in range(5):
			check(scene.youths[i].global_transform==positions[i],"conversation preserves participant transform "+str(i))
			check(scene.youths[i].get_instance_id()==cast_ids[i],"same physical participant made the journey "+str(i))
		scene._menu_action("youth:report")
		await frames(2)
		check(scene.model.snapshot()==prior,"report cannot be smuggled through the return conversation")
		seen_outcomes.append(outcome)
		return_snapshots[outcome]=prior
		if return_fixture.is_empty(): return_fixture=prior
		await super.press(scene,"Continue home together")
		look(scene,Supply.QUARTERMASTER)
		await tap(scene,KEY_E)
	await super.press(scene,prefix)

func _contact_boundaries() -> void:
	var home:=Launch.make_world()
	var scene=home.get_node("ChildhoodChapter")
	scene.save_path=SAVE
	ok(scene.model.restore(return_fixture),"explicit admitted return-world fixture")
	root.add_child(home);await frames(8)
	# Walk back onto the approach with the existing companions to verify the
	# roadside E interaction, independently of the quartermaster menu shortcut.
	await walk(scene,Vector3(2,0,-10));await frames(120)
	look(scene,scene.youths[3].global_position);await tap(scene,KEY_E)
	check(scene._paused and scene._panel_text.text.begins_with("ON THE WAY HOME"),"physical roadside friend interaction opens the optional exchange")
	var listening: Dictionary=scene.model.snapshot();await frames(20)
	check(scene.model.snapshot()==listening,"roadside listening freezes the same party and world")
	await super.press(scene,"Continue home together")
	await walk(scene,Vector3(3,0,4));await frames(120)
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E)
	var before: Dictionary=scene.model.snapshot()
	# An opaque screen behind the speaker blocks an actual companion. Rechecking
	# the invitation alone would allow this stale dialog choice to speak remotely.
	var a: Vector3=scene.youths[3].global_position
	var p: Vector3=scene.avatar.global_position
	var midpoint: Vector3=(a+p)*.5+Vector3.UP
	var wall=scene._box(Vector3(2.4,3,.3),midpoint,Color.GRAY,true)
	wall.get_parent().look_at(a+Vector3.UP)
	await frames(4)
	check(not scene._contact(scene.youths[3]),"new screen actually removes friend contact")
	await super.press(scene,"Hear Mela and Jiva before")
	check(not scene._paused and scene._message.contains("close enough"),"return exchange refuses a now-obstructed friend")
	scene.bazaar_performance.sample(false)
	check(scene.bazaar_performance.canvas.visible and scene.bazaar_performance.bottom.visible and scene.bazaar_performance.subtitle.text==scene._message,"blocked friend refusal is visible in the single director channel")
	check(scene.model.brawl().events==before.youth_brawl.events,"blocked exchange preserves authoritative receipts")
	scene._paused=true;scene.avatar.set_physics_process(false)
	wall.get_parent().queue_free();await frames(4)
	scene._resume();look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E)
	check(scene._friends_in_contact(),"removing screen restores actual contact")
	before=scene.model.snapshot()
	look(scene,Supply.QUARTERMASTER+Vector3(0,0,-20))
	await super.press(scene,"Give the bazaar account")
	check(scene.model.brawl().events==before.youth_brawl.events and scene.model.brawl_phase()=="returning","turning away invalidates queued report")
	check(scene._message.contains("face them"),"report refusal gives a local recovery instruction")
	scene.bazaar_performance.sample(false)
	check(scene.bazaar_performance.canvas.visible and scene.bazaar_performance.bottom.visible and scene.bazaar_performance.subtitle.text==scene._message,"lost-facing refusal is visibly recoverable")
	before=scene.model.snapshot()
	scene._menu_action("youth:report");await frames(2)
	check(scene.model.brawl().events==before.youth_brawl.events,"closed callback cannot report")
	look(scene,Supply.QUARTERMASTER);await tap(scene,KEY_E)
	await super.press(scene,"Give the bazaar account")
	check(scene.model.brawl_phase()=="reported","renewed local report succeeds after contact recovery")
	check(scene.model.journal().filter(func(m):return m.id=="youth-bazaar-report").size()==1,"one canonical report after optional exchange and refusals")
	ok(scene.model.validate(scene.model.snapshot()),"completed story still validates")
	home.queue_free();await frames(4)

func _run() -> void:
	if "--contact-only" in OS.get_cmdline_user_args():
		var saved: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://bazaar-story-return.json"))
		if not saved is Dictionary or saved.get("failed",1)!=0:
			check(false,"contact rerun requires successful physical journey snapshots");quit(1);return
		return_fixture=saved.snapshots.stood_ground
		await _contact_boundaries()
		await _recovery_and_visibility()
		print("BAZAAR_STORY_CONTACT_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0);return
	check(StoryLines.return_exchange("unknown").is_empty(),"unknown outcome produces no invented account")
	for route in ["fight","leave","withdraw"]: await _journey(route)
	check(seen_outcomes.size()==3 and seen_outcomes.has("stood_ground") and seen_outcomes.has("withdrew") and seen_outcomes.has("walked_away"),"all three admitted outcomes reach distinct return exchanges")
	await _contact_boundaries()
	await _recovery_and_visibility()
	var recording:=FileAccess.open("user://bazaar-story-return.json",FileAccess.WRITE)
	recording.store_string(JSON.stringify({"schema":"1792.bazaar-story-return.v1","passed":passed,"failed":failed,"source":"three actual input journeys; initial completed-inquiry fixture each","snapshots":return_snapshots},"\t",true,true));recording.close()
	for suffix in ["",".tmp",".bazaar-retry.json",".bazaar-retry.json.tmp",".checkpoint.json"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE+suffix))
	print("BAZAAR_STORY_TESTS: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
