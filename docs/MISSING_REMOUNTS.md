# Missing remounts: investigation in the existing home territory

An **original fictional encounter** after the household inquiry and allowance.
It adds no claim about a recorded historical incident, named culprit or surveyed
Gujranwala building. It remains the same 1792 / Buddh home entry, not a separate
chapter, historical date jump or replacement for the fixed Mahan interlude.

## Play

Open `game/project.godot` in standard Godot 4.5.1. Complete the home tutorial,
ambush and inquiry; accept the quartermaster's limited allowance. Speak again
and choose **Investigate the two missing remounts**.

The yard is beyond the southern/back wall of the home compound. Leave by the
existing open front and go around the outside; the old back wall is not a gate.

- **Introduced route:** visit the western market, ask the handler for an
  introduction, then speak to the gatekeeper at the yard's east entrance.
- **Service route:** enter the western service gap without permission. The screen
  obstructs sight; it does not erase sound or create social access.
- **Overlook:** the low ramp on the north side leads up and down into the yard.
  This uses ordinary character motion, not a new wall-running/parkour controller.

Face the nearby sealed tally and horses, then press **E**. Bring both observations
back to the quartermaster. The tally is **read aloud**: collecting writing does
not grant Buddh literacy. The yard's explanation remains testimony, not proof
of innocence or guilt.

The two tethered horses are located, **not collected or added to inventory**.
There is no invented cash reward, new rideable mount, pursuit combat or arrest.
The existing household horse and financial ledger remain unchanged.

**WASD/mouse** movement/view; **C** existing quiet walk; **E** interaction;
**B** oral accounts; **J** journal; **F5/F9** save/load. The new default slot is
`1792-remounts-v1.json`. J offers an explicit import of an existing
`1792-gujranwala-v1.json` supply save when present: this replaces the whole current
run, never merges its future knowledge or earnings. Original supply slots are
not overwritten. Existing R checkpoints still discard later optional substates.

## What the witnesses know

Two fixed observers have independent local contact records. The gatekeeper is
fictionally familiar with Buddh; the yard keeper is not. Visibility requires a
real scene collision ray, a forward cone and range. Identification additionally
requires familiarity and a shorter range. Sound records a **coarse yard location**,
not precise unseen player coordinates. Hearing, seeing, identifying and access
permission remain separate. Repeating a perception is not another independent
witness. Nearby observed challenges produce audible feedback in the caption.

An introduced, visible person does not trigger a trespass complaint. The first
unpermitted contact queues **one** report in this bounded encounter. A visible
runner must reach the actual witness, wait at least 60 existing ticks from the
contact, collect that witness's then-current account, and physically reach the
duty post at least 120 ticks later. Another observer identifying the player after
collection cannot rewrite that packet. These are authored minimum delays, not
historical travel-time estimates.

Before delivery the post knows nothing. Delivery produces one retained account;
a named complaint changes the yard custodians' grievance/recognition, whereas an
anonymous account does not invent an identity. An introduced visit also retains
access/trust and the handler's introduction obligation. These are separate local
relationship fields, not a global respect meter or a full faction simulation.

One visible, authored **yard reserve** travels to the report's location, searches
for 600 ticks, then physically returns. It neither spawns infinitely nor follows
the current player position. It is separate from the player's hired garrison.
Search is a bounded visit and wait: the responder does not yet fight, arrest,
interrogate, generate fresh reports or run a general tactical-search planner.

Menus freeze the same chapter clock, movement and delivery. Resting a whole supply
watch is refused while a message or response is active. Resolution does not erase
an already queued complaint. Local observations and relationship outcomes persist
across saves; no omniscient report state is added to the player journal/HUD.

## Engineering boundary

`remount_state.gd` extends `gujranwala_state.gd` with one optional `remounts` substate.
`remount_chapter.gd` extends the existing controller. `home_launch.gd` changes only
its selected subclass. The source home PackedScene, original player, historical
roster, schemas, childhood/aftermath authorities, supply rules and Mahan contract
are unchanged. Godot owns live state; no competing Bevy, Python or NET executor
has been embedded. The C++ / Rust / Python / Julia direction remains an extension
boundary, not a prerequisite to this playable increment.

Rules stage a ledger copy before admitting an event. Save validation replays the
ordered, bounded event history and compares every derived contact/report/outcome.
Motion is separately capped, and loading checks actual standing room before
replacing live state. Rejecting a transaction or a load leaves state intact.
Idle agents may settle vertically onto the collision floor, but may not move
horizontally without an order. This is local consistency checking, not authenticated
anti-cheat, independent evidence of historical truth, or a proof that saved motion
actually occurred. JSON pose serialization is checked to 1e-12 in the test that
compares in-memory floating values; discrete knowledge is checked exactly.

There are at most 48 event receipts, two observers, one report and one reserve.
Static obstacle routing reuses the existing flat-world navigator. The gateway
and screen have enough clearance for its existing grid; no navigator fork was
introduced. General 3D navigation, dynamic lighting-based detection, multi-hop
rumour networks, arbitrary observer populations and streamed cities are not here.

## Run and audit

```sh
python tools/run_checks.py --godot /path/to/godot
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_remounts.gd
/path/to/godot --path game --rendering-method gl_compatibility --script res://tests/render_remounts.gd
```

The encounter suite tests domain refusals and real input/collision-driven journeys
through both entry routes, the ramp and physical messenger/search loop. A labelled
completed-inquiry fixture sets each journey's starting point; it is not claimed as
another end-to-end tutorial run. After departure, journey movement is real character
input or existing agent navigation, not pose/progress injection. Separate original
suites retain their childhood/inquiry journey coverage. Render setups are explicitly
presentation fixtures, not evidence of human playtesting.

Tests export `user://remounts-trace.json` as `1792.remounts-trace.v1`: full developer
state, original event sequence and clock. `export_id` identifies an export occurrence,
not execution, source authenticity or verification. It stays `not_verified`, with
no verification ID. This is an offline inspection seam for future NET experiments;
no NET adapter or cross-language numerical comparison is claimed implemented.

The trace contains NPC knowledge and must not be presented as the player journal.
Focused passing checks do not qualify physical-GPU frame budgets, Windows saves,
controller support, accessibility acceptance, historical accuracy or game enjoyment.
