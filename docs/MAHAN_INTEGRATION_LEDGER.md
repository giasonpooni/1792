# Mahan interlude v1 — integration ledger

Stacked on PR #7 tip `feat/ambush-aftermath-v1` @ `012145721af9fb2b9fc4be46399151765a888404`.

## Added

| Path | Role |
| --- | --- |
| `docs/MAHAN_INTERLUDE.md` | Playable intent, fixed endpoint, epistemic fence, source vs game-canon, non-goals |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | This ledger |
| `game/mahan/mahan_state.gd` | Isolated `mahan.v1` authority; actor `mahan_singh`; save `user://1792-mahan-v1.json` |
| `game/mahan/mahan_launch.gd` | Menu composition parallel to `home_launch.gd` |
| `game/mahan/mahan_chapter.gd` | Greybox camp + one authored recon/command beat |
| `game/world/mahan_camp.tscn` | New empty camp root (does not touch `home_territory.tscn`) |
| `game/tests/test_mahan.gd` | Domain validate, cross-profile refusal, one beat + save round-trip, menu smoke |

## Touched

| Path | Change |
| --- | --- |
| `game/ui/main_menu.gd` | Fourth entry launching Mahan via `MahanLaunch.enter` |
| `tools/run_checks.py` | Registers `test_mahan.gd` after aftermath; prior suites remain invoked |
| `tools/check_project.py` | Menu assertion still requires home + command entries; also requires Mahan launch path |

## Deliberately left alone

- `schemas/world_state.schema.json`
- `data/world/1792_start.json`
- `game/childhood/childhood_state.gd`, `aftermath_state.gd`, `checkpoint_store.gd`, `home_chapter.gd`, `home_launch.gd`
- `game/campaign/command_state.gd`, `house_command_state.gd`
- `game/world/home_territory.tscn` (byte-identical retention still enforced)
- `game/characters/character_names.gd` (Buddh/Ranjit presentation policy unchanged)
- `game/mounts/riding_rules.gd` and Lahore riding/companion libraries (not forked)
- Silent cross-chapter knowledge merge (none added)
- Existing draft PR merge / `main` merge

## Identity notes

- Childhood/Lahore protagonist key remains `ranjit_singh`.
- Mahan uses separate actor id `mahan_singh` and separate save path.
- No automatic knowledge handoff into Buddh's journal.
