extends RefCounted
## Explicit completed-inquiry fixture, NOT evidence of another played childhood.
const Previous := preload("res://tests/aftermath_fixture.gd")
const Story := preload("res://childhood/aftermath_state.gd")
const Base := preload("res://childhood/childhood_state.gd")
const Rules := preload("res://territory/misl_rules.gd")

static func complete() -> Dictionary:
	var model:=Story.new()
	assert(model.restore(Previous.survived()).is_empty())
	for id in ["steward","courier"]:
		assert(Previous.pose(model,Base.SITES[id]+Vector3.RIGHT).is_empty())
		assert(model.hear_return(id).is_empty())
	assert(Previous.pose(model,Story.MOTHER+Vector3.RIGHT).is_empty())
	assert(model.hear_offer().is_empty())
	assert(model.decide_protection("independent_inquiry").is_empty())
	assert(Previous.pose(model,Story.CLUE).is_empty())
	assert(model.inspect_bend().is_empty())
	assert(Previous.pose(model,Story.MOTHER+Vector3.RIGHT).is_empty())
	assert(model.report_home().is_empty())
	assert(Previous.pose(model,Rules.QUARTERMASTER+Vector3(0,0,-1)).is_empty())
	return model.snapshot()
