# Movement foundation: qualification before content multiplication

> This page retains the original PR #26 foundation description. The current branch
> extends it with [active traversal saves and reachable hand contact](TRAVERSAL_CONTACT.md).
> Its earlier mid-vault save refusal, no-hand-IK scope, old course slot, and unchanged-test
> statements describe that baseline, not the current contact increment. The campaign
> admission boundary and movement defaults remain unchanged.

This increment extends the existing Player scene and motor. It does not add another
player controller, import a second physics engine, rewrite a campaign, or declare
the production vertical slice complete.

## Play

Open `game/project.godot` in **Godot 4.5.1 Standard** and select **Movement
qualification · shared motor / no story progress**. The retained Home territory,
political/perception, and Lahore entries remain available.

The development course uses the same `game/player/player.tscn` and `player.gd`
as the game. It runs as the current scene; the campaign is not running alongside
it. Practice saves cannot be imported as campaign saves.

Walk down the lane, face the low gold rail and press **V** to vault. Approach the
next gold platform and press **V** to mantle. Run along that platform and press
**Space** before its rear edge to cross the **2.5-metre** gap. Land on the next
platform, walk off onto the lower ground, and continue through the exit gate.
The side stations test a low ceiling, an unmarked wall, an over-height obstacle,
and a 30-degree slope. All dimensions are authored game units, not measurements
of historical Gujranwala or human performance.

| Input | Operation |
| --- | --- |
| WASD / left stick | Move; analog strength is retained |
| Shift / left-stick click | Run |
| Mouse / right stick | Look in the qualification course |
| Space / gamepad A | Jump in the course |
| V / gamepad X | Qualified vault or mantle in the course |
| Escape / Start | Pause course motion without discarding velocity |
| R | Reset practice; not a campaign rewind |
| F5 / F9 | Save/load the separate course slot |
| F1 | Return to the existing main menu |

Button names describe the conventional Xbox-style layout. Native tests inject
joypad-axis/button events through Godot's InputMap; physical controllers, Windows,
console certification and full campaign UI/gamepad navigation are not qualified.

## What changes in existing gameplay

The shared input path now preserves analog magnitude. Full keyboard input retains
its original response by default. Existing scene/player exports and the 0.35 m
radius / 1.6 m capsule remain in place. The previous input deadzone was 0.5; it is
now explicitly 0.2 for the added stick mappings. Mouse yaw is wrapped to a finite
angle; existing sensitivity and pitch clamps remain.

**Two declared response profiles, one implementation and one physical body:**

- `movement_profile = 0` retains the qualified legacy horizontal basis and
  component-wise acceleration for the existing campaign scenes.
- `movement_profile = 1` uses a yaw-only horizontal basis and a vector-magnitude
  acceleration bound. The course selects this isotropic profile explicitly.

The first global isotropic trial broke four existing aftermath route assertions:
straight-line scripted approaches became pinned by the courier and a stable post.
Those routes had previously passed with the legacy axis-dependent transient.
The correction preserves the existing profile rather than shrinking colliders,
removing NPCs, weakening assertions, or silently declaring those journeys obsolete.
Every inherited test file remains unchanged. Campaign promotion of the new profile
requires route and feel qualification, not merely editing the export default.

`traversal_enabled` remains **false in campaign scenes**. Current campaign saves
and several interaction/companion checks assume grounded, horizontally measured
travel. This release does not turn every roof into a safe campaign interaction
surface or pretend old saves can restore airborne motion. The new capabilities
are executable on the actual shared motor but are admitted only by the course.

## Actual motion rules

| Parameter | Isotropic course value |
| --- | ---: |
| Walk / run target | 4.5 / 7.5 m/s |
| Ground acceleration and braking | 18 m/s² vector bound |
| Air acceleration | 6 m/s² |
| Gravity | 22 m/s² |
| Initial jump velocity | 7.5 m/s |
| Edge grace / pre-landing input buffer | 0.10 / 0.12 s |
| Maximum downward velocity | 50 m/s |
| Obstacle height envelope | 0.35–1.45 m |
| Low-vault height ceiling | 0.8 m |
| Forward probe reach | 1.15 m |
| Swept traversal path speed | 4 m/s |
| Fixed physics step used for qualification | 60 Hz |

These values are versioned design choices, not locked production balancing.
A held jump does not repeatedly launch the character. Edge grace is earned by
recent support and consumed by jumping. Buffered input may trigger shortly after
landing. An external load-speed constraint prevents admission of jump/vault actions
in the opt-in traversal profile; inherited campaign load rules remain unchanged.

### Vault and mantle admission

Only marked **static collision bodies** can be traversal targets. Art does not
implicitly become a handhold. The probe checks a front face, a sufficiently level
top on the same collider, height bounds, destination support, destination capsule
clearance, and the complete lift/cross/lower body path. A thin low obstacle also
needs a detectable far edge and landing support before it is classified as a vault.

Execution uses `move_and_collide` on each segment, not a Tween assigning the body
transform. A new obstacle interrupts movement where the collision occurs. A deleted
or transformed support invalidates the contact. The implementation is deliberately
conservative: no curved/moving ledges, wall running, ledge hanging, corner transfers,
free climbing, automatic step-up, root-motion warping or arbitrary geometry inference.

