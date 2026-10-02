# Shared-world gameplay

1792's traversal, social access, historical cognition and conflict use the
existing Home world's positions, player and horse motors, event authority,
childhood clock and whole-world save. Each new workload extends that substrate.

The player loop is **perceive → interpret received information → choose an
approach → interact or fight → encounter remembered consequences**. The current
increment implements a small local passage contract; it does not establish that
the full four-pillar campaign has been completed.

## Household passage

After completing the household inquiry, approach the keeper beside the final
riding marker at `ChildhoodState.GATES[2]`, dismount, face him and press **E**.
Choose **Ask for one passage**, then cross between the markers on foot or
horseback. The grant is for one crossing. Return and choose **Hear the keeper's
account**. A witnessed rushed or unpermitted crossing changes his account;
acknowledging a heard concern can secure another passage.

The marker remains an open route. These poles do not enclose a compound, and the
keeper is a fictional local role, not a claim about a documented childhood
incident, general rank recognition or historical policing. Pace thresholds and
permission rules are authored game rules.

| Layer | Authority in this increment |
| --- | --- |
| Geometry | Existing riding marker and admitted player/horse positions |
| Local authority | Optional one-passage permission and the keeper's retained concern |
| Observation | Godot collision ray from the keeper to the crossing body, within local range |
| Evidence | Ordered passage/action receipts on the existing childhood tick |
| Player knowledge | Own crossings plus keeper testimony received in local conversation |
| Presentation | Existing gate gestures, traffic, cart and cloth remain passive |
| Verification | Finite reducer replay, receipt validation and native motor/input checks |

`household_threshold_03` identifies the marker. `fictional_household_gate_keeper`
is distinct from the existing mobile `fictional_household_guard` escort. The
authored household authority is not promoted to a historical fact or a global
faction reputation value.

## Information and preservation

No passage history exists in legacy saves until the player requests passage.
Once active, accepted movement can append a receipt when its segment crosses the
bounded central plane. Stationary samples and routes beside that segment do not
create incidents. A blocked sightline cannot create witnessed guard conduct.
The player journal does not expose the keeper's private reaction at the moment
of a crossing. It receives that reaction through a later local account.

The optional event block belongs to `WorkshopState`, above the existing childhood,
aftermath, supply, water, service and youth authorities. It does not instantiate
another game loop or clock. Existing carrying, riding and service restrictions
continue to apply. Invalid actions and rejected restores preserve the whole
live state. F5/F9, checkpoints and the bazaar retry replace the complete world,
including this history, rather than merging memories from later attempts.

Tracking covers the integrated Home executor's `_record_walk` and
`_record_mounted` hooks, which submit movement plus observations to
`record_gate_position` and `record_gate_ride`. Direct legacy model movement and
declared fixture restores do not supply those observations. A future provider
must use the observation seams to participate; this is not a universal gate
enforcement guarantee over every model method.
Mounting and dismounting retain their original pose-handoff rules; this increment
records continuous foot and horse locomotion through the marker.

The bounded receipt budget suspends further passage tracking when exhausted;
the inherited movement route and other tasks stay available. These event records
are validated gameplay receipts, not cryptographic proof of a physical sensor or
historical authentication.

## Next extensions

Dress, introductions, escorts, familiarity and faction control can extend the
same local access contract after their own evidence and gameplay checks exist.
They should not be inferred from decorative uniforms or crowd animation.
Material wear and procession traffic retain their existing presentation roles
until an explicitly admitted world event gives them gameplay meaning.

The childhood-through-Lahore production priority, full regional geography goal,
religious-site view-only rule and separate historical evidence boundaries remain
in force. This work adds no religious-site access, biography unlock or DLC.

## Validation

Run `python tools/run_checks.py --godot /path/to/Godot_v4.5.1` for the inherited
suite and passage checks. The new suite distinguishes declared domain fixtures
from its motor-driven request, crossing, account, reconciliation and save/reload
journey. Human playtesting, historical review and final character art remain
separate from those technical checks.
