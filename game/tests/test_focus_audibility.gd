# Copyright (c) 2026 Notation Systems Inc. All rights reserved.
extends SceneTree
## Actual native playback and AudioServer routing; isolated layout is restored.
const Audibility := preload("res://perception/focus_audibility.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("FOCUS AUDIBILITY FAIL: " + label)

func frames(count: int = 3) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func looping_sound() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(2205 * 2)
	for i in range(2205):
		data.encode_s16(i * 2, int(sin(TAU * 440.0 * i / 22050.0) * 2200.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 2205
	return stream

func mixer_snapshot() -> Array:
	var result: Array = []
	for bus in range(AudioServer.bus_count):
		result.append({"name": AudioServer.get_bus_name(bus),
			"send": AudioServer.get_bus_send(bus), "mute": AudioServer.is_bus_mute(bus),
			"volume_db": AudioServer.get_bus_volume_db(bus), "solo": AudioServer.is_bus_solo(bus)})
	return result

func run() -> void:
	var saved_layout := AudioServer.generate_bus_layout()
	var original_state := mixer_snapshot()
	AudioServer.set_bus_layout(AudioBusLayout.new())
	AudioServer.bus_count = 5
	AudioServer.set_bus_name(1, "FocusParentFixture")
	AudioServer.set_bus_name(2, "FocusWorldFixture")
	AudioServer.set_bus_name(3, "FocusSourceFixture")
	AudioServer.set_bus_name(4, "FocusIsolatedFixture")
	for bus in range(5):
		AudioServer.set_bus_volume_db(bus, 0.0)
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_solo(bus, false)
	AudioServer.set_bus_send(1, &"Master")
	AudioServer.set_bus_send(2, &"FocusParentFixture")
	AudioServer.set_bus_send(3, &"FocusWorldFixture")
	AudioServer.set_bus_send(4, &"Master")
	var source := AudioStreamPlayer3D.new()
	source.stream = looping_sound()
	source.volume_db = -12.0
	source.bus = &"FocusSourceFixture"
	root.add_child(source)
	check(not Audibility.admitted(null), "null source is safely declined")
	check(not Audibility.admitted(source), "stopped native source cannot create hearing eligibility")
	source.play()
	await frames()
	check(source.playing and not source.stream_paused, "native looping source is actually playing and unpaused")
	check(Audibility.admitted(source), "unmuted source routes through two parent buses to Master")
	source.stream_paused = true
	await frames()
	check(not Audibility.admitted(source), "paused native playback is declined")
	source.stream_paused = false
	await frames()
	check(Audibility.admitted(source), "resuming native playback restores eligibility")

	source.volume_db = Audibility.SOURCE_FLOOR_DB
	check(not Audibility.admitted(source), "existing source threshold declines its exact boundary")
	source.volume_db = Audibility.SOURCE_FLOOR_DB + 0.1
	check(Audibility.admitted(source), "source just above the existing threshold remains eligible")
	source.volume_db = -70.0
	AudioServer.set_bus_volume_db(3, 30.0)
	check(not Audibility.admitted(source), "downstream gain cannot bypass the retained source floor")
	source.volume_db = -12.0
	AudioServer.set_bus_volume_db(3, 0.0)

	AudioServer.set_bus_mute(3, true)
	check(not Audibility.admitted(source), "direct source-bus mute is honored")
	AudioServer.set_bus_mute(3, false)
	AudioServer.set_bus_mute(2, true)
	check(not Audibility.admitted(source), "immediate parent-bus mute is honored")
	AudioServer.set_bus_mute(2, false)
	AudioServer.set_bus_mute(1, true)
	check(not Audibility.admitted(source), "multihop ancestor-bus mute is honored")
	AudioServer.set_bus_mute(1, false)
	AudioServer.set_bus_mute(0, true)
	check(not Audibility.admitted(source), "Master mute is honored through the complete send chain")
	AudioServer.set_bus_mute(0, false)
	check(Audibility.admitted(source), "restoring all route mutes restores eligibility")

	AudioServer.set_bus_solo(4, true)
	check(source.playing and AudioServer.is_bus_solo(4), "native source remains playing while an isolated mixer branch is soloed")
	check(not Audibility.admitted(source), "a soloed mixer branch outside the source send path isolates the playing source")
	AudioServer.set_bus_solo(4, false)
	AudioServer.set_bus_solo(2, true)
	check(not Audibility.admitted(source), "soloing a source ancestor does not admit the un-soloed child source bus")
	AudioServer.set_bus_solo(2, false)
	AudioServer.set_bus_solo(3, true)
	check(Audibility.admitted(source), "soloing the source bus admits its complete send chain")
	for bus in range(4):
		AudioServer.set_bus_mute(bus, true)
	check(Audibility.admitted(source), "native solo mode overrides mute flags on the soloed source and its send ancestors")
	for bus in range(4):
		AudioServer.set_bus_mute(bus, false)
	AudioServer.set_bus_solo(3, false)
	check(Audibility.admitted(source), "clearing native solo isolation restores ordinary routed admission")

	AudioServer.set_bus_volume_db(3, -20.0)
	AudioServer.set_bus_volume_db(2, -20.0)
	AudioServer.set_bus_volume_db(1, -10.0)
	check(not Audibility.admitted(source), "cumulative authored source and bus attenuation below threshold is declined")
	AudioServer.set_bus_volume_db(1, -8.0)
	check(not Audibility.admitted(source), "effective gain at the exact authored threshold is declined")
	AudioServer.set_bus_volume_db(1, -7.0)
	check(Audibility.admitted(source), "restored cumulative gain above threshold restores eligibility")
	for bus in range(1, 4):
		AudioServer.set_bus_volume_db(bus, 0.0)
	AudioServer.set_bus_volume_db(0, -50.0)
	check(not Audibility.admitted(source), "Master attenuation contributes to the effective authored threshold")
	AudioServer.set_bus_volume_db(0, 0.0)
	check(Audibility.admitted(source), "restoring Master gain restores eligibility")

	source.bus = &"MissingFocusSourceFixture"
	check(AudioServer.get_bus_index(&"MissingFocusSourceFixture") == -1, "missing-source-bus fixture genuinely has no mixer bus")
	check(Audibility.admitted(source), "unknown source bus follows native documented Master fallback safely")
	AudioServer.set_bus_mute(0, true)
	check(not Audibility.admitted(source), "unknown source bus cannot bypass muted fallback Master")
	AudioServer.set_bus_mute(0, false)
	source.bus = &"FocusSourceFixture"
	AudioServer.set_bus_send(3, &"MissingFocusSendFixture")
	check(AudioServer.get_bus_send(3) == &"MissingFocusSendFixture" and not Audibility.admitted(source), "unknown send destination declines safely without an invalid mixer lookup")
	AudioServer.set_bus_send(3, &"FocusSourceFixture")
	check(AudioServer.get_bus_send(3) == &"FocusSourceFixture" and not Audibility.admitted(source), "self-looped send declines safely without hanging")
	AudioServer.set_bus_send(3, &"FocusWorldFixture")
	AudioServer.set_bus_send(2, &"FocusSourceFixture")
	check(not Audibility.admitted(source), "two-bus routing cycle declines safely without hanging")
	AudioServer.set_bus_send(2, &"FocusParentFixture")
	check(Audibility.admitted(source), "repairing fixture routing restores eligibility")

	var before := mixer_snapshot()
	var source_before := {"playing": source.playing, "paused": source.stream_paused,
		"bus": source.bus, "volume_db": source.volume_db}
	for _i in range(5):
		Audibility.admitted(source)
	check(mixer_snapshot() == before, "eligibility queries do not mutate mixer gain, routes, mute or solo state")
	check(source_before == {"playing": source.playing, "paused": source.stream_paused,
		"bus": source.bus, "volume_db": source.volume_db}, "eligibility queries do not mutate native source playback or settings")
	source.stop()
	check(not Audibility.admitted(source), "stopping native playback revokes eligibility")
	source.queue_free()
	await frames()
	# Fixed-FPS headless frames can finish before the Dummy mixer's real-time
	# retirement step. Let native playback references retire before teardown.
	OS.delay_msec(80)
	AudioServer.set_bus_layout(saved_layout)
	check(mixer_snapshot() == original_state, "native routing fixture restores the complete previous mixer layout")
	print("FOCUS_AUDIBILITY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
