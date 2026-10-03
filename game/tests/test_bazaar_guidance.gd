# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://tests/test_youth_brawl.gd"
## Explicit reducer/spatial fixtures qualify the actual production HUD. These
## are not an input-driven journey; test_bazaar_direction retains those routes.
const Guidance := preload("res://presentation/bazaar_guidance.gd")
var home: Node3D
var scene: Node3D
var captures := 0

func _initialize() -> void: run_guidance.call_deferred()
func collision_authority() -> Array:
	var result: Array=[]
	for node in home.find_children("*","CollisionShape3D",true,false):
		result.append([node.get_instance_id(),node.global_transform,node.shape.get_rid(),node.disabled,node.get_parent().collision_layer,node.get_parent().collision_mask])
	return result
func authority() -> Dictionary:
	return {"state":scene.model.snapshot(),"journal":scene.model.journal(),"collision":collision_authority(),"camera":scene.avatar.pivot.transform}
func fixture(phase: String):
	var model=fresh()
	ok(Pose.pose(model,Vector3(-12,.14,-18)),"declared guidance fixture pose")
	var data: Dictionary=model.snapshot()
	data.youth_brawl.actors[3].position=Base.coords(Vector3(-13,.14,-17))
	data.youth_brawl.actors[4].position=Base.coords(Vector3(-11,.14,-17))
	ok(model.restore(data),"declared cast positions")
	if phase!="invited": ok(model.brawl_action("challenge"),"fixture challenge")
	if phase in ["leaving","returning"]: ok(model.brawl_action("leave"),"fixture leave")
	if phase=="fighting": ok(model.brawl_action("stand"),"fixture stand")
	if phase=="returning":
		data=model.snapshot();data.player.position=Base.coords(R.REGROUP);data.actors.ranjit_singh.position=data.player.position.duplicate()
		for i in [3,4]: data.youth_brawl.actors[i].position=Base.coords(R.REGROUP+Vector3(-1 if i==3 else 1,0,1))
		ok(model.restore(data),"declared regroup position")
		ok(model.brawl_action("regroup"),"fixture accepts physical-party receipt")
	return model
func present(model) -> void:
	ok(scene.model.restore(model.snapshot()),"actual production scene restores validated fixture")
	scene._message="";scene._apply();scene._paused=false;scene.avatar.velocity=Vector3.ZERO
	scene._refresh();scene.art.detail.hud.sample()
	look(scene,scene.youths[0].global_position)
	scene.bazaar_performance.rehydrate();scene.bazaar_performance.sample(false)
	await frames(3)
	scene.bazaar_performance.sample(false)
func relocate_party(player: Vector3,mela: Vector3,jiva: Vector3) -> void:
	var data: Dictionary=scene.model.snapshot();data.player.position=Base.coords(player);data.actors.ranjit_singh.position=data.player.position.duplicate()
	data.youth_brawl.actors[3].position=Base.coords(mela);data.youth_brawl.actors[4].position=Base.coords(jiva)
	ok(scene.model.restore(data),"explicit read-only party pose fixture")
	scene._apply();scene._paused=false;scene.avatar.velocity=Vector3.ZERO
	scene._refresh();scene.art.detail.hud.sample()
	await frames(3);scene.bazaar_performance.sample(false)
func verify_layout(label: String) -> void:
	var d: Node=scene.bazaar_performance
	var before:=authority()
	for size in [Vector2i(1280,720),Vector2i(800,450)]:
		root.size=size;d.sample(false);await frames(3);d.sample(false);await process_frame
		var screen:=root.get_visible_rect()
		check(d.canvas.visible and screen.encloses(d.top.get_global_rect()),"native task panel fits %s at %s"%[label,size])
		check(d.objective.is_visible_in_tree() and d.prompt.is_visible_in_tree(),"task and controls survive at %s"%size)
		if d.bottom.visible:
			check(screen.encloses(d.bottom.get_global_rect()),"native speech panel fits %s at %s"%[label,size])
			check(not d.top.get_global_rect().intersects(d.bottom.get_global_rect()),"task and speech do not overlap at %s"%size)
		if OS.get_environment("BAZAAR_GUIDANCE_RENDER")=="1":
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			check(not image.is_empty() and image.get_size()==size and image.save_png("user://bazaar-guidance-%s-%dx%d.png"%[label,size.x,size.y])==OK,"native frame exported: "+label)
			captures+=1
	check(authority()==before,"resizing and rendering preserve state, journal, collision, camera: "+label)
