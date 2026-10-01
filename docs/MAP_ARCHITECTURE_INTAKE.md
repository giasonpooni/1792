# Maps, facade modules and uploaded environment packs

Copyright (c) 2026 Cartesian Graphics. Original note and tooling only; referenced
maps, renders and asset packs retain their respective rights.

Status: inspected source intake and an executable offline inspector, **not a new
rendered courtyard, terrain acquisition or converted game asset**. Recorded
2026-09-29. Parent: museum intake PR #42 at `780548cb6d288c1511784c18fcb11f22ecf1d6f1`.

[Machine-readable register](../data/art_intake/map_architecture_20260929.json)
contains image/archive hashes, dimensions, title observations, source pointers and
separate permission/completeness/runtime decisions. Raw pixels and archives are
not committed. This extends [the reference collection](REFERENCE_BATCH_20260929.md)
and [the authored courtyard](COURTYARD_AUTHORED.md), not a new workbench.

## What the map images contribute

These are different depictions, not five interchangeable versions of one border.
The entries below describe the supplied images; no polygon is digitised or admitted.

| Image | Visible information | Treatment |
| --- | --- | --- |
| Warren Hastings overview | Approximate-boundary legend; broad political labels; religious categories in the legend | Context for changing regional powers. Depiction window and edition unresolved; do not turn its legend into a population or faction taxonomy. |
| India in 1823 | Dated subject, plate 22, Justus Perthes/Gotha credit, separate British Territory/Protected States legend | Later-Ranjit comparison candidate; 1823 is not proven publication date and cannot become the 1792 opening state. |
| Modern satellite map with outlines | Modern cities, Google basemap, multiple coloured outlines without an explanatory key | Orientation reference only. Meanings, author and date unresolved. Not a game-envelope revision or a historical/modern sovereignty determination. |
| Lahore Durbar circa 1844 | Visible Navtej Singh Heer/2015 credit; historical extent claim and a distinct hatched earlier-control claim | Modern interpretation of a later period. Keep the two claim types separate; neither establishes the geography inherited by young Ranjit. |
| Sikh Empire in 1839 | Modern-country locator legend and modern names, including Faisalabad | Locator reference, not evidence that each labelled city/footprint existed in 1839 or 1792. Bibliographic source and boundaries still unresolved. |

The University of Chicago hosts the *Imperial Gazetteer of India, Atlas: 1909*.
It is a candidate collection to check for the 1823 plate, **not an exact source
match established here**. [S06] Exact editions of the other images also remain
unresolved. Do not upgrade a title, caption or copied map into surveyed precision.

Future map records should distinguish depiction date, publication date, provenance,
scale/projection, place-name validity, map claim and positional uncertainty.
Administration, effective military control, tribute, alliance, raiding reach and
contested areas are different relations. A settlement registry and terrain frame
must not inherit a political claim merely from a fill colour.

The existing full geographic envelope remains; a subcontinent overview does not
silently promise a newly populated all-India game. DEMs, river reconstruction,
settlement footprints and routes still need their own evidence and qualifications.

## Funeral and Phillaur caption continuation

Two subsequent caption leads were checked against holding-museum records. The
new image-only messages were exposed as placeholders, not additional mounted
files. The captions and source links are retained separately; no matching pixel
hash, newly inspected image count or full reproduction licence is invented.

**Funeral of Ranjit Singh:** the British Museum catalogue identifies painting
1925,0406,0.2, made in the Punjab Hills circa 1840, with Pahari/Kangra/Sikh style
classifications. [S07] This is a catalogue candidate matching the supplied subject
and caption, not a verified match to inaccessible uploaded pixels. Ranjit's death
belongs to 1839, not the painting's production year. [S10] A near-contemporary
painting can guide a later narrative study of procession, clothing, mourning and
staging, but it is not a surveyed plan or an independently verified participant
list. The museum explicitly describes sati in the picture; that context must not
be silently replaced by a purely celebratory royal tableau. No funeral scene,
new playable action or dialogue is implemented. Religious-figure depiction rules
remain in force. The actual digital reproduction's rights still require review.

