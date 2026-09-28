extends SceneTree
## Contract tests with a declared future pre-Lahore fixture, NOT a played father campaign.
const Interlude := preload("res://history/fixed_interlude.gd")
var passed := 0
var failed := 0
func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else:
		failed += 1
		push_error("FAIL: "+label)
func ok(error: String, label: String) -> void: check(error.is_empty(),label+": "+error)
func reject(model, action: Callable, label: String) -> void:
	var before: Dictionary = model.snapshot()
	check(not str(action.call()).is_empty(),label+" refused")
	check(model.snapshot() == before,label+" is atomic")
func anchor(year: int = 1797) -> Dictionary: return {"chapter_id":Interlude.GATE,"year":year}
func present(year: int = 1797) -> Dictionary:
	return {"schema_version":"world-state.v1","profile":"pre_lahore_test_fixture",
		"game_time":{"year":year,"day":200,"hour":16.5},
		"player":{"character_id":"ranjit_singh","position":[12.25,0.14,-8.0],"known_places":["gujranwala"]},
		"places":[{"id":"gujranwala"}],
		"inventory":[{"id":"present_horse","condition":0.8}],"treasury":37,
		"beliefs":[{"source":"courier","claim":"a report, not certainty"}],
		"relationships":[{"source":"raj_kaur","target":"ranjit_singh","stance":"authored_rivalry"}],"territory":{"lahore_taken":false}}
func provider(value: Dictionary) -> String:
	if value.get("profile") != "pre_lahore_test_fixture": return "Wrong test fixture."
	if not value.get("places") is Array or not value.get("relationships") is Array: return "Missing world collections."
	if not value.get("player") is Dictionary or not value.player.get("known_places") is Array: return "Missing known-place record."
	if not value.get("territory") is Dictionary or value.territory.get("lahore_taken") != false: return "Lahore is already taken."
	return ""
