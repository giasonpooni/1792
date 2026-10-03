extends RefCounted
## Authored presentation policy; never a character key, save migration or historical date claim.
## Buddh remains the player's identity. Others use Ranjit after the authored accession.
const HERO_ID := "ranjit_singh"
const BEFORE_ACCESSION := "before_accession"
const AFTER_ACCESSION := "after_accession"
const PLAYER_NAME := "Buddh Singh"
const PUBLIC_NAME := "Ranjit Singh"
# Original fictional relationships, not claims about documented childhood mentors.
# Membership in a religious community alone never supplies familiarity.
const CHILDHOOD_MONIKERS := {
	"fictional_nihang_elder": "Buddh",
	"fictional_nihang_veteran": "Little rider",
	"fictional_nihang_companion": "Buddh"
}

static func relationship_address(speaker_id: String, subject_id: String, established: bool,
		phase: String, formal: bool = false) -> String:
	if subject_id != HERO_ID or phase not in [BEFORE_ACCESSION, AFTER_ACCESSION]: return ""
	if established and CHILDHOOD_MONIKERS.has(speaker_id): return CHILDHOOD_MONIKERS[speaker_id]
	return address(phase, formal)

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
