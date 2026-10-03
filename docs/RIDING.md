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

### Dismount clearance on planar slopes

The integrated probe uses the actual configured walking shape and child transform.
Missing shapes and colliders refuse the transfer. Disabled hulls also refuse unless
the seated scene explicitly requests qualification of its retained walking hull;
the Punjab Chiefs adapter owns that request and reenables the same hull on landing.
The Home adapter retains an enabled shape with collision mask zero while mounted.
Queries use the horse's current collision mask, including camp traffic in Home;
walking restores both floor and camp-traffic collision. Queries do not temporarily
enable the walking body or mutate its shape.

A fixed 0.04 m lift above the centre ground ray embedded rounded capsules in steeper
walkable slopes. The held branch originally calculated capsule support analytically.
Integration preserves current main's bounded clearance search with the actual shape:
each endpoint starts 0.04 m above sampled ground and may use the declared small
vertical lifts before a full-hull sweep. Both ordinary and retained disabled hulls
still refuse an intersecting transfer.

The admitted angle is the smaller of the horse and player floor limits; with current
settings it remains **40°**. Each endpoint is checked using the same actual shape,
and the existing safe motion fraction must be at least **0.999**. The domain still
decides whether speed, grounded state and distance allow the action. Native planar
fixtures require the admitted walking hull to settle without upwards depenetration.

This bounded query qualifies clearance against native planar fixtures. It does not verify
the entire footprint of an irregular ledge, support on moving platforms, horse hoof
contacts, or a mounting/dismounting animation. Ramp fixtures extend physics qualification;
they do not replace Home terrain or claim that historical Gujranwala had these slopes.

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

### Saved horse support on slopes

Grounded saved poses now qualify support by sweeping the horse capsule downward from
the saved position and yaw. The previous short ray through the root rejected actual
motor-settled poses on 37°–39.9° ramps. A vertical capsule of radius 0.8 m on an inclined
plane has root height `0.8 * (sec(angle) - 1)` above the plane under its centre; at 39°
that is about **0.229 m**, beyond the old 0.20 m centre ray even while the hull touches
the ground to one side.

The saved-hull obstruction check remains first. A **0.25 m** downward hull
sweep then retains the prior **0.05 m** lower-cap tolerance plus **0.20 m** support-search allowance.
Only a detected contact proceeds to a normal query. That query samples at most 0.00025 m
beyond the unsafe sweep fraction, with a 0.002 m contact margin, and checks the horse's
existing floor-angle limit. The normal-query margin does not extend a collision-free
sweep. No live body moves during validation.

This intentionally preserves flat-ground compatibility: candidate feet at 0.199 m still
pass, while 0.201 m fails. The allowance is a bounded load tolerance, not proof that a
forged grounded record is touching the floor. Clear airborne poses still require no
ground support. Save fields, staged admission and the single campaign clock remain intact. Irregular
terrain, dynamic support and physical horse hoof contacts remain separate work.

### Saved headroom and airborne clearance

The former obstruction query shifted the entire capsule up 0.05 m. A horse that the
native motor could settle below a 3.21 m or 3.24 m ceiling was consequently refused
on load: the actual hull top was approximately 3.20 m, but the query reached 3.25 m.
The same shift could miss a small obstacle penetrating an airborne horse's feet.

Grounded validation now uses a separate capsule with the same **0.8 m** radius,
height **3.15 m** and centre **1.625 m** above the saved root. Its top remains at
**3.20 m**, and its lower cap is identical to the old lifted query. This is a lower-cap
tolerance, including a thin region along the lower flanks, rather than a literal flat
slice removed from the bottom. The downward sweep and support limits stay the same.
The live **3.2 m** collision capsule is never resized or moved by the query.

Airborne records use the complete original capsule at its actual **1.6 m** centre.
They receive no ground-clearance tolerance: a 3 cm foot obstruction is refused,
while an unobstructed pose with 4 cm of headroom is admitted. Both branches qualify
the saved pose independently of the live horse's location and preserve its shape
resource, transforms, velocities and floor state. These checks assume the retained
upright, yaw-only horse body; they do not add leaning or deformable horse collision.

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

`test_mount_clearance.gd` adds native body-clearance fixtures and the actual Home mount
action/input path. It distinguishes the atomic action (no clock advancement) from a queued
F request consumed in one ordinary owning physics tick. These are explicit spatial test
fixtures, not a claim that an autonomous player reached the horse.

The earlier 2 October 2026 mounting-clearance increment passed **49** new checks: clear approaches,
ray-clear narrow gaps and low barriers, initial/final overlap, displaced/rotated child
shapes, unavailable hulls, read-only queries, and the Home action/input boundary. The
same final test against the preceding horse implementation in an isolated game copy
produced **35 passes and 14 expected assertion failures**, with no unexpected engine
errors. An earlier Home fixture disabled `process_mode` and inadvertently removed
colliders; that run is explicitly superseded, and the corrected fixture freezes only
callbacks while keeping native collisions active.

