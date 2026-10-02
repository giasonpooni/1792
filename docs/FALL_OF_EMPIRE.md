# 1792: Fall of Empire

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

**Approved direction: the world built during Ranjit Singh's life continues after
him, through the fall of the Sikh Empire, resistance, the 1857 rebellion and the
postwar settlement. Playable perspectives may serve opposing forces.**

**Current delivery: a deferred DLC contract plus an executable, explicitly
synthetic authoring desk. Not a playable historical campaign.** The base game's
childhood-to-Lahore work and then Ranjit's complete life remain the production
priority. No DLC launcher, entitlement, main-game unlock, active historical actor
or release is created by this foundation.

## Scope and ending

The editorial interval is **1839 through 1859**, represented as half-open years
`[1839, 1860)`. The working final anchor is **8 July 1859**, the formal declaration
of peace recorded by the consulted secondary chronology [S4]. Its cited original
nineteenth-century works and the proclamation itself were **not independently
inspected**. This is a source-limited editorial choice, not a claim that every
region became peaceful on one date.

The Delhi assault/capture in September 1857, the Government of India Act of
2 August 1858, the 1 November proclamation and the later formal-peace anchor are
separate events [S3–S4]. Governing authority passes from the Company to the Crown;
this is not a claim that the Company's corporate existence ended in 1858.

The final chapter is deliberately **after the fighting**, not credits over a
conquered city. Here, “peace and rule restored” means that the chosen local
campaign has ceased active operations, administration has been established and
ordinary routes and provisioning can function again. It does not mean that all
characters approve of the settlement or recover their homes and relatives.

| Chapter | Editorial years | Intended playable work; none is complete |
| --- | --- | --- |
| **The empty throne** | 1839–1844 | Inheritance, access to court, retinue resources, conflicting letters and succession. |
| **Naurangabad and the princes** | 1843–1845 | Refuge, secular couriers and associates, competing accounts; retain the earlier Naurangabad module. |
| **Across the Sutlej** | 1845–1846 | First Anglo-Sikh War, supply, command, survival and the treaty/regency aftermath. |
| **The last army** | 1848–1849 | Multan, the Second Anglo-Sikh War, surrender and annexation. |
| **After annexation** | 1849–1856 | Disarmament, estate changes, surveillance and resistance networks; do not terminate the strand at Maharaj Singh's arrest. |
| **A divided country** | 1857 | Cis-Sutlej and Punjabi military networks, Delhi, opposing soldier/civilian viewpoints and the distinct Gogera/Bar uprising. |
| **Beyond Delhi** | 1858–1859 | Continued campaigns and their reports, separation of local outcomes from wider government transition. |
| **The road reopens** | 1858–1859 | Return journeys, military dispositions, route inspection, market delivery and household accounts. |

These are overlapping **editorial chapter windows**, not exact reigns, lifespans
or continuous fighting dates. [S1–S3] support the broad wars and transition.
Naurangabad, the detailed post-annexation network and Bar operations are explicitly
marked research windows in this increment, not certified reconstructions.

The final chapter depends transitively on all preceding chapters. The data checker
refuses a direct jump from Delhi to the conclusion. The existing six modules
`lahore_succession`, `naurangabad`, `sobraon`, `second_war`, `last_resistance` and
`bar_1857` are referenced, not replaced. The parent anthology retains all 31
entries and the geographic registry retains its 41 shared place identities.
The wider 1873 Singh Sabha epilogue remains separate, not silently deleted or
folded into this DLC's endpoint.

## Ensemble, not a single faction selector

The manifest retains 24 **candidate or context records**, not 24 playable
characters. The earlier Lahore, Naurangabad, Attariwala and Bar casts remain.
For 1857, the candidate/context ledger includes Sarup Singh of Jind, Narinder
Singh of Patiala, Randhir Singh of Kapurthala, Bharpur Singh of Nabha, Wazir Singh
of Faridkot, Shamsher Singh Sandhawalia, Thakur Singh Sandhawalia and Nahar Singh
of Ballabhgarh. Empty source arrays mean an unreconciled production lead, not
independently verified participation. Individual scenes still need their own
identity, date, location and action evidence.

Jind's district history supports Sarup Singh's Karnal march, supply/road work and
Delhi participation [S5]. It does not justify inventing private motives or an
“only ruling prince” superlative. The consulted secondary Shamsher biography
reports 125 horsemen associated with Hodson's Horse [S7]; that is not a verified
muster or evidence that Shamsher personally attended every regimental action.
Its magistracy date is February 1862, outside this DLC.

