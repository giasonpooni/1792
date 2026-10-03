extends SceneTree
## Domain tests: fixture positioning is explicit; native contact/facing is tested separately.
const Model := preload("res://childhood/childhood_state.gd")
const Aftermath := preload("res://childhood/aftermath_state.gd")
const Rules := preload("res://childhood/message_followup_rules.gd")
const Names := preload("res://characters/character_names.gd")
const SAVE := "user://opening-message-regression-only.json"
var passed := 0
var failed := 0

func _initialize() -> void: _run.call_deferred()
func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
func ok(error: String, label: String) -> void: check(error.is_empty(), label + ": " + error)
func refuse(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), label + " refused")
	check(model.snapshot() == before, label + " preserves whole state")
func pose(model, place: Vector3) -> void:
	var state: Dictionary = model.snapshot()
	state.player.position = Model.coords(place)
	state.actors[Names.HERO_ID].position = Model.coords(place)
	ok(model.restore(state), "install domain pose fixture")
func briefed(model = null):
	if model == null: model = Model.new()
	var state: Dictionary = model.snapshot()
	state.childhood.walked = 6.0
	state.childhood.looked = 1.0
	ok(model.restore(state), "orientation fixture")
	pose(model, Model.SITES.courier)
	model.advance()
	ok(model.inspect_letter(), "collect sealed message")
	ok(model.hear("courier"), "hear initial courier account")
	pose(model, Model.SITES.steward)
	model.advance()
	ok(model.hear("steward"), "hear initial steward account")
	return model
func only_receipt_changed(before: Dictionary, after: Dictionary, label: String) -> void:
	var base := after.duplicate(true)
	base.erase("opening_message")
	var prior := before.duplicate(true)
	prior.erase("opening_message")
	check(base == prior, label + " grants no unrelated state, clock or resource change")

func routes_and_legacy() -> void:
	var fresh := Model.new()
	var seed: Dictionary = fresh.snapshot()
	check(not seed.has("opening_message") and fresh.message_phase() == "dormant" and fresh.message_followup().is_empty(), "new and old-style profiles have no optional field")
	ok(fresh.restore(seed), "restore legacy profile")
	check(fresh.snapshot() == seed and fresh.journal().is_empty(), "legacy restore infers no new event")
	for route in ["direct", "clarify"]:
		var model = briefed()
		var original: Dictionary = model.snapshot()
		ok(model.message_action(route), "agree " + route)
		only_receipt_changed(original, model.snapshot(), route + " agreement")
		check(model.stage() == "riding", "optional errand never blocks riding")
		check(model.message_phase() == ("report" if route == "direct" else "clarify"), "route phase")
		var detached: Dictionary = model.message_followup()
		detached.receipts.clear()
		check(model.message_followup().receipts.size() == 1, "follow-up read is detached")
		refuse(model, model.message_action.bind(route), "duplicate agreement")
		refuse(model, model.message_action.bind("clarify" if route == "direct" else "direct"), "route rewrite")
		if route == "clarify":
			pose(model, Model.SITES.spar)
			refuse(model, model.message_action.bind("report"), "report before clarification")
			pose(model, Model.SITES.courier)
			model.advance()
			var before: Dictionary = model.snapshot()
			ok(model.message_action("confirm"), "physically hear clarification")
			only_receipt_changed(before, model.snapshot(), "clarification")
			check(model.journal().back().text == Rules.COURIER_CLARIFICATION and model.journal().back().source_id == "fictional_courier", "clarification has the heard original words and provenance")
			refuse(model, model.message_action.bind("confirm"), "repeated clarification")
		pose(model, Model.SITES.spar)
		refuse(model, model.message_action.bind("report"), "distinct physical visit cannot share prior receipt tick")
		model.advance()
		var before_report: Dictionary = model.snapshot()
		ok(model.message_action("report"), "report " + route + " route")
		only_receipt_changed(before_report, model.snapshot(), "spoken report")
		var legacy_progress: Dictionary = model.progress()
		legacy_progress.tick = original.childhood.tick
		check(model.message_phase() == "complete" and legacy_progress == original.childhood, "completion preserves legacy lessons and memories")
		# The common clock advances for the journey, so compare legacy memories explicitly.
		check(model.progress().memories == original.childhood.memories, "old testimony texts remain byte-for-byte unchanged")
		check(model.journal().back().id == "opening_message_report", "report projected in journal")
		var projected: Array = model.journal()
		projected.back().text = "Invented certainty"
		check(model.journal().back().text != "Invented certainty", "journal projection is detached")
		refuse(model, model.message_action.bind("report"), "repeated report")
		ok(model.validate(model.snapshot()), "completed route validates")
		ok(model.restore(original), "rollback to pre-choice save")
		check(not model.snapshot().has("opening_message") and model.journal() == original.childhood.memories, "rollback removes later route and knowledge")

