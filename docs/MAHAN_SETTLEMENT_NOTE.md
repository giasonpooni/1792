# Gujranwala settlement observation — ledger note

Extended on draft PR #9 (`feat/mahan-interlude-v1`). See also [MAHAN_INTEGRATION_LEDGER.md](MAHAN_INTEGRATION_LEDGER.md), [GUJRANWALA.md](GUJRANWALA.md), [MAHAN_INTERLUDE.md](MAHAN_INTERLUDE.md).

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
| `docs/GUJRANWALA.md` / `docs/MAHAN_INTERLUDE.md` | Settlement observation notes |
| `docs/MAHAN_INTEGRATION_LEDGER.md` | Pointer + this note |

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
