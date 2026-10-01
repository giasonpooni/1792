extends SceneTree
const P := preload("res://childhood/perspective_view.gd")
var passed := 0
func check(value: bool) -> void:
	if not value:
		push_error("Perspective check failed")
		quit(1)
	else: passed += 1
func _initialize() -> void:
	var memories: Array = []
	check(P.project(memories, -1).status == "REFUSED")
	var prior := P.project(memories, 0)
	check(prior.weights == [0.5, 0.5] and prior.cause_identity == null)
	memories.append({"id":"courier", "source_id":"fictional_courier", "channel":"testimony", "received_tick":10, "text":"Authored report"})
	check(P.project(memories, 9).status == "REFUSED")
	var view := P.project(memories, 10)
	check(is_equal_approx(view.weights[1], 0.7))
	check(view.cause_identity == null and not view.calibrated_probability)
	check(P.project(memories, 10) == view)
	memories.append(memories[0].duplicate())
	check(P.project(memories, 11).status == "REFUSED")
	memories.pop_back()
	memories[0].received_tick = true
	check(P.project(memories, 10).status == "REFUSED")
	print("PERSPECTIVE_VIEW: %d passed, 0 failed" % passed)
	quit(0)
