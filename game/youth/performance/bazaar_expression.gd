# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Authored facial blocking, not inferred emotion, phonemes, historical fact or game state.
## Values are geometric controls in metres/radians; they never feed the encounter reducer.
const POSES := {
	"neutral": [0.0,0.0,0.0,0.0,0.0,0.0,0.0],
	"amused": [.004,.003,-.05,.04,.005,.003,.10],
	"wry": [.006,0.0,-.12,.02,.001,.006,.08],
	"resolute": [-.002,-.002,-.08,.08,-.001,-.001,.16],
	"concerned": [.003,.003,-.18,.18,-.003,-.003,.04],
	"challenging": [-.004,-.003,.17,-.13,-.002,.001,.28],
	"relieved": [.001,.001,-.02,.02,.003,.002,.05],
	"chastened": [0.0,0.0,-.13,.13,-.003,-.002,.20]
}

static func controls(name: String,weight: float=1.0) -> Dictionary:
	var p: Array=POSES.get(name,POSES.neutral)
	var w:=clampf(weight,0.0,1.0)
	return {"name":name if POSES.has(name) else "neutral", "weight":w,
		"brow_lift":Vector2(p[0],p[1])*w,"brow_roll":Vector2(p[2],p[3])*w,
		"mouth_corners":Vector2(p[4],p[5])*w,"lid_tension":float(p[6])*w}

static func choose(index: int,phase: String,outcome: String,down: bool,pose: String,speech: Dictionary) -> String:
	if phase in ["none","reported","caught"]: return "neutral"
	if down: return "chastened"
	if pose=="brace": return "concerned"
	if index<3: return "challenging" if phase in ["challenged","fighting"] else "neutral"
	if phase=="fighting": return "resolute" if index==3 else "concerned"
	if phase=="challenged": return "resolute" if index==3 else "concerned"
	var actor:=int(speech.get("actor",-1))
	# The most important homecoming turn is an admission, not another victory grin.
	var beat:=String(speech.get("performance_beat",""))
	if beat=="regroup:stood_ground:1": return "concerned" if index==4 else "chastened"
	if beat=="regroup:stood_ground:2": return "relieved"
	if phase=="returning":
		if outcome=="withdrew": return "chastened" if index==3 else "relieved"
		if outcome=="walked_away": return "concerned" if index==3 else "relieved"
		return "amused" if index==3 else "wry"
	if phase=="leaving": return "resolute" if index==3 else "relieved"
	if actor==index: return "amused" if index==3 else "wry"
	return "neutral"

static func delivery(speech: Dictionary,tick: int) -> Dictionary:
	if speech.is_empty(): return {"speaker":-1,"weight":0.0,"nod":0.0}
	var duration:=int(speech.get("duration",210))
	var ending:=int(speech.get("until",tick))
	var beginning:=int(speech.get("started",ending-duration))
	var age:=tick-beginning
	if age<0 or tick>=ending: return {"speaker":-1,"weight":0.0,"nod":0.0}
	# One held emphasis near the start, then listening stillness. No perpetual jaw flapping.
	var attack:=clampf(float(age)/10.0,0.0,1.0)
	var release:=clampf(float(ending-tick)/12.0,0.0,1.0)
	var nod:=sin(PI*clampf(float(age-12)/24.0,0.0,1.0))*.025
	return {"speaker":int(speech.get("actor",-1)),"weight":minf(attack,release),"nod":nod}
