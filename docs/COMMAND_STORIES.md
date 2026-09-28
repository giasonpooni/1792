# Playable command stories

## What this slice adds

One separate, deliberately fictional Lahore command sandbox: Ranjit assigns a road patrol,
the player controls its captain or delegates the SAME order, and a delayed report brings
its outcome back to the command hub. This is a small executable prototype, not the full campaign.

The original 1792 home scene and original `world-state.v1` schema remain unchanged.
The menu exposes both prototypes. The sandbox's 1801 fixture is a development setting,
not a claim that this invented patrol occurred in that year. Starting it does not time-skip
or overwrite the original opening. Its captain is fictional; historical commanders and
expedition chronologies require source review before their stories are added.

## Try the loop

Open `game/project.godot` in the standard Godot editor (reference test target: 4.5.1).
Run the project and choose **Lahore · Command story**. Walk toward the courtyard table
and press E. Assign the four-rider patrol, press E again, then choose **Play as the captain**.
Follow the marked dirt road to the village and press E. Continue to the outpost, press E,
and choose **Organize patrol**. Control returns to Ranjit at his saved position. After four
game minutes, the report appears in the received-report journal and the riders become available again.

The two-rider scout package cannot secure the road. It can gather observations and withdraw.
A retreat before observing the outpost produces a report with unknown road security, not invented intelligence.

E away from a field objective opens the captain's field menu. **Return to Lahore and delegate**
releases control without resetting the captain, order, budget, route progress, or world clock.
From the courtyard table, Ranjit can take control of that deployed captain again.

F5 saves; F9 loads. F1 opens a pause menu. Escape closes a decision menu or releases the mouse.
Click the world to recapture the mouse. WASD moves, Shift runs, and the mouse orbits the camera.
The save lives at Godot's `user://1792-command-story-v1.json`, separate from the historical starting fixture.
On Windows the default location is `%APPDATA%/Godot/app_userdata/1792/`.

## Ownership and lifecycle

`game/campaign/command_state.gd` owns the sandbox state. `command_sandbox.gd` presents it
and submits actions. It does not grant itself success or independently award resources.
Both manual play and the delegated policy use the same observation and outcome functions.

```text
available → assigned → active (manual OR delegated) → reporting → completed
                └── cancel before departure → available
```

An order has an issuer ID, commander ID, unique order ID, allocation and progress.
The active player character is a separate identity. The report has its own evidence ID,
observer, observation time and arrival time. An ordered event log records transitions.
This is ordinary single-player provenance, not a cryptographic certificate or event-replay engine.

Only one executor owns the captain at a time. Manual control suspends delegated movement.
Switching viewpoints never moves the other character to the player's old position.
One fixed simulation tick is one game minute; the scene advances two ticks per real second.
Decision menus explicitly pause the sandbox clock. The render-frame accumulator is presentation
state, not a saved simulation clock; loading restarts it without advancing a campaign tick.

## Resources, consequences and information

| Package | Riders reserved | Supplies committed | Coins committed |
| --- | ---: | ---: | ---: |
| Scouts | 2 | 3 | 10 |
| Patrol | 4 | 6 | 20 |

All quantities are gameplay placeholders. Assignment reserves the budget, cancellation before
start returns all of it, deployment commits supplies and coins, and report arrival releases riders once.
The prototype does not simulate casualties, troop formations or actual returning rider entities.

Organizing a patrol changes outpost security from 0.35 to 0.60 and captain trust from 0.50 to 0.60.
Withdrawal changes them to 0.25 and 0.45. These are designer-authored test values, not historical
measurements or a validated social model. Neither result transfers territorial ownership.
A future contestation system must distinguish military presence, allegiance, revenue and administration.

Characters hold separate known-place lists. A captain's observations do not instantly update Ranjit's
knowledge. The Lahore journal only reads delivered reports. `snapshot()` exposes full truth for
saving and development; it is NOT the player-facing intelligence API. There is no physical courier yet.

## Save contract

The snapshot retains `schema_version: world-state.v1` and adds the profile
`command_schema_version: command-story.v1`. The legacy example remains valid under its original
schema; it is not silently promoted into a later-era command save. Unsupported profiles are refused.

The domain validator checks structure, finite positions, references, executor ownership, observation
order, report timing, resource accounting and event ordering before replacing the live state.
A failed load leaves the current session intact. Writes use a checked temporary file and rename;
I/O failures are returned to the UI. This is not a guarantee against every filesystem or power-loss failure.
Unknown top-level extension fields are preserved. Saves are bounded to 1 MiB in this prototype.

## Tests

```sh
python tools/check_project.py
python tools/run_checks.py --godot /path/to/godot
```

The first command is structural validation only; it cannot certify GDScript execution.
The second requires an actual engine, imports the project, runs domain invariants and scene interactions,
and fails on script/runtime errors or a missing completion marker. No engine means a nonzero exit,
not a false pass. Tests position actors directly for domain cases and separately exercise actual physics
movement and the scene's interaction handlers. This is not a full mouse-driven or human usability test.

The GitHub workflow additionally attempts software-rendered screenshots under Xvfb. The engine ZIP
is version- and SHA256-pinned, Actions are commit-pinned, and the workflow has read-only repository permissions.
CI evidence must be read for the actual commit; a workflow definition is not evidence that it passed.

## Boundaries for subsequent work

This slice intentionally has one order, two playable identities and three greybox locations.
It has no horses, character animation, combat, stealth, army rendering, real Lahore reconstruction,
multiple concurrent expeditions, regional streaming, historical commanders, commander mortality,
faction simulation, Bevy runtime, Blender asset pack or NET transport.

Godot remains gameplay authority. Blender can replace the blockout assets without changing order
logic. A future Bevy provider may own delegated simulation only behind an explicit ownership transfer;
it must not become a second writer for the same captain. NET can inspect exported snapshots or run
experiments later; it is not required to launch the game. The next useful step is improving movement,
adding a horse and a small companion patrol, then replacing the outpost decision with an actual encounter.
