# First rideable horse

## What is playable

The existing **Houses and rivals** scene now includes one persistent household horse.
Either active character can mount it, ride the courtyard–village–outpost road, dismount
on clear ground and interact with the original house-conflict/patrol encounter.
There is no fourth menu mode and no new engine or game-state service.

W requests forward motion. A/D steer; the horse does not strafe. Shift requests canter,
Ctrl requests walk, S/Space brakes; releasing W stops the horse. F mounts or dismounts.
Mouse orbit remains independent of horse heading. Decision menus pause mounted motion
and campaign time together. There is no jump, backward gait, stamina or horse-follow command.

Prototype tuning (metres/seconds, not historical or equestrian measurements): walk 3,
trot 6.5, canter 11; acceleration 4.5 m/s², braking 9 m/s², turn rate decreases from 1.9
to 0.65 rad/s. The mesh is procedural original blockout geometry; leg swing is not a
rigged or biomechanically validated animation. The conservative capsule hull includes
rider clearance, not mesh-perfect horse collision.

## One owner for each kind of state

`house_command_state.gd` remains the campaign authority, extending the original command
implementation. Its optional `riding.v1` dictionary contains one horse ID, current rider ID,
position, yaw, forward speed, vertical speed and grounding state. No rider/resource balance
is added or duplicated. Enabling riding twice cannot respawn/reset the horse.

`riding_rules.gd` is stateless validation/tuning. `horse.gd` is a Godot CharacterBody3D
adapter; only the owning scene calls its `step()` from a physics callback. After collision
resolution, `record_ride()` validates and commits the pose, updating the active actor and
player projection together. The horse body, rendered rider and camera are projections,
not additional saved authorities. Walking physics/collision is disabled while mounted.

Mounted actor positions use the horse's ground-reference position. The seat and camera
heights are visual offsets, not a second world location. Camera orbit and leg-animation
phase are presentation state and are not saved. This is not an event-replay engine or
cross-platform deterministic-physics guarantee.

Dismount first before a character handover, field observation, outcome or court interaction.
The horse remains parked on dismount and cannot be driven by a delegated captain. Delegated
without mustered companions keep the original abstract on-foot policy. Mustered patrols use
physical captain/companion movement and return; see [Companions](COMPANIONS.md). A report cannot
teleport a parked horse to Lahore. Without muster, the older immediate viewpoint return remains.

## Spatial checks

Mounting needs proximity and a clear swept path to the horse. F requests are handled in
physics time. Both mount and dismount probes use the active actor's actual enabled
collision shape and its local transform; they do not substitute an eye ray or a
hard-coded capsule. Dismounting requires a grounded, nearly stopped horse. The scene tries
both sides, then rear/front, requiring a ground ray, standable normal, standing-shape
clearance and swept path. A knee-height or thin wall cannot be bypassed simply because an
eye ray or the final landing is clear. The campaign additionally rejects nonfinite or
distant landing proposals. On admitted slopes, the ground probe spans the vertical change
possible across the declared exit offset and the actual actor shape may use only a bounded
16 cm clearance lift. The opt-in campaign guardrail admits at most 2 m of vertical change;
the scene still has to prove real support, clearance and a swept route.

These are local single-player invariants, not a network anti-cheat boundary. The campaign
cannot attest collision geometry by itself; the trusted scene adapter performs the probes.
An empty result preserves mounted state and displays a reason. The scene is still the old,
compressed, flat greybox. A separate native 30-degree fixture qualifies uphill movement,
turning, braking, side and longitudinal dismounts, remounting and mounted-pose reload. It
is followed by input-driven 15-degree convex-crest and concave-trough fixtures plus a
2 m drop edge. It does not establish arbitrary uneven-terrain, discontinuous-ground or
streamed-world support.

## Saves and compatibility

The visible scene opts into riding. Domain-only legacy consumers that do not opt in retain
their existing snapshots. Both original command saves and prior house-conflict saves import
without rewriting their orders, resources, reports or political history; a parked horse is
added. Existing `world-state.v1` and original command implementation are unchanged.

