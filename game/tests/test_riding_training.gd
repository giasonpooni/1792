extends SceneTree
## An explicit legacy Home fixture supplies the entry; all lesson motion uses game input.
const Launch:=preload("res://childhood/home_launch.gd")
const Base:=preload("res://childhood/childhood_state.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const Fixed:=preload("res://history/fixed_interlude.gd")
const State:=preload("res://mounts/horsecraft_state.gd")
const TrainingSession:=preload("res://mounts/riding_training_session.gd")
const SAVE:="user://riding-training-native-only.json"
var passed:=0
var failed:=0
var home: Node3D
var chapter: Node3D
var session: Node
var lesson: Node3D

static func legacy_riding_seed() -> Dictionary:
	# Explicit admitted old-save fixture, not a claim of playing the inherited gate.
	var model:=Base.new()
	var value: Dictionary=model.snapshot()
	value.player.position=Base.coords(Base.SITES.letter+Vector3.RIGHT)
	value.actors.ranjit_singh.position=value.player.position.duplicate()
	assert(model.restore(value).is_empty())
	assert(model.inspect_letter().is_empty());assert(model.hear("courier").is_empty())
	value=model.snapshot();value.player.position=Base.coords(Base.SITES.steward+Vector3.RIGHT)
	value.actors.ranjit_singh.position=value.player.position.duplicate()
	assert(model.restore(value).is_empty());assert(model.hear("steward").is_empty())
	value=model.snapshot();value.childhood.walked=6.0;value.childhood.looked=1.0;value.childhood.ride_gate=1
	value.player.position=[5.5,.14,-4.0];value.actors.ranjit_singh.position=value.player.position.duplicate()
	assert(model.validate(value).is_empty())
	return value

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if value: passed+=1
	else:
		failed+=1;push_error("RIDING TRAINING: "+message)

func ok(error: String,message: String) -> void:
	check(error.is_empty(),message+": "+error)

static func same_json(left: Variant,right: Variant) -> bool:
	# JSON numbers normalize integer types and can round the final binary digit.
	if (left is int or left is float) and (right is int or right is float):
		return absf(float(left)-float(right))<=1.0e-12
	if left is Dictionary and right is Dictionary:
		if left.size()!=right.size(): return false
		for field in left:
			if not right.has(field) or not same_json(left[field],right[field]): return false
		return true
	if left is Array and right is Array:
		if left.size()!=right.size(): return false
		for i in range(left.size()):
			if not same_json(left[i],right[i]): return false
		return true
	return left==right

func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0,brake: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if brake: Input.action_press("move_backward")

func key(target: Node,code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	if target==lesson and is_instance_valid(session): session._input(event)
	else: target._unhandled_input(event)

func click(target: Node) -> void:
	var event:=InputEventMouseButton.new();event.pressed=true;event.button_index=MOUSE_BUTTON_LEFT
	if target==lesson and is_instance_valid(session): session._input(event)
	else: target._unhandled_input(event)

func install_seed(at: Vector3=Vector3(5.5,.14,-4.0)) -> void:
	var value:=legacy_riding_seed()
	value.player.position=Base.coords(at);value.actors.ranjit_singh.position=value.player.position.duplicate()
	ok(chapter.model.restore(value),"explicit legacy riding fixture imports")
	chapter._apply()
	var toward: Vector3=Skills.TRAINING_SITE-chapter.avatar.global_position
	chapter.avatar.pivot.rotation.y=atan2(-toward.x,-toward.z)
	chapter.avatar.pivot.rotation.x=0.0

func _unparked_session_disposal() -> void:
	# Freeze this explicit legacy entry fixture only so queued disposal can be
	# compared at an exact boundary, without ordinary Home motion between reads.
	var prior_process: int=home.process_mode
	home.process_mode=Node.PROCESS_MODE_DISABLED
	var before: Dictionary=chapter.model.snapshot()
	var player_pose: Transform3D=chapter.avatar.global_transform
	var horse_pose: Transform3D=chapter.horse.global_transform
	var pointer_mode: int=Input.mouse_mode
	var drawing_disabled: bool=root.disable_3d
	var canvases: Dictionary={}
	for canvas in home.find_children("*","CanvasLayer",true,false): canvases[canvas.get_instance_id()]=canvas.visible
	for practice in ["unknown","single","pair"]:
		check(not chapter.open_riding_training(practice).is_empty(),"pre-park %s request is refused"%practice)
		await process_frame;await process_frame
		check(Input.mouse_mode==pointer_mode,"rejected %s session disposal preserves the actual Home pointer mode"%practice)
		check(chapter.training_session==null and root.find_children("RidingTrainingSession","CanvasLayer",false,false).is_empty(),"rejected %s request leaves no active or undisposed overlay"%practice)
	var unstarted:=TrainingSession.new();root.add_child(unstarted)
	var unstarted_ref: WeakRef=weakref(unstarted)
	unstarted.queue_free();await process_frame;await process_frame
	check(unstarted_ref.get_ref()==null and Input.mouse_mode==pointer_mode,"never-started session disposal preserves its caller's mouse ownership")
	var abandoned:=TrainingSession.new();root.add_child(abandoned)
	var abandoned_ref: WeakRef=weakref(abandoned)
	abandoned.abandon();await process_frame;await process_frame
	check(abandoned_ref.get_ref()==null and Input.mouse_mode==pointer_mode,"abandoning a no-host visit releases no unrelated input ownership")
	var after_canvases: Dictionary={}
	for canvas in home.find_children("*","CanvasLayer",true,false): after_canvases[canvas.get_instance_id()]=canvas.visible
	check(chapter.model.snapshot()==before and chapter.avatar.global_transform==player_pose and chapter.horse.global_transform==horse_pose,"unparked disposal changes neither canonical Home authority nor native body transforms")
	check(home.process_mode==Node.PROCESS_MODE_DISABLED and root.disable_3d==drawing_disabled and after_canvases==canvases,"unparked disposal preserves execution, drawing and Canvas flags it never owned")
	home.process_mode=prior_process

func _run() -> void:
	controls();home=Launch.make_world();root.add_child(home);current_scene=home
	chapter=home.get_node("ChildhoodChapter");chapter.save_path=SAVE;await frames(6)
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false},"fresh Home starts with all advanced riding skills locked")
	var initial: Dictionary=chapter.model.snapshot()
	check(not chapter.open_riding_training().is_empty(),"training before ordinary riding lesson is refused")
	check(chapter.model.snapshot()==initial,"early refusal preserves Home authority")
	install_seed(Vector3(0,.14,0))
	check(not chapter.open_riding_training().is_empty(),"remote training entry is refused")
	install_seed()
	await _unparked_session_disposal()
	check(not chapter.open_riding_training("single").is_empty() and not chapter.open_riding_training("pair").is_empty(),"locked skills cannot enter either learned practice formation")
	var agreed: Vector3=chapter.avatar.global_position
	chapter.avatar.global_position+=Vector3.RIGHT
	check(not chapter.open_riding_training().is_empty(),"body and recorded position disagreement refuses entry")
	chapter.avatar.global_position=agreed
	var art_id: int=chapter.art.get_instance_id()
	var art_enabled: bool=chapter.art.enabled
	var detail_id: int=chapter.art.detail.child_root.get_instance_id()
	var carried_id: int=chapter.workplace.carried.get_instance_id()
	var material_record: Dictionary=chapter.art.material_fidelity.records[0]
	var material_node: MeshInstance3D=material_record.node
	var material=material_node.material_override
	var paused_home: Dictionary=chapter.model.snapshot()
	var player_pose: Transform3D=chapter.avatar.global_transform
	var horse_pose: Transform3D=chapter.horse.global_transform
	ok(chapter.open_riding_training(),"ordinary riding lesson opens bound training")
	session=chapter.training_session;lesson=session.lesson
	check(home.is_inside_tree(),"Home stays in-tree while training is active")
	check(session.viewport.own_world_3d and lesson.get_world_3d()!=chapter.get_world_3d(),"training has a separate native physics world")
	check(root.disable_3d and not session.viewport.disable_3d,"only hidden Home rendering is suspended; lesson still renders its own world")
	check(home.process_mode==Node.PROCESS_MODE_DISABLED,"Home execution and input are suspended together")
	await frames(8)
	check(lesson.lesson_phase=="single" and not lesson.right.visible and lesson.right.collision_layer==0,"single exercise has only one active horse")
	check(lesson.hud.text.contains("ONE MOVING HORSE") and lesson.hud.text.contains("Moving standing hold:"),"first lesson presents one current exercise and its actual moving hold")
	check(not lesson.hud.text.contains("Left click fire") and not lesson.hud.text.contains("R reload") and not lesson.hud.text.contains("Enter next exercise"),"early single exercise hides unavailable weapon and continuation controls")
	var inactive_pose: Transform3D=lesson.right.global_transform
	var refused_shots: Dictionary=lesson.model.snapshot()
	click(lesson)
	check(lesson.model.snapshot()==refused_shots,"firing cannot skip the first balance lesson")
	key(lesson,KEY_ENTER)
	check(lesson.lesson_phase=="single","Enter cannot skip single standing hold")
	controls(1);await frames(35)
	check(lesson.right.global_transform==inactive_pose,"inactive horse does not secretly execute during single riding")
	check(chapter.model.snapshot()==paused_home and chapter.avatar.global_transform==player_pose and chapter.horse.global_transform==horse_pose,"Home tick and physical bodies remain frozen during actual training input")
	check(chapter.art.get_instance_id()==art_id and chapter.art.enabled==art_enabled and chapter.art.detail.child_root.get_instance_id()==detail_id,"live Home art survives suspension without exit/rebuild")
	check(chapter.workplace.carried.get_instance_id()==carried_id and material_node.material_override==material,"workshop attachments and material identities remain intact")
	check(not session.finish(true).is_empty(),"completed boolean alone cannot forge an unfinished lesson")
	check(chapter.model.snapshot()==paused_home,"premature completion grants no capability")
	var canceled_return: Dictionary={}
	session.tree_exiting.connect(func():
		canceled_return.snapshot=chapter.model.snapshot();canceled_return.process_mode=home.process_mode)
	controls();key(lesson,KEY_F1);await frames(3)
	check(canceled_return.get("snapshot")==paused_home,"F1 cancellation returns the exact unmodified Home authority")
	check(home.is_inside_tree() and canceled_return.get("process_mode",Node.PROCESS_MODE_DISABLED)!=Node.PROCESS_MODE_DISABLED,"cancellation resumes retained Home")
	check(not root.disable_3d,"cancellation restores the Home viewport render flag")
	check(chapter.art.detail.child_root.get_instance_id()==detail_id and chapter.workplace.carried.get_instance_id()==carried_id,"cancellation retains external art and carried attachment")
	await frames(4)
	install_seed()
	var before_lesson: Dictionary=chapter.model.snapshot()
	ok(chapter.open_riding_training(),"training can retry after cancel without grants")
	session=chapter.training_session;lesson=session.lesson;await frames(6)
	await _complete_lesson()
	var receipt: Dictionary=lesson.completion_receipt()
	check(not receipt.is_empty() and receipt.subject_id=="ranjit_singh" and receipt.flashback_actor_id=="mahan_singh","complete receipt separates learner and flashback actor identities")
	check(receipt.milestones.map(func(item): return item.id)==Skills.SKILL_IDS,"completion proves three ordered skill milestones")
	check(receipt.facts.volley_slots==[0,1,2,3] and receipt.facts.reloaded_slots.size()==4,"proof names all four discharge and recharge slots")
	check(chapter.model.capabilities()=={"single_standing":false,"paired_standing":false,"mounted_matchlock":false},"complete flashback remains unadmitted before guarded return")
	var completed_return: Dictionary={}
	session.tree_exiting.connect(func(): completed_return.snapshot=chapter.model.snapshot())
	controls();key(lesson,KEY_ENTER);await frames(3)
	if DisplayServer.get_name()!="headless": check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and chapter.avatar.input_enabled,"disposed hosted lesson preserves playable Home mouse capture")
	check(chapter.model.capabilities()=={"single_standing":true,"paired_standing":true,"mounted_matchlock":true},"guarded return unlocks all three capabilities on existing Home authority")
	check(not root.disable_3d,"completed return restores visible Home rendering")
	var admitted_at_return: Dictionary=completed_return.get("snapshot",{})
	var admitted: Dictionary=chapter.model.snapshot()
	var base_admitted: Dictionary=admitted_at_return.duplicate(true);base_admitted.erase("riding_skills")
	var base_before: Dictionary=before_lesson.duplicate(true);base_before.erase("riding_skills")
	check(base_admitted==base_before,"successful return changes only the riding skill extension")
	check(admitted.riding_skills.lesson_receipts.size()==1,"one accepted lesson creates one skill receipt")
	ok(chapter.model.accept_riding_training(receipt,receipt.present_sha256),"exact receipt admission is idempotent")
	check(chapter.model.snapshot()==admitted,"receipt replay creates no additional grant")
	var altered: Dictionary=receipt.duplicate(true);altered.completion_sha256="0".repeat(64)
	check(not chapter.model.accept_riding_training(altered,receipt.present_sha256).is_empty(),"changed duplicate receipt is refused")
	check(chapter.model.snapshot()==admitted,"changed replay leaves admitted state intact")
	var fixed:=Fixed.new()
	check(not fixed.restore(receipt,chapter.model.validate).is_empty() and not fixed.allows_lahore_transition(),"skill receipt cannot satisfy the later fixed father interlude")
	home.process_mode=Node.PROCESS_MODE_DISABLED
	ok(chapter.model.save_to(SAVE),"advanced skills save using isolated Home slot")
	var restored:=Skills.new();ok(restored.load_from(SAVE),"extended skill save restores")
	check(same_json(restored.snapshot(),admitted) and restored.capabilities()==chapter.model.capabilities(),"save/load preserves whole Home and three capabilities")
	chapter._load(SAVE)
	check(same_json(chapter.model.snapshot(),admitted),"visible Home loader accepts the extended authority")
	check(chapter.art.get_instance_id()==art_id and chapter.art.detail.child_root.get_instance_id()==detail_id,"load does not destroy retained Home art")
	home.process_mode=Node.PROCESS_MODE_INHERIT;await frames(3)
	var before_slate: Dictionary=chapter.model.snapshot()
	key(chapter,KEY_T);await frames(5)
	check(chapter._paused and chapter._panel.visible and chapter._panel_text.text.begins_with("YOUTH STORIES · DEVELOPMENT SLATE"),"inherited T still opens the story development slate after skills are learned")
	check(chapter.model.snapshot()==before_slate,"story development slate remains read-only and freezes the Home clock")
	chapter._actions.get_child(0).pressed.emit()
	check(not chapter._paused and chapter.model.snapshot()==before_slate,"existing Return button resumes the slate without changing authority")
	await frames(3)
	await _practice("single")
	await _practice("pair")
	key(chapter,KEY_F);await frames(3)
	check(chapter.model.mounted(),"learner remounts existing household horse after return")
	for _i in range(30):
		if chapter._horse_support().safe: break
		await frames(1)
	check(chapter._horse_support().safe,"existing mounted horse settles before standing input")
	key(chapter,KEY_X);await frames(50)
	check(chapter.model.mounted() and chapter.single_stance()=="standing","persisted capability executes real single-horse standing in Home")
	controls(1);Input.action_press("sprint")
	var saw_recovery:=false
	var unsafe_speed:=0.0
	for _i in range(120):
		await frames(1)
		if chapter.single_stance()=="recovering":
			saw_recovery=true;unsafe_speed=chapter.horse.speed;break
	check(saw_recovery and chapter._single_stance.snapshot().brake_required,"actual canter speed loses standing support and requests recovery braking")
	await frames(5)
	check(chapter.horse.speed<unsafe_speed,"Home recovery slows the sole existing horse motor despite held canter input")
	controls(0,true);await frames(50)
	check(chapter.single_stance()=="seated" and chapter.horse.speed<=.15,"Home recovery returns to a stopped seated stance")
	controls();current_scene=null;home.queue_free();home=null;chapter=null;session=null;lesson=null;await frames(4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("RIDING_TRAINING_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)

func _practice(formation: String) -> void:
	var before: Dictionary=chapter.model.snapshot()
	ok(chapter.open_riding_training(formation),"learned "+formation+" practice opens without replaying instruction")
	session=chapter.training_session;lesson=session.lesson;await frames(6)
	check(lesson.practice_mode==formation and lesson.lesson_phase==formation,"practice immediately selects the learned formation")
	check(lesson.hud.text.contains("Left click fire") and lesson.hud.text.contains("R reload") and lesson.hud.text.contains("Enter return"),"learned practice retains its complete available controls")
	controls(1);await frames(35);key(lesson,KEY_SPACE);await frames(State.RISE_TICKS+5)
	check(lesson.model.stance()=="standing" and lesson.observation().safe,"learned "+formation+" practice supports actual standing input")
	click(lesson)
	check(lesson.model.snapshot().shots.size()==1,"mounted matchlock skill fires during learned "+formation+" practice")
	controls(0,true);await frames(45);key(lesson,KEY_R);await frames(State.RELOAD_TICKS+1)
	check(lesson.model.snapshot().slots[0],"learned practice restores a discharged mounted weapon")
	check(lesson.training_proof().is_empty() and lesson.completion_receipt().is_empty(),"free practice creates no replacement training proof")
	var returned: Dictionary={}
	session.tree_exiting.connect(func(): returned.snapshot=chapter.model.snapshot())
	controls();key(lesson,KEY_ENTER);await frames(3)
	check(returned.get("snapshot")==before,"leaving learned practice preserves all Home authority and the original receipt")
	check(chapter.model.snapshot().riding_skills.lesson_receipts.size()==1,"learned practice adds no duplicate skill receipt")

func _complete_lesson() -> void:
	controls(1);await frames(35);key(lesson,KEY_SPACE);await frames(State.RISE_TICKS+60+4)
	check(lesson.model.stance()=="standing" and lesson.single_standing_ticks>=60,"actual one-horse riding completes supported standing hold")
	check(lesson.hud.text.contains("Standing hold earned: 1.0 / 1.0 s") and lesson.hud.text.contains("Enter next exercise"),"earned single hold reveals the next exercise control")
	key(lesson,KEY_ENTER);await frames(5)
	check(lesson.lesson_phase=="pair" and lesson.right.visible and lesson.right.collision_layer==1,"Enter admits a real second horse only after single hold")
	check(lesson.hud.text.contains("TWO MOVING HORSES") and not lesson.hud.text.contains("Left click fire") and not lesson.hud.text.contains("R reload"),"paired balance presents its own exercise without locked weapon controls")
	click(lesson);check(lesson.model.snapshot().shots.is_empty(),"paired balance cannot bypass weapon phase")
	controls(1);await frames(35);key(lesson,KEY_SPACE);await frames(State.RISE_TICKS+60+4)
	check(lesson.model.stance()=="standing" and lesson.paired_standing_ticks>=60,"actual two-horse riding completes independent supported hold")
	key(lesson,KEY_ENTER);await frames(2)
	check(lesson.lesson_phase=="weapons","both holds open mounted weapon practice")
	check(lesson.hud.text.contains("Standing shots: 0 / 4") and lesson.hud.text.contains("Weapons reloaded: 0 / 4") and lesson.hud.text.contains("Left click fire") and lesson.hud.text.contains("R reload"),"weapon exercise presents admitted controls and distinct discharge/reload progress")
	for slot in range(4): key(lesson,KEY_1+slot);click(lesson)
	check(lesson.model.snapshot().slots==[false,false,false,false] and lesson.shot_observations.size()==4,"four separate mounted shots consume exactly four charges")
	check(lesson.hud.text.contains("Standing shots: 4 / 4") and lesson.status.text.contains("1 empty") and lesson.status.text.contains("4 empty"),"four spent weapons are visible as actual slot states")
	controls(0,true);await frames(45)
	for slot in range(4):
		key(lesson,KEY_1+slot);key(lesson,KEY_R)
		if slot==0:
			await frames(30)
			check(lesson.status.text.contains("Reload 1:") and lesson.status.text.contains(" / 3.0 s"),"active charge cycle presents its measured time and separate weapon identity")
			await frames(State.RELOAD_TICKS-29)
		else: await frames(State.RELOAD_TICKS+1)
		check(lesson.model.snapshot().slots[slot],"exclusive real-time charge cycle restores weapon %d"%slot)
	key(lesson,KEY_SPACE);await frames(State.RECOVER_TICKS+5)
	check(lesson.lesson_phase=="complete" and lesson.model.stance()=="seated" and lesson.observation().max_speed<=.15,"three-phase lesson finishes only seated, safe and stopped")
	check(lesson.hud.text.contains("Enter return to the riding lesson") and not lesson.hud.text.contains("Left click fire") and not lesson.hud.text.contains("R reload"),"completed lesson foregrounds its valid return without weapon controls")
