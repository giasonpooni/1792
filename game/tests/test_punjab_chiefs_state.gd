# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends SceneTree
const State := preload("res://history/punjab_chiefs_state.gd")
const ROUTES := ["alliance", "delegation", "desi", "exile", "heirs", "litter", "overture", "regency", "revenge", "rumours", "settlement", "sodhra", "well"]
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(test: bool, label: String) -> void:
	if test: passed += 1
	else: failed += 1; push_error("FAIL: " + label)

func ok(error: String, label: String) -> void:
	check(error.is_empty(), label + ": " + error)

func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(), label + " refuses")
	check(model.snapshot() == before, label + " preserves progress")

func _pick(model, option: int = 0) -> void:
	var beat: Dictionary = model.current_beat()
	if beat.is_empty(): check(false, "choice requires a current beat"); return
	if option >= beat.choices.size(): check(false, "route offers requested alternative"); return
	ok(model.choose(beat.choices[option].id), model.sequence_id + "/" + beat.id)

func _finish(id: String, option: int) -> State:
	var model := State.new()
	ok(model.start(id), "begin " + id)
	check(not model.complete() and model.ending().is_empty(), "no premature ending: " + id)
	for _index in range(State.MAX_BEATS):
		if model.complete(): break
		_pick(model, option)
	check(model.complete() and model.current_beat().is_empty(), "finite route completes: " + id)
	check(not model.ending().is_empty(), "completed route has ending: " + id)
	var replay := State.new()
	# JSON roundtripping deliberately exercises integral floats from the parser.
	ok(replay.restore(JSON.parse_string(JSON.stringify(model.snapshot()))), "JSON route replay: " + id)
	check(replay.snapshot() == model.snapshot() and replay.ending() == model.ending(), "same outcome after replay: " + id)
	reject(model, model.choose.bind("extra_after_ending"), "cannot append after " + id)
	return model

func _routes() -> void:
	var model := State.new()
	var available: Array = model.catalogue().map(func(item): return item.id)
	available.sort()
	check(available == ROUTES, "the thirteen distinct family and court tales are available")
	if available != ROUTES: return
	for id in ROUTES:
		var first := _finish(id, 0)
		var alternate := _finish(id, 1)
		check(first.flags != alternate.flags, "decisions change the account: " + id)
		check(first.ending() != alternate.ending(), "alternatives reach different conclusions: " + id)
		# A partially heard tale restores to its exact next action, not its ending.
		var partial := State.new()
		ok(partial.start(id), "partial start " + id)
		_pick(partial)
		var restored := State.new()
		ok(restored.restore(partial.snapshot()), "partial replay " + id)
		check(restored.step_index == 1 and not restored.complete(), "restore leaves remaining actions " + id)
		check(restored.current_beat() == partial.current_beat(), "restore returns to next beat " + id)

func _atomic_rejections() -> void:
	var model := State.new()
	check(not model.complete() and model.current_beat().is_empty() and model.ending().is_empty(), "new progress has no invented tale")
	reject(model, model.choose.bind("unknown"), "choice without a tale")
	ok(model.start("delegation"), "atomic test route")
	if model.sequence.is_empty(): return
	var later: String = model.sequence.beats[1].choices[0].id
	reject(model, model.choose.bind(later), "future beat choice")
	reject(model, model.choose.bind("unknown"), "unknown choice")
	reject(model, model.choose.bind("x".repeat(65)), "oversized choice")
	reject(model, model.start.bind("unknown"), "unknown start")
	var first: String = model.current_beat().choices[0].id
	_pick(model)
	reject(model, model.choose.bind(first), "repeated completed choice")
	_pick(model)
	var valid: Dictionary = model.snapshot()
	for case in ["extra", "missing", "schema", "identity", "sequence_type", "step", "fraction", "negative", "nan", "infinite", "step_bool", "flags", "flag_type", "flag_name", "flag_count", "history_type", "history_length", "choice_type", "choice_length", "choice_unknown", "choice_order", "choice_repeat", "unstarted"]:
		var bad: Dictionary = valid.duplicate(true)
		match case:
			"extra": bad["campaign"] = {"tick": 100}
			"missing": bad.erase("flags")
			"schema": bad.schema = "future"
			"identity": bad.sequence_id = "unknown"
			"sequence_type": bad.sequence_id = 1
			"step": bad.step_index += 1
			"fraction": bad.step_index = 1.5
			"negative": bad.step_index = -1
			"nan": bad.step_index = NAN
			"infinite": bad.step_index = INF
			"step_bool": bad.step_index = true
			"flags": bad.flags["unearned_reward"] = true
			"flag_type": bad.flags[bad.flags.keys()[0]] = 1
			"flag_name": bad.flags["Bad Flag"] = true
			"flag_count":
				for n in range(State.MAX_FLAGS + 1): bad.flags["flag_%d" % n] = true
			"history_type": bad.choices = {}
			"history_length": bad.choices.resize(State.MAX_BEATS + 1)
			"choice_type": bad.choices[0] = {"id": first}
			"choice_length": bad.choices[0] = "x".repeat(65)
			"choice_unknown": bad.choices[0] = "unknown"
			"choice_order": bad.choices.reverse()
			"choice_repeat": bad.choices[1] = bad.choices[0]
			"unstarted": bad.sequence_id = ""
		reject(model, model.restore.bind(bad), "restore " + case)
	for malformed in [null, [], "saved", 4, true]:
		reject(model, model.restore.bind(malformed), "non-dictionary restore")
	# A plausible false flag is still rejected if no recorded choice produced it.
	var forged: Dictionary = valid.duplicate(true)
	var key: String = forged.flags.keys()[0]
	forged.flags[key] = not forged.flags[key]
	reject(model, model.restore.bind(forged), "forged alternative outcome")
	ok(model.restore(valid), "valid candidate still accepted after rejections")
	check(model.snapshot() == valid, "valid history remains usable")
	var empty := State.new()
	ok(model.restore(empty.snapshot()), "restore genuinely unstarted progress")
	check(model.sequence_id.is_empty() and model.flags.is_empty() and model.choices.is_empty(), "rewind clears later history")

