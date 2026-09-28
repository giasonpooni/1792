# Mahan Singh interlude (recon delay + column march + cavalry + logistics + politics + orders)

## Playable loop intent

This slice deepens the **separate playable profile** for **Mahan Singh** (stable actor
id `mahan_singh`) with delayed scout custody, authored column movement on greybox
nodes, **opt-in cavalry** that reuses the existing riding library, and a
**small logistics** module (forage / wait consumption / stockout), and a
**bounded clan/subordinate politics** slice (retainer counsel, delayed household rumor,
march-willingness pressure), and **subordinate column orders** (scout / hold rear /
pursue-contact stub). It remains a modular campaign extension parallel to
childhood -> aftermath, not a rewrite of those chapters and not a merge into the Lahore
sandboxes.

| Step | Actual interaction |
| --- | --- |
| Enter | Main menu -> **1790 / Mahan Singh / Field camp (interlude)** |
| Mount | Near the **field horse**, press **F** to mount (or dismount when stopped). Only this chapter opts into riding. |
| Dispatch | On foot at the **camp table**, press **E**. Dispatch a scout detachment to the **ford** or **ridge** (costs 1 provision). Optional: **forage** at the column node when packs have room. |
| Delay clock | Walk, wait, or ride. Pending custody shows on the HUD. **Player knowledge updates only when the report arrives** (`arrives_at`); undelivered text stays out of the journal. |
| Column order | After >=1 delivered report, press **E** at the table (dismounted). Optional: **consult subordinates** (hold vs advance counsel) and/or **request household word** (delayed clan-house rumor). Choose **advance the horse column** or **hold for corroboration**. **Stockout** blocks advance; advancing against active retainer hold-pressure **strains** disposition. Optional: dispatch a second scout or forage before ordering. |
| March | If advancing: walk or **ride** to an adjacent authored node (**camp -> ford -> ridge**), **dismount**, and press **E** to commit the march (costs 2 provisions + time). Optional: **issue subordinate orders** (scout flank / hold rear / pursue contact stub). **Strained** disposition blocks march and offensive sub-orders until disposition steadies; **hold rear** remains available. **Forage** once per node. Wait time drains provisions. Stockout blocks further marches. Hold keeps the column at camp. |
| Fixed endpoint frame | Press **E** with the column (or at the table) and **acknowledge** that Mahan's historical death is fixed campaign history. |

WASD moves (or mounts: W forward, A/D steer, Shift canter, Ctrl walk, S/Space brake);
mouse looks; **F** mounts/dismounts; **J** opens the attributed field journal (delivered
memories only; pending targets listed without text); **F5/F9** save/load
`user://1792-mahan-v1.json`; **F1** pauses. Greybox geometry and one authored
recon/march/cavalry beat only.

## Cavalry (library reuse)

- Reuses `game/mounts/riding_rules.gd` (`riding.v1`, `household_horse_01`, mount/
  dismount distances, speed envelope) and the `horse.tscn` / `horse.gd` adapter.
- Rider id in this profile is **`mahan_singh`**. Mahan validates riding on its own
  envelope; it does **not** rewrite Lahore `Riding.validate` allowlists
  (`ranjit_singh` / `patrol_captain` remain Lahore-only).
- Riding is **opt-in** via `enable_riding()` from the Mahan chapter only. Domain-only
  consumers retain snapshots without a horse key.
- Table / march / endpoint actions require a dismount (same pattern as house sandbox).
- Short mounted travel is physical greybox riding between camp markers -- not a new
  expedition map and not a rewrite of column `march_to` logistics.

## Logistics (provisions / forage)

- Field packs are a **small logistics ledger**, not an economy UI: start 10 / max 12.
- **Forage** once per authored node while standing with the column (`camp` +2, `ford`/`ridge` +1). Full yield only; refuse when packs cannot take it.
- **Wait consumption:** every 60 ticks drains 1 provision while stock remains; stockout stops further drain.
- **Stockout** (provisions below march cost 2) blocks **advance** and **march**; **hold**, forage, dispatch (if affordable), and the fixed endpoint remain available.
- Dispatch (-1) and march (-2) costs from the prior tip still apply and compose with forage/wait in the logistics adapter.
- Implemented as `mahan_logistics_*.gd` on top of the cavalry adapter -- does **not** rewrite `house_command_state`, `command_state`, or a taxation UI.

