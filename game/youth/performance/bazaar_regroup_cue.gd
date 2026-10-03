# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## A present-tense companion gesture, derived from the unchanged regroup requirement.
## No movement, receipts, memory, camera direction or timer of its own.
const Rules := preload("res://youth/brawl_rules.gd")
const Base := preload("res://childhood/childhood_state.gd")

static func read(phase: String,tick: int,avatar: Vector3,positions: Array,velocities: Array,down: Array,clear: Array) -> Dictionary:
	if phase not in ["leaving","fighting"] or positions.size()!=5 or velocities.size()!=5 or clear.size()!=2 or down.size()!=3: return {}
	if Base.distance(avatar,Rules.REGROUP)>3.2: return {}
	# A raised friendly hand must never compete with an immediate attack.
	if phase=="fighting":
		for i in range(3):
			if not down[i] and Base.distance(avatar,positions[i])<6.0: return {}
	for i in [3,4]:
		var other: int=7-i
		if not clear[i-3] or Base.distance(avatar,positions[i])>4.5 or Base.distance(avatar,positions[other])<=4.5: continue
		if Base.distance(positions[i],positions[other])>7.0 or Vector2(velocities[i].x,velocities[i].z).length()>.30: continue
		# One restrained raised hand, with a small breath over the existing world clock.
		return {"actor":i,"other":other,"amount":.85+.10*sin(float(tick+i*23)/50.0)}
	return {}
