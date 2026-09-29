# Active traversal saves and reachable hand contact

This increment extends the PR #26 shared movement foundation. The actual Player
scene, controller, capsule and 60 Hz engine physics remain authoritative. There
is no new campaign, duplicate movement engine, service, registry or story entry.

## Play the existing course

Open `game/project.godot` in **Godot 4.5.1 Standard** and choose **Movement
qualification · shared motor / no story progress**. Walk down the central lane,
vault the low rail, mantle onto the next platform, jump the gap, drop and exit.
The dimensions, layout and existing motion rates are retained.

| Input | Action |
| --- | --- |
| WASD / left stick | Move |
| Shift / L3 | Run |
| Mouse / right stick | Look |
| Space / A | Jump |
| V / X | Vault or mantle an admitted marked obstacle |
| Escape / Start | Pause, including an active traversal |
| F5 / F9 | Save/load, including a vault or mantle in progress |
| R / F1 | Reset practice / return to the main menu |

To inspect the hand contact, walk close to the front of the mantle platform, face
it and press V. Pause at the beginning of the climb. The original blockout now
has small palm meshes and a limited two-bone contact solve. The hand placement is
not guaranteed from every admitted approach: an unreachable target is released.
No input locks the entire character to the ledge, and this is not a ledge-hang state.

## Persistence closes the previous explicit refusal

The new slot is `user://1792-locomotion-contact-v1.json`. The older
`1792-locomotion-course-v1.json` is untouched. The course envelope remains
`locomotion-course-save.v1`; its bound source/tuning digest changes. Older course
revisions are not silently relabelled or imported. Campaign slots are untouched.

The existing `locomotion.v1` snapshot keeps position, velocity, grounding, camera,
edge grace and buffered input. **Only while a traversal is active** it adds a
bounded `traversal-contact.v1` record containing:

- The code-owned action kind, admitted origin and horizontal forward direction.
- Three admitted lift/cross/lower waypoints and the current segment index.
- The physical ledge contact and distinct obstacle/landing support bindings.

A binding has a scene-authored stable ID and a collision fingerprint. It never
contains a NodePath, executable selector, runtime instance ID, or a provider name.
The scene declares the resolution scope; saved data cannot choose a different
world to search. Ambiguous IDs refuse rather than picking the first object.

Fingerprints cover the static body's world transform, collision layers/masks,
traversable flag, and direct box-shape transforms, dimensions, margin and disabled
status. The current bounded implementation admits at most eight direct box shapes
per body and scans at most 256 static bodies. It rejects conveyor velocities,
non-box contact shapes and missing/queued-for-deletion objects. This is not a
claim to serialize moving platforms, arbitrary meshes or streamed worlds.

### Validate before changing live state

Restore checks the course/source/timing envelope, ordinary motion shape and
current capsule clearance first. For an active traversal it then resolves both
supports and **re-runs the original probe from the retained origin**, comparing
all waypoints, kind, support identities and contact. The saved pose must lie on
the current path segment. It rechecks the remaining endpoint clearances and
collision sweeps before changing the live body, route, timers, camera or tick.

A 0.0001 local-metre tolerance accommodates JSON/Vector3 path reconstruction; it
is not extra reach assistance. Observation replay comparisons use exact decoded
JSON state, not this tolerance. Shape sweeps are paired with overlap queries.

The conservative original-path recheck can reject a new obstruction behind the
saved character as well as one ahead. This deliberately bounds the prototype;
it does not promise that every environmentally altered world can resume a contact.
The unchanged world does resume every tested segment of both actions.

On success, physical movement continues from the saved point through the remaining
segments using the same collision motor. Loading does not teleport to the action's
completion point. Future observation samples are discarded when rolling back.
Rejection preserves the current body, route, tick and samples. A rejected save
retains the last good file. File writes still stage and rename; Windows replacement
and duplicate-JSON-key hardening remain unqualified.

The digests establish reproducibility and compatibility, **not authenticity or
anti-cheat**. A self-consistent edited snapshot is not independent evidence that
a route was physically played or an event historically occurred.

### Engine floor-cache correction

Fresh-process comparison exposed a hidden previous-floor cache in
`CharacterBody3D`: a producer that had stood on the ground before climbing could
snap down differently from a newly created consumer after the same saved climb.
The opt-in controller now temporarily disables floor snap during explicitly
airborne movement. It restores the configured snap length immediately afterward.
The persisted `_grounded` state, rather than stale engine contact, determines this
choice. Legacy campaign movement is untouched. Resumed and uninterrupted traces
now compare exactly in the checked cases.

The first cross-rate restart driver also stepped `move_and_slide` outside a physics
frame, unintentionally allowing its internal integration delta to follow render
scheduling. The corrected driver awaits the actual physics frame for every motor
command. This was a test-harness correction, not a relaxation of equality.

## Limited two-bone contact, not completed climbing animation

