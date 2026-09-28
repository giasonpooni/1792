extends RefCounted
## A detached save envelope, never a running world or an authority for game facts.
const Model := preload("res://childhood/aftermath_state.gd")
const LIMIT := 196608
const SCHEMA := "1792.chapter-checkpoint.v1"

static func validate(value: Variant) -> String:
	if not value is Dictionary or value.size() != 4 or value.get("schema") != SCHEMA:
		return "Malformed checkpoint envelope."
	if value.get("reason") not in ["return_trail","courtyard_return"]: return "Unsupported checkpoint reason."
	var camera: Variant = value.get("camera")
	if not camera is Array or camera.size() != 2: return "Invalid checkpoint camera."
	for number in camera:
		if not Model.Riding.finite_number(number): return "Nonfinite checkpoint camera."
	if camera[0] < -0.9 or camera[0] > 0.5 or absf(camera[1]) > PI + 1e-6: return "Checkpoint camera outside limits."
	var staged := Model.new()
	var error := staged.restore(value.get("snapshot"))
	if not error.is_empty(): return error
	if staged.mounted(): return "Checkpoint must be on foot."
	if value.reason == "return_trail" and (staged.stage() != "ready" or not staged.near("quarry",6.0)): return "Return-trail checkpoint is not before the encounter."
	if value.reason == "courtyard_return" and (staged.stage() != "escaped" or not staged.near("home",5.0) or not staged.aftermath().memories.is_empty()):
		return "Courtyard checkpoint is not before the aftermath."
	return ""

static func write(path: String, snapshot: Dictionary, view: Vector3, reason: String) -> String:
	var envelope := {"schema":SCHEMA, "reason":reason, "snapshot":snapshot.duplicate(true),
		"camera":[clampf(view.x,-0.9,0.5),wrapf(view.y,-PI,PI)]}
	var error := validate(envelope)
	if not error.is_empty(): return error
	var text := JSON.stringify(envelope,"",true,true)
	if text.to_utf8_buffer().size() > LIMIT: return "Checkpoint exceeds size budget."
	var file := FileAccess.open(path + ".tmp",FileAccess.WRITE)
	if file == null: return "Cannot create checkpoint temporary file."
	file.store_string(text)
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK: return "Checkpoint write failed."
	status = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"),ProjectSettings.globalize_path(path))
	return "" if status == OK else "Checkpoint replacement failed."

static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"error":"No checkpoint saved yet. Continue the lesson or load a manual save."}
	if file.get_length() > LIMIT:
		file.close()
		return {"error":"Checkpoint exceeds size budget."}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return {"error":"Malformed checkpoint JSON."}
	var error := validate(parser.data)
	if not error.is_empty(): return {"error":error}
	return {"error":"", "envelope":parser.data.duplicate(true)}