**Thakur Singh's alleged Ballabhgarh operations remain a research lead.** His
later Singh Sabha and Duleep Singh activity does not establish his operational
role in 1857 [S8]. The Una district account places Bikrama Singh Bedi's armed
hill rising in the 1848–49 sequence [S6]; it is not automatically moved to 1857.
The specific Sampuran Singh claim also needs independent investigation and must
not be silently substituted with a different Bedi figure.

Kinship does not determine allegiance. Family membership, institutional ties,
resources and received information remain distinct. No racial or religious
category produces a loyalty, bravery or combat modifier. Religious figures remain
**unembodied context**, and religious sites remain **exterior-only**. Secular
associates provide action perspectives where already required by the anthology.

The approved gameplay direction is to inhabit actors on opposing sides without
creating duplicate versions of the same battle. Historical macro outcomes and
reliably dated lives constrain historical mode; local routes, receipt of reports,
rescue, loss and personal outcomes provide bounded agency. **Battle simulation,
character mortality constraints and campaign switching are not implemented here.**

## Shared evidence and cross-title continuity

`game/data/fall_of_empire.v1.json` contains 12 event records, eight chapter
contracts, the cast ledger, eight attributed claims, source scope/rights, four
future links and the closing contract. Chapters reference a shared event ID and
existing place IDs. No fictional coordinate, city mesh, regimental roster or
all-India map is admitted by these references. Off-region campaigns remain a
research/dispatch requirement, not already-built terrain.

A claim is not an event admission; a proposed identification is not a person
merge. Blavatsky's claimed India and Mentana experiences remain attributed
material. The Koot Hoomi/Thakur Singh proposal remains a hypothesis. This
increment has **not independently reverified those leads**. Mentana (1867), the
separate 1873 epilogue and later Theosophy/Duleep material remain outside this
DLC. No Blavatsky cameo is silently spawned during 1857.

This is a game-owned, file-backed authoring contract over the existing anthology,
not a new global history service, evidence database, autonomous agent system or
NET runtime dependency. Specialist tools and NET can later invoke its tests;
no such cross-repository integration is claimed in this increment.

## Executable first loop: the settlement desk

Launch the **standalone scene**, not a second world alongside the Home campaign:

```sh
godot --path game res://dlc/fall_of_empire/desk.tscn
```

Or open that scene in the project's pinned **Godot 4.5.1 Standard** and use F6.
The ordinary F5/main menu is unchanged. The desk's four tabs show the chapter
contract, perspective test, explicit authoring timeline/checkpoints and evidence
limits. Its colours, geometry and text are original; no archival art was imported.

There are three unnamed fictional role fixtures: `company_courier`,
`rebel_courier`, and `resident`. The first ID remains stable across the editorial
Company-to-Crown transition; it is not a claim of continued Company government
in 1859. These are test roles, not substitutes for researched historical people.

**A complete desk journey:**

1. As the Company-associated courier, observe the shared road. Keep an in-memory
   checkpoint in the timeline tab. Send the observation to the rebel-associated
   courier. Switch perspectives: the recipient knows nothing until at least
   120 active fixture ticks have elapsed and the report is received.
2. Restore the whole checkpoint. The later report and recipient knowledge both
   disappear. Advance the three authoring anchors in order; they do not reveal
   information in the character notebook or finish the settlement.
3. As the rebel-associated courier, record **dispersed**, **detained**, or
   **left region**. These are authored disposition alternatives, not a command
   for the player to embrace a political allegiance.
4. As the Company-associated courier, inspect/reopen the road and send the new
   observation to the resident. As the resident, record **returned**,
   **displaced**, or **missing** for the household, receive the arrived report
   and complete a market delivery.
5. Back in the authoring timeline, check/close the settlement. All nine
   disposition/household combinations can close, including displacement and
   missing people. Closing freezes the fixture; restore or reset to explore a
   different branch.

This is an **interactive state/knowledge qualification desk**, not walking,
combat, physical couriers, a reconstructed road, a finished mission or an open
world. Its 120 ticks equal two fixture seconds at the existing 60 Hz reference;
they are not a calibrated historical message transit time. Authoring advances
are not character actions. Human players will remember other perspectives;
only the character's in-game notebook is isolated.

## State, replay and protected boundaries

`rules.gd` is a pure staged reducer. The scene alone owns its isolated fixture
tick. No gameplay provider, inherited state reducer, treasury, player movement,
Home clock, main menu or save format is changed. The only disk output is a test
verification record; interactive checkpoints are in memory.