`two_bone_ik.gd` solves a fixed-length two-segment chain by the law of cosines. Both
segments remain 0.28 local metres in this proxy. Singular, non-finite and unreachable
targets are refused. A collinear pole uses a deterministic perpendicular fallback.

The shared motor exposes **read-only** hand targets probed against the admitted
support. The proxy faces the admitted traversal direction, not the moving camera.
For each reachable target it checks shoulder-to-elbow and elbow-to-hand collision
rays before applying skeleton-local bone poses. Endpoint error is measured from
the actual transformed forearm endpoint, not just the requested target.

The solve writes only the skeleton and visual orientation. It cannot change body
position, collision, trajectory, clock, inventory or knowledge. Loading while
paused reconstructs the pose immediately with zero animation-time advance.
Changed supports, reach loss or completed traversal release the contact.

This is an early **reachable-hand phase**. The current lift/cross/lower trajectory
is retained at 4 m/s, without momentum preservation. Arms outside reach revert to
the procedural traversal pose. There is no foot IK, skinning, finger grip, palm
orientation solve, full-volume arm collision, foot planting, root motion, smooth
contact blending, ledge hanging or full-body biomechanical vault. Collision rays
are not equivalent to limb-volume clearance. Human animation-quality approval
remains outstanding.

## Checks and retained observations

```sh
python tools/run_checks.py --godot /path/to/godot
python tools/check_contact_restart.py --godot /path/to/godot
```

The first command retains all prior native/Python suites and adds
`test_traversal_contact.gd` and the process-restart campaign. The prior locomotion
suite keeps its 91 assertions; exactly two old assertions expecting refused
mid-vault saving are changed to require successful saving with a contact record.
No unrelated inherited test is removed or weakened.

New native fixtures cover both actions in all three segments, file save/load,
whole-state rewind, a newly created scene with new runtime object handles,
malformed records and altered supports. Refusal fixtures cover source and landing
removal/movement, changed dimensions/layers/flags, duplicate IDs, conveyors,
obstructions, forged points, wrong segments and impossible motion fields. Hand
fixtures verify fixed chain lengths, actual endpoints, camera independence,
read-only pose reconstruction and reach release.

A normal-spawn journey uses movement and action inputs to save/reload the actual
vault and mantle. No position or progress injection occurs in that journey. Other
physical and rendering fixtures explicitly declare their initial setup.

`check_contact_restart.py` starts **six producer processes** (two actions by three
segments) and **18 new consumer processes** (the same six saves at render schedules
30/60/144). Each producer writes a real course save; a fresh consumer resolves
new engine objects from the stable IDs. Every comparison covers the initial saved
state and 80 subsequent 60 Hz physical ticks. Exact JSON state equality is required,
including the eventual landing. These are 18 comparisons, not 1,440 unique scenarios.
They establish only this engine/platform/profile, not cross-platform determinism.

`render_traversal_contact.gd` captures five actual software-rendered fixtures:
reachable mantle hands, paused restored hands from the other side, mid-vault save,
resumed landing, and an 800x450 compact view. Close-up inspection hides only floating station captions, not geometry or actors.
It checks image creation, UI bounds, camera-to-body visibility and hand endpoint/framing constraints. Visual inspection remains distinct from
native state assertions and from human playtesting. The inherited five movement
captures are retained and rerun as well.

The workflow retains source commit/tree, source.tar, engine ZIP digest, native logs,
restart traces, screenshots and separately identified verification records. Model,
operation, execution and observation/verification identities are not conflated.
No NET adapter or proof-system integration is claimed.

## Admission boundary and next work

Campaign `movement_profile = 0` and `traversal_enabled = false` remain unchanged.
The original player PackedScene, capsule dimensions, horse mechanics, campaign
saves, economy, stories, research data and copyright notices remain. The separate
unpublished anthology and other town/workshop/social-field/Mahan branches are not
silently absorbed, discarded or jointly qualified.

Next work remains contact blending and complete animation, vertical interaction
checks, companion capability/alternate-route behavior, campaign motion snapshot
integration and a representative Gujranwala route. Combat and mounted transitions
remain separate foundation tasks. This increment does not yet enable campaign
parkour, add a story, complete the city, export a player build or qualify Windows,
physical gamepads, consoles, human feel or physical-GPU performance.

## Primary API references consulted

- [PhysicsBody3D](https://docs.godotengine.org/en/4.5/classes/class_physicsbody3d.html): non-mutating motion checks and collision movement.
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html): overlap queries versus shape sweeps.
- [Skeleton3D](https://docs.godotengine.org/en/4.5/classes/class_skeleton3d.html): skeleton-relative global bone poses.
- [SkeletonIK3D](https://docs.godotengine.org/en/4.5/classes/class_skeletonik3d.html): deprecated API reviewed; not used as a dependency.

These references describe engine APIs. The original solver, game rules and fixtures
are qualified by execution, not by citing an API reference.