func recovery_and_attention() -> void:
	var d: Node=scene.bazaar_performance
	for phase in ["invited","challenged","leaving","returning"]:
		await present(fixture(phase))
		var before:=authority();var guidance: Dictionary=Guidance.read(scene)
		check(guidance.recover_index==-1,"near clear friends need no recovery: "+phase)
		check(d.objective.text==guidance.task and d.detail.visible and d.title.visible,"rest foreground explains current responsibility: "+phase)
		check(not scene._hud.is_visible_in_tree() and not scene._caption.is_visible_in_tree(),"encounter has one HUD owner: "+phase)
		check(not scene.art.detail.hud.visible,"household compact HUD yields to the active bazaar encounter: "+phase)
		var task: String=d.objective.text
		scene.avatar.velocity=Vector3(2,0,0);d.sample(false)
		check(d.objective.text==task and d.prompt.visible and not d.detail.visible and not d.title.visible,"movement keeps action and retires secondary explanation: "+phase)
		scene.avatar.velocity=Vector3.ZERO;d.sample(false)
		check(d.detail.visible and d.title.visible,"rest immediately restores optional detail: "+phase)
		check(authority()==before,"guidance does not mutate authority: "+phase)
	# At the existing regroup and reporting thresholds, a friend can be visible
	# yet still too far for the actual reducer. Name the real missing companion.
	for phase in ["leaving","returning"]:
		await present(fixture(phase))
		var at: Vector3=R.REGROUP if phase=="leaving" else Supply.QUARTERMASTER
		await relocate_party(at,at+Vector3(-6,0,0),at+Vector3(1,0,1))
		var read: Dictionary=Guidance.read(scene)
		check(read.recover_index==3 and read.task.contains("Mela"),"destination names the separated Mela: "+phase)
		check(read.task.begins_with("Wait"),"visible moving friend can close the gap: "+phase)
		await relocate_party(at,at+Vector3(-1,0,1),at+Vector3(6,0,0))
		read=Guidance.read(scene)
		check(read.recover_index==4 and read.task.contains("Jiva"),"destination names the separated Jiva: "+phase)
		await verify_layout("recovery-"+phase)
		await relocate_party(at,at+Vector3(-1,0,1),at+Vector3(14,0,0))
		read=Guidance.read(scene)
		check(read.recover_index==4 and read.task.begins_with("Go back"),"out-of-contact friend requires a real return: "+phase)
	await present(fixture("invited"))
	var a: Vector3=scene.youths[3].global_position;var p: Vector3=scene.avatar.global_position
	var wall=scene._box(Vector3(.25,3,3),(a+p)*.5+Vector3.UP,Color.GRAY,true)
	wall.get_parent().disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	await frames(4)
	check(not scene._contact(scene.youths[3]),"actual wall removes nearby friend contact")
	var read: Dictionary=Guidance.read(scene)
	check(read.recover_index==3 and read.task=="Go back for Mela","near but obstructed friend is not declared safely present")
	wall.get_parent().queue_free();await frames(4)
	check(Guidance.read(scene).recover_index==-1,"removing physical obstruction restores ordinary outing guidance")
