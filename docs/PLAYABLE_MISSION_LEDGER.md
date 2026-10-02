# Playable mission and sequence ledger

1792 – The One-Eyed King: playable mission and sequence ledger

Snapshot: **2026-10-02**. Main: `cd3a473b6725872d4c03f190cd1b07ae940d72c9`.

**33 authored playable sequences**: 30 on the recorded main revision and 3 on recorded draft branches. These range from short lessons to multi-stage prototype missions; this is not a count of finished campaign missions or one fully integrated build.

| Inventory category | Entries |
| --- | ---: |
| playable sequence | 33 |
| presentation | 1 |
| scenario variant | 1 |
| route variant | 1 |
| micro scene | 3 |
| study | 5 |
| mechanic | 2 |

## Active development

HOME-003, HOME-004, HOME-005, HOME-006, HOME-007 on `feat/childhood-arc-development-v1-20261002`. Riding-to-inquiry development continues the opening-message pass. These changes elaborate existing sequences; the total remains 33. Source guides remain pinned to their inspected revisions.

See [the active playable increment](CHILDHOOD_ARC_DEVELOPMENT.md) and [development cards for every sequence](MISSION_DEVELOPMENT_PLAN.md).

## Counting and maintenance

The JSON file is authoritative; this document is generated. Stable IDs survive renaming and moving scenes. A mission owns its child beats. Alternate approaches, captain/delegated control, chapter wrappers, art passes and integration PRs do not create new missions. The thirteen TALE entries share a scene adapter but each has its own authored objective arc.

Historical confidence and implementation are separate. Legends, allegations and conflicting accounts remain available for cinematic adaptation with their source identity retained. A related short recollection does not mark a larger planned biography mission complete.

This pass inspected repository content and versioned documentation. It did not rerun gameplay suites or certify a release. Branch references below pin the inspected revisions; merge status can change after this snapshot.

Edit `data/production/playable_ledger.json`, then run `python tools/playable_ledger.py --write`. Use `--check` to catch stale generated output, and `--check-source-paths` in a checkout containing the recorded commits to verify references.

## Playable sequence index

