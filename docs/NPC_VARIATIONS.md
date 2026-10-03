# NPC variations (game-canon fiction)

These records are **authored fiction** for the Mahan / Gujranwala greybox. They are **not historical persons** and must not be cited as prosopography.

## Separation

Person ≠ dynasty ≠ household ≠ faction ≠ current alignment.

| Field | Generated value |
| --- | --- |
| `person_id` | Stable `fic_<seed tag>_<index>` |
| `dynasty_id` | `unspecified` |
| `household_id` | `unaffiliated_fiction` (never `sukerchakia`) |
| `faction_id` | `none` |
| `current_alignment` | Disposition band only (`wary`, `neutral`, `cordial`, `deferential`) |

## Fixed, not randomized

- Actors: `mahan_singh`, `ranjit_singh` (Buddh)
- Household object: `sukerchakia`
- `raj_kaur` is not generated and is not placed on any Sandhawalia roster. This module invents no Sandhawalia entries.

Roles are extras only: retainer, traveler, scout, forager, gate watcher. Clothing, kit, mount presence, disposition, and speech style come from `game/npc/data/variation_tables.json`.

## Determinism and fence

`game/npc/npc_variation.gd` rolls an LCG from an FNV-32 seed. The same seed and count always yield the same ids and columns.

Memories attached to a generated NPC stay on that record (`scope: generated_npc_only`, empty `transfers_to`). `spill_memories_to_journal` always refuses, including for `ranjit_singh` and `mahan_singh`. No childhood save, Lahore command state, or `world_state.schema.json` write.

`for_site` only tags sites already on the Mahan/Gujranwala greybox list (settlement, garhi, fort road, camp, ridge, ford, camp table). Other sites, including Lahore and the childhood home, are refused.

Suite: `npc-variation` in `tools/run_checks.py` (`NPC_VARIATION_TESTS`).
