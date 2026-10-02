# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## The first UI route earns its progress by walking, looking and real E input.
## That first route restores no fixture or saved pose; paused reads preserve authority.
## Later explicitly declared household fixtures qualify presentation and input access.
const Launch := preload("res://childhood/home_launch.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Guidance := preload("res://presentation/beginning_guidance.gd")
const Menu := preload("res://ui/main_menu.tscn")
const Household := preload("res://territory/misl_rules.gd")
const Workshop := preload("res://workshops/workshop_state.gd")
const Craft := preload("res://workshops/workshop_rules.gd")
const Service := preload("res://misl/service_rules.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Riding := preload("res://mounts/riding_rules.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
var passed := 0
var failed := 0
var home: Node3D
var chapter: Node3D

class GuidanceSubject extends Node3D:
	var model

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> bool:
	if value: passed += 1
	else: failed += 1; push_error("BEGINNING GUIDANCE: " + label)
	return value

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func release_controls() -> void:
	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint"]:
		Input.action_release(action)

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.pressed = true
	root.push_input(event, true)

func mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	root.push_input(event, true)

func click_choice(fragment: String,exact: bool=false) -> bool:
	for button in chapter._actions.get_children():
		if button is Button and (button.text==fragment if exact else button.text.contains(fragment)):
			# Journal actions follow remembered speech inside the production scroll area.
			# Reach the actual visible button with native wheel input, not a scroll setter.
			for _i in range(40):
				if chapter._journal_scroll.get_global_rect().encloses(button.get_global_rect()): break
				var within: Vector2=chapter._journal_scroll.get_global_rect().get_center()
				var motion:=InputEventMouseMotion.new();motion.position=within;motion.global_position=within
				root.push_input(motion,true)
				var wheel:=InputEventMouseButton.new()
				wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.position=within;wheel.global_position=within;wheel.pressed=true
				root.push_input(wheel,true)
				wheel=InputEventMouseButton.new()
				wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.position=within;wheel.global_position=within;wheel.pressed=false
				root.push_input(wheel,true);await frames(2)
			if not chapter._journal_scroll.get_global_rect().encloses(button.get_global_rect()):
				print("GUIDANCE SCROLL DIAGNOSTIC: ",JSON.stringify({"phase":chapter.model.workshop_phase(),"button":str(button.get_global_rect()),"scroll":str(chapter._journal_scroll.get_global_rect()),"offset":chapter._journal_scroll.scroll_vertical,"maximum":chapter._journal_scroll.get_v_scroll_bar().max_value,"page":chapter._journal_scroll.get_v_scroll_bar().page}))
			if not check(root.get_visible_rect().encloses(button.get_global_rect()) and chapter._journal_scroll.get_global_rect().encloses(button.get_global_rect()),"actual pointer choice is visible inside its scroll viewport: "+fragment): return false
			var at: Vector2=button.get_global_rect().get_center()
			# Viewport events alone do not move the native window pointer used by release.
			Input.warp_mouse(at);await frames(2)
			if not check(root.get_mouse_position().distance_to(at)<1.1,"native window pointer reaches the displayed choice: "+fragment): return false
			var hover:=InputEventMouseMotion.new();hover.position=at;hover.global_position=at
			root.push_input(hover,true);await process_frame
			if fragment=="Resume" and OS.get_environment("BEGINNING_GUIDANCE_POINTER_DIAGNOSTICS")=="1":
				var hovered: Control=root.gui_get_hovered_control() if root.has_method("gui_get_hovered_control") else null
				print("GUIDANCE POINTER DIAGNOSTIC: ",JSON.stringify({"phase":chapter.model.workshop_phase(),"button_rect":str(button.get_global_rect()),"scroll_rect":str(chapter._journal_scroll.get_global_rect()),"mouse":str(root.get_mouse_position()),"hovered":str(hovered.get_path()) if is_instance_valid(hovered) else "none","disabled":button.disabled,"can_process":button.can_process(),"mouse_mode":Input.mouse_mode,"scroll":chapter._journal_scroll.scroll_vertical}))
				await RenderingServer.frame_post_draw
				var observed:=root.get_texture().get_image()
				if observed!=null: observed.save_png("user://guidance-resume-"+chapter.model.workshop_phase()+".png")
			var received: Array=[false]
			var witness: Callable=func(): received[0]=true
			button.pressed.connect(witness)
			var event:=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=true
			root.push_input(event,true);await process_frame
			event=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=false
			root.push_input(event,true);await frames(4)
			if is_instance_valid(button): button.pressed.disconnect(witness)
			return check(received[0],"actual visible pointer choice reaches the existing button signal: "+fragment)
	return check(false,"actual displayed choice exists: "+fragment)

func face(target: Vector3) -> void:
	var offset: Vector3 = target - chapter.avatar.global_position
	var yaw := atan2(-offset.x, -offset.z)
	var turn := wrapf(yaw - chapter.avatar.pivot.rotation.y, -PI, PI)
	mouse(Vector2(-turn / chapter.avatar.mouse_sensitivity, 0))
	await process_frame
	check(absf(wrapf(chapter.avatar.pivot.rotation.y - yaw, -PI, PI)) < .01, "ordinary mouse input faces the next walk or interaction target")

func walk(target: Vector3, radius: float = .45) -> bool:
	release_controls(); await face(target)
	var best := Base.distance(chapter.avatar.global_position, target)
	var stalled := 0
	for _i in range(600):
		var distance := Base.distance(chapter.avatar.global_position, target)
		if distance <= radius:
			release_controls(); await frames(16)
			return check(Base.distance(chapter.avatar.global_position, target) < radius + 1.0, "native player motor reaches the route target")
		if distance < best - .03: best = distance; stalled = 0
		else: stalled += 1
		if stalled >= 100: break
		Input.action_press("move_forward"); await frames(1)
	release_controls()
	return check(false, "ordinary walking stalled at %s toward %s" % [chapter.avatar.global_position, target])

func physics_identity() -> Array:
	var result: Array = []
	for node in home.find_children("*", "CollisionShape3D", true, false):
		result.append([node.get_instance_id(), node.global_transform, node.shape.get_rid(), node.disabled, node.get_parent().collision_layer, node.get_parent().collision_mask])
	return result

func check_ui(task_fragment: String, marker_fragment: String = "") -> void:
	var hud: Node = chapter.art.detail.hud
	var before: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var bodies := physics_identity()
	for _i in range(4): Guidance.read(chapter); hud.sample()
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "guidance reads and HUD sampling have no canonical, journal or physics authority")
	check(hud.visible and hud.task.text.contains(task_fragment) and not hud.task.text.contains("\n"), "compact beginning shows one current objective: " + task_fragment)
	check(not chapter._hud.is_visible_in_tree() and not chapter._caption.is_visible_in_tree() and not chapter._narrator_label.is_visible_in_tree(), "single compact task and dialogue replace the three legacy text blocks")
	check(hud.words.text == chapter.story_caption() and hud.controls.text.contains("WASD") and hud.controls.text.contains("Mouse"), "directed caption and current movement controls remain available")
	if marker_fragment.is_empty():
		check(not chapter._marker.visible, "orientation has no premature target marker")
	else:
		check(chapter._marker.is_visible_in_tree() and chapter._marker.text.contains(marker_fragment), "named current marker survives its initially hidden orientation state: " + marker_fragment)

func modal_and_layout() -> void:
	var hud: Node = chapter.art.detail.hud
	key(KEY_J); await frames(3)
	check(chapter._paused and chapter._panel.is_visible_in_tree() and not hud.visible, "real journal input immediately suppresses compact beginning guidance")
	var before: Dictionary = chapter.model.snapshot()
	var journal: Array = chapter.model.journal()
	var bodies := physics_identity()
	await frames(8)
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "actual journal keeps whole Home authority frozen")
	key(KEY_ESCAPE); await frames(3)
	check(not chapter._paused and hud.visible and not chapter._hud.is_visible_in_tree(), "Escape resumes the single compact beginning objective")
	key(KEY_F7); await frames(3)
	check(chapter._paused and chapter._art_open and not hud.visible, "real F7 opens the paused art control without compact gameplay text")
	before = chapter.model.snapshot(); journal = chapter.model.journal(); bodies = physics_identity()
	for _i in range(2):
		chapter._menu_action("art:hud")
		check(not hud.visible and not chapter._hud.is_visible_in_tree(), "compact/original switch does not leak gameplay text over the art modal")
	await frames(8)
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "art modal and layout selection keep whole Home authority frozen")
	key(KEY_F7); await frames(3)
	check(not chapter._paused and hud.visible and not chapter._hud.is_visible_in_tree(), "real F7 returns to the single compact beginning objective")
	# Freeze only execution for layout/reference checks; do not forge story progress.
	var old_process := home.process_mode
	home.process_mode = Node.PROCESS_MODE_DISABLED
	before = chapter.model.snapshot(); journal = chapter.model.journal(); bodies = physics_identity()
	for size in [Vector2i(800, 600), Vector2i(1280, 720)]:
		root.size = size; hud.sample(); await frames(3); hud.sample(); await process_frame
		var screen := root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.bottom.get_global_rect()), "beginning text fits the %dx%d viewport" % [size.x, size.y])
		check(not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()), "beginning task and spoken words do not overlap after resize")
	hud.compact = false; hud.sample()
	check(not hud.visible and chapter._hud.is_visible_in_tree() and chapter._caption.is_visible_in_tree(), "classic mode restores retained task and speech labels")
	check(chapter._marker.is_visible_in_tree(), "classic mode retains the current lesson's dynamic marker")
	hud.compact = true; chapter._refresh()
	check(hud.visible and not chapter._hud.is_visible_in_tree() and chapter._marker.is_visible_in_tree(), "return to compact mode restores one objective and its current marker")
	check(chapter.model.snapshot() == before and chapter.model.journal() == journal and physics_identity() == bodies, "resize and HUD switches preserve authority and physical identities")
	home.process_mode = old_process

