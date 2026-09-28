extends RefCounted
## Isolated Mahan Singh field-command profile. Separate actor, save slot and memories.
## Does not extend childhood/Lahore authorities and never merges knowledge into Buddh.
## Recon reports mirror Lahore custody shape (observed_at / arrives_at / delivered) without
## rewriting command_state — player knowledge updates only on delivery.
const ACTOR_ID := "mahan_singh"
const PROFILE := "mahan.v1"
const SAVE_PATH := "user://1792-mahan-v1.json"
const LIMIT := 131072
const REPORT_DELAY := 120
const DISPATCH_COST := 1
const MARCH_COST := 2
const MARCH_TICKS := 30
const PROVISIONS_MAX := 12
const NODES := {
	"camp": Vector3(-3, 0.14, 2),
	"ford": Vector3(10, 0.14, -8),
	"ridge": Vector3(16, 0.14, -16),
	"gujranwala_fort_road": Vector3(-10, 0.14, 8),
	"gujranwala_camp": Vector3(-16, 0.14, 14),
	"gujranwala_settlement": Vector3(-20, 0.14, 20)
}
const ADJACENT := {
	"camp": ["ford", "gujranwala_fort_road"],
	"ford": ["camp", "ridge"],
	"ridge": ["ford"],
	"gujranwala_fort_road": ["camp", "gujranwala_camp"],
	"gujranwala_camp": ["gujranwala_fort_road", "gujranwala_settlement"],
	"gujranwala_settlement": ["gujranwala_camp"]
}
const NODE_LABELS := {
	"camp": "field camp",
	"ford": "ford",
	"ridge": "ridge",
	"gujranwala_fort_road": "Gujranwala fort road",
	"gujranwala_camp": "Gujranwala camp",
	"gujranwala_settlement": "Gujranwala town"
}
const SITES := {
	"camp_table": Vector3(0, 0.14, 0),
	"camp": NODES.camp,
	"ford": NODES.ford,
	"ridge": NODES.ridge,
	"gujranwala_fort_road": NODES.gujranwala_fort_road,
	"gujranwala_camp": NODES.gujranwala_camp,
	"gujranwala_settlement": NODES.gujranwala_settlement
}
# Authored fiction informed by late-campaign / delayed-report pattern; not quotations.
const SCOUT_TEXTS := {
	"ford": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "Riders returned from the ford after dark. The crossing is passable; opposite-bank watchfires were few, but they could not confirm the fort road beyond."
	},
	"ridge": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "The ridge detachment came in late. Dust hangs on the far road from the crest; the fort garrison itself remains unverified."
	},
	"gujranwala_fort_road": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "The fort-road detachment returned. Tracks and pack dust run toward Gujranwala; the home settlement itself was not entered, and the garhi motif remains unverified from this approach."
	},
	"gujranwala_camp": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "Riders reached the household staging ground outside Gujranwala. Hearth smoke rises toward the walled town; the column can stage here without claiming a surveyed street plan."
	},
	"gujranwala_settlement": {
		"source_id": "fictional_field_scout",
		"channel": "delayed_report",
		"text": "The town approach is open from the staging ground. Gujranwala remains Sukerchakia home-ground in delayed account only — this report does not invent a street survey or open a town combat map."
	}
}

const DECISIONS := {
	"advance_scouts": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I ordered the horse column forward along the reconnoitred path. The fort road remains uncertain; I am acting on delayed scout custody, not live sight."
	},
	"hold_for_corroboration": {
		"source_id": "self",
		"channel": "command_decision",
		"text": "I held the column at camp and waited for further corroboration. Delay preserves the horse line; delivered scout accounts still leave the fort unverified."
	}
}
static func node_label(node_id: String) -> String:
	return str(NODE_LABELS.get(node_id, node_id))

static func scout_targets() -> Array:
	return SCOUT_TEXTS.keys()

var _state: Dictionary

func _init() -> void:
	_state = _initial()
