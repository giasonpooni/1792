# Home visual study — playable presentation increment

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## Scope and launch

This extends the same `1792 / Buddh Singh / Home territory` entry, stacked on the
historical-world foundation. It is not a second world, new campaign, different
engine or a migration to surveyed Gujranwala. Ranjit's childhood through the Lahore
prelude remains first, followed by his complete life before DLC production.

Press **F7** for a paused presentation control: compare the retained greybox with
the material study, or choose daylight, golden hour and evening. These are **look
development presets**, not in-game time travel, historical weather or a day/night
simulation. F7 returns to the same childhood scene. F2 research, F3 atlas, F4
subjective perception and T youth catalogue retain their existing meanings.

## What changes on screen

- Original analytic plaster/brick, timber, earth and woven-surface shaders.
  Brick course size is an authored material parameter, not a measured period sample.
- A continuous-mesh veranda arch kit, shutter detailing, caps and rafters using
  the existing prototype's footprint; no sacred building is introduced.
- Stable roof cloth, timber braces, rope bindings and simple tack detail.
- Market awning and original turned pottery placed on the existing solid counter.
- Instanced, seeded foliage clusters replacing the former box-shaped crowns.
- Costume proxies for the existing static people, a reuse of the qualified
  locomotion skeleton for Buddh, and rounded horse/retainer presentation. These
  are still **proxies, not production character art, a historical likeness, facial
  performance, cloth physics, motion capture or completed anatomical modelling**.
- Three art-directed environment/light presets with reversible original resources.

No third-party image, texture, scan, mesh, sound or museum reproduction is bundled.
All new shaders and generated mesh recipes are original project material. The
reference packet's craft categories remain research leads, not authenticated
relics, garments or specific Gujranwala workshop biographies. See
[MATERIAL_CULTURE_INTAKE.md](MATERIAL_CULTURE_INTAKE.md).

## Protected execution boundaries

`art_chapter.gd` extends `atlas_chapter.gd`, which retains the active youth/service
controller. `home_art.gd` replaces only mesh presentation and the locally-owned
lighting resources. All original collision shapes, transforms, layers, actors,
physics methods, routes, save writers and domain validators remain authoritative.
No new gameplay witnesses, inventory, trading or workshop quest is claimed.

The costume is attached to the existing trainer mesh so the practice telegraph
still propagates. The player's costume is hidden immediately when the inherited
avatar is hidden for mounting. The base player capsule, conservative horse hull,
combat and camera ownership are not replaced by art geometry.

Cloth motion and the new player-pose adapter sample the existing chapter tick.
They do not use shader `TIME`, start another simulation timer or advance the world.
Lighting controls cannot modify a save. Disabling the study restores the exact
old mesh/material/scale/layer and environment resources. Removing the component
also cleans its externally attached costume and foliage nodes.

A compact-window issue in the inherited modal layout was found while qualifying
F7. The new controller clears stale child minimum sizes before applying the same
layout calculation. Text/actions remain in the existing scroll container; this
does not replace the UI or modify gameplay state.

The full-envelope atlas and its 252 **missing** acquisition cells are untouched.
No terrain data has been acquired by this visual increment. The 56 x 56 m retained
Home remains an explicitly compressed authored scene, not the target 1:1 world.

## Build, run, observe, compare

Use the existing Godot 4.5.1 reference executable:

```sh
python tools/check_home_art.py
python tools/run_checks.py --godot /path/to/godot
python tools/capture_home_art.py --godot /path/to/godot --output /existing-parent/new-capture-run
```

The capture command exclusively creates a new directory and refuses an existing
one. It runs import and an actual renderer, retains logs, per-source hashes,
source/operation/execution identity, PNG hashes, dimensions, device description,
draw-call/primitive counters and the capture batch. It uses Xvfb when appropriate
on Linux; it does not acquire assets, contact providers or start a service.
A dirty worktree is explicitly unqualified by commit; generated Godot UID sidecars
are excluded because this branch uses retained path references rather than UID
imports. Source-content hashes remain present for local experiments.

Eight captures cover baseline/daylight/golden/evening courtyard comparisons,
stable, market, the original player camera with HUD, and the F7 control at 800 x
450. Inspection-camera images are identified separately from actual player-camera
images. Scene-pixel hashes omit the upper caption so changed labels alone cannot
satisfy the lighting comparison. The original scene is not rebuilt between the
baseline and dressed captures.

Native checks compare every collision object before and after attachment, cycle
presentation restoration, retain trainer/rider visibility, inspect swept routes,
exercise actual F-key/modal/button calls, freeze the world under the art panel,
and round-trip the existing save. The numerous per-mesh assertions are not
independent gameplay scenarios or a measure of artistic quality.

Software-rendered images are evidence of execution, not a reference-GPU frame-rate
qualification, shipping console support, user playtesting or AAA visual completion.
No audio has been added in this increment. Real terrain acquisition, researched
footprints, production clothing/characters, better animation and inhabited workshop
story content remain subsequent work.

## Technical references

- Godot 4.5 spatial shader reference: https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/spatial_shader.html
- Godot 4.5 MultiMesh: https://docs.godotengine.org/en/4.5/classes/class_multimesh.html
- Godot 4.5 Environment: https://docs.godotengine.org/en/4.5/classes/class_environment.html

These document engine behaviour, not historical material culture. The existing
research manifest remains the evidence reference and is not rewritten by this kit.

On Linux with a stale or occupied `DISPLAY`, pass `--xvfb` to the capture tool
to create a private display. This still renders actual engine frames; headless
imports alone never count as visual qualification.
