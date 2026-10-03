# Punjab ecology in the Gujranwala opening

The opening now has a first exterior ecology pass: cultivated settlement margins,
grazing/scrub country, riverine thickets and seasonal wetland margins. Four authored
pockets extend the existing Home art layer. **F7 → Ecology / seasonal study** opens
the evidence notebook and dry, monsoon and receding-water previews.

This implements the mosaic premise. It does not reconstruct all of Punjab or locate
an actual river beside the household. The pockets occupy the existing compressed
scenery frame outside the 56 × 56 metre playable wall. The full-envelope atlas and
its metric/geographic authority are unchanged. The 1792 reconstruction envelope
also does not assign a new event date to Buddh's childhood scene.

## Visible changes and proposed mechanics

| Habitat | Current visual implementation | Proposed gameplay, currently inactive |
| --- | --- | --- |
| Settlement / cultivated margins | Existing field plots retained, bounded earthen bunds, short cut margins and a planted shade-tree form; existing wells and livestock retained | Water, supplies, witnesses and local authority |
| Dry scrub / grazing | Patchy seasonal grass, sparse branching bushes and an open grazing trace | Exposed riding, intermittent concealment and grazing routes |
| Riverine thicket | Tall grass/reed forms, unresolved shrub forms and an illustrative wet edge | Concealment, restricted movement and uncertain crossings |
| Seasonal wetland | Mud, reeds and visibly expanding/receding water | Seasonal routes and visibility |

Seven old decorative placeholders (six horizon-wide furrows and one long unlocated
water strip) are hidden while the ecology pass is active. F7's earlier-study and
greybox controls restore their original visibility. Cultivated plots remain; land
without crops is not treated as land without livelihoods.

The three seasonal profiles are authored visual parameters, not rainfall data,
hydrological simulation, crop calendars or a new clock. There are no new collisions,
navigation regions, witnesses, animal spawns, movement penalties or detection
bonuses. No light preset or season change edits saves, journal, economy, knowledge,
campaign time or input ownership. Mesh instances use local seeded generators and
the profile can be reapplied without drift.

## Evidence boundaries

The canonical ecology resource is `game/data/punjab_ecology.v1.json`. Its source
records are separate from observations, reconstruction decisions and placements.
`ecology_catalog.gd` validates and resolves the chain before rendering. Every
rendered pocket stores its placement/decision IDs and the catalogue content digest.

| Required distinction | Record location |
| --- | --- |
| Source and publication date | `sources` |
| Observation date, location and habitat | `observations` |
| Identification confidence | Observation and reconstruction records separately |
| Target epoch, confidence and reconstruction decision | `reconstruction_decisions` |
| Authored coordinates, footprint and visual seed | `placements` |
| Original wording and corrected identification | `taxonomic_corrections` |
| Conflicting chronology | `evidence_issues` |
| Proposed gameplay | `habitats[].gameplay_proposal` |

`placement_evidence(id)` returns detached source/observation/decision records.
Reading a development notebook does not add those facts to the protagonist's
knowledge. Source dates may be unknown; they are explicit nulls with an explanatory
label, never substituted with 1792 or a publication year.

- **Reeta Grewal, `4_grewal_r.pdf`:** printed p. 42 retells Barr's 1839 grass/jungle
  corridor between Gujranwala and Wazirabad and tall swamp grasses beyond Lahore.
  Barr's underlying journal has not been checked in this pass. Both locations and
  the 47-year temporal gap remain explicit. The Lahore description supplies a
  regional habitat analogue, not a Gujranwala river location.
- **N. C. Nair, `Flora of Punjab Plains.pdf`:** scanned title, foreword, preface and
  introduction checked. Publication is 1978; principal fieldwork is 1961–1966 in
  Indian Punjab/Haryana, supplemented by collections and earlier literature. It
  remains an identification resource. Individual species entries/specimens need
  checking before plant identity or historical occurrence is admitted.
- **Ayesha Iqbal, `Acad.Int.J.Soc.Sci.44b.2025.409-420.pdf`:** the 1849–1947 Gujrat
  governance study belongs to the deferred later historical layer. Its fourth
  settlement-report reference says 1918; the [British Library catalogue](https://searcharchives.bl.uk/catalog/040-000150972)
  gives Williamson's 1912–1916 report as Lahore, 1916. The original report is still
  needed. Neither reference establishes opening land law.
- **[Douie](https://www.gutenberg.org/cache/epub/24562/pg24562-images.html):** the
  grazing and pre-annexation irrigation passages prevent a blanket wilderness
  assumption. They do not map these prototype plots or water features.
- **Taxonomic correction:** Grewal's printed appendix p. 54 says
  `willow azadirachta indica`. The raw wording is retained; [Kew](https://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:1213180-2/general-information)
  identifies that scientific name with neem. This corrects the name association,
  without identifying an actual historical specimen. The new vegetation remains
  labelled as functional forms rather than verified species.
- **Wildlife:** captive-tiger evidence cannot establish a wild population. No
  blanket abundance claims are admitted. The [NOAA river-dolphin review](https://repository.library.noaa.gov/view/noaa/17049/noaa_17049_DS1.pdf)
  supports a range/habitat research lead; actual placement requires a located
  reach, dated range evidence, depth, flow and channel connectivity. The decorative
  water patches are not such evidence. Source-era taxonomy is not silently updated.

## Validation and continuation

`game/tests/test_punjab_ecology.gd` is part of `tools/run_checks.py`. It checks
reference resolution, rejection of inappropriate source classes, malformed
coordinates/dates, evidence inspection isolation, conservation of model/journal/
physical state, actual F7 actions, seasonal reversibility and legacy appearance
restoration. Tests verify structural claims; they do not authenticate history.

`game/tests/render_punjab_ecology.gd` captures the actual Home with eight explicitly
diagnostic views, including same-camera dry/monsoon/receding wetland comparisons.
It writes PNG and decoded RGBA hashes, the catalogue digest, supplied source and
execution identities, engine/renderer details and frozen-state checks. Set
`ECOLOGY_CAPTURE_OUTPUT`, `ECOLOGY_EXECUTION_ID` and `ECOLOGY_SOURCE_COMMIT` when
running it with a real display. These are art-inspection cameras, not player input
qualification. Human art approval and physical-GPU performance remain unclaimed.

Next implementation should bind a dated local river reach and specific plant
identifications before extending these pockets into traversable ecological zones.
Movement/concealment and seasonal route changes must then compose with the current
movement, visibility, clock and save systems and qualify the existing opening
journey. They must not be inferred from the present visual preview.
