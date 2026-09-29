# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const Blocking:=preload("res://youth/performance/bazaar_companion_blocking.gd")
const Brawl:=preload("res://youth/brawl_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")
var passed:=0
var failed:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	if value: passed+=1
	else: failed+=1;push_error("COMPANION BLOCKING FAIL: "+label)
func projection(hero: Vector3,goal: Vector3,target: Vector3) -> Dictionary:
	var forward:=goal-hero;forward.y=0;forward=forward.normalized()
	var right:=Vector3(-forward.z,0,forward.x)
	var delta:=target-hero
	return {"lead":delta.dot(forward),"side":delta.dot(right),"distance":delta.length()}
func run() -> void:
	var hero:=Vector3(-20,.14,-12)
	check(Blocking.phase_goal("invited",hero).is_equal_approx(Brawl.RING),"invited uses existing confrontation destination")
	check(Blocking.phase_goal("leaving",hero).is_equal_approx(Brawl.REGROUP),"leaving uses existing regroup destination")
	check(Blocking.phase_goal("returning",hero).is_equal_approx(Supply.QUARTERMASTER),"returning uses existing home destination")
	for phase in ["invited","challenged","fighting","leaving","returning"]:
		var goal:=Blocking.phase_goal(phase,hero)
		var mela:=projection(hero,goal,Blocking.target(hero,phase,3))
		var jiva:=projection(hero,goal,Blocking.target(hero,phase,4))
		check(mela.side<-.85 and jiva.side>.85,"friends occupy opposite authored sides in "+phase)
		check(mela.distance<1.2 and jiva.distance<1.2,"formation remains physically compact in "+phase)
	check(projection(hero,Brawl.RING,Blocking.target(hero,"invited",3)).lead>projection(hero,Brawl.RING,Blocking.target(hero,"invited",4)).lead,"Mela leads Jiva on outward walk")
	check(projection(hero,Brawl.REGROUP,Blocking.target(hero,"leaving",4)).lead>projection(hero,Brawl.REGROUP,Blocking.target(hero,"leaving",3)).lead,"Jiva leads Mela on withdrawal")
	check(Blocking.descriptor("invited",3)=="eager_left" and Blocking.descriptor("invited",4)=="measured_right","outward blocking roles remain explicit")
	check(Blocking.descriptor("leaving",4)=="leading_right","withdrawal blocking gives Jiva the lead")
	check(Blocking.target(hero,"none",0)==hero,"non-companion has no formation override")
	print("BAZAAR_COMPANION_BLOCKING_TESTS: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
