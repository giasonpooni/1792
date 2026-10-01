# Inhabited Home: the household smith's commission

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## What this increment does

This integrates the existing finite workshop recipe from PR #21 into the current
childhood/youth/service/water/art branch. It is **not a new second economy** and
not a merge of the older town/remount implementation. The original source was
`51fae26d48348cb7e82ef5f8ff5b9567bfe37bd4`, `game/workshops/workshop_rules.gd`.
The new adapter extends `brawl_state.gd`; its controller extends `art_chapter.gd`.
The current original Home packed scene is unchanged byte-for-byte.

The workshop is now an original fictional station in the west household courtyard
at local `(-15, 0.14, 8)`. This is **not** the older town branch's smith at `(-46,
0.14, -7)`, a surveyed Gujranwala building, or a documented childhood event. Its
model identity is `home-courtyard-smith.v2`; older workshop records are not silently
relocated into it. All anthology/DLC research remains deferred.

The craftsmanship intake supplies design leads, not historical proof of this
errand. The smith's iron and labour are abstracted into the fee, as in PR #21.
This is not a historically calibrated recipe or a mass-conserving metallurgy
simulation. No mature imperial acquisition, foreign officer, religious figure or
religious interior is added. Sada Kaur and Adina Beg remain non-playable.

## Play the actual task

Run the existing **1792 / Buddh Singh / Home territory** entry in Godot 4.5.1.
Complete the existing household inquiry. Face the quartermaster and press **E**,
then accept the existing limited allowance. Speak again and select the commission.

1. Reserve two timber bundles and four household coins. The personal purse stays
   separate. The fuel/payment is in your custody, visibly carried.
2. Walk to the smith in the west courtyard. Face him and press E; hand over the
   fuel and payment. You now have free hands, while the order remains with him.
3. Work takes 600 active ticks (ten play seconds at the existing 60 Hz clock).
   Conversation, F7 art controls and other modal views pause that same clock.
4. Return to the smith and collect the two tool bundles. Completion alone never
   credits the household store. The HUD does not remotely announce readiness.
5. Physically return to the quartermaster and hand in both bundles. Two tool units
   enter stock and household standing rises by three once. There is no cash reward.

Before handover, cancellation returns unused fuel and the reserved fee. After
handover, they are spent. Full stores refuse return/refund without destroying
cargo. The finite task cannot be repeated for infinite supplies or rewards.

Both fuel and tools cap the existing player motor at 3 metres/second. Mounting,
food/caravan cargo, water handling, the friends' outing and active service
commitments cannot overlap carried workshop cargo. Once handed over, work can
continue while other compatible tasks proceed. Existing upkeep still settles
first when a workshop deadline lands on the same watch.

The new buttons belong to their current paused conversation. Physical distance,
elevation, facing, eye-ray visibility and current body/model agreement are checked
again at execution. A wall appearing after the menu opens can refuse the handover
before funds or custody change. Scene checks are not replicated as a second
physics engine inside the reducer.

## Visible and audible activity

The station uses original procedural meshes and the existing art kit: supported
bench, anvil, hearth, canopy, pottery, a fictional articulated smith, carried fuel
and finished tools. Four local solid props add real collision; no old collider is
removed, scaled or weakened to make a route work. The existing art remains
reversibly selectable with F7, but this functional workplace is not deleted by a
cosmetic comparison toggle.

The hammer pose, cloth, hearth and tool visibility sample the existing chapter
tick and custody state. A short, original synthesized mono PCM strike plays on
contiguous work ticks at the anvil through an AudioStreamPlayer3D. Pauses stop the
cue; save rewinds and fast-forwarded rest do not emit a burst of missed strikes.
This is a prototype cue, not recorded historical sound, production character
animation, lip sync, a new population simulation or an independent workshop AI.

The active task has a shorter contextual HUD; B and J retain full accounts and
journal access. F2 research, F3 atlas, F4 perception, F7 visual study, T youth slate
and inherited controls remain available. Lighting changes do not alter history.

## Persistence and shared replay

F5/F9 use `user://1792-home-workshop-v2.json`. The journal offers explicit import
of an existing prior youth/visual save, replacing the whole run. Older chapter
import actions still use the current staged loader. A file selected as a prior
save is not merged into later resources or memories.

Workshop custody is the optional `misl.ledger.workshop` field, replayed from the
existing `misl.events` receipt stream. Code-owned reducer extension points make the
old economy extensible without changing its default behaviour. Household-service
prefix replay receives the same code-owned reducer. No function, module, provider
or executable is selected from save-file data.

Load validates the full domain and saved standing space before live promotion.
The bazaar retry uses the same workshop-aware model and restores the entire earlier
world, including pending work; future workshop completion cannot survive a rewind.
The existing bounded 256-receipt ledger remains. Admission reserves room for six
workshop operations, but unrelated later receipts can still exhaust that budget.
No output or completion is fabricated when the ledger is exhausted.

These are compatibility, receipt-consistency and current-world collision checks,
not signatures, anti-cheat proof, proof that a hand-edited file was physically
played, complete historical cross-system trajectory authentication, or qualified
Windows atomic-save semantics. There is no new treasury or second live world.

## Run and inspect the actual engine

```sh
python tools/check_home_workshop.py
python tools/run_checks.py --godot /path/to/godot
python tools/capture_home_art.py --profile workshop --godot /path/to/godot --output /existing-parent/new-run
```

Use `--xvfb` on Linux for a private software-rendering display when needed. The
existing `--profile home` default still produces its original eight comparisons.
The workshop profile reuses that capture runner, creates a **new** directory only,
runs the input-driven journey and then draws five native views. There is no NET
adapter claimed by this command-line extension.

The journey uses one explicitly declared completed-inquiry starting fixture.
Subsequent travel uses player input, Godot collision and actual menu-button signals.
It exercises fuel, working and tool custody, pauses and save/reload. Separate
fixtures check malformed records, duplicate/refunded fees, insufficient stock,
full stores, deadline/upkeep ordering, shared service/water replay, late obstacles,
blocked saves and multi-system bazaar rollback. These are not all separate played
storylines, and test counts do not measure art quality.

The renderer restores snapshots from that executed journey, checks their source
content binding and current geometry, and records snapshot/operation identity,
source hash, image hashes, dimensions, render device and draw/primitive counters.
Working daylight/golden views use an inspection camera. The carried-tools view
uses the existing player camera and the recorded look direction. The compact
smith view and settled account view use the normal interface. These are not
human playtests or a physical-GPU frame-rate benchmark.

## Preserved scope and remaining work

The full-map atlas and all 252 **missing** acquisition cells remain. Home is still
a compressed authored 56 x 56 metre prototype, not a 1:1 regional reconstruction.
No terrain provider, surveyed footprint, final Blender character/horse asset,
new historical finding or completed childhood-to-Lahore campaign is claimed.

The original workshop branch, funded-service branch, NET attachments and other
parallel work remain independent; this selective integration does not claim their
combined acceptance. Finish the active Ranjit narrative before historical DLC.
