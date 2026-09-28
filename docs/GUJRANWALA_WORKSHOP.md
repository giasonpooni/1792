# Gujranwala: a workshop with consequences

This extends the existing **1792 · Buddh Singh · Home territory** entry and the
connected town above PR #17. It does not restart the game, replace its protagonist,
merge the separate water/narration/politics drafts, or make NET a runtime dependency.

## Play the commission

Finish the childhood lessons, encounter and household inquiry. Hear the
quartermaster's allowance, then select **Commission two tool bundles**. The
existing household store releases two timber bundles and its coffers reserve
four coins. The personal purse does not pay or receive money from this task.

Walk out through the courtyard front, follow the market lane through the west
town gate, and enter the first courtyard on your left. The fictional smith stands
at local `(-46, 0.14, -7)`. Face him and press E. Hand over the fuel and payment,
close the conversation, and wait or explore. The job finishes after 600 unpaused
chapter ticks, ten play seconds at 60 Hz. Speak again to collect the two tool
bundles, then walk them back to the quartermaster and return them to stock.

You can cancel at home before handover: both timber and reserved money return
atomically. After the smith receives them they are spent, not refundable. A full
store refuses a return or refund without destroying cargo or refunding only half
of a transaction. Existing construction or consumption can free storage space.
Completing the task adds three bounded household-standing points; it creates no
cash reward. Completed or cancelled commissions cannot be farmed repeatedly.

Your carried bundles are visible, cap walking/running to 3 m/s in this prototype,
and prevent mounting. Food-contract and workshop cargo cannot be hand-carried at
the same time. A started order frees your hands: the existing horse becomes usable
again. Upkeep and other active obligations continue while you travel; conversation
and journal panels pause the same world clock. Work also advances during the
existing legal rest-to-next-watch operation; it is an already commissioned external
artisan, not another assignment to the household's worker pool.

## What changes in the world

The existing west courtyard receives an anvil, supported bench, hearth, fictional
smith, hammer pose, finished tool bundles and a state-driven carried-load model.
The smith's hammer and hearth respond to **actual workshop state**. Output stays
on the bench until pickup; it then appears with the player instead. The potter and
cloth worker add clock-driven work poses to two other existing courts. They are
nonblocking presentation actors with no autonomous travel, needs, employment,
production or separate save authority. Their poses pause and reconstruct from
`childhood.tick`; they cannot manufacture economic goods.

The original 86 × 108 metre neighbourhood, buildings, gates, landmarks, horse,
caravan and remount investigation remain. No terrain expansion, streaming, furnished
interiors, recorded voice, combat AI or finished character art is added here.

## One ledger, explicit custody

The new `workshop` dictionary is an optional member of the **existing**
`misl.ledger`. Its receipts live in the existing `misl.events` sequence:

```text
smith.reserve -> smith.start -> smith.ready -> smith.collect -> smith.deliver
              \-> smith.refund  (before start only)
```

Before handover, the player holds exactly the deducted timber/payment. At start,
the timber becomes used fuel and the fee becomes paid. At pickup, the two output
bundles become carried cargo, not household stock. At delivery the cargo becomes
stock exactly once. This is an authored inventory recipe, **not conservation of
physical mass**: the artisan's iron and work are bundled into the price and not
separately simulated. None of these quantities is historically calibrated.

Existing supply purchases, wages, food, fodder, buildings, labour and storage rules
are unchanged. A small trusted-code reducer seam in `gujranwala_state.gd` allows
this subclass to extend the original reducer. `misl_rules.gd` optionally accepts
a code-supplied callback during validation/replay; its default remains unchanged.
No callback, module name or executable is accepted from a save. The old controller
correctly refuses new workshop receipts instead of claiming compatibility.

The original economic validator still checks receipt order, original watch
settlement, capacity, balances and merchant state. The workshop validator replays
the same actions, cross-checks their declared tick against the receipt tick and
requires automatic completion at its due tick. If upkeep and completion coincide,
upkeep precedes completion. Ordinary input cannot request `smith.ready`.

The inherited 256-receipt cap remains. Beginning a task requires six available
slots. Other later transactions can still exhaust the overall bounded scenario;
that condition is not silently repaired by minting output or discarding evidence.
A job may not start when its deadline exceeds the existing chapter-clock limit.

## Knowledge and persistence

A remote completion does not add an NPC report or global 'tools ready' message.
The HUD/accounts continue to say the order was left with the smith. The actual
working/ready state is visible on returning to his court. Spoken handover, pickup
and home receipts join the existing journal with explicit speaker IDs. This does
not grant Buddh literacy or identify anyone involved in earlier events.

F5/F9 use `user://1792-gujranwala-workshop-v1.json`. M can import the previous
`1792-gujranwala-town-v1.json` slot without overwriting it. The inherited imports
remain. Loads stage domain validation and standing-space checks before replacing
the live state. A pending job preserves its original start tick; loading is not a
new commission. An earlier whole-world snapshot removes later job progress,
resource effects, knowledge and town access together. Original checkpoint bytes
and schemas are not changed.

These are consistency checks, not signed-save authentication or independently
attested proof of movement. The inherited JSON loader's broader limitations remain.

## Research and rights boundary

The existing town source ledger and reconstruction method still apply. This
increment adds **authored fictional connective content and gameplay abstraction**:
smith, commission, work poses, clothing, props, exact placements, tool shapes,
recipe, costs and duration. It introduces no new historical findings or claims of
having researched a documented Gujranwala smith or an actual childhood errand.
No archival photographs, commercial assets, voice imitation or private code is
imported. Original Cartesian Graphics rights and separate licensing drafts are
unchanged. Research notes must not be treated as character knowledge.

## Validation commands and limits

```sh
python tools/run_checks.py --godot /absolute/path/to/Godot

LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a /absolute/path/to/Godot \
  --path game --rendering-method gl_compatibility --audio-driver Dummy \
  --script res://tests/render_workshop.gd
```

The added suite checks a full input/button/collision-driven workshop round trip,
pending and carried-output saves, old-save rollback, duplicate actions, source
funds, capacity refusal, visibility and late obstruction, exclusive cargo, automatic
completion timing, same-tick upkeep, and modified/missing receipts. Travel starts
from an explicitly labelled completed-inquiry fixture; no pose/progress injection
occurs after departure. Isolated domain, obstruction and history-budget fixtures
are separate. The inherited suites still cover the earlier actual gameplay routes.

Seven rendered fixtures cover the court, smith, work, ready bench, carried-player
view, accounts and compact interaction panel. They use declared presentation
setups and are not human playtest evidence. The CI artifact binds source commit,
source tree, runtime digest, logs, the automated journey and rendered views.
Headless/software-rendered checks do not establish physical-GPU performance,
Windows save behavior, controller accessibility or production readiness.