| ID | Sequence | Era | Delivery |
| --- | --- | --- | --- |
| HOME-001 | [Learning the yard](#home-001) | 1792 | main |
| HOME-002 | [The sealed message](#home-002) | 1792 | main |
| HOME-003 | [First riding gates](#home-003) | 1792 | main |
| HOME-004 | [Guard and counter](#home-004) | 1792 | main |
| HOME-005 | [Tracks beyond Home](#home-005) | 1792 | main |
| HOME-006 | [The return-path ambush](#home-006) | 1792 | main |
| HOME-007 | [The household inquiry](#home-007) | 1792 | main |
| HOME-008 | [Four-food delivery](#home-008) | 1792 | main |
| HOME-009 | [Bring the carrier Home](#home-009) | 1792 | main |
| HOME-010 | [Water for the household](#home-010) | 1792 | main |
| HOME-011 | [The smith’s commission](#home-011) | 1792 | main |
| HOME-012 | [Sukerchakia household service](#home-012) | 1792 | main |
| HOME-013 | [The Bhangi Bazaar Brawl](#home-013) | 1792 | main |
| HOME-014 | [Maha’s horsecraft lesson](#home-014) | 1792 | main · [source PR #71](https://github.com/giasonpooni/1792/pull/71) |
| HOME-015 | [Missing remounts](#home-015) | 1792 | draft · [source PR #14](https://github.com/giasonpooni/1792/pull/14) |
| HOME-016 | [The borrowed rope](#home-016) | 1792 | draft · [source PR #23](https://github.com/giasonpooni/1792/pull/23) |
| HOME-017 | [A funded instructor](#home-017) | 1792 | draft · [source PR #32](https://github.com/giasonpooni/1792/pull/32) |
| CMD-001 | [Lahore road patrol](#cmd-001) | 1801 fictional fixture | main |
| MAHA-001 | [Mahan’s field camp](#maha-001) | 1790 development fixture; chronology variants retained | main · [source PR #9](https://github.com/giasonpooni/1792/pull/9) |
| PRO-001 | [Sobraon to the oral telling](#pro-001) | 1846 → 1849 → retrospective | main · [source PR #77](https://github.com/giasonpooni/1792/pull/77) |
| TALE-001 | [The Wedding Road](#tale-001) | Late eighteenth century; Nakai marriage negotiations | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-002 | [The Unequal Victory](#tale-002) | 1785; a remembered coalition and its strained aftermath | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-003 | [A Stranger at the Threshold](#tale-003) | 1790; the book's account of revenge after Wazir Singh's death | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-004 | [Desi Remembers the Reins](#tale-004) | Early eighteenth century; ancestral recollection | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-005 | [What Can Be Carried](#tale-005) | Late eighteenth century; Ramgarhia displacement and return traditions | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-006 | [The Water of Bahrwal](#tale-006) | Ancestral legend; Guru Arjun and Hem Raj | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-007 | [The Door to the Young Chief](#tale-007) | 1792; the Sukerchakia household | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-008 | [The Whisper After Midnight](#tale-008) | Late 1790s; the household at night | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-009 | [Two Names in the Dispatch](#tale-009) | 1807; a dispatch from Batala | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-010 | [The Fortress in the Letter](#tale-010) | Late 1808; a diplomatic approach | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-011 | [Behind the Lowered Curtain](#tale-011) | 1820–1821; departure from a watched camp | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-012 | [When the Camp Falls Quiet](#tale-012) | 1792; the camp at Sodhra | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |
| TALE-013 | [Names at the Gate](#tale-013) | Late 1790s; after the Ramnagar conflict | main · [source PR #76](https://github.com/giasonpooni/1792/pull/76) |

## Detailed register

### HOME-001

**Learning the yard** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** Walk, turn and inspect the household yard.
- **Completion / consequences:** Reach the opening lesson prompts.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-002

**The sealed message** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** Receive the courier’s message and take it to the steward for reading aloud.
- **Completion / consequences:** Hear the steward; no literacy granted.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-003

**First riding gates** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** Mount and ride through the numbered gates.
- **Completion / consequences:** Finish the riding course.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-004

**Guard and counter** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** Spar; guard, recover and counter.
- **Completion / consequences:** Complete the trainer’s lesson.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-005

**Tracks beyond Home** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** Inspect three traces and approach the quarry quietly.
- **Completion / consequences:** Complete the tracking lesson; no harvesting loop.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-006

**The return-path ambush** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Follow the preceding childhood prompts.
- **Play:** React to the assailant and escape toward Home.
- **Completion / consequences:** Survive and reach Home; failure retries the encounter.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-007

**The household inquiry** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** HOME-006
- **Play:** Hear accounts, choose escort or independent inquiry, inspect the bend and report.
- **Completion / consequences:** Return the account; neither route establishes the culprit.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/AFTERMATH.md).
- **Child beats:** Hear the household → Choose approach → Inspect the bend → Report

### HOME-008

**Four-food delivery** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Accept the finite contract; carry four food to the market.
- **Completion / consequences:** Deliver the cargo once and receive the existing payout.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-009

**Bring the carrier Home** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Meet and physically escort the return supply carrier.
- **Completion / consequences:** One household check-in; no duplicated cargo or payout.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/PLAYABLE_GUIDE.md).

### HOME-010

**Water for the household** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Make two well trips; draw and carry three units each time.
- **Completion / consequences:** Return six units; drawing and carrying use the existing world clock.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/GUJRANWALA_WATER_ROUND.md).

### HOME-011

**The smith’s commission** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Reserve fuel and fee; hand over, wait, collect tools and carry them Home.
- **Completion / consequences:** Deliver two tools once; cancellation only before handover.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/HOME_WORKSHOP_INTEGRATION.md).

### HOME-012

**Sukerchakia household service** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Hear requests, provision a hired guard, dispatch him and receive his returned account.
- **Completion / consequences:** Complete the finite market and well requests; reports require hearing.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/SUKERCHAKIA_SERVICE.md).

### HOME-013

**The Bhangi Bazaar Brawl** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory.
- **Prerequisites:** Completed inquiry; allowance/resources where required by the linked guide.
- **Play:** Meet Mela and Jiva, walk to the challenge, counter or leave together, regroup and report.
- **Completion / consequences:** Resolve the confrontation and return; withdrawal is a route, not another mission.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/YOUTH_CAMPAIGN.md).

### MEM-001

**Maha’s family story / Charat Singh** — presentation; main.

- **Era:** Family retrospective
- **Launch:** Begin through the Home launcher.
- **Prerequisites:** None
- **Play:** Advance, revisit or skip the ten-page family introduction.
- **Completion / consequences:** Return to the childhood opening.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Attributed family-history adaptation; ten pages are not ten missions.
- **Revision:** `feat/opening-game-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/21f8cf824d6b5dd98b2bb44dfa37948adafd55e7/docs/BEGINNING_SEQUENCE.md).

### HOME-014

**Maha’s horsecraft lesson** — playable sequence; main.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Speak to the stable trainer after the first riding lesson.
- **Prerequisites:** HOME-003
- **Play:** Complete moving standing riding, paired standing riding, then mounted firing, reloading and withdrawal.
- **Completion / consequences:** Receive the three Home capability flags.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/opening-game-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/21f8cf824d6b5dd98b2bb44dfa37948adafd55e7/docs/HORSECRAFT_STUDY.md).
- **Child beats:** Single horse balance → Paired horse balance → Mounted matchlock handling

### HOME-015

**Missing remounts** — playable sequence; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Hear the quartermaster’s brief.
- **Prerequisites:** Inquiry and allowance
- **Play:** Reach the private yard, inspect the sealed tally and two horses, report both.
- **Completion / consequences:** Deliver observations; no horse inventory or cash grant.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/missing-remounts-v1` · [source guide/data](https://github.com/giasonpooni/1792/blob/06fccd1ededdfe203c8135efc4f844aeb78899d9/docs/MISSING_REMOUNTS.md).
- **Child beats:** Permission route / service gap / ramp overlook → Inspect tally and horses → Report

### HOME-016

**The borrowed rope** — playable sequence; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Listen to the quartermaster’s rope story.
- **Prerequisites:** Completed inquiry
- **Play:** Hear variant tellings, inspect the rope, compare, request recollection and retell locally.
- **Completion / consequences:** Listener receives the chosen sourced account; no canonical-truth or cash reward.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Explicitly fictional sakhi-inspired transmission episode.
- **Revision:** `feat/oral-memory-v1` · [source guide/data](https://github.com/giasonpooni/1792/blob/575b95f398059a8d26ca03c57c75a198eb1a8293/docs/ORAL_MEMORY.md).

### HOME-017

**A funded instructor** — playable sequence; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Reserve the instructor commission.
- **Prerequisites:** Inquiry, allowance, sufficient household funds
- **Play:** Earn/reserve funds, meet the agent and candidate, escort Home, sign, provision pupil and fund practice.
- **Completion / consequences:** Complete the funded practice under actual attendance and supply conditions.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/funded-service-v1` · [source guide/data](https://github.com/giasonpooni/1792/blob/ae3dffe2e2182a7692e0d430393c1fc5955f6b06/docs/FUNDED_SERVICE.md).
- **Child beats:** Commission → Introduction → Escort → Signing and wages → Funded practice

### CMD-001

**Lahore road patrol** — playable sequence; main.

- **Era:** 1801 fictional fixture
- **Launch:** Main menu → Lahore · Command story.
- **Prerequisites:** None
- **Play:** Assign riders; play as captain or delegate the same order; inspect village/outpost and organize patrol or withdraw.
- **Completion / consequences:** Delayed report releases the riders; control switching does not create another order.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/COMMAND_STORIES.md).

### CMD-002

**Houses and rivals** — scenario variant; main.

- **Era:** Command sandbox
- **Launch:** Main menu → Houses and rivals.
- **Prerequisites:** None
- **Play:** Play the expanded house-dispute command scenario with riding and companions.
- **Completion / consequences:** Resolve the existing command/report loop.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/HOUSE_CONFLICT.md).
- **Variant of:** CMD-001; excluded from the authored-sequence total.

### ROAD-001

**The disputed crossing** — route variant; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. After first food delivery, select the disputed return route.
- **Prerequisites:** HOME-008
- **Play:** Recognize the keeper’s claim, seek delayed confirmation, or use the field bypass.
- **Completion / consequences:** Escort the same carrier Home; one original check-in.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/shah-caravan-road-v1` · [source guide/data](https://github.com/giasonpooni/1792/blob/b251d6967ec46a95bcee4bbca55737d900b6c66d/docs/DISPUTED_ROAD.md).
- **Variant of:** HOME-009; excluded from the authored-sequence total.

### MAHA-001

**Mahan’s field camp** — playable sequence; main.

- **Era:** 1790 development fixture; chronology variants retained
- **Launch:** Main menu → 1790 / Mahan Singh / Field camp (interlude).
- **Prerequisites:** None
- **Play:** Dispatch scouts, receive reports, consult retainers, march or hold, inspect field markers and issue bounded orders.
- **Completion / consequences:** Acknowledge the fixed endpoint; this prototype is not the completed later father campaign.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/mahan-interlude-v1` · [source guide/data](https://github.com/giasonpooni/1792/blob/8e858c00d4cd457f3a44174229462fd192b8cee0/docs/MAHAN_INTERLUDE.md).
- **Child beats:** Reconnaissance → Orders and march → Settlement/garhi observations → Fixed endpoint

### PRO-001

**Sobraon to the oral telling** — playable sequence; main.

- **Era:** 1846 → 1849 → retrospective
- **Launch:** Begin through the branch’s Home launcher.
- **Prerequisites:** None
- **Play:** Escape the earthworks, optionally carry a wounded soldier, steer river timber and approach the later surrender tableau.
- **Completion / consequences:** Hand off through oral narration to the existing family introduction.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Historical framing with original veteran viewpoint and authored survival actions.
- **Revision:** `feat/sobraon-oral-opening-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/e42ddd552879673b7477dbd4f926e389c1aa8e5b/docs/SOBRAON_ORAL_OPENING.md).
- **Child beats:** Sobraon bank → Sutlej crossing → Rawalpindi surrender → Narrator handoff

### TALE-001

**The Wedding Road** — playable sequence; main.

- **Era:** Late eighteenth century; Nakai marriage negotiations
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects delegation.
- **Prerequisites:** None
- **Play:** Inspect the gifts before the delegation leaves. Receive the delegate and agree how to enter. Escort the delegate across the courtyard to the entrance. Hear the rival messenger before choosing whom to alert. Return to the keeper with your account of the arrival.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** retrospective_family_account; The source connects Bhagwan Singh's alliance through his sister with losses of territory and attempted interference. The errands, witnesses, dialogue and local outcomes are original. The prospective bride Raj Kaur is distinct from Ranjit Singh's mother.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Inspect the gifts before the delegation leaves. → Receive the delegate and agree how to enter. → Escort the delegate across the courtyard to the entrance. → Hear the rival messenger before choosing whom to alert. → Return to the keeper with your account of the arrival.

| Beat | Choices |
| --- | --- |
| delegation_prepare | Show every seal / Keep the letters covered |
| delegation_receive | Lead with kinship / Lead with protection |
| delegation_cross | Credit the whole escort / Name the sponsoring house |
| delegation_intercept | Report the interference / Ask what settlement he wants |
| delegation_account | Name your witnesses / Keep the negotiation discreet |

### TALE-002

**The Unequal Victory** — playable sequence; main.

- **Era:** 1785; a remembered coalition and its strained aftermath
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects alliance.
- **Prerequisites:** None
- **Play:** Hear the captain's grievance before leaving the gathering. Ask the wounded companion how to make the passage. Escort the wounded companion to the crossing marker. Challenge the victory announcement before it is repeated. Decide how the remaining dressings should leave the gathering.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** retrospective_family_account; The book records shifting Nakai, Sukerchakia and other chief relationships, the 1785 coalition after Jai Singh's 1783 seizure, and failed reconciliation. This local escort and honour dispute is invented to make those pressures playable.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Hear the captain's grievance before leaving the gathering. → Ask the wounded companion how to make the passage. → Escort the wounded companion to the crossing marker. → Challenge the victory announcement before it is repeated. → Decide how the remaining dressings should leave the gathering.

| Beat | Choices |
| --- | --- |
| alliance_orders | Promise to seek public credit / Promise the riders a safe passage |
| alliance_collect | Walk together openly / Take the quieter passage |
| alliance_crossing | Ask both contingents for help / Ask your own riders for help |
| alliance_honour | Name the allies and their losses / Seek recognition in private |
| alliance_supplies | Leave dressings at the crossing / Reserve your contingent's share |

### TALE-003

**A Stranger at the Threshold** — playable sequence; main.

- **Era:** 1790; the book's account of revenge after Wazir Singh's death
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects revenge.
- **Prerequisites:** None
- **Play:** Ask the stranger why he has come to the household. Compare the stranger's account with the gate witness. Warn the steward before the household gathering continues. Bring the waiting dependent away from the approach. Escort the dependent into the sheltered passage.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** retrospective_family_account; The book attributes Wazir Singh's murder to Dal Singh, son of Hira Singh of Bahrwal, and says an unnamed devoted servant later killed Dal Singh in his household. The player witnesses warning signs and shelters people; choices do not cancel that recorded death or establish omniscient guilt.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Ask the stranger why he has come to the household. → Compare the stranger's account with the gate witness. → Warn the steward before the household gathering continues. → Bring the waiting dependent away from the approach. → Escort the dependent into the sheltered passage.

| Beat | Choices |
| --- | --- |
| revenge_notice | Ask whose service brought him / Withhold the household's movements |
| revenge_witness | Carry the witness's exact account / Call attention to the danger |
| revenge_warning | Deliver a warning with its limits / Ask permission to move dependents |
| revenge_gather | Explain that you are finding shelter / Keep the instructions calm and brief |
| revenge_shelter | Keep her sheltered and call for aid / Keep her sheltered and send a witness |

### TALE-004

**Desi Remembers the Reins** — playable sequence; main.

- **Era:** Early eighteenth century; ancestral recollection
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects desi.
- **Prerequisites:** None
- **Play:** Approach Desi and take the saddle. Ride Desi to the first route marker. Ride at least twelve metres before reaching the far marker. Reach the watering place and dismount beside Desi. Return to the companion and choose what the story remembers.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** recorded_ancestral_tradition; The book names Budha Singh's piebald mare Desi and credits him with surviving about forty wounds. This short ride, horse responses and dialogue are original. It preserves the larger-than-life ancestor without treating the ride as a documented journey.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Approach Desi and take the saddle. → Ride Desi to the first route marker. → Ride at least twelve metres before reaching the far marker. → Reach the watering place and dismount beside Desi. → Return to the companion and choose what the story remembers.

| Beat | Choices |
| --- | --- |
| desi_mount | Let her settle before mounting / Mount with the familiar signal |
| desi_approach | Keep a measured stride / Give her room to find her stride |
| desi_far_route | Read the ground before returning / Answer the companion across the ground |
| desi_water | Let Desi drink before speaking / Check her tack before the rest |
| desi_remember | Remember the mare beside the rider / Remember the endurance of the pair |

### TALE-005

**What Can Be Carried** — playable sequence; main.

- **Era:** Late eighteenth century; Ramgarhia displacement and return traditions
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects exile.
- **Prerequisites:** None
- **Play:** Hear the elder before seeking shelter for the party. Choose what the salvaged supplies can offer the hosts. Negotiate a night's hospitality with the settlement host. Gather the weary follower for the last walk to shelter. Escort the weary follower to the shelter entrance.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** retrospective_account_with_treasure_tradition; The source contains Ramgarhia humiliation, release with gifts, retaliatory vows, exile and a treasure-in-a-well episode. This relief errand and its choices are original, with the treasure retained as narrated possibility rather than a fabricated documented discovery by the player.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Hear the elder before seeking shelter for the party. → Choose what the salvaged supplies can offer the hosts. → Negotiate a night's hospitality with the settlement host. → Gather the weary follower for the last walk to shelter. → Escort the weary follower to the shelter entrance.

| Beat | Choices |
| --- | --- |
| exile_promise | Promise an account of every person / Carry the household's vow of return |
| exile_supplies | Offer goods for the night's shelter / Keep the goods and offer service |
| exile_host | Ask for shelter with a limited promise / Promise to remember the hospitality |
| exile_companion | Let the treasure tale sustain him / Name the help already within reach |
| exile_arrive | Thank the hosts before speaking of return / Renew the vow with an obligation to the hosts |

### TALE-006

**The Water of Bahrwal** — playable sequence; main.

- **Era:** Ancestral legend; Guru Arjun and Hem Raj
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects well.
- **Prerequisites:** None
- **Play:** Draw the first water from the Bahrwal well. Prepare the household's welcome from the open courtyard. Reach the resting-place marker and hear the charpai episode. Listen at the exterior threshold as the blessing is told. Return to the well and draw its sweetened water.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** recorded_miracle_legend; The book records Hem Raj carrying the sleeping Guru Arjun home on a charpai, brackish water becoming sweet, and a blessing promising a powerful descendant. This adaptation preserves the miracle as the legend tells it. Dialogue and attendant errands are original; no Guru avatar, impersonation or religious-building entry is required.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Draw the first water from the Bahrwal well. → Prepare the household's welcome from the open courtyard. → Reach the resting-place marker and hear the charpai episode. → Listen at the exterior threshold as the blessing is told. → Return to the well and draw its sweetened water.

| Beat | Choices |
| --- | --- |
| well_first_water | Tell the household how the water tastes / Carry the water with care |
| well_hospitality | Prepare a clear approach / Set the water within reach |
| well_charpai | Follow the narrated passage quietly / Attend to Hem Raj's act of service |
| well_blessing | Receive the legend as the household tells it / Remember the blessing through the well |
| well_return | Share the sweet water with the household / Carry the well's story onward |

### TALE-007

**The Door to the Young Chief** — playable sequence; main.

- **Era:** 1792; the Sukerchakia household
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects regency.
- **Prerequisites:** None
- **Play:** Receive Lakhpat Rai's order for the audience list. Hear Dal Singh's objection at the waiting place. Receive Sada Kaur and choose how to announce her arrival. Escort Sada Kaur to the audience entrance. Complete the audience register after the door closes.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** conflicting_regency_accounts_with_original_dramatization; The Memorial records Lakhpat Rai quarrelling with Dal Singh, Maha Singh's maternal uncle, and a temporary reconciliation. Buxi supplies the household power struggle. The user-selected 1792 frame retains the project chronology beside the Memorial's 1790 succession. Sada's participation in this particular access dispute and all dialogue are original adaptations of the supplied political plot. This Dal is the elder regency figure, distinct from Dal son of Hira Singh of Bahrwal, killed in the revenge account.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Receive Lakhpat Rai's order for the audience list. → Hear Dal Singh's objection at the waiting place. → Receive Sada Kaur and choose how to announce her arrival. → Escort Sada Kaur to the audience entrance. → Complete the audience register after the door closes.

| Beat | Choices |
| --- | --- |
| regency_accounts | Give the accounts first place / Reserve time for the petitions |
| regency_kinship | Record his objection beside his name / Propose that both men be heard together |
| regency_sada | Announce her openly before entering / Take her in after a quiet notice |
| regency_threshold | Call both men into the hearing / Keep the scheduled separate hearings |
| regency_record | Record a temporary working agreement / Preserve the objections beside the agreement |

### TALE-008

**The Whisper After Midnight** — playable sequence; main.

- **Era:** Late 1790s; the household at night
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects rumours.
- **Prerequisites:** None
- **Play:** Hear what the waiting messenger intends to repeat. Examine the unsigned account before it leaves the court. Hear the attendant before taking her away from the gathering. Escort the attendant to the sheltered passage. Choose how the night register will carry the accusation.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** conflicting_accusations_with_original_witness_story; Griffin repeats allegations about Raj Kaur, Lakhpat Rai and matricide, then doubts the killing stories. Buxi describes the struggle over authority and cites Sinha's rejection of Smyth's accusation. Neither establishes guilt. This night, its letter, the witnesses and every spoken line are invented. Poison remains an allegation voiced by a character, never an acquired poison item or biological finding. Timing is deliberately broad; no death in 1801 is asserted.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Hear what the waiting messenger intends to repeat. → Examine the unsigned account before it leaves the court. → Hear the attendant before taking her away from the gathering. → Escort the attendant to the sheltered passage. → Choose how the night register will carry the accusation.

| Beat | Choices |
| --- | --- |
| rumours_hear | Ask where his account began / Ask him to wait for the attendant |
| rumours_packet | Mark the accusations as unconfirmed / Keep the sheet intact for the hearing |
| rumours_witness | Promise a private hearing / Promise that others will hear her accurately |
| rumours_cross | Ask that her name stay within the hearing / Record her presence with protection requested |
| rumours_report | Seal it for a private inquiry / Read the allegation and its limits publicly |

### TALE-009

**Two Names in the Dispatch** — playable sequence; main.

- **Era:** 1807; a dispatch from Batala
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects heirs.
- **Prerequisites:** None
- **Play:** Receive the household announcement from Mehtab Kaur's steward. Hear Sada Kaur's instruction before sealing the message. Decide how the dispatch should carry the competing allegation. Gather the escort rider before leaving Batala. Escort the rider to the departure entrance with the dispatch.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** conflicting_birth_and_legitimacy_accounts; Griffin alleges substituted children and later political acknowledgement; the Memorial records the twins' birth announcement, thanksgiving and Mehtab's maternity. Neither the courier nor the choices establish biological truth. All dialogue, dispatch handling and minor witnesses are original. The scene preserves competing accusations without encoding strict male primogeniture or deciding future accession. Its authored 1807 frame follows the selected announcement variant and does not silently reconcile every source chronology.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Receive the household announcement from Mehtab Kaur's steward. → Hear Sada Kaur's instruction before sealing the message. → Decide how the dispatch should carry the competing allegation. → Gather the escort rider before leaving Batala. → Escort the rider to the departure entrance with the dispatch.

| Beat | Choices |
| --- | --- |
| heirs_receive | Put the names before political titles / Preserve the household's full formal address |
| heirs_sada | Ask for an acknowledged delivery / Ask to deliver the words before witnesses |
| heirs_seal | Keep the accusation in a separate marked enclosure / Leave the unsigned allegation with the steward |
| heirs_companion | Permit only the birth announcement / Keep the dispatch private until delivery |
| heirs_depart | Register a household birth announcement / Register confidential household service |

### TALE-010

**The Fortress in the Letter** — playable sequence; main.

- **Era:** Late 1808; a diplomatic approach
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects overture.
- **Prerequisites:** None
- **Play:** Receive Sada Kaur's instruction for the sealed approach. Consult the storekeeper before carrying any practical assurance. Secure the packet and choose its delivery record. Meet the receiving agent and establish the limit of his authority. Escort the agent to the outer entrance and complete the handoff.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** secondary_diplomatic_account_with_original_courier_scene; The university entry records secret negotiations with British officers. Discover Sikhism describes a November 1808 offer of Atalgarh to Metcalfe tied to restoration of possessions. The packet, route, receiving agent and conditions voiced here are invented. This stage ends with an approach delivered, never a completed alliance, an invented interception or a transfer of the fort. Atalgarh here belongs to Sada's diplomatic story, not Dal Singh's Akalgarh identity.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Receive Sada Kaur's instruction for the sealed approach. → Consult the storekeeper before carrying any practical assurance. → Secure the packet and choose its delivery record. → Meet the receiving agent and establish the limit of his authority. → Escort the agent to the outer entrance and complete the handoff.

| Beat | Choices |
| --- | --- |
| overture_instruction | Ask that restoration remain the first condition / Ask for a hearing before practical promises |
| overture_inventory | Include the existing obligations in your oral account / Give no capacity figures without a written request |
| overture_packet | Record the intact seal before handing it over / Ask a household witness to record your departure |
| overture_agent | Require a receipt for delivery alone / Require a named route for the reply |
| overture_handoff | Report that an approach has been delivered / Report the conditions repeated at handoff |

### TALE-011

**Behind the Lowered Curtain** — playable sequence; main.

- **Era:** 1820–1821; departure from a watched camp
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects litter.
- **Prerequisites:** None
- **Play:** Receive Sada Kaur's instruction before the curtain is lowered. Choose what account of the departure to leave with the papers. Confront Vasakha Singh before returning to the bearers. Gather the bearers and begin the short approach to the gate. Escort the covered litter to the outer camp entrance.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** source_attributed_escape_with_original_retainer_viewpoint; Griffin and the university entry preserve a covered-litter escape followed by detention. Discover Sikhism dates its account to 1820 and names Vasakha Singh as the informing retainer and Desa Singh as the pursuer. This 1820–1821 frame retains chronology variants. The player is a fictional additional retainer; dialogue, papers and movement choices are original. Detention is fixed. Local agency determines the treatment of bearers, the wording of a report and how the party reaches its last gate, never a successful alternate escape.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Receive Sada Kaur's instruction before the curtain is lowered. → Choose what account of the departure to leave with the papers. → Confront Vasakha Singh before returning to the bearers. → Gather the bearers and begin the short approach to the gate. → Escort the covered litter to the outer camp entrance.

| Beat | Choices |
| --- | --- |
| litter_order | Promise that the bearers will not be coerced / Promise a discreet departure without a false order |
| litter_papers | Leave the household's request in writing / Record your own responsibility for the preparations |
| litter_retainer | Ask him to distinguish departure from armed defiance / Ask him to name the bearers as hired workers |
| litter_lift | Keep everyone together and stop for a clear challenge / Keep the litter together until the entrance |
| litter_last_gate | Acknowledge the order and demand a recorded return / State a protest and name everyone placed in custody |

### TALE-012

**When the Camp Falls Quiet** — playable sequence; main.

- **Era:** 1792; the camp at Sodhra
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects sodhra.
- **Prerequisites:** None
- **Play:** Receive the father's order before the camp moves. Bring the veteran into the evacuation work. Escort the veteran to the evacuation gate. Prepare what the returning party needs. Give Ranjit his father's message.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** retrospective_history_with_declared_dramatic_handover; This scene selects Griffin's 1792 illness and withdrawal, not the Memorial's 1790 child-victory outcome. The father's private words, delegated tasks, veteran, young runner, evacuation staging and choices are original drama. Authority passes through a small order to care for the camp; this is not evidence for a documented bedside investiture. Maha's death after his return remains fixed. Mana Singh is a research lead, not the identity assigned to the fictional veteran.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Receive the father's order before the camp moves. → Bring the veteran into the evacuation work. → Escort the veteran to the evacuation gate. → Prepare what the returning party needs. → Give Ranjit his father's message.

| Beat | Choices |
| --- | --- |
| sodhra_father | Carry his exact words / Ask who will stand beside his son |
| sodhra_veteran | Admit that you are frightened / Ask how Maha first trusted him |
| sodhra_passage | Count attendants and dependents / Leave a witness at the gate |
| sodhra_supplies | Divide the water between chief and bearers / Request the household's reserved jar |
| sodhra_son | Tell him his father heard him / Ask him to check the camp with the veteran |

### TALE-013

**Names at the Gate** — playable sequence; main.

- **Era:** Late 1790s; after the Ramnagar conflict
- **Launch:** Run res://history/punjab_chiefs_home.tscn; reach story bench; T selects settlement.
- **Prerequisites:** None
- **Play:** Learn what you may promise the waiting family. Hear the representative before entering together. Escort the representative through the reception gate. Ask the clerk to state what provision and service require. Settle one immediate need before the household leaves.
- **Completion / consequences:** Reach a local ending; F5/F9 preserve this story; no Home grants.
- **Implementation:** Playable blockout adaptation; five beats; local branch outcomes.
- **Source treatment:** secondary_reference_with_original_local_negotiation; The entry takes the reported estates and military employment offered to Jan Muhammad's sons as its historical anchor. The unnamed family representative, veteran, clerk, guarantees, supplies, dialogue and local outcomes are original. These people speak for particular households, never every Chattha family. The sequence follows the conflict without replaying its killing; jobs and provision do not erase bereavement. The late-1790s period is separate from the 1792 opening.
- **Revision:** `feat/punjab-chiefs-playable-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/312414b3b47893f7310e53568c689fcfce1d6ba1/game/history/punjab_chiefs_catalogue.json).
- **Child beats:** Learn what you may promise the waiting family. → Hear the representative before entering together. → Escort the representative through the reception gate. → Ask the clerk to state what provision and service require. → Settle one immediate need before the household leaves.

| Beat | Choices |
| --- | --- |
| settlement_charge | Establish who can guarantee passage / Ask what the household needs first |
| settlement_receive | Hear the dependents' needs first / Hear his questions about service first |
| settlement_gate | Call the veteran forward as guarantor / Remain beside the visitor while waiting |
| settlement_terms | Read provision and service separately / Name witnesses who can be found again |
| settlement_provision | Ask for grain to be issued now / Arrange a witnessed return to the household |

### MICRO-001

**Saffron in the fold** — micro scene; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Face the story object and press V.
- **Prerequisites:** Completed inquiry
- **Play:** Turn the cloth and notice its repairs.
- **Completion / consequences:** Finish the optional presentation; no inventory or memory reward.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/bazaar-listening-performance-20260929` · [source guide/data](https://github.com/giasonpooni/1792/blob/acaefc087cb5f6ccb60aa3868bdb907765ed6859/docs/QUIET_OBJECT_STORIES.md).

### MICRO-002

**The hole that was not used** — micro scene; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Face the story object and press V.
- **Prerequisites:** Completed inquiry
- **Play:** Inspect the harness cheekpiece.
- **Completion / consequences:** Finish the optional presentation; no inventory or memory reward.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/bazaar-listening-performance-20260929` · [source guide/data](https://github.com/giasonpooni/1792/blob/acaefc087cb5f6ccb60aa3868bdb907765ed6859/docs/QUIET_OBJECT_STORIES.md).

### MICRO-003

**A pan with two endings** — micro scene; draft.

- **Era:** 1792
- **Launch:** Run game/project.godot; choose Home territory. Face the story object and press V.
- **Prerequisites:** Completed inquiry
- **Play:** Bring Mela and Jiva nearby and hear both fables.
- **Completion / consequences:** Finish the optional presentation; no inventory or memory reward.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/bazaar-listening-performance-20260929` · [source guide/data](https://github.com/giasonpooni/1792/blob/acaefc087cb5f6ccb60aa3868bdb907765ed6859/docs/QUIET_OBJECT_STORIES.md).

### STUDY-001

**Locomotion course** — study; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run res://mechanics/course.tscn.
- **Prerequisites:** None
- **Play:** Exercise movement and traversal fixtures.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/LOCOMOTION_FOUNDATION.md).

### STUDY-002

**Ground-contact course** — study; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run res://mechanics/ground_course.tscn.
- **Prerequisites:** None
- **Play:** Exercise terrain contacts and movement fixtures.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/ground-contact-physics-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/7ab4692886fa7bda97953a948db6ec4bfce50497/docs/GROUND_CONTACT_PHYSICS.md).

### STUDY-003

**Horsecraft study** — study; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run res://mounts/horsecraft_study.tscn.
- **Prerequisites:** None
- **Play:** Practice the horse motor outside campaign skill rewards.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/opening-game-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/21f8cf824d6b5dd98b2bb44dfa37948adafd55e7/docs/HORSECRAFT_STUDY.md).

### STUDY-004

**Service equipment study** — study; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run res://presentation/equipment_study.tscn.
- **Prerequisites:** None
- **Play:** Inspect articulated equipment and poses.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/SERVICE_EQUIPMENT.md).

### STUDY-005

**Political exposure sandbox** — study; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run res://world/political_home.tscn.
- **Prerequisites:** None
- **Play:** Explore local perception and political exposure fixtures.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `main` · [source guide/data](https://github.com/giasonpooni/1792/blob/8ae0e3a45a5137e4e1dcb92318297515f4b35ea9/docs/POLITICAL_EXPOSURE_VISION.md).

### SYSTEM-001

**Hawk scouting** — mechanic; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run game/project.godot; choose Home territory. X releases/recalls the hawk.
- **Prerequisites:** None
- **Play:** Fly, observe and tag bounded visible contacts.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/hawk-scout-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/153ed09fb0d843346402d771afb0053a5e1c3f39/docs/HAWK_SCOUT.md).

### SYSTEM-002

**Ground Focus** — mechanic; main.

- **Era:** Development fixture / Home prototype
- **Launch:** Run game/project.godot; choose Home territory. Z toggles Focus.
- **Prerequisites:** None
- **Play:** Observe nearby sensory evidence and temporary last-seen markers.
- **Completion / consequences:** Exercise the feature; no separate authored mission completion.
- **Implementation:** Implemented prototype on the recorded revision.
- **Source treatment:** Original authored gameplay; historical setting does not authenticate the episode.
- **Revision:** `feat/ground-focus-v1-20261002` · [source guide/data](https://github.com/giasonpooni/1792/blob/79d23545ff8c62ffb782e478497d0bf532767ea2/docs/GROUND_FOCUS.md).

## Planned and contract-only register

The 28-entry youth slate contains one implemented bazaar adaptation and 27 remaining proposals. Some overlap with recollections below; related IDs show that relationship without asserting completion. The later father campaign and Fall of Empire remain contracts. Additional brief groups preserve incoming material without manufacturing a mission count.

| ID | Title | Status | Related playable content | Scope / source |
| --- | --- | --- | --- | --- |
| YOUTH-bhangi_market_brawl | The Bhangi Bazaar Brawl | implemented_adaptation | HOME-013 | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-hashmat_ladewali | The Hunt at Ladewali / Hashmat Khan | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-sodhran_command | The Child at Sodhran | planned | TALE-012 | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-throne_lahore_pardon | The Throne of Lahore: Pardon | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-regency_escape | Out of the Regents’ Sight | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-ammunition_rebellion | The Inherited Ammunition | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-river_races | Across the River | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-end_regency | Taking the Reins | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-boar_hunt | The Great Boar Hunt | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-nihang_camp | A Night in the Nihang Camp | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-bazaar_revelry | Nights in the Bazaar | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-afghan_raiders | Against the Afghan Advance | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-pocket_money_companions | A Pouch for the Playground | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-captured_falcon | The Falcon in Another Courtyard | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-unwritten_king | The Unwritten King | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-sodhran_naming | The Day Budh Singh Became Ranjit | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-ancestral_mare | Budha Singh and Desi | planned | TALE-004 | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-jhang_night_raids | The Fighting at Jhang | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-gujranwala_skirmishes | The Village Alarm | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-palace_purge | Keys to the Household | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-maan_singh_lethal | The King of Thieves: Lethal Variant | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-kasur_night | Night Encounter near Kasur | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-raj_kaur_mystery | Raj Kaur: Conflicting Accounts | planned | TALE-008 | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-ramnagar_cavalry | The Clash at Ramnagar | planned | TALE-013 | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-brick_kilns | The Battle of the Brick Kilns | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-hound_confrontation | The Hounds in the Courtyard | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-bazaar_arrest | The Unrecognized Heir | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| YOUTH-sialkot_tribute | The Sialkot Tribute Raid | planned | — | Related recollections do not complete the proposed larger mission. `game/youth/story_catalogue.json` |
| PLAN-FATHER | Required pre-Lahore Mahan campaign and childhood reprise | contract_only | MAHA-001 | Four sequencing placeholders; no completed 1797–1798 host or playable reprise. `docs/MAHAN_INTERLUDE.md` |
| PLAN-FALL | Fall of Empire campaign | contract_only | PRO-001 | PR34: eight chapter contracts and a synthetic authoring desk; the later prologue does not implement those chapters. `docs/FALL_OF_EMPIRE.md` |
| BRIEF-001 | Punjab ecology and running skirmish encounters | proposed | — | Grassland, river, scrub and wetland scenarios; mounted reload/retreat does not yet constitute a full misl skirmish mission. `User reference intake, this conversation` |
| BRIEF-002 | Maha’s smallpox vigil and childhood training | proposed | — | Retain the supplied family tradition as a dramatic proposal; not an implemented bedside mission. `User reference intake, this conversation` |
| BRIEF-003 | Rasulnagar naming and the three-generation Chattha conflict | proposed | — | Retain competing chronology; settlement recollection is not the complete siege campaign. `User reference intake, this conversation` |
| BRIEF-004 | Dal Singh and Sada Kaur’s secret alignment | proposed | — | Regency recollection is related; a full conspiracy mission remains to be authored. `User reference intake, this conversation` |
| BRIEF-005 | Mathew and the royal caravan | proposed | — | Foreign visitor/backchannel scenario proposed in the supplied brief. `User reference intake, this conversation` |
| BRIEF-006 | Lahore informants and the 1799 entry | proposed | — | Intelligence, gate approach and political settlement need a complete authored mission. `User reference intake, this conversation` |
| BRIEF-007 | Palace correspondence and competing intelligence networks | proposed | — | Household reports, interception and private motives remain attributed proposals. `User reference intake, this conversation` |
| BRIEF-008 | Cis-Sutlej estates and diplomatic protection | proposed | — | Wadni/Himatpur petitions and boundary politics remain proposed. `User reference intake, this conversation` |
| BRIEF-009 | Rival misls, hill states and regional diplomacy | proposed | — | Faction descriptions are worldbuilding, not one completed mission per state. `User reference intake, this conversation` |
| BRIEF-010 | Sindh, Shikarpur and the Mazari campaign | proposed | — | Later-life southern campaign material remains proposed. `User reference intake, this conversation` |

## Draft branch coverage and duplicate control

Every open PR in the inspected 36-head snapshot is registered here. Content inherited by a branch is not counted again. The earlier west-gate smith and the current household smith are deliveries of the same commission; art and producer branches are not additional errands. PR #74 is another hawk implementation. PR #78 combines work and adds no mission merely by integration. Generic building, hiring, purchases, upkeep and witness/perception systems are activities supporting these sequences, not separately authored missions.

| PR | Work | Inventory role | Direct entries | Pinned revision |
| --- | --- | --- | --- | --- |
| [#78](https://github.com/giasonpooni/1792/pull/78) | Integrate ready 1792 stories, physics, scouting and production work | integration_container | — | `62b322c51726a7b60b662a64135d70819bc6a1e4` |
| [#77](https://github.com/giasonpooni/1792/pull/77) | Add playable Sobraon opening and oral handoff into childhood | content_or_mechanic_source | PRO-001 | `e42ddd552879673b7477dbd4f926e389c1aa8e5b` |
| [#76](https://github.com/giasonpooni/1792/pull/76) | Add 13 playable family, court and frontier recollections | content_or_mechanic_source | TALE-001, TALE-002, TALE-003, TALE-004, TALE-005, TALE-006, TALE-007, TALE-008, TALE-009, TALE-010, TALE-011, TALE-012, TALE-013 | `312414b3b47893f7310e53568c689fcfce1d6ba1` |
| [#75](https://github.com/giasonpooni/1792/pull/75) | Add ground Focus observations and correct hawk sensor geometry | content_or_mechanic_source | SYSTEM-002 | `79d23545ff8c62ffb782e478497d0bf532767ea2` |
| [#74](https://github.com/giasonpooni/1792/pull/74) | Add bounded third-person hawk reconnaissance | alternative_delivery_of_SYSTEM-001 | — | `eb8bce6867f8e16be075493388db8fd7e23eb658` |
| [#73](https://github.com/giasonpooni/1792/pull/73) | Add bounded third-person hawk scouting and last-seen tagging | content_or_mechanic_source | SYSTEM-001 | `153ed09fb0d843346402d771afb0053a5e1c3f39` |
| [#72](https://github.com/giasonpooni/1792/pull/72) | Stage shields, scabbard suspension and carry belts in the Gujranwala arms niche | enhancement_or_infrastructure | — | `a54d96f9b4c6d587dd0a11c1c6314a9608cf5fdf` |
| [#71](https://github.com/giasonpooni/1792/pull/71) | Build family introduction and complete playable childhood beginning | content_or_mechanic_source | MEM-001, HOME-014, STUDY-003 | `21f8cf824d6b5dd98b2bb44dfa37948adafd55e7` |
| [#68](https://github.com/giasonpooni/1792/pull/68) | Add bounded ground contact physics and playable stairs/slopes course | content_or_mechanic_source | STUDY-002 | `7ab4692886fa7bda97953a948db6ec4bfce50497` |
| [#67](https://github.com/giasonpooni/1792/pull/67) | Connect Home passage, witnessed conduct and received memory | enhancement_or_infrastructure | — | `116cbc4125d2b56e556b0f7d2a3e0082fe9cd2cc` |
| [#66](https://github.com/giasonpooni/1792/pull/66) | Enrich Gujranwala at eye level: trim, timber reveals, repair fields and quiet storage | enhancement_or_infrastructure | — | `d6d1739b68d77cd6fb7fa1d74db22545fd630b75` |
| [#63](https://github.com/giasonpooni/1792/pull/63) | Deepen Gujranwala beauty: painted veranda, jali rhythm, planting and threshold light | enhancement_or_infrastructure | — | `f23d0e507d73d4acff98b1848fc635ce80770470` |
| [#59](https://github.com/giasonpooni/1792/pull/59) | Add Gujranwala Slice 0.1 with durable visits | launcher_or_preservation_wrapper | — | `988c89412e5dc8b39b4f9a31c5e07e82efa463bf` |
| [#58](https://github.com/giasonpooni/1792/pull/58) | Capture playable childhood slice for Foundry and derive received-memory perspective | launcher_or_preservation_wrapper | — | `bacf327b9d71a35833c7776a248a70bf15449d48` |
| [#53](https://github.com/giasonpooni/1792/pull/53) | Small things worth stopping for: playable object stories and restrained character performance | content_or_mechanic_source | MICRO-001, MICRO-002, MICRO-003 | `acaefc087cb5f6ccb60aa3868bdb907765ed6859` |
| [#51](https://github.com/giasonpooni/1792/pull/51) | Break follower symmetry: Mela eager outward, Jiva leading the withdrawal | enhancement_or_infrastructure | — | `6ca351b4b734aaa9ef652cedca11545699b125d2` |
| [#50](https://github.com/giasonpooni/1792/pull/50) | Add facial micro-performance to bazaar supporting figures | enhancement_or_infrastructure | — | `269a63f350c167ea284dfa3d0376911635c2d895` |
| [#49](https://github.com/giasonpooni/1792/pull/49) | Direct bazaar eye-line and attention without inventing perception state | enhancement_or_infrastructure | — | `be3fdfda9d47eef1fb9c5d1891d4a0e3f332e42a` |
| [#41](https://github.com/giasonpooni/1792/pull/41) | experiment: one live coding/vision agent revises the smith through unchanged workcell gates | enhancement_or_infrastructure | — | `2e1e66af5bf3fc913224a245a31478463b7b9d93` |
| [#39](https://github.com/giasonpooni/1792/pull/39) | feat: title-owned smith workcell with baked art, native probes and source capsule | enhancement_or_infrastructure | — | `5039f8b290cf9a39198ebb9a37709202b00e914f` |
| [#38](https://github.com/giasonpooni/1792/pull/38) | Integrate accepted Foundry bench into playable workshop and qualify movement, pickup and saves | enhancement_or_infrastructure | — | `4869eac467288b99c32268df99d4a06e573fb28d` |
| [#35](https://github.com/giasonpooni/1792/pull/35) | docs: situated-history style, perspective tooling and production priorities | enhancement_or_infrastructure | — | `dbf22a0014947eb254ead13de77efc15b4354c90` |
| [#34](https://github.com/giasonpooni/1792/pull/34) | Fall of Empire: 1839–1859 DLC contract and opposing-perspective settlement desk | planned_campaign_contract | — | `0dc67dd1ee77cdf0e758f8f45e645b5d2f097bf3` |
| [#32](https://github.com/giasonpooni/1792/pull/32) | Build funded recruitment, physical candidate escort and limited officer viewpoint; retain traversal contact | content_or_mechanic_source | HOME-017 | `ae3dffe2e2182a7692e0d430393c1fc5955f6b06` |
| [#30](https://github.com/giasonpooni/1792/pull/30) | feat: game-owned water-round operation for NET Foundry | enhancement_or_infrastructure | — | `fee822a3e0bde3b48dc6e196e5e43c20393816fa` |
| [#29](https://github.com/giasonpooni/1792/pull/29) | feat: game-owned water-round workload for NET industrial production | enhancement_or_infrastructure | — | `70fcc477fb3783847fea56fa0ccaa5868413226f` |
| [#28](https://github.com/giasonpooni/1792/pull/28) | docs: position 1792 under proposed Cartesian private layer and Notation Systems commons | enhancement_or_infrastructure | — | `f5f15f1a3e07104dee51ee64a61d390e957e0a81` |
| [#24](https://github.com/giasonpooni/1792/pull/24) | PC platform foundation: native Steam runtime qualification and verified Windows builds | enhancement_or_infrastructure | — | `53da0f4b0b91fcb2a9dffbae356306a8fbcd28b3` |
| [#23](https://github.com/giasonpooni/1792/pull/23) | Playable oral memory: situated listening, differing accounts and attributed retelling | content_or_mechanic_source | HOME-016 | `575b95f398059a8d26ca03c57c75a198eb1a8293` |
| [#21](https://github.com/giasonpooni/1792/pull/21) | Build a playable Gujranwala workshop commission and visible town crafts | older_delivery_of_HOME-011 | — | `51fae26d48348cb7e82ef5f8ff5b9567bfe37bd4` |
| [#20](https://github.com/giasonpooni/1792/pull/20) | Local social field v1: delayed actor beliefs and situated dialogue | enhancement_or_infrastructure | — | `de63cfb5ca522e3e3cbbe31d9f78a3e9b549a2ae` |
| [#19](https://github.com/giasonpooni/1792/pull/19) | Connect Gujranwala's store and bazaar: carried provisions, reserve choices and household trade | enhancement_or_infrastructure | — | `6ac5a4b159692b8f8835496efc9a1551cad4eb3a` |
| [#17](https://github.com/giasonpooni/1792/pull/17) | Build connected Gujranwala neighbourhood: courtyards, bazaar, exploration and persistent town travel | enhancement_or_infrastructure | — | `6e8f27715a0ae5de78d42b0696c620d66b0fd4cb` |
| [#16](https://github.com/giasonpooni/1792/pull/16) | Build researched Gujranwala setting, Shah Muhammad narration and disputed-road caravan | content_or_mechanic_source | ROAD-001 | `b251d6967ec46a95bcee4bbca55737d900b6c66d` |
| [#14](https://github.com/giasonpooni/1792/pull/14) | Build Gujranwala: remount investigation and research-informed architecture | content_or_mechanic_source | HOME-015 | `06fccd1ededdfe203c8135efc4f844aeb78899d9` |
| [#9](https://github.com/giasonpooni/1792/pull/9) | Mahan Singh interlude: …→history→encounter→settlement→garhi + Gujranwala geography (draft) | content_or_mechanic_source | MAHA-001 | `8e858c00d4cd457f3a44174229462fd192b8cee0` |
