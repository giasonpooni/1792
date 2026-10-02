# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Launch:=preload("res://childhood/home_launch.gd")
const Detail:=preload("res://presentation/courtyard_detail.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Supply:=preload("res://territory/misl_rules.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else: failed+=1;push_error("COURTYARD: "+label)
func frames(n: int=3) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func physical(home: Node3D) -> Array:
	var values: Array=[]
	for n in home.find_children("*","CollisionShape3D",true,false): values.append([n.get_instance_id(),n.global_transform,n.shape.get_rid(),n.disabled,n.get_parent().collision_layer,n.get_parent().collision_mask])
	return values
func run() -> void:
	var receipt: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Detail.BUILD_PATH));var old:=receipt.duplicate(true)
	check(Detail.validate_receipt(receipt).is_empty() and receipt==old,"read-only receipt validation")
	for key in ["georeferenced","historically_verified","schema","missing","duplicate","path","hash"]:
		var bad:=receipt.duplicate(true)
		match key:
			"georeferenced","historically_verified": bad[key]=true
			"schema": bad.schema="survey"
			"missing": bad.assets.pop_back()
			"duplicate": bad.assets[1]=bad.assets[0].duplicate(true)
			"path": bad.assets[0].file="../project.godot"
			"hash": bad.assets[0].sha256="unbound"
		check(not Detail.validate_receipt(bad).is_empty(),"refuse "+key)
	var home:=Launch.make_world();var c=home.get_node("ChildhoodChapter");c.save_path="user://courtyard-isolated.json"
	check(c.model.restore(Fixture.complete()).is_empty(),"declared inquiry fixture")
	root.add_child(home);await frames(6);c.open_art_study()
	var state: Dictionary=c.model.snapshot();var bodies:=physical(home);var d=c.art.detail
	check(d.enabled and d._loaded and d._bay_count==8,"eight imported bays")
	check(d.bone_map.size()==11 and d.target_skeleton.get_bone_count()==11,"named skeleton map")
	check(not d.build(c,c.art).is_empty(),"duplicate attachment refuses")
	for b in d.bone_map:
		var t: Transform3D=d.target_skeleton.get_bone_global_pose(b.target)
		check(t.is_finite() and t.origin.length()>.35,"noncollapsed finite bone")
		check(t.origin.distance_to(d.source_skeleton.get_bone_global_pose(b.source).origin)<.0001,"source-aligned bone position")
	var pose: Transform3D=d.target_skeleton.get_bone_global_pose(6);var tick: int=d.last_tick
	d.sample(tick);check(d.target_skeleton.get_bone_global_pose(6)==pose,"same tick same pose")
	d.sample(-1);check(d.last_tick==tick,"negative tick refused")
	for _i in range(3):
		c.art.set_refinement(false);check(not d.child_root.visible and not d.visible,"earlier study restored")
		for r in d.records: check(r.node.material_override==r.old,"exact material reference restored")
		c.art.set_refinement(true);c.art.set_enabled(false);check(not d.child_root.is_visible_in_tree(),"greybox hides imported costume")
		c.art.set_enabled(true);check(physical(home)==bodies and c.model.snapshot()==state,"visual cycle preserves physical/domain state")
	check(c.get_node("CourtyardPierEnvelopes").get_child_count()==9,"nine game-owned pier bodies")
	check(c.get_node("CourtyardPierEnvelopes").find_children("*","CollisionShape3D",true,false).size()==27,"27 explicit pier shapes")
	d.set_camera(false);check(is_equal_approx(d._arm.spring_length,5.5) and is_equal_approx(d._camera.fov,75),"original camera restored")
	d.set_camera(true);check(is_equal_approx(d._arm.spring_length,3.5) and is_equal_approx(d._camera.fov,62),"close walking camera")
	await frames(20);check(c.model.snapshot()==state and d.last_tick==tick,"modal freezes common clock")
	c.avatar.pivot.rotation.y=1.1;d.sample(tick);check(is_equal_approx(c.art._hero_proxy.rotation.y,1.1),"legacy idle appearance follows look")
	c._resume();check(Pose.pose(c.model,Vector3(-8.5,.14,9.4)).is_empty(),"explicit pier approach fixture")
	c._apply();c.avatar.pivot.rotation.y=PI;Input.action_press("move_forward");await frames(95);Input.action_release("move_forward");await frames(6)
	check(c.avatar.global_position.z<10.86 and c.avatar.global_position.z>10.3,"input body blocked by pier")
	check(not c._fits(Vector3(-8.5,.14,11.35)),"pier is not clear saved ground")
	for target in [Vector3(-7.2,.14,10.35),Vector3(-7.2,.14,10.65)]:
		var reached:=false
		for _i in range(240):
			var delta: Vector3=target-c.avatar.global_position
			if Vector2(delta.x,delta.z).length()<.28: reached=true;break
			c.avatar.pivot.rotation.y=atan2(-delta.x,-delta.z);Input.action_press("move_forward");await physics_frame
		Input.action_release("move_forward");await frames(5);check(reached,"walk around pier")
	check(c.model.validate(c.model.snapshot()).is_empty(),"walking state validates")
	check(Pose.pose(c.model,Supply.QUARTERMASTER).is_empty(),"HUD fixture at quartermaster")
	check(c.model.begin_allowance().is_empty(),"HUD allowance fixture")
	c._apply();check(c.model.workshop_action("reserve").is_empty(),"HUD commission fixture");c._refresh();await frames(4)
	check(d.hud.visible and not c._hud.visible,"compact task HUD · compact=%s · layer=%s · classic=%s · phase=%s · paused=%s" % [d.hud.compact,d.hud.visible,c._hud.visible,c.model.workshop_phase(),c._paused])
	check(d.hud.words.text==c._message and d.hud.narrator.text==c._narrator_label.text,"existing speech and narration retained")
	d.hud.compact=false;d.hud.sample();check(not d.hud.visible and c._hud.visible,"classic HUD restored")
	d.hud.compact=true;c._refresh();c.open_art_study();state=c.model.snapshot()
	check(not d.hud.visible,"modal immediately suppresses compact HUD")
	check(c.model.save_to(c.save_path).is_empty(),"whole-run save")
	var saved:=FileAccess.get_file_as_string(c.save_path)
	c._menu_action("art:camera");c._menu_action("art:refinement");c._menu_action("art:evening")
	check(c.model.snapshot()==state and FileAccess.get_file_as_string(c.save_path)==saved,"presentation cannot write save")
	check(c.model.restore(JSON.parse_string(saved)).is_empty(),"whole-run load")
	c.remove_child(c.art);c.art.queue_free();await frames()
	check(not c.avatar.has_node("ChildhoodCostumeStudy"),"external costume cleaned")
	check(is_equal_approx(c.avatar.get_node("CameraPivot/SpringArm3D/Camera3D").fov,75),"camera optics restored on removal")
	home.queue_free();await frames()
	for suffix in ["",".tmp"]: DirAccess.remove_absolute("user://courtyard-isolated.json"+suffix)
	print("COURTYARD_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
