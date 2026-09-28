extends RefCounted
## EXPLICIT DOMAIN/RENDER FIXTURE. Does not claim a played childhood journey.
## The unchanged childhood suite covers the full movement/input-driven tutorial.
const Base := preload("res://childhood/childhood_state.gd")

static func pose(model, p: Vector3) -> String:
	var value: Dictionary = model.snapshot()
	value.player.position = Base.coords(p)
	value.actors[Base.Names.HERO_ID].position = value.player.position.duplicate()
	return model.restore(value)

static func precursor() -> Dictionary:
	var model := Base.new()
	pose(model,Base.SITES.letter+Vector3.RIGHT)
	assert(model.inspect_letter().is_empty())
	assert(model.hear("courier").is_empty())
	pose(model,Base.SITES.steward+Vector3.RIGHT)
	assert(model.hear("steward").is_empty())
	var value := model.snapshot()
	value.childhood.walked = 6.0
	value.childhood.looked = 1.0
	value.childhood.ride_gate = 3
	value.childhood.parries = 2
	value.childhood.counters = 1
	assert(model.restore(value).is_empty())
	for i in range(1,4):
		model.advance()
		pose(model,Base.SITES["track_%d" % i])
		assert(model.inspect_track("track_%d" % i).is_empty())
	pose(model,Base.SITES.quarry+Vector3(0,0,2.0))
	return model.snapshot() # Before observing quarry so the actual E interaction can capture a checkpoint.

static func survived() -> Dictionary:
	var model := Base.new()
	assert(model.restore(precursor()).is_empty())
	assert(model.observe_quarry(true).is_empty())
	pose(model,Base.SITES.bend)
	assert(model.start_ambush().is_empty())
	model.witness_threat()
	model.advance()
	pose(model,Base.SITES.home)
	assert(model.reach_home().is_empty())
	return model.snapshot()
