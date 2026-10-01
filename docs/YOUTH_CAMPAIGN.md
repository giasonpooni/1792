# The playable youth campaign

The childhood and adolescent years are a substantial campaign, not a disposable
controls tutorial. All 28 entries below are required **playable story work**.
A journal entry, narrated paragraph or enabled menu label does not complete one.
Each entry records player actions, an observable completion condition, persistent
fallout, dependencies and its actual implementation status.

## First playable increment: the Bhangi Bazaar Brawl

On this branch, use the existing **1792 · Buddh Singh · Home territory** entry.
Finish the childhood lesson and household inquiry. No allowance is required.
Visit the western market, face the trader and press **E**; choose **Walk with
Mela and Jiva**. These two original fictional companions are not household guards.
They follow on foot within 12 local metres and clear physical sight. Around a
wall, or beyond range, they stop; return for them rather than receiving a teleport.

Walk southeast from the stall to the labelled open ground. Bring both friends,
face the challenger and press E. His Bhangi affiliation is authored local speech,
not a historical identification of these fictional participants.

* **Stand:** face a raised blow and hold **Q**; counter its recovery with **left
  click**. Three opponents have staggered attack cycles. One counter puts an
  opponent out of this nonlethal greybox fight. Two checked opponents distinguish
  the standing-your-ground outcome. Friends follow but do not yet fight.
* **Withdraw:** physically leave the fight with both companions. A brawl need not
  end in defeating everyone. Three unguarded blows end the attempt.
* **Walk away:** answer the challenge by leaving together before fighting.

All three routes require actual regrouping at the open home approach, then a
return to the quartermaster with both friends. E gives the oral account once.
The reported outcome and memories persist. There is no fabricated reward,
territorial transfer, universal Bhangi grievance, permanent friend recruitment or
integration with the separate social-field PR. Those are later integration work.

The location is original compressed encounter ground beside the current market,
not a newly surveyed district or proof this happened inside historical Gujranwala.
Current meshes are a greybox, not final child/adult character art or animation.
The current brawl has no blade pickup, lethal finisher, destructible stalls,
arresting watch, crowd panic, companion combat or complete melee system.

## Saves and ownership

F5/F9 use `user://1792-youth-bazaar-v1.json`. J explicitly imports the earlier
household-service slot by replacing the whole world. Before answering the
challenge, a separate `.bazaar-retry.json` snapshot is saved. The failure panel
can restore it; ordinary R still restores the earlier childhood checkpoint.
There is no future-income or future-memory merge. A failed candidate load leaves
the live world unchanged. The snapshot is validated against this code-owned
encounter version; no provider or executable path comes from save data.

The optional `youth_brawl` record uses the same `childhood.tick` and authoritative
home world. Its ordered, bounded receipt history reconstructs phase, damage,
checked attacks, outcome and attributed memories. The controller owns physical
ray tests and collision movement; the model separately enforces ranges, timings,
identities, movement caps and replay consistency. Saved poses are validated for
standing room. These are consistency tests, **not cryptographic authentication
or a proof that every serialized movement occurred**.

An outing cannot begin with an active household service detail, contracted cargo,
caravan or carried/drawing water. During it, new household transactions, mounting,
rest and task assignment are refused. Existing upkeep still uses the common clock.
Ninety-six receipts bound this version; three are reserved from combat for exit
and reporting. Long-campaign save compaction is not implemented.

Godot remains the live authority. No second clock, money store, actor registry,
NET session or C++/Rust/Julia simulation is introduced. Existing water, service,
childhood, reconstruction, narration and political/perception code are retained.
The earlier travelling-guard experiment was parked locally, not silently combined
with this different youth-friend mechanic. Other town/workshop/social-field drafts
remain separate; this branch is based on household-service PR #22.

## Full required slate

`playable_greybox` means the new episode above. `existing_seed` means prior game
mechanics exist but do **not** complete the requested story. `planned` means an
actual playable implementation still has to be built. T displays this inventory
as a paused authoring view; it does not create character knowledge or launch
unbuilt episodes.

