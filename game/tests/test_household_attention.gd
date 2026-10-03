# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Declared reducer-created presentation fixtures, not a claim of a played journey.
## Actual production scene/HUD, native journal input and rendered layout are checked.
const Launch := preload("res://childhood/home_launch.gd")
const Guidance := preload("res://presentation/household_guidance.gd")
const Model := preload("res://workshops/workshop_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Service := preload("res://misl/service_rules.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
var passed := 0
var failed := 0
var captures := 0
var home: Node3D
var chapter: Node3D

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> bool:
	if ok: passed += 1
	else: failed += 1; push_error("HOUSEHOLD ATTENTION: " + label)
	return ok
func frames(n: int = 3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func accepted(error: String, label: String) -> bool: return check(error.is_empty(), label + (": " + error if not error.is_empty() else ""))
func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode=code; event.pressed=true; root.push_input(event,true)
	event=InputEventKey.new(); event.keycode=code; event.pressed=false; root.push_input(event,true)
func authority() -> Dictionary:
	return {"state":chapter.model.snapshot(), "journal":chapter.model.journal(), "collisions":collisions()}
func collisions() -> Array:
	var result: Array=[]
	for node in home.find_children("*", "CollisionShape3D", true, false):
		result.append([node.get_instance_id(),node.global_transform,node.shape.get_rid(),node.disabled,node.get_parent().collision_layer,node.get_parent().collision_mask])
	return result
func base_fixture(working: bool = true):
	var model := Model.new()
	accepted(model.restore(Fixture.complete()),"declared completed-inquiry fixture restores")
	accepted(model.begin_allowance(),"declared allowance accepted through reducer")
	if working:
		accepted(model.workshop_action("reserve"),"declared smith fee and fuel reserved")
		accepted(Pose.pose(model,Craft.SITE),"declared smith contact pose")
		accepted(model.workshop_action("start"),"declared smith begins existing clock work")
		accepted(Pose.pose(model,Supply.QUARTERMASTER),"declared return to household")
	return model
func present(model, kind: String) -> Dictionary:
	accepted(chapter.model.restore(model.snapshot()),"presentation fixture validates: "+kind)
	# Fixtures jump between unrelated moments; they must not retain the previous
	# live-input acknowledgement as if it belonged to this restored scenario.
	chapter._message=""
	chapter._apply(); chapter._refresh(); chapter.avatar.velocity=Vector3.ZERO
	var before:=authority()
	var result: Dictionary=Guidance.read(chapter)
	for _i in range(4): chapter.art.detail.hud.sample()
	check(result.get("kind","")==kind,"accepted commitment owns the foreground: "+kind)
	check(authority()==before,"guidance and HUD preserve state, journal and collisions: "+kind)
	var hud: Node=chapter.art.detail.hud
	check(hud.visible and hud.task.text==result.get("task", ""),"production compact HUD displays the accepted responsibility")
	check(not chapter._hud.is_visible_in_tree() and not chapter._caption.is_visible_in_tree(),"one compact foreground replaces the legacy text blocks")
	check(hud.narrator.visible and hud.narrator.text==result.progress,"at rest the accepted responsibility explains the next action")
	check(chapter._marker.visible and chapter._marker.position.is_equal_approx(result.target+Vector3.UP*2.1),"production objective marker follows the foreground task")
	return result
func reduced_movement_attention() -> void:
	var hud: Node=chapter.art.detail.hud
	var before:=authority()
	var task: String=hud.task.text
	chapter.avatar.velocity=Vector3(1,0,0); hud.sample()
	check(hud.visible and hud.task.text==task and not hud.narrator.visible and not hud.title.visible,"motion keeps the task while retiring title and explanatory detail")
	check(not hud.controls.text.is_empty(),"current controls survive movement attention reduction")
	chapter.avatar.velocity=Vector3.ZERO; hud.sample()
	check(hud.title.visible and hud.narrator.visible,"stopping restores optional explanatory detail without a delay")
	check(authority()==before,"attention reduction changes no authoritative state, journal or collision")
func layout_and_capture(label: String) -> void:
	var hud: Node=chapter.art.detail.hud
	var before:=authority()
	for size in [Vector2i(1280,720),Vector2i(800,450)]:
		root.size=size; hud.sample(); await frames(); hud.sample(); await process_frame
		var screen:=root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.control_strip.get_global_rect()),"task and controls fit actual %dx%d viewport: %s"%[size.x,size.y,label])
		check(not hud.top.get_global_rect().intersects(hud.control_strip.get_global_rect()),"task and controls remain separate at %dx%d: %s"%[size.x,size.y,label])
		if hud.bottom.visible:
			check(screen.encloses(hud.bottom.get_global_rect()) and not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()),"active caption fits without task overlap: "+label)
		if OS.get_environment("HOUSEHOLD_ATTENTION_RENDER")=="1":
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			if check(not image.is_empty() and image.get_size()==size and image.save_png("user://household-attention-%s-%dx%d.png"%[label,size.x,size.y])==OK,"actual production frame exported: "+label): captures+=1
	check(authority()==before,"window resize and render preserve state, journal and collisions: "+label)
