# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
## External production instrumentation over the ORIGINAL game state implementation.
## Explicit post-inquiry/pose fixtures, NOT a played journey or rendered navigation.
const State := preload("res://territory/gujranwala_state.gd")
const Water := preload("res://territory/water_round_rules.gd")
const Economy := preload("res://territory/misl_rules.gd")
const Fixture := preload("res://tests/gujranwala_fixture.gd")
const Pose := preload("res://tests/aftermath_fixture.gd")
const STRIDE := 6
const END := 70
var model := State.new()
var request: Dictionary
var samples: Array = []
var events: Array = []
var refused := 0
var checkpoint_ok := 0
var origin := 0
var initial_money := 0
var output_dir := ""

func _initialize() -> void:
	_run.call_deferred()

func require_ok(error: String) -> bool:
	if not error.is_empty():
		push_error(error)
		return false
	return true

func action(tick: int, kind: String, position: Vector3) -> void:
	# Test positioning uses the existing validated fixture. No locomotion claim.
	var error: String = Pose.pose(model, position)
	if error.is_empty():
		error = model.water_action(kind)
	if not error.is_empty():
		refused += 1
	events.append({"id":"water-action-%d" % events.size(), "tick":tick,
		"kind":"water." + kind, "actor_id":"ranjit_singh", "target_ids":[],
		"causes":[], "payload":{"admitted":error.is_empty(), "reason":error,
		"game_tick":int(model.snapshot().childhood.tick)}})

func observe(tick: int) -> void:
	var ledger: Dictionary = model.water_round().ledger
	var money: Dictionary = model.economy().ledger
	var values := {"remaining":ledger.remaining, "carried":ledger.carried,
		"stored":ledger.stored, "balance":ledger.remaining+ledger.carried+ledger.stored,
		"refusals":refused, "checkpoint_ok":checkpoint_ok,
		"valid_state":1 if model.validate(model.snapshot()).is_empty() else 0,
		"currency_delta":int(money.purse)+int(money.treasury)-initial_money,
		"engine_ticks":int(model.snapshot().childhood.tick)-origin}
	for channel in request.scenario.channels:
		# An explicit recorder fault tests missing evidence, not game behavior.
		if request.diagnostic_fault=="drop-sample" and tick==END and channel=="stored":
			continue
		samples.append({"tick":tick,"channel":channel,"value":values[channel]})

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=2:
		quit(2); return
	var parsed := JSON.new()
	if parsed.parse(FileAccess.get_file_as_string(args[0]))!=OK or not parsed.data is Dictionary:
		quit(2); return
	request = parsed.data
	output_dir = args[1].get_base_dir()
	if request.scenario.project_id!="1792" or request.scenario.model_id!=Water.MODEL_ID:
		quit(2); return
	var parameters: Dictionary = request.scenario.parameters
	if not require_ok(model.restore(Fixture.complete())) or not require_ok(model.begin_allowance()) or not require_ok(model.begin_water_round()):
		quit(2); return
	origin = int(model.snapshot().childhood.tick)
	initial_money = int(model.economy().ledger.purse)+int(model.economy().ledger.treasury)
	for tick in range(END+1):
		if tick>0:
			for _i in range(STRIDE): model.advance()
		if tick==int(parameters.first_deposit_tick) or tick==int(parameters.second_deposit_tick):
			action(tick,"deposit",Water.STORE-Vector3(0,0,1))
		if tick==0 or tick==31:
			action(tick,"draw",Vector3(26,0.14,14))
		if tick==int(parameters.checkpoint_tick):
			var original: Dictionary = model.snapshot()
			var path := output_dir.path_join("checkpoint.json")
			var error: String = model.save_to(path)
			var restored := State.new()
			if error.is_empty(): error = restored.load_from(path)
			checkpoint_ok = 1 if error.is_empty() and Economy._equal(original,restored.snapshot()) else 0
			if checkpoint_ok==1: model = restored
			events.append({"id":"water-checkpoint-%d" % events.size(),"tick":tick,
				"kind":"water.checkpoint","actor_id":"ranjit_singh","target_ids":[],"causes":[],
				"payload":{"roundtrip_equal":checkpoint_ok==1,"game_tick":int(model.snapshot().childhood.tick)}})
		observe(tick)
	var dropped := 1 if request.diagnostic_fault=="drop-sample" else 0
	var trace := {"schema":"ciw.game-trace.v1", "request_nonce":request.nonce,
		"scenario_digest":request.scenario_digest,"engine":"godot",
		"engine_version":Engine.get_version_info().string,"samples":samples,"events":events,
		"dropped_samples":dropped,"dropped_events":0,"complete":dropped==0}
	var file := FileAccess.open(args[1],FileAccess.WRITE)
	if file==null:
		quit(2); return
	file.store_string(JSON.stringify(trace)); file.flush()
	var error := file.get_error()
	file.close()
	quit(0 if error==OK else 2)
