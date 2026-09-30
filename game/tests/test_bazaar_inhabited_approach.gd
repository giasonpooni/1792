# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Presentation fixtures only. Actual physical approach is covered by test_bazaar_direction.
const Launch:=preload("res://childhood/home_launch.gd")
const State:=preload("res://youth/brawl_state.gd")
const Fixture:=preload("res://tests/gujranwala_fixture.gd")
const Pose:=preload("res://tests/aftermath_fixture.gd")
const Supply:=preload("res://territory/misl_rules.gd")
const WalkLines:=preload("res://youth/performance/bazaar_walk_lines.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("INHABITED BAZAAR FAIL: "+label)
func ok(error: String,label: String) -> void: check(error.is_empty(),label+": "+error)
func frames(n:=4) -> void:
	for _i in range(n): await physics_frame
	await process_frame
func invited_at(point: Vector3) -> State:
	var model:=State.new();ok(model.restore(Fixture.complete()),"completed inquiry fixture")
	ok(Pose.pose(model,Supply.MARKET),"market fixture")
	ok(model.begin_brawl(),"existing invitation")
	ok(Pose.pose(model,point),"presentation position fixture")
	return model
func run() -> void:
	var home:=Launch.make_world();var scene=home.get_node("ChildhoodChapter")
	var model: State=invited_at(WalkLines.ZONES[0].center)
	ok(scene.model.restore(model.snapshot()),"restore invited approach fixture")
	root.add_child(home);await frames(8)
	var approach: Node3D=scene.bazaar_performance.inhabited_approach
	check(is_instance_valid(approach),"inhabited approach attached to shipped Home scene")
	check(approach.get_meta("classification","")=="original-prototype-ambient-vignettes","explicit authored classification")
	check(approach.find_children("*","CollisionShape3D",true,false).is_empty(),"vignettes add no collision shapes")
	check(approach.find_children("*","StaticBody3D",true,false).is_empty(),"vignettes add no static physics bodies")
	check(is_instance_valid(approach.merchant) and is_instance_valid(approach.helper) and is_instance_valid(approach.animal) and is_instance_valid(approach.cart),"three ambient vignette families exist")
	check(approach.cart_wheels.size()==4,"stationary cart has four visual wheels")
	var before: Dictionary=scene.model.snapshot()
	for tick in [0,30,120,360]:
		approach.sample(tick,"invited")
		approach.sample(tick,"fighting")
	check(scene.model.snapshot()==before,"ambient work/stillness sampling mutates no world state")
	var seen: Dictionary={}
	var goods:=WalkLines.available(WalkLines.ZONES[0].center,"invited",seen)
	check(goods.id=="goods" and goods.lines.size()==2,"goods vignette has bounded companion exchange")
	seen[goods.id]=1
	check(WalkLines.available(WalkLines.ZONES[0].center,"invited",seen).is_empty(),"session-local seen vignette does not repeat immediately")
	check(WalkLines.available(WalkLines.ZONES[1].center,"challenged",{}).is_empty(),"ambient observations stop once confrontation begins")
	check(WalkLines.available(Vector3.ZERO,"invited",{}).is_empty(),"far location emits no market observation")
	# Use actual director/contact logic at the goods zone. Friends remain the original physical actors.
	scene.avatar.global_position=WalkLines.ZONES[0].center
	ok(Pose.pose(scene.model,WalkLines.ZONES[0].center),"align authoritative player fixture")
	var positioned: Dictionary=scene.model.snapshot()
	scene.bazaar_performance.walk_seen.clear();scene.bazaar_performance.speech.clear();scene.bazaar_performance.queue.clear()
	scene.bazaar_performance.sample(true)
	check(not scene.bazaar_performance.speech.is_empty(),"director emits a nearby ambient companion line")
	check(String(scene.bazaar_performance.speech.text).begins_with("Mind the baskets"),"Jiva owns the first goods observation")
	check(scene.model.snapshot()==positioned,"ambient line trigger adds no receipt, memory or clock")
	scene.bazaar_performance.sample(true)
	check(scene.model.snapshot()==positioned,"ambient subtitle sampling remains authority-neutral")
	check(scene.model.journal().filter(func(m): return String(m.id).contains("goods") or String(m.id).contains("animal") or String(m.id).contains("cart")).is_empty(),"ambient observations never enter journal")
	home.queue_free();await frames(3)
	print("BAZAAR_INHABITED_APPROACH_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
