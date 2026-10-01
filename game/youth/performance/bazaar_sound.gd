# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original synthesized, nonvocal placeholder foley. No samples, music or imitation voices.
static func make(kind: String) -> AudioStreamWAV:
	var length:=.11 if kind=="cloth" else .19 if kind=="check" else .26
	var size:=int(length*22050);var bytes:=PackedByteArray();bytes.resize(size*2)
	var rng:=RandomNumberGenerator.new();rng.seed=1792+kind.hash()
	var memory:=0.0
	for i in range(size):
		var t:=float(i)/22050;var noise:=rng.randf_range(-1,1)
		memory=lerpf(memory,noise,.26)
		var envelope:=minf(t/.006,1)*exp(-t*(36 if kind=="cloth" else 23))
		var wave: float=(memory*.38+sin(TAU*(115 if kind=="check" else 72)*t)*.25)*envelope
		bytes.encode_s16(i*2,int(clampf(wave,-.7,.7)*32767))
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.stereo=false;stream.data=bytes;return stream
