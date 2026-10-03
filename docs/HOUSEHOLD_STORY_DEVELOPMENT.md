# The promises carried Home

This pass develops **HOME-008–012** in *1792: The Lotus Throne*. It continues the
opening and childhood work with five distinct household stories. The register
still contains 33 authored playable sequences: these are deeper versions of
existing arcs, not five additional missions.

The connecting idea is responsibility made visible. Food can be counted, an
escort can fall behind, water has to be carried, a commission has to be paid for,
and an absent guard can speak only when he returns. These small obligations give
the childhood chapter a quieter rhythm after the ambush and inquiry.

## Dramatic development now playable

| Sequence | Setup, turn and payoff | Playable staging and attention |
| --- | --- | --- |
| HOME-008 · Four-food delivery | The quartermaster entrusts four portions to Buddh. At the market, the trader checks whether the promise was kept. The departure tally returns in the acknowledgment. | Four cosmetic parcels follow the actual cargo record and disappear on handover. Brief speaker-specific lines replace generic success text. Travel leaves the objective readable without repeated exposition. |
| HOME-009 · Bring the carrier Home | Agreeing to escort someone becomes a test of pace. Reaching the gate alone is an incomplete arrival; waiting or returning for the carrier completes the practical promise. | Separation and reunion use the actual nine-metre contact rule. Guidance points to the same carrier. At accepted check-in, his same load is put down. The ordinary and disputed routes retain one shared supply receipt. |
| HOME-010 · Water for the household | The first journey teaches handling. On the second, the repeated road changes Buddh's observation: ordinary comfort requires someone to carry the weight. The household vessel fills in two stages. | A short draw cue fits the existing three-second action. Filled-load lines follow live transitions; half/full vessel levels follow actual deposits. Inner observation replaces the planned worker exchange in this increment. |
| HOME-011 · The smith's commission | Two rough heads invite a promise. Fuel and payment make the commitment real. Returning to the bench reveals the pair taking shape; carrying both tools Home closes the order. | Unfinished blanks, one active blank, a finished handled pair and an empty collected bench distinguish work states. Local dialogue changes with the commission. The player can do other things during work. |
| HOME-012 · Household guard service | Two requesters have different immediate needs. Dispatch creates an empty post. The guard's return provides an account of work Buddh did not witness. | A satchel stays on the same service actor. Short departure and received-report lines surround the existing journey. Compact guidance does not distinguish remote outbound, onsite, returning and report-ready states. |

All new dialogue is original dramatic writing. These errands are not presented
as documented childhood episodes. The broader register continues to retain
legends, source disagreements and allegations with attribution; this household
increment neither removes them nor turns them into established history.

## Attention and player control

The compact panel names the immediate responsibility and the next usable action.
Moving or mounting reduces secondary explanation while retaining task and
controls. Drawing or carrying water takes priority over other accepted errands;
an empty, assigned water vessel does not displace food cargo or an active escort.
Carrier recovery and food handover stay ahead of background smith work. Actual
tool custody remains visible before starting another empty-vessel trip. A brawl
continues to use its existing encounter guidance.

Speaker menus bring the current continuation to the top and focus it after
inherited offers have been assembled. Other offers remain available. The brief
matches that continuation instead of leading with a different, unaccepted task.
At Home without the carrier, the player is directed back to the waiting person;
a menu cannot substitute for physical arrival.

The earlier finite caption queue, quiet intervals and journal dialogue recall
remain in use. No camera takes control away to manufacture a composition. There
is no added countdown, extra reward for listening, or requirement to watch the
smith's entire work interval. The intended attention effect is a clearer task,
recognizable change and a short resolution—not a claim of measured retention.

## Play and compare the sequences

Choose Begin, play or skip the opening frame, and complete the childhood lessons
and household inquiry. Speak to the quartermaster to establish household supplies.
These activities can overlap; the following order is useful for reviewing their
individual beats, not a new enforced chapter order.

1. Accept the four-food delivery. Carry the visible parcels to the market trader,
   face him and hand them over. Inspect the account before and after payment.
2. Accept the return-carrier escort at the market. Walk far enough ahead to lose
   contact, then return. Bring the same carrier Home and check in with the
   quartermaster. Notice the difference between your arrival and his arrival.
3. Accept the two-load water round. Draw at the east well, walk the first load
   Home and deposit it. Repeat the journey and compare the second observation
   and the household vessel's level.
4. Reserve the smith's fuel and fee. Before handover, cancellation is available.
   Commit at the smith, leave while he works, then return to speak and collect.
   Bring both tool bundles to the quartermaster.
5. Hear the household-service brief and the market/well requests. Hire and
   provision a guard through the established supply rules. Dispatch him on one
   request, continue ordinary work, then receive his returned account at Home.
   Repeat for the other request and compare their different needs.

E opens local conversations. F mounts or dismounts when allowed. B opens
accounts; J opens the journal and dialogue recall. The current task's controls
remain visible while moving or mounted. Save/load uses the existing chapter save.

## State and information boundaries

Presentation reads existing records; it adds no resource type, clock, collision
body, quest reward or save schema. The carried parcels, water level, tools and
satchel are cosmetic views. Workshop staging is also bound in the compiled smith
workcell; its exact-source capsule was refreshed and build/load/smoke checked.

Economy, water and service answers belong to the dialogue that offered them.
Executing a queued answer checks that the player is still standing near the
speaker, facing an unobstructed interaction point. Replacing or closing a menu
invalidates stale actions. A saved completion cannot repeat its payment or load.

Water fill dialogue requires an actual unpaused clock transition. Loading a
filled vessel does not pretend that a new draw just finished. Escort transitions
also avoid replaying arrival or reunion merely because a snapshot was restored.
Canonical service testimony and journal evidence retain their previous content;
new dialogue does not create a firsthand account of delegated work.

## Verification and remaining work

Targeted Godot 4.5.1 checks cover real physical supply, water, workshop and guard
journeys, plus explicit state fixtures for restoration, overlapping tasks,
blocked/stale answers and presentation. The inherited beginning suite checks the
childhood route and workshop guidance. The normal check runner includes the four new
headless suites. The native CI step runs the two new UI suites under Xvfb and
preserves their captures.

Native views were inspected at 1280×720 and 800×450. The review caught crowded
speaker menus, a mismatched briefing, a market contact point and overlapping
task priorities; those findings drove the corresponding fixes. Controlled
render fixtures and the service satchel inspection camera are not substitutes
for a first-time player's end-to-end run.

Local results (passed/failed): delivery story **71/0**, water story **48/0**,
service story **71/0**, smith staging **38/0**, household attention **290/0**
and menu priority **154/0**. Native presentation assertions are included in the
last two totals. Existing supply **135/0**, water **277/0**, service **121/0**,
workshop **156/0** and beginning **480/0** suites also passed. This is **1,841**
passing targeted checks; the entire repository suite was not rerun. Structural,
ledger, source capsule and profile checks passed separately.

These checks establish
the tested behavior, not finished cinematic quality. Procedural character and
environment art, subtle performance, authored audio, localization and first-time
human comprehension/pacing sessions remain development work. Wider planned
moments in the 33 narrative cards remain plans unless their current-pass record
explicitly lists implementation.
