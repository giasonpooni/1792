# Historical events (Mahan-scoped stub)

## Intent

Optional **historical-state event** records for the Mahan Singh interlude. Pipeline shape:

`source evidence → historical entity → event/relationship → time validity → location → who could know it? → gameplay representation`

This slice is a **schema + loader stub**, not a full research dossier pipeline.

## Schema

- File: `schemas/historical_event.schema.json`
- Version const: `historical-event.v1`
- **Does not** modify `schemas/world_state.schema.json` (digest check remains).

### Core fields

| Field | Role |
| --- | --- |
| `event_id` | Stable id |
| `date_range` | Time validity |
| `location` | Place id + optional `related_place_ids` |
| `actors[]` | `{id, role, kind}` person/household/faction |
| `evidence[]` | source / confidence / evidence_class A–D |
| `canon_class` | source_attested / reconstructed / game_canon / authored_fiction |
| `historical_outcome.fixed` | When true, no `alter_outcome` |
| `knowledge` | observers, report_routes, delay, player_knowledge |
| `gameplay` | playable, intervention_scope, invariants, profile_scope |

Companion: `schemas/historical_location.schema.json` (`historical-location.v1`).

## Authored seeds

| Event | Canon | Fixed? | Knowledge |
| --- | --- | --- | --- |
| `mahan_singh_death_fixed` | game_canon | yes | campaign-frame endpoint ack |
| `mahan_late_campaign_illness` | game_canon | no | observe or delayed report |
| `mahan_gujranwala_home_ground` | game_canon | no | observe (place_id=gujranwala_settlement) |

## Gujranwala locations

| location_id | kind | role |
| --- | --- | --- |
| `gujranwala_settlement` | settlement | home_ground |
| `gujranwala_garhi` | fort | reference_only |
| `gujranwala_fort_road` | road | approach |
| `gujranwala_camp` | camp | column_node |
| `gujranwala_lahore_approach` | road | reference_only |
| `sukarchakia_field_camp` | camp | column_node |

Evidence vs game-canon marked in each stub. See `docs/GUJRANWALA.md`.

## Non-goals

Full dossier pipeline, SuperGrok synthesis, Latif rewrites, combat, world_state bump, merge to main.
