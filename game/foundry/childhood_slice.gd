extends "res://tests/test_childhood.gd"
## Reuses the existing actual keyboard/physics journey. No domain pose fixtures.
const Perspective := preload("res://childhood/perspective_view.gd")
const MILESTONES := [
	"walk and view practice precede reading", "E acquires letter physically",
	"courier account attributed", "two oral accounts open riding",
	"all three physical gates", "actual guard input checks telegraphed practice strikes",
	"counter opens hunting lesson", "physical sight and inspection of track 1",
	"physical sight and inspection of track 2", "physical sight and inspection of track 3",
	"quiet quarry observation precedes ambush", "actual movement escapes to the courtyard",
	"save resumes before ambush without losing lessons"
]
var samples: Array = []

func check(value: bool, label: String) -> void:
	super.check(value, label)
	if not value or not label in MILESTONES: return
	for node in root.get_children():
		if not node.has_node("ChildhoodChapter"): continue
		var model = node.get_node("ChildhoodChapter").model
		var state: Dictionary = model.snapshot()
		var memories: Array = model.journal()
		samples.append({"milestone": label, "state": state, "memories": memories,
			"perspective": Perspective.project(memories, int(model.progress().tick))})
		return

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Require request and observation path.")
		quit(2)
		return
	var request = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not request is Dictionary or not request.has_all(["nonce", "source_lock_id"]):
		quit(2)
		return
	# Base SAVE is a regression-only user path. The binding runs in an isolated
	# project/user-data directory; no player saves are touched.
	await _journey()
	var output := {"schema": "1792.childhood-slice-observations.v1",
		"nonce": request.nonce, "source_lock_id": request.source_lock_id,
		"engine_version": Engine.get_version_info().string,
		"source_class": "authored_source_informed_prototype",
		"capture_class": "actual_input_driven_journey",
		"samples": samples, "assertions": passed, "failures": failed,
		"historical_authentication": false, "human_playability_review": false}
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		quit(2)
		return
	file.store_string(JSON.stringify(output, "", true, true))
	file.close()
	for suffix in ["", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))
	print("CHILDHOOD_SLICE_CAPTURE: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
