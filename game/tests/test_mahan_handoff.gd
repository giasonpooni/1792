extends SceneTree
## Opt-in Mahan→Buddh handoff cutter: default refuse, no silent journal/map merge.
const Handoff := preload("res://mahan/mahan_handoff.gd")
const History := preload("res://mahan/mahan_history_state.gd")
const Mahan := preload("res://mahan/mahan_state.gd")
const Childhood := preload("res://childhood/childhood_state.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _rich_mahan() -> History:
	var model := History.new()
	model.enable_riding()
	var s: Dictionary = model.snapshot()
	s.player.position = Mahan.coords(Mahan.SITES.camp_table)
	s.actors[Mahan.ACTOR_ID].position = Mahan.coords(Mahan.SITES.camp_table)
	check(model.restore(s).is_empty(), "pose restore for handoff fixture")
	check(model.dispatch_scout("ford").is_empty(), "dispatch ford for handoff")
	check(model.dispatch_scout("gujranwala_settlement").is_empty(), "dispatch settlement for handoff")
	model.advance(Mahan.REPORT_DELAY)
	check("ford" in model.known_nodes(), "ford known")
	check("gujranwala_settlement" in model.known_nodes(), "settlement known")
	check(not model.journal().is_empty(), "mahan journal populated")
	return model

func _default_refuse() -> void:
	check(not Handoff.can_handoff(), "can_handoff empty → false")
	check(not Handoff.can_handoff({}), "can_handoff {} → false")
	var denied := Handoff.fresh_controller()
	check(denied.opt_in == false, "fresh controller opt_in false")
	check(denied.allowlist_report_ids.is_empty(), "fresh allowlist empty")
	check(denied.approve_apply == false, "fresh approve_apply false")
	check(not Handoff.can_handoff(denied), "fresh controller cannot handoff")
	var prop := Handoff.propose_transfer(["scout_ford.report"], {}, denied)
	check(prop.ok == false, "propose default refuse ok=false")
	check(str(prop.error).begins_with("Refuse:"), "propose default refuse message")
	check(prop.error == Handoff.REFUSE_DEFAULT, "propose uses REFUSE_DEFAULT")
	var applied := Handoff.apply_transfer({"schema": "mahan-handoff-proposal.v1"}, denied, {})
	check(applied.ok == false, "apply default refuse ok=false")
	check(applied.error == Handoff.REFUSE_DEFAULT, "apply uses REFUSE_DEFAULT")
	# opt_in alone without allowlist still refuses
	var half := Handoff.fresh_controller()
	half.opt_in = true
	check(not Handoff.can_handoff(half), "opt_in without allowlist → false")
	var prop2 := Handoff.propose_transfer(["scout_ford.report"], {}, half)
	check(prop2.ok == false, "propose without allowlist refuses")
	check(prop2.error == Handoff.REFUSE_NO_ALLOWLIST, "propose REFUSE_NO_ALLOWLIST")

func _reject_wholesale_journal() -> void:
	var model := _rich_mahan()
	var journal: Array = model.journal()
	check(not journal.is_empty(), "fixture journal non-empty")
	var ctrl := Handoff.fresh_controller()
	ctrl.opt_in = true
	ctrl.allowlist_report_ids = ["scout_ford.report"]
	ctrl.approve_apply = true
	check(Handoff.can_handoff(ctrl), "controller ready for journal refuse tests")
	# Helper always refuses wholesale journal merge.
	var err := Handoff.refuse_wholesale_journal_merge(journal, ctrl)
	check(err == Handoff.REFUSE_WHOLESALE_JOURNAL, "helper refuses populated journal")
	check(not Handoff.refuse_wholesale_journal_merge([], ctrl).is_empty(), "helper refuses empty merge op too")
	# propose rejects wildcard / journal tokens
	for bad_id in ["*", "all", "journal", "ALL"]:
		var bad := Handoff.propose_transfer([bad_id], model.snapshot(), ctrl)
		check(bad.ok == false, "propose rejects wholesale token: " + bad_id)
		check(bad.error == Handoff.REFUSE_WHOLESALE_JOURNAL, "wholesale token message: " + bad_id)
	# apply rejects merge_journal_wholesale / journal_texts even when opted in
	var packet := Handoff.propose_transfer(["scout_ford.report"], model.snapshot(), ctrl)
	check(packet.ok, "valid propose for apply journal gates")
	check(packet.packet.journal_texts.is_empty(), "proposal carries no journal texts")
	var merge_flag := Handoff.apply_transfer(packet.packet, ctrl, {"merge_journal_wholesale": true})
	check(merge_flag.ok == false, "apply refuses merge_journal_wholesale")
	check(merge_flag.error == Handoff.REFUSE_WHOLESALE_JOURNAL, "merge_journal_wholesale message")
	var texts := Handoff.apply_transfer(packet.packet, ctrl, {"journal_texts": journal})
	check(texts.ok == false, "apply refuses journal_texts payload")
	check(texts.error == Handoff.REFUSE_JOURNAL_TEXTS, "journal_texts message")
	# Smuggled journal_texts on packet itself
	var smuggle: Dictionary = packet.packet.duplicate(true)
	smuggle.journal_texts = journal.duplicate(true)
	var smuggled := Handoff.apply_transfer(smuggle, ctrl, {"accept_report_dry_run": true})
	check(smuggled.ok == false, "apply refuses packet with journal_texts")
	check(smuggled.error == Handoff.REFUSE_JOURNAL_TEXTS, "smuggled journal_texts message")

func _reject_known_nodes_without_allowlist() -> void:
	var model := _rich_mahan()
	var nodes: Array = model.known_nodes()
	check("gujranwala_settlement" in nodes, "fixture has settlement node")
	var ctrl := Handoff.fresh_controller()
	ctrl.opt_in = true
	ctrl.allowlist_report_ids = ["scout_ford.report", "scout_gujranwala_settlement.report"]
	ctrl.approve_apply = true
	# allowlist_known_nodes stays empty → graft refuses
	check(ctrl.allowlist_known_nodes.is_empty(), "known_nodes allowlist empty by default")
	var packet := Handoff.propose_transfer(["scout_ford.report"], model.snapshot(), ctrl)
	check(packet.ok, "propose ok for node graft test")
	check(packet.packet.known_nodes.is_empty(), "proposal does not include known_nodes")
	var fake_bag := {"known_places": ["sukerchakia_home"]}
	var grafted := Handoff.apply_transfer(packet.packet, ctrl, {
		"knowledge_bag": fake_bag,
		"graft_known_nodes": nodes.duplicate()
	})
	check(grafted.ok == false, "apply refuses known_nodes graft without allowlist")
	check(str(grafted.error).begins_with(Handoff.REFUSE_KNOWN_NODES), "known_nodes refuse message")
	check(fake_bag.known_places == ["sukerchakia_home"], "fake bag unchanged after refuse")
	# Packet that smuggles known_nodes is refused
	var smuggle: Dictionary = packet.packet.duplicate(true)
	smuggle.known_nodes = nodes.duplicate()
	var smuggled := Handoff.apply_transfer(smuggle, ctrl, {"knowledge_bag": fake_bag})
	check(smuggled.ok == false, "apply refuses packet smuggling known_nodes")
	check(str(smuggled.error).begins_with(Handoff.REFUSE_KNOWN_NODES), "smuggled nodes message")
	# Childhood authority still pristine / no auto knowledge
	var child := Childhood.new()
	var before: Dictionary = child.snapshot()
	check(child.snapshot().player.known_places == ["sukerchakia_home"], "childhood places stay home-only")
	check(child.snapshot() == before, "childhood untouched by handoff cutter")

func _opt_in_propose_and_dry_run() -> void:
	var model := _rich_mahan()
	var ctrl := Handoff.fresh_controller()
	ctrl.opt_in = true
	ctrl.allowlist_report_ids = ["scout_ford.report", "scout_gujranwala_settlement.report"]
	check(Handoff.can_handoff(ctrl), "opt-in + allowlist → can_handoff")
	# ID not on allowlist refused
	var foreign := Handoff.propose_transfer(["scout_ridge.report"], model.snapshot(), ctrl)
	check(foreign.ok == false, "propose refuses id outside allowlist")
	check(str(foreign.error).begins_with(Handoff.REFUSE_ID_NOT_ALLOWED), "outside allowlist message")
	# Valid propose
	var prop := Handoff.propose_transfer(
		["scout_ford.report", "scout_gujranwala_settlement.report"],
		model.snapshot(),
		ctrl
	)
	check(prop.ok, "propose selected ids ok")
	check(prop.packet.report_ids.size() == 2, "packet has two report ids")
	check(prop.packet.journal_texts.is_empty(), "packet journal_texts empty")
	check(prop.packet.known_nodes.is_empty(), "packet known_nodes empty")
	check(prop.packet.historical_outcome_fixed == true, "packet keeps outcome fixed")
	check(prop.packet.silent_merge == false, "packet silent_merge false")
	check(prop.packet.source_profile == "mahan.v1", "packet source profile")
	check(prop.packet.target_actor_hint == "ranjit_singh", "packet target hint")
	# apply without approve_apply refuses
	var no_approve := Handoff.apply_transfer(prop.packet, ctrl, {})
	check(no_approve.ok == false, "apply without approve_apply refuses")
	check(no_approve.error == Handoff.REFUSE_NO_APPROVE_APPLY, "approve_apply message")
	# approve + dry-run success (no slot write)
	ctrl.approve_apply = true
	var bag := {"transferred_report_ids": []}
	var applied := Handoff.apply_transfer(prop.packet, ctrl, {
		"knowledge_bag": bag,
		"accept_report_dry_run": true
	})
	check(applied.ok, "dry-run apply ok")
	check(applied.receipt.dry_run == true, "receipt is dry_run")
	check(applied.receipt.applied == false, "live applied stays false")
	check(applied.receipt.childhood_slot_written == false, "no childhood slot write")
	check(applied.receipt.journal_texts_copied == 0, "no journal texts copied")
	check(applied.receipt.known_nodes_copied == 0, "no known_nodes copied")
	check(applied.receipt.historical_outcome_fixed == true, "receipt outcome fixed")
	check("scout_ford.report" in applied.bag.transferred_report_ids, "dry-run records ford id")
	check("scout_gujranwala_settlement.report" in applied.bag.transferred_report_ids, "dry-run records settlement id")

func _refuse_childhood_slot_and_outcome() -> void:
	var ctrl := Handoff.fresh_controller()
	ctrl.opt_in = true
	ctrl.allowlist_report_ids = ["scout_ford.report"]
	ctrl.approve_apply = true
	var prop := Handoff.propose_transfer(["scout_ford.report"], {"profile": "mahan.v1"}, ctrl)
	check(prop.ok, "propose for slot/outcome tests")
	var slot := Handoff.apply_transfer(prop.packet, ctrl, {
		"childhood_save_path": Handoff.CHILDHOOD_SAVE_HINT
	})
	check(slot.ok == false, "apply refuses childhood_save_path")
	check(slot.error == Handoff.REFUSE_CHILDHOOD_SLOT, "childhood slot message")
	ctrl.allow_childhood_slot_write = true
	var slot2 := Handoff.apply_transfer(prop.packet, ctrl, {"write_childhood_slot": true})
	check(slot2.ok == false, "apply refuses even when slot-write flag set")
	check(slot2.error == Handoff.REFUSE_CHILDHOOD_SLOT, "flagged slot write still refused")
	ctrl.allow_childhood_slot_write = false
	var outcome := Handoff.apply_transfer(prop.packet, ctrl, {
		"alter_historical_outcome": true
	})
	check(outcome.ok == false, "apply refuses alter_historical_outcome")
	check(outcome.error == Handoff.REFUSE_ALTER_OUTCOME, "alter outcome message")
	var outcome2 := Handoff.apply_transfer(prop.packet, ctrl, {
		"historical_outcome": {"fixed": false}
	})
	check(outcome2.ok == false, "apply refuses historical_outcome payload")
	check(outcome2.error == Handoff.REFUSE_HISTORICAL_OUTCOME, "historical_outcome message")
	var silent := Handoff.apply_transfer(prop.packet, ctrl, {"silent_merge": true})
	check(silent.ok == false, "apply refuses silent_merge")
	check(silent.error == Handoff.REFUSE_SILENT_MERGE, "silent_merge message")
	# Wrong source profile
	var bad_src := Handoff.propose_transfer(["scout_ford.report"], {"profile": "childhood.v1"}, ctrl)
	check(bad_src.ok == false, "propose refuses non-mahan source")
	check(bad_src.error == Handoff.REFUSE_BAD_SOURCE, "bad source message")
	# Mahan authority still has no silent merge methods
	var model := Mahan.new()
	check(not model.has_method("handoff_to_childhood"), "no handoff_to_childhood on authority")
	check(not model.has_method("merge_knowledge"), "no merge_knowledge on authority")
	check(not model.has_method("handoff_to_buddh"), "no handoff_to_buddh on authority")

func _run() -> void:
	_default_refuse()
	_reject_wholesale_journal()
	_reject_known_nodes_without_allowlist()
	_opt_in_propose_and_dry_run()
	_refuse_childhood_slot_and_outcome()
	print("MAHAN_HANDOFF_TESTS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
