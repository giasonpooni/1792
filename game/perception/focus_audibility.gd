# Copyright (c) 2026 Notation Systems Inc. All rights reserved.
extends RefCounted
## Read-only eligibility for authored Focus hearing cues, not measured audibility.
## Spatial reach/occlusion stay with GroundFocus. This checks native playback,
## routing mutes and the configured source-plus-bus gain; it does not inspect
## stream samples, bus effects, RMS, speaker output or hearing physiology.
## Godot 4.5 API references:
## https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer3d.html
## https://docs.godotengine.org/en/4.5/classes/class_audioserver.html

const SOURCE_FLOOR_DB := -60.0 # Retains the original GroundFocus source gate.
const EFFECTIVE_FLOOR_DB := -60.0 # Authored cue eligibility, not a measured SPL.

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
	var visited: Dictionary = {}
	var count := AudioServer.bus_count
	for _step in range(count):
		if bus < 0 or bus >= count or visited.has(bus):
			return false
		visited[bus] = true
		if AudioServer.is_bus_mute(bus):
			return false
		var gain_db := AudioServer.get_bus_volume_db(bus)
		if not is_finite(gain_db):
			return false
		effective_db += gain_db
		if not is_finite(effective_db):
			return false
		if bus == master:
			return effective_db > EFFECTIVE_FLOOR_DB
		# Malformed send names/cycles decline safely. This observer never repairs
		# the mixer or claims that its authored gate models DSP fallback behavior.
		bus = AudioServer.get_bus_index(AudioServer.get_bus_send(bus))
	return false
