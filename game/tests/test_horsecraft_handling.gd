extends SceneTree
## Native input drives the shared motor/reducer. Explicit camera and old-save
## fixtures qualify presentation contracts, not human play or historical likeness.
const Study:=preload("res://mounts/horsecraft_study.tscn")
const Launch:=preload("res://childhood/home_launch.gd")
const TrainingFixture:=preload("res://tests/test_riding_training.gd")
const Skills:=preload("res://mounts/riding_skill_state.gd")
const State:=preload("res://mounts/horsecraft_state.gd")
const OnFootCostume:=preload("res://assets/courtyard/childhood_costume.glb")
const SAVE:="user://horsecraft-handling-native-only.json"
var passed:=0
var failed:=0
var scene: Node3D
var home: Node3D
var chapter: Node3D
var session: Node

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool,message: String) -> void:
	if value: passed+=1
	else:
		failed+=1;push_error("HORSECRAFT HANDLING: "+message)

func frames(count: int=3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func controls(forward: float=0.0,brake: bool=false) -> void:
	for action in ["move_forward","move_backward","move_left","move_right","sprint"]: Input.action_release(action)
	if forward>0: Input.action_press("move_forward",forward)
	if brake: Input.action_press("move_backward")

func key(target: Node,code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	if target==scene and is_instance_valid(session): session._input(event)
	else: target._unhandled_input(event)

func click() -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	if is_instance_valid(session): session._input(event)
	else: scene._unhandled_input(event)

func near(left: Vector3,right: Vector3) -> bool:
	return left.distance_to(right)<1.0e-5

func no_collision(node: Node) -> bool:
	return node.find_children("*","CollisionObject3D",true,false).is_empty() and node.find_children("*","CollisionShape3D",true,false).is_empty()

func points_equal(left: Array,right: Array) -> bool:
	if left.size()!=right.size(): return false
	for i in range(left.size()):
		if not near(left[i],right[i]): return false
	return true

func _run() -> void:
	controls();scene=Study.instantiate();root.add_child(scene);await frames(6)
	check(scene.rider.get_script().resource_path=="res://mounts/horsecraft_rider_visual.gd","study instantiates the actual shared handling rig")
	var study_palette: Dictionary=scene.rider.palette_observation()
	check(study_palette.profile=="horsecraft-study" and study_palette.colors.tunic=="748495" and study_palette.colors.headwrap=="526c87","isolated study retains its existing blue authored palette")
	check(no_collision(scene.rider) and no_collision(scene.left._visual) and no_collision(scene.right._visual),"shared horse and rider presentation contributes no collision object or shape")
	for horse in [scene.left,scene.right]:
		check(not horse.is_physics_processing() and not horse._visual.is_physics_processing(),"owning scene remains the sole horse motor executor")
		check(is_equal_approx(horse.get_node("Hull").shape.radius,.8) and is_equal_approx(horse.get_node("Hull").shape.height,3.2),"new silhouette retains the original conservative horse/rider hull")
	controls(1);await frames(35);key(scene,KEY_SPACE);await frames(State.RISE_TICKS+State.STAND_OBJECTIVE_TICKS+5)
	check(scene.model.stance()=="standing" and scene.observation().safe,"native input establishes supported standing before handling checks")
	_check_contacts("paired study",2)
	var weapon_ids: Array=[]
	for node in scene.rider.weapons: weapon_ids.append(node.get_instance_id())
	# An explicit inspection aiming fixture must survive same-frame input without
	# the presentation adapter secretly replacing it with a gameplay camera.
	scene.camera.global_position+=Vector3(1.7,.25,2.3)
	scene.camera.rotation.y+=.09
	var camera_fixture: Transform3D=scene.camera.global_transform
	var marker_colors: Dictionary={}
	for slot in range(4):
		key(scene,KEY_1+slot)
		_check_weapons(slot,weapon_ids)
		check(scene.camera.global_transform==camera_fixture,"same-frame slot %d selection retains the explicit camera fixture"%slot)
		var muzzle: Vector3=scene.rider.active_muzzle_world()
		var marker: Marker3D=scene.rider.weapons[slot].get_node("EstablishedMuzzleEndpoint")
		check(near(muzzle,marker.global_position),"slot %d ray origin matches the selected physical visual muzzle endpoint"%slot)
		marker_colors[slot]=scene.rider.weapon_observation()[slot].charge_marker_color
		click()
		check(scene.shot_observations.size()==slot+1,"input click records one accepted shot for selected slot %d"%slot)
		if scene.shot_observations.size()>slot:
			var shot: Dictionary=scene.shot_observations[slot]
			check(shot.slot==slot and near(Vector3(shot.origin[0],shot.origin[1],shot.origin[2]),muzzle),"slot %d collision probe uses that same-frame selected muzzle"%slot)
		check(scene.camera.global_transform==camera_fixture,"firing slot %d retains the explicit camera fixture"%slot)
		_check_weapons(slot,weapon_ids)
		check(scene.rider.weapon_observation()[slot].charge_marker_color!=marker_colors[slot],"spent slot %d visibly changes its own charge cue"%slot)
	check(scene.model.snapshot().slots==[false,false,false,false],"four selected weapons spend four independent authoritative charges")
	var model_before: Dictionary=scene.model.snapshot()
	var body_before: Array[Transform3D]=[scene.left.global_transform,scene.right.global_transform]
	var velocities: Array[Vector3]=[scene.left.velocity,scene.right.velocity]
	var sampled: Dictionary=scene.rider.pose_observation()
	for _i in range(20): scene._present(false)
	check(scene.model.snapshot()==model_before,"repeated view projection cannot advance clock, stance, charges or reload")
	check(scene.left.global_transform==body_before[0] and scene.right.global_transform==body_before[1] and scene.left.velocity==velocities[0] and scene.right.velocity==velocities[1],"repeated view projection cannot move either independent horse")
	check(scene.rider.pose_observation()==sampled and scene.camera.global_transform==camera_fixture,"repeated same-tick view sampling is stable and preserves the camera fixture")
	controls(0,true);await frames(45);key(scene,KEY_1);key(scene,KEY_R)
	var reload_start: Dictionary=scene.rider.pose_observation()
	check(reload_start.reload_active and reload_start.reload_slot==0 and reload_start.reload_ticks==0,"R immediately projects the selected accepted reload into the visible rig")
	await frames(30)
	var progressing: Dictionary=scene.rider.pose_observation()
	check(progressing.reload_ticks>0 and progressing.reload_progress>reload_start.reload_progress,"native reload ticks advance the sampled handling gesture")
	check(not near(progressing.grip_world[1],reload_start.grip_world[1]),"reload progress moves the visible working hand")
	controls(1);await frames(55)
	check(scene.model.snapshot().reload_paused,"real faster gait suspends the weapon charge cycle")
	var frozen_ticks: int=scene.model.snapshot().reload_ticks
	var frozen_progress: float=scene.rider.pose_observation().reload_progress
	await frames(12)
	check(scene.model.snapshot().reload_ticks==frozen_ticks and scene.rider.pose_observation().reload_progress==frozen_progress,"speed-suspended reload cue cannot invent handling progress")
	key(scene,KEY_ESCAPE)
	var paused_pose: Dictionary=scene.rider.pose_observation()
	var paused_reins: Dictionary=scene.rider.rein_observation()
	var hand_transforms: Array[Transform3D]=[scene.rider.hands[0].global_transform,scene.rider.hands[1].global_transform]
	var weapon_transform: Transform3D=scene.weapon.global_transform
	var paused_model: Dictionary=scene.model.snapshot()
	controls(1);await frames(25)
	for _i in range(10): scene._present(false)
	check(scene.rider.pose_observation()==paused_pose and scene.rider.rein_observation()==paused_reins,"pause freezes sampled reload, recoil, foot and rein observations")
	check(scene.rider.hands[0].global_transform==hand_transforms[0] and scene.rider.hands[1].global_transform==hand_transforms[1] and scene.weapon.global_transform==weapon_transform,"pause freezes the actual handling nodes without an autonomous animation clock")
	check(scene.model.snapshot()==paused_model,"paused presentation leaves native authoritative progression unchanged")
	controls(0,true);key(scene,KEY_ESCAPE);await frames(State.RELOAD_TICKS+50)
	check(scene.model.snapshot().slots==[true,false,false,false],"resumed exclusive reload restores only selected weapon zero")
	_check_weapons(0,weapon_ids)
	check(scene.rider.weapon_observation()[0].charge_marker_color==marker_colors[0],"successful reload restores that weapon's visible charge cue")
	controls();scene.queue_free();scene=null;await frames(4)
	await _home_lesson()
	print("HORSECRAFT_HANDLING_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)

func _check_weapons(selected: int,identities: Array) -> void:
	var pose: Dictionary=scene.rider.pose_observation()
	var records: Array=scene.rider.weapon_observation()
	var snapshot: Dictionary=scene.model.snapshot()
	check(pose.selected_slot==selected and pose.weapon_identity=="horsecraft-study-slot-%d"%(selected+1),"selected identity follows the admitted slot within the same frame")
	check(pose.charges==snapshot.slots,"pose charge correspondence matches the original reducer")
	var stored: Array=[]
	var selected_count:=0
	for slot in range(4):
		var node: Node3D=scene.rider.weapons[slot]
		var record: Dictionary=records[slot]
		check(node.get_instance_id()==identities[slot] and record.instance_id==identities[slot],"weapon %d retains a distinct physical visual identity across selection and firing"%slot)
		check(record.charged==snapshot.slots[slot] and record.visible==node.is_visible_in_tree(),"weapon %d charge and visibility observations agree with live state and actual visual"%slot)
		if slot==selected:
			selected_count+=1
			check(node.get_parent()==scene.weapon and record.role=="selected" and record.parent_instance_id==scene.weapon.get_instance_id(),"selected weapon is the actual active mount child")
		else:
			stored.append(record.weapon_identity)
			check(node.get_parent()==scene.rider.storage and record.role=="stored","each unselected weapon remains a separate stored visual")
	check(selected_count==1 and stored==pose.stored_weapon_identities,"one indexed active weapon and three indexed stored identities remain coherent")

func _check_contacts(label: String,horse_count: int) -> void:
	var pose: Dictionary=scene.rider.pose_observation()
	var reins: Dictionary=scene.rider.rein_observation()
	var supports: Array=scene.rider_support_points()
	check(pose.standing_blend==1.0 and points_equal(pose.foot_world,supports),label+" visible feet contact actual supplied saddle support points")
	check(points_equal(scene.rider.visible_foot_points(),supports),label+" real foot anchors agree with the observed supported pose")
	var bridles: Array=[]
	for horse in scene.active_riding_horses(): bridles.append_array(horse.bridle_points_world())
	check(reins.horse_count==horse_count and points_equal(reins.anchors,bridles),label+" reins begin at each active horse's actual bridle")
	check(reins.source=="supplied-observed-bridle-anchors" and not reins.owns_steering,label+" reins project observations without a steering authority")
	if horse_count==1:
		check(near(supports[0],scene.left.saddle_support_point()-scene.left.global_basis.x*.22) and near(supports[1],scene.left.saddle_support_point()+scene.left.global_basis.x*.22),label+" both support contacts belong to the sole active saddle")
	else:
		check(near(supports[0],scene.left.saddle_support_point()+scene.left.global_basis.x*.22) and near(supports[1],scene.right.saddle_support_point()-scene.right.global_basis.x*.22),label+" left and right foot contacts belong to distinct inward saddle edges")
		check(scene.left.get_rid()!=scene.right.get_rid() and supports[0].distance_to(supports[1])>1.0,label+" independent pair geometry is retained")

func _home_lesson() -> void:
	# Reuse the admitted old-save fixture. No advanced capability or completion
	# proof is seeded: the bound native lesson earns and returns all three skills.
	home=Launch.make_world();root.add_child(home);current_scene=home
	chapter=home.get_node("ChildhoodChapter");chapter.save_path=SAVE;await frames(6)
	var seed: Dictionary=TrainingFixture.legacy_riding_seed()
	check(chapter.model.restore(seed).is_empty(),"explicit old-save riding fixture restores without learned skill receipt")
	chapter._apply()
	# Applying an old pose clears native floor contact; let the unchanged avatar
	# motor establish it instead of claiming that the admitted coordinates do so.
	await frames(6)
	var toward: Vector3=Skills.TRAINING_SITE-chapter.avatar.global_position
	chapter.avatar.pivot.rotation.y=atan2(-toward.x,-toward.z);chapter.avatar.pivot.rotation.x=0.0
	var entry_error: String=chapter.open_riding_training()
	check(entry_error.is_empty(),"real Home trainer opens a bound lesson: "+entry_error)
	if not entry_error.is_empty():
		current_scene=null;home.queue_free();home=null;chapter=null;await frames(4)
		return
	session=chapter.training_session;scene=session.lesson;await frames(6)
	check(scene.rider.palette_observation().profile=="horsecraft-study","attributed Maha training retains its own study palette")
	var inactive_transform: Transform3D=scene.right.global_transform
	controls(1);await frames(35);key(scene,KEY_SPACE);await frames(State.RISE_TICKS+60+5)
	check(scene.lesson_phase=="single" and scene.single_standing_ticks>=60,"native one-horse riding earns the first standing hold")
	_check_contacts("single lesson",1)
	check(scene.right.global_transform==inactive_transform and not scene.right.visible and scene.right.collision_layer==0,"single lesson neither moves, renders nor collides a fictitious second horse")
	key(scene,KEY_ENTER);await frames(5)
	controls(1);await frames(35);key(scene,KEY_SPACE);await frames(State.RISE_TICKS+60+5)
	check(scene.lesson_phase=="pair" and scene.paired_standing_ticks>=60,"native paired riding earns the second supported hold")
	_check_contacts("paired lesson",2)
	key(scene,KEY_ENTER);await frames(2)
	for slot in range(4): key(scene,KEY_1+slot);click()
	controls(0,true);await frames(45)
	for slot in range(4):
		key(scene,KEY_1+slot);key(scene,KEY_R);await frames(State.RELOAD_TICKS+1)
	key(scene,KEY_SPACE);await frames(State.RECOVER_TICKS+5)
	check(not scene.completion_receipt().is_empty(),"actual three-phase lesson produces the only learned receipt used by Home handling fixture")
	controls();key(scene,KEY_ENTER);await frames(4);scene=null;session=null
	check(chapter.model.has_riding_skill("single_standing"),"guarded native return admits the earned standing capability")
	key(chapter,KEY_F);await frames(4)
	for _i in range(30):
		if chapter._horse_support().safe: break
		await frames(1)
	key(chapter,KEY_X);await frames(State.RISE_TICKS+5)
	check(chapter.model.mounted() and chapter.single_stance()=="standing","earned Home standing executes through the existing mount and stance controls")
	var rig: Node3D=chapter._riding_visual
	check(chapter.horse._rider.get_child_count()==7 and not chapter.horse._rider.visible,"Home preserves all seven legacy rider anchors while displaying the shared rig")
	check(rig.visible and rig.get_script().resource_path=="res://mounts/horsecraft_rider_visual.gd","mounted Home uses the actual shared handling rig")
	var home_palette: Dictionary=rig.palette_observation()
	var onfoot_palette:=_onfoot_palette()
	check(home_palette.profile=="childhood-home" and not home_palette.historical_authentication,"Home explicitly selects authored costume continuity without a likeness claim")
	check(not home_palette.visible_facial_hair and not rig.face_parts[1].is_visible_in_tree(),"Home child identity retains the existing clean lower-face costume presentation")
	for colors in [["tunic","child_cotton"],["headwrap","child_cotton"],["trousers","child_trousers"],["sash","child_sash"],["skin","child_skin"],["eyes","child_eyes"],["leather","child_leather"]]:
		check(home_palette.colors[colors[0]]==onfoot_palette[colors[1]],"mounted "+colors[0]+" pigment matches the existing on-foot costume asset")
	check(rig.body.material_override.get_instance_id()==home_palette.material_ids.tunic and rig.sash.material_override.get_instance_id()==home_palette.material_ids.sash and rig.turban.material_override.get_instance_id()==home_palette.material_ids.headwrap,"palette observations identify the actual visible torso, sash and headwrap materials")
	check(not rig.equipped and not rig.weapon_mount.visible and not rig.storage.visible,"ordinary Home horse riding displays no borrowed practice weapon")
	var all_unequipped:=true
	for record in rig.weapon_observation():
		if record.role!="unequipped" or record.visible: all_unequipped=false
	check(all_unequipped,"all four actual weapon visuals are unequipped and invisible in Home")
	var expected: Array=[chapter.horse.saddle_support_point()-chapter.horse.global_basis.x*.22,chapter.horse.saddle_support_point()+chapter.horse.global_basis.x*.22]
	check(points_equal(rig.visible_foot_points(),expected),"Home standing feet project the sole existing household horse's real saddle")
	check(points_equal(rig.rein_observation().anchors,chapter.horse.bridle_points_world()),"unarmed Home reins attach to the existing horse's real bridle")
	check(no_collision(rig) and no_collision(chapter.horse._visual),"Home visual extension adds no new collision authority")
	var before: Dictionary=chapter.model.snapshot()
	var horse_transform: Transform3D=chapter.horse.global_transform
	for _i in range(10): chapter._sample_standing()
	check(chapter.model.snapshot()==before and chapter.horse.global_transform==horse_transform,"Home presentation sampling cannot mutate recorded world or physical horse")
	check(rig.palette_observation()==home_palette,"repeated Home presentation sampling retains all palette material identities and colors")
	controls();current_scene=null;home.queue_free();home=null;chapter=null;await frames(4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func _onfoot_palette() -> Dictionary:
	# Compare against the retained authored asset rather than copying profile literals.
	var costume: Node3D=OnFootCostume.instantiate()
	var colors: Dictionary={}
	for mesh in costume.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material: Material=mesh.mesh.surface_get_material(i)
			if material is StandardMaterial3D: colors[material.resource_name]=material.albedo_color.to_html(false)
	costume.free()
	return colors