func main_menu_contract() -> void:
	var menu: Control = Menu.instantiate()
	root.add_child(menu); current_scene = menu; await frames(3)
	var begin: Button = menu.find_child("BeginChildhood", true, false)
	check(is_instance_valid(begin) and root.gui_get_focus_owner() == begin and begin.is_visible_in_tree(), "main menu focuses its visible childhood Begin action")
	var panel := begin.get_parent()
	var group_index := -1
	for node in panel.get_children():
		if node is Label and node.text == "DEVELOPMENT STUDIES": group_index = node.get_index()
	check(group_index > begin.get_index(), "development studies are visibly grouped after the primary beginning")
	for node in panel.get_children():
		if node is Button and node != begin:
			check(node.get_index() > group_index, "retained study entry follows the development group")
	var buttons := menu.find_children("*", "Button", true, false)
	for destination in ["res://world/political_home.tscn", "res://world/command_sandbox.tscn",
			"res://world/house_sandbox.tscn", "res://mechanics/course.tscn",
			"res://presentation/equipment_study.tscn", "res://mounts/horsecraft_study.tscn",
			"res://mechanics/ground_course.tscn", "res://world/mahan_camp.tscn",
			"res://history/punjab_chiefs_home.tscn"]:
		var retained := buttons.filter(func(button): return button.get_meta("destination_scene", "") == destination)
		check(retained.size() == 1, "retained development study remains available: " + destination)
	for mode in ["continue", "new"]:
		var retained := buttons.filter(func(button): return button.get_meta("slice_mode", "") == mode)
		check(retained.size() == 1, "retained Slice action remains available: " + mode)
	begin.pressed.emit(); await frames(3)
	home = current_scene; chapter = home.get_node("ChildhoodChapter")
	check(home != menu and is_instance_valid(chapter.intro_session) and chapter.model.stage() == "orientation", "real Begin action opens the production prologue before original Home play")
	check(chapter.model.progress().walked == 0.0 and chapter.model.progress().looked == 0.0 and chapter.model.journal().is_empty(), "menu entry invents no childhood progress or memories")
	current_scene = null; home.queue_free(); home = null; chapter = null; await frames(4)

