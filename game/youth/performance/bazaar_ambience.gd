# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original nonvocal procedural market bed: air, timber creak, distant hoof rhythm.
## No speech, music, copied recording or historical acoustic claim.
static func make() -> AudioStreamWAV:
	var rate:=22050
	var seconds:=6.0
	var count:=int(rate*seconds)
	var bytes:=PackedByteArray();bytes.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=179217
	var low:=0.0
	for i in range(count):
		var t:=float(i)/rate
		var noise:=rng.randf_range(-1,1);low=lerpf(low,noise,.015)
		var air:=low*.13
		var creak:=sin(TAU*1.72*t+sin(t*.31)*1.4)*.035*(.5+.5*sin(TAU*.17*t))
		var hoof_phase:=fmod(t,1.73)
		var hoof:=(exp(-hoof_phase*35)+.62*exp(-maxf(0,hoof_phase-.16)*42) if hoof_phase<.38 else 0.0)*sin(TAU*72*t)*.075
		var v:=clampf(air+creak+hoof,-.32,.32)
		bytes.encode_s16(i*2,int(v*32767))
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.stereo=false
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=count;stream.data=bytes
	return stream
