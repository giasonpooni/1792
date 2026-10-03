# Smith asset-and-mechanic production capsule

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

This optional capsule attaches the existing Home workshop to NET's executable
workcell. It is not another quest, a replacement Home world, or a change to any
player save. It reuses nine original rule/presentation dependencies, with exact revisions
selected by the source manifest.

## What is built

`workcells/baked_smith.gd` extends the original workshop presentation. It binds
serialized node paths and the original canopy materials after a compiled scene
is loaded. The same `workshop_world.sample()` method still supplies animation
and the same `workshop_rules.apply()` reducer supplies all commission transitions.
The adapter does not duplicate their mathematics or economic rules.

The source manifest selects fourteen exact files, including the shared title
licence as `workcells/NOTICE.txt`. Only `workshops/workshop_world.gd` (candidate
presentation/geometry) and `workshops/workshop_rules.gd` (candidate reducer) are
editable in this slot. Dependencies, harnesses and notices remain protected.
Original sources are frozen in an isolated NET capsule; submitting candidates
never writes back into this checkout. Code/content keeps its original title
licence and is not relicensed under NET's software licence.

The build produces a real `smith.scn` with baked descendants and resources.
Independent containers load that compiled scene, check the reducer and bindings,
render daylight/evening PNGs at the same inspection camera and tick, and create
`smith.pck` only when the operator-granted technical gates pass. A new process
loads the PCK and reaches workshop readiness on inspection tick 600.

## Inspection versus gameplay

The optional package is an inspection scene of the fictional courtyard smith.
It has a separate, explicitly labelled inspection ledger/clock, not authority over
an active Home game. E advances reserve/start/collect/deliver, Space pauses, R
resets this isolated fixture, and L changes the light. Actions here are direct
inspection controls, not qualified walking, facing, eye-ray or handover input.
The original Home journey and its tests remain the authority for those mechanics.

The programme tests the original four colliders, bounded workshop extent,
scene/resource counts, fixed action results, duplicate/early-action refusal,
refund custody, JSON ledger equality, baked hammer pose and packaged loading.
No new state is admitted by these checks. Tick 600 is the authored inspection
schedule, not a measured physical manufacturing process.

Visual acceptance is deliberately limited: real image bytes, same-state camera,
nonblank scene pixels and bounded draw/geometry counts. The current artisan,
workbench, canopy, sound and materials remain prototypes, not the intended final
high-fidelity style. Human visual review, original-player camera composition,
physical-GPU frame time, sound, historical qualification and release remain open.
Software-rendered CI images cannot certify console or reference-PC performance.

## Use

Run `python tools/check_smith_workcell.py` to check the capsule without a runtime.
NET's companion `net workcell title-configure` command verifies the manifest hash
and all source hashes before creating the slot. Its `--title-root` is this
repository's `game/` directory; `--source-profile` is
`tools/net/smith-workcell.profile.json`. Image provisioning and MCP connection
remain operator actions, not agent-selected shell/image commands.

The generated PCK can be inspected using the matching Godot 4.5.1 runtime:

```sh
godot --main-pack /absolute/path/smith.pck
```

This source branch does not add the inspection scene to the main menu, activate
DLC, enable campaign parkour, change religious-site access, relocate historic
places, or claim that the full childhood campaign or artistic target is complete.