**Phillaur / Philoor:** the Met identifies the matching *title* as photograph
2005.100.491.1 (66), object 287666, by an unknown photographer, an albumen silver
print dated 1858-61. [S08] That date belongs to the photograph, not construction
under Ranjit Singh. Jalandhar district's history describes conversion of the older
sarai into a fort between 1809 and 1812 under Mokham Chand. [S09] It also records
subsequent British military use. Only these narrow chronology distinctions are
admitted here; architect attributions and all other details are not adopted
wholesale. The photograph can inform later surviving fabric, with separate review
of alterations before using it for an earlier scene. It cannot establish a 1792
fort footprint, facade dimensions, the unseen sides or an exact river channel.

The Met labels its version **Public Domain** and provides an Open Access route.
Prefer that traceable museum source for any future acquisition rather than
assuming the supplied Getty/Heritage credit settles all versions' rights. [S08]
Neither museum image was downloaded to the game or committed by this intake.
The supplied sukerchakia image URL was attempted but was not retrievable here.

These references strengthen the eventual end of Ranjit's full narrative and a
site's architectural time layers; neither expands current childhood production.

## The useful facade language

The six facade/street renders show a particularly useful production sequence:
projecting window -> balcony -> shopfront combination -> multi-bay building -> lane.
Small columns, bracket supports, lattice infill, roof caps, overhangs and shutters
make a reusable kit richer without requiring every building to be a unique mesh.

The filenames attribute this set to Uzair Baig. His own portfolio contains
*Walled City of Lahore*, described as detailed building models. [S01] This verifies
a related creator/project, not a remote pixel-hash match, available source pack,
measured survey or permission to copy the depicted models. No source mesh for these
renders was supplied, and their rights remain unestablished.

For current production, the proposed next asset is one **original, modest timber
projecting-window/balcony variant** compatible with the existing courtyard bay.
Use larger and more elaborate variants selectively when a household/place/date
supports them. Do not cover every Gujranwala frontage with the same ornate cap.
A lower-floor closure resembling a modern shop fitting requires particular date
review. Closed scenery is not an entered room; a projecting balcony is not an
approved parkour surface. No new geometry is implemented by this intake.

## Actual archive findings

The offline inspector reads ZIP members in memory, validates their lengths/CRC,
records SHA-256, and inspects limited uncompressed legacy Blender metadata. It
neither extracts members nor launches Blender, follows linked libraries or executes
embedded scripts/drivers. Stored counts are **not** evaluated visible mesh counts.

| Supplied archive | Header and stored data | Production consequence |
| --- | --- | --- |
| Arab Village.zip | `arab village.blend`: 2.70 header, 145 object blocks, 142 mesh blocks, 8 materials, 22 images; no library blocks | A concrete component-review candidate, not just an image. Legacy material conversion and selected-component review remain untested. |
| Grassy Field.zip | `grass.blend`: 2.57 header, 21 object blocks, 7 mesh blocks, 11 materials, 3 particle-settings blocks, two linked libraries | The archive omits `Shrubs6.blend` and `Boulders.blend`. Some images have no legacy packed-file pointer. It cannot be called a complete drop-in scene. |

A nonzero packed-file pointer does not prove all texture bytes are usable. Object
counts include stored/orphan data; polygon counters are not runtime triangle
budgets. Header versions, rather than site compatibility labels, identify the
actual uploaded files. No Blender import, native render, scale, UV, shader, plant
species, motion or game-frame-rate qualification was performed.

### Rights results, separately from technical suitability

**Arab Village, mawais:** the bundled HTML notice says CC BY 3.0. The current
BlendSwap listing says CC0 and includes a creator clarification permitting CC0.
Retain both records and credit mawais; review embedded-image provenance separately.
This supports proceeding to component review, not replacing Gujranwala with an
Arab-themed town or treating every texture as independently verified. [S02]