func household_presentation_transition() -> void:
	# This is explicitly a restored completed-inquiry fixture, not a fresh journey.
	# Only allowance acceptance below uses actual displayed dialogue input.
	if is_instance_valid(home): home.queue_free()
	home=null;chapter=null;await frames(4)
	home=Launch.make_world();chapter=home.get_node("ChildhoodChapter")
	check(chapter.model.restore(Fixture.complete()).is_empty(),"declared completed-inquiry presentation fixture restores through the existing validator")
	root.add_child(home);await frames(5)
	check(not chapter.model.has_economy() and Guidance.read(chapter).task=="Speak to the quartermaster","completed inquiry alone keeps the original allowance handoff")
	check_ui("quartermaster","Quartermaster")
	await face(Household.QUARTERMASTER);key(KEY_E);await frames(4)
	check(chapter._paused and chapter._panel.is_visible_in_tree(),"real E opens the actual quartermaster dialogue from the declared fixture")
	if not await click_choice("Accept the limited household allowance"): return
	check(chapter.model.has_economy() and chapter.model.workshop_phase()=="unassigned" and not chapter._paused,"actual allowance choice resumes compact guidance before a commission is assigned")
	check(chapter.model.economy().events.is_empty() and chapter.model.economy().ledger.treasury==120 and chapter.model.economy().ledger.stock.timber==8,"commission guidance places no order or charge after the actual allowance transition")
	check_ui("smith's commission","Quartermaster")
	check(Guidance.read(chapter).target==Household.QUARTERMASTER and chapter.art.detail.hud.controls.text.contains("B  Accounts"),"unassigned commission points at the existing quartermaster with the actual accounts control")
	await modal_and_layout()
	check(chapter.model.workshop_phase()=="unassigned" and chapter.model.validate(chapter.model.snapshot()).is_empty(),"post-allowance modal and resize checks preserve valid unassigned custody")
	await face(Household.QUARTERMASTER);key(KEY_E);await frames(4)
	if not await click_choice("Commission two tool bundles"): return
	check(chapter.model.workshop_phase()=="fuel" and chapter.model.economy().ledger.treasury==116 and chapter.model.economy().ledger.stock.timber==6,"actual displayed commission choice reserves one inherited order and charge")
	check(chapter._marker.visible and chapter._marker.text=="Smith · E" and chapter._marker.position.is_equal_approx(Craft.SITE+Vector3.UP*2.1),"actual reserve handoff replaces the quartermaster objective with the smith destination")

