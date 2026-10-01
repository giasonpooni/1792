# Sikh Museum Initiative: object-level reference intake

Copyright (c) 2026 Cartesian Graphics. All rights reserved in this original note.
No ownership claim over the referenced objects, models or source publications.

Status: research intake, not downloaded assets or new runtime implementation.
Recorded 2026-09-29. User source: <https://sketchfab.com/SikhMuseumInitiative>.
Companion to [the existing reference batch](REFERENCE_BATCH_20260929.md) and
[material-culture intake](MATERIAL_CULTURE_INTAKE.md).

## Why this collection matters

The project's account describes photography, photogrammetry and 3D reconstruction
with the Royal Armouries for the shield, helmet and Akali turban. That offers a
more traceable starting point for those object forms than anonymous fantasy art.
It does not establish that every model in the profile is a measured scan. [S01]

Use three distinct identities: the physical museum object, its digital depiction,
and any later game adaptation. Keep their dates, dimensions, authors, rights and
uncertainties separate. A model publication date is not a manufacture date.

The [machine-readable shortlist](../data/art_intake/smi_collection_20260929.json)
records twelve selected leads with stable model IDs and per-object source pointers.
It is not a complete/current catalogue count and is not loaded by Godot.

## Priority objects and proposed use

| Reference | Project-reported object information | Proposed production treatment |
| --- | --- | --- |
| Akali Turban | Royal Armouries XXVIA.60; late eighteenth/early nineteenth century. [S02] | Specialist headgear construction reference, not Ranjit's ordinary cloth turban. |
| Sikh Helmet | Royal Armouries XXVIA.35 A; probably nineteenth century. [S03] | Metal bowl, mail, lining and decoration study for an appropriate later military context. Not automatically 1792 equipment. |
| Lahore Shield | Royal Armouries XXVIA.140; probably early nineteenth century. [S04] | Shape, grip, lining and surface reference; object appearance in a specific household/year remains a separate question. |
| Katti and Talwar | Project labels these general sword depictions, without an accession. [S05] | Candidate for a small, sourced weapon-form study at the existing workshop; exact period, measurements and rights first. |
| Brown Bess | Project gives a broad pre-1800 date. [S06] | Identify the particular pattern and local issue history before using the model in a scene. |
| Sikh Cannon | Consulted indexed page supplies no object description. [S07] | Research lead only; do not name it Zamzama or infer date, bore or dimensions. |
| Sikh Empire Flag | Published description associates the pattern with Anglo-Sikh-war standards. [S08] | Later standard research, not the single flag for all misls and centuries. Review both faces and iconography. |
| Sikh Manuscript | Project identifies University of Leicester MS 241 and early-1800 dating. [S09] | Sacred manuscript context, not a generic ledger or loot reskin. |
| Panjangla Maharani Jindan Kaur | Model description attributes the jewellery and gives 1800-1840. [S10] | Later court reference, with attribution/custody still to check. |
| Harimandir Sahib Gold Dome | One architectural component, not a whole-site survey. [S11] | Exterior-only study; date-specific appearance, physical scale and placement still required. |
| Guru Nanak coin / Avatars Sword | Coin page gives 1828; sword page has conflicting 1820-1840 and 1840-1850 ranges. [S12, S13] | Hold: chronology and depicted religious figures require review. Do not silently pick a date or erase imagery and call it an exact replica. |

Accession and date information above is attributed to the project's pages. The
holding museum's linked catalogue shell did not expose the underlying object
records in this retrieval, so independent accession-record verification is not
claimed. General depictions, reconstructed patterns and identified museum objects
must not collapse into a single "authenticated scan" category.

## Download and rights result

**No downloadable commercial-use licence was confirmed for these twelve models.**
Several individual Sketchfab pages returned 403/cache errors. The collection list,
indexed descriptions and project pages could be read, but current permission
metadata could not be established. Public Data API metadata was not retrievable.
This means unknown permission, not proof that the creator never offers licences.
No source mesh, viewer payload, texture, screenshot or model archive was acquired.

