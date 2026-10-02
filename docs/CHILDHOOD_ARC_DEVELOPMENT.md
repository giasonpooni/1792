# From the riding yard to the household inquiry

This development pass works through **HOME-003–007** in the existing Home chapter.
It continues the opening-message work without adding another mission to the ledger.

## What is playable in this pass

| Sequence | Development now in the build | Next performance work |
| --- | --- | --- |
| HOME-003 · Riding | Three numbered cloth markers distinguish the next gate and completed gates. A flat stopping patch and reactions after each successful gate guide the return to foot practice. | Horse/rider animation, recorded reactions and a more developed practice setting. |
| HOME-004 · Guard and counter | Visible arm preparation and recovery follow the real timing. Early, late and unfaced swings receive distinct corrections. Brief feedback remains readable instead of disappearing next frame. | Paired character animation and authored practice sound. |
| HOME-005 · Tracking | Prints, bent reeds and pressed grass provide distinct traces and original observations. Out-of-order inspection tells the player to recover the earlier trail; it grants no progress. The stationary quarry has subtle breathing motion. | Animal movement, richer ground art and sound; no hunting kill or harvesting is implemented here. |
| HOME-006 · Ambush | The existing assailant has a visible raised weapon and stagger pose tied to the actual threat window. Returning Home hands off to the household conversation. Escape and guarded retreat keep their existing rules. | More detailed approach terrain, facial performance and encounter sound. |
| HOME-007 · Inquiry | The report is assembled from actual received accounts and observations. Going alone and bringing the guard receive distinct acknowledgments. The earlier message errand is recalled only to the extent completed. | Performance blocking, voiced exchanges and further household reactions. |

The new geometry and gestures are original procedural staging. They supplement the
existing prototype art; they are not finished character animation, motion capture,
or historically authenticated terrain. The same collision bodies, routes, clock,
lesson gates, escort and save records remain authoritative.

## Play the continuous route

Choose Begin, play or skip the opening presentation, and complete the message lesson.
The optional message follow-up remains available. Mount with F, ride the three gates
in order, brake, and dismount on clear ground. Approach the practice trainer, face
him and hold Q through two blows. Counter with the left mouse button during recovery.

Follow the prints, reeds and pressed grass with E. Approach the quarry quietly with
C, then observe it with E. Return by the marked bend. Escape to the courtyard, or
guard and counter to make an opening before retreating. Hear the two household
accounts, speak to Raj Kaur and choose whether to take the guard. Inspect the bend
and return to report.

The final dialogue distinguishes an attacker actually seen from an unclear encounter,
a received report from a direct observation, and a completed earlier message from
an intention that was never carried out. It offers no culprit or hidden answer.
Legacy remembered testimony is retained unchanged. All additional prose is original
dramatic writing; source disputes elsewhere in the game remain available.

## Interaction and persistence

Raj Kaur's decision and report buttons belong to the conversation that offered them.
Executing a queued answer rechecks standing ground, local distance, facing and an
unobstructed view. Closing the conversation or inserting a wall cannot complete a
report remotely. Both established escort/independent routes still complete normally.

Presentation reads the existing tick. Pausing freezes gestures and feedback time;
loading a snapshot restores its state and clears transient practice feedback. New
staging adds no collision objects and does not advance memories, gate completion,
damage, guard behavior or a second clock. The guard still physically travels and
must be present where the selected route requires him.

## Qualification

Run the targeted checks with Godot 4.5.1:

```sh
godot --headless --fixed-fps 60 --path game --script res://tests/test_childhood_arc.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_childhood_arc_staging.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_inquiry_presentation.gd
```

The normal check runner also includes these tests. Controlled setup/render fixtures
are distinguished from input-driven journeys. The existing childhood and aftermath
suites retain the full route coverage. Exact observed results are recorded in the
development PR; these commands alone do not certify execution or final art quality.

Local Godot 4.5.1 results for this pass: childhood arc **107/0**, staging **113/0**,
inquiry presentation **243/0**, inherited childhood **110/0**, inherited aftermath
**166/0**, and opening-message scene **40/0** (passed/failed). Six aftermath captures
and three production staging views rendered successfully. The visual checks caught
and corrected reversed wind-up rotation and a duplicate costume arm; native tests
now check the weapon's world height and the shared costume treatment.

Further environment work is still needed around the first two traces, where older
market dressing partly obscures the ground. Their interactions and paths remain
playable; this pass does not claim a finished trail layout or final character art.