The rectangular path is a **provisional movement primitive**, not a finished
biomechanical vault animation. It does not preserve running momentum through a vault.

### Camera and visible body

The course uses the retained spring-arm camera, with a small sphere sweep added
in the course configuration. It retracts under obstruction. The two camera input
paths feed the same pivot, and camera pitch does not reduce isotropic forward speed.

An original **11-bone procedural skeleton** supplies an articulated blockout with
velocity-driven limb motion and a provisional traversal pose. It writes only its
own skeleton/visual orientation. It is not a skinned production character, motion
capture, hand/foot IK, root motion, clinical vision simulation or a new collision
hull. Pausing freezes this proxy as well as course motion. Native tests check that
its head is at the expected skeletal height and that it cannot mutate the motor.

## Persistence and failure behavior

`user://1792-locomotion-course-v1.json` contains only the course identity, physical
source/tuning digests, fixed-step declaration, observation tick and motor snapshot.
The snapshot includes position, velocity, support flag, grace/buffer timers and
camera orientation. A mid-air save restores velocity, not a fake grounded stance.

A candidate is checked before the current body or course tick is replaced. Foreign
schemas, different course/motor/tuning identities, malformed values, impossible
speed, unsupported grounded poses and obstructed capsules are refused. Loading
clears the discarded trace rather than mixing future observations into the earlier
run. File size is bounded to 8 KiB, and writing uses a temporary file before rename.
Windows replacement and duplicate-JSON-key hardening are not qualified.

A **mid-vault/mid-mantle save is explicitly refused** because the committed contact
and remaining route are not yet serialized. The previous manual save is retained.
Pause/resume during that motion works. This limitation must be removed before
traversal is promoted to the full campaign persistence contract.

Digests are reproducibility/compatibility checks, not signatures, anti-cheat,
authenticated history, or a proof that arbitrary saved positions were physically
visited. Runtime geometry is rechecked at the candidate capsule; the implementation
does not claim to reconstruct all external edits to an entire world.

## Execute and inspect

```sh
python tools/run_checks.py --godot /path/to/godot
python tools/check_locomotion_rates.py --godot /path/to/godot
```

The original runner retains every earlier suite and adds the native movement suite
and a render-schedule replay comparison. `test_locomotion.gd` distinguishes explicit
physical setup fixtures from a connected input-driven course journey. The latter
starts at the normal course spawn; there are no subsequent pose, velocity or
progress injections. It physically vaults, mantles, jumps, lands, drops and exits.

The native suite covers analog and actual injected joypad input, diagonal response,
full-speed movement, camera pitch, jump shape, held input, coyote expiry, buffering,
ceiling collision, slope traversal, blocked destinations, late obstacles, moved
supports, proxy isolation, pause, mid-air replay, malformed saves, file roundtrips,
mid-vault save refusal and preservation of the old save file.

`test_locomotion_rate.gd` runs the **same 180 physics-tick commands** at render
schedules of 30, 60 and 144. Python compares every recorded tick/position/velocity/
mode and the source identities. It also records a separately canonicalized
observation digest. This checks that fixture on the pinned engine/platform; it
is not proof of cross-platform floating-point determinism, input latency, frame-time
budgets, or physical-GPU performance. Real-time profiling and human playtesting
remain necessary.

`render_locomotion.gd` captures five declared presentation fixtures using actual
software rendering. The compact fixture sets an 800×450 layout canvas explicitly;
it does not claim every inherited campaign panel was redesigned. The workflow
retains these images, logs, exact source, runtime checksum, the played-route trace,
rate observations, and their separate verification report.

## Preserved work and next admission boundary

The published youth-bazaar/service branch is the integration base. All original
story catalogue records, gameplay authorities, receipts, saves, horse mechanics,
vision experiments and Cartesian Graphics notices are retained. The unpublished
51-contract anthology package is not overwritten or silently published here.
Other town/workshop/social-field/Mahan drafts remain independently scoped.

Godot remains the sole game runtime. NET/SCR/Blender/native-language providers are
not required to play this course. No duplicate scientific execution system or new
NET adapter is claimed by retaining local motion evidence.

The next gate is to integrate an animation-quality contact solution and serialize
committed traversal, then qualify vertical interactions, recovery and companion
capabilities in a representative campaign route. Combat unification and mounted
transitions remain separate foundation work; this patch does not claim to finish them.

## Primary API references consulted

- [CharacterBody3D](https://docs.godotengine.org/en/4.5/classes/class_characterbody3d.html)
- [PhysicsBody3D sweeps and motion](https://docs.godotengine.org/en/4.5/classes/class_physicsbody3d.html)
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate3d.html)
- [Input vectors and actions](https://docs.godotengine.org/en/4.5/classes/class_input.html)
- [SpringArm3D](https://docs.godotengine.org/en/4.5/classes/class_springarm3d.html)
- [Skeleton3D](https://docs.godotengine.org/en/4.5/classes/class_skeleton3d.html)

These references describe the APIs, not evidence that this game's design is fun,
production-ready or historically accurate.