func service_travel(model, target: Vector3) -> void:
	# Detached reducer fixture uses bounded motion receipts. No physical route is claimed.
	for _i in range(2000):
		if model.service().ledger.stage not in ["outbound","returning"]: break
		var record: Dictionary=model.service().agent
		var old:=Base.point(record.position)
		if Base.distance(old,target)<=1.5: break
		var direction: Vector3=(target-old).normalized()
		record.position=Base.coords(old+direction*Service.SPEED*.1)
		record.velocity=Base.coords(direction*Service.SPEED)
		var error: String=model.record_service_motion(record,.1)
		if not error.is_empty(): check(false,"service fixture admitted bounded motion: "+error); return
		model.advance(); model.progress_service()
	model.progress_service()
func journal_modal() -> void:
	home.process_mode=Node.PROCESS_MODE_INHERIT
	key(KEY_J); await frames()
	check(chapter._paused and chapter._panel.is_visible_in_tree() and not chapter.art.detail.hud.visible,"native J places household guidance beneath the journal modal")
	var before:=authority(); await frames(6)
	check(authority()==before,"native journal freezes the complete household state and collision identities")
	key(KEY_ESCAPE); await frames()
	check(not chapter._paused and chapter.art.detail.hud.visible,"native Escape restores the accepted foreground task")
	home.process_mode=Node.PROCESS_MODE_DISABLED
