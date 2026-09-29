# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Author-directed physical formation targets for Mela/Jiva.
## Uses the same authoritative CharacterBodies and movement recorder; no teleporting or new AI state.
const Brawl:=preload("res://youth/brawl_rules.gd")
const Supply:=preload("res://territory/misl_rules.gd")

static func phase_goal(phase: String,hero: Vector3) -> Vector3:
	match phase:
		"invited","challenged": return Brawl.RING
		"fighting","leaving": return Brawl.REGROUP
		"returning": return Supply.QUARTERMASTER
	return hero+Vector3(0,0,-1)

static func target(hero: Vector3,phase: String,index: int) -> Vector3:
	if index not in [3,4]: return hero
	var toward:=phase_goal(phase,hero)-hero;toward.y=0
	if toward.length()<.05: toward=Vector3(0,0,-1)
	else: toward=toward.normalized()
	var right:=Vector3(-toward.z,0,toward.x)
	var side: float=-.92 if index==3 else .92
	var lead:=0.0
	match phase:
		"invited":
			lead=.48 if index==3 else -.28 # Mela leans into the outing; Jiva follows deliberately.
		"challenged":
			lead=.12 if index==3 else -.12
		"fighting":
			lead=-.18 if index==3 else -.52 # Neither becomes a combatant; Jiva hangs further back.
		"leaving":
			lead=-.30 if index==3 else .68 # Jiva naturally finds the way out.
		"returning":
			lead=.05 if index==3 else .34
		_: lead=0
	return hero+toward*lead+right*side

static func descriptor(phase: String,index: int) -> String:
	if index==3:
		return {"invited":"eager_left","challenged":"close_left","fighting":"near_left","leaving":"following_left","returning":"settling_left"}.get(phase,"left")
	return {"invited":"measured_right","challenged":"close_right","fighting":"rear_right","leaving":"leading_right","returning":"homeward_right"}.get(phase,"right")
