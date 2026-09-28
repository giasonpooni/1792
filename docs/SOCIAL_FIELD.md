# Local social field v1

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

## Scope

An executable, bounded extension of the existing political-exposure chapter.
The social field is an authored gameplay abstraction, not a calibrated theory
of human behaviour. No new historical claim is introduced. Raj Kaur retains the
Phulkian gameplay alignment; this does not equate kinship with political allegiance.
The two new keepers are fictional characters with authored communication links,
not portraits of a historical profession or community.

Baseline: `5b19fda41a50516bc595c32a5455c07016b90212` (the existing water-round merge).
This increment does not change the integrated home-territory economy or its saves.
It does not revise the inherited vision model or its historical qualifications.

## Play the consequences

Choose **Living politics + one-eye vision (extended home chapter)**. Complete the
existing inquiry, or explicitly import an eligible aftermath save using its journal.
Speak with E to the market keeper at local `(15, 0.14, 1)` and gate keeper at
`(-12, 0.14, -18)`. These are compressed scene coordinates, not a geographical survey.
The northern retainer at `(-18, 0.14, -20)` also has a local conversation.

Visit the Bhangi authored outpost and issue a raid. The world incident resolves
through the existing operation. The market keeper does not know immediately; a
local account arrives after the existing faction report plus another local delay.
Return to hear a guarded greeting. The gate keeper receives a later, attenuated
relay and may remain reserved rather than guarded. Raj Kaur does not inherit
these accounts without a declared report route to her gameplay bloc.

Offer Bhangi reparations through Raj Kaur's existing policy menu. The market
keeper's response can soften after the report arrives. The gate keeper's separate
account is not cleared by that offer. None of these conversations grants money,
credit, soldiers, omniscient journal entries, or new historical facts.

Dialogs pause the existing clock. F5/F9 retain the same political save; restoring
an earlier save discards later knowledge because the same input ledger is replayed.
The new residents are simple noncolliding greybox presentations, not new navigation
or physical-agent authorities. Their greetings change; gate closure, credit refusal,
NPC path changes and economy-linked services are not implemented by this increment.

## One authority and one queue

`political_state.gd` still extends the existing aftermath authority. It owns the
chapter clock and admitted `politics.v1` input ledger. `exposure_rules.gd` still
owns the single derived queue. When an existing report is scheduled, a local
receipt for each eligible observer is placed in that same queue with a later due
time. Delivering it calls the pure social reducer and does not increment faction
grievance again. No independent scheduler, server or world-state store is added.

`social_field_rules.gd` owns only reusable projection mathematics and admission.
It accepts supplied actor/subject IDs, not hard-coded 1792 faction names.
`social_field_profile.gd` owns the authored local links, scene positions and text.
`social_registry.gd` remains the authority for named characters and dated alignment.

The disposable `runtime.social` cache is not persisted as a second truth. An old
political save is replayed to derive the newly available local responses. The save
schema stays unchanged; exact replay qualification is scoped to this code revision
and the source digests in the evidence receipt, not a promise of cross-version
behavioural equivalence with older builds that had no social responses.

## Bounded model

Each received incident contributes to five actor/subject dimensions: trust,
grievance, fear, attention and reciprocal obligation. These are dimensionless game
variables, not probabilities, psychological measurements or Bayesian posteriors.
A report's existing severity is multiplied by authored confidence and a linear
age weight, reaching zero 7,200 ticks after the report's original send time.
Dimensions are clipped to [0,1] after summing contributions. Stance thresholds
select `open`, `reserved`, `guarded` or `reassured` presentation text.

An observer keeps at most 128 incident-root/kind records. An echo of an existing
root does not add another contribution. Higher-confidence evidence replaces that
root's confidence without refreshing its age. Conflicting subject, severity or
send-time under the same root is refused. When capacity is exceeded, the oldest
send-time cohort is evicted and a watermark prevents discarded old reports from
re-entering as new. This is a bounded prototype memory, not lifelong social history.

Actor membership determines eligible routes, not universal faction-wide awareness.
Two actors in the same bloc can receive a report at different times and weights.
Routes are fixed authored links: this version does not yet simulate moving couriers,
interception, dynamic geographical rerouting, forged accusations, or conflicting
accounts of the same incident. It preserves the existing faction/coalition reducer;
local belief is not yet fed back into a new coalition model.

## Observation boundary

`social_debug(observer)` is privileged developer inspection. It includes scores,
stance and event roots. It must not be bound to the ordinary HUD or NPC dialogue.

`local_social_response(observer, perceived)` additionally requires inquiry
completion, being on foot, authority-owned proximity within three local metres,
and a scene-provided observation. The scene computes that observation using its
existing eye model and an actual collision ray. Its returned dictionary is a
whitelist of speaker ID, display name, text and `local_conversation` channel.
It carries no scores, event roots, other actors' memory, hidden perpetrator or queue.
This is an in-process observation contract, not a security boundary against mods
calling privileged game code. Local conversation is not retained as a new journal
entry in v1; it is presentation of the actor's current received response.

## Build and audit

```sh
python tools/check_project.py
python tools/check_reconstruction.py
python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
```

The runner retains every inherited suite and adds `test_social_field.gd`.
The tests cover delayed knowledge, same-bloc differences, disconnected observers,
positive repair, non-global effects, duplicate-root handling, confidence replacement,
nonfinite/refused receipts, bounded memory, expiry, replay, save/restore with pending
receipts, rewind, public observation filtering, the actual scene interaction and
physical occlusion. The unchanged CI runtime is pinned Godot 4.5.1.

`render_social_field.gd` adds three software-rendered fixture captures: open,
guarded after a received raid account, and reassured after received reparations.
Fixtures call admitted operations but use explicit test positions; they do not
establish an end-to-end played journey or historical truth.

Native evidence is retained in `test-results/social-field-observation.json` with
separate model, operation, execution, evidence and verification-policy identities,
source hashes, engine version and `audience: privileged_test_observer`. Test counts
and execution status must be taken from the exact CI run, not inferred from this doc.

## NET and later extraction

NET remains the investigation controller, not the game's scheduler. The retained
native observation is an integration seam for later NET ingestion; this change does
not register a new NET operation or assert an end-to-end NET adapter has been tested.
No code is copied into another game's repository and no new microtool repository is
created. Shared C++/Rust/Python/Julia providers remain optional bounded workloads,
not prerequisites for running this Godot slice.

The next coherent increment is a physically delivered or intercepted local receipt,
followed by a narrow authority-owned service consequence. Those additions should
reuse existing custody, routes, operation admission and persistence instead of
creating a second economy or turning local social scores into universal reputation.
