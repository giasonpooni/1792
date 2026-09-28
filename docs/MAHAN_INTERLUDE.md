# Mahan Singh interlude (first bounded slice)

## Playable loop intent

This slice introduces a **separate playable profile** for **Mahan Singh** (stable actor
id `mahan_singh`) during a compressed field-camp command beat. It is a modular
campaign extension parallel to childhood → aftermath, not a rewrite of those chapters
and not a merge into the Lahore sandboxes.

| Step | Actual interaction |
| --- | --- |
| Enter | Main menu → **1790 · Mahan Singh · Field camp (interlude)** |
| Delayed report | Walk to the scout marker and press **E**. One delayed reconnaissance account is remembered. |
| Column order | Return to the camp table and press **E**. Choose **advance a scout detachment** or **hold for corroboration**. |
| Fixed endpoint frame | Press **E** again at the table to acknowledge that Mahan's historical death is fixed campaign history. |

WASD moves; mouse looks; **J** opens the attributed field journal; **F5/F9** save/load
`user://1792-mahan-v1.json`; **F1** pauses. This is skeleton geometry and one authored
beat only.

## Fixed historical endpoint

**Mahan Singh's death is FIXED campaign history.** Player column orders in this interlude
do **not** create an alternate-history branch in which he survives, nor a playable rescue
or succession rewrite. The endpoint acknowledgement records that constraint explicitly.
Later slices may dramatize illness, retirement from the field, or succession framing, but
they must not offer a player-alterable survival outcome.

The year label `1790` on this profile is a scenario tag for the late field-command
context, not a claim that every authored beat happened on a verified calendar day.

## Epistemic fence

Mahan observations, scout reports, map knowledge and command decisions live only inside
`profile: mahan.v1` under actor `mahan_singh`.

- They **must not** automatically become Buddh Singh / `ranjit_singh` knowledge when
  control returns to childhood or Lahore.
- Childhood and Lahore save slots **must not** load a Mahan envelope, and a Mahan load
  **must refuse** childhood/Lahore/aftermath profiles.
- There is **no** silent cross-chapter knowledge merge in this slice.

Buddh remains the player-facing early identity elsewhere; public Ranjit/Maharaja
presentation in Lahore is unchanged. The stable childhood/Lahore key remains
`ranjit_singh`.

## Source class vs game-canon

| Layer | Treatment in this slice |
| --- | --- |
| Source class | Nominated secondary narratives place Mahan's final illness during a late campaign (often linked to Sodhra / Bhangi contest) and his death as fixed lineage history. This slice does **not** quote those works or promote a single edition as verified chronology. |
| Game-canon | Authored scout speech, camp geography, and the advance/hold decision are **fiction** used to exercise command, delayed information and subordinate orders. |
| Non-claim | No claim that a specific scout report, fort-road state, or table dialogue is documentary fact. |

Keep source account, editorial interpretation, game-canon decision, world event and
character knowledge distinct (see [HISTORICAL_SOURCES.md](HISTORICAL_SOURCES.md) and
[HISTORICAL_METHOD.md](HISTORICAL_METHOD.md)).

## Design concentration

In scope for the interlude family: command, movement, clan/house politics,
reconnaissance, delayed information, cavalry, logistics and subordinate-command
decisions. This first slice only delivers the profile skeleton plus one recon/command
beat. Broad religious-conflict framing is a non-goal.

## Non-goals (this PR)

- Full expedition map, navmesh campaign or Sodhra reconstruction
- Alternate history / player-alterable survival of Mahan
- Automatic childhood → Mahan → Lahore handoff or accession scene
- Combat redesign, schema bump, or rewriting Latif/childhood content
- Merging existing draft PRs or merging this branch to `main`
- Silent injection of Mahan memories into childhood/Lahore journals
- Touching `schemas/world_state.schema.json`, `data/world/1792_start.json`,
  childhood/Lahore core validators (except test registration), or
  `home_territory.tscn` bytes

## Architecture

- Profile authority: `game/mahan/mahan_state.gd` (`mahan.v1`)
- Launch composition: `game/mahan/mahan_launch.gd` onto `game/world/mahan_camp.tscn`
- Chapter presentation: `game/mahan/mahan_chapter.gd`
- Reuses existing player controller and save/load pattern; does **not** replace
  childhood checkpoint, companion, riding or Lahore command machinery

See [MAHAN_INTEGRATION_LEDGER.md](MAHAN_INTEGRATION_LEDGER.md).