func threat_and_queue() -> void:
	var model=fixture("fighting")
	for i in range(80): model.advance()
	await present(model)
	var d: Node=scene.bazaar_performance
	var tick: int=int(scene.model.progress().tick)
	check(d.in_view(0) and scene._facing(scene.youths[0].global_position),"actual camera sees and faces the windup threat")
	check(d.urgent_cue(scene.model.brawl(),tick).contains("STRIKE COMING"),"existing physical windup produces the immediate action cue")
	d.speech={"actor":3,"text":"A nearby friend has something to say.","until":tick+300}
	d.sample(false)
	check(not d.bottom.visible and not d.detail.visible and not d.title.visible,"immediate strike retires caption and secondary text")
	check(d.prompt.text.contains("STRIKE COMING"),"combat action owns the prominent controls line")
	await verify_layout("windup")
	d.speech.clear();d.queue=[{"actor":3,"text":"Wait until the immediate strike passes.","expires":tick+300}]
	var before:=authority();var heard: int=d.heard.size();d.sample()
	check(d.speech.is_empty() and d.queue.size()==1 and d.heard.size()==heard,"urgent cue defers rather than silently consumes new dialogue")
	check(authority()==before,"threat prioritization preserves all authority")
	for i in range(30): scene.model.advance()
	d.sample()
	check(not d.speech.is_empty() and d.speech.text=="Wait until the immediate strike passes." and d.queue.is_empty(),"still-relevant queued line starts after the danger cue clears")
	check(d.bottom.visible,"subtitles regain the channel after immediate action")
	await verify_layout("speech")
	# An old line expires at its original clock boundary; suppression must not
	# manufacture unlimited speech persistence or carry it across a new context.
	d.speech.clear();d.queue=[{"actor":3,"text":"Expired context.","expires":int(scene.model.progress().tick)-1}]
	d.sample();check(d.speech.is_empty() and d.queue.is_empty(),"expired deferred dialogue is discarded without being heard")
	d.queue=[{"actor":3,"text":"Stale fight line.","expires":int(scene.model.progress().tick)+300}]
	d.receive({"kind":"regroup","tick":scene.model.progress().tick}, {"outcome":"withdrew"})
	check(not d.queue.any(func(line):return line.text=="Stale fight line."),"context change discards deferred fight dialogue")
	# A combat cue cannot know about an opponent behind the player or a wall.
	await present(model);tick=int(scene.model.progress().tick)
	look(scene,scene.avatar.global_position+Vector3(0,0,10));d.sample(false)
	check(d.urgent_cue(scene.model.brawl(),tick).is_empty(),"unfaced threat does not reveal an immediate cue")
	look(scene,scene.youths[0].global_position)
	var wall=scene._box(Vector3(3,3,.25),(scene.avatar.global_position+scene.youths[0].global_position)*.5+Vector3.UP,Color.GRAY,true)
	wall.get_parent().disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	await frames(4);d.sample(false)
	check(d.urgent_cue(scene.model.brawl(),tick).is_empty(),"actual wall prevents a threat cue through scenery")
	wall.get_parent().queue_free();await frames(4)
	for i in range(25): model.advance()
	ok(model.brawl_action("parry",0),"declared timed parry fixture")
	await present(model)
	check(d.urgent_cue(scene.model.brawl(),int(scene.model.progress().tick)).contains("Counter now"),"received checked strike names the existing recovery action")
func modal_and_hydration() -> void:
	await present(fixture("returning"))
	var d: Node=scene.bazaar_performance
	scene._open_journal();d.sample(false)
	check(scene._paused and scene._panel.is_visible_in_tree() and not d.canvas.visible,"actual journal modal owns the foreground")
	var before:=authority();var tick: int=int(scene.model.progress().tick)
	d.queue=[{"actor":3,"text":"Paused line.","expires":tick+100}]
	for i in range(5): d.sample()
	check(authority()==before and d.speech.is_empty() and d.queue.size()==1,"paused sampling advances neither world nor speech")
	scene._resume();d.sample(false)
	check(d.canvas.visible,"resuming returns the outing foreground")
	d.rehydrate();d.sample(false)
	check(d.queue.is_empty() and d.speech.is_empty(),"rehydration does not replay old scene dialogue")
	check(authority()==before,"hydration preserves state, memories, collision and camera")
