# Third-party notices and inventory

1792's original project material is attributed to Cartesian Graphics under the [root notice](LICENSE). Third-party material retains its respective rights holders and licences. Nothing in this document expands the proprietary notice to cover upstream material.

## Inspection scope

This initial inventory is based on the `main` source-tree snapshot at commit `37012b179f9cd369407e3f71909bd1cca28beaf2` on 2026-09-28. Its complete tracked tree contains the Godot project, project scripts/scenes, JSON world data/schema, Markdown documents, and `.gitignore`; it lists no bundled engine binary, vendored library directory, package lockfile, imported media asset, or font file.

This is a bounded source-tree inventory, **not** a scan of the separate feature branches, ignored/local files, external tools, or exported builds. It does not independently establish authorship or prove that every snippet was written from scratch. Reinspect dependencies and assets when feature branches are integrated or a build is packaged.

## Godot Engine

1792 uses Godot through `game/project.godot`. Godot Engine is supplied separately under the MIT licence; the proprietary notice for 1792 does not apply to the engine. Its original copyright attribution is:

> Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
> Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

An unmodified copy of the engine's MIT text is retained at [Godot-MIT.txt](licenses/third-party/Godot-MIT.txt). Its source is [Godot's `4.5.1-stable` LICENSE.txt](https://github.com/godotengine/godot/blob/4.5.1-stable/LICENSE.txt), upstream blob `0e3ba08d6b2e8cf435241829c96f10b74e4356fe`. This pins the provenance of the notice copy; it does **not** declare or change the game's engine version.

Godot's official [licensing page](https://godotengine.org/license/) explains the distinction between the engine licence and game content. Its [licence-compliance guide](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html) explains distribution obligations.

**Before shipping:** include the notices required for the exact engine/export-template build and its bundled third-party libraries. Godot's main MIT text alone is not an exhaustive notice bundle for all engine dependencies. Keep any required `COPYRIGHT.txt`, library notices, font notices, and attribution accessible in the distribution. This change does not add export packaging or a runtime credits screen.

## Other named systems

### Pinned Godot JSON verification adapter (2026-10-02 increment)

`tools/godot451_json.py` adapts the Godot 4.5.1 decimal-number parser into a
bounded Python verification helper. Its upstream sources are `core/io/json.cpp`
(blob `34f001a228237a8fc9c0d10f1908ba0034d11de8`) and
`core/string/ustring.cpp` (blob `45d8497af81a905599bd7790c777c27d256da6c3`),
both at the [`4.5.1-stable` tag](https://github.com/godotengine/godot/tree/4.5.1-stable).
Godot Engine contributors, Juan Linietsky and Ariel Manzur retain their original
copyright and **MIT** terms. The complete MIT notice and pinned source references
are retained in the helper; the unchanged notice also remains at
`licenses/third-party/Godot-MIT.txt`. The project's proprietary notice does not
replace these upstream rights.

The adaptation preserves the native numeric operation sequence and adds strict
JSON/finite-size checks, exact raw clock binding and whole cold-save comparison.
It is used by evidence verification; it does not replace the engine or game save
authority. Redistributed copies must retain the included upstream MIT notice.

Bevy, Blender, and Notations Engineering Terminal are architecture or tool references in the inspected README, not vendored implementations in that snapshot. Mentioning or using them does not transfer their ownership to Cartesian Graphics or apply 1792's proprietary notice to them. Record the applicable version and terms when any engine, plug-in, library, adapter, or content is actually incorporated or distributed.

## Additions and release review

For each incoming third-party component, record the exact repository paths, upstream source, pinned revision or version, actual copyright holder, licence identifier and text, modifications, and release obligations. Retain permission evidence privately where necessary. Follow [asset intake](docs/ASSET_LICENSING.md) for media and [contribution review](CONTRIBUTING.md) for externally authored code.

Unresolved rights are not cleared by this inventory. Preserve applicable upstream terms and obtain review before combining licences that could conflict with the intended distribution.

## Courtyard surface samples (2026-09-29 increment)

`game/assets/surfaces/dirt_*_1k.png`: Dirt by Charlotte Baglioni, Poly Haven.
`game/assets/surfaces/plastered_wall_*_1k.png`: Plastered Wall by Amal Kumar,
Poly Haven. These retain **CC0-1.0**; the proprietary game notice does not apply
to them. See the [surface inventory](game/assets/surfaces/README.md) and accompanying
`sources.json` for source URLs, licence links, upstream/output hashes and resizing.
They are generic material samples, not evidence for a historical building/site.

Blender is an external build tool, not a bundled engine dependency. Original
script-generated geometry and source code remain project material. User-supplied
reference images and `desert_cavalier(1).stl` were not redistributed or imported.