func guidance_fixture() -> GuidanceSubject:
	var subject:=GuidanceSubject.new();subject.model=Workshop.new()
	check(subject.model.restore(Fixture.complete()).is_empty() and subject.model.begin_allowance().is_empty(),"declared guidance priority fixture has one existing allowance authority")
	return subject

func check_deferred(subject: GuidanceSubject,label: String) -> void:
	var before: Dictionary=subject.model.snapshot();var journal: Array=subject.model.journal()
	check(Guidance.read(subject).is_empty(),"unassigned commission guidance defers to "+label)
	check(subject.model.snapshot()==before and subject.model.journal()==journal,"deferring guidance preserves whole state and memories for "+label)
	check(subject.model.validate(before).is_empty(),"declared "+label+" priority fixture validates")

func household_priority_fixtures() -> void:
	# Reducer-created priority cases are pure presentation fixtures; no route is claimed.
	var subject:=guidance_fixture()
	check(subject.model.operate("accept_delivery").is_empty(),"declared carried food commitment accepted")
	check_deferred(subject,"contracted food custody")
	check(Pose.pose(subject.model,Household.MARKET).is_empty() and subject.model.operate("deliver").is_empty() and subject.model.operate("accept_escort").is_empty(),"declared returning caravan commitment accepted through existing receipts")
	check_deferred(subject,"active caravan");subject.free()
	subject=guidance_fixture()
	check(Pose.pose(subject.model,Household.MARKET).is_empty() and subject.model.begin_brawl().is_empty(),"declared friends' outing accepted")
	check_deferred(subject,"the friends' active outing");subject.free()
	subject=guidance_fixture()
	check(subject.model.begin_water_round().is_empty(),"declared water round accepted without inventing carried water")
	check(not Guidance.read(subject).is_empty(),"idle water record preserves inherited compatibility with an unassigned commission")
	check(Pose.pose(subject.model,Water.WELL).is_empty() and subject.model.water_action("draw").is_empty(),"declared water draw begun through existing reducer")
	check_deferred(subject,"drawing water")
	for _i in range(Water.DRAW_TICKS): subject.model.advance()
	check_deferred(subject,"carried water");subject.free()
	subject=guidance_fixture()
	check(subject.model.operate("hire","guard").is_empty() and subject.model.rest_watch().is_empty() and subject.model.begin_service().is_empty(),"declared supplied guard and idle service record use the existing allowance clock")
	check(not Guidance.read(subject).is_empty(),"idle service record preserves inherited compatibility with an unassigned commission")
	check(Pose.pose(subject.model,Service.SITES.market).is_empty() and subject.model.service_action("hear","market").is_empty() and Pose.pose(subject.model,Household.QUARTERMASTER).is_empty() and subject.model.service_action("dispatch","market").is_empty(),"declared service detail is dispatched through existing requests and receipts")
	check_deferred(subject,"reserved service attendance");subject.free()
	subject=guidance_fixture()
	check(subject.model.workshop_action("reserve").is_empty(),"declared smith order reserves existing fuel and payment")
	check_deferred(subject,"the established fuel guidance")
	check(Pose.pose(subject.model,Craft.SITE).is_empty() and subject.model.workshop_action("start").is_empty(),"declared fuel passes to the smith")
	check_deferred(subject,"the established working guidance")
	for _i in range(Craft.WORK_TICKS): subject.model.advance()
	check_deferred(subject,"the established ready guidance")
	check(subject.model.workshop_action("collect").is_empty(),"declared ready tools pass to the carrier")
	check_deferred(subject,"the established carried-tools guidance");subject.free()

