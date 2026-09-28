# Companion patrol: leave and return together

## Play the new loop

Use the existing **Lahore · Houses and rivals** entry. Settle the estate petition as Ranjit,
assign scouts or the four-person patrol, then G -> **Muster allocated companions** before
departure. Take the captain's viewpoint or delegate. This is optional within the existing
scene, not a fourth prototype. The older abstract loop remains available without mustering.

The original rider allocation includes the captain. Two scouts therefore create one companion,
and four riders create three. They are dismounted troop stand-ins with fictional numbered
identities. No additional troops, horses or resource pool are granted by mustering.
Cancel before departure to remove the group and return the original allocation once.

G opens **Follow / regroup** and **Hold**. A command requires every trooper within 30 metres.
This is a deliberately simple radius rule, not a model of voice propagation or messenger travel.
Held troopers remain where they are; delegation and outcome selection do not silently cancel Hold.
The captain may ride the existing horse but troopers travel at up to 6 m/s on foot; ride back toward
stragglers rather than relying on teleport catch-up. No companion mounts or horses are simulated.

Observe the village and outpost. A secure decision requires the captain within four metres of
the outpost and at least two companions within seven metres, as well as the existing allocation,
observation and political-commission gates. Withdraw remains possible with fewer/no observations.
Decisions remain menu-based; presence is now physical, but there is still no combat encounter.

## Return, consequences and reports

For a mustered patrol, choosing secure/withdraw commits a field decision and begins return:

```
assigned -> muster -> outbound -> committed field decision -> returning
                                                      -> check-in -> reporting -> completed
```

The captain stays playable for the return. Bring all troopers to the courtyard, walk around the
command table to its near side, dismount, E -> **Check patrol in**. Every trooper must be within
seven metres of the return point; the captain within 3.5. A delegated captain walks back using
the same physics/navigation adapter and checks in when the whole group has arrived.

**This bounded version settles the original security, trust and political effects at check-in,
not at the instant the outpost decision is selected.** Resources remain reserved during return.
At check-in the original consequence functions run once, a report is compiled and the original
four-game-minute delivery delay begins. The report's inherited `observed_at` is the check-in /
compilation tick in this profile; `companions.decision_tick` separately preserves the earlier field
decision time. The journal labels both. There is no newly observed outpost information on return.
An unobserved withdrawal still produces null/unknown conditions, not a default claim of security.

The report arrives and releases the existing allocation once. Companions remain as courtyard
stand-ins after check-in; the one-order prototype does not offer a second mission or duplicate them.
A field decision cannot be changed, re-applied or retroactively reconciled during the return.
Before that decision, the existing negotiation and reconciliation choices continue to apply.
None of these actions annexes land or changes biographies, clans, religions or historical events.

## Ownership and movement

`house_command_state.gd` is still the authority and uses the original single `_state`. The optional
`companions.v1` record contains the order ID, unique trooper IDs, instruction, current phase,
position/yaw/velocity records, committed outcome and field/return timestamps. `companion_rules.gd`
is stateless validation and tuning. Troopers do not become playable actor slots.

`patrol_director.gd` manages scene projections, not another campaign or resource ledger. A
CharacterBody3D adapter drives each companion and, during delegation only, the existing captain.
The old delegated position step is disabled only for mustered patrols. Domain `advance()` alone
cannot move these units; it waits for physical motion submissions. Manual/delegated handovers
preserve IDs, positions, the hold order, allocation and committed decision. A mounted captain
still cannot hand over control until dismounted.

`patrol_navigator.gd` samples the current flat scene's static collision geometry into a small
AStarGrid2D. Segment sweeps avoid thin-wall/corner cutting, while bodies perform actual collision
movement. The cache is rebuilt on a new scene, not saved as world truth. Friendly troopers use
stable trailing offsets and non-blocking friendly collisions; there is no crowd-separation or
formation tactics solver. New runtime obstacles stop a body but are not automatically rebaked;
complete dynamic-obstacle rerouting is a later task. There is no jump, slope/path streaming,
teleport recovery, physics replay certification or cross-platform determinism guarantee.

All companion motion is submitted through a bounded domain entry point. It rejects unknown IDs,
manual-captain writes from the delegated adapter, nonfinite/malformed motion and excessive steps.
The trusted scene validates collision geometry; this is a local single-player boundary, not anti-cheat.
Menus pause all relevant motion and the same campaign clock, including when viewing the codex.

## Saves and compatibility

F5/F9 use `user://1792-companions-v1.json` (separate from the earlier riding slot). F1 explicitly
imports older riding, house or original command saves. Importing old saves does **not** invent
active companions; muster is available only for an assigned, unstarted order. Loading an older
snapshot after a mustered one removes stale companion projections instead of duplicating them.

Validation binds troop count and IDs to the original allocation, phase to the original order,
returned state to courtyard positions, and outcome/time to the original report. Motion values
must be finite. Staged scene loads additionally check every companion and the captain against
standing clearance and ground before replacing any live state. As in the riding slice, a blocked
or malformed load leaves the live session intact. General historical/save migration is not added.

Regression files use an injected test-only save path. Integer counts, IDs, lifecycle and decision
fields are compared exactly; serialized floating-point positions are compared within 1e-12 in
round-trip tests because JSON conversion can differ by a double-precision ULP.

## Validation and next work

`python tools/run_checks.py --godot /path/to/godot` runs the original command, house and riding suites
unchanged, plus companion rules, saves and real physical round trips. Scripts use a fixed 60 Hz
frame step so automated input drivers have a declared step, not a machine-dependent wall clock.
A separate test body proves wall stopping and no-path refusal. Render captures are scene evidence,
not proof of human enjoyment. `render_companions.gd` uses a tracking camera for delegated travel
captures; that camera is only a test fixture, not an added free-flight gameplay mode.

Next useful work: an actual checkpoint conversation/encounter with a rival patrol, better route
landmarks, animation and sound, followed by human testing of follow distances and returning to court.
No new world regions, engine services, autonomous faction plots or historical commanders are added.

Engine API references (consulted for this implementation):
- https://docs.godotengine.org/en/4.5/classes/class_astargrid2d.html
- https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html