## Clan / subordinate politics (bounded)

- Subordinates are **separate Person actors** inside `mahan.politics` (camp retainer,
  horse jemadar) with **household relations** to graph object `sukerchakia` and
  time-bounded **alignments** (`prefer_hold` / `prefer_advance` / `counsel_noted`).
  They are **not** Faction tags on people and do **not** appear in the top-level
  `actors` fence (only `mahan_singh` does).
- **Consult subordinates** at the camp table: authored hold-vs-advance counsel.
- **Request household word**: delayed rumor with scout-shaped custody
  (`observed_at` / `arrives_at` / `delivered`); journal text appears **only on delivery**.
- **Consequences:** matching hold advice raises retainer loyalty and sets disposition
  `aligned`. Advancing against active `prefer_hold` **strains** disposition and blocks
  **march willingness** until the player **acknowledges clan-house pressure** (or the
  delivered rumor softens stance to `counsel_noted`).
- Raj Kaur / Phulkian / Sandhawalia research dumps are **out of this slice** -- no
  antagonist roster rewrite, no `house_command_state` rewrite.
- Implemented as `mahan_politics_*.gd` on top of the logistics adapter.

## Subordinate orders / pursuit stub (bounded)

- After **advance the horse column**, issue column sub-orders to politics subordinates:
  - **scout** -> horse jemadar (flank scout assignment)
  - **hold rear** -> camp retainer (rear-guard assignment)
  - **pursue contact** -> horse jemadar (schedules a timed outcome report)
- **Disposition gates:** `scout` and `pursue_contact` require disposition `steady` or
  `aligned`. While disposition is `strained`, offensive sub-orders are refused; **hold
  rear** remains available.
- **Pursuit stub:** uses scout-shaped delayed custody (`observed_at` / `arrives_at` /
  `delivered`); journal text appears **only on delivery**. This is **not** combat AI
  and does **not** rewrite `patrol_director` or `house_command_state`.
- One active order per subordinate; subordinates stay inside `mahan.politics` /
  `mahan.orders` relations -- not top-level `actors`, not Faction tags.
- Implemented as `mahan_orders_*.gd` on top of the politics adapter.

## Ontology fence

`Person != Dynasty != Household != Faction != Alignment`.

- **Person:** actor `mahan_singh`
- **Household graph object:** `sukerchakia` (`mahan.household_id`) -- field authority
  for this interlude; not a Dynasty, Faction, or Alignment label
- Place id `sukarchakia_field_camp` remains the camp place string (existing spelling)
- Subordinate counsel uses household relations + time-bounded alignments, never Faction tags on Person
- This slice does **not** collapse Raj Kaur into Sandhawalia, or Person into Household
- Raj Kaur does **not** appear in this Mahan politics slice

## Fixed historical endpoint

**Mahan Singh's death is FIXED campaign history.** Player column orders, marches and
rides in this interlude do **not** create an alternate-history branch in which he
survives, nor a playable rescue or succession rewrite. The endpoint acknowledgement
records that constraint explicitly. Later slices may dramatize illness, retirement from
the field, or succession framing, but they must not offer a player-alterable survival
outcome.

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
- **Delayed custody:** undelivered scout reports are not journal knowledge and do not
  unlock `known_nodes` until `delivered` flips on the delay clock.
- Undelivered pursuit custody likewise stays out of the journal until delivery.

Buddh remains the player-facing early identity elsewhere; public Ranjit/Maharaja
presentation in Lahore is unchanged. The stable childhood/Lahore key remains
`ranjit_singh`.

## Source class vs game-canon