func check_workshop_presentation(subject: GuidanceSubject,phase: String,target: Vector3,marker: String) -> void:
	# Each phase is a declared validated presentation restoration, not played travel.
	var old_process:=home.process_mode;home.process_mode=Node.PROCESS_MODE_DISABLED
	check(chapter.model.restore(subject.model.snapshot()).is_empty(),"declared "+phase+" presentation fixture restores through the existing validator")
	chapter._apply();chapter._message=subject.model.journal()[-1].text;chapter._refresh()
	var hud: Node=chapter.art.detail.hud
	var before: Dictionary=chapter.model.snapshot();var journal: Array=chapter.model.journal();var bodies:=physics_identity()
	for _i in range(4): Guidance.read(chapter);hud.sample()
	check(hud.visible and not chapter._hud.is_visible_in_tree() and chapter.model.workshop_phase()==phase,"compact presentation owns the declared "+phase+" objective without legacy text")
	check(chapter._marker.visible and chapter._marker.text==marker and chapter._marker.position.is_equal_approx(target+Vector3.UP*2.1),"declared "+phase+" projects the actual custody destination onto the original marker")
	if phase=="complete":
		check(hud.task.text=="First household responsibility complete" and hud.narrator.text=="Both tool bundles were returned. The commission is settled. Speak to the quartermaster to choose another responsibility.","settled commission shows only its completed responsibility and existing quartermaster handoff")
		check(chapter.model.economy().ledger.stock.tools==4 and chapter.model.economy().ledger.treasury==116 and chapter.model.economy().ledger.purse==18,"completed presentation grants no extra output or private payout")
	else:
		check(hud.task.text==chapter.workshop_hint().replace(" [E]",""),"declared "+phase+" keeps the existing workshop's received task text")
	for size in [Vector2i(800,600),Vector2i(1280,720)]:
		root.size=size;hud.sample();await frames(3);hud.sample();await process_frame
		var screen:=root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.bottom.get_global_rect()) and not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()),"declared "+phase+" objective fits without overlap at %dx%d"%[size.x,size.y])
	hud.compact=false;chapter._refresh()
	check(not hud.visible and chapter._hud.is_visible_in_tree() and not chapter._marker.visible,"classic refresh retains its original UI and marker behavior for "+phase)
	hud.compact=true;chapter._refresh();hud.sample()
	check(hud.visible and not chapter._hud.is_visible_in_tree() and chapter._marker.visible and chapter._marker.position.is_equal_approx(target+Vector3.UP*2.1),"compact refresh reinstates the correct "+phase+" destination after the inherited marker reset")
	check(chapter.model.snapshot()==before and chapter.model.journal()==journal and physics_identity()==bodies,"sampling, resizing and layout switches preserve whole state, journal and collision identities for "+phase)
	home.process_mode=old_process
	await modal_and_layout()
	key(KEY_J);await frames(3)
	before=chapter.model.snapshot();journal=chapter.model.journal();bodies=physics_identity()
	await frames(8)
	check(chapter._paused and not hud.visible and chapter.model.snapshot()==before and chapter.model.journal()==journal and physics_identity()==bodies,"real journal freezes all "+phase+" state before an actual pointer resume")
	if not await click_choice("Resume",true):
		key(KEY_ESCAPE);await frames(3);return
	check(not chapter._paused and hud.visible and chapter._marker.visible and chapter._marker.position.is_equal_approx(target+Vector3.UP*2.1),"actual displayed Resume pointer restores the correct "+phase+" compact objective")

func completed_priority_fixtures(completed: Dictionary) -> void:
	# Completed summaries defer to the same existing custody exclusions as onboarding.
	var subject:=GuidanceSubject.new();subject.model=Workshop.new()
	check(subject.model.restore(completed).is_empty() and subject.model.operate("accept_delivery").is_empty(),"declared completed commission accepts a separate existing food contract")
	check_deferred(subject,"completed-commission food custody")
	check_priority_presentation(subject,"completed-commission food custody")
	check(Pose.pose(subject.model,Household.MARKET).is_empty() and subject.model.operate("deliver").is_empty() and subject.model.operate("accept_escort").is_empty(),"declared completed commission accepts an existing return caravan")
	check_deferred(subject,"completed-commission active caravan");check_priority_presentation(subject,"completed-commission active caravan");subject.free()
	subject=GuidanceSubject.new();subject.model=Workshop.new()
	check(subject.model.restore(completed).is_empty() and Pose.pose(subject.model,Household.MARKET).is_empty() and subject.model.begin_brawl().is_empty(),"declared completed commission accepts the existing friends' outing")
	check_deferred(subject,"completed-commission friends' outing");check_priority_presentation(subject,"completed-commission friends' outing");subject.free()
	subject=GuidanceSubject.new();subject.model=Workshop.new()
	check(subject.model.restore(completed).is_empty() and subject.model.begin_water_round().is_empty() and Pose.pose(subject.model,Water.WELL).is_empty() and subject.model.water_action("draw").is_empty(),"declared completed commission begins an existing water draw")
	check_deferred(subject,"completed-commission drawing water")
	check_priority_presentation(subject,"completed-commission drawing water")
	for _i in range(Water.DRAW_TICKS): subject.model.advance()
	check_deferred(subject,"completed-commission carried water");check_priority_presentation(subject,"completed-commission carried water");subject.free()
	subject=GuidanceSubject.new();subject.model=Workshop.new()
	check(subject.model.restore(completed).is_empty() and subject.model.operate("hire","guard").is_empty() and subject.model.rest_watch().is_empty() and subject.model.begin_service().is_empty() and Pose.pose(subject.model,Service.SITES.market).is_empty() and subject.model.service_action("hear","market").is_empty() and Pose.pose(subject.model,Household.QUARTERMASTER).is_empty() and subject.model.service_action("dispatch","market").is_empty(),"declared completed commission reserves an existing supplied service detail")
	check_deferred(subject,"completed-commission reserved service");check_priority_presentation(subject,"completed-commission reserved service");subject.free()