func _story(id: String, decisions: Array) -> State:
	var model := State.new()
	ok(model.start(id), "named decisions for " + id)
	for decision in decisions: ok(model.choose(decision), "story decision " + decision)
	check(model.complete(), "named decisions finish " + id)
	return model

func _domain_outcomes() -> void:
	var delegation := _story("delegation", ["protect_letters", "kinship_first", "name_house", "seek_terms", "guard_confidence"])
	check(delegation.flags.get("private_letters", false) and delegation.flags.get("guarded_confidence", false), "delegation retains the decision to protect confidence")
	check(not delegation.flags.has("reported_interference") and delegation.ending().contains("discretion"), "a private negotiation does not become a public accusation")
	var alliance := _story("alliance", ["promise_credit", "walk_together", "request_assistance", "name_cost", "share_dressings"])
	check(alliance.flags.get("public_recognition", false) and alliance.flags.get("shared_supplies", false), "ally service receives acknowledgement and supplies")
	check(alliance.ending().contains("mutual care"), "aid changes the remembered alliance")
	var revenge := _story("revenge", ["ask_identity", "record_words", "warn_host", "reassure_family", "send_witness"])
	check(revenge.flags.get("warned_host", false) and revenge.flags.get("sheltered_dependent", false), "warning and shelter survive the revenge account")
	check(revenge.ending().contains("witness is sought") and revenge.ending().contains("killed Dal Singh"), "first matching ending retains witness and recorded fatal revenge")
	var desi := _story("desi", ["gentle_mount", "measured_stride", "check_ground", "water_first", "remember_partnership"])
	check(desi.flags.has("mounted") and desi.flags.mounted == false, "dismount replaces the earlier mounted narrative flag")
	check(desi.flags.get("water_first", false) and desi.ending().contains("Desi drinking"), "horse care completes the remembered partnership")
	var replay := State.new()
	ok(replay.restore(desi.snapshot()), "false narrative flags replay")
	check(replay.flags.has("mounted") and replay.flags.mounted == false, "false flag survives restoration")
	var exile := _story("exile", ["carry_vow", "offer_service", "reciprocal_help", "keep_treasure_tale", "renew_return"])
	check(exile.flags.get("treasure_tale_kept", false) and exile.flags.get("return_with_debt", false), "exile retains the treasure tradition and debt to hosts")
	check(exile.ending().contains("well-treasure tradition"), "legend can shape the exile ending")
	var well := _story("well", ["name_brackish", "clear_threshold", "follow_quietly", "receive_blessing", "carry_story"])
	check(well.flags.get("miracle_witnessed", false) and well.flags.get("story_carried", false), "well route preserves the witnessed miracle as narrative")
	check(well.ending().contains("sweet water") and well.ending().contains("powerful descendant"), "the well tradition retains blessing and prophecy")

func _detached_queries() -> void:
	var model := State.new()
	ok(model.start("well"), "query test route")
	if model.sequence.is_empty(): return
	_pick(model)
	var before: Dictionary = model.snapshot()
	var expected_beat: Dictionary = model.current_beat()
	var sequence_copy: Dictionary = model.sequence
	sequence_copy.beats.clear()
	var flag_copy: Dictionary = model.flags
	flag_copy["gold_for_the_campaign"] = true
	var history_copy: Array = model.choices
	history_copy.clear()
	var beat_copy: Dictionary = model.current_beat()
	beat_copy.choices.clear()
	var snapshot_copy: Dictionary = model.snapshot()
	snapshot_copy.flags.clear(); snapshot_copy.choices.clear()
	var catalogue_copy: Array = model.catalogue()
	catalogue_copy.clear()
	check(model.snapshot() == before and model.current_beat() == expected_beat, "queries cannot mutate progress or next action")
	check(model.catalogue().size() == ROUTES.size(), "catalogue query is detached")
	ok(model.start("desi"), "a new telling replaces prior story progress")
	check(model.step_index == 0 and model.choices.is_empty() and model.flags.is_empty(), "story switch does not inherit another tale's flags")

func _run() -> void:
	_routes()
	_atomic_rejections()
	_domain_outcomes()
	_detached_queries()
	print("PUNJAB_CHIEFS_STATE_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
