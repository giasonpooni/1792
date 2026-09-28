# Mahan interlude -- integration ledger

Stacked on PR #7 tip `feat/ambush-aftermath-v1` @ `012145721af9fb2b9fc4be46399151765a888404`.
Extended in place on draft PR #9 (`feat/mahan-interlude-v1`).

## Added (v1 skeleton)

| Path | Role |
| --- | --- |
| `docs/MAHAN_INTERLUDE.md` | Playable intent, fixed endpoint, epistemic fence, source vs game-canon, non-goals |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This ledger |
| `game/mahan/mahan_state.gd` | Isolated `mahan.v1` authority; actor `mahan_singh`; save `user://1792-mahan-v1.json` |
| `game/mahan/mahan_launch.gd` | Menu composition parallel to `home_launch.gd` |
| `game/mahan/mahan_chapter.gd` | Greybox camp + recon/command presentation |
| `game/world/mahan_camp.tscn` | New empty camp root (does not touch `home_territory.tscn`) |
| `game/tests/test_mahan.gd` | Domain validate, cross-profile refusal, beat + save round-trip, menu smoke |

## Extended (recon delay + column march)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_state.gd` | Scout detachments with Lahore-shaped delay custody; `known_nodes`; camp->ford->ridge march; provisions stub; knowledge on delivery only |
| `game/mahan/mahan_chapter.gd` | Dispatch / pending HUD / march panels; ford and ridge markers |
| `game/tests/test_mahan.gd` | Delay-clock, pending-vs-delivered, hold vs advance march, provisions/adjacency, fence |
| `docs/MAHAN_INTERLUDE.md` | Playable loop for recon delay + column nodes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | Extension note |

## Extended (prior slice -- cavalry via riding_rules)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_cavalry_state.gd` | Mahan-only adapter: opt-in `enable_riding()`; mount/dismount/`record_ride` for rider `mahan_singh`; reuses `riding_rules` VERSION/HORSE_ID/distances without rewriting Lahore `Riding.validate`; `household_id: sukerchakia` graph object; dismount gates |
| `game/mahan/mahan_cavalry_chapter.gd` | Chapter adapter spawns `horse.tscn`; **F** mount/dismount; mounted physics step; HUD mount status; ride greybox toward authored nodes |
| `game/mahan/mahan_launch.gd` | Composes `mahan_cavalry_chapter.gd` instead of base chapter |
| `game/tests/test_mahan_cavalry.gd` | 44 cavalry checks: opt-in, mount gates, short ride, Lahore validate still rejects `mahan_singh`, save/load + ontology refusal |
| `docs/MAHAN_INTERLUDE.md` | Cavalry loop + ontology fence |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This cavalry note |


## Extended (prior slice -- logistics forage / wait / stockout)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_logistics_state.gd` | Mahan-only logistics adapter on cavalry: forage once/node, wait drain every 60 ticks, stockout blocks advance/march; `logistics` ledger; compose with dispatch/march costs; no economy UI |
| `game/mahan/mahan_logistics_chapter.gd` | Forage actions on dispatch/decision/march panels; stockout HUD; keeps horse adapter |
| `game/mahan/mahan_cavalry_chapter.gd` | Additive guard: do not replace a pre-installed adapter model that already exposes `enable_riding` |
| `game/mahan/mahan_launch.gd` | Composes `mahan_logistics_chapter.gd` |
| `game/tests/test_mahan_logistics.gd` | Logistics checks: forage, wait drain, stockout->hold, forage lifts advance, save/load, ontology refusal, launch smoke |
| `tools/run_checks.py` | Registers `test_mahan_logistics.gd` after cavalry |
| `docs/MAHAN_INTERLUDE.md` | Logistics loop + non-goals |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This logistics note |


## Extended (prior slice -- clan/subordinate politics)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_politics_state.gd` | Mahan-only politics adapter on logistics: subordinate Persons with household relations + time-bounded alignments; consult counsel; delayed household rumor (scout-shaped custody); disposition/march-willingness gates; no `house_command_state` / antagonists rewrite |
| `game/mahan/mahan_politics_validate.gd` | Split-out ledger/memory validators (tooling size split; same ontology rules) |
| `game/mahan/mahan_politics_chapter.gd` | Counsel / household-word / pressure-ack panels; politics HUD; keeps logistics + horse adapters |
| `game/mahan/mahan_logistics_chapter.gd` | Additive guard: do not replace a pre-installed adapter model that already exposes `forage` |
| `game/mahan/mahan_launch.gd` | Composes `mahan_politics_chapter.gd` |
| `game/tests/test_mahan_politics.gd` | Politics checks: consult, hold-align, advance-strain+ack, delayed rumor, ontology, Raj Kaur absence, launch smoke |
| `tools/run_checks.py` | Registers `test_mahan_politics.gd` after logistics |
| `docs/MAHAN_INTERLUDE.md` | Politics loop + ontology fence |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This politics note |


