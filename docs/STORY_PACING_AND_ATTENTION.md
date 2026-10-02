# Story pacing and attention

This pass develops original literary direction for all 33 inventoried playable
sequences and implements the next presentation increment in the childhood arc.
The individual directions live in `mission_development.json`; the readable matrix
is in `MISSION_DEVELOPMENT_PLAN.md`. The count remains 33. A direction card describes
intended development, not another implemented mission or completed performance.

## The connected childhood story

The dramatic movement is curiosity, confidence, concentration, discovery, alarm,
and reflection. Its recurring idea is **look first, then answer**. The trainer
teaches a physical habit; the trail asks the player to use it differently; the
inquiry asks whether an observation is enough to justify an accusation.

| Sequence | Implemented direction in this increment |
| --- | --- |
| HOME-003 · Riding | Keep the active gate and steering controls prominent. Secondary explanations recede while moving or mounted, and optional opportunities return when standing. Gate reactions finish instead of remaining on screen indefinitely. |
| HOME-004 · Guard and counter | Shorten preparation and correction lines around the real combat rhythm. The trainer introduces “look first, then answer”; the transition to tracking recalls it in Buddh’s own words. |
| HOME-005 · Tracking | Let observations finish into silence. Successful quiet observation ends with the choice to leave the animal undisturbed. Move two exact pieces of market dressing that covered prints and reeds; restrained soil contrast supports the first clue. |
| HOME-006 · Ambush | Clear pending trail reactions on danger. Immediate strike/escape cues take priority. After physical return, the familiar household gate receives a short reaction whose meaning has changed. |
| HOME-007 · Inquiry | Keep received testimony and observed facts as the basis of the existing report. After the report, Buddh reflects on having brought an observation rather than a culprit’s name. New interactions can interrupt incidental reflection. |

These are authored internal reactions and dialogue, not historical quotations.
No hidden assailant, conspiracy, disputed parentage or political guilt becomes true
because a presentation line appears. Legends and conflicting allegations remain
in the wider mission direction with their existing treatment.

## What the player experiences

One primary objective remains visible during movement. The compact HUD separates
essential controls from speech; an empty caption leaves no dark speech panel.
Explanatory text returns at rest. Imminent danger keeps movement, guarding and
counter controls visible. The original HUD switch remains available.

Captions use the existing simulation clock. A displayed observation gets a reading
window; a deliberate new interaction can replace it. Combat feedback takes priority
over incidental prose. At most two incidental lines can wait, and old ones are
discarded. Entering or leaving danger clears incompatible speech. No camera move,
input lock, added mission delay or new failure timer is required to read a line.

The starting display budget is 1.5 seconds plus one third of a second per word,
bounded to 3–12 seconds at the existing 60 ticks per second. These are tuning values,
not evidence of measured attention or comprehension. Combat cues may replace text
sooner when the next action requires it. The next player test should watch missed
instructions and recovery, not equate longer playing time with better storytelling.

The journal offers a separate **Recent scene dialogue** view for the last twelve
displayed lines. Reviewing it pauses the world; returning to the journal or play
does not add remembered evidence. The normal journal is not lengthened with those
lines. Loading a save or checkpoint clears transient captions and recall from the
discarded session, while mounting and dismounting preserve recall.

## Presentation boundaries

The trail correction moves only `StreetBay_R_2` and `StorageBasket6`, after checking
their source, expected original position, mesh and lack of collision descendants.
It restores their original transforms when removed. It does not move the trail
sites, navigation bodies, the separate story-detail anchor or the camera. The first
clue uses flat, non-emissive soil contrast. Four nearby comparison captures show
the three print pairs and seven bent reeds exposed; this is not proof of every
approach or camera angle.

The integrated branch includes the current main branch’s Gujranwala daily-detail
art. Character bodies, much scenery and animation remain prototypes. The mounted
camera can still meet inherited roof obstructions; this pass does not claim final
cinematography, voice acting, music or a finished environment.

## Verification

The focused unit suite covers priority, finite waiting, stale-line removal, quiet
intervals, rewinding and bounded recall. The scene suite uses declared initial
fixtures, then real pause/save/load inputs and physical movement into danger and
home. It compares authoritative state and journal evidence around presentation
operations. The HUD suite checks movement/rest, optional paths, mounted and threat
controls, classic/compact switching and two viewport sizes.

Visual checks use native Godot rendering. Some captures use explicit camera and
state fixtures to compare layout; they are not represented as an entire natural
playthrough. The small responsive-layout fixture disables viewport scaling for its
geometry check; the shipped stretch setting is unchanged. Exact results and scope
are recorded in the development PR.

Local Godot 4.5.1 results in this pass:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Caption priority and timing | 22 | 0 |
| Native caption/replay/save and danger journey | 57 | 0 |
| Native attention HUD, including six captures | 47 | 0 |
| Trace layout correction | 20 | 0 |
| Existing childhood staging | 113 | 0 |
| Existing childhood arc | 107 | 0 |
| Existing aftermath | 166 | 0 |
| Existing courtyard | 123 | 0 |
| Existing beginning guidance and pointer routes | 480 | 0 |

This is 1,135 targeted checks. Project/reference checks, source-closure profiles,
ledger consistency and whitespace checks also pass. Four trace comparison images
were inspected; the quiet and small threat HUD views were rechecked after the
main-branch art integration. The full repository suite and human attention study
were not run as part of this increment.

Discovered and fixed during this pass: save restoration through an inherited loader
kept discarded dialogue history; the shared apply boundary now clears it. Adding
recall directly to the journal also increased scrolling to Resume; recall now has
its own optional view and the original pointer-scroll test budget is retained.