func check_priority_presentation(subject: GuidanceSubject,label: String) -> void:
	# Declared temporary presentation restoration; the previous test world is restored.
	var old_process:=home.process_mode;home.process_mode=Node.PROCESS_MODE_DISABLED
	var previous: Dictionary=chapter.model.snapshot();var previous_message: String=chapter._message
	check(chapter.model.restore(subject.model.snapshot()).is_empty(),"declared "+label+" presentation fixture restores")
	chapter._apply();chapter._refresh()
	var before: Dictionary=chapter.model.snapshot();var journal: Array=chapter.model.journal();var bodies:=physics_identity()
	for _i in range(4): chapter.art.detail.hud.sample()
	check(not chapter.art.detail.hud.visible and chapter._hud.is_visible_in_tree(),"compact household presentation yields to existing "+label+" UI")
	check(chapter.model.snapshot()==before and chapter.model.journal()==journal and physics_identity()==bodies,"priority sampling preserves whole state, journal and collision identities for "+label)
	check(chapter.model.restore(previous).is_empty(),"previous presentation world restored after "+label)
	chapter._message=previous_message;chapter._apply();chapter._refresh();home.process_mode=old_process

func workshop_presentation_fixtures() -> void:
	var subject:=guidance_fixture()
	check(subject.model.workshop_action("reserve").is_empty(),"declared workshop presentation order reserves one fee and fuel")
	await check_workshop_presentation(subject,"fuel",Craft.SITE,"Smith · E")
	check(Pose.pose(subject.model,Craft.SITE).is_empty() and subject.model.workshop_action("start").is_empty(),"declared workshop presentation hands the existing fuel to the smith")
	await check_workshop_presentation(subject,"working",Craft.SITE,"Smith · E")
	var working_task: String=chapter.art.detail.hud.task.text;var working_marker: String=chapter._marker.text
	var cargo_subject:=GuidanceSubject.new();cargo_subject.model=Workshop.new()
	check(cargo_subject.model.restore(subject.model.snapshot()).is_empty() and Pose.pose(cargo_subject.model,Household.QUARTERMASTER).is_empty() and cargo_subject.model.operate("accept_delivery").is_empty(),"declared hands-free working commission accepts an existing separate cargo contract")
	check_priority_presentation(cargo_subject,"working-commission food custody");cargo_subject.free()
	for _i in range(Craft.WORK_TICKS): subject.model.advance()
	await check_workshop_presentation(subject,"ready",Craft.SITE,"Smith · E")
	check(chapter.art.detail.hud.task.text==working_task and chapter._marker.text==working_marker,"remote readiness changes neither received workshop guidance nor its smith marker")
	check(subject.model.workshop_action("collect").is_empty(),"declared workshop presentation collects the existing output")
	await check_workshop_presentation(subject,"tools",Household.QUARTERMASTER,"Quartermaster · E")
	check(Pose.pose(subject.model,Household.QUARTERMASTER).is_empty() and subject.model.workshop_action("deliver").is_empty(),"declared workshop presentation settles the existing two tool bundles")
	await check_workshop_presentation(subject,"complete",Household.QUARTERMASTER,"Quartermaster · E")
	completed_priority_fixtures(subject.model.snapshot());subject.free()