func blocked_action_feedback() -> void:
	await present(fixture("returning"))
	var d: Node=scene.bazaar_performance
	# Exercise the actual failed local return action with a separated friend.
	var at: Vector3=scene.model.position()
	await relocate_party(at,at+Vector3(-1,0,1),at+Vector3(14,0,0))
	var before:=authority()
	scene._open_return_exchange();d.sample(false)
	check(not scene._paused and d.bottom.visible and d.speaker.text=="CONTINUE","failed local friend conversation uses the visible recovery channel")
	check(d.subtitle.text.contains("Bring Mela and Jiva"),"visible feedback tells the player which prerequisite failed")
	check(authority()==before,"failed local conversation and feedback add no state, memories, collision or camera changes")
	var feedback: Dictionary=d.action_feedback.duplicate(true)
	check(int(feedback.until)>int(scene.model.progress().tick) and int(feedback.until)-int(scene.model.progress().tick)<=720,"recovery message has a finite existing-clock reading deadline")
	d.queue=[{"actor":3,"text":"This line waits behind the recovery instruction.","expires":int(feedback.until)+300}]
	var heard: int=d.heard.size();d.sample()
	check(d.queue.size()==1 and d.speech.is_empty() and d.heard.size()==heard,"ambient line is not consumed or heard behind recovery feedback")
	await verify_layout("blocked-conversation")
	scene._open_journal();d.sample(false)
	for i in range(8): d.sample()
	check(not d.canvas.visible and d.action_feedback==feedback and scene.model.snapshot()==before.state,"pause hides recovery feedback without burning its deadline or advancing state")
	scene._resume();d.sample(false)
	check(d.bottom.visible and d.subtitle.text==feedback.text,"resume restores the still-current recovery instruction")
	while int(scene.model.progress().tick)<int(feedback.until): scene.model.advance()
	d.sample()
	check(d.action_feedback.is_empty() and not d.speech.is_empty() and d.speech.text=="This line waits behind the recovery instruction.","feedback expires on the shared clock and releases still-valid dialogue")
	d.show_action_feedback("Temporary recovery.");d.rehydrate();d.sample(false)
	check(d.action_feedback.is_empty(),"rehydration clears temporary action feedback")
	await present(fixture("fighting"))
	for i in range(80): scene.model.advance()
	d.show_action_feedback("Regroup when there is room.");d.sample(false)
	check(d.prompt.text.contains("STRIKE COMING") and not d.bottom.visible,"an immediate strike outranks even actionable recovery feedback")
	d.receive({"kind":"regroup","tick":scene.model.progress().tick},{"outcome":"withdrew"})
	check(d.action_feedback.is_empty(),"received phase transition clears the old recovery context")
func report_foreground() -> void:
	await present(fixture("returning"))
	await relocate_party(Supply.QUARTERMASTER,Supply.QUARTERMASTER+Vector3(-1,0,1),Supply.QUARTERMASTER+Vector3(1,0,1))
	ok(scene.model.brawl_action("report"),"actual report receipt admits the end cap")
	scene._refresh();scene._sync_youth(true)
	var d: Node=scene.bazaar_performance
	d.sample()
	# Match the normal visual sampling order: shared foreground then encounter.
	scene.art.detail.hud.sample();d.sample(false)
	check(d.canvas.visible and not scene.art.detail.hud.visible,"finite ending owns one foreground after brawl_busy has ended")
	check(d.title.text=="ALL THREE HOME" and d.speaker.text=="QUARTERMASTER","received report gets the authored resolution")
	await verify_layout("all-three-home")
	while int(scene.model.progress().tick)<int(d.report_until): scene.model.advance()
	scene.art.detail.hud.sample();d.sample(false)
	check(not d.canvas.visible and scene.art.detail.hud.visible,"ending expiry returns the household foreground without another input")
func run_guidance() -> void:
	if DisplayServer.get_name()=="headless": printerr("BAZAAR GUIDANCE requires Xvfb/gl_compatibility native UI.");quit(2);return
	root.content_scale_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
	home=Launch.make_world();scene=home.get_node("ChildhoodChapter");scene.save_path="user://bazaar-guidance-isolated.json"
	root.add_child(home);await frames(4)
	# Freeze fixture clocks/scripts while retaining the real collision space for
	# visibility rays. Godot otherwise removes disabled collision objects.
	for body in home.find_children("*","CollisionObject3D",true,false): body.disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	home.process_mode=Node.PROCESS_MODE_DISABLED
	await recovery_and_attention();await threat_and_queue();await modal_and_hydration();await blocked_action_feedback();await report_foreground()
	home.queue_free();await frames(3)
	print("BAZAAR_GUIDANCE_TESTS: %d passed, %d failed; %d native captures"%[passed,failed,captures]);quit(1 if failed else 0)
