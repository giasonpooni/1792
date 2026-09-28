# Childhood: learn the world before surviving it

## Play the implemented chapter

Run `game/project.godot` with Godot 4.5.1 Standard. Choose the existing **1792 · Buddh Singh · Home territory** entry. The menu now composes a childhood director onto the original home scene rather than opening another detached demonstration. Opening the bare `home_territory.tscn` directly still gives the retained reference scene.

This is a small, compressed, **authored source-informed prototype**, not a dated reconstruction of an actual day in 1792. The stationary quarry, training partner, courier, steward, anonymous attacker, dialogue and map are fictional placeholders. Latif's hunting-return ambush account informs the sequence; the escape outcome does not reproduce his narrated killing or territorial consequence. See [historical sources](HISTORICAL_SOURCES.md).

| Lesson | Actual input and completion |
| --- | --- |
| Find your bearings | Walk at least five metres with WASD and turn the view with the mouse. |
| A message you cannot read | Approach the courier and press E to acquire the sealed message. E again hears his account; E at the steward hears a reading. Both accounts are required, in either order. Seeing the document does not expose its words. |
| Horse practice | F mounts the existing horse; W advances, A/D steer, Shift requests canter, Ctrl walk, S/Space brake. Ride the three pole gates in order, stop, and F dismount on clear ground. |
| Guard and counter | Approach and face the trainer. Hold Q through two visibly telegraphed blows, then left-click during recovery. There is no damage in practice. |
| Hunting trail | Look toward and examine three tracks in order with E. Approach the stationary quarry while holding C, then E to observe it. Tracking/stalking are implemented; shooting, killing, harvesting and animal AI are not. |
| Return-path ambush | Return through the marked bend. An unnamed attacker approaches and telegraphs strikes. Make distance and reach the courtyard, or face the attacker, Q guard, then left-click during stagger to create an escape opening. Riding remains available. |
| Aftermath | Returning records survival, not proof of who commissioned the attack. Hear the two return accounts, negotiate with Raj Kaur, inspect the bend with or without a guard, and report back. R restores a separately retained checkpoint after a failed attempt. See [Aftermath](AFTERMATH.md). |

The courtyard tree offers an optional E reflection. It is original inner dialogue, not scripture, a historical quotation, a magical reveal or a farmable combat bonus. It is not a required tutorial gate.

J/F1 opens the remembered-accounts journal and pauses the chapter. F5/F9 save/load the childhood slot; Escape resumes. F4 toggles mild subjective peripheral framing without altering progress, collision, damage, testimony or font legibility. Keyboard/mouse is the tested input path; controller mapping and remapping UI are not implemented.

## What the player knows

The readable journal is a player-facing representation of remembered speech and direct experience. It is not Buddh independently reading a manuscript. Each memory retains a source ID, channel and receipt tick. A repeated statement is the same account, not another corroboration. The two fictional accounts have different temporal limits; disagreement does not automatically make either speaker a liar.

No true mastermind is secretly inferred and published by this prototype. Its anonymous assailant is not identified as Hashmat Khan or attached to a historical clan. Seeing an assault records the assault. Returning without seeing the assailant can still record that an attack happened, without inventing his identity. The practice waypoint is an explicit tutorial aid, not a supernatural perception ability or a historical map.

## State, execution and compatibility

`childhood_state.gd` owns this active scenario's `world-state.v1` record with additive `profile: childhood.v1`, stable hero ID `ranjit_singh`, one simulation tick, the original `riding.v1` dictionary and a bounded memory/progress substate. Only one chapter/campaign runs at a time. The Lahore command and house authorities are unchanged and never execute inside the childhood scene.

`home_launch.gd` composes `home_chapter.gd` onto the original PackedScene at menu launch. The original home scene bytes, player movement, horse controller, command authorities, world schema and prior tests remain unchanged. The existing home nameplate is hidden only in this composition. The future connection from childhood into the full political campaign is not implemented; this chapter does not silently migrate a home save into a Lahore save.

The scene submits bounded walking, horse and attacker motion after Godot physics. It uses the original mount controller's spatial mounting/dismounting checks. Inspecting tracks and quarry requires a character-eye line-of-sight query; the third-person camera cannot inspect through a wall. Practice and attacker strikes have visible/captioned timing and facing requirements. Attacker movement is simple direct pursuit with collision, not a navmesh planner or general tactical AI.

Simulation ticks assume the project's 60 Hz physics. Menus stop both actor movement and the clock. Rendering and the peripheral-framing toggle cannot advance lesson state. The resolved name is Buddh Singh throughout; public court address is still the existing explicit post-accession presentation policy in the Lahore scenes.

## Persistence

The composed chapter now uses `user://1792-childhood-aftermath-v1.json`. Its pause menu explicitly imports the former `user://1792-childhood-v1.json` without overwriting it. Checkpoints use the active save path plus `.checkpoint.json`, not the manual slot. `aftermath_state.gd` extends the unchanged childhood authority with one optional subrecord in the same `_state`; no second clock runs. Temporary-file replacement follows the existing save pattern. The bounded validator rejects nonfinite coordinates, nonintegral progress, unknown fields, causal lesson skips, rewritten testimony, invented firsthand memory, future receipt times and mismatched identity/clock/horse state. Discrete tick fields are normalized after validated JSON parsing; positional floating-point representation is not claimed bit-identical across engines.

Loading stages a candidate separately, then checks standing room/ground for the player and assailant and the existing horse hull against current collision geometry. An invalid load leaves the live authority and positions intact. This is an integrity boundary, not authentication or a security sandbox: same-process code can construct a valid alternative history, and the save is not signed. Godot's ordinary JSON parser is used; duplicate-key rejection is not claimed. Windows replacement behavior remains unverified.

## Verification and limits

`tools/run_checks.py` runs every existing suite, including `test_childhood.gd`, followed by `test_aftermath.gd`. The latter extends this journey with branch, guard and checkpoint tests. The new test exercises an actual menu signal and scene handoff, an input-driven whole lesson/escape journey, separate guard/counter fixtures, attributed memory and save round-trips, a wall-obstructed view, invalid spatial load, pause and the visual toggle. There is no progress/position injection after departure in the whole journey; camera steering is supplied by the test driver. Domain and encounter setup fixtures are marked separately.

`render_childhood.gd` supplies four visual fixtures: home, unopened meaning of a message, received accounts and the ambush. Those fixtures do not prove manual playtesting. New tests inject `user://childhood-regression-only.json`; they do not write player saves.

This is placeholder geometry, text captions and a bounded practice/escape encounter. No voice recordings, musical assets, medically validated vision simulation, dynamic eyesight progression, animation rig, full melee system, wall-running, jumping, climbing, advanced stealth, general NPC scheduling, branching family conspiracy or full-world chronology has been implemented. Physical-GPU performance, controller support and small-window usability require further testing.
