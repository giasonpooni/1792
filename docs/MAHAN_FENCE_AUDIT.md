# Mahan integration fence audit

Tip audited: draft PR #9 `feat/mahan-interlude-v1` @ `99fa0cab01ed3223d9517ac8f15885d23d5a0a25` (pre-fence commit), then fence-test landing on the same branch.

Scope: **Mahan vs childhood vs Lahore** save / knowledge / identity / ontology / schema / menu fences. No architecture rewrite. Core validators and `world_state.schema.json` / `home_territory.tscn` left untouched except test registration.

Automated proof lives in:

- existing `game/tests/test_mahan*.gd` (domain fences already present)
- new `game/tests/test_mahan_fence.gd` (cross-profile integration matrix)
- `tools/check_project.py` digests (schema + home PackedScene)

## Checklist

| # | Fence | Result | Proof | Notes |
| --- | --- | --- | --- | --- |
| 1 | **Save isolation** — Mahan save must not load into childhood / aftermath / command / house slots and vice versa | **PASS** | `test_mahan.gd` `_cross_profile_fence`; **extended** in `test_mahan_fence.gd` `_save_isolation` | Bidirectional file + dictionary refuse for childhood, aftermath, Lahore `command_state`, and `house_command_state`. Canonical paths stay distinct (`user://1792-mahan-v1.json` ≠ childhood/aftermath/command/house). |
| 2 | **Knowledge isolation** — Mahan journal / `known_nodes` / history events must not appear in Ranjit/Buddh childhood or Lahore `known_places` after any transition stub (no auto handoff) | **PASS** (no handoff exists) | `test_mahan_fence.gd` `_knowledge_isolation`; prior Gujranwala epistemic checks in `test_mahan.gd` | Grafting Mahan nodes into childhood `known_places` or Lahore allowlist is refused; childhood journal lacks Mahan tokens; no `handoff_to_*` / `merge_knowledge` APIs; history `profile_scope` stays `mahan.v1`. |
| 3 | **Identity** — `HERO_ID` remains `ranjit_singh`; `mahan_singh` is separate; Lahore riding validate still rejects `mahan_singh` | **PASS** | `test_mahan_cavalry.gd`; **extended** in `test_mahan_fence.gd` `_identity` | Explicit `Names.HERO_ID == "ranjit_singh"`; positive control that `Riding.validate` still admits `ranjit_singh`. |
| 4 | **Ontology** — Sukerchakia household ≠ person; no Raj Kaur on Sandhawalia in Mahan data | **PASS** | cavalry / logistics / politics / orders / history suites; **extended** in `test_mahan_fence.gd` `_ontology` | `household_id: sukerchakia` is not an `actors` Person key; Sandhawalia / Person-as-household restores refused; Raj Kaur / Sandhawalia / Phulkian tokens absent from snapshot + authored catalog. |
| 5 | **Schema** — `historical_event.schema.json` additive; `world_state.schema.json` unchanged digest | **PASS** | `check_project.py` `test_original_world_schema_is_not_replaced` (git blob sha1 `5bb28190…`); history suite + fence schema smoke | Optional `historical-event.v1` / `historical-location.v1` only. Mirror sync: tip had drifted `game/mahan/data/locations/gujranwala_settlement.json` vs `data/history/…` (`connects` missing `gujranwala_camp`); **synced to `data/history` copy** so `check_project` identity holds. |
| 6 | **Menu** — Mahan entry composes without mutating home PackedScene bytes | **PASS** | `check_project.py` `test_legacy_home_scene_is_retained_byte_for_byte` (git blob sha1 `48d9a1ed…`); `test_mahan.gd` menu smoke; **extended** in `test_mahan_fence.gd` `_schema_and_menu` | Launch + menu instantiate leave `home_territory.tscn` byte-identical. |


## Godot suite counts (this beat, local Godot 4.5.1)

| Suite | Result |
| --- | --- |
| mahan | **197 passed**, 0 failed |
| mahan-cavalry | **44** |
| mahan-logistics | **75** |
| mahan-politics | **89** |
| mahan-orders | **101** |
| mahan-history | **95** (restored after orders additive guard) |
| mahan-fence | **119** (new) |
| `tools/check_project.py` | **9 OK** (world_state + home digests intact; history mirrors identical) |

## Residual gaps

| Gap | Severity | Suggested follow-up |
| --- | --- | --- |
| No authored *transition scene* yet — fence proves absence of handoff APIs and graft refusal, not a future accession cutter | Low (by design) | When an accession beat is authored, add an explicit refuse/opt-in test rather than silent merge |
| Player-facing save UI still uses per-chapter paths; no shared save browser that could mix slots | Low | Keep chapter-local F5/F9; if a meta save UI appears, gate by `profile` |
| `test_mahan.gd` Gujranwala cases are on tip; concurrent-agent PLACEHOLDER risk on core files remains procedural | Process | Keep ledger “do not stub” note; prefer `push_files` for large restores |
| Full `run_checks` wall-clock across all non-Mahan suites not re-proven in this beat if machine time-boxes | Ops | Re-run full `tools/run_checks.py --godot …` on tip after fence land |
| ~~History chapter launch overwrote HistoryModel~~ — **fixed this beat** via orders additive guard | Was High | `mahan_orders_chapter.gd` now keeps a pre-installed `observe_historical_event` model (ledger already claimed this) |

## Deliberately not changed

- `schemas/world_state.schema.json`
- `game/world/home_territory.tscn`
- childhood / aftermath / Lahore / house core validators (read-only consumers in fence tests)
- Architecture / adapter stack order (`history` still composes on `orders` … `state`)
- Merge to `main`

## Fix landed with this audit

- Restored missing additive guard on `mahan_orders_chapter.gd` so HistoryModel is not clobbered by OrdersModel during `super._ready()` (matches ledger intent; history suite back to **95 passed**).

## Suggested next beat

1. Keep fence suite green on every Mahan tip push.
2. If accession / Buddh handoff is designed, add an *opt-in* transfer schema with explicit player consent — never silent journal merge.
3. Optional: pack any remaining local-only Gujranwala march-node extras already noted in the PR body.
