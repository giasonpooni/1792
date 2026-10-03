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
| `docs/GUJRANWALA.md` | NEW research notes: 1770s-1790s Sukerchakia/Gujranwala geography; source-class vs game-canon; uncertainty |
| `schemas/historical_location.schema.json` | Optional `historical-location.v1` (settlement/road/camp/fort stubs) |
| `data/history/locations/*.json` | Gujranwala settlement, camp, fort road, garhi, Lahore approach + field-camp stub |
| `data/history/mahan_gujranwala_home_ground.json` | Home-ground historical-event frame |
| `game/mahan/data/**` | Runtime mirrors of history locations + home-ground event |
| `game/mahan/mahan_state.gd` | March graph: camp <-> gujranwala nodes (+ ford/ridge); scout texts; labels |
| `game/mahan/mahan_chapter.gd` | Dynamic scout dispatch; Gujranwala greybox markers |
| `game/mahan/mahan_logistics_state.gd` | Forage yields for Gujranwala nodes |
| `game/mahan/mahan_*_chapter.gd` | Scout panels iterate `scout_targets()` |
| `game/mahan/mahan_history_state.gd` | Loads location stubs; resolves event place ids |
| `game/tests/test_mahan.gd` | Gujranwala march path + epistemic fence |
| `game/tests/test_mahan_history.gd` | Location resolve + home-ground observe |
| `tools/check_project.py` | Location mirror identity + schema shape |
| `docs/MAHAN_INTERLUDE.md` / `docs/HISTORICAL_EVENTS.md` | Home-ground / march notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This note |

## Touched (unchanged role)

| Path | Change |
| --- | --- |
| `game/ui/main_menu.gd` | Fourth entry launching Mahan via `MahanLaunch.enter` |
| `tools/run_checks.py` | Registers mahan suites through handoff; prior suites remain |
| `tools/check_project.py` | Menu assertion requires home + command + Mahan launch path |

## Deliberately left alone

- `schemas/world_state.schema.json` (unchanged; optional `historical_event.schema.json` only)
- `data/world/1792_start.json`
- childhood/aftermath/checkpoint/home chapter authorities
- `command_state.gd`, `house_command_state.gd` (pattern mirrored, not rewritten)
- `home_territory.tscn`, `character_names.gd`, `riding_rules.gd` core contracts
- Silent cross-chapter knowledge merge; draft/`main` merges
- Full combat / economy / social sim / antagonists roster / expedition map

## Identity notes

- Childhood/Lahore protagonist key remains `ranjit_singh`; Mahan uses `mahan_singh`.
- Household graph object `sukerchakia` is not a Person/Dynasty/Faction/Alignment collapse.
- No automatic knowledge handoff into Buddh's journal.
- Gujranwala settlement is a place object; household remains `sukerchakia`.
- Undelivered scout custody never becomes journal knowledge early.

## Extended (this tip -- integration fence audit)

| Path | Change |
| --- | --- |
| `docs/MAHAN_FENCE_AUDIT.md` | NEW pass/fail/gap table |
| `game/tests/test_mahan_fence.gd` | Cross-profile fence suite |
| `tools/run_checks.py` | Registers fence after history (now after settlement) |
| `game/mahan/data/locations/gujranwala_settlement.json` | Mirror-synced |
| `game/mahan/mahan_orders_chapter.gd` | Orders additive guard restored |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This fence note |

## Extended (this tip -- Gujranwala ridge->settlement encounter stub)

| Path | Change |
| --- | --- |
| `data/history/mahan_gujranwala_ridge_settlement_approach.json` | NEW encounter historical-event frame |
| `game/mahan/data/mahan_gujranwala_ridge_settlement_approach.json` | Runtime mirror |
| `game/mahan/mahan_encounter_state.gd` | Encounter adapter |
| `game/mahan/mahan_encounter_chapter.gd` | Presentation + approach marker |
| `game/mahan/mahan_launch.gd` | Composes encounter chapter |
| `game/tests/test_mahan_encounter.gd` | Encounter suite (**123**) |
| `tools/run_checks.py` | Registers mahan-encounter |
| `docs/GUJRANWALA.md` / `docs/MAHAN_INTERLUDE.md` | Encounter notes |

## Extended (this tip -- Mahan->Buddh opt-in handoff cutter)

| Path | Change |
| --- | --- |
| `docs/MAHAN_HANDOFF.md` | NEW design |
| `game/mahan/mahan_handoff.gd` | Opt-in cutter (default deny) |
| `game/tests/test_mahan_handoff.gd` | Handoff suite (**101**) |
| `tools/run_checks.py` | Registers mahan-handoff after fence |

