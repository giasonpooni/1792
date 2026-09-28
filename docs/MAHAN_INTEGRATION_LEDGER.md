# Mahan interlude — integration ledger

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
| `game/mahan/mahan_state.gd` | Scout detachments with Lahore-shaped delay custody; `known_nodes`; camp→ford→ridge march; provisions stub; knowledge on delivery only |
| `game/mahan/mahan_chapter.gd` | Dispatch / pending HUD / march panels; ford & ridge markers |
| `game/tests/test_mahan.gd` | Delay-clock, pending-vs-delivered, hold vs advance march, provisions/adjacency, fence |
| `docs/MAHAN_INTERLUDE.md` | Playable loop for recon delay + column nodes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | Extension note |

## Extended (this slice — cavalry via riding_rules)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_state.gd` | Opt-in `enable_riding()`; mount/dismount/`record_ride` for rider `mahan_singh`; reuses `riding_rules` VERSION/HORSE_ID/distances without rewriting Lahore `Riding.validate`; `household_id: sukerchakia` graph object; dismount gates on dispatch/decide/march/endpoint |
| `game/mahan/mahan_chapter.gd` | Spawns `horse.tscn` adapter; **F** mount/dismount; mounted physics step; HUD mount status; ride greybox toward authored nodes |
| `game/tests/test_mahan.gd` | Cavalry opt-in, mount gates, short ride, Lahore validate still rejects `mahan_singh`, save/load + ontology refusal |
| `docs/MAHAN_INTERLUDE.md` | Cavalry loop + ontology fence |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This cavalry note |

## Touched (unchanged role)

| Path | Change |
| --- | --- |
| `game/ui/main_menu.gd` | Fourth entry launching Mahan via `MahanLaunch.enter` |
| `tools/run_checks.py` | Registers `test_mahan.gd` after aftermath; prior suites remain invoked |
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
- Full combat, economy UI, clan politics rewrite, expedition map

## Identity notes

- Childhood/Lahore protagonist key remains `ranjit_singh`.
- Mahan uses separate actor id `mahan_singh` and separate save path.
- Household graph object `sukerchakia` is not a Person/Dynasty/Faction/Alignment collapse.
- No automatic knowledge handoff into Buddh's journal.
- Undelivered scout custody never becomes Mahan journal knowledge early, and never crosses the profile fence.
- Mahan cavalry rider is `mahan_singh`; Lahore `Riding.validate` still admits only `ranjit_singh` / `patrol_captain`.
