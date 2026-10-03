extends SceneTree
## Explicit domain fixtures exercise disclosure and rollback. These are not a
## claim of physical travel; the native journey suite covers world interaction.
const Model := preload("res://childhood/aftermath_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Fixture := preload("res://tests/aftermath_fixture.gd")
const View := preload("res://childhood/inquiry_presentation.gd")
const Message := preload("res://childhood/message_followup_rules.gd")
var passed := 0
var failed := 0

func _initialize() -> void: _run.call_deferred()
func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
func ok(error: String, label: String) -> void: check(error.is_empty(), label + ": " + error)

func arrived(seen: bool = true):
	var model := Model.new()
	var seed := Fixture.survived()
	if not seen:
		seed.childhood.ambush.seen = false
		seed.childhood.memories = seed.childhood.memories.filter(func(m): return m.id != "assault")
	ok(model.restore(seed), "explicit surviving childhood fixture")
	return model

func choose(model, choice: String) -> void:
	for speaker in ["courier", "steward"]:
		ok(Fixture.pose(model, Base.SITES[speaker]), "pose at return witness")
		ok(model.hear_return(speaker), "receive return testimony")
	ok(Fixture.pose(model, Model.MOTHER), "pose at protection offer")
	ok(model.hear_offer(), "receive offer")
	ok(model.decide_protection(choice), "choose protection")

func at_bend(model) -> void:
	ok(Fixture.pose(model, Model.CLUE), "pose at clue")
	if model.aftermath().escort.active:
		var seed: Dictionary = model.snapshot()
		seed.aftermath.escort.position = Base.coords(Model.CLUE)
		ok(model.restore(seed), "explicit escort rendezvous fixture")
	ok(model.inspect_bend(), "observe actual trace")

func give_report(model) -> void:
	ok(Fixture.pose(model, Model.MOTHER), "pose at oral report")
	if model.aftermath().escort.active:
		var seed: Dictionary = model.snapshot()
		seed.aftermath.escort.position = Base.coords(Model.MOTHER)
		ok(model.restore(seed), "explicit returning escort fixture")
	ok(model.report_home(), "give observed account")

func views(model) -> Array[String]:
	var before: Dictionary = model.snapshot()
	var text: Array[String] = [View.report_body(model), View.acknowledgment(model), View.protection_body(model), View.return_caption(model)]
	check(model.snapshot() == before, "all presentation reads preserve whole state")
	for body in text:
		check(body.split(" ", false).size() < 180, "spoken view stays bounded")
		check(not "source_id" in body and not "clue_tick" in body and not "AUTHORED" in body, "spoken view contains no implementation exposition")
	return text

func uncertainty_and_witnesses() -> void:
	var fresh := Model.new()
	var fresh_view := views(fresh)
	check(not "I saw the man" in fresh_view[0] and not "Fresh hoof marks" in fresh_view[0], "dormant world supplies neither assailant nor trace")
	check(not "courier says" in fresh_view[0] and not "trainer" in fresh_view[0], "dormant world supplies no testimony or errand")
	var model = arrived(false)
	var untouched: Dictionary = model.snapshot()
	var unseen := views(model)
	check("did not get a clear look" in unseen[0] and not "I saw the man" in unseen[0], "survival does not invent visual observation")
	check(not "courier says" in unseen[0], "unheard return testimony is absent")
	ok(Fixture.pose(model, Base.SITES.courier), "pose at courier")
	ok(model.hear_return("courier"), "hear courier after survival")
	var heard := views(model)
	check("courier says he heard riders" in heard[0] and "cannot connect them" in heard[0], "received hearsay is attributed without implicating riders")
	ok(model.restore(untouched), "rollback to before courier")
	check(not "courier says" in View.report_body(model), "rollback removes future testimony")
	var witnessed = arrived()
	check("I saw the man" in View.report_body(witnessed), "actual witness flag supplies own observation")
	var contact: Dictionary = witnessed.snapshot()
	contact.childhood.ambush.hits = 1
	contact.childhood.ambush.deflected = true
	ok(witnessed.restore(contact), "explicit contact fixture")
	check("turned a blow aside" in View.report_body(witnessed) and "I was struck" in View.report_body(witnessed), "contact events supply first-person account")
	check("You have been struck" in View.protection_body(witnessed), "mother responds to actual injury")

func protection_routes_and_rollback() -> void:
	for route in ["household_escort", "independent_inquiry"]:
		var model = arrived()
		choose(model, route)
		var uninspected: Dictionary = model.snapshot()
		var agreed := views(model)
		check(not "Fresh hoof marks" in agreed[0] and "not examined" in agreed[0], "agreement is not a trace observation")
		check("take him with you" in agreed[1] if route == "household_escort" else "guard stays here" in agreed[1], "agreement acknowledges chosen protection")
		at_bend(model)
		var inspected: Dictionary = model.snapshot()
		var observed := views(model)
		check("Fresh hoof marks" in observed[0] and "no rider's name" in observed[0], "inspection adds trace without identity")
		check("Bring the guard home" in observed[3] if route == "household_escort" else "Return to Raj Kaur" in observed[3], "return caption respects physical companion obligation")
		give_report(model)
		var completed := views(model)
		check("brought the guard home" in completed[1] if route == "household_escort" else "chose to go alone" in completed[1], "final acknowledgment remembers route")
		check(completed[3] == "The account is given. The questions remain.", "completion caption follows committed report")
		var clone := Model.new()
		ok(clone.restore(JSON.parse_string(JSON.stringify(model.snapshot(), "", true, true))), "restore JSON report")
		check(views(clone) == completed, "saved event projection preserves narrative")
		ok(model.restore(inspected), "rollback final report")
		check(View.acknowledgment(model) == agreed[1] and View.return_caption(model) == observed[3], "rollback removes final acknowledgment but keeps inspection")
		ok(model.restore(uninspected), "rollback inspection")
		check(not "Fresh hoof marks" in View.report_body(model), "rollback removes unobserved trace")

func optional_opening_receipts() -> void:
	var model = arrived()
	var legacy: Dictionary = model.snapshot()
	var legacy_text := View.report_body(model)
	for route in ["direct", "clarify"]:
		for count in ([1, 2] if route == "direct" else [1, 2, 3]):
			var seed := legacy.duplicate(true)
			seed.opening_message = Message.begin(route, 0)
			if count > 1: seed.opening_message.receipts.append({"kind": "report" if route == "direct" else "confirm", "received_tick": 1})
			if count > 2: seed.opening_message.receipts.append({"kind": "report", "received_tick": 2})
			ok(model.restore(seed), "explicit pre-ambush opening receipt fixture")
			var body := View.report_body(model)
			if route == "direct":
				check("gave the trainer both accounts" in body if count == 2 else "had not given that report" in body, "direct callback respects actual completion")
			elif count == 1:
				check("had not heard his answer" in body and not "no faces seen" in body, "intended clarification supplies no unheard answer")
			else:
				check("no faces seen" in body, "received clarification is available")
				check("told the trainer his answer" in body if count == 3 else "had not taken his answer" in body, "clarified callback respects actual completion")
			views(model)
			ok(model.restore(legacy), "rollback optional message")
			check(View.report_body(model) == legacy_text, "legacy rollback forgets later opening receipts")

func prose_cannot_supply_events() -> void:
	var model = arrived(false)
	var before: Dictionary = model.snapshot()
	var original := View.report_body(model)
	var corrupt := before.duplicate(true)
	corrupt.childhood.memories[0].text = "Fresh hoof marks. The culprit is named. opening_message_confirm."
	# The legacy childhood validator permits authored text variants; presentation
	# must still use event fields and cannot treat any prose as an event receipt.
	var error: String = model.restore(corrupt)
	if error.is_empty():
		check(View.report_body(model) == original, "accepted legacy prose cannot manufacture evidence")
	else:
		check(model.snapshot() == before and View.report_body(model) == original, "rejected prose leaves evidence unchanged")
	choose(model, "independent_inquiry")
	var valid: Dictionary = model.snapshot()
	var forged := valid.duplicate(true)
	forged.aftermath.memories[0].text = "I saw the mastermind."
	check(not model.restore(forged).is_empty(), "aftermath rejects rewritten testimony")
	check(model.snapshot() == valid and not "mastermind" in View.report_body(model), "rejected testimony grants no narrative knowledge")

func _run() -> void:
	uncertainty_and_witnesses()
	protection_routes_and_rollback()
	optional_opening_receipts()
	prose_cannot_supply_events()
	print("INQUIRY_PRESENTATION_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