**Grassy Field, metalix:** the bundled notice specifies CC BY 3.0 and the listing
says CC-BY. Its creator explicitly excludes background foliage/textures over rights
uncertainty. A discussion of learning techniques is not used to erase the bundled
notice. Keep attribution for reused content and replace unavailable dependencies
with separately cleared assets, rather than hunting for unlicensed copies. [S03]

CC BY 3.0 allows commercial adaptation subject to its terms. Preserve creator,
title, licence/source links and adaptation notices, and do not apply additional
restrictions to the licensed material. This is not a requirement to release the
whole original game under that licence, or a warranty over unrelated embedded
content. [S04] Record chosen components and any conversion separately before a
runtime import; no raw pack is added to the proprietary game source here.

## Reusable inspection command

```sh
python tools/art/test_inspect_asset_archive.py -v
python tools/art/inspect_asset_archive.py "Arab Village.zip" --output /existing-parent/new-report.json
python tools/art/inspect_asset_archive.py "Grassy Field.zip" --output /existing-parent/other-new-report.json
```

Standard-library Python only. New reports use exclusive creation; existing reports
are not overwritten. The inspector refuses unsafe paths, duplicates/case collisions,
links/special entries, encrypted or unsupported compression, expansion budgets,
truncated blocks and unsupported Blender headers. It understands a limited SDNA
layout only when declared sizes agree; unknown fields remain null. [S05]

Both actual uploads were inspected and source hashes remained unchanged. The
committed reports are reproducible input observations; synthetic tests cover
32/64-bit and both endiannesses plus refusal cases. These are not security
certification, topology validation or historical approval. The offline CI check
uses synthetic fixtures and the retained reports, not redistributed source ZIPs.

## Protected production order

Ranjit's childhood through the Lahore prelude remains first, then his full life,
then DLC. Religious figures remain unembodied, religious sites exterior-only;
Sada Kaur and Adina Beg stay non-playable. The plain-cloth, uncovered-face Ranjit
direction remains. No current actor, economy, clock, saved world, place, religious
site importance or terrain acquisition status changes from this batch.

## Sources

Consulted 2026-09-29. These are source pointers, not redistributed source assets.

- S01: Uzair Baig, *Walled City of Lahore*: <https://uzairbaig.artstation.com/projects/xKqY4>
- S02: mawais, *Arab Village*, listing and creator clarification: <https://blendswap.com/blend/12913>
- S03: metalix, *Grassy Field*, description and licence listing: <https://blendswap.com/blend/3497>
- S04: Creative Commons, CC BY 3.0 deed: <https://creativecommons.org/licenses/by/3.0/>
- S05: Blender's legacy file-format documentation: <https://archive.blender.org/www/development/architecture/blender-file-format/index.html>
- S06: Digital South Asia Library, 1909 atlas collection; exact plate not matched: <https://dsal.uchicago.edu/reference/gaz_atlas_1909/>

- S07: British Museum, painting 1925,0406,0.2; catalogue indexed text retrieved,
  direct opening failed: <https://www.britishmuseum.org/collection/object/A_1925-0406-0-2>
- S08: Metropolitan Museum of Art, photograph 287666 / 2005.100.491.1 (66),
  dated 1858-61, Public Domain label and Open Access statement:
  <https://www.metmuseum.org/art/collection/search/287666>
- S09: District Administration Jalandhar, Phillaur Fort subsection, narrow
  conversion/use chronology only: <https://jalandhar.nic.in/places-of-interest/>
- S10: Wallace Collection, Anglo-Sikh Wars, Ranjit death year and related
  Phillaur photograph context, not blanket endorsement of all interpretation:
  <https://www.wallacecollection.org/explore/explore-in-depth/the-sikh-empire/the-lahore-durbar-the-court-of-lahore/anglo-sikh-wars/>
