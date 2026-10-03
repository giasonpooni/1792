# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
extends RefCounted
## Original scene dialogue; reads the finite round without adding memories or rewards.

static func action_line(action: String, water: Dictionary) -> String:
	var stored: int = int(water.get("ledger", {}).get("stored", 0))
	match action:
		"begin": return "Quartermaster · Two loads from the east well, Buddh. Bring each one back before drawing the next."
		"draw":
			return "Buddh · Steady now." if stored == 0 else "Buddh · Once more."
		"cancel": return "Buddh · Set it down. I can begin again when I am ready."
		"deposit":
			return "Quartermaster · One load in. The empty carrier is yours for the second." if stored < 6 else "Quartermaster · That is both loads. Set the carrier down, Buddh. The household has its water."
	return ""

static func filled_line(water: Dictionary) -> String:
	return "Buddh · There is the weight. Walk it home; no riding with the open load." if int(water.ledger.stored) == 0 else "Buddh · Someone walks this lane every day. Today I feel the weight."

static func well_body(water: Dictionary) -> String:
	if water.is_empty(): return "The household carrier is kept with the quartermaster. Ask there before beginning a round."
	match water.ledger.phase:
		"ready":
			return "Buddh · An empty carrier, and two journeys ahead.\n\nStay beside the well while drawing. The filled carrier must be walked home." if int(water.ledger.stored) == 0 else "Buddh · The same rope, the same way home. The household empties a vessel; someone makes this journey again.\n\nOne more load."
		"drawing": return "The rope is in hand. Return to the scene to finish raising the bucket, or set it down and begin again later."
		"carrying": return "The carrier is full. Walk it back to the quartermaster before drawing again; the open load cannot be mounted."
	return "Both loads are in the household vessel. This round is finished."