Sketchfab documents authenticated downloads and model-specific licence/attribution
handling. Its supported download formats include glTF/GLB/USDZ; this does not prove
which packages exist for these particular objects. [S14, S15]

The appropriate next acquisition step is an object-specific enquiry to the Sikh
Museum Initiative / Taran3D and any necessary collection rights holders. Ask about
commercial game use, texture/mesh adaptation and optimisation, compiled game and
promotional use, required credit, and whether source redistribution in a public
repository is permitted. These are distinct permissions. Request measurements,
source provenance, modelled restorations and attribution support at the same time.
**No message has been sent and no partnership or licence has been obtained.**

## Integration into the existing workflow

Use the current reference/asset path, not a new museum runtime or online dependency:

object record -> authorised source package -> immutable source copy -> reviewed
Blender adaptation -> existing Godot import -> current in-game inspection/capture.

After authorised acquisition, measure scale/axes, bounds, mesh topology, UVs,
materials and texture colour spaces. Decide whether the item needs optimisation,
attachment points, cloth motion or LOD variants. Keep generic type geometry
separate from a named relic's unique decoration and ownership history. A geometry
model does not establish mass, balance, armour protection or combat performance.
Those remain separately authored gameplay parameters unless measured/sourced.

For the immediate courtyard, prioritise one well-supported small equipment form
and its handling/readability in the smith sequence. This is a proposal, not a new
commission or reward. Armour, jewellery and imperial standards can enrich later
Ranjit chapters without entering the childhood scene prematurely.

This object collection does not supply our whole Gujranwala settlement, terrain,
horse, protagonist or living population. The existing full-envelope 1:1 target,
childhood-first sequence, religious-site exterior restriction and non-playable
Sada Kaur/Adina Beg choices remain unchanged. Importance/luck ratings are not
inferred from how attractive, ornate or widely viewed a digital model is.

## Sources and access boundaries

Links are references, not imported copyrighted assets. Consulted 2026-09-29.
Model-specific URLs and additional access notes are in the JSON companion.

- S01: project digitisation account: <https://www.sikhmuseum.org.uk/akali-turban-in-3d/>
- S02: Akali Turban: <https://www.anglosikhmuseum.com/akali-turban/>
- S03: Sikh Helmet: <https://www.anglosikhmuseum.com/sikh-helmet/>
- S04: Lahore Shield: <https://www.anglosikhmuseum.com/lahore-shield/>
- S05: general swords: <https://www.anglosikhmuseum.com/sikh-swords/>
- S06: Brown Bess: <https://www.anglosikhmuseum.com/brown-bess/>
- S07: indexed cannon page: <https://sketchfab.com/3d-models/sikh-cannon-63b4690337584b5fb98d35f4fd5ab101>
- S08: indexed flag page: <https://sketchfab.com/3d-models/sikh-empire-flag-2a42576d84f446dca4a007751a2c8303>; related flag context, not established as identical: <https://www.anglosikhmuseum.com/khalsa-army-flag/>
- S09: indexed manuscript page: <https://sketchfab.com/3d-models/sikh-manuscript-48832d09b74b4250b23282436caff6c7>
- S10: indexed jewellery page: <https://sketchfab.com/3d-models/panjangla-maharani-jindan-kaur-7aaad007ab0844519cd3a82512f792c9>
- S11: dome entry: <https://www.anglosikhmuseum.com/gold-dome/>
- S12: indexed coin page: <https://sketchfab.com/3d-models/guru-nanak-coin-sikh-empire-b53593f73b6f429ea6b175a3e0953450>
- S13: indexed sword page: <https://sketchfab.com/3d-models/guru-nanak-avatars-sword-0dcd5d8c2b4746c29dfddda102d30135>
- S14: official download/attribution guidelines: <https://sketchfab.com/developers/download-api/guidelines>
- S15: official download API: <https://sketchfab.com/developers/download-api>