## Extended (prior slice -- subordinate orders / pursuit stub)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_orders_state.gd` | Mahan-only orders adapter on politics: scout / hold_rear / pursue_contact to politics subordinates; disposition gates; pursuit timed custody stub (not combat AI); no `house_command_state` / `patrol_director` rewrite |
| `game/mahan/mahan_orders_chapter.gd` | Subordinate-orders panel on march; pursuit pending HUD; keeps politics + logistics + horse adapters |
| `game/mahan/mahan_politics_chapter.gd` | Additive guard: do not replace a pre-installed adapter model that already exposes `consult_subordinates` |
| `game/mahan/mahan_launch.gd` | Composes `mahan_orders_chapter.gd` |
| `game/tests/test_mahan_orders.gd` | Orders checks: hold rear, scout, pursue delay clock, strained disposition gate, ontology, Raj Kaur absence, launch smoke |
| `tools/run_checks.py` | Registers `test_mahan_orders.gd` after politics |
| `docs/MAHAN_INTERLUDE.md` | Orders loop + pursuit stub fence |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This orders note |

## Extended (this slice -- historical-event schema stub)

| Path | Change |
| --- | --- |
| `schemas/historical_event.schema.json` | NEW optional `historical-event.v1` schema (does **not** touch `world_state.schema.json`) |
| `schemas/historical_location.schema.json` | NEW optional `historical-location.v1` for settlement/road stubs |
| `data/history/locations/gujranwala_*.json` | Gujranwala settlement, garhi, fort road, Lahore approach (+ field camp stub) |
| `data/history/mahan_gujranwala_home_ground.json` | Home-ground historical-event frame referencing Gujranwala settlement |
| `data/history/mahan_singh_death_fixed.json` | Authored fixed-death frame; game-canon; player_knowledge starts false |
| `data/history/mahan_late_campaign_illness.json` | Authored illness frame; Mahan direct observer; delayed report route |
| `game/mahan/data/*.json` | Runtime copies identical to `data/history/` for `res://` load |
| `game/mahan/mahan_history_state.gd` | Loader/validator + knowledge fence on orders adapter; delayed historical custody |
| `game/mahan/mahan_history_chapter.gd` | Historical-frames panel; known-only display; keeps orders stack |
| `game/mahan/mahan_orders_chapter.gd` | Additive guard: do not replace a pre-installed adapter that exposes `observe_historical_event` |
| `game/mahan/mahan_launch.gd` | Composes `mahan_history_chapter.gd` |
| `game/tests/test_mahan_history.gd` | History checks: observe fence, delayed delivery, endpoint knowledge grant, ontology, Raj Kaur absence, launch smoke |
| `tools/run_checks.py` | Registers `test_mahan_history.gd` after orders |
| `tools/check_project.py` | Structural check: schema shape + data/history ↔ game/mahan/data identity |
| `docs/HISTORICAL_EVENTS.md` | Short historical-event stub doc |
| `docs/MAHAN_INTERLUDE.md` | Historical frames loop + schema fence |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This history note |


## Extended (this tip -- Gujranwala home-ground geography)

