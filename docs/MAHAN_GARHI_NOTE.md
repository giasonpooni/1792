# Gujranwala garhi landmark observation — ledger note

Extended on draft PR #9 (`feat/mahan-interlude-v1`). See also [MAHAN_INTEGRATION_LEDGER.md](MAHAN_INTEGRATION_LEDGER.md), [GUJRANWALA.md](GUJRANWALA.md), [MAHAN_INTERLUDE.md](MAHAN_INTERLUDE.md), [MAHAN_SETTLEMENT_NOTE.md](MAHAN_SETTLEMENT_NOTE.md).

## Extended (this tip -- Gujranwala garhi landmark observation)

| Path | Change |
| --- | --- |
| `game/mahan/mahan_garhi_state.gd` | NEW garhi adapter on settlement: examine rampart/gatehouse/bastion; attributed memories; delayed landmark report with `player_knowledge` false until delivery |
| `game/mahan/mahan_garhi_chapter.gd` | NEW presentation + garhi markers |
| `game/mahan/mahan_garhi_validate.gd` | Split-out ledger/memory validators |
| `game/mahan/mahan_settlement_chapter.gd` | Additive guard so GarhiModel survives `super._ready()` |
| `game/mahan/mahan_launch.gd` | Composes garhi chapter |
| `game/tests/test_mahan_garhi.gd` | Garhi suite (examine, custody clock, fort-road unlock, ontology, launch smoke) |
| `tools/run_checks.py` | Registers `mahan-garhi` between settlement and fence |
| `data/history/locations/gujranwala_garhi.json` (+ mirror) | Gameplay notes updated (role stays `reference_only`; still no siege) |
| `docs/GUJRANWALA.md` / `docs/MAHAN_INTERLUDE.md` | Garhi observation notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | Pointer + this note |

Identity notes (garhi landmark):

- Place `gujranwala_garhi` ≠ person; household remains `sukerchakia`; Raj Kaur / Sandhawalia absent; no religious framing.
- Sealed examine facts are attributed observations, not a surveyed fort plan or combat AI.
- Delayed report flips `player_knowledge` only on delay-clock delivery.
- Unlock via settlement **or** fort_road (existing stubs) or after `advance_under_custody`.
- No combat AI; fixed historical endpoint unchanged; no childhood/Lahore authority rewrite.

### Garhi landmark local wall-clock (this tip)

Godot **4.5.1.stable**; structure + mahan family (counts filled after local run):

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
| mahan-settlement | **139** |
| mahan-garhi | **140** (new) |
| mahan-fence | **121** |
| mahan-handoff | **101** |


## Full `tools/run_checks.py` wall-clock (tip `919448e`)

Full inherited + mahan* suite on tip `919448e163233fdd849ebcf41fcc1d56b209b123` (Godot **4.5.1.stable**): **2436** runtime asserts passed, 0 failed (+ **9** structural). See [MAHAN_INTEGRATION_LEDGER.md](MAHAN_INTEGRATION_LEDGER.md) for the complete table. No Mahan-side hook fixes; childhood/Lahore untouched.