func mounted_workshop_presentation_fixture(phase: String) -> Dictionary:
	# Declared working/ready presentation restoration, not a fresh played journey.
	# The horse retains its original unmounted record; walking and F earn this mount.
	var subject:=guidance_fixture()
	var original_horse: Dictionary=subject.model.horse_record()
	check(subject.model.workshop_action("reserve").is_empty() and Pose.pose(subject.model,Craft.SITE).is_empty() and subject.model.workshop_action("start").is_empty(),"declared mounted "+phase+" fixture begins the existing smith work")
	if phase=="ready":
		for _i in range(Craft.WORK_TICKS): subject.model.advance()
	print("MOUNTED WORKSHOP INHERITED HORSE: ",JSON.stringify({"phase":phase,"horse":original_horse}))
	check(subject.model.horse_record()==original_horse and not subject.model.mounted(),"declared mounted "+phase+" fixture preserves its actual inherited unmounted horse record")
	check(Pose.pose(subject.model,Riding.position(original_horse)+Vector3.LEFT*4.0).is_empty(),"declared mounted "+phase+" presentation fixture places only the unmounted player near the existing horse")
	if is_instance_valid(home): home.queue_free()
	home=null;chapter=null;await frames(4)
	home=Launch.make_world();chapter=home.get_node("ChildhoodChapter")
	check(chapter.model.restore(subject.model.snapshot()).is_empty(),"declared mounted "+phase+" presentation fixture restores through the existing validator")
	subject.free();root.add_child(home);await frames(5)
	check(chapter.model.validate(chapter.model.snapshot()).is_empty() and chapter.model.workshop_phase()==phase and not chapter.model.mounted(),"declared mounted "+phase+" setup remains valid and actually unmounted")
	if not await walk(Riding.position(chapter.model.horse_record())+Vector3.LEFT*1.8,.35): return {}
	key(KEY_F);await frames(16)
	check(chapter.model.mounted() and chapter.model.workshop_phase()==phase and not chapter.avatar.is_physics_processing() and chapter.avatar.collision_layer==0,"actual walking and F earn mounted control in hands-free "+phase+" work")
	var hud: Node=chapter.art.detail.hud
	var observed: Dictionary={"phase":phase,"mounted":chapter.model.mounted(),"task":hud.task.text,"controls":hud.controls.text,"marker":chapter._marker.text,"narrator":hud.narrator.text,"words":hud.words.text}
	print("MOUNTED WORKSHOP OBSERVATION: ",JSON.stringify(observed))
	check(hud.visible and observed.task=="Stop and dismount to hear the smith","mounted "+phase+" task first names the actual speech prerequisite")
	check(observed.controls=="W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped","mounted "+phase+" controls show the inherited horse motor and safe dismount")
	check(chapter._marker.visible and observed.marker=="Smith · dismount first" and chapter._marker.position.is_equal_approx(Craft.SITE+Vector3.UP*2.1),"mounted "+phase+" smith marker names dismount instead of an unavailable E action")
	var old_process:=home.process_mode;home.process_mode=Node.PROCESS_MODE_DISABLED
	var before: Dictionary=chapter.model.snapshot();var journal: Array=chapter.model.journal();var bodies:=physics_identity()
	for _i in range(4): hud.sample()
	for size in [Vector2i(800,600),Vector2i(1280,720)]:
		root.size=size;hud.sample();await frames(3);hud.sample();await process_frame
		var screen:=root.get_visible_rect()
		check(screen.encloses(hud.top.get_global_rect()) and screen.encloses(hud.bottom.get_global_rect()) and not hud.top.get_global_rect().intersects(hud.bottom.get_global_rect()),"mounted "+phase+" guidance fits without overlap at %dx%d"%[size.x,size.y])
	check(chapter.model.snapshot()==before and chapter.model.journal()==journal and physics_identity()==bodies,"mounted "+phase+" sampling and resize preserve whole authority, journal and collision identities")
	home.process_mode=old_process
	before=chapter.model.snapshot();journal=chapter.model.journal()
	key(KEY_E);await frames(3)
	print("MOUNTED WORKSHOP REFUSAL: ",JSON.stringify({"phase":phase,"message":chapter._message,"mounted":chapter.model.mounted(),"paused":chapter._paused,"tick_before":before.childhood.tick,"tick_after":chapter.model.progress().tick}))
	check(chapter.model.mounted() and not chapter._paused and not chapter._panel.is_visible_in_tree() and chapter._message.to_lower().contains("dismount"),"actual mounted "+phase+" E refuses speech through the inherited interaction")
	# Compare to the same model's ordinary advancement, including derived game_time.
	# This detached test oracle never joins the live scene or executes a second motor.
	var expected_model=chapter.model.get_script().new()
	check(expected_model.restore(before).is_empty(),"declared mounted "+phase+" no-interaction control restores the exact pre-E authority")
	var advanced: int=int(chapter.model.progress().tick)-int(before.childhood.tick)
	for _i in range(advanced): expected_model.advance()
	check(advanced>0 and chapter.model.snapshot()==expected_model.snapshot() and chapter.model.journal()==journal,"mounted "+phase+" E refusal equals ordinary clock advancement across the whole world without custody or knowledge")
	await modal_and_layout()
	check(chapter.model.mounted() and chapter.model.workshop_phase()==phase,"mounted "+phase+" journal and art controls preserve the existing executor and custody")
	key(KEY_F);await frames(5)
	check(not chapter.model.mounted() and chapter.model.workshop_phase()==phase and chapter.avatar.is_physics_processing() and chapter.avatar.collision_layer==1,"actual stopped F dismount restores the inherited on-foot executor in "+phase)
	check(hud.visible and hud.task.text==chapter.workshop_hint().replace(" [E]","") and hud.controls.text.contains("E  Speak") and chapter._marker.text=="Smith · E" and chapter._marker.position.is_equal_approx(Craft.SITE+Vector3.UP*2.1),"actual "+phase+" dismount restores received workshop guidance and the available smith action")
	check(chapter.model.validate(chapter.model.snapshot()).is_empty(),"actual mounted "+phase+" round trip leaves the whole restored world valid")
	return observed

