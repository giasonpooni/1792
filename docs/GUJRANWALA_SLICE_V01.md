# Gujranwala Vertical Slice 0.1

This increment makes the existing Home chapter a named, resumable visit. It composes the current childhood, inquiry, water, workshop, service and bazaar implementations under a `New` / `Continue` entry. It does not replace their state authority, motor, clock, receipts or physical access gates.

## Play

Open `game/project.godot` in Godot 4.5.1 standard, press F5, and choose **Start a new Gujranwala run**. A new run begins with the actual childhood lessons. Complete the inquiry, hear the quartermaster's allowance, bring two water loads home, settle the smith commission, and walk with Mela and Jiva before returning with their account. The suggested order does not lock out other existing errands. Current cargo, company and contracted work take priority in guidance.

- `O`: route/checklist; the world pauses during the dialog.
- `E`: existing local interactions and conversations.
- `J` or `F1`: journal, controls, manual saves, checkpoints, and save-and-menu.
- `F5` / `F9`: manual save / restore for this run.
- **Continue**: restore the latest accepted visit, including positions, custody, receipts, received memories, task deadlines and camera.

The inherited gameplay remains an early prototype. The errands, timings, quantities and local architecture are authored fixtures, not surveyed Gujranwala geography or proof that the described childhood events occurred. This slice does not complete Ranjit Singh's life narrative or authorize DLC production.

## Runtime and identities

`slice_chapter.gd` extends `home_workshop_chapter.gd`; `WorkshopState` remains the single world authority. `route_guide.gd` is a read-only projection of existing state. It creates no quest ledger, rewards, events, historical knowledge or scene-specific copies of the world.

The continuation envelope records a random 128-bit run ID, camera, and unchanged authoritative world snapshot. The run ID identifies save slots, not a historical person, operation receipt or proof of execution. Each run has separate manual/checkpoint/bazaar retry paths. Starting a new run therefore cannot load an earlier run through R or the bazaar retry action, and existing Home/legacy slots are untouched. Older per-run manual saves remain on disk.

Continue validates the bounded envelope with a detached `WorkshopState`, checks the inherited physical standing/horse/agent access gates, and only then replaces the live model. Rejected JSON, receipts, poses or filesystem writes leave the earlier continuation file unchanged. A refused startup stays paused and does not overwrite the refused file with a fresh world.

The continuation writer uses a temporary file, flush, and replacement rename. It runs every 1,800 active ticks (30 seconds at the existing 60 Hz clock), at save-and-menu, and at OS close. Periodic saves wait for a physically restorable pose rather than interrupting a jump or vault. A filesystem failure holds the visit with an explicit message. Dialog pauses do not drive autosaves; no offline catch-up is performed. Camera/clocks/custody are restored together.

Remote smith `working` and `ready` produce identical route/checklist guidance. Only actual local pickup changes the carried-tool objective; the guide cannot invent a received readiness report. A cancelled/refunded smith commission is visibly marked cancelled and does not claim tool production.

## Verification

Run `python tools/run_bazaar_direction.py --godot /path/to/godot`. The existing full baseline runs before the new Slice suite; the runner fails on engine errors even if an assertion marker appears.

`test_gujranwala_slice.gd` covers bounded envelope/camera/run validation; exact snapshot roundtrip; invalid write/file/size refusal; pending and carried water plus workshop custody; original 180-tick draw deadline and six-unit conservation; same remote smith guidance; fresh-run retry isolation; paused startup/route state; cleared queued input; physical obstruction refusal; periodic/exit write refusal; save-before-menu; OS-close dispatch; and refused Continue/New preserving earlier bytes.

The new native input journey starts from one explicitly declared completed-inquiry fixture, walks the actual collision world, accepts/draws/deposits through E and buttons, unloads/reloads during the first draw, and completes both water trips. It is execution evidence for those actions after that fixture, not a claim that an entire childhood campaign was played.

Native visual inspection covers the actual main menu, route dialog and courtyard player camera at 1280×720 and 800×450 with Godot's OpenGL software renderer. This qualifies layout and rendering in that environment, not hardware performance, Windows rename behavior, controller experience, or human playtesting.

Local qualification on 1 October 2026: **120 Slice assertions and 9,972 inherited assertions across 28 Godot suites passed**, together with the inherited Python structural checks. The tested engine was `4.5.1.stable.official.f62fdbde1`; its Linux ZIP SHA256 was `02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd`. The new suite also confirms active supply cargo/caravan guidance takes priority over idle water and remote pending smith work.
