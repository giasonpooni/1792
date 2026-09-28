# After the ambush: protection and independence

## What is playable

Use the same **1792 · Buddh Singh · Home territory** entry. Survive the existing
return-path encounter. Back in the yard, hear the courier and steward again, then
approach Raj Kaur at the rear of the courtyard, face her and press **E**.

Both return conversations are attributed testimony. Raj Kaur offers household
protection: take a guard when returning to the bend, or insist on an independent
inquiry. The six antagonist identities and their earlier codex entries remain
unchanged; her new dialogue is original authored characterization, not a recovered
historical quotation or a factual claim that she ordered the attack.

| Choice | Actual mechanical consequence |
| --- | --- |
| Accept the household guard | One fictional dismounted escort is deployed. He must be within six metres of the bend for inspection, and within seven metres of Raj Kaur before the inquiry can close. The household disposition is `Guarded cooperation`. |
| Insist on going alone | No guard is deployed; Buddh can inspect and report by himself. The household disposition is `Strained independence`. |

**G** switches a deployed guard between follow and hold when within ten metres
and clear line of sight. This is a bounded proximity/visibility check, not acoustic
propagation. The guard reuses `patrol_agent.gd` and `patrol_navigator.gd` unchanged.
He follows physically around the home scene's static obstacles. No teleport
catch-up, mounted escort, combat assistance or autonomous intrigue is implemented.
A player can ride, but must dismount for dialogue and inspection and wait for the
guard if they agreed to bring him. Leaving the guard behind does not lock player
movement; it prevents completing the agreed inspection/check-in without him.

Return to the bend, face the disturbed ground and examine it with **E**. The
character-eye visibility query, not the orbit camera, gates this observation.
Then return to Raj Kaur and choose **Give the observed account aloud**. A clue is
recorded, but no identity for the rider, assailant or commissioner is revealed.
Repeated conversations, inspection and check-in cannot duplicate progress.
The small inquiry ends there; no new region, reward treasury or Lahore transition
is created. The disposition is a local, persisted household result, not a
population-wide opinion, loyalty simulation, or religious alignment.

## Checkpoint recovery

The scene captures detached snapshots at two safe points:

1. After the actual quarry observation interaction, before approaching the bend.
2. On escaping to the courtyard on foot. A mounted arrival can capture this
   checkpoint when dismounting near home before starting aftermath conversations.

Three unguarded blows still end the current attempt. The new recovery panel and
**R** allow restoring the last checkpoint without replaying all lessons. The
latest safe checkpoint replaces the earlier one; this is not a checkpoint browser.
A failure to create or replace the file is reported, not displayed as a save.

F5/F9 use `user://1792-childhood-aftermath-v1.json`. Checkpoints use that same
path plus `.checkpoint.json`, with their own temporary file. The manual save and
previous `1792-childhood-v1.json` slot are never overwritten by checkpoint writes.
The pause menu explicitly imports the previous childhood save. New/imported
legacy snapshots do not invent a protection agreement, escort journey or clue.
The original Lahore save slots and schemas are unchanged.

Restoring a checkpoint replaces the whole retained world state: clock, positions,
lesson progress, damage, memories, agreement and escort. The camera's pitch and
yaw are retained too. Knowledge from a discarded attempt is not merged into an
earlier one. R can also deliberately restore a checkpoint after surviving; the
menu labels that replacement. Visual-framing preference stays a presentation
setting and is not rewound. Pending strike/mount/interaction actions are cleared.

A bounded `1792.chapter-checkpoint.v1` envelope records a supported reason, camera
and scenario snapshot. Before commit, loading validates the envelope, chapter
identity, causal progress and memories, then checks actor, horse, attacker and
guard standing geometry against the current scene. A failed load leaves the live
state intact. The old attacker visual/collider is disabled immediately when an
earlier checkpoint is restored. Temporary-file replacement is not a universal
filesystem transaction; Windows behavior remains unverified. Ordinary Godot JSON
parsing is retained: duplicate-key rejection, signed saves, adversarial security
and cross-platform bitwise replay are not claimed.

## Ownership and scope

`aftermath_state.gd` extends `childhood_state.gd` through a small additive
`aftermath.v1` record inside the existing `_state`. It does not instantiate a
second live childhood model. The model owns progress, memories, the agreement and
guard record; the scene submits bounded motion through its one physics loop.
Temporary candidate models during loading are validators, not parallel simulations.
The original `childhood_state.gd`, player, horse, patrol agent/navigator, home
PackedScene, world schema and both Lahore authorities are unchanged.

The extension retains immutable speaker/channel/text definitions and receipt
ticks. Later reflection and aftermath memories are shown in tick order, with an
explicit same-tick tie order rather than relying on sorting stability. Numerical
save fields normalize after validation; there is no ungrounded source-authenticity
or historical-truth guarantee. The current 60 Hz simulation remains the only clock.

No private scientific library, modern political material, book scans, copyrighted
game assets, external service, second game engine or new historical allegation
is included in this increment. Narrative source notes and the selected biased
Latif account are unchanged.

## Tests

`test_aftermath.gd` adds domain refusals, both input-driven aftermath routes,
actual guard following/holding/regrouping, mid-return save/load, real assailant
strike cycles and checkpoint recovery, tampered memories, and spatially blocked
loads. Aftermath routes start from a clearly labeled survived-tutorial fixture;
there is no pose or progress injection during those routes. The unchanged
childhood suite separately exercises the whole tutorial and first escape.
`aftermath_fixture.gd` is only domain/render setup, not a new runtime provider.

`render_aftermath.gd` supplies five labeled presentation fixtures: the offer,
a smaller-window rendering, escort in the courtyard, remembered accounts, and
the recovery panel. These are not human playtests. Regression saves derive from
an injected test-only path, including their checkpoint sidecar. All older suites
and render jobs remain in the normal runner/CI. Exact observed counts, source
revision and retained evidence are reported in the pull request.
