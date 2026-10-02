# Mahan → Buddh handoff cutter (opt-in, default deny)

Status: **stub cutter / API + tests**. No accession scene. No Buddh-side receiver UI.
No silent merge on menu load. Live write into childhood / Buddh save slots is **future**.

Tip family: draft PR #9 `feat/mahan-interlude-v1`.

## Goal

Provide an **explicit controller-approved** transfer path for *selected report IDs*
from the Mahan interlude (`profile: mahan.v1`, actor `mahan_singh`) toward the
Buddh / early-Ranjit identity (`ranjit_singh` via existing `character_names`
presentation). Default behaviour is **refuse**. Knowledge must never cross the
profile fence silently.

## Hard rules

| Rule | Enforcement |
| --- | --- |
| **Default deny** | `can_handoff()` is false unless `opt_in=true` **and** `allowlist_report_ids` is non-empty |
| **Selected IDs only** | `propose_transfer(ids, …)` accepts only IDs present on the controller allowlist |
| **No wholesale journal merge** | Journal text bodies are never copied; `journal_texts` on a packet must stay empty; helpers refuse `*`, `all`, `journal`, and `merge_journal_wholesale` |
| **No silent map graft** | Writing Mahan `known_nodes` into a Buddh knowledge bag requires a separate `allowlist_known_nodes`; default empty → refuse |
| **historical_outcome stays fixed** | Handoff cannot alter fixed death / campaign endpoint; packets carry `historical_outcome_fixed: true` |
| **No childhood slot write (this stub)** | `apply_transfer` always refuses `childhood_save_path` / `allow_childhood_slot_write`; live apply is future |
| **No core rewrites** | Does **not** rewrite `childhood_state`, `command_state`, `house_command_state`, or `character_names` accession inference |
| **No menu auto-transition** | Launch / main menu must not call apply; cutter is opt-in API only |

## Controller shape

```text
{
  "opt_in": false,                 # must flip to true
  "allowlist_report_ids": [],      # selected scout/history report ids only
  "allowlist_known_nodes": [],     # optional; required to graft map ids into a bag
  "approve_apply": false,          # propose ≠ apply; apply needs this flip
  "allow_childhood_slot_write": false  # ignored / refused in this stub
}
```

`MahanHandoff.fresh_controller()` returns the default-deny dictionary above.

## API (`game/mahan/mahan_handoff.gd`)

| Function | Behaviour |
| --- | --- |
| `can_handoff(controller)` | `true` only with opt-in + non-empty report allowlist |
| `propose_transfer(ids, source_snapshot, controller)` | Builds a dry packet of selected report IDs; refuses otherwise. Packet **omits** journal texts and known_nodes |
| `apply_transfer(packet, controller, target)` | Refuses unless opt-in + allowlist + `approve_apply`. Always refuses childhood save-slot writes. Refuses wholesale journal merge and unallowlisted `graft_known_nodes`. Opted-in success is a **dry-run receipt** (`applied: false`) |
| `refuse_wholesale_journal_merge(journal, controller)` | Always returns a refuse string |

Target dictionary (test / future receiver hooks):

- `knowledge_bag` — fake Buddh bag (tests); not a childhood save
- `graft_known_nodes` — attempted map ids (refused without `allowlist_known_nodes`)
- `merge_journal_wholesale` / `journal_texts` — always refuse
- `childhood_save_path` / `write_childhood_slot` — always refuse in stub
- `historical_outcome` / `alter_historical_outcome` — always refuse
- `silent_merge` / `auto_merge` — always refuse

## What transfers (when explicitly approved)

**Now (stub):** only a dry-run receipt listing selected `report_ids`. No journal bodies,
no automatic `known_nodes`, no childhood file mutation, no alternate history.

**Future (not this beat):** a Buddh-side receiver that, under the same controller
gates, materialises allowlisted report *metadata* into a Buddh-scoped knowledge
store — still never wholesale journal paste, still never silent menu merge, still
never flipping `historical_outcome.fixed`.

## Epistemic separation (restated)

Mahan observations, scout reports, map knowledge (`known_nodes`), and history
ledger rows live only inside `mahan.v1`. They do **not** become `ranjit_singh` /
Buddh knowledge unless a controller explicitly opts in and allowlists the
specific report IDs. See also [MAHAN_INTERLUDE.md](MAHAN_INTERLUDE.md) epistemic
fence and [MAHAN_FENCE_AUDIT.md](MAHAN_FENCE_AUDIT.md).

## Out of scope

- Buddh-side receiver UI
- Merging save stacks / alternate history / combat
- Accession cinematic or menu auto-start
- Rewriting childhood / Lahore / house authorities
- Merge to `main`

## Tests

- `game/tests/test_mahan_handoff.gd` — default refuse; wholesale journal refuse;
  known_nodes bag refuse without allowlist; opted-in propose + dry-run apply;
  childhood slot write refuse; historical_outcome fixed
- Fence suite continues to prove absence of silent `handoff_to_*` / `merge_knowledge`
  methods on the Mahan authority itself
