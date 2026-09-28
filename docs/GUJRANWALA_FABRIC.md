# Gujranwala: architectural fabric over the playable home cell

This increment develops the **existing 1792 home and missing-remounts scene**.
It is not a new menu, an accurate city survey, an expansion of the walking boundary,
or another simulation owner. The inherited gate, service passage, overlook,
caravan, horse, witnesses, messenger, save and checkpoint paths remain in use.

## What changed

- Ten existing masonry wall meshes receive a procedural brick/plaster material.
  The brick module, colors and maintained finish are authored choices. No photograph
  is used as a game texture. The original walls' collision bodies remain unchanged.
- Ten shallow blind bays, timber screens and cornices decorate the two courtyards.
  Blind bays are backed by the original walls; they do not promise open doorways.
  Arch curves are approximations, not measured profiles.
- Existing stable beams and the market counter receive small original timber/pottery
  meshes. These objects introduce no new inventory, crafting recipe or resource gain.
- Sixteen flat-roofed background houses establish a settlement silhouette outside
  the retained test boundary. They are **not additional playable streets**.
- **F2** opens reconstruction notes in the existing modal UI. Notes expose evidence,
  limitations and design choices without entering Buddh's memories or knowledge.
  The existing chapter pause freezes gameplay while the notes are open.

## Research used, and what it does not establish

Sana Arslan's architectural study describes brick, plaster and wood, and illustrates
courtyards, arches and attached columns. Its modern condition survey and proposed
restoration work are not a reconstruction of the entire building in 1792. The game
therefore uses a material/form vocabulary, not the survey's precise plan or tourism
proposals. Relevant text and PDF figures were inspected on 28 September 2026.

- [Article and PDF](https://alqamarjournal.com/alqamar/article/view/1481): printed
  pages 74-78, figures 2 and 4-6. Restoration proposals appear later, pp. 87-92.
  The issue is labelled April-June 2024; the landing page records publication on
  15 June 2025. Both metadata values are retained, not silently reconciled.
- [UKPHA courtyard photograph](https://www.flickr.com/photos/35729318@N00/3993139067/):
  taken 16 March 2004. Modern visual reference, not proof of the 1792 condition.
  All rights reserved; the photograph is not redistributed.
- [District Gujranwala, Geography](https://gujranwala.punjab.gov.pk/geography):
  present regional context only. No modern administrative boundary is converted
  into a historical territory, and no contemporary road is imported.

The three sources, three limited claims, four authored element groups and explicit
exclusions are retained in `game/data/gujranwala_fabric.json`. Source references are
neither mathematical verification nor authenticated archaeological evidence.
Modern railway/street layouts, unverified monument replicas, suggested tourism
mosaics/fountains and a rumoured tunnel are excluded. Existing Mahan chronology,
character naming, household relations and the selected narrative source lens are
unchanged. This pass does not grant a new narrator or new historical knowledge.

## Implementation and invariants

`gujranwala_fabric.gd` builds one detachable visual node under the existing remount
controller. It modifies no scene file, provider, treasury, clock or save schema.
Its only live integration points are build, F2 dispatch and the existing dialog.
No source record is dynamically executed or imported. There are no new runtime
packages or borrowed game/franchise assets.

The current output contains 317 new mesh instances and zero new collision shapes.
This is an explicit prototype cost, not a frame-budget qualification. Repeated
houses/materials are candidates for batching if a measured profile requires it.
A material-only change does not silently alter guard light sensitivity: detection
still uses the existing collision-based sight rules, not a new lighting model.

The manifest binds the exact catalogue bytes and counts; it remains `not_verified`.
It is deterministic for the pinned recipe, not a proof of source authenticity.
`remove_material_overrides` supports test cleanup; removing the whole decoration
leaves existing collision identities and live state untouched.

## Run and test

Open `game/project.godot` in **Godot 4.5.1 Standard**, F5, then choose the existing
**1792 / Buddh Singh / Home territory** entry. F2 opens reconstruction notes.
Complete the existing inquiry and allowance, then ask the quartermaster about
missing remounts. See [Missing remounts](MISSING_REMOUNTS.md) and
[Gujranwala supplies](GUJRANWALA.md) for the inherited playable loops.

```sh
python tools/run_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_gujranwala_fabric.gd
/path/to/godot --path game --rendering-method gl_compatibility --script res://tests/render_gujranwala_fabric.gd
```

The new 30-assertion suite checks malformed/dangling evidence records, exact-year
limits, prohibited reconstruction claims, deterministic output, duplicate-build
refusal, detached data, and F2's lack of state/knowledge side effects. It compares
all existing collision-shape identities, transforms and shape resources before
and after removing the visual layer. The original journeys are rerun unchanged.
Five new software-rendered views inspect courtyard, stable, market, overview and
800x600 notes. Screenshot poses are labelled presentation fixtures, not playtests.

Initial checks caught an incorrect expected wall count; actual source has three
home walls plus seven remount walls. Visual review caught one-sided arch strips
and overly periodic weathering. Both were corrected before the final qualification.
Physical-GPU performance, Windows saves, human playtesting and a historically exact
city reconstruction are not established by these checks.
