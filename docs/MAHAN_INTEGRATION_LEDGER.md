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


## Extended (this slice -- subordinate orders / pursuit stub)

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

## Touched (unchanged role)

| Path | Change |
| --- | --- |
| `game/ui/main_menu.gd` | Fourth entry launching Mahan via `MahanLaunch.enter` |
| `tools/run_checks.py` | Registers base `test_mahan.gd`, `test_mahan_cavalry.gd`, `test_mahan_logistics.gd`, `test_mahan_politics.gd`, then `test_mahan_orders.gd`; prior suites remain invoked |
| `tools/check_project.py` | Menu assertion still requires home + command entries; also requires Mahan launch path |

## Deliberately left alone

- `schemas/world_state.schema.json`
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

## Identity notes

- Childhood/Lahore protagonist key remains `ranjit_singh`.
- Mahan uses separate actor id `mahan_singh` and separate save path.
- Household graph object `sukerchakia` is not a Person/Dynasty/Faction/Alignment collapse.
- No automatic knowledge handoff into Buddh's journal.
- Undelivered scout custody never becomes Mahan journal knowledge early, and never crosses the profile fence.
- Mahan cavalry rider is `mahan_singh`; Lahore `Riding.validate` still admits only `ranjit_singh` / `patrol_captain`.
- Politics subordinates are separate Person ids under household relations to `sukerchakia`; not Faction tags; Raj Kaur absent from this slice.
- Orders reuses politics subordinate ids; scout/hold_rear/pursue stay under household relations; pursuit knowledge arrives only on delay-clock delivery.
