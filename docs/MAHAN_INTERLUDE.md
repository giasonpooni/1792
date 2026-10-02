# Mahan Singh: a required past with a fixed ending

## User-directed story structure

Before taking Lahore, during the one- or two-year lead-up represented by the
**1797–1798 pre-Lahore chapter**, the player must leave the forward-moving
Buddh Singh story and play Mahan Singh's earlier story. Mahan dies at its fixed
ending. The story then revisits Buddh's beginning before reconnecting with the
already-suspended pre-Lahore progression. It does not restart the player's save,
rewrite the inheritance, resurrect Mahan in the later world or replay years of
completed progress to farm items and resources.

```
Buddh: childhood -> growing independence -> pre-Lahore story gate
                                                |
                                      suspend the present
                                                |
                         Mahan: earlier command and clan conflicts
                                                |
                                   fixed ending: Mahan dies
                                                |
                                reprise: Buddh's beginning
                                                |
                              resume the pre-Lahore present
                                                |
                                    continue toward Lahore
```

Mahan is a second playable historical viewpoint, not a temporary rename of
Buddh. Runtime actor IDs remain `mahan_singh` and the existing `ranjit_singh`.
Buddh's player/self name remains Buddh Singh; public forms of address remain
controlled by the existing naming policy. The reprise must not automatically
copy Buddh's visual treatment, literacy, skills or knowledge onto Mahan.
Those are separate character profiles for future scene development.

## Fixed outcome does not require empty gameplay

The overall endpoint is locked. Encounters inside the retrospective can still
allow different routes, order timing, positioning, optional conversations and
local mission performance. A mission should ask the player to complete something
possible, not falsely promise that better combat can prevent the fixed death.

Ordinary mission failure retries that mission; Mahan's scripted historical death
successfully concludes his portion and advances to the Buddh reprise. There is
no survival ending or new timeline. Local variations cannot contradict inherited
facts already present in Buddh's suspended world. Player interpretation may change;
Buddh's inventory, territory, relationships, clock and memories are not rewritten.

This phase should make familiar homes, rivalries and households intelligible from
a previous generation's position. The player can learn why a relationship matters
without granting Buddh facts he never witnessed or received through an account.
The retrospective is not automatically his literal memory or a supernatural vision.

## Source basis and limits

This specification uses the **Maha Singh excerpt supplied by the user**. Its
terminology and conflicting chronology are retained rather than silently reconciled:

- Name variants: Maha, Mahan and Mahn Singh; Punjabi Mahaṅ Singh.
- The excerpt gives **1760 – 15 April 1790** and **1756 – April 1792** as alternatives.
- It describes succession after Charat Singh, the Sukerchakia Misl, an alliance
  with Jassa Singh Ramgarhia, and reduction of Kanhaiya Misl power.
- It names Charat Singh and Desan Kaur as his parents, and Mai Man Kaur and
  Raj Kaur as wives, with Raj Kaur as Ranjit Singh's mother.

Reference supplied by the user: https://en.wikipedia.org/wiki/Maha_Singh .
The page has not been independently re-researched in this increment. These are
source-attributed inputs, not new verification of dates or private motives.
No cause, exact place, final words or death scene is invented as established fact.
The 1797/1798 anchor belongs to Buddh's later narrative position, not Mahan's death.
The selected Latif account and earlier historical research policies remain intact.

The later fixed-ending retrospective is separate from the riding-training
flashback added at the user's direction. During childhood riding instruction,
Buddh can hear an attributed tale of Maha Singh and play a short horsecraft
lesson. Its completion unlocks standing riding, paired standing riding and
mounted matchlock handling in the existing Home skill record. It does not
complete this retrospective, replay Mahan's death or open the Lahore gate.
See [the horsecraft lesson and its evidence limits](HORSECRAFT_STUDY.md).

Proposed mission authoring groups are: inheritance of command, the Ramgarhia
alliance, Kanhaiya rivalry, and final orders. Their encounter maps, objectives,
combat, dialogue and visual ending remain to be authored. The runtime beat names
are sequencing placeholders, not claims that four complete historical missions
have been reconstructed or played.

## What is implemented now

`game/history/fixed_interlude.gd` is an executable **sequencing and preservation
contract**, not a playable campaign. It requires an explicit pre-Lahore anchor,
year 1797 or 1798, Buddh as the suspended actor, and a caller-supplied validator
for that present-world profile. It refuses a 1792 childhood or 1801 Lahore snapshot;
merely changing a display label cannot backdate either existing prototype.

The controller retains the validated present as detached JSON and its SHA-256
binding. It records an ordered prefix of father-story beats, distinguishes retry
from fixed death, requires the Buddh reprise, and only then emits the original
present plus a single-use story receipt. The receipt explicitly grants **no items
and no character knowledge**. Its scope is player/viewer story completion, not
an in-world letter or testimony. The JSON bytes remain identical; a host must
restore them through its own domain loader, including normal numeric normalization.

Snapshots of the contract can be persisted by a future campaign/session owner.
Restoring them again requires that owner's validator. Reordered beats, alternate
terminal outcomes, changed bindings and premature return are refused without
replacing live contract state. The digest is a consistency check, not an authenticated
save or anti-cheat proof. Ordinary JSON duplicate-key hardening is not claimed.
The controller has no clock and never steps the parked present; future scene
routing must activate only the currently played world and pause the other.

**The 1797–1798 world, father missions, playable reprise, historical scene/checkpoint
routing and the actual Lahore transition are not implemented in this change.**
This fixed-ending contract adds no menu preview or immediate-childhood trigger.
The separate riding lesson above has its own childhood trigger and skill receipt.
`allows_lahore_transition()` is a gate the future router must call, not a
claim that the current menu or map is already controlled by that router.

## Validation

`test_fixed_interlude.gd` uses a deliberately labeled pre-Lahore test fixture
and a test provider, not an actual late-campaign save. It checks wrong years and
actors, provider veto, nonfinite/object input, frozen snapshot isolation, ordered
beats, retry versus historical death, required reprise, single-use return,
JSON round-trips and tampered outcomes/bindings. All inherited gameplay suites
remain in the normal runner. No new rendered scene or gameplay run is claimed
for this contract-only increment.