| Path | Change |
| --- | --- |
| `docs/GUJRANWALA.md` | NEW research notes: 1770s–1790s Sukerchakia/Gujranwala geography; source-class vs game-canon; uncertainty |
| `schemas/historical_location.schema.json` | Optional `historical-location.v1` (settlement/road/camp/fort stubs) |
| `data/history/locations/*.json` | Gujranwala settlement, camp, fort road, garhi, Lahore approach + field-camp stub |
| `data/history/mahan_gujranwala_home_ground.json` | Home-ground historical-event frame |
| `game/mahan/data/**` | Runtime mirrors of history locations + home-ground event |
| `game/mahan/mahan_state.gd` | March graph: `camp ↔ gujranwala_fort_road ↔ gujranwala_camp ↔ gujranwala_settlement` (+ retained ford/ridge); scout texts; labels |
| `game/mahan/mahan_chapter.gd` | Dynamic scout dispatch; Gujranwala greybox markers |
| `game/mahan/mahan_logistics_state.gd` | Forage yields for Gujranwala nodes |
| `game/mahan/mahan_*_chapter.gd` | Scout panels iterate `scout_targets()` |
| `game/mahan/mahan_history_state.gd` | Loads location stubs; resolves event `place_id` / `related_place_ids` |
| `game/tests/test_mahan.gd` | Gujranwala march path + epistemic fence |
| `game/tests/test_mahan_history.gd` | Location resolve + home-ground observe |
| `tools/check_project.py` | Location mirror identity + schema shape |
| `docs/MAHAN_INTERLUDE.md` / `docs/HISTORICAL_EVENTS.md` | Home-ground / march notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This note |

## Touched (unchanged role)

| Path | Change |
| --- | --- |
| `game/ui/main_menu.gd` | Fourth entry launching Mahan via `MahanLaunch.enter` |
| `tools/run_checks.py` | Registers base `test_mahan.gd` … `test_mahan_orders.gd`, then `test_mahan_history.gd`; prior suites remain invoked |
| `tools/check_project.py` | Menu assertion still requires home + command entries; also requires Mahan launch path |

## Deliberately left alone

- `schemas/world_state.schema.json` (unchanged; new optional file is `historical_event.schema.json` only)
- `data/world/1792_start.json`
- `game/childhood/childhood_state.gd`, `aftermath_state.gd`, `checkpoint_store.gd`, `home_chapter.gd`, `home_launch.gd`
- `game/campaign/command_state.gd`, `house_command_state.gd` (pattern mirrored, not rewritten)
- `game/world/home_territory.tscn` (byte-identical retention still enforced)
- `game/characters/character_names.gd` (Buddh/Ranjit presentation policy unchanged)
- `game/mounts/riding_rules.gd` core contracts (reused, not rewritten; Lahore allowlist intact)
- Silent cross-chapter knowledge merge (none added)
- Existing draft PR merge / `main` merge
- Full combat, full economy sim/taxation UI, full social sim / `house_command_state` rewrite, `antagonists.json` roster gates, expedition map
- Full combat sandbox / `patrol_director` rewrite (pursuit is delayed-custody stub only)
- Full research dossier pipeline / SuperGrok synthesis / Latif rewrites (historical-event stub only)

## Identity notes

- Childhood/Lahore protagonist key remains `ranjit_singh`.
- Mahan uses separate actor id `mahan_singh` and separate save path.
- Household graph object `sukerchakia` is not a Person/Dynasty/Faction/Alignment collapse.
- No automatic knowledge handoff into Buddh's journal.
- Undelivered scout custody never becomes Mahan journal knowledge early, and never crosses the profile fence.
- Mahan cavalry rider is `mahan_singh`; Lahore `Riding.validate` still admits only `ranjit_singh` / `patrol_captain`.
- Politics subordinates are separate Person ids under household relations to `sukerchakia`; not Faction tags; Raj Kaur absent from this slice.
- Orders reuses politics subordinate ids; scout/hold_rear/pursue stay under household relations; pursuit knowledge arrives only on delay-clock delivery.
- Historical-event actors keep Person ≠ Household ≠ Faction; Raj Kaur absent; `player_knowledge` refused unless observer / delivered report / campaign-frame endpoint ack.
- Gujranwala settlement is a place object (`gujranwala_settlement`); household remains `sukerchakia`; not a faction tag.
- Gujranwala march nodes enter `known_nodes` only on delivered scout custody; no silent childhood/Lahore knowledge handoff.


## Extended (this tip -- integration fence audit)

| Path | Change |
| --- | --- |
| `docs/MAHAN_FENCE_AUDIT.md` | NEW pass/fail/gap table for Mahan vs childhood vs Lahore fences |
| `game/tests/test_mahan_fence.gd` | Cross-profile save/knowledge/identity/ontology/menu fence suite |
| `tools/run_checks.py` | Registers `test_mahan_fence.gd` after history |
| `game/mahan/data/locations/gujranwala_settlement.json` | Mirror-synced to `data/history/locations/…` (`connects` includes `gujranwala_camp`) so check_project identity holds |
| `game/mahan/mahan_orders_chapter.gd` | **orders additive guard restored**: keep pre-installed HistoryModel (`observe_historical_event`) across `super._ready()` |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This fence note |

