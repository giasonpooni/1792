# Gujranwala — Sukerchakia home-ground notes (Mahan interlude)

Short research / framing notes for the **Mahan Singh** field-command slice.
Gujranwala is treated as a **Settlement / place object**, not a Person, Dynasty,
Faction, or Alignment tag. Household context remains **`sukerchakia`**.

This document is **not** the childhood supply-loop design on other stacks. It does
**not** invent primary citations. Prefer public encyclopedic / secondary summaries;
evidence classes follow [HISTORICAL_METHOD.md](HISTORICAL_METHOD.md).

## Geographic frame (public secondary / encyclopedic)

| Motif | Class | Note |
| --- | --- | --- |
| Gujranwala in the **Rechna Doab** (Chenab north / Ravi south) | **B** (reconstructed regional geography) | Orientation only; greybox is not a surveyed doab map. |
| Town as relatively modern 18th-century settlement vs older Lahore/Sialkot | **B** | Common public summaries; founding narratives disagree (Serai Gujran / Khanpur Sansi motifs). |
| Charat Singh moves Sukerchakia HQ toward Gujranwala and fortifies | **B** | Repeated in secondary Sikh-misl narratives; dates vary (mid-1750s / 1763 capital motifs). |
| Afghan pressure demolishes / Charat rebuilds battlements | **B** | Secondary narrative motif; not independently verified here. |
| **Garhi Mahan Singh** fortress motif inside the walled town | **B** (low confidence on plan) | Named fortress motif in secondary accounts; **no surveyed 1790 plan** claimed. |
| Ranjit Singh birth associated with Gujranwala (1780) | **B** | Widely repeated; exact house/market localization is contested/uncertain. |
| Chattha strongholds along the **Chenab** (Rasulnagar/Ramnagar, etc.) as campaign context | **B** | Regional opposition frame for Mahan expansion; not playable combat in this slice. |
| Roads toward Lahore / Wazirabad / Sialkot as regional axes | **B** + **C** | Orientation reconstructed; specific game road nodes are authored abstractions. |
| Rivers as operational obstacles (fords / seasonal crossings) | **B** + **C** | Ford greybox is gameplay abstraction, not a named surveyed crossing. |

**Uncertainty:** Death year for Mahan is variously given as **1790** or **1792** in
public secondary pages; this interlude keeps the authored fixed-death frame and does
not adjudicate editions. Sodhra / Bhangi siege illness motifs remain game-canon
connective tissue (see historical-event stubs), not documentary quotation.

## Ontology fence

| Concept | Id / treatment |
| --- | --- |
| Person | `mahan_singh` (player actor in this profile) |
| Household | `sukerchakia` (graph object; not a person) |
| Settlement | `gujranwala_settlement` (place / location stub) |
| Faction / Alignment | **not** collapsed onto the settlement |
| Raj Kaur / Phulkian / Sandhawalia | **absent** from this Mahan politics/orders/history slice |

## Game-canon place nodes (this slice)

Modular `historical-location.v1` stubs under `data/history/locations/` (mirrored for
Godot at `game/mahan/data/locations/`):

| `location_id` | Kind | Gameplay role |
| --- | --- | --- |
| `sukarchakia_field_camp` | camp | Existing greybox column root |
| `gujranwala_fort_road` | road | Approach toward home-ground |
| `gujranwala_camp` | camp | Household staging column node |
| `gujranwala_settlement` | settlement | Named town / home-ground |
| `gujranwala_garhi` | fort | Reference-only landmark motif |
| `gujranwala_lahore_approach` | road | Reference-only long axis (no Lahore rewrite) |

### March graph (greybox)

Authored nodes in `mahan_state.gd` (positions stay inside the existing ±28 greybox):

```
gujranwala_settlement — gujranwala_camp — gujranwala_fort_road — camp — ford — ridge
```

- `camp` starts known; Gujranwala nodes enter **`known_nodes` only on delivered scout custody** (same epistemic fence as ford/ridge).
- Scout / march speech is **authored fiction (class D / C)** informed by home-ground framing — **not** primary quotations.
- Does **not** open a town sim, siege map, or childhood/Lahore authority rewrite.


## Authored encounter stub (ridge→settlement)

Playable greybox beat on the existing march path
(`gujranwala_fort_road` / `gujranwala_camp` / `gujranwala_settlement`):

| Piece | Role |
| --- | --- |
| Historical-event frame | `mahan_gujranwala_ridge_settlement_approach` (`authored_fiction`, class D/B) |
| Greybox marker | Approach encounter marker between fort road and camp |
| Delayed scout custody | `dispatch_approach_scout` → delay clock → journal on delivery only |
| Player choices | `hold_observe` or `advance_under_custody` (requires delivered scout) |
| Endpoint fence | Choices do **not** alter Mahan's fixed death; no alternate-history win; no combat AI |

Adapter: `mahan_encounter_state.gd` / `mahan_encounter_chapter.gd` (extends history).
Ontology unchanged: settlement is a place; household remains `sukerchakia`.

## What this is not

- Not a full Punjab regional map or river-accurate navmesh.
- Not a documentary reconstruction of Garhi Mahan Singh’s plan.
- Not permission to invent Sandhawalia cast or put Raj Kaur on this politics slice.
- Not a merge with childhood Gujranwala supply-loop PRs on other stacks.

## Sources consulted (public overview only)

Public encyclopedic / secondary pages used for orientation (no edition-page primary
anchors claimed here):

- Wikipedia: *Gujranwala* (geography; Sikh-period capital motifs; Rechna Doab).
- Wikipedia / secondary summaries of Sukerchakia–Chattha conflict and Mahan Singh
  career motifs (Rasulnagar/Ramnagar, Chenab tract).
- Common secondary Sikh-misl narratives naming Garhi Mahan Singh and HQ at Gujranwala.

Record residual uncertainty rather than upgrading class B motifs to class A.

See also [MAHAN_INTERLUDE.md](MAHAN_INTERLUDE.md), [HISTORICAL_EVENTS.md](HISTORICAL_EVENTS.md),
[HISTORICAL_METHOD.md](HISTORICAL_METHOD.md).