func _run() -> void:
	var validate_present := Callable(self,"provider")
	var model := Interlude.new()
	check(not model.allows_lahore_transition(),"gate closed without story")
	check(model.controlled_actor() == "","no actor before begin")
	reject(model,model.begin.bind(anchor(1792),present(1792),validate_present),"not immediately after childhood")
	reject(model,model.begin.bind(anchor(1801),present(1801),validate_present),"not after accession")
	reject(model,model.begin.bind(anchor(),present(1798),validate_present),"year relabelling")
	reject(model,model.begin.bind(anchor(),present(),Callable()),"missing provider validator")
	var bad_world := present()
	bad_world.player.character_id = "patrol_captain"
	reject(model,model.begin.bind(anchor(),bad_world,validate_present),"wrong suspended actor")
	bad_world = present()
	bad_world.territory.lahore_taken = true
	reject(model,model.begin.bind(anchor(),bad_world,validate_present),"provider vetoes late entry")
	bad_world = present()
	bad_world.player.position[0] = NAN
	reject(model,model.begin.bind(anchor(),bad_world,validate_present),"nonfinite retained world")
	bad_world = present()
	bad_world.unknown_object = RefCounted.new()
	reject(model,model.begin.bind(anchor(),bad_world,validate_present),"object serialization")
	var world := present()
	var original_json := JSON.stringify(world,"",true,true)
	ok(model.begin(anchor(),world,validate_present),"bind pre-Lahore context")
	check(model.controlled_actor() == "mahan_singh","father is a separate playable identity")
	check(world == present(),"enter does not mutate caller's world")
	world.treasury = 0
	check(model.snapshot().present_json == original_json,"caller cannot mutate parked world")
	var detached := model.snapshot()
	detached.completed_beats.append("invented")
	check(model.snapshot().completed_beats.is_empty(),"read projection detached")
	reject(model,model.begin.bind(anchor(),present(),validate_present),"double entry")
	reject(model,model.complete_beat.bind("kanhaiya_conflict"),"skip earlier beats")
	reject(model,model.conclude_fixed_history,"early death completion")
	check(model.resume_buddh().has("error") and not model.allows_lahore_transition(),"cannot bypass to Buddh")
	ok(model.complete_beat("inherit_misl_command"),"first beat recorded")
	ok(model.fail_attempt(),"ordinary attempt fails")
	check(model.snapshot().outcome == "" and model.next_beat() == "","attempt failure is not historical death")
	reject(model,model.complete_beat.bind("ramgarhia_alliance"),"failed attempt cannot complete beat")
	var serialized := JSON.stringify(model.snapshot(),"",true,true)
	var parser := JSON.new()
	check(parser.parse(serialized) == OK,"interlude serializes")
	var loaded := Interlude.new()
	ok(loaded.restore(parser.data,validate_present),"suspend/load failed attempt")
	check(loaded.snapshot().present_json == original_json,"load retains exact parked JSON")
	ok(loaded.retry_attempt(),"retry does not restart father story")
	check(loaded.next_beat() == "ramgarhia_alliance","only current beat retried")
	for beat in ["ramgarhia_alliance","kanhaiya_conflict","final_orders"]:
		ok(loaded.complete_beat(beat),"record beat "+beat)
		check(not loaded.allows_lahore_transition(),"gate still closed before fixed ending/resume")
	ok(loaded.conclude_fixed_history(),"death completes fixed story")
	check(loaded.snapshot().outcome == Interlude.FIXED_END,"one terminal outcome")
	reject(loaded,loaded.fail_attempt,"historical death is not game over")
	for damage in ["survives","wrong_actor","skip","reorder","hash","extra","date","knowledge_merge"]:
		var changed := loaded.snapshot()
		match damage:
			"survives": changed.outcome = "mahan_survives"
			"wrong_actor": changed.interlude_id = "ranjit_singh"
			"skip": changed.completed_beats.pop_back()
			"reorder": changed.completed_beats.reverse()
			"hash": changed.present_json += " "
			"extra": changed.present_actor = "mahan_singh"
			"date": changed.anchor.year = 1798
			"knowledge_merge": changed.character_knowledge_grants = ["the_father_saw_this"]
		reject(loaded,loaded.restore.bind(changed,validate_present),"tampered "+damage)
	check(loaded.controlled_actor() == "ranjit_singh" and loaded.snapshot().phase == "buddh_reprise","father death hands historical viewpoint to young Buddh")
	check(not loaded.resume_buddh().error.is_empty() and not loaded.allows_lahore_transition(),"reprise cannot be bypassed")
	ok(loaded.complete_buddh_reprise(),"replayed beginning catches up to suspended story")
	reject(loaded,loaded.complete_buddh_reprise,"reprise cannot complete twice")
	var receipt: Dictionary = loaded.resume_buddh()
	check(receipt.error.is_empty(),"return accepted")
	check(receipt.world_json == original_json,"parked present resumes byte-identical")
	var original_parser := JSON.new()
	check(original_parser.parse(original_json) == OK,"original frozen JSON decodes")
	check(receipt.world == original_parser.data,"all decoded money, position, relations, knowledge and territory preserved")
	check(receipt.world.treasury == 37 and receipt.world.game_time.year == 1797,"numeric values preserved despite JSON integer/float representation")
	check(receipt.story_receipt.scope == "viewer_story_progress","receipt not an NPC memory")
	check(receipt.story_receipt.item_grants.is_empty() and receipt.story_receipt.character_knowledge_grants.is_empty(),"no historical loot or omniscient grants")
	check(loaded.controlled_actor() == "ranjit_singh" and loaded.allows_lahore_transition(),"Buddh resumes at the story gate")
	check(not loaded.resume_buddh().error.is_empty(),"single-use return cannot award twice")
	check(receipt.anchor == anchor(),"same story year and anchor, not a childhood restart")
	var second := Interlude.new()
	ok(second.begin(anchor(1798),present(1798),validate_present),"one-year lead-up also supported")
	for beat in Interlude.BEATS: ok(second.complete_beat(beat),"second sequence "+beat)
	ok(second.conclude_fixed_history(),"same fixed ending on second anchor")
	ok(second.complete_buddh_reprise(),"second reprise")
	check(second.resume_buddh().story_receipt.outcome == receipt.story_receipt.outcome,"anchor year cannot change father's ending")
	print("FIXED_INTERLUDE_TESTS: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)
