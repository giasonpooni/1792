# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Read-only foregrounding of an accepted household responsibility. Background
## work never interrupts a carried load or invents a remotely received report.
const Base := preload("res://childhood/childhood_state.gd")
const Supply := preload("res://territory/misl_rules.gd")
const Water := preload("res://territory/water_round_rules.gd")

static func read(chapter: Node3D, moving: bool = false) -> Dictionary:
	var model = chapter.model
	if model.aftermath_phase() != "complete" or not model.has_method("has_economy") or not model.has_economy(): return {}
	if model.has_method("brawl_busy") and model.brawl_busy(): return {}
	if model.has_method("remount_busy") and model.remount_busy(): return {}
	var ledger: Dictionary = model.economy().ledger
	var water: Dictionary = model.water_round().ledger if model.has_method("has_water_round") and model.has_water_round() else {}
	var mode := "mounted" if model.mounted() else "moving" if moving else "rest"
	var result := {"kind":"", "title":"GUJRANWALA  /  HOUSEHOLD RESPONSIBILITY", "task":"", "progress":"", "controls":"E  Speak / settle     WASD  Walk     Mouse  Look     B  Accounts     J  Journal", "target":Vector3.ZERO, "marker":"", "show_target":true, "attention_mode":mode, "show_progress":mode == "rest"}
	var foot_action := false
	# Drawing is interrupted by leaving, and filled water constrains movement.
	# Those immediate commitments precede other accepted travel. An empty vessel
	# can wait until food custody or the accompanying carrier is settled.
	if water.get("phase", "") in ["drawing", "carrying"]:
		_water_task(result, water)
		foot_action = true
	elif ledger.caravan == "active":
		result.kind = "caravan"
		var carrier := Base.point(model.economy().merchant.position)
		var home_distance := Base.distance(carrier, Supply.QUARTERMASTER)
		var gap := Base.distance(model.position(), carrier)
		result.title = "GUJRANWALA  /  BRING THE CARRIER HOME"
		if home_distance <= 4.5:
			result.task = "Check the arrived carrier in"
			result.progress = "The carrier has reached Home. Settle the food and fodder with the quartermaster."
			result.target = Supply.QUARTERMASTER; result.marker = "Quartermaster · E"
			foot_action = true
		elif gap > 9.0:
			result.task = "Return to the carrier"
			result.progress = "He waits when you move more than nine metres away. Rejoin him to continue."
			result.target = carrier; result.marker = "Waiting carrier"
		else:
			result.task = "Stay beside the carrier on the way Home"
			result.progress = "Keep him within nine metres. Reaching the gate alone does not finish the journey."
			result.target = carrier; result.marker = "Return carrier"
	elif ledger.delivery == "outbound":
		result.kind = "delivery"
		result.title = "GUJRANWALA  /  FOUR PORTIONS"
		result.task = "Bring the four portions to the trader"
		result.progress = "Four portions are in your care. Speak to the market trader for the handover."
		result.target = Supply.MARKET; result.marker = "Market trader · E"; foot_action = true
	elif water.get("phase", "") == "ready":
		# An assigned but empty water vessel is not custody; workshop cargo still
		# needs to be settled before the next draw can begin.
		if water.phase == "ready" and model.has_method("carrying_workshop") and model.carrying_workshop(): return {}
		_water_task(result, water)
		foot_action = true
	elif model.has_method("service_reserved") and model.service_reserved():
		result.kind = "service"
		result.title = "GUJRANWALA  /  A GUARD IN YOUR SERVICE"
		result.task = "Ask at Home for the guard's account"
		result.progress = "One guard is committed. You can continue other household work and hear his account after he returns."
		result.target = Supply.QUARTERMASTER; result.marker = "Quartermaster · E"; foot_action = true
		# This deliberately does not expose onsite/returning/awaiting_account as
		# remotely known facts. Hearing the report remains a local player action.
	else:
		return {}
	if model.mounted():
		result.controls = "W  Forward     A / D  Steer     S / Space  Brake     F  Dismount when stopped"
		if foot_action:
			result.task = "Stop and dismount for the handover" if result.kind in ["delivery", "caravan"] else "Stop and dismount to continue"
			result.marker = result.marker.replace(" · E", " · dismount first")
	return result

static func _water_task(result: Dictionary, water: Dictionary) -> void:
	result.kind = "water"
	result.title = "GUJRANWALA  /  WATER FOR THE HOUSEHOLD"
	if water.phase == "carrying":
		result.task = "Carry the open vessel Home"
		result.progress = "Walk to the quartermaster and deposit this load. The open vessel must stay on foot."
		result.target = Water.STORE; result.marker = "Household water · E"
	elif water.phase == "drawing":
		result.task = "Stay beside the well while the bucket rises"
		result.progress = "Leaving cancels this draw. Speak at the well if you want to cancel it yourself."
		result.target = Water.WELL; result.marker = "Raising the bucket"
	else:
		result.task = "Return to the well for the second load" if water.stored > 0 else "Take the empty vessel to the well"
		result.progress = "One load delivered; one remains." if water.stored > 0 else "Two loads will fill the household vessel. Begin the first draw at the well."
		result.target = Water.WELL; result.marker = "Well · E"
