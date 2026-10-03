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

Mounting needs proximity, a clear line to the horse, and a clear sweep of the avatar's
actual walking collision shape. The probe preserves the shape's global transform and
active collision mask, excludes the avatar and horse, and checks both endpoints before
sweeping the complete approach. This prevents a narrow gap or a low barrier from admitting
a transfer just because the elevated sightline is clear. Queries do not move either body
or change authoritative state. A rejected transfer keeps the walking controller active.

The shape receives the existing 0.04 m dismount-style floor allowance without shrinking
its radius or height. Only a completely clear `[1.0, 1.0]` cast result is accepted. This
qualifies the straight approach for the existing discrete mount action; it does not add a
mounting animation, stepping over obstacles, or an uneven-ground solver. Current Home
and House callers use one standing capsule and collision mask 1 while on foot.

F requests are handled in physics time. Dismounting requires a grounded, nearly stopped horse. The scene tries both sides,
then rear/front, requiring a ground ray, standable normal, actual standing-capsule
clearance at both ends and a completely clear swept path. A thin wall cannot be bypassed
simply because the final landing is clear.
The campaign additionally rejects nonfinite or distant landing proposals.

These are local single-player invariants, not a network anti-cheat boundary. The campaign
cannot attest collision geometry by itself; the trusted scene adapter performs the probes.
An empty result preserves mounted state and displays a reason. The scene is still the old,
compressed, flat greybox. This does not establish uneven-terrain or streamed-world support.

### Dismount clearance on planar slopes

The dismount probe now uses the actual walking capsule's radius, height, offset and
orientation. A missing, disabled or non-capsule walking shape refuses the transfer.
It deliberately queries walking collision mask **1**, because the mounted avatar has
mask **0** and both retained scene adapters restore mask 1 when walking resumes.
The check does not temporarily enable the walking body or mutate its shape.

A fixed 0.04 m lift above the centre ground ray embedded the rounded capsule in steeper
walkable slopes: the previous implementation refused native 30° and 39° ramp fixtures
even though the retained player body could stand on them. Placement now computes the
capsule's support distance against the sampled plane before adding the existing 0.04 m
vertical allowance. For capsule radius `r`, height `h`, world shape basis `A`, upward
unit surface normal `n`, and world child offset `o`, the calculation is:

```
q = transpose(A) * n
support = r * length(q) + (h / 2 - r) * abs(q.y)
lift = max(0, (support - dot(n, o)) / n.y) + 0.04
```

The admitted angle is the smaller of the horse and player floor limits; with current
settings it remains **40°**. Initial overlap is explicitly refused because a sweep can
ignore a shape it already intersects. Each endpoint is then checked using the same
actual capsule, and only a full `[1.0, 1.0]` motion result permits a landing. The domain
still decides whether speed, grounded state and distance allow the action.

This calculation qualifies clearance against a sampled local plane. It does not verify
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
collision stopping, airborne landing, mounted save/load, legacy imports and commission rules.
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
rigs, uneven ground, mounted companions and actual encounter combat. The bounded flat-world
dismounted companion patrol and its physical return are covered by `COMPANIONS.md`. No historical biographies, clan relations or source claims are
changed by this riding slice. Tahal Singh Chhachhi has not replaced the fictional captain.
