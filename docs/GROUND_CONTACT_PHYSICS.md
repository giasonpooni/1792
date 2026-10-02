# Ground contact physics

The **Ground contact practice · stairs and slopes** menu entry runs the existing
Player scene and CharacterBody3D in an isolated, original metric course. Walk up
four 18 cm stairs, descend the incline, return up it, then walk down the stairs.
The side stations expose an over-height riser, low ceiling, curb, drop and slopes.
They are physical design fixtures, not a surveyed historical place.

## Implementation boundary

`ground_contact_enabled` is false by default. The new course selects it explicitly
alongside the existing isotropic movement and traversal profiles. The inherited
movement course and campaign retain their prior response unless they explicitly
admit the new profile. Existing horse and horsecraft code is not replaced.

The static-step probe uses the actual capsule, its local transform, collision mask
and declared floor policy. Admission checks the original support, upward clearance,
the complete horizontal advance and a walkable landing. The maximum configured
step is 0.30 m. High obstacles, insufficient overhead space, unsupported landings
and unqualified moving supports cannot become valid steps through visual inference.
The admitted actor has one registered capsule owner and no collision exceptions.
Unrepresented native shape owners and unsupported practice shapes refuse saving
and restoration rather than disappearing from compatibility checks.

Each lift, advance and lower segment is swept on the same native physics body.
Horizontal advance consumes the commanded tick movement once. The surface and
clearance are rechecked; a failed execution restores the original body pose. A
final native floor-contact update establishes the engine's actual grounding flag.

At slow analog speeds, the rounded capsule first meets a stair corner at a steep
contact normal. A short, explicit contact transition retains the original support
and total rise bound while the commanded movement crosses that corner. Successive
supported destinations may adjust downward relative to the immediately prior tick,
but never below the original contact anchor. It expires within one second, adds no
autonomous horizontal movement, and releases on interruption.
A separate ray verifies the same static body's walkable top face; that observation
does not fabricate the native grounding flag. No separate locomotion service or
frame-driven transform animation advances the actor.

The opt-in slope policy uses constant ground speed and bounded floor snapping.
The floor angle remains an authored motor parameter. Unsupported drops detach and
fall under the existing gravity. These are controllable kinematic character rules,
not a biomechanical, deformable-ground or rigid-body animal simulation.

The independent fixture matrix measures 18, 24 and 30 cm risers at walking targets
of 0.45, 1.125, 2.25 and 4.5 m/s; over-height 30.1 cm and larger risers refuse.
The connected course also admits mapped input strength 0.22, just above its 0.20
deadzone, without a fall-and-retry cycle. A command at 0.21 moves too slowly to
reach the first stair during the current 40-second probe, so it is not evidence of
stair refusal or completion. No implementation promises finite-time traversal for
an arbitrarily small input above the deadzone.

Zero input, full reversal and a perpendicular turn release retained stair contact
in one physics tick. The shared acceleration still governs stopping and direction
change; contact release does not add an impulse or autonomous horizontal travel.

The side turn-terrace station qualifies 0°, ±30° and ±45° entries against
a broad 18 cm tread. Its authored route then turns 90 degrees onto a perpendicular
12 cm rise and returns down the same edge. The rise stays supported; the descent is
a short native-gravity transition. A separate 30-degree diagonal approach confirms
that the complete capsule still refuses an otherwise walkable tread under a low
ceiling. These are bounded graybox collision fixtures, not global traversal promises.

## State and measurement

The retained motion snapshot stores the motor's integration state. Its velocity
field is not sufficient evidence of real travel against a blocked wall. The course
measures actual movement through native body positions on consecutive physics ticks.
Whole-tick displacement includes step sweeps as well as the floor-contact update;
the last `move_and_slide()` call alone cannot measure a multi-segment step.
The opt-in articulated proxy also uses observed travel for its walking animation,
so retained drive against a wall does not animate successful locomotion.

Saving during the short stair-contact transition is explicitly refused because its
pending contact is not serialized. The previous save remains available. Saving is
admitted again after stable footing; the original vault/mantle save refusal also
remains in force. Practice saves use `user://1792-ground-contact-course-v1.json`,
separate from the inherited locomotion course and all campaign slots.

Practice restoration validates the complete field set, finite motion and timing,
source revision, resolved motor tuning, runtime collision geometry, actual capsule
clearance and support before replacing the body, course observation time or pause
state. Failed load/save admission retains the current state and prior file.
Grounded restoration reconstructs native floor contact at the admitted pose;
airborne movement cannot inherit snapping from the engine's previous floor state.
Digests provide compatibility and reproducibility checks; they are not signatures
or proof that an arbitrary candidate position was visited.

## Qualification

```sh
python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
```

The new native suite separates explicit collision setup fixtures from the played
out-and-back journey. The latter begins at the normal course spawn and uses mapped
movement input throughout, without subsequent pose, velocity or progress injection.
It measures rise, horizontal displacement, support, capsule clearance, stopping,
pause and save/replay, and challenges height, ceiling, edge and geometry changes.

The dedicated workflow retains executed traces, a paused plateau snapshot, exact
source commit/tree and source archive, runtime archive checksum, native logs and
separate rendering evidence. The renderer restores the already executed snapshot
through the same course authority, validates the spatial-control summary against its
declared angle, support, descent, travel and clearance bounds, freezes motion and
verifies that drawing leaves its decoded state and original evidence bytes unchanged.

The source-bound screenshot represents that retained point in the executed route;
it is not an additional movement execution or a claim of human playtesting.
The six-hour continuation checkpoint is in [PHYSICS_BUILD_WINDOW.md](PHYSICS_BUILD_WINDOW.md).

## API references

- [CharacterBody3D floor policy and native motion](https://docs.godotengine.org/en/4.5/classes/class_characterbody3d.html)
- [PhysicsBody3D test and execution sweeps](https://docs.godotengine.org/en/4.5/classes/class_physicsbody3d.html)
- [PhysicsDirectSpaceState3D shape queries](https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html)

The workflow pins the existing Godot 4.5.1 runtime. Engine/platform determinism,
production animation and human feel require their own evidence.
