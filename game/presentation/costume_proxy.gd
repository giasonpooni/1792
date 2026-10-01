# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends "res://player/locomotion_proxy.gd"
## Reuse the qualified skeleton; deterministic visual sample, not another motor/clock.
func _ready() -> void:
	super._ready()
	set_process(false)

func sample_tick(tick: int) -> void:
	var speed:=Vector2(actor.velocity.x,actor.velocity.z).length()
	phase=fmod(float(posmod(tick,216000))/60.0*speed*3.5,TAU)
	super._process(0.0)
