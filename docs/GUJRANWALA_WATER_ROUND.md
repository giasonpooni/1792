# Water for the Household

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## Playable increment

After the existing household inquiry and allowance, ask the quartermaster to
assign a water round. Walk out through the courtyard's open front, around the
east wall, and north to the existing well. Face the well and press E, then choose
Draw. Remain nearby for 180 existing physics ticks (three seconds at 60 Hz).
Walking away or choosing Cancel stops the draw without consuming the allocation.
Return on foot and select Deposit at the quartermaster. Repeat once to finish.

The assigned round is six abstract units, three per load. These are **not litres**,
not the well's capacity, and not an aquifer model. Loaded walking/running is capped
at three game metres per second; open carriers cannot be mounted. Depositing
restores the original locomotion settings. The household vessel visibly records
whether water has been delivered, and the player carries a primitive bucket.

No new money is paid, and the task cannot be accepted or completed repeatedly.
Time spent travelling/drawing advances the existing supply watches, wages and
food/fodder obligations. Water does not yet constrain production, satisfy thirst,
or undergo recurring consumption. This is one optional physical service task,
not a complete water economy. Ignoring it does not break the existing missions.

## Historical evidence and its limits

Chetan Singh's *Well-irrigation methods in medieval Panjab: The Persian wheel
reconsidered* (1985, Indian Economic & Social History Review 22(1), pp. 73–87)
provides a research route into different regional water-lifting practices.
The publisher's publicly visible notes distinguish rope/bucket, lever and wheel
contexts; note 15 warns against simply transferring modern groundwater depths
into earlier periods. Note 33 references Gujranwala in the later Imperial Gazetteer.
Only the publisher's metadata and visible notes were consulted in this increment;
the access-restricted article body and cited Gazetteer page were not obtained.

Source: https://journals.sagepub.com/doi/10.1177/001946468502200104
Locators: notes 2, 15, 22, 33 and 38. This is regional comparative research, **not**
evidence that this exact household well, bucket, task or rate existed in 1792.
The prototype does not call its hand-worked animation a calibrated Persian wheel.

The Department of Archaeology and Museums' birthplace inventory describes the
surviving haveli's courtyard/reception arrangement and an inferred more open
late-eighteenth-century setting. The record also labels the site's relative
chronology 1799–1849 while attributing an earlier birth to it. Surviving fabric,
site associations and construction phases must therefore remain separate claims.
The entry is itself based on an architectural website, not a 1792 measured plan.

Source: https://doam.gov.pk/public/sites/10111
Locators: Relative Chronology, Description, Title of Publication.

No precise well location, water quality, vessel manufacture, aquifer yield,
worker productivity, or domestic consumption rate is admitted from these sources.
The six-unit task, time cost, bucket appearance, cistern position, two trips and
speed limit are **authored gameplay**. No archival images or source prose is shipped.
See `data/history/gujranwala_water_research.v1.json` for machine-readable scope.

## State, operations and verification

`water_round_rules.gd` is a pure reducer. `gujranwala_state.gd` remains the single
world writer and retains one `childhood.tick`. The optional `water_round` property
lives in the existing `world-state.v1` snapshot and the existing Gujranwala save
slot. Older saves do not gain an assignment, completion or resource balance.
Older checkpoints replace the whole later session, including the water task.

The source, carried and stored task units obey:

    remaining + carried + stored = 6

Only the existing tick can finish a draw; a player command cannot submit `filled`.
Completion transfers units once. Deposits transfer, rather than copy, cargo. Replay
checks event order, actor identity, endpoint position, exact draw interval and all
materialized quantities. Pending draws must still be local and unexpired when a
save is admitted. Invalid loads are rejected before the current session is replaced.
These receipts are consistency checks, not authenticated historical measurements
or proof against an attacker who can rewrite an entire coherent save.

128 receipts bound this prototype. Starting a draw reserves room for completion
and deposit. Repeated cancellation can exhaust the task's budget, after which
new draws are refused but existing cargo can still be deposited and other missions
continue. Full campaign compaction/continuation is not implemented.

The view samples state; it has no separate timer, inventory, treasury or save.
The existing narrator stays independent. The carrier cap is applied both to the
avatar target speed and the model's motion-admission bound, whose retained 0.08
metre tolerance is not a security-grade anti-cheat guarantee.

Run all inherited and new native checks with:

    python tools/run_checks.py --godot /path/to/godot

The new suite includes actual input-driven traversal of both water trips starting
from an explicitly labelled completed-inquiry fixture. It also checks drawing
across save/load, pause, cancellation, conservation, forged receipts, no extra
payout, legacy rollback and bounded-resource behavior. Native evidence records the
executed source SHA, model ID, layout digest and final task digest separately.
Render fixtures produce five inspection captures; they are not human playtesting.