func locality_and_refusal() -> void:
	var fresh := Model.new()
	pose(fresh, Model.SITES.steward)
	for action in ["direct", "clarify", "confirm", "report", "reveal"]:
		refuse(fresh, fresh.message_action.bind(action), "premature " + action)
	var model = briefed()
	pose(model, Model.SITES.steward + Vector3(0, 3.01, 0))
	refuse(model, model.message_action.bind("direct"), "vertical separation")
	pose(model, Model.SITES.steward + Vector3(2.3, 2.3, 0))
	refuse(model, model.message_action.bind("direct"), "diagonal full-3D separation")
	pose(model, Model.SITES.courier)
	refuse(model, model.message_action.bind("clarify"), "wrong speaker")
	pose(model, Model.SITES.steward + Vector3(0, 3.0, 0))
	ok(model.message_action("direct"), "inclusive full-3D range boundary")
	model.advance()
	pose(model, Model.SITES.spar)
	var mounted: Dictionary = model.snapshot()
	mounted.riding.horse.position = mounted.player.position.duplicate()
	mounted.riding.horse.rider_id = Names.HERO_ID
	ok(model.restore(mounted), "mounted fixture")
	refuse(model, model.message_action.bind("report"), "mounted report")

func saved_routes() -> void:
	var model = briefed(Aftermath.new())
	ok(model.message_action("clarify"), "inherited authority accepts optional route")
	pose(model, Model.SITES.courier)
	model.advance()
	ok(model.save_to(SAVE), "save awaiting clarification")
	var pending := Aftermath.new()
	ok(pending.restore(JSON.parse_string(FileAccess.get_file_as_string(SAVE))), "independently decode saved pending world")
	ok(model.message_action("confirm"), "clarification after saved point")
	pose(model, Model.SITES.spar)
	model.advance()
	ok(model.message_action("report"), "complete inherited-authority route")
	var clone := Aftermath.new()
	ok(clone.restore(JSON.parse_string(JSON.stringify(model.snapshot(), "", true, true))), "JSON restores completed inherited authority")
	check(clone.message_phase() == "complete" and clone.journal() == model.journal(), "completion and projected testimony survive JSON")
	ok(model.load_from(SAVE), "load earlier pending save")
	check(model.snapshot() == pending.snapshot() and model.message_phase() == "clarify", "load rolls back all world state and optional receipt")
	check(model.journal().filter(func(entry): return entry.id in ["opening_message_confirm", "opening_message_report"]).is_empty(), "load removes unheard future information")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func malformed_receipts() -> void:
	var model = briefed()
	ok(model.message_action("clarify"), "prepare validation route")
	pose(model, Model.SITES.courier)
	model.advance()
	ok(model.message_action("confirm"), "prepare clarification receipt")
	pose(model, Model.SITES.spar)
	model.advance()
	ok(model.message_action("report"), "prepare complete receipt")
	var valid: Dictionary = model.snapshot()
	var mutations: Array[Callable] = [
		func(s): s.opening_message = {},
		func(s): s.opening_message.extra = "secret",
		func(s): s.opening_message.schema_version = "opening-message.v2",
		func(s): s.opening_message.choice = "accuse",
		func(s): s.opening_message.receipts = {},
		func(s): s.opening_message.receipts = [],
		func(s): s.opening_message.receipts[0].extra = true,
		func(s): s.opening_message.receipts[0].received_tick = 0,
		func(s): s.opening_message.receipts[1].received_tick = 2.5,
		func(s): s.opening_message.receipts[1].received_tick = true,
		func(s): s.opening_message.receipts[1].received_tick = NAN,
		func(s): s.opening_message.receipts[1].received_tick = -1,
		func(s): s.opening_message.receipts[1].received_tick = s.childhood.tick + 1,
		func(s): s.opening_message.receipts[1].received_tick = s.opening_message.receipts[0].received_tick,
		func(s): s.opening_message.receipts[1].kind = "report",
		func(s): s.opening_message.receipts[1].kind = "clarify",
		func(s): s.opening_message.receipts.append(s.opening_message.receipts.back().duplicate()),
		func(s): s.opening_message.choice = "direct",
		func(s): s.childhood.unearned_reward = 100,
		func(s): s.other_optional_key = {}
	]
	for index in range(mutations.size()):
		var corrupt := valid.duplicate(true)
		mutations[index].call(corrupt)
		refuse(model, model.restore.bind(corrupt), "malformed receipt %d" % index)
	var premature := Model.new().snapshot()
	premature.opening_message = Rules.begin("direct", 0)
	refuse(model, model.restore.bind(premature), "restored agreement without received base memories")