Identity notes (fence):

- Bidirectional save refuse covers childhood, aftermath, Lahore command, and house slots.
- No auto knowledge handoff APIs; grafted Mahan nodes refused by childhood/Lahore allowlists.
- `HERO_ID` remains `ranjit_singh`; Lahore `Riding.validate` still rejects `mahan_singh`.
- `world_state.schema.json` and `home_territory.tscn` digests unchanged.


## Full `tools/run_checks.py` wall-clock (this beat)

Proven on tip `92be95dd2f68765a900ff221e5af2f440f5eb923` with Godot **4.5.1.stable** (`/workspace/godot451/Godot_v4.5.1-stable_linux.x86_64`), `python3 tools/run_checks.py --godot …`, exit **0**. No Mahan-side hook fixes required; childhood/Lahore architecture untouched.

| Suite | Result |
| --- | --- |
| structure (`check_project`) | **9 OK** |
| import | OK |
| command-story | **202** passed, 0 failed |
| houses | **272** passed, 0 failed |
| riding | **177** passed, 0 failed |
| companions | **229** passed, 0 failed |
| character-names | **56** passed, 0 failed |
| childhood | **110** passed, 0 failed |
| aftermath | **164** passed, 0 failed |
| mahan | **197** passed, 0 failed |
| mahan-cavalry | **44** passed, 0 failed |
| mahan-logistics | **75** passed, 0 failed |
| mahan-politics | **89** passed, 0 failed |
| mahan-orders | **101** passed, 0 failed |
| mahan-history | **96** passed, 0 failed |
| mahan-encounter | **123** passed, 0 failed |
| mahan-fence | **121** passed, 0 failed |
| **Total runtime asserts (mahan family + prior)** | prior tip **1930** + encounter **123** + history/fence deltas (**+3**) → **2056** on this tip when full `run_checks` is re-run (+ 9 structural) |

Residual after full suite:

- Authored Gujranwala ridge→settlement encounter stub is on tip (greybox + historical-event frame; still no full combat / town sim).
- No accession / Buddh handoff cutter (fence proves absence; future opt-in only).
- Concurrent-agent PLACEHOLDER risk on core files remains procedural — prefer `push_files` for large restores.


## Extended (this tip -- Gujranwala ridge→settlement encounter stub)

| Path | Change |
| --- | --- |
| `data/history/mahan_gujranwala_ridge_settlement_approach.json` | NEW authored encounter historical-event frame (fort_road→settlement) |
| `game/mahan/data/mahan_gujranwala_ridge_settlement_approach.json` | Runtime mirror |
| `game/mahan/mahan_history_state.gd` | Catalog includes approach event (4 seeded events) |
| `game/mahan/mahan_encounter_state.gd` | NEW encounter adapter: greybox nodes, delayed approach scout, hold/advance choices within fixed endpoint |
| `game/mahan/mahan_encounter_chapter.gd` | NEW presentation + approach marker |
| `game/mahan/mahan_history_chapter.gd` | Additive guard so EncounterModel survives `super._ready()` |
| `game/mahan/mahan_launch.gd` | Composes encounter chapter |
| `game/tests/test_mahan_encounter.gd` | Encounter suite (custody clock, choices, ontology, launch smoke) |
| `game/tests/test_mahan_history.gd` | Catalog size 4 |
| `tools/run_checks.py` | Registers `mahan-encounter` before `mahan-fence` |
| `tools/check_project.py` | Approach event mirror + schema shape |
| `docs/GUJRANWALA.md` / `docs/MAHAN_INTERLUDE.md` / `docs/HISTORICAL_EVENTS.md` | Encounter notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This note |

Identity notes (encounter):

- Settlement remains a place object; household remains `sukerchakia`; Raj Kaur / Sandhawalia absent.
- Encounter choices cannot alter fixed death; no combat AI; delayed scout knowledge on delivery only.
- No `house_command_state` / `world_state.schema.json` rewrite.


### Encounter stub local wall-clock (this tip)

Godot **4.5.1.stable**; suites run at least:

| Suite | Result |
| --- | --- |
| structure | **9 OK** |
| mahan | **197** |
| mahan-cavalry | **44** |
| mahan-logistics | **75** |
| mahan-politics | **89** |
| mahan-orders | **101** |
| mahan-history | **96** |
| mahan-encounter | **123** |
| mahan-fence | **121** |