func overlapping_water_commitments() -> void:
	# These combinations are explicitly admitted by the inherited authority.
	# Guidance must not tell a drawing player to depart and cancel the bucket.
	for cargo in ["delivery","caravan"]:
		var model=base_fixture()
		accepted(model.operate("accept_delivery"),"overlap fixture accepts food custody: "+cargo)
		if cargo=="caravan":
			accepted(Pose.pose(model,Supply.MARKET),"overlap fixture reaches trader")
			accepted(model.operate("deliver"),"overlap fixture settles food")
			accepted(model.operate("accept_escort"),"overlap fixture accepts accompanying carrier")
			accepted(Pose.pose(model,Water.STORE),"overlap fixture returns for water assignment")
		accepted(model.begin_water_round(),"inherited authority permits empty water vessel alongside "+cargo)
		var empty:=present(model,cargo)
		check(empty.kind==cargo,"idle empty vessel leaves existing travel commitment in foreground: "+cargo)
		accepted(Pose.pose(model,Water.WELL),"overlap fixture reaches well: "+cargo)
		accepted(model.water_action("draw"),"inherited authority admits draw alongside "+cargo)
		var drawing:=present(model,"water")
		check(drawing.task.contains("Stay") and drawing.target==Water.WELL,"immediate draw foreground prevents misleading departure toward "+cargo)
		for _i in range(Water.DRAW_TICKS): model.advance()
		var carried:=present(model,"water")
		check(carried.target==Water.STORE and carried.progress.contains("on foot"),"open water foreground preserves movement constraint alongside "+cargo)
		check(not model.mount().is_empty() and not model.mounted(),"new guidance does not bypass inherited mounted-water refusal")
		accepted(Pose.pose(model,Water.STORE),"overlap fixture brings filled water Home")
		accepted(model.water_action("deposit"),"overlap fixture deposits water before continuing "+cargo)
		var continuation:=present(model,cargo)
		check(continuation.kind==cargo and model.water_round().ledger.phase=="ready","deposit restores still-unfinished travel ahead of the idle second draw: "+cargo)
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("HOUSEHOLD ATTENTION requires Xvfb/gl_compatibility for native UI qualification."); quit(2); return
	root.content_scale_size=Vector2i.ZERO; root.size=Vector2i(1280,720)
	home=Launch.make_world(); chapter=home.get_node("ChildhoodChapter")
	root.add_child(home); await frames(4); home.process_mode=Node.PROCESS_MODE_DISABLED
	var model=base_fixture()
	accepted(model.operate("accept_delivery"),"working smith permits separate accepted food custody")
	var delivery:=present(model,"delivery")
	check(delivery.target==Supply.MARKET and delivery.progress.contains("Four"),"food custody names the actual trader and finite carried load")
	reduced_movement_attention(); await layout_and_capture("food")
	await journal_modal()
	accepted(Pose.pose(model,Riding.position(model.horse_record())),"declared on-foot approach to existing horse")
	accepted(chapter.model.restore(model.snapshot()),"declared unmounted food fixture validates")
	chapter._apply(); chapter._refresh()
	home.process_mode=Node.PROCESS_MODE_INHERIT
	key(KEY_F); await frames(12)
	home.process_mode=Node.PROCESS_MODE_DISABLED; chapter.art.detail.hud.sample()
	check(chapter.model.mounted() and chapter.model.validate(chapter.model.snapshot()).is_empty(),"native F mounts existing horse and retains valid food custody")
	var mounted: Dictionary=Guidance.read(chapter)
	check(mounted.kind=="delivery" and mounted.attention_mode=="mounted" and mounted.controls.contains("Brake") and not mounted.controls.contains("WASD"),"mounted delivery retains the active task and actual horse controls")
	check(mounted.task.contains("dismount") and mounted.marker.contains("dismount") and not mounted.marker.contains(" · E"),"mounted handover foregrounds the unavailable speech prerequisite")
	check(not chapter.art.detail.hud.narrator.visible,"mounted movement has no secondary exposition")
	model=base_fixture()
	accepted(model.operate("accept_delivery"),"declared caravan precursor accepts food")
	accepted(Pose.pose(model,Supply.MARKET),"declared trader contact")
	accepted(model.operate("deliver"),"actual food receipt unlocks return caravan")
	accepted(model.operate("accept_escort"),"actual escort commitment accepted")
	var nearby:=present(model,"caravan")
	check(nearby.task.contains("Stay") and nearby.target==Base.point(model.economy().merchant.position),"nearby carrier task asks the player to accompany the actual carrier")
	await layout_and_capture("carrier-near")
	accepted(Pose.pose(model,Supply.QUARTERMASTER),"declared separated-player presentation pose")
	var separated:=present(model,"caravan")
	check(separated.task.contains("Return") and separated.target==nearby.target and separated.marker!=nearby.marker,"separated player is redirected to the waiting carrier, not rewarded at Home")
	check(model.economy().ledger.caravan=="active","guidance cannot check the caravan in")
	await layout_and_capture("carrier-separated")
	model=base_fixture()
	accepted(model.begin_water_round(),"working smith permits an accepted empty water vessel")
	var water_ready:=present(model,"water")
	check(water_ready.target==Water.WELL,"accepted water task takes priority over background smith work")
	accepted(Pose.pose(model,Water.WELL),"declared well contact")
	accepted(model.water_action("draw"),"actual draw begins")
	var drawing:=present(model,"water")
	check(drawing.task.contains("Stay") and drawing.progress.contains("cancels"),"drawing asks the player to remain and explains cancellation")
	for _i in range(Water.DRAW_TICKS): model.advance()
	var carrying:=present(model,"water")
	check(carrying.target==Water.STORE and carrying.task.contains("Carry") and model.water_round().ledger.carried==Water.LOAD,"actual filled vessel takes priority over the smith and targets the household store")
	reduced_movement_attention(); await layout_and_capture("water")
	accepted(Pose.pose(model,Water.STORE),"declared water-store contact")
	accepted(model.water_action("deposit"),"actual first water load deposited")
	var second:=present(model,"water")
	check(second.task.contains("second") and second.target==Water.WELL,"first deposit advances the local task to the remaining load")
	overlapping_water_commitments()
	model=base_fixture()
	accepted(model.operate("hire","guard"),"declared service guard hired")
	accepted(model.rest_watch(),"actual paid supplied watch qualifies service")
	accepted(model.begin_service(),"actual household service brief")
	accepted(Pose.pose(model,Service.SITES.market),"declared local requester contact")
	accepted(model.service_action("hear","market"),"actual market request heard")
	accepted(Pose.pose(model,Supply.QUARTERMASTER),"declared dispatch contact")
	accepted(model.service_action("dispatch","market"),"actual supplied guard dispatched")
	var outbound:=present(model,"service")
	check(outbound.target==Supply.QUARTERMASTER and not outbound.progress.contains("completed"),"service guidance asks for a future local account without reporting remote success")
	service_travel(model,Service.SITES.market)
	check(model.service().ledger.stage=="attending","declared bounded service fixture reaches attendance")
	var attending:=present(model,"service")
	for _i in range(Service.SERVICE_TICKS): model.advance(); model.progress_service()
	check(model.service().ledger.stage=="returning","original service clock finishes bounded attendance")
	var returning:=present(model,"service")
	service_travel(model,Service.home(int(model.service().ledger.slot)))
	check(model.service().ledger.stage=="awaiting_account","declared bounded service fixture returns for a local account")
	var awaiting:=present(model,"service")
	check(outbound==attending and outbound==returning and outbound==awaiting,"remote service stages never change task, controls, marker or explanatory wording")
	check(model.service().ledger.memories.size()==1,"unheard completed service adds no received account")
	await layout_and_capture("service")
	model=base_fixture()
	accepted(Pose.pose(model,Supply.MARKET),"declared friends' outing contact")
	accepted(model.begin_brawl(),"actual friends' outing begins despite background smith")
	accepted(chapter.model.restore(model.snapshot()),"declared brawl fixture validates")
	chapter._apply(); chapter._refresh(); chapter.art.detail.hud.sample()
	var before:=authority()
	check(Guidance.read(chapter).is_empty() and not chapter.art.detail.hud.visible and chapter._hud.is_visible_in_tree(),"active friends' outing retains its original foreground instead of household task pressure")
	check(authority()==before,"yielding to the outing preserves state, journal and collisions")
	home.queue_free(); await frames()
	print("HOUSEHOLD_ATTENTION_TESTS: %d passed, %d failed; %d captures"%[passed,failed,captures])
	quit(1 if failed else 0)
