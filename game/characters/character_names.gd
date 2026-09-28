extends RefCounted
## Authored presentation policy; never a character key, save migration or historical date claim.
## Buddh remains the player's identity. Others use Ranjit after the authored accession.
const HERO_ID := "ranjit_singh"
const BEFORE_ACCESSION := "before_accession"
const AFTER_ACCESSION := "after_accession"
const PLAYER_NAME := "Buddh Singh"
const PUBLIC_NAME := "Ranjit Singh"

static func player_name(actor_id: String, other_name: String = "") -> String:
	return PLAYER_NAME if actor_id == HERO_ID else other_name

static func address(phase: String, formal: bool = false) -> String:
	match phase:
		BEFORE_ACCESSION:
			return PLAYER_NAME
		AFTER_ACCESSION:
			return "Maharaja " + PUBLIC_NAME if formal else PUBLIC_NAME
	# Unknown chapter must not silently award a title. This is not a date heuristic.
	return ""