The current integrated scene uses `user://1792-companions-v1.json`; the earlier riding slot
`1792-riding-v1.json` remains importable through F1 alongside house/command slots. None of the
older slots is overwritten.
A staged load checks domain state and horse/world collision before installing the snapshot.
Malformed/unsupported records, invalid rider identity, nonfinite motion, out-of-bounds poses,
parked horses with speed, mismatched actor/horse locations, and blocked loaded poses are
rejected. A failed load does not partially replace the live horse or campaign.

The footprint bounds in `riding_rules.gd` are prototype guardrails, not Punjab's historical
frontiers. Spatial load checks cover the horse; general on-foot save/world collision
validation remains inherited and is not claimed as solved here.

## Test and development boundary

Run `python tools/run_checks.py --godot /path/to/godot` for all structural, import, command,
house-reporting and riding checks. The riding suite exercises actual physics/input over a
round trip, acceleration/braking, safe and blocked dismounts, mounting through walls,
low-barrier and offset-hull clearance, collision stopping, airborne landing, mounted
save/load, a bounded 30-degree horse/rider slope fixture, compound crest/trough support,
a real-gravity drop, legacy imports and commission rules.
Original tests are retained unchanged; new tests do not weaken their assertions.

`render_riding.gd` creates five controlled render fixtures. They are actual Godot images,
but capture success is not a human playtest and fixture placement is not autonomous travel.
The input-driven journey is exercised separately by `test_riding.gd`.

The reference engine is Godot 4.5.1, matching the existing project. API references:
- https://docs.godotengine.org/en/4.5/classes/class_characterbody3d.html
- https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html
- https://docs.godotengine.org/en/4.5/classes/class_physicsbody3d.html

Next gaps: mouse/keyboard feel on Windows, small-window/controller input, proper horse/rider
rigs, oblique compound terrain, mounted companions and actual encounter combat. The bounded
flat-world dismounted companion patrol and its physical return are covered by `COMPANIONS.md`.
No historical biographies, clan relations or source claims are
changed by this riding slice. Tahal Singh Chhachhi has not replaced the fictional captain.

## Saved motion continuity

Restoring a pose does not reset Godot's last-move contact flags. A falling file
loaded into a body whose previous move was grounded therefore used to lose its
saved downward velocity on the first resumed tick. The adapter now projects the
existing saved `grounded` flag into that one gravity update, consumes it, then
returns to native contact detection. No save field, clock owner, acceleration,
braking, gravity, hull or terrain policy changes. Pose-only horsecraft study
records have no grounding claim and retain their existing native-contact path.

`test_horse_motion_resume.gd` compares an uninterrupted native fall with the
same saved pose applied to a previously grounded body and a fresh body. The
90-tick fall and landing traces agree exactly in the tested stationary flat-floor
fixture. Against both `2d5b82b` and the unmodified current-main motor at
`a1c5222`, 8 checks pass and 4 fail: a saved -6.6000004 m/s
fall becomes 0 m/s instead of -6.9666672 m/s on the next tick, producing a
maximum vertical path error of 5.689446 m. The corrected fixture passes all
12 checks with zero path error.

`test_horse_motion_resume_load.gd` adds 144 checks through the actual Home and
House file writers and load adapters. The original motor passes 130 and fails
14; the correction passes all 144. Native floor contact and native falling
motion establish the two different cache states. Checks cover the first resumed
velocity and position, later clear-air steps, native landing, and grounded saves
loaded over an airborne live cache. Full snapshots, saved clocks, original file
bytes, actor/player/horse projections and sole movement ownership remain intact.
These are authored physical fixtures; they do not assert universal contact-cache
restoration or cross-platform deterministic physics.

On the current-main parent `a1c5222`, the complete `tools/run_checks.py` run
with Godot 4.5.1 passes 18,656 native assertions across 63 suites and 150
structural checks across 10 suites. The NET profile integrity check and three
render-schedule locomotion rate checks also pass. No script, shader or engine
errors were reported. Three retained scene suites emitted ObjectDB cleanup
warnings: youth brawl, home workshop and Sobraon prologue. The youth warning
also reproduces with the unmodified parent motor; workshop repeats identify
audio resources, and the Sobraon warning did not recur. The other warnings have
not been proven inherited. This motion-restoration change does not resolve the
separate 39-degree uphill crest stall diagnosed in the earlier local branch.
