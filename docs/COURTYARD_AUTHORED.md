# Authored courtyard increment

Copyright (c) 2026 Cartesian Graphics. All rights reserved, except attributed CC0 assets.

This is an executable refinement of the existing Home/household-smith sequence.
It is not a claim that the supplied high-fidelity visual target is achieved.

## Implemented

Two original Blender script-authored exports are now loaded by the existing Home:
an eight-instance 4.25-metre bay kit and an eleven-bone fitted childhood garment
study. Bevelled joinery, door leaves, shutters, lattice panels, rafters and plinths
replace the earlier broad veranda proxies. Opaque infill and closed backing align
with the inherited solid back wall; there is no newly enterable room.

The existing locomotion skeleton supplies pose deltas to the imported skeleton.
Godot's parent-local pose convention is used, rather than incorrectly subtracting
the rest translation. The same carried workshop load follows the fitted hand;
its custody, fee, output and inventory identity do not change. Idle appearance
follows the current look direction, including after position-only legacy saves.
This remains a preliminary body/garment study: not a finished likeness, facial
scar reconstruction, anatomical model, cloth simulation, IK system or mocap set.

Texture import settings explicitly enable mipmaps; the close character retains its
full mesh rather than automatic distance simplification. The project default now
enables 4x MSAA, equally for both A/B views; no component owns global AA state. These settings are
recorded source, not a measured physical-GPU performance guarantee.

The existing player camera has a reversible 3.5-metre/62-degree walking option.
Mounted distance remains 6.8 metres. The original walking optics remain selectable.
A compact HUD projects existing task, speech and narrator text during the active
commission; it does not create new knowledge. Distant development labels are
suppressed during that task. Earlier lessons retain their established help UI.

F7 now selects refined/earlier/greybox presentation, the existing three lighting
looks, close/original camera and compact/original HUD. These are authoring views,
not changes to time, weather or historical epoch. Original scene bytes remain intact.

## Physical and state boundary

Nine explicit pier bodies (27 simple box shapes) are added by the existing
workshop chapter. They prevent walking through the visible posts. They remain
present across visual toggles. Inherited colliders are not moved or removed.
The new standing-space obstruction is checked by the inherited load validator;
old saves that intersect a post refuse rather than being silently relocated.
There is no additional state store, clock, economic reducer or world manager.
The existing water, service, brawl and workshop receipts remain authoritative.

## Source assets and rights

`tools/art/build_courtyard.py` is the original Blender recipe. The accepted GLBs
and their output receipts live in `game/assets/courtyard/`. The first export used
Blender 4.0.2; the receipt pins those exact outputs. Rebuilding is not claimed to
produce byte-identical exports across executions or Blender installations.
Editable component .blend outputs are retained in the first export evidence,
Actions run 36542324455 / artifact 11020304020, whose archive SHA-256 is
`ca0916c2496a3c84c4e62e014f95d6d355cb5fa6265eb8103ab13a4a2dd46bfa`.
The procedural source is retained in the repository independently of that artifact.

The generic Dirt and Plastered Wall maps are CC0 material samples, not original
Cartesian Graphics textures and not evidence for Punjabi terrain or buildings.
Their authors, licence links, source URLs, original hashes and 4k-JPEG-to-1k-PNG
adaptation are recorded in [the surface inventory](../game/assets/surfaces/README.md)
and `sources.json`. The acquisition tool is explicit and offline from the game's
perspective; neither launch nor ordinary tests download assets.

The newer user-supplied images and STL are separately recorded in
[reference intake](REFERENCE_BATCH_20260929.md). Their pixels and geometry are
not included in the game or repository. Receiving a reference is not a licence.

## Execute and inspect

Open `game/project.godot` in Godot 4.5.1 and choose the existing Home territory.
The smith commission remains available after the inquiry and household allowance.
No Blender installation, Python server or NET process is needed to play.

```sh
python tools/check_courtyard.py
python tools/run_checks.py --godot /path/to/godot
python tools/capture_home_art.py --profile courtyard --xvfb --godot /path/to/godot --output /existing-parent/new-run
```

Omit `--xvfb` outside a headless Linux environment. Existing `home` and `workshop`
capture profiles remain available. The courtyard profile executes the inherited
input-driven commission from one declared completed-inquiry fixture. It records
actual motor/camera observations during the outward walk, then renders those
observations through the same player-camera component. This is observation replay,
not a fresh camera-rail animation, a newly played full childhood or live-GPU FPS.
Six stills include same-state/same-camera A/B views, lighting and compact controls.
Motion images are content checked; their camera/body reconstruction tolerance is
1e-5 local metres/component units. The encoded video uses recorded simulation-tick
spacing, not elapsed rendering speed. No interpolation quality claim is made.
Source changes during capture invalidate qualification.

## What remains unfinished

Horse, smith and other supporting figures remain proxies. The child's face,
hands, garment deformation and historical proportions need a dedicated art pass.
The current plaster/wood/ground combination is a material study, not finished
asset direction. Repeated bays, horizon foliage and scene composition still need
artistic work. Test counts do not certify beauty or parity with the supplied games.

The full geographic envelope and evidence-bounded 1:1 target remain unchanged;
this 56 x 56 metre authored Home is still compressed, and no terrain was acquired.
Religious sites remain exterior-only; religious figures remain unembodied.
Ranjit's childhood through the Lahore prelude stays first, followed by his full
life before DLC production. Main and unrelated draft branches are not merged here.