func encounter_refusal() -> void:
	var model = briefed()
	ok(model.message_action("direct"), "agree before encounter")
	var riding_done: Dictionary = model.snapshot()
	riding_done.childhood.ride_gate = 3
	ok(model.restore(riding_done), "completed riding fixture")
	pose(model, Model.SITES.spar)
	ok(model.spar_result("parry"), "first guard")
	ok(model.spar_result("parry"), "second guard")
	ok(model.spar_result("counter"), "counter")
	for trail in ["track_1", "track_2", "track_3"]:
		pose(model, Model.SITES[trail])
		ok(model.inspect_track(trail), "track encounter prerequisite")
	pose(model, Model.SITES.quarry)
	ok(model.observe_quarry(true), "observe quarry")
	pose(model, Model.SITES.bend)
	for _tick in range(3): model.advance()
	ok(model.start_ambush(), "start encounter")
	pose(model, Model.SITES.spar)
	var active: Dictionary = model.snapshot()
	refuse(model, model.message_action.bind("report"), "active encounter report")
	for _hit in range(3): model.take_hit()
	refuse(model, model.message_action.bind("report"), "caught report")
	ok(model.restore(active), "restore live encounter")
	pose(model, Model.SITES.home)
	ok(model.reach_home(), "escape encounter")
	pose(model, Model.SITES.spar)
	refuse(model, model.message_action.bind("report"), "post-ambush errand closure")
	check(model.message_phase() == "report", "closed pending errand never invents a report")
	ok(model.validate(model.snapshot()), "pending route remains a valid historical receipt")
	var completed := active.duplicate(true)
	completed.opening_message.receipts.append({"kind": "report", "received_tick": int(active.childhood.ambush.start_tick) - 1})
	ok(model.restore(completed), "completed pre-ambush report survives encounter transition")
	check(model.message_phase() == "complete" and model.stage() == "active", "completion does not change the later encounter")
	for offset in [0, 1]:
		var during := completed.duplicate(true)
		during.opening_message.receipts.back().received_tick = int(active.childhood.ambush.start_tick) + offset
		refuse(model, model.restore.bind(during), "receipt at or after ambush boundary %d" % offset)
	ok(model.restore(active), "rollback completed fixture to prior valid pending world")
	check(model.message_phase() == "report" and model.journal().filter(func(entry): return entry.id == "opening_message_report").is_empty(), "rollback retains encounter and removes report knowledge")

func _run() -> void:
	routes_and_legacy()
	locality_and_refusal()
	saved_routes()
	malformed_receipts()
	encounter_refusal()
	print("MESSAGE_FOLLOWUP_STATE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