Every accepted receipt carries model-bound operation, execution, shared event,
actor, ordinal and tick identities. Reports preserve the original observation
root, have a delivery deadline and do not become independent corroboration.
The recipient reads a whitelisted detached view, not the hidden world or other
roles' reports. Refused operations never replace the caller's state.

Restoration replays at most 64 receipts, reconstructs world/knowledge/pending
reports and compares the whole snapshot. Unknown identities, modified derived
state, backwards chronology, malformed receipts, source mismatch and fabricated
knowledge refuse. JSON's integral floats are normalized to integers; booleans,
fractional ticks and nonfinite values are not treated as valid ordinals.
Restoring a prior snapshot replaces the complete fixture, including later
knowledge. The content binding covers the manifest and reducer source.

These digests and consistency checks are **not signatures, anti-cheat or proof
that a physical journey happened**. The bounded receipt budget can be exhausted
by unnecessary actions; the desk then refuses further mutation rather than
inventing progress. It does not yet reserve completion slots or page history.

## Verify

```sh
python tools/fall_of_empire.py
python tools/check_fall_of_empire.py
godot --headless --fixed-fps 60 --path game --script res://tests/test_fall_of_empire.gd
python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
```

The new native tests exercise all nine endings, delayed delivery, root identity,
actor isolation, chronological/role/receipt refusals, source binding, JSON
round-trip, whole-state rollback and an actual UI-signal/physics-tick journey.
That journey is not an injected mouse/controller traversal or human playtest.
`render_fall_of_empire.gd` renders the original desk at 1280×720 and 800×450 with
explicit fixtures and viewport bounds checks.

The verification record `user://fall-of-empire-tests.json` distinguishes model,
operation, execution, observations and verifier. Its historical certification and
production-readiness flags stay false. The dedicated read-only GitHub workflow
retains exact source, runtime hash, all inherited checks, new checks and three
software-rendered captures. Check actual run results rather than treating the
workflow definition or this document as a completed CI result.

## Next production admission

After the full Ranjit narrative, the first DLC **physical** slice should be one
shared, sourced road/settlement event that can be traversed from opposing
perspectives using the existing motor, collision, clock and whole-world save.
Qualification must establish access, delivery and switching without private
knowledge leaks, duplicate resources or historical identity conflicts. Final
terrain, historical art, battle AI, performance, controller support and human
playtesting remain separate work. The desk does not bypass those gates.

## Consulted sources and limits

Source IDs in the manifest bind to these references. Only selected public text
was consulted; source-listed books, rosters, trial files and original proclamation
images are not claimed as inspected. No copied prose, photographs, maps, audio,
fonts or other third-party assets are distributed.

- **S1:** [National Army Museum, First Sikh War](https://www.nam.ac.uk/explore/first-sikh-war): broad succession and 1845–46 context.
- **S2:** [National Army Museum, Second Sikh War](https://www.nam.ac.uk/explore/second-sikh-war): campaign and 29 March 1849 annexation context.
- **S3:** [National Army Museum, Decisive events of the Indian Rebellion](https://www.nam.ac.uk/explore/decisive-events-indian-mutiny): Delhi, wider campaigns and aftermath. Its compressed Company-ending language is not adopted as a corporate dissolution date.
- **S4:** [Timeline of the Indian Rebellion of 1857](https://en.wikipedia.org/wiki/Timeline_of_the_Indian_Rebellion_of_1857): selected 1858/1859 closing dates, especially 8 July 1859. A secondary compilation, not the original proclamation; unrelated entries are not admitted wholesale.
- **S5:** [Government of Haryana, Jind district history](https://jind.gov.in/about-district/history/): selected Sarup Singh campaign and settlement passages, not the page's evaluative descriptions of motives.
- **S6:** [Government of Himachal Pradesh, Una district history](https://hpuna.nic.in/history/): selected Bedi resistance chronology; no new 1857 field rebellion inferred.
- **S7:** [Jat Chiefs, Shamsher Singh Sandhawalia](https://jatchiefs.com/sardar-shamsher-singh-sandhawalia-of-raja-sansi/): secondary 125-horse report and later magistracy, not an independently checked muster.
- **S8:** [Encyclopaedia of Sikhism, Thakur Singh Sandhanvalia](https://eos.learnpunjabi.org/THAKUR%20SINGH%20SANDHANVALIA%20%281837-1887%29.html): later biography; not corroboration of the supplied Ballabhgarh operations.

Original game code/content remains under the repository's Cartesian Graphics
rights. Historical facts and public-domain material are not claimed as owned.
