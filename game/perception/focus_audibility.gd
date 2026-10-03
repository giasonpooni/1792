# Copyright (c) 2026 Notation Systems Inc. All rights reserved.
extends RefCounted
## Read-only eligibility for authored Focus hearing cues, not measured audibility.
## Spatial reach/occlusion stay with GroundFocus. This checks native playback,
## routing mutes/solo isolation and the configured source-plus-bus gain; it does not inspect
## stream samples, bus effects, RMS, speaker output or hearing physiology.
## Godot 4.5 API references:
## https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer3d.html
## https://docs.godotengine.org/en/4.5/classes/class_audioserver.html

const SOURCE_FLOOR_DB := -60.0 # Retains the original GroundFocus source gate.
const EFFECTIVE_FLOOR_DB := -60.0 # Authored cue eligibility, not a measured SPL.

static func _route_to_master(start: int, master: int, count: int) -> Array[int]:
	var route: Array[int] = []
	var visited: Dictionary = {}
	var bus := start
	for _step in range(count):
		if bus < 0 or bus >= count or visited.has(bus):
			return []
		visited[bus] = true
		route.append(bus)
		if bus == master:
			return route
		# This observer keeps malformed configured sends ineligible instead of
		# repairing the mixer or inferring the engine's fallback output.
		bus = AudioServer.get_bus_index(AudioServer.get_bus_send(bus))
	return []

static func admitted(source: AudioStreamPlayer3D) -> bool:
	if not is_instance_valid(source) or not source.playing or source.stream_paused:
		return false
	var effective_db := source.volume_db
	if not is_finite(effective_db) or effective_db <= SOURCE_FLOOR_DB:
		return false
	var master := AudioServer.get_bus_index(&"Master")
	if master < 0:
		return false
	var bus := AudioServer.get_bus_index(source.bus)
	# AudioStreamPlayer3D documents a missing source bus as a Master fallback.
	if bus < 0:
		bus = master
	var count := AudioServer.bus_count
	var source_route := _route_to_master(bus, master, count)
	if source_route.is_empty():
		return false
	var solo_mode := false
	var soloed: Dictionary = {}
	for candidate in range(count):
		if not AudioServer.is_bus_solo(candidate):
			continue
		solo_mode = true
		var solo_route := _route_to_master(candidate, master, count)
		if solo_route.is_empty():
			return false
		for member in solo_route:
			soloed[member] = true
	if solo_mode and not soloed.has(source_route[0]):
		return false
	for member in source_route:
		# Godot's mixer applies mutes only outside solo mode. A soloed bus and
		# its send ancestors remain audible even if their mute flags are set.
		if not solo_mode and AudioServer.is_bus_mute(member):
			return false
		var gain_db := AudioServer.get_bus_volume_db(member)
		if not is_finite(gain_db):
			return false
		effective_db += gain_db
		if not is_finite(effective_db):
			return false
		if member == master:
			return effective_db > EFFECTIVE_FLOOR_DB
	return false
