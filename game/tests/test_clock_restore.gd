# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## Explicit state regression, not a played journey or elapsed wall time.
const State := preload("res://territory/gujranwala_state.gd")
const Rules := preload("res://territory/misl_rules.gd")
const SAVE := "user://net-clock-regression-only.json"
var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition: passed+=1
	else:
		failed+=1
		push_error("FAIL: "+label)

func _initialize() -> void:
	var original := State.new()
	for target in [94,274,601,1430,4809,6522,6525]:
		while original.progress().tick<target: original.advance()
		var before := original.snapshot()
		check(original.save_to(SAVE).is_empty(),"clock regression save at "+str(target))
		var restored := State.new()
		check(restored.load_from(SAVE).is_empty(),"clock regression load at "+str(target))
		check(Rules._equal(before,restored.snapshot()),"derived clock roundtrips exactly at "+str(target))
		check(Rules._equal(before,original.snapshot()),"saving does not mutate original clock")
		original.advance();restored.advance()
		check(Rules._equal(original.snapshot(),restored.snapshot()),"next original tick agrees after checkpoint")
		var corrupt := restored.snapshot()
		var unmodified := restored.snapshot()
		corrupt.game_time.hour+=0.001
		check(not restored.restore(corrupt).is_empty(),"inconsistent clock still refuses before normalization")
		check(Rules._equal(unmodified,restored.snapshot()),"clock refusal does not mutate state")
	DirAccess.remove_absolute(SAVE)
	print("DERIVED_CLOCK_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