| Story | Status | Player activity |
| --- | --- | --- |
| The Bhangi Bazaar Brawl | `playable_greybox` | Walk with two friends into a challenge; guard, counter and get everyone out. |
| The Hunt at Ladewali / Hashmat Khan | `existing_seed` | Track quarry, become separated, survive the mounted ambush and fight back. |
| The Child at Sodhran | `planned` | Keep a camp supplied as Mahan falls ill; scout and command against relief forces. |
| The Throne of Lahore: Pardon | `planned` | Travel incognito, duel Maan Singh, bring him alive to Lahore and reveal identity. |
| Out of the Regents’ Sight | `planned` | Slip out of household supervision and meet companions without a remote alert. |
| The Inherited Ammunition | `planned` | Obtain access to ammunition, practise with friends and account for spent stock. |
| Across the River | `planned` | Read the bank and current, swim or ride a crossing and stay with companions. |
| Taking the Reins | `planned` | Hear conflicting accounts, secure support and assume administration. |
| The Great Boar Hunt | `planned` | Track a boar, manage a frightened horse and evade or meet its charge. |
| A Night in the Nihang Camp | `planned` | Enter a dera without royal ceremony, join its kitchen work, listen and train. |
| Nights in the Bazaar | `planned` | Attend a celebration, choose company, wagers or drinking and interpret talk. |
| Against the Afghan Advance | `planned` | Scout movements, protect villages and disrupt a military supply route. |
| A Pouch for the Playground | `planned` | Choose whom to share personal coins with, play together and reciprocate help. |
| The Falcon in Another Courtyard | `planned` | Follow a missing bird, enter a rival court and confront its keeper. |
| The Unwritten King | `existing_seed` | Evade or attend lessons, hear accounts aloud and reconstruct a discrepancy. |
| The Day Budh Singh Became Ranjit | `planned` | Play the victory-message and father-son naming tradition as a declared variant. |
| Budha Singh and Desi | `planned` | Hear the ancestral horse story, then play its crossing and a later riding challenge. |
| The Fighting at Jhang | `planned` | Reconnoitre approaches, manage ammunition and fight or withdraw in close quarters. |
| The Village Alarm | `planned` | Hear a local alarm, gather companions and intercept a livestock or crop raid. |
| Keys to the Household | `planned` | Investigate a court threat, choose allies and contest access to administration. |
| The King of Thieves: Lethal Variant | `planned` | Use a small retinue as bait and duel the bandit leader on the road. |
| Night Encounter near Kasur | `planned` | Follow a raid through rain and navigate a low-visibility interception. |
| Raj Kaur: Conflicting Accounts | `planned` | Play the requested dark household story through an explicitly chosen telling. |
| The Clash at Ramnagar | `planned` | Read an approaching charge, hold formation or break into the clash. |
| The Battle of the Brick Kilns | `planned` | Locate pinned companions, draw attention and manoeuvre around kiln walls. |
| The Hounds in the Courtyard | `planned` | Respond to an insult, command the hounds and choose when to recall them. |
| The Unrecognized Heir | `planned` | Enter incognito, join a dice dispute, face the watch and navigate detention. |
| The Sialkot Tribute Raid | `planned` | Scout a collection post, muster a finite party and carry captured goods home. |

## Lore and competing accounts

Inclusion and evidence are separate fields. User-supplied AI prose supplies the
creative requirement, not independent historical verification. Unverified lore
is included as authored adaptation; it is not silently promoted to documented
history. This does not require a disclaimer interrupting every gameplay action.
The research view and story framing carry the distinction.

The Maan Singh pardon story and requested lethal variant are separate tellings:
a single persistent actor cannot be both killed and subsequently recruited.
SikhNet's consulted story places the pardoning Maharaja at Lahore; it does not
support the supplied teenage execution. The naming-at-Sodhran tradition is kept
as a requested variant alongside references connecting the name with Mahan's
victory. The stable `ranjit_singh` ID and Buddh/public-name policy are unchanged.

Regency management, murder allegations, intimate relationships, knowledge of
plots and a direct order to kill are separate claims. The dark palace/Raj Kaur
adaptations remain required stories, but their accounts cannot make every other
character omniscient or automatically prove a culprit. The later Jhang/Kasur
campaigns are not silently backdated to validate a supplied teenage night battle.

Sources actually read for this increment:

- [EBSCO, Ranjit Singh](https://www.ebsco.com/research-starters/history/ranjit-singh):
  Early Life and opening Life's Work sections; broad contextual reference, not
  support for each anecdotal detail.
- [SikhNet, The Throne of Lahore](https://sikhnet.com/stories/audio/throne-lahore):
  story text consulted, recording not used. Its particular prose/audio is not
  copied into the game; the pardon/identity-reveal premise is recorded.
- [Sikh Encyclopedia, Ranjit Singh](https://www.thesikhencyclopedia.com/ranjit-singh/):
  early career and later Jhang/Kasur passages, including a different Ramnagar frame.
- [Sikh Philosophy Network, 2011 reproduction](https://www.sikhphilosophy.net/threads/maharaja-ranjit-singh.34168/):
  youth paragraphs including Hashmat, swimming and the practice-round anecdote.
  This is a forum reproduction; its underlying works were not independently read.

The remaining videos/books/links in the supplied AI conversation are research
leads, not works claimed to have been consulted. No primary chronicle has newly
been verified in this pass. No third-party images, modern story recordings,
photographs, source scans or private conversation dumps are shipped.

## Qualification

`python tools/check_youth.py` checks the complete slate, source links, distinct
variants, stable identity and honest executable-entry metadata. The native
`test_youth_brawl.gd` adds pure reducer/refusal fixtures and three actual
input/collision-driven journeys beginning at a labelled completed-inquiry fixture.
Additional fixtures execute failure/retry, stale-dialogue occlusion, rejected spatial loads and the combat-receipt boundary. The renderer uses declared presentation fixtures and one real guard/counter.
The existing `tools/run_checks.py` retains all prior suites and adds these checks.

Run using pinned Godot 4.5.1 Standard. Qualification results are recorded in the
pull request after actual execution. A workflow definition or story catalogue
alone does not establish that runtime tests have passed. Human playtesting,
Windows/controller testing, physical-GPU performance, full combat art and the
other 27 complete story implementations remain outstanding.
