# Courtyard fabric detail

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

The Home courtyard now has a photo-informed detail layer built onto its existing
eight imported bays. It uses the inspected HAV01, HAV03 and HAV06 references from
the [2 October intake](GUJRANWALA_REFERENCE_BATCH_20261002.md). Each rendered mesh
retains photo IDs and the SHA-256 of its runtime evidence manifest,
`game/data/courtyard_fabric.v1.json`. That manifest also binds the full intake's
content hash and the individual photograph hashes.

| Detail | Implemented change | Evidence boundary |
| --- | --- | --- |
| Arch reveals | Eight authored five-lobed intrados profiles, with 0.46 m reveal depth, added to the existing mouldings. | Cusped openings are visible in the photographs; this profile and its dimensions are not measured or traced. |
| Grouped shafts | Four small engaged shafts around each of nine retained piers. | The grouping is a visual interpretation; native checks confirm containment inside the actual existing pier collision shapes. |
| Wall panels | Sixteen shallow framed recesses above the existing lattice panels. | Recessed panel vocabulary is observed; placement, spacing and finish are authored. |
| Roof structure | Two longitudinal timber bearers under the existing transverse rafters. | The photos show beam/ceiling-member relationships; no structural or dimensional survey is claimed. |

The warm trim tone is an art choice to improve profile readability under the
existing lighting. It does not establish an original historic pigment or exposed
material. Broad facade depth, repeated doors, surface treatment and the wider
courtyard composition remain prototype work; this increment is not a faithful
one-to-one haveli reconstruction.

The imported Blender assets and their receipts are retained. The layer adds
13 batched mesh instances and has no collision, navigation, timer or frame-update
owner. Existing refinement and greybox controls hide it with the rest of the
courtyard art. It changes no campaign state, saved data, playable bounds or routes.

## Verification

`game/tests/test_courtyard_fabric.gd` exercises the composed Home, verifies finite
mesh data and evidence bindings, checks every shaft vertex against its actual
game-owned pier shape, and tests visual cycles and removal without changing body
identities or campaign state. It is included in `tools/run_checks.py`.

The targeted native suites passed: fabric **54**, retained courtyard **123**,
material fidelity **478**, and ecology **73**, for **728 checks** with no failures.
The retained courtyard suite also exercises walking into and around the piers,
modal clock behaviour, saving, loading and visual restoration. These are targeted
checks, not a claim that the entire game suite was rerun for this increment.

`game/tests/render_courtyard_fabric.gd` captures matched before/after frontage,
column and roof views of the composed Home. The diagnostic cameras are explicitly
labelled. Capture records retain the evidence digest, camera, frozen tick,
execution identity and PNG/decoded-pixel hashes. The local rendering check also
verifies unchanged source bytes and differences in scene pixels below the caption.
It does not certify historical accuracy, final visual quality or hardware speed.

The first render made the small shaft relief difficult to read. A warmer trim
tone and closer diagnostic view were then inspected. The remaining flatness of
the facade under broad ambient light is visible in the captures and remains a
material/lighting target for subsequent work.

## Genealogical reference added alongside this pass

`data/history/ranjit_genealogy_intake_20261002.json` records the recovered
1080 × 1668 family-tree image by content hash. Its printed English caption names
*Iqbalnama-i-Maharaja Ranjit Singh*, the Maharaja Ranjit Singh Museum in Amritsar,
and “Acc. No nil.” These are caption attributions, not a newly verified museum
catalogue record. The manuscript labels remain untranscribed; the diagram's date
and relationship semantics remain unresolved. No actor ID or accepted family
relationship is changed by the image intake.
