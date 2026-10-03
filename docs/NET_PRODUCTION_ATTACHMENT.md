# Optional NET production attachment: household water round

This first title-owned workload exposes the ORIGINAL `gujranwala_state.gd`,
`water_round_rules.gd` and inherited save/clock code to an external production
controller. No NET dependency is added to the playable game. The native batch exposed a one-float-step derived-clock discrepancy on JSON
reload at tick 274. The existing childhood restore now recomputes day/hour from
the authoritative integer tick after unchanged validation, using the original
clock mapping. Four checkpoint regressions retain exact equality and refusal of
inconsistent clocks. No scene, fixture, licence, mission or balance constant changes.

`game/tools/net/water_round_capture.gd` is a development entrypoint, not a new game
loop. The explicit post-inquiry fixture is the initial condition. Validated pose
fixtures position the character at interaction endpoints; this is **domain
execution, not walking, navigation, collision, rendering or human playtesting**.
It does not claim that the fixture's earlier childhood was played.

The snapshot is an explicit 11-script dependency closure. The operator selects
`tools/net/water-round.profile.json` by its exact file digest and separately pins
the extracted Godot 4.5.1 executable. `source_revision` records the existing title
revision context; the `files` map binds the actual workload bytes, including the
new harness. It does not claim the entire repository is attested by that label.

The existing game state owns every transition. The harness calls `advance()` six
times per observation interval, from observation 0 through 70: 420 existing
physics ticks, with elapsed capture time 7 seconds at the game's 60 Hz convention.
The capture clock is relative to water assignment; the original game tick is also
observed and appears in event payloads. No game clock is replaced or independently
integrated by NET.

At observation zero it starts drawing. Candidates vary first-deposit time
(29/30/31), second-deposit time (60/61/62), and checkpoint time (15/45).
At observation 31 the second draw is attempted, after any same-interval deposit.
The Cartesian product yields 18 independent candidate work orders. The fixed
baseline is first deposit 30, second deposit 61, checkpoint 15. Checkpointing calls
the original `save_to` and `load_from` through an explicit temporary path, then
continues with the freshly loaded game state. It does not use a player's save slot.

Nine fixed checks cover conservation of six **authored units, not litres**, no
currency change, valid original state, no refused actions, six stored units,
empty carrier, exhausted assignment, successful checkpoint roundtrip and exactly
420 physics ticks. Recorded refusals are valid diagnostic observations; they do
not become fake runtime crashes. Missing observations remain incomplete.
An explicit `drop-sample` qualification switch tests recorder completeness only.

## Verify and use

```sh
python tools/check_net_profile.py
```

In a separately installed NET checkout containing `game_project_workflow`, declare
an 18-case batch, then execute it with operator-pinned sources and Godot. Full
commands and the JSON work-order format are documented in NET's
`docs/INDUSTRIAL_GAME_PRODUCTION.md`. Agents submit parameter candidates; they
cannot change the title's acceptance checks through those candidates.

The title remains proprietary under the repository's existing project terms. The
reusable NET adapter contains no copied proprietary title code. Source files stay
in this repository and are copied only to a local temporary workload directory at
execution. Neither this profile nor a passing check authorizes publication,
release, historical-truth claims or state admission.