Retained riding **177**, childhood **110**, companions **229**, and water-round **277**
checks also passed: **842 native checks** in this targeted qualification. The structural
suite passed **8** checks. The entire game suite was not rerun for this bounded change.

`render_mount_clearance.gd` captures three labelled fixtures in the composed Home:
narrow posts, a low barrier and an open approach. Each queries the actual adapter and
calls the existing mount action; blocked cases must retain the snapshot and physical
poses. PNG and decoded-pixel hashes bind the captures to their execution. Fixture
obstacles and diagnostic cameras are authored test geometry, not historical evidence
or a human playtest.

The subsequent slope-aware dismount increment adds **83** native spatial checks in
`test_dismount_clearance.gd` and **38** actual Home integration checks in
`test_dismount_home.gd`. Flat, 20°, 30°, 35° and 39° planar ramps admit a clear landing;
41° and 50° refuse one. The real standing body settles without an upward depenetration
jump. A blocked first side falls back to the opposite side. Initial overlap, a taller
actual hull under a low ceiling, and missing/disabled hulls refuse safely even though
the mounted avatar's collision mask is zero.

The identical spatial test against `eed8175` produced **42 passes and 9 expected
failures**. The passing implementation reaches additional grounding assertions after
the formerly refused ramps, so baseline and final assertion totals differ. The Home
checks confirm unchanged complete state on atomic refusal, existing walking ownership
on success, and exactly one normal tick for queued F input. Alongside rerun mounting
**49**, riding **177**, childhood **110**, companions **229**, and water-round **277**
checks, the new qualification totals **963 native checks**, plus **8** structural
checks. This remains a targeted run rather than the entire game suite.

`render_dismount_clearance.gd` uses the shared horse and player bodies on authored
flat, 35° and 45° diagnostic ramps. Accepted placements settle using the existing
player motor; the steep fixture remains refused. Captures bind the operation,
execution, source bytes and pixel hashes without claiming a historical terrain survey
or a played campaign route.

The next saved-support increment adds **132** checks in `test_horse_grounding.gd` and
**24** in `test_horse_slope_load.gd`. The same tests against `b5f0c6c` produce respectively
**124 passes / 8 expected failures** and **19 passes / 5 expected failures**. The Home
test settles through the existing horse motor and mounted reducer on an authored 39°
ramp, saves, installs a distinguishable live state, then invokes the actual load path.
Successful loading restores the saved state and clock. Obstructed saved poses and
removed support preserve the live authority, physical projections and original save bytes.

`test_horse_slopes.gd` adds **72** checks of existing movement across nine broad-ramp
fixtures: 0°, 20° and 35°, each uphill, downhill and across the slope. After setup,
acceleration, travel and braking all use the shared horse motor. Measured steady
three-dimensional path speed is **10.997–11.0001 m/s**, and braking from the 11 m/s cap
takes **74 physics ticks** at 60 Hz over **6.629–6.631 m**. All measured travel samples
remain grounded. These are authored controller settings on the pinned runtime, not
equestrian measurements or a played campaign journey. The hypothesized sustained-slope
speed loss was not reproduced, so the motor, acceleration and braking were retained.

With rerun riding **177**, childhood **110**, companions **229**, and water-round **277**
checks, saved-support qualification totals **1,021 native checks**, plus **8** structural
checks. The whole game suite was not rerun for this increment.

The saved-headroom increment adds **77** native checks in `test_horse_headroom.gd`
and **84** in `test_horse_headroom_load.gd`. Against `4963f53`, the identical final
tests produce respectively **71 passes / 6 expected failures** and **68 passes /
16 expected failures**. Direct fixtures cover motor-settled low ceilings, actual head
and side intersections, airborne foot obstruction, repeated queries, alternating
grounded/airborne records and live shape/state preservation.

The load fixture exercises both actual **Home and House** writers and load adapters.
A native settled pose below a low ceiling and a clear airborne pose load successfully;
a lowered ceiling or an airborne foot blocker refuses atomically. Success restores
the complete saved authority and clock; refusal preserves the distinguishable live
state, physical projections, camera and controller ownership. Both outcomes preserve
the original save bytes. Props and the airborne setup are explicit fixtures, not a
played campaign route. An initial fixture proof included native floor contact when
checking overhead clearance; the corrected proof excludes only its known supporting
platform. Superseded diagnostics are retained separately from qualifying runs.

With rerun ground-support **132**, slope-load **24**, riding **177**, childhood **110**,
companions **229** and water-round **277** checks, this increment totals **1,110 native
checks**, plus **8** structural checks. The whole game suite was not rerun. The horse
motor, locomotion tuning and authored terrain are unchanged by this load correction.

Separate baseline diagnostics found a remaining **39° uphill crest stall**, about
0.53 m before the top, on both joined box colliders and a continuous triangle surface.
The horse remains grounded; the cause is unresolved. The tested 39° downhill route
and 39.9° uphill route complete, so this is not established as an angle threshold.
These diagnostic scenarios are excluded from the passing assertion total. They
identify the next contact/movement investigation rather than qualify general
uneven-terrain support.

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