| Layer | Treatment in this slice |
| --- | --- |
| Source class | Nominated secondary narratives place Mahan's final illness during a late campaign (often linked to Sodhra / Bhangi contest) and his death as fixed lineage history. This slice does **not** quote those works or promote a single edition as verified chronology. |
| Game-canon | Authored scout speech, camp/ford/ridge geography, dispatch/march costs, the advance/hold decision, the field-horse park, and fictional subordinate counsel / household-courier rumor are **fiction** used to exercise command, delayed information, cavalry reuse, logistics and subordinate-house pressure. |
| Non-claim | No claim that a specific scout report, ford state, ridge dust, table dialogue or horse park is documentary fact. |

Keep source account, editorial interpretation, game-canon decision, world event and
character knowledge distinct (see [HISTORICAL_SOURCES.md](HISTORICAL_SOURCES.md) and
[HISTORICAL_METHOD.md](HISTORICAL_METHOD.md)).

## Delayed information (library-shaped reuse)

Scout detachments append reports shaped like Lahore command custody
(`observed_at`, `arrives_at = observed_at + REPORT_DELAY`, `delivered`) and deliver
inside `advance()` -- the same *pattern* as `command_state.received_reports()`, without
rewriting `command_state.gd` or sharing mutable authority. Mahan keeps its own
`REPORT_DELAY` (tick-scale for the interlude clock) and its own save envelope.

## Design concentration

In scope for the interlude family: command, movement, clan/house politics,
reconnaissance, delayed information, cavalry, logistics and subordinate-command
decisions. This slice delivers the profile skeleton, delayed scout custody, authored
column nodes (camp/ford/ridge), **cavalry opt-in via riding_rules**, a **logistics**
forage/wait/stockout module, a **bounded clan/subordinate politics** slice, a
**subordinate orders / pursuit stub** slice, and the fixed endpoint frame. Broad
religious-conflict framing is a non-goal.


## Gujranwala ridge→settlement encounter stub

Authored playable beat on the Gujranwala march path (fort road / camp / settlement):

- Greybox approach marker + historical-event frame `mahan_gujranwala_ridge_settlement_approach`
- Delayed approach-scout custody (knowledge on delivery only)
- Choices: hold/observe, or advance under delivered custody — both keep the **fixed historical endpoint**
- No combat AI, no town sim, no alternate-history survival win, no `house_command_state` rewrite

## Non-goals (this PR)

- Full expedition map, navmesh campaign or Sodhra reconstruction
- Alternate history / player-alterable survival of Mahan
- Automatic childhood -> Mahan -> Lahore handoff or accession scene
- Combat redesign, schema bump, or rewriting Latif/childhood content
- Full economy sim / taxation UI
- Merging existing draft PRs or merging this branch to `main`
- Silent injection of Mahan memories into childhood/Lahore journals
- Touching `schemas/world_state.schema.json`, `data/world/1792_start.json`,
  childhood/Lahore core validators (except test registration), or
  `home_territory.tscn` bytes
- Rewriting `game/campaign/command_state.gd` or `riding_rules.gd` core contracts
- Rewriting `house_command_state.gd` or `antagonists.json` roster gates
- Full social sim, Sandhawalia research dump into game, or Raj Kaur in this Mahan slice
- Rewriting `house_command_state.gd` clan politics (pattern mirrored in Mahan-only adapter)
- Full combat sandbox or rewriting `patrol_director` (pursuit is delayed-custody stub only)

## Architecture

- Profile authority: `game/mahan/mahan_state.gd` (`mahan.v1`) plus Mahan-only `mahan_cavalry_state.gd`, `mahan_logistics_state.gd`, `mahan_politics_state.gd`, and `mahan_orders_state.gd` adapters
- Launch composition: `game/mahan/mahan_launch.gd` onto `game/world/mahan_camp.tscn`
- Chapter presentation: base `mahan_chapter.gd` -> `mahan_cavalry_chapter.gd` -> `mahan_logistics_chapter.gd` -> `mahan_politics_chapter.gd` -> `mahan_orders_chapter.gd` -> `mahan_history_chapter.gd` -> `mahan_encounter_chapter.gd`
- Reuses existing player controller, `riding_rules` / `horse` adapter and save/load
  pattern; does **not** replace childhood checkpoint, companion or Lahore command
  machinery

See [MAHAN_INTEGRATION_LEDGER.md](MAHAN_INTEGRATION_LEDGER.md).
