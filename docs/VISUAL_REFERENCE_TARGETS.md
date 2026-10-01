# Visual reference targets: lived-in historical realism

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

Status: reference intake and production targets, not newly implemented art.
Recorded 2026-09-29 from three user-supplied screenshots. This is their working
translation into the existing [visual direction](VISUAL_PRODUCTION.md), not a
claim that every depicted feature or a particular rendering technique is approved.

## The intended level of finish

Grounded, tactile, luminous historical realism remains the direction. The current
low-detail bodies, horse, broad wall surfaces and repeated forms are development
proxies, not the proposed shipping aesthetic. Passing the gameplay tests does not
approve their visual quality. Adding more procedural objects does not, by itself,
close that gap.

The reference is the coherence of the complete playable frame: character,
architecture, surfaces, light, inhabitants and distance. It is not a request to
copy a European city, adult costume, ornament set or skyline into childhood Punjab.

## Three complementary benchmarks

| Reference | Visible qualities to pursue | Translation for 1792 |
| --- | --- | --- |
| R1: street, shown in a split comparison | Street depth, varied foreground surfaces, inhabited edges, layered facades, stalls and a legible moving character | Research-appropriate bazaar fabric; convincing ground, timber, plaster, cloth and pottery; purposeful nearby activity rather than a uniform crowd count |
| R2: richly furnished, sunlit interior | Doorway framing, directional light, material contrast, ceiling/floor/wall continuity, furnished social space | A secular household threshold and adjoining room first; later court interiors only when their place, date and use support them |
| R3: elevated roofscape | Strong near silhouette, intermediate roof layers, distant landmarks and atmospheric separation | Period/place-specific roof and courtyard structure; visible height, routes and sightlines without importing the pictured monumental skyline |

R1 is not evidence of a particular platform's improvement. These stills do not
establish frame rate, lighting implementation, crowd simulation, traversal
availability or the fidelity of unseen space. Technical methods require their own
implementation and measurements.

## First production benchmark: one inhabited courtyard sequence

Use the existing Home courtyard, veranda, stable approach and smith interaction.
This is a small visual-production workload within the current compressed Home,
not a replacement for the full-map, evidence-bounded 1:1 reconstruction target.
It must remain recognizably the same playable place and household task.

Author one coherent facade/threshold kit and its material set before proliferating
locations: properly shaped edges, construction joints, shutters, recesses and
purposeful trim. Dress a secular adjoining space with researched or explicitly
fictional furnishings. A newly enterable room needs collision, access and save
qualification; a closed decorative door must not imply playable access.

Replace the child and horse proxies with proportioned, rigged assets and approved
garment/tack designs. The child's identity and age must not be inferred from the
adult reference costume. Test supported walking, carrying, riding and interaction
poses on the existing motor; unsupported actions remain unimplemented.

Materials should distinguish their physical character and use: dry earth should
not read like polished stone; plaster, rough timber, woven cloth and metal should
not share one gloss response. Wear should follow plausible contact, exposure and
repair rather than uniform noise. Specific construction, decoration, dress and
furnishing choices remain subject to the existing historical method.

Compose and inspect normal gameplay views as well as close detail. Keep a clear
movement corridor through purposeful clusters of objects and activity. Nearby
workers need readable hands, tools and tasks; a static visual extra is not a new
witness, employee or autonomous agent. Richness does not require making every
surface ornate or every open space crowded.

## Acceptance is visual and executable

The proposed review sequence is courtyard approach, smith handover, work view,
collection and return, with a secular threshold view once that space is actually
implemented. It reuses the existing task and clock; it is not another quest or a
newly promised amount of authored playtime.

Review close, ordinary third-person and distant views under daylight and evening
looks. Retain the same camera/state for revision comparisons. A beautiful special
angle cannot conceal a broken ordinary view. Native captures establish execution;
concept illustrations must be labelled and cannot substitute for rendered play.

Record the asset source/export identity, scene revision, camera, supported motion,
lighting preset, renderer, hardware and measured frame-time/memory results. Human
review decides composition, material credibility, silhouette, animation and sound.
No image-similarity threshold or native assertion total certifies artistic parity.
Software-rendered CI remains useful but does not qualify the reference PC or
consoles. The existing provisional performance target is not a measured result.

Keep inherited gameplay, collision, save/load, custody, access and pause checks.
Separate decorative skyline geometry from accessible terrain. In this baseline,
campaign parkour remains disabled; the third reference does not silently enable
it. Roof traversal promotion still needs the existing movement qualification.

## Production ownership and protected scope

Blender remains the authoring surface, Godot the active runtime, and NET the
production workbench. Extend that loop rather than adding another renderer,
world clock, inventory authority or project-specific workbench. Automation should
repeat approved asset/export/inspection work, not replace artistic acceptance.

Ranjit's childhood through the Lahore prelude remains first, his complete life
next, DLC afterward. Religious figures are not embodied; religious sites remain
exterior-only and non-enterable. Sada Kaur and Adina Beg remain non-playable. A
luxurious interior reference does not override those rules or import later
imperial acquisitions into childhood. Buddh's lived knowledge remains separate
from retrospective narration and authoring references.

## Reference custody

The screenshots remain user-supplied visual references. No screenshot pixels,
extracted textures, traced models, game audio or character assets are committed by
this intake. The following SHA-256 values identify the supplied files only; they
do not establish original publication, historical truth or redistribution rights.

| ID | Supplied-file SHA-256 |
| --- | --- |
| R1 | `460f48d7d7e506705a470edbbdb405040112f5f220d306d3f6842179ecd86b2d` |
| R2 | `b68fbd87edefc4cf74d620638d93d122cae89e97bbc6322fdd43cbe310ae8196` |
| R3 | `7d9fe0664aa75901b03752875b37c3600bfbcdfd643f239a98764f75ce3f5d15` |

Implementation baseline: workshop PR #36 at
`e911f433ebe67984c2af375f39becf510ebc68dc`. Its qualified functional prototype and
[visual study](HOME_VISUAL_STUDY.md) are foundations, not completion of this target.
See [workshop integration](HOME_WORKSHOP_INTEGRATION.md) for the current playable
loop and [historical method](HISTORICAL_METHOD.md) for evidence handling.
