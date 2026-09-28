extends RefCounted
## Narrative sequencing contract, not the playable Mahan campaign or a second live world.
## A caller-validated present is retained as JSON; no old-world inventory/knowledge merges.
const Names := preload("res://characters/character_names.gd")
const ID := "mahan_singh.fixed_history.v1"
const VERSION := "historical-interlude.v1"
const GATE := "pre_lahore_1797_1798"
const MAHAN := "mahan_singh"
const FIXED_END := "mahan_dies_buddh_succeeds"
# Authoring milestones drawn from the supplied excerpt; no mission implementation implied.
const BEATS := ["inherit_misl_command", "ramgarhia_alliance", "kanhaiya_conflict", "final_orders"]
const LIMIT := 262144
var _state: Dictionary = {}

static func _json_data(value: Variant, depth: int = 0) -> bool:
	if depth > 32: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING: return true
		TYPE_FLOAT: return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not _json_data(item,depth+1): return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _json_data(value[key],depth+1): return false
			return true
	return false

static func _anchor_error(anchor: Variant, present: Variant, validator: Callable) -> String:
	if not anchor is Dictionary or anchor.size() != 2 or anchor.get("chapter_id") != GATE:
		return "This interlude belongs at the declared pre-Lahore chapter gate."
	if typeof(anchor.get("year")) not in [TYPE_INT,TYPE_FLOAT] or (anchor.year != 1797 and anchor.year != 1798):
		return "The narrative anchor must declare 1797 or 1798."
	if not present is Dictionary or not _json_data(present): return "Present snapshot is not bounded JSON data."
	if not validator.is_valid(): return "A domain validator for the suspended campaign is required."
	# Validate a copy: provider validation cannot silently alter the retained campaign.
	var error: Variant = validator.call(present.duplicate(true))
	if not error is String: return "The campaign validator must return an error string."
	if not error.is_empty(): return error
	if present.get("schema_version") != "world-state.v1": return "Unsupported world contract."
	if not present.get("player") is Dictionary or present.player.get("character_id") != Names.HERO_ID:
		return "Buddh must be the suspended protagonist."
	if not present.get("game_time") is Dictionary or present.game_time.get("year") != anchor.year:
		return "The story anchor cannot relabel another year's world."
	return ""

func begin(anchor: Dictionary, present: Dictionary, validator: Callable) -> String:
	if not _state.is_empty(): return "An interlude session is already bound."
	var error := _anchor_error(anchor,present,validator)
	if not error.is_empty(): return error
	var text := JSON.stringify(present,"",true,true)
	if text.to_utf8_buffer().size() > LIMIT: return "Suspended campaign exceeds the size budget."
	_state = {"schema_version":VERSION,"interlude_id":ID,"anchor":anchor.duplicate(true),
		"present_json":text,"present_sha256":text.sha256_text(),"phase":"playing",
		"completed_beats":[],"outcome":""}
	return ""

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func controlled_actor() -> String:
	if _state.is_empty(): return ""
	return Names.HERO_ID if _state.phase in ["buddh_reprise","complete","returned"] else MAHAN

func next_beat() -> String:
	if _state.is_empty() or _state.phase != "playing" or _state.completed_beats.size() == BEATS.size(): return ""
	return BEATS[_state.completed_beats.size()]

func complete_beat(id: String) -> String:
	if id.is_empty() or id != next_beat(): return "Complete the current authored beat in order."
	_state.completed_beats.append(id)
	return ""

func fail_attempt() -> String:
	if _state.is_empty() or _state.phase != "playing" or next_beat().is_empty(): return "No playable beat attempt is active."
	_state.phase = "retry"
	return ""

func retry_attempt() -> String:
	if _state.is_empty() or _state.phase != "retry": return "No failed attempt to retry."
	_state.phase = "playing"
	return "" # Scene-specific checkpoints must be restored by the future mission provider.

func conclude_fixed_history() -> String:
	if _state.is_empty() or _state.phase != "playing" or _state.completed_beats.size() != BEATS.size():
		return "Mahan's required story beats are not complete."
	_state.outcome = FIXED_END
	_state.phase = "buddh_reprise"
	return "" # Fixed historical death leads into the son's reprise, not a game-over screen.

func complete_buddh_reprise() -> String:
	if _state.is_empty() or _state.phase != "buddh_reprise": return "The return through Buddh's beginning is not active."
	_state.phase = "complete"
	return ""

func resume_buddh() -> Dictionary:
	if _state.is_empty() or _state.phase != "complete": return {"error":"Finish the fixed ending and childhood reprise before resuming the suspended present."}
	var parser := JSON.new()
	if parser.parse(_state.present_json) != OK: return {"error":"Retained present cannot be decoded."}
	var result := {"error":"","anchor":_state.anchor.duplicate(true),
		"world_json":_state.present_json,"world":parser.data,
		"story_receipt":{"id":ID+":"+_state.present_sha256,"interlude_id":ID,"outcome":FIXED_END,
			"scope":"viewer_story_progress","item_grants":[],"character_knowledge_grants":[]}}
	_state.phase = "returned"
	return result # Host resumes its suspended scene and records the receipt, not a world-state patch.

func allows_lahore_transition() -> bool:
	return not _state.is_empty() and _state.phase == "returned"

func restore(value: Variant, validator: Callable) -> String:
	var error := validate(value,validator)
	if not error.is_empty(): return error
	_state = value.duplicate(true)
	_state.anchor.year = int(_state.anchor.year)
	return ""

static func validate(value: Variant, validator: Callable) -> String:
	if not value is Dictionary or value.size() != 8: return "Malformed interlude snapshot."
	for key in ["schema_version","interlude_id","present_json","present_sha256","phase","outcome"]:
		if not value.get(key) is String: return "Malformed interlude field."
	if value.schema_version != VERSION or value.interlude_id != ID: return "Unknown historical interlude."
	if value.phase not in ["playing","retry","buddh_reprise","complete","returned"]: return "Unknown interlude phase."
	if not value.get("completed_beats") is Array or value.completed_beats.size() > BEATS.size(): return "Invalid interlude progress."
	for i in range(value.completed_beats.size()):
		if value.completed_beats[i] != BEATS[i]: return "Reordered, duplicated or unknown story beat."
	if value.phase in ["buddh_reprise","complete","returned"]:
		if value.completed_beats != BEATS or value.outcome != FIXED_END: return "The fixed historical ending cannot be changed."
	elif value.outcome != "": return "Historical ending before story completion."
	if value.phase == "retry" and value.completed_beats.size() == BEATS.size(): return "Fixed ending is not a failed mission."
	if value.present_json.to_utf8_buffer().size() > LIMIT or value.present_json.sha256_text() != value.present_sha256:
		return "Retained present binding is invalid."
	var parser := JSON.new()
	if parser.parse(value.present_json) != OK: return "Malformed retained present JSON."
	return _anchor_error(value.get("anchor"),parser.data,validator)