func mounted_workshop_presentation_fixtures() -> void:
	var working: Dictionary=await mounted_workshop_presentation_fixture("working")
	var ready: Dictionary=await mounted_workshop_presentation_fixture("ready")
	if not working.is_empty() and not ready.is_empty():
		for field in ["task","controls","marker","narrator","words"]:
			check(working[field]==ready[field],"mounted working and ready presentation reveal no remote result through "+field)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("BEGINNING GUIDANCE requires a real display backend for native mouse capture; run with Xvfb/gl_compatibility.")
		quit(2); return
	root.content_scale_size = Vector2i.ZERO; root.size = Vector2i(1280, 720)
	root.disable_3d = true # This route qualifies native input/physics and UI, not pixels.
	release_controls(); await main_menu_contract()
	home = Launch.make_world(); root.add_child(home); chapter = home.get_node("ChildhoodChapter"); await frames(8)
	check(chapter.model.stage() == "orientation" and not chapter.model.progress().letter_seen and chapter.model.journal().is_empty(), "construction begins with a genuinely fresh orientation authority")
	check_ui("Explore")
	mouse(Vector2(160, 0)); mouse(Vector2(-160, 0))
	if not await walk(Vector3(-4.8, .14, 1.0)): await finish(); return
	if not await walk(Vector3(-5.2, .14, 2.0)): await finish(); return
	check(chapter.model.stage() == "letter" and chapter.model.progress().walked >= 5.0 and chapter.model.progress().looked >= .6, "ordinary walking and looking earn the first lesson transition")
	check_ui("sealed message", "Courier")
	await modal_and_layout()
	await face(Base.SITES.courier); key(KEY_E); await frames(3)
	check(chapter.model.progress().letter_seen and chapter.model.progress().heard.is_empty() and chapter.model.journal().size() == 1, "first real E collects only the sealed message")
	check_ui("courier's account", "Courier")
	key(KEY_E); await frames(3)
	check(chapter.model.progress().heard == ["courier"], "second real E hears only the courier's account")
	check_ui("steward", "Steward")
	if not await walk(Vector3(-10.6, .14, 4.0)): await finish(); return
	await face(Base.SITES.steward); key(KEY_E); await frames(3)
	check(chapter.model.stage() == "riding" and chapter.model.progress().heard == ["courier", "steward"], "actual steward interaction opens riding through the original reducer")
	check_ui("household horse", "Household horse")
	check(chapter.model.journal().map(func(memory): return memory.id) == ["letter", "courier", "steward"] and chapter.model.capabilities() == {"single_standing": false, "paired_standing": false, "mounted_matchlock": false}, "guidance exposes only actually earned memories and grants no advanced skill")
	await modal_and_layout()
	# Removing only this UI component restores field captions without touching art.
	home.process_mode = Node.PROCESS_MODE_DISABLED
	var before: Dictionary = chapter.model.snapshot()
	var bodies := physics_identity()
	var hud: Node = chapter.art.detail.hud
	var captions: Array = hud._labels.duplicate()
	hud.get_parent().remove_child(hud); hud.queue_free(); await frames(3)
	check(chapter._hud.is_visible_in_tree() and chapter._caption.is_visible_in_tree(), "HUD component removal restores retained UI references")
	check(captions.all(func(record): return not is_instance_valid(record.node) or record.node.visible == record.visible), "HUD removal restores original static field-caption visibility")
	check(chapter._marker.is_visible_in_tree() and chapter.model.snapshot() == before and physics_identity() == bodies, "HUD removal preserves the current dynamic marker and whole Home authority")
	await household_presentation_transition()
	household_priority_fixtures()
	await workshop_presentation_fixtures()
	await mounted_workshop_presentation_fixtures()
	await finish()

func finish() -> void:
	release_controls(); current_scene = null
	if is_instance_valid(home): home.queue_free()
	home = null; chapter = null; await frames(4)
	print("BEGINNING_GUIDANCE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
