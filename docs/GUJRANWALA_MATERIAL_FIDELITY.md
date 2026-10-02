# Gujranwala material and vessel fidelity

This increment extends the beauty, depth/patina and microdetail passes on the existing Home. It improves the surfaces and pottery already composed in the court. It adds no prop locations or gameplay mechanics.

## Existing surfaces

A reversible material projection addresses 222 declared meshes in the three craft layers:

- plaster accents, parapets, repair/patina fields and pavilion cornices use the existing generic CC0 plaster height and roughness maps;
- jali bars, timber reveals and pavilion columns use directional analytic grain;
- market/storage vessels use subdued turning bands and pore variation;
- existing textiles and storage mats use filtered weave.

The original pigment palette remains authoritative. Plaster relief changes shading normals by at most millimetre-scale height samples; it never displaces a vertex. Timber/cloth coordinates belong to the mesh, so supplied-tick rotations do not cause world-space texture crawling. Distant weave and turning bands are derivative filtered. Water, foliage, soil, metal hardware and emissive openings retain their existing materials.

The generic plaster maps retain their upstream CC0 dedication and provenance in [the surface directory](../game/assets/surfaces/README.md). They are appearance references, not evidence of Punjabi building materials or their age.

## Twelve fitted vessels

The six small market cylinders and six storage jars now use a reusable turned shell with belly, shoulder, neck, connected lip, inner wall, inner floor and closed underside. Three deterministic variants provide modest silhouette variation. Every vertex remains within its former cylinder's radius and height at the same position.

Each vessel has 1,727 vertices and 3,120 triangles. These twelve replacements total 37,440 triangles; physical GPU performance has not been measured. The five previously authored market pots retain their existing distinct profile. Six redundant legacy market-rim nodes remain in the inventory with rendering layers cleared, because the new shell supplies its fitted lip.

The shape studies are original procedural art. They do not authenticate a specific vessel type, maker, archaeological sample or historical household.

## Lifecycle and authority

The material projection stores the exact original and finished material references. The inherited F7 refinement switch and greybox comparison restore them. The projection creates no geometry. Vessel replacement changes only the existing mesh resources; transforms, node counts and physical envelopes remain fixed.

No collision, navigation, economy, actor behavior, campaign state, save, journal or knowledge authority is added. The supplied chapter tick still owns existing cloth/foliage motion. The finish shader uses no independent clock.

## Render evidence

The renderer retains the five original inspection categories and adds a sixth courtyard evening frame. The courtyard daylight, golden-hour and evening frames share one camera, FOV, tick and campaign snapshot. The market inspection camera now approaches its counter directly, since the former angle mostly saw the adjacent store wall. Gameplay cameras and the carried-water sightline assertion remain unchanged.

The manifest records PNG byte hashes, decoded RGBA pixel hashes, dimensions, renderer/device, camera position/target/FOV and renderer-reported frozen state identity. In-engine before/after snapshot assertions check runtime state preservation. An independent Python decoder verifies PNG integrity and pixel differences, and checks the consistency of the reported camera/state metadata. It cannot independently reconstruct the campaign from a screenshot.

Cleanup releases scene/camera references before renderer shutdown. CI now uses explicit error branches: any SCRIPT ERROR, SHADER ERROR or ERROR in render logs fails qualification. The former `! grep` form did not enforce that under Bash `set -e` and allowed texture-leak errors through despite green job status. No render assertion is relaxed.

These frames are art-inspection views, not gameplay screenshots, historical evidence, human art approval or a hardware performance benchmark.

## Verification

Run the inherited suite plus vessel-envelope/topology and material-lifecycle checks:

```sh
python tools/run_checks.py --godot /path/to/godot
python tools/test_check_gujranwala_beauty_capture.py
```

Then run the native `res://tests/render_gujranwala_beauty.gd` with the Compatibility renderer and verify its output:

```sh
python tools/check_gujranwala_beauty_capture.py --capture-dir /path/to/gujranwala-beauty-images
```

The inherited `render_water_round.gd` remains a required composition regression. The Home visual workflow retains source commit/tree, the source archive, logs and inspection images. Human review of actual gameplay, source research for vegetation/architecture, and character face/hair/hands/animation work remain separate production tasks.

The descriptive inventory is [gujranwala_material_fidelity.v1.json](../data/art/gujranwala_material_fidelity.v1.json); executable tests and rendered output determine qualification.