## Extended (this tip -- Gujranwala settlement observation greybox)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_settlement_state.gd` | NEW settlement adapter on encounter: examine walls/gate/well/house; attributed memories; delayed local rumor with `player_knowledge` false until delivery |
| `game/mahan/mahan_settlement_chapter.gd` | NEW presentation + settlement markers |
| `game/mahan/mahan_settlement_validate.gd` | Split-out ledger/memory validators |
| `game/mahan/mahan_encounter_chapter.gd` | Additive guard so SettlementModel survives `super._ready()` |
| `game/mahan/mahan_launch.gd` | Composes settlement chapter |
| `game/tests/test_mahan_settlement.gd` | Settlement suite (examine, custody clock, ontology, launch smoke) |
| `tools/run_checks.py` | Registers `mahan-settlement` between encounter and fence |
| `docs/GUJRANWALA.md` / `docs/MAHAN_INTERLUDE.md` / `docs/MAHAN_SETTLEMENT_NOTE.md` | Settlement observation notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This note |

Identity notes (settlement observation):

- Settlement remains a place object; household remains `sukerchakia`; Raj Kaur / Sandhawalia absent; no religious framing.
- Sealed examine facts are attributed observations, not town omniscience or economy sim.
- Local rumor knowledge flips `player_knowledge` only on delay-clock delivery.
- No combat AI; fixed historical endpoint unchanged; no childhood/Lahore authority rewrite.

### Settlement observation local wall-clock (this tip)

Godot **4.5.1.stable**; structure + mahan family:

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
| mahan-settlement | **139** (new) |
| mahan-fence | **121** |
| mahan-handoff | **101** |

## Extended (this tip -- Gujranwala garhi landmark observation)

See **[MAHAN_GARHI_NOTE.md](MAHAN_GARHI_NOTE.md)** for path table, identity notes, and suite counts (ledger size split).

`mahan_garhi_*` on settlement: examine rampart/gatehouse/bastion; delayed report; fort_road/settlement unlock; no combat/siege; fence+handoff green.


## Full `tools/run_checks.py` wall-clock (tip `919448e`)

Proven on tip `919448e163233fdd849ebcf41fcc1d56b209b123` (`feat/mahan-interlude-v1`) with Godot **4.5.1.stable** (`/workspace/godot451/Godot_v4.5.1-stable_linux.x86_64`), `python3 tools/run_checks.py --godot …`, exit **0**. No Mahan-side hook fixes required; childhood/Lahore architecture untouched; no merge.

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
| mahan-settlement | **139** passed, 0 failed |
| mahan-garhi | **140** passed, 0 failed |
| mahan-fence | **121** passed, 0 failed |
| mahan-handoff | **101** passed, 0 failed |
| **Total runtime asserts** | **2436** passed, 0 failed (+ 9 structural) |

Inherited non-Mahan runtime: **1210**. Mahan-family runtime: **1226**.

Residual / suggested next playable beat (pick one; still no combat AI rewrite, no childhood/Lahore architecture rewrite, no merge):

1. **Column contact stub** — deepen the existing ridge→settlement / pursuit delayed-custody contact without combat AI (hold_observe / advance_under_custody presentation + custody clocks only).
2. **Baggage train logistics deepen** — extend forage / wait / stockout / march-cost on Gujranwala nodes (still no economy UI).
3. Keep `mahan-garhi` + settlement + fence + handoff green on every tip push; prefer `push_files`; never PLACEHOLDER-stub.


## NPC variations (fiction extras — not merged)

Bounded randomizer on `feat/mahan-interlude-v1` only. Does not rewrite childhood/Lahore architecture, identity, save format, or `world_state.schema.json`.

| Path | Change |
| --- | --- |
| `game/npc/data/variation_tables.json` | Role, clothing, kit, mount, disposition, speech tables. Canonical ids fixed. `raj_kaur` / Sandhawalia forbidden. |
| `game/npc/npc_variation.gd` | Seeded generator, site tag for Gujranwala greybox, memory attach, journal spill always refuses |
| `game/tests/test_npc_variation.gd` | Determinism, uniqueness, canonical-id refusal, epistemic fence |
| `docs/NPC_VARIATIONS.md` | Marks output as game-canon fiction, not historical persons |
| `tools/run_checks.py` | Registers `npc-variation` after `mahan-handoff` |

Godot **4.5.1.stable**: `NPC_VARIATION_TESTS: 284 passed, 0 failed`. Structural `check_project`: 9 OK. No merge to `main`.
