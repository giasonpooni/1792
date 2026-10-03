extends SceneTree
## Presentation cases are explicit fixtures; the one-horse hold uses real input.
const Lesson := preload("res://mounts/horsecraft_training.tscn")
const State := preload("res://mounts/horsecraft_state.gd")
const Direction := preload("res://mounts/horsecraft_direction.gd")
const Attention := preload("res://presentation/story_attention.gd")
var passed := 0
var failed := 0
var lesson: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("HORSECRAFT STORY: " + description)

func frames(count: int = 3) -> void:
	for _i in range(count): await physics_frame
	await process_frame

func key(code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	lesson._unhandled_input(event)

func _read_cases() -> void:
	var model := State.new()
	var state: Dictionary = model.snapshot()
	var support := {"safe": true, "mean_speed": 3.0, "max_speed": 3.0}
	var before := state.duplicate(true)
	var observation := support.duplicate(true)
	var single := Direction.read("single", state, support, false)
	var pair := Direction.read("pair", state, support, false)
	check(single.task.contains("onto the saddle") and pair.task.contains("across both saddles"), "each formation names its own immediate physical demand")
	check(not single.controls.contains("fire") and not pair.controls.contains("reload"), "balance lessons omit unavailable weapon controls")
	check(Direction.read("single", state, support, true).controls.contains("Enter next exercise"), "actual earned flag exposes voluntary continuation")
	check(not Direction.read("single", state, support, false).controls.contains("Enter"), "unearned hold offers no continuation")
	var weapons := Direction.read("weapons", state, support, false)
	check(weapons.task.contains("seated shots do not earn"), "seated discharge cannot masquerade as earned standing practice")
	check(weapons.controls.contains("Space stand"), "seated matchlock exercise identifies the required stance input")
	check(state == before and support == observation, "direction sampling preserves every supplied state and support field")
	state.stance = "standing"
	check(Direction.read("weapons", state, support, false).task.contains("while standing"), "supported standing gets the current shooting objective")
	state.slots[0] = false
	check(Direction.read("weapons", state, support, false).task.contains("Matchlock 1 is empty"), "spent selection is explained by its actual identity")
	state.reload_slot = 0
	check(Direction.read("weapons", state, support, false).task.contains("finish recharging matchlock 1"), "exclusive charge tells the player to finish the current weapon")
	check(not Direction.read("weapons", state, support, false).controls.contains("fire"), "active charge suppresses conflicting firing instruction")
	state.reload_paused = true
	check(Direction.read("weapons", state, support, false).urgent, "paused reload surfaces a present corrective demand")
	state.reload_slot = -1; state.reload_paused = false
	state.volley_slots = [0, 1, 2, 3]; state.slots = [false, false, false, false]
	check(Direction.read("weapons", state, support, false).controls.contains("select empty"), "four recorded standing shots shift attention to recharging")
	state.slots = [true, true, true, true]
	check(Direction.read("weapons", state, support, false).controls == "S brake · Space sit", "all charged weapons shift attention to safe withdrawal")
	state.brake_required = true
	check(Direction.read("weapons", state, support, true).urgent and Direction.read("weapons", state, support, true).controls.contains("recovery"), "recovery outranks earned progress and weapon controls")
	state.brake_required = false; state.stance = "seated"
	check(not Direction.read("complete", state, support, true).controls.contains("Enter"), "moving completion cannot advertise return")
	support.max_speed = 0.0
	check(Direction.read("complete", state, support, true).controls.contains("Enter return"), "stopped seated completion offers the actual guarded return")
	support.safe = false
	check(Direction.read("complete", state, support, true).urgent and not Direction.read("complete", state, support, true).controls.contains("Enter"), "unsafe support prevents a misleading ready-to-return prompt")
	check(Direction.return_line(false, "").contains("No new riding skills learned"), "withdrawal explains no grant without rebuking the player")
	check(Direction.return_line(false, "pair").contains("retained"), "practice withdrawal states already earned skills persist")
	check(Direction.return_line(true, "").contains("brought the horses home"), "completion pays off the opening responsibility motif")
	var voices: Array[String] = []
	for beat in ["single", "single_earned", "pair", "pair_earned", "weapons", "complete"]:
		var line := Direction.line(beat)
		check(line.begins_with("Maha, in the tale:") and not line in voices, "distinct attributed original dialogue for " + beat)
		voices.append(line)

func _run() -> void:
	_read_cases()
	lesson = Lesson.instantiate(); root.add_child(lesson); current_scene = lesson
	await frames(6)
	check(lesson.hud.text.contains("Ride forward, then rise"), "native first exercise foregrounds its present demand")
	check(lesson.status.text.contains("Maha, in the tale:"), "native dialogue appears in the separate caption area")
	var frozen: Dictionary = lesson.model.snapshot()
	var proof_before: Array = lesson.milestones.duplicate(true)
	for _i in range(20): lesson._refresh()
	check(lesson.model.snapshot() == frozen and lesson.milestones == proof_before, "repeated rendering never earns a hold or changes practice authority")
	key(KEY_ESCAPE)
	var paused_tick: int = lesson.lesson_tick
	await frames(8)
	check(lesson.lesson_tick == paused_tick and lesson.model.snapshot() == frozen, "pause freezes the existing lesson and caption clock")
	check(lesson.hud.text.contains("restart all three exercises") and lesson.hud.text.contains("leaving keeps your Home as it was"), "pause explains restart and withdrawal consequences before using them")
	lesson.message = "The retained lesson changed; the return cannot merge these states."
	lesson._refresh()
	check(lesson.status.text.contains("return cannot merge"), "paused session refusal remains visible instead of being masked by dialogue")
	key(KEY_ESCAPE)
	Input.action_press("move_forward"); await frames(35); key(KEY_SPACE)
	await frames(State.RISE_TICKS + 64)
	check(lesson._has_milestone("single_standing"), "native horse input earns the actual moving hold")
	check(lesson.status.text.contains("listened to the horse"), "earned movement receives the first instructor payoff")
	check(lesson.hud.text.contains("Enter next exercise"), "earned hold reveals continuation without forcing the next scene")
	Input.action_release("move_forward"); Input.action_press("move_backward"); await frames(40)
	Input.action_release("move_backward")
	await frames(Attention.reading_ticks(Direction.line("single_earned")) + 2)
	check(not lesson.status.text.contains("listened to the horse"), "milestone dialogue expires instead of remaining over later riding")
	check(lesson._has_milestone("single_standing"), "caption expiry cannot remove the earned milestone")
	key(KEY_ENTER); await frames(5)
	check(lesson.lesson_phase == "pair" and lesson.status.text.contains("Neither can be forgotten"), "voluntary transition starts the pair's distinct teaching beat")
	check(lesson.max_single_hold_ticks == 60, "formation transition retains earned hold evidence")
	key(KEY_ESCAPE); key(KEY_BACKSPACE); await frames(5)
	check(lesson.lesson_phase == "single" and lesson.milestones.is_empty(), "explicit restart begins all three exercises again")
	check(lesson.status.text.contains("Feel the horse's step") and not lesson.status.text.contains("Neither can be forgotten"), "restart discards earlier scene captions")
	check(lesson.training_proof().is_empty() and lesson.completion_receipt().is_empty(), "presentation and voluntary reset cannot manufacture completion")
	current_scene = null; lesson.queue_free(); lesson = null; await frames(3)
	print("HORSECRAFT_STORY_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
