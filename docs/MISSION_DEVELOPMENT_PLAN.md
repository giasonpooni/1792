# Mission and sequence development

This is the working development plan for **1792: The Lotus Throne**. It turns the [playable ledger](PLAYABLE_MISSION_LEDGER.md) into **33 individual development cards**, plus a secondary queue and the remaining story backlog. The structured source is [mission_development.json](../data/production/mission_development.json).

**Current increment:** HOME-017 is in development: A Funded Instructor. [This pass](INSTRUCTOR_STORY_DEVELOPMENT.md) composes the retained commission into current Home and develops consent, shared travel, signing and interrupted practice around the promise of a place kept ready. Earlier [rope and remounts](ROPE_AND_REMOUNT_STORY.md), [friends and horsecraft](FRIENDS_AND_HORSECRAFT_STORY.md), [household](HOUSEHOLD_STORY_DEVELOPMENT.md), [childhood arc](CHILDHOOD_ARC_DEVELOPMENT.md) and opening work remain included. Current-pass guides state the implemented subset of the wider card direction.

The first prototype pass is now implemented and locally verified: orientation lead-in, both optional message routes, physical reporting, remembered receipts and save/load. See [The Words Between Us](MESSAGE_FOLLOWUP.md) for the actual playable scope. The P0 cards remain in development for performance and visual polish; their cinematic ideas are not claims of completed animation.

The ledger records prototypes on different revisions and branches. These cards do not imply those branches are all integrated. Baseline source details remain in the ledger and in each JSON card; use those to locate the existing implementation before beginning its next pass.

## Working rules

- Develop each sequence around a specific player action, human tension and visible local consequence.
- Preserve myths, miracles, rival accounts and invented drama. Keep attribution in the production record; do not make a disputed allegation true merely by storing it as a game fact.
- Keep fixed historical endpoints explicit. Give the player meaningful choices about care, communication, route and immediate treatment where changing the larger outcome would break the chosen frame.
- Build cinematic moments through movement, framing, sound, performance and staging. A cutscene, finished animation or voice recording is not implied by a card.
- Keep finite resources, physical escorts and heard reports connected to their existing authorities. An alternate path is part of its original arc, not another reward or mission.
- A development card is not a completion receipt. Prove its acceptance criterion, record the implemented revision, and update the ledger only when the actual playable scope changes.

## Development order

| Phase | Focus | Sequence cards | Current state |
| --- | --- | ---: | --- |
| P0 | Opening decisions | 2 | In development |
| P1 | Complete the childhood dramatic arc | 5 | In development |
| P2 | Make Gujranwala relationships playable | 10 | HOME-008–017 in development in the current Home chain |
| P3 | Individualize the historical recollections | 13 | Planned |
| P4 | Connect command and the retrospective frame | 3 | Planned |

These priorities group development work; they do not reorder historical events or force the player to play every recollection in sequence. Draft-branch integration is a prerequisite for using a card inside a continuous campaign.

## Remaining childhood branch integration

**Borrowed Rope**, **Missing Remounts** and **Funded Instructor** now extend the current Home chain. Their guides record integration, targeted qualification and remaining production work. The instructor's escrow, upkeep and receipts compose with workshop reduction; the limited teaching view and interrupted practice use the existing world and clock. Later recollection and command prototypes remain separate integration work.

## Sequence cards

### HOME-001 · Learning the yard

**P0 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can a child find his own bearings in a household already full of adult purposes?
- **Playable objective:** Walk the yard, turn deliberately toward its landmarks, and find the courier without losing control of movement.
- **Encounter or choice:** Choose the first landmark to inspect; the lead-in makes the message a discoverable interruption rather than another unrelated instruction.
- **Local consequence:** The next objective names the courier and where to find him; exploration creates no hidden literacy or political knowledge.
- **Cinematic moment:** Hooves, work and voices establish ordinary household life before a waiting courier cuts across it.
- **Next implementation task:** Improve the orientation lead-in, landmark staging and objective text that hands the player into HOME-002.
- **Acceptance criterion:** A fresh start explains walk and look, completion leads visibly to the courier, and pausing or repeating an interaction cannot skip the message lesson.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-002 · The sealed message

**P0 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** What does a future ruler do when the words of an order and the account of its bearer leave uncertainty?
- **Playable objective:** Receive the sealed message, hear courier and steward, and decide how to take the uncertain account to the trainer.
- **Encounter or choice:** After both initial accounts, ask the steward to proceed directly to the trainer or first return to the courier for clarification; existing training stays available.
- **Local consequence:** The journal keeps the selected approach, any clarification actually heard, and the trainer’s receipt; neither path discovers a hidden culprit or grants a risk modifier.
- **Cinematic moment:** The seal remains visible in the child’s hand while an older voice supplies its meaning; the reply is the child’s first deliberate public decision.
- **Next implementation task:** Add the optional post-reading conversation, clarification interaction, trainer acknowledgment, remembered receipt and matching objective cues.
- **Acceptance criterion:** Both approaches can reach their trainer acknowledgment, clarification is credited only after hearing it, repeat interactions do not duplicate receipts, and normal riding progression remains available.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-003 · First riding gates

**P1 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can the child turn confidence into control when the horse has momentum of its own?
- **Playable objective:** Mount, pass the three gates in order, brake, and dismount on clear ground.
- **Encounter or choice:** A trainer calls for a controlled approach to the last gate; the player can slow early or recover after overshooting.
- **Local consequence:** Feedback distinguishes missing a gate from losing control and returns the rider to the unfinished part without awarding an advanced horsecraft flag.
- **Cinematic moment:** The courtyard opens into a longer sightline as the horse accelerates, then the last gate tightens the composition around a deliberate stop.
- **Next implementation task:** Stage a readable entry and stopping area, add contextual trainer reactions, and make the next valid gate apparent from horseback.
- **Acceptance criterion:** A first-time player can identify the next gate and stopping requirement; wrong-order passage cannot complete the course and a safe retry preserves completed gates.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-004 · Guard and counter

**P1 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Will the child strike in anger or wait for the opening his teacher has exposed?
- **Playable objective:** Read two telegraphed blows, hold guard, recover and counter within the trainer’s opening.
- **Encounter or choice:** Early swings meet a guarded response; a patient counter produces a clear change in the trainer’s stance.
- **Local consequence:** The lesson records one learned sequence and gives specific corrective feedback without practice damage or an arbitrary damage upgrade.
- **Cinematic moment:** The sound of the yard falls behind the rhythm of two practice blows; the teacher briefly lowers his weapon after a clean counter.
- **Next implementation task:** Give each practice phase distinct posture, caption and sound cues, with recovery feedback tied to the actual strike window.
- **Acceptance criterion:** Early, late and correctly timed counters receive distinct feedback; the lesson finishes only after the required guards and counter, with no damage in practice.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-005 · Tracks beyond Home

**P1 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can observation overcome the urge to hurry toward a prize?
- **Playable objective:** Follow three physical traces and quietly reach an observation position beside the quarry.
- **Encounter or choice:** A tempting direct line passes the later trace but cannot replace examining the earlier evidence; noisy approach calls for a calmer second attempt.
- **Local consequence:** The remembered trail contains only examined traces; completion records observation of the animal, not a kill or harvested item.
- **Cinematic moment:** Reeds and dry scrub part just enough for a first distant glimpse; the final approach holds on the animal’s breathing and the player’s footsteps.
- **Next implementation task:** Make the three traces visually distinct, use terrain to connect their sightlines, and replace generic guidance with evidence-specific observations.
- **Acceptance criterion:** Each trace requires proximity and eye-level visibility, out-of-order inspection explains what is missing, and the final approach cannot complete through a wall or while rushing.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-006 · The return-path ambush

**P1 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can the child bring his lessons to bear when the return home becomes dangerous?
- **Playable objective:** Recognize the ambush, create space by movement or a guarded counter, and reach the courtyard alive.
- **Encounter or choice:** Escape immediately or face the attacker long enough to open a safer retreat; mounted escape remains a supported route.
- **Local consequence:** The aftermath receives only the assault details the player actually observed; reaching safety does not identify the attacker’s employer.
- **Cinematic moment:** The familiar return bend suddenly conceals movement; the courtyard’s light becomes a practical destination while footsteps close behind.
- **Next implementation task:** Rework the bend’s approach and escape sightline, give the assailant an unmistakable warning tell, and stage the household’s arrival response.
- **Acceptance criterion:** Both immediate escape and guard-counter retreat are viable, failed attempts restart the encounter without corrupting the household state, and unseen identity information is never added.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-007 · The household inquiry

**P1 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Who gets to shape the account of an attack before the child has understood it himself?
- **Playable objective:** Hear the household accounts, choose escort or independent inquiry, inspect the bend and return a bounded report.
- **Encounter or choice:** Raj Kaur’s offer makes protection useful but socially visible; investigating alone changes the exchange and presence at the bend.
- **Local consequence:** The report retains chosen approach and inspected evidence, while uncertainty survives both routes and neither produces a culprit.
- **Cinematic moment:** The same bend is quieter on the return visit; a guard’s presence, or its absence, changes the distance between the child and the road.
- **Next implementation task:** Give the inquiry a staged household discussion, branch-specific companion blocking and a final report assembled from heard and seen details.
- **Acceptance criterion:** Both inquiry routes reach a distinct acknowledgment, omitted evidence is not reported as seen, and restoring the checkpoint restores the companion and chosen route together.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### HOME-008 · Four-food delivery

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can the young heir keep an ordinary promise when rank does not carry the food for him?
- **Playable objective:** Accept the four-food contract, collect its actual cargo and deliver it to the market recipient.
- **Encounter or choice:** Decide whether to check the delivery terms with the household before setting off; the recipient responds to the real cargo rather than the player’s title.
- **Local consequence:** The existing finite payment remains attached to one successful handover; a failed attempt leaves a clear account of missing cargo.
- **Cinematic moment:** A busy market makes room for a small, practical exchange: a tally, a handover, and a recipient who returns immediately to work.
- **Next implementation task:** Author a short contract briefing, show cargo and recipient spatially, and stage the single delivery acknowledgment.
- **Acceptance criterion:** Exactly four food leave the carried supply on success, payout occurs once, and save/load before or after handover cannot repeat the reward.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [the household story pass](HOUSEHOLD_STORY_DEVELOPMENT.md) for current behavior, verification and remaining performance work.

### HOME-009 · Bring the carrier Home

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Does giving an escort order matter if the person entrusted to you cannot keep up?
- **Playable objective:** Meet the return carrier, keep physical contact during the journey, and check the same carrier and cargo into Home.
- **Encounter or choice:** Stop and regroup when the carrier is separated or continue ahead and return to recover contact; the disputed crossing remains an optional route of this arc.
- **Local consequence:** Arrival is earned by the carrier’s physical return, with one existing supply check-in and no additional cargo for alternate paths.
- **Cinematic moment:** At the gate the child turns back; the laden carrier is still crossing the open road and the escort must wait.
- **Next implementation task:** Add readable lost-contact and regroup behavior, an arrival blocking pass, and a shared handover used by the ordinary and disputed routes.
- **Acceptance criterion:** Reaching Home alone cannot finish; a separated carrier can be recovered, and every route resolves the same one-time check-in.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [the household story pass](HOUSEHOLD_STORY_DEVELOPMENT.md) for current behavior, verification and remaining performance work.

### HOME-010 · Water for the household

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Will the heir notice how much labor sits beneath the household’s ordinary comfort?
- **Playable objective:** Draw three units at the well twice, carry each load on foot, and return six units to the household.
- **Encounter or choice:** The second trip makes the player choose a usable, steady route with the loaded carrier; waiting during the draw offers a short exchange with another household worker.
- **Local consequence:** Water accounting follows the real draw and deposits; conversation changes local acknowledgment without producing repeatable money.
- **Cinematic moment:** The well’s rope creaks against the rim, then the frame drops to the weight of the carried vessels on the walk back.
- **Next implementation task:** Stage the draw and deposit as visible actions, add one concise worker exchange, and communicate load restrictions before the player tries to mount.
- **Acceptance criterion:** Two valid draws and deposits deliver exactly six units, load restrictions are explained in context, and interruption or reload cannot create water.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [the household story pass](HOUSEHOLD_STORY_DEVELOPMENT.md) for current behavior, verification and remaining performance work.

### HOME-011 · The smith’s commission

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can a promise to improve the household survive the cost and waiting that skilled work requires?
- **Playable objective:** Reserve fuel and fee, hand over the commission, return when the smith has finished, and deliver the two tools Home.
- **Encounter or choice:** Before handover, commit the reserved resources or cancel openly; after handover, the smith gives an honest progress report rather than a second purchase.
- **Local consequence:** Cancellation releases only the pre-handover reservation; completion yields the existing two tools once and records the household’s receipt.
- **Cinematic moment:** A tool-shaped blank passes from dark workbench to furnace light; the collected pair is carried out through the same threshold later.
- **Next implementation task:** Connect commission dialogue to the smith’s workcell staging and make reservation, work underway, collection and Home delivery distinct visible states.
- **Acceptance criterion:** All four stages read clearly, cancellation is unavailable after handover, and collecting or delivering twice cannot duplicate tools or fee deductions.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [the household story pass](HOUSEHOLD_STORY_DEVELOPMENT.md) for current behavior, verification and remaining performance work.

### HOME-012 · Sukerchakia household service

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can the child accept responsibility for someone else’s service without pretending to have seen what the guard saw?
- **Playable objective:** Hear the market and well requests, provision an already hired guard, dispatch him, and receive his returned accounts.
- **Encounter or choice:** Choose which finite request to serve first; if provisions or attendance are missing, resolve those needs before ordering departure.
- **Local consequence:** The guard’s report remains an attributed report received only when heard, with no firsthand memory from delegated work.
- **Cinematic moment:** The guard walks away carrying the household’s supplies; an empty place at the gate persists until he physically returns.
- **Next implementation task:** Give the two requesters different immediate needs and add a visible departure, absence, return and report sequence around the existing service state.
- **Acceptance criterion:** Dispatch respects hire and provision requirements, both requests finish once, and returned information appears only after the player hears the guard.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [the household story pass](HOUSEHOLD_STORY_DEVELOPMENT.md) for current behavior, verification and remaining performance work.

### HOME-013 · The Bhangi Bazaar Brawl

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** What kind of courage will the child’s friends remember: winning a public challenge or bringing everyone home?
- **Playable objective:** Walk with Mela and Jiva to the bazaar confrontation, counter or withdraw together, then regroup and report Home.
- **Encounter or choice:** Stand through the challenge or deliberately leave with both companions; the friends react to the choice without turning withdrawal into a failed mission.
- **Local consequence:** The local retelling and companion responses remember the chosen resolution; no route declares a wider clan uniformly hostile.
- **Cinematic moment:** A market conversation loses its casual rhythm; after the confrontation, the camera finds the three friends walking at the same pace again.
- **Next implementation task:** Complete approach, confrontation and regroup blocking; author separate companion lines for a guarded resolution and collective withdrawal.
- **Acceptance criterion:** Both resolutions complete, neither companion teleports through the encounter, and the Home report matches the actual route after save/load.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [friends and horsecraft](FRIENDS_AND_HORSECRAFT_STORY.md) for the developed subset and verification limits.

### HOME-014 · Maha’s horsecraft lesson

**P2 · In development**. Baseline: main prototype; 1792.

- **Dramatic question:** Can showmanship be disciplined enough to become a useful mounted skill?
- **Playable objective:** Complete moving single-horse balance, paired-horse balance, then mounted firing, reloading and withdrawal.
- **Encounter or choice:** The trainer allows a controlled reset between exercises; the player chooses when to stand, settle, fire and withdraw while movement continues.
- **Local consequence:** Only each completed exercise grants its existing corresponding capability; the standalone practice scene never grants campaign skills.
- **Cinematic moment:** The paired horses briefly settle into one rhythm before the lesson changes to smoke, reload and a controlled retreat.
- **Next implementation task:** Give the three exercises separate staging and instructor reactions, strengthen mounted input feedback, and make the retreat a visible finish.
- **Acceptance criterion:** Each flag requires its own actual exercise, retrying one cannot complete another, and exiting the lesson returns Home with only earned capabilities.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Implemented increment:** See [friends and horsecraft](FRIENDS_AND_HORSECRAFT_STORY.md) for the developed subset and verification limits.

### HOME-015 · Missing remounts

**P2 · In development**. Baseline: draft branch prototype; 1792.

- **Dramatic question:** Can the young heir establish what happened to the remounts without treating suspicion as permission?
- **Playable objective:** Reach the private yard, inspect the sealed tally and both horses, then report the limited observations to the quartermaster.
- **Encounter or choice:** Seek an introduction through the east gate, use the service gap, or observe from the ramp; witnesses react to how the boundary was crossed.
- **Local consequence:** The report distinguishes what was seen and what was read aloud; the route may create a local witness account but never a horse or cash grant.
- **Cinematic moment:** Two horses shift behind a private gate while the sealed tally remains out of reach of easy explanation.
- **Next implementation task:** Build three legible approach routes with different witness staging and a report conversation that names the actual evidence obtained.
- **Acceptance criterion:** All three routes can deliver the required observations, unseen or unread tally content is absent from the report, and witness memory follows the route actually taken.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

**Current increment:** See [rope and remounts](ROPE_AND_REMOUNT_STORY.md) for current-Home integration, developed staging and verification limits.

### HOME-016 · The borrowed rope

**P2 · In development**. Baseline: draft branch prototype; 1792.

- **Dramatic question:** What is owed to a story when two people remember its lesson differently?
- **Playable objective:** Hear the rope story’s variants, inspect the rope, compare the accounts, and retell a chosen version to a local listener.
- **Encounter or choice:** Preserve one teller’s framing or openly name the disagreement; the physical rope can prompt recollection but cannot settle the story’s moral.
- **Local consequence:** The listener receives the selected attributed telling; the game stores transmission rather than declaring a canonical truth.
- **Cinematic moment:** The same length of rope passes through two different gestures as its tellers place emphasis on different parts of the memory.
- **Next implementation task:** Stage each telling with a distinct voice and object handling, then add a concise retelling response that reflects the player’s chosen attribution.
- **Acceptance criterion:** The two accounts remain distinguishable, repeat listening adds no independent corroboration, and the listener receives only the retelling actually selected.

**Historical treatment:** Explicitly fictional sakhi-inspired transmission episode.

**Current increment:** See [rope and remounts](ROPE_AND_REMOUNT_STORY.md) for current-Home integration, developed staging and verification limits.

### HOME-017 · A funded instructor

**P2 · In development**. Baseline: draft branch prototype; 1792.
**Current increment:** See [the instructor development guide](INSTRUCTOR_STORY_DEVELOPMENT.md) for current-Home integration, original scene direction and qualification limits.

- **Dramatic question:** Can the household sustain the teacher it wants, beyond the promise of a wage?
- **Playable objective:** Reserve the commission, meet and escort the instructor, sign terms, provision the pupil, and complete funded practice.
- **Encounter or choice:** Commit only when wages and supplies are available; during practice, recover attendance or supplies when an interruption stops progress.
- **Local consequence:** The instructor’s presence, pay and eligible teaching time determine progress; unsupported promises cannot produce trained pupils.
- **Cinematic moment:** A quiet signing at the quartermaster’s desk is followed by an ordinary drill whose pauses reveal what the contract actually costs.
- **Next implementation task:** Review human pacing and develop candidate, signing and pupil performances beyond the current procedural staging.
- **Acceptance criterion:** Commission, escort and signing occur in order; practice advances only with attendance and required supplies, and interrupted or resumed sessions do not double-charge.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### CMD-001 · Lahore road patrol

**P4 · Planned**. Baseline: main prototype; 1801 fictional fixture.

- **Dramatic question:** How much authority can a ruler safely delegate before hearing what the road actually requires?
- **Playable objective:** Assign the patrol, control the captain or delegate the same order, inspect village and outpost, and receive the return report.
- **Encounter or choice:** Organize the patrol or withdraw on the available observations; switching viewpoint changes control, not the number of orders or riders.
- **Local consequence:** Riders remain committed until the delayed report resolves the original order; the ruler learns only the report received.
- **Cinematic moment:** The departure order is heard at court, then the same riders appear on a quieter road where the decision has physical costs.
- **Next implementation task:** Author a distinct road dilemma and concise village/outpost reactions around the existing command loop, keeping delegated and direct control equivalent.
- **Acceptance criterion:** Both control modes resolve one shared order, no viewpoint switch duplicates riders, and the report reflects the actual patrol or withdrawal outcome.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### MAHA-001 · Mahan’s field camp

**P4 · Planned**. Baseline: main prototype; 1790 development fixture; chronology variants retained.

- **Dramatic question:** What can a father still put in order when the campaign’s horizon is narrowing?
- **Playable objective:** Send scouts to ford and ridge, hear delayed reports, consult retainers, choose march or hold, and reach the fixed endpoint.
- **Encounter or choice:** Spend time and provisions improving the account or advance with incomplete knowledge; bounded field orders change the immediate march, not the recorded death.
- **Local consequence:** The camp retains which reports arrived and which orders were issued; the father’s endpoint and chronology variant remain declared.
- **Cinematic moment:** A scout returns to find the same tent quieter; the last instruction carries farther than the father can now march.
- **Next implementation task:** Give the ford and ridge different practical risks, stage report arrival and the final handover, and connect the field prototype to a clearly marked retrospective frame.
- **Acceptance criterion:** March and hold produce distinct local supply/report histories, delayed knowledge is not available early, and every supported route reaches the declared fixed endpoint without inventing a completed father campaign.

**Historical treatment:** Original authored gameplay; historical setting does not authenticate the episode.

### PRO-001 · Sobraon to the oral telling

**P4 · Planned**. Baseline: main prototype; 1846 → 1849 → retrospective.

- **Dramatic question:** What does a survivor choose to carry when an army’s crossing is gone?
- **Playable objective:** Escape the Sobraon earthworks, optionally carry a wounded soldier, steer timber across the Sutlej, and approach the later surrender tableau.
- **Encounter or choice:** Take the wounded man and accept slower movement or move alone; steer through the river’s physical obstacles before the later oral telling.
- **Local consequence:** The immediate survival presentation remembers the rescue choice; the veteran’s later knowledge does not enter the child’s 1792 state.
- **Cinematic moment:** The roar of the river cuts to the heavy silence of dropped muskets, then an oral voice carries the image into family memory.
- **Next implementation task:** Polish danger telegraphs, wounded-carry staging, timber feedback and the transition between the three times; keep the handoff to the family introduction explicit.
- **Acceptance criterion:** Both rescue choices can complete the crossing, river failure retries the bank checkpoint, skipping has a coherent handoff, and no future information or prologue supplies migrate into Home.

**Historical treatment:** Historical framing with original veteran viewpoint and authored survival actions.

### TALE-001 · The Wedding Road

**P3 · Planned**. Baseline: main prototype; Late eighteenth century; Nakai marriage negotiations.

- **Dramatic question:** Can a family alliance reach the doorway without becoming a public contest over who commands it?
- **Playable objective:** Inspect the gifts, receive the delegate, escort the arrival, hear the rival messenger and return an account to the keeper.
- **Encounter or choice:** Enter with visible ceremony or a quieter practical approach, then choose whom to alert about the rival message.
- **Local consequence:** The local arrival and final account reflect presentation and disclosure; the scene does not award the marriage or determine the bride’s life.
- **Cinematic moment:** Gift bearers pause at a threshold while a lone messenger waits just outside the procession’s rhythm.
- **Next implementation task:** Replace the generic courtyard beats with a visible delegation, distinct gifts, rival messenger staging and an arrival reaction for each local ending.
- **Acceptance criterion:** Both entry approaches remain playable, the alerted party matches the player’s choice, and the final account names only information heard during the errand.

**Historical treatment:** retrospective_family_account; The source connects Bhagwan Singh's alliance through his sister with losses of territory and attempted interference. The errands, witnesses, dialogue and local outcomes are original. The prospective bride Raj Kaur is distinct from Ranjit Singh's mother.

### TALE-002 · The Unequal Victory

**P3 · Planned**. Baseline: main prototype; 1785; a remembered coalition and its strained aftermath.

- **Dramatic question:** Whose sacrifice disappears when a coalition begins to tell a single story of victory?
- **Playable objective:** Hear the grievance, help the wounded companion across the passage, challenge the announcement and decide where the remaining dressings go.
- **Encounter or choice:** Give priority to public recognition or immediate relief; the companion’s passage makes the practical cost of either emphasis visible.
- **Local consequence:** The gathering’s local account and allocation of dressings differ; no choice rewrites the coalition’s campaign result.
- **Cinematic moment:** A victory announcement continues over the sound of a wounded companion stopping halfway across the crossing.
- **Next implementation task:** Stage the wounded escort with pauses and acknowledgment, separate the announcer from the relief point, and make the final allocation visible in the scene.
- **Acceptance criterion:** The companion physically reaches the crossing marker, the selected dressings recipient is reflected in the ending, and recognition never erases the recorded political dispute.

**Historical treatment:** retrospective_family_account; The book records shifting Nakai, Sukerchakia and other chief relationships, the 1785 coalition after Jai Singh's 1783 seizure, and failed reconciliation. This local escort and honour dispute is invented to make those pressures playable.

### TALE-003 · A Stranger at the Threshold

**P3 · Planned**. Baseline: main prototype; 1790; the book's account of revenge after Wazir Singh's death.

- **Dramatic question:** How far can a warning protect a household when the player cannot prove what a stranger intends?
- **Playable objective:** Question the stranger, compare the gate witness, warn the steward and escort a dependent into shelter.
- **Encounter or choice:** Give the warning as a concern or as a firmer alarm, then prioritize the dependent’s safe passage through a gathering that continues around them.
- **Local consequence:** The household response and witness wording change locally; the warning neither establishes omniscient guilt nor cancels the attributed death.
- **Cinematic moment:** The gathering remains audible as the dependent enters a narrower, quieter passage and the stranger disappears from the player’s view.
- **Next implementation task:** Make the two accounts spatially and vocally distinct, add a time-conscious shelter walk without a false alternate-history rescue promise, and stage the report.
- **Acceptance criterion:** All permitted warnings can lead to shelter, the dependent must arrive physically, and every ending distinguishes witnessed signs from the later recorded revenge account.

**Historical treatment:** retrospective_family_account; The book attributes Wazir Singh's murder to Dal Singh, son of Hira Singh of Bahrwal, and says an unnamed devoted servant later killed Dal Singh in his household. The player witnesses warning signs and shelters people; choices do not cancel that recorded death or establish omniscient guilt.

### TALE-004 · Desi Remembers the Reins

**P3 · Planned**. Baseline: main prototype; Early eighteenth century; ancestral recollection.

- **Dramatic question:** Does an ancestor’s legend live in spectacular feats or in the horse he learned to trust?
- **Playable objective:** Mount Desi, ride the marked journey, cover the required distance, water and dismount, then choose the companion’s closing emphasis.
- **Encounter or choice:** Let the closing telling emphasize the larger-than-life rider or the mare’s endurance; the ride remains one real mounted journey.
- **Local consequence:** The companion preserves the selected telling, while the short ride grants no proof of forty wounds or campaign horsecraft capability.
- **Cinematic moment:** The watering pause reveals the mare’s breathing and dust-marked coat after the storyteller’s sweeping claims.
- **Next implementation task:** Give Desi a recognizable piebald appearance, shape the route into a crest and watering pause, and stage the two closing emphases with the horse present.
- **Acceptance criterion:** The route requires actual mounted travel and dismounting, both legend emphases remain available, and replay cannot grant Home training flags.

**Historical treatment:** recorded_ancestral_tradition; The book names Budha Singh's piebald mare Desi and credits him with surviving about forty wounds. This short ride, horse responses and dialogue are original. It preserves the larger-than-life ancestor without treating the ride as a documented journey.

### TALE-005 · What Can Be Carried

**P3 · Planned**. Baseline: main prototype; Late eighteenth century; Ramgarhia displacement and return traditions.

- **Dramatic question:** What remains of a chief’s dignity when his followers need shelter more than another vow?
- **Playable objective:** Hear the elder, choose an offer from salvaged supplies, negotiate hospitality and escort a weary follower to shelter.
- **Encounter or choice:** Offer practical relief or preserve more of the party’s portable wealth; the host responds to the offer and the follower bears the delay.
- **Local consequence:** Tonight’s hospitality and the party’s remaining supplies shape the local ending; the treasure in the well remains a narrated possibility.
- **Cinematic moment:** A follower lowers a salvaged bundle at a host’s threshold while someone behind them still speaks of revenge.
- **Next implementation task:** Build a visibly burdened arrival, make the offered supplies tangible, and author host/follower responses that distinguish pride, need and obligation.
- **Acceptance criterion:** Each valid offer yields a coherent hospitality response, the follower reaches shelter physically, and no choice silently converts the treasure tradition into a documented player discovery.

**Historical treatment:** retrospective_account_with_treasure_tradition; The source contains Ramgarhia humiliation, release with gifts, retaliatory vows, exile and a treasure-in-a-well episode. This relief errand and its choices are original, with the treasure retained as narrated possibility rather than a fabricated documented discovery by the player.

### TALE-006 · The Water of Bahrwal

**P3 · Planned**. Baseline: main prototype; Ancestral legend; Guru Arjun and Hem Raj.

- **Dramatic question:** How does a household remember a welcome that its descendants understand as a blessing?
- **Playable objective:** Draw the first water, prepare the welcome, hear the charpai episode and blessing at the exterior threshold, then return to draw again.
- **Encounter or choice:** Choose where to place care and attention during the welcome while the telling preserves its miraculous transformation.
- **Local consequence:** The closing reflection remembers the chosen service and sweetened water within the legend’s frame; it grants no numerical miracle bonus.
- **Cinematic moment:** The same rope returns over the well’s rim after the blessing, with the changed water held in a still, attentive pause.
- **Next implementation task:** Give the first and second draws distinct sensory presentation, stage the welcome through attendants and objects, and retain the complete miracle in the oral account.
- **Acceptance criterion:** Both draws and the welcome occur in order, the miracle remains present in the telling, and the scene requires no Guru impersonation or religious-building entry.

**Historical treatment:** recorded_miracle_legend; The book records Hem Raj carrying the sleeping Guru Arjun home on a charpai, brackish water becoming sweet, and a blessing promising a powerful descendant. This adaptation preserves the miracle as the legend tells it. Dialogue and attendant errands are original; no Guru avatar, impersonation or religious-building entry is required.

### TALE-007 · The Door to the Young Chief

**P3 · Planned**. Baseline: main prototype; 1792; the Sukerchakia household.

- **Dramatic question:** Who can reach the young chief when every adult treats access as authority?
- **Playable objective:** Receive the audience order, hear Dal Singh’s objection, announce and escort Sada Kaur, then complete the register.
- **Encounter or choice:** Choose how to announce the arrival and whose objection to preserve in the register; control of a doorway becomes a political act.
- **Local consequence:** Witness acknowledgment and register wording differ locally; the scene does not settle who legitimately controlled the entire regency.
- **Cinematic moment:** An audience door closes between the child and the player while rival claimants remain on opposite sides of the waiting place.
- **Next implementation task:** Block the waiting factions as a tense, navigable audience queue and author specific reactions to the announcement and register choices.
- **Acceptance criterion:** The escort completes without bypassing the waiting dispute, register text reflects selected attribution, and the elder Dal Singh remains distinct from the Bahrwal revenge figure.

**Historical treatment:** conflicting_regency_accounts_with_original_dramatization; The Memorial records Lakhpat Rai quarrelling with Dal Singh, Maha Singh's maternal uncle, and a temporary reconciliation. Buxi supplies the household power struggle. The user-selected 1792 frame retains the project chronology beside the Memorial's 1790 succession. Sada's participation in this particular access dispute and all dialogue are original adaptations of the supplied political plot. This Dal is the elder regency figure, distinct from Dal son of Hira Singh of Bahrwal, killed in the revenge account.

### TALE-008 · The Whisper After Midnight

**P3 · Planned**. Baseline: main prototype; Late 1790s; the household at night.

- **Dramatic question:** Will an accusation become a fact merely because the court writes it down?
- **Playable objective:** Hear the messenger, inspect the unsigned account, listen to the attendant, escort her to shelter and choose the night register’s wording.
- **Encounter or choice:** Repeat the allegation with its source, record its uncertain standing, or emphasize the attendant’s direct account according to the available authored choices.
- **Local consequence:** The night’s circulation and protection of a witness shape the local ending; an affair, poisoning and guilt remain contested claims.
- **Cinematic moment:** An unsigned sheet waits under a lamp while the attendant’s quieter testimony competes with voices beyond the door.
- **Next implementation task:** Give rumor, document and direct testimony distinct staging and journal treatment; make the attendant’s shelter and the register’s final wording visible.
- **Acceptance criterion:** The register never states an unsupported allegation as established fact, the attendant reaches shelter, and every ending preserves the source disagreement rather than deleting the dark story.

**Historical treatment:** conflicting_accusations_with_original_witness_story; Griffin repeats allegations about Raj Kaur, Lakhpat Rai and matricide, then doubts the killing stories. Buxi describes the struggle over authority and cites Sinha's rejection of Smyth's accusation. Neither establishes guilt. This night, its letter, the witnesses and every spoken line are invented. Poison remains an allegation voiced by a character, never an acquired poison item or biological finding. Timing is deliberately broad; no death in 1801 is asserted.

### TALE-009 · Two Names in the Dispatch

**P3 · Planned**. Baseline: main prototype; 1807; a dispatch from Batala.

- **Dramatic question:** What can a courier responsibly carry when a birth announcement has already become a struggle over legitimacy?
- **Playable objective:** Receive the announcement, hear Sada Kaur’s instruction, choose how to carry the competing allegation and escort the dispatch rider to departure.
- **Encounter or choice:** Prioritize the formal household announcement or preserve the accusation as an attributed competing account; the courier cannot adjudicate parentage.
- **Local consequence:** The dispatch’s wording and handoff differ; neither choice proves substitution, assigns biological truth or decides future succession.
- **Cinematic moment:** Two names are spoken over a dispatch being sealed while an older accusation threatens to travel with them.
- **Next implementation task:** Create distinct announcement and rumor witnesses, make the seal and rider handoff visible, and write endings around transmission rather than a solved maternity mystery.
- **Acceptance criterion:** Each dispatch can be delivered, its wording matches the chosen treatment, and no ledger, ending or reward encodes strict primogeniture or a confirmed fabricated pregnancy.

**Historical treatment:** conflicting_birth_and_legitimacy_accounts; Griffin alleges substituted children and later political acknowledgement; the Memorial records the twins' birth announcement, thanksgiving and Mehtab's maternity. Neither the courier nor the choices establish biological truth. All dialogue, dispatch handling and minor witnesses are original. The scene preserves competing accusations without encoding strict male primogeniture or deciding future accession. Its authored 1807 frame follows the selected announcement variant and does not silently reconcile every source chronology.

### TALE-010 · The Fortress in the Letter

**P3 · Planned**. Baseline: main prototype; Late 1808; a diplomatic approach.

- **Dramatic question:** How much can a threatened ruler offer before anyone on the other side is authorized to answer?
- **Playable objective:** Receive the sealed approach, consult stores, record delivery terms, meet the receiving agent and escort him through the handoff.
- **Encounter or choice:** Carry a narrow approach or a stronger practical assurance within the scene’s choices; question the receiver about the limits of his authority.
- **Local consequence:** The delivery record captures the offer and the receiver’s limited mandate; the fort is not transferred and no alliance is concluded.
- **Cinematic moment:** The fort remains distant in the composition while the sealed packet crosses a much smaller space between two hands.
- **Next implementation task:** Stage stores, packet and receiver as three different forms of power, and give each ending a concrete receipt that stops short of acceptance.
- **Acceptance criterion:** The packet reaches the selected handoff, practical assurances match what was consulted, and every ending remains an approach delivered rather than British protection secured.

**Historical treatment:** secondary_diplomatic_account_with_original_courier_scene; The university entry records secret negotiations with British officers. Discover Sikhism describes a November 1808 offer of Atalgarh to Metcalfe tied to restoration of possessions. The packet, route, receiving agent and conditions voiced here are invented. This stage ends with an approach delivered, never a completed alliance, an invented interception or a transfer of the fort. Atalgarh here belongs to Sada's diplomatic story, not Dal Singh's Akalgarh identity.

### TALE-011 · Behind the Lowered Curtain

**P3 · Planned**. Baseline: main prototype; 1820–1821; departure from a watched camp.

- **Dramatic question:** What loyalty remains possible when escape has become a procession toward a closing gate?
- **Playable objective:** Receive Sada Kaur’s instruction, choose the departure account, confront Vasakha Singh and escort the bearers and covered litter to the outer entrance.
- **Encounter or choice:** Protect the bearers’ treatment or emphasize the report’s wording while deciding how openly to confront the informing retainer.
- **Local consequence:** The party’s dignity, witness account and treatment at the last gate vary; detention remains the fixed endpoint.
- **Cinematic moment:** The lowered curtain moves with each step while the gateway ahead gradually fills the frame.
- **Next implementation task:** Replace abstract escort markers with the litter and bearers’ synchronized movement, stage the retainer confrontation, and author distinct detention acknowledgments.
- **Acceptance criterion:** The litter and bearers reach the gate physically, local choices change the promised treatment or account, and no route advertises a successful alternate escape.

**Historical treatment:** source_attributed_escape_with_original_retainer_viewpoint; Griffin and the university entry preserve a covered-litter escape followed by detention. Discover Sikhism dates its account to 1820 and names Vasakha Singh as the informing retainer and Desa Singh as the pursuer. This 1820–1821 frame retains chronology variants. The player is a fictional additional retainer; dialogue, papers and movement choices are original. Detention is fixed. Local agency determines the treatment of bearers, the wording of a report and how the party reaches its last gate, never a successful alternate escape.

### TALE-012 · When the Camp Falls Quiet

**P3 · Planned**. Baseline: main prototype; 1792; the camp at Sodhra.

- **Dramatic question:** Can a child receive his father’s authority through a duty before he is ready to receive it through a title?
- **Playable objective:** Carry the father’s order, bring the veteran into evacuation work, escort him to the gate, prepare the returning party and deliver the message to Ranjit.
- **Encounter or choice:** Give priority to the people moving out or the wording of the message within the authored choices; practical care makes the handover personal.
- **Local consequence:** The evacuation’s immediate care and remembered message differ; Maha’s illness, withdrawal and later death remain fixed in the selected chronology.
- **Cinematic moment:** The campaign’s noise recedes while a small order passes from father, to runner, to son beside an evacuation gate.
- **Next implementation task:** Stage the camp’s gradual emptying, build a visible veteran escort and supplies handover, and write the father-son message as declared original drama.
- **Acceptance criterion:** The veteran and provision stages complete before the message is delivered, each ending acknowledges the chosen care, and the scene never labels the invented exchange a documented bedside investiture.

**Historical treatment:** retrospective_history_with_declared_dramatic_handover; This scene selects Griffin's 1792 illness and withdrawal, not the Memorial's 1790 child-victory outcome. The father's private words, delegated tasks, veteran, young runner, evacuation staging and choices are original drama. Authority passes through a small order to care for the camp; this is not evidence for a documented bedside investiture. Maha's death after his return remains fixed. Mana Singh is a research lead, not the identity assigned to the fictional veteran.

### TALE-013 · Names at the Gate

**P3 · Planned**. Baseline: main prototype; Late 1790s; after the Ramnagar conflict.

- **Dramatic question:** Can an agreement give a defeated household a future without demanding that it forget its dead?
- **Playable objective:** Learn the limits of your promise, hear the representative, escort the family’s reception, clarify provision and service, and settle one immediate need.
- **Encounter or choice:** Emphasize immediate provision or the terms of service; the representative can question what the clerk’s assurances actually mean.
- **Local consequence:** A bounded household need is met and terms are recorded locally; employment does not erase bereavement or speak for every Chattha family.
- **Cinematic moment:** A family representative hesitates at the same kind of gate that once kept enemies apart, with a clerk waiting inside instead of a drawn weapon.
- **Next implementation task:** Give the representative a particular household concern, stage the clerk’s terms as a conversation and make the final provision or service arrangement visible.
- **Acceptance criterion:** The player can promise only the stated terms, the representative reaches the reception physically, and the ending preserves grief alongside the limited settlement.

**Historical treatment:** secondary_reference_with_original_local_negotiation; The entry takes the reported estates and military employment offered to Jan Muhammad's sons as its historical anchor. The unnamed family representative, veteran, clerk, guarantees, supplies, dialogue and local outcomes are original. These people speak for particular households, never every Chattha family. The sequence follows the conflict without replaying its killing; jobs and provision do not erase bereavement. The late-1790s period is separate from the 1792 opening.

## Secondary queue

These 13 items support the sequence cards. They remain presentations, route/scenario variants, optional micro-scenes, studies or mechanics; they are not added to the 33 sequence count.

| ID | Type and relationship | Next development task | Acceptance criterion |
| --- | --- | --- | --- |
| MEM-001 · Maha’s family story / Charat Singh | presentation; P0; HOME-001 | Give the family telling a clear opening and a short handoff to the child’s yard; retain previous, next and skip without adding page-count missions. | Finishing, revisiting and skipping all return to a coherent Home start without granting information from later eras. |
| CMD-002 · Houses and rivals | scenario_variant; P4; CMD-001 | Author house-specific reactions and companion staging as a scenario variant of the same command order. | Expanded house presentation resolves the original order once and does not add riders or a second completion. |
| ROAD-001 · The disputed crossing | route_variant; P2; HOME-009 | Stage the closed bar, keeper and delayed confirmation as three credible return choices sharing one carrier and handover. | Recognition, confirmation and bypass all preserve the same cargo and can reach one Home check-in; waiting does not invent an immediate reply. |
| MICRO-001 · Saffron in the fold | micro_scene; P2; HOME-007 | Animate or present the cloth being turned so its repair is discovered through the action, then return cleanly to the world. | The repair is visible during inspection, interruption restores control, and the optional scene grants no mission or inventory reward. |
| MICRO-002 · The hole that was not used | micro_scene; P2; HOME-003 | Make the unused harness hole and worn neighboring material legible, with a short observation tied to inspection. | The object can be understood without a quest marker, its scene closes safely, and no riding skill is awarded for looking. |
| MICRO-003 · A pan with two endings | micro_scene; P2; HOME-013 | Stage Mela and Jiva around the pan with different rhythms and reactions for their two endings. | Both nearby companions contribute their own fable, missing attendance prompts regrouping, and neither telling becomes a forced canon. |
| STUDY-001 · Locomotion course | study; P1; HOME-001, HOME-005 | Use the movement course to qualify the yard and trail’s actual slopes, clearances and stopping distances. | The mission geometry can be traversed with its shipped movement controls; the fixture remains outside campaign completion totals. |
| STUDY-002 · Ground-contact course | study; P1; HOME-005, HOME-006 | Qualify scrub, bank and bend contact geometry before relying on it for pursuit or stealth staging. | The player and pursuer remain grounded at the encounter’s slopes and edges, with no checkpoint placed inside collision. |
| STUDY-003 · Horsecraft study | study; P2; HOME-014 | Use the standalone course to qualify balance, paired movement and mounted reload cues before staging the lesson. | The required maneuvers work in the study, and exiting practice cannot write any Home capability receipt. |
| STUDY-004 · Service equipment study | study; P2; HOME-012, HOME-017 | Review guard silhouettes, articulation and equipment overlap in the actual service and drill poses. | Duty and practice poses remain readable without severe equipment intersections; the inspection adds no mission or equipment grant. |
| STUDY-005 · Political exposure sandbox | study; P2; HOME-015, HOME-016 | Qualify how a local witness sees, remembers and reports a boundary crossing or telling before reusing the behavior in stories. | A witness needs a real perception or report event; camera-only visibility never becomes character knowledge. |
| SYSTEM-001 · Hawk scouting | mechanic; P3; HOME-005, HOME-015 | Choose and reconcile the hawk branch variants, then design one bounded scouting use without replacing ground-level evidence inspection. | Hawk contacts are limited to what its mechanic can observe, do not identify hidden motives, and do not complete unrelated quest evidence automatically. |
| SYSTEM-002 · Ground Focus | mechanic; P1; HOME-005, HOME-007 | Connect nearby sensory evidence to the trail and bend while keeping markers temporary and observations grounded. | Focus cannot reveal through walls or preserve absent contacts as current facts; toggling it never advances a lesson. |

## Story backlog and scope

The 28 youth catalogue entries contain **one existing adaptation alias** (HOME-013) and **27 planned entries**. The father campaign, eight Fall of Empire chapter contracts, and ten reference-intake briefs are additional planning scope. Their counts are different units and are not summed into a claim of playable missions. A related recollection does not complete a larger proposed battle or campaign.

| Backlog ID | Title / current scope | Next planning task |
| --- | --- | --- |
| YOUTH-bhangi_market_brawl | The Bhangi Bazaar Brawl — implemented_adaptation. Related: HOME-013. | Continue development under HOME-013; keep this catalogue entry as its alias. |
| YOUTH-hashmat_ladewali | The Hunt at Ladewali / Hashmat Khan — planned. | Outline the named source account and distinguish its hunt, confrontation and outcome from the anonymous opening ambush. |
| YOUTH-sodhran_command | The Child at Sodhran — planned. Related: TALE-012. | Choose an explicit chronology variant and outline command decisions beyond TALE-012’s evacuation errand. |
| YOUTH-throne_lahore_pardon | The Throne of Lahore: Pardon — planned. | Draft a hearing with a playable act of judgment and a bounded recipient of the pardon. |
| YOUTH-regency_escape | Out of the Regents’ Sight — planned. | Map one departure, its household witnesses and the return consequences without presuming the regents’ motives as fact. |
| YOUTH-ammunition_rebellion | The Inherited Ammunition — planned. | Define the physical ammunition custody, available refusal or delivery choices, and the immediate consequence of each. |
| YOUTH-river_races | Across the River — planned. | Choose a river crossing and qualify swimming or craft behavior before writing the race’s social stakes. |
| YOUTH-end_regency | Taking the Reins — planned. | Map the transfer of particular orders and offices into a playable audience rather than one button granting absolute power. |
| YOUTH-boar_hunt | The Great Boar Hunt — planned. | Define animal behavior, a hunting party’s responsibilities and failure recovery before promising a complete hunt. |
| YOUTH-nihang_camp | A Night in the Nihang Camp — planned. | Choose a host and evening duty through which the player can experience the camp, with attributed religious and oral material. |
| YOUTH-bazaar_revelry | Nights in the Bazaar — planned. | Outline one night with companions, a concrete obligation and a morning consequence; avoid a generic revelry montage. |
| YOUTH-afghan_raiders | Against the Afghan Advance — planned. | Choose a specific threatened place, evacuation or skirmish objective and evidence-limited enemy observations. |
| YOUTH-pocket_money_companions | A Pouch for the Playground — planned. | Design a finite pouch and a choice between friends’ immediate needs with visible accounting. |
| YOUTH-captured_falcon | The Falcon in Another Courtyard — planned. | Define who holds the bird, how the player can negotiate or retrieve it, and how this differs from unlocking the hawk mechanic. |
| YOUTH-unwritten_king | The Unwritten King — planned. | Design an oral judgment or remembered dispatch task whose success does not require the protagonist to read. |
| YOUTH-sodhran_naming | The Day Budh Singh Became Ranjit — planned. | Record the naming tradition and chronology alternatives, then choose a framed messenger viewpoint for the proposed episode. |
| YOUTH-ancestral_mare | Budha Singh and Desi — planned. Related: TALE-004. | Decide whether this becomes an expanded ancestor journey or remains an alias of TALE-004; do not count both for the same ride. |
| YOUTH-jhang_night_raids | The Fighting at Jhang — planned. | Outline darkness, scouts, mounted movement and a limited raid objective with a physical withdrawal. |
| YOUTH-gujranwala_skirmishes | The Village Alarm — planned. | Draft a village alarm in which warning, muster and civilian movement precede the bounded fighting. |
| YOUTH-palace_purge | Keys to the Household — planned. | Identify which keys, offices and witnesses the player can affect while keeping allegations distinct from established acts. |
| YOUTH-maan_singh_lethal | The King of Thieves: Lethal Variant — planned. | Define the explicit telling that supports the lethal variant and its local playable choice; do not silently replace a competing pardon account. |
| YOUTH-kasur_night | Night Encounter near Kasur — planned. | Choose the encounter viewpoint, what can be recognized at night and a recoverable route back from the meeting. |
| YOUTH-raj_kaur_mystery | Raj Kaur: Conflicting Accounts — planned. Related: TALE-008. | Expand the competing tellers and political stakes beyond TALE-008 without encoding the poison or matricide allegation as solved truth. |
| YOUTH-ramnagar_cavalry | The Clash at Ramnagar — planned. Related: TALE-013. | Outline reconnaissance, artillery and mounted objectives separately from TALE-013’s later settlement. |
| YOUTH-brick_kilns | The Battle of the Brick Kilns — planned. | Map kiln geometry, sightlines and one tactical objective before choosing the mission’s full battle scale. |
| YOUTH-hound_confrontation | The Hounds in the Courtyard — planned. | Define handlers, dogs and a readable de-escalation or escape objective before introducing animal pursuit. |
| YOUTH-bazaar_arrest | The Unrecognized Heir — planned. | Design recognition, custody and release as physical stages with different witnesses and a bounded consequence. |
| YOUTH-sialkot_tribute | The Sialkot Tribute Raid — planned. | Define the tribute demand, transport and response choices before representing the whole campaign. |
| PLAN-FATHER | Required pre-Lahore Mahan campaign and childhood reprise — contract_only. Related: MAHA-001. | Specify the pre-Lahore trigger, father-viewpoint handoff, campaign stages and childhood reprise; MAHA-001 is an input, not completion of the contract. |
| PLAN-FALL | Fall of Empire campaign — contract_only. Related: PRO-001. | Keep the eight later-era chapter contracts as future scope; polish PRO-001 only as the current retrospective frame. |
| BRIEF-001 | Punjab ecology and running skirmish encounters — proposed. | Write one grassland running-skirmish encounter and one seasonal river obstacle with terrain-dependent movement, reload and withdrawal. |
| BRIEF-002 | Maha’s smallpox vigil and childhood training — proposed. | Frame the smallpox vigil as an attributed family recollection and choose a caregiver or attendant action before proposing a playable bedside scene. |
| BRIEF-003 | Rasulnagar naming and the three-generation Chattha conflict — proposed. | Separate three generations and chronology variants; choose distinct siege, message and settlement viewpoints before setting mission counts. |
| BRIEF-004 | Dal Singh and Sada Kaur’s secret alignment — proposed. | Draft an access or messenger task around the proposed alliance, with the secret’s source and the player’s actual knowledge stated. |
| BRIEF-005 | Mathew and the royal caravan — proposed. | Outline caravan travel and the foreign visitor’s backchannel using separate public and privately attributed accounts. |
| BRIEF-006 | Lahore informants and the 1799 entry — proposed. | Map a Lahore informant chain, gate approach and entry settlement with civic stakes and physically delivered intelligence. |
| BRIEF-007 | Palace correspondence and competing intelligence networks — proposed. | Design one disputed dispatch route with distinct sender, carrier, receiver and witness knowledge; avoid a universal omniscient spy network. |
| BRIEF-008 | Cis-Sutlej estates and diplomatic protection — proposed. | Choose one petition and boundary crossing to make estate protection concrete, retaining the supplied diplomatic accounts as attributed. |
| BRIEF-009 | Rival misls, hill states and regional diplomacy — proposed. | Choose a specific negotiable obligation for each future faction encounter; worldbuilding descriptions alone do not establish missions. |
| BRIEF-010 | Sindh, Shikarpur and the Mazari campaign — proposed. | Separate Shikarpur ambitions, river access and the Mazari operation into research-and-outline tasks before promising a southern campaign. |

## Literary, cinematic and attention direction

The 33 cards now each include a `narrative_direction` block in the structured source. These are **original planned directions**, including a dramatic turn, setup and payoff, playable staging, attention rhythm, quiet recovery, bounded agency and an observable acceptance condition. They extend the existing cards; they add no missions and do not replace their historical treatment.

The current runtime attention pass targets the shared childhood presentation and HOME-003–007. Its caption and HUD changes are a concrete first step toward that arc's attention direction. They do not implement the other sequences' proposed performances, scenery, sound or camera work. Existing prototype receipts and the new direction's acceptance conditions remain separate.

### The connected childhood arc

Use the yard threshold as the first recurring image: ordinary home, a place of departure, then the place the child needs to reach under threat. The riding lesson develops restraint, sparring develops patience, and tracking develops observation. The ambush gives those skills immediate stakes; the inquiry then asks what the child can honestly say about the event. The same terrain returns with a changed meaning. This is a proposed dramatic structure, not a claim that the fictional attack caused a documented historical policy.

The emotional rhythm is **curiosity → confidence → concentration → discovery → alarm → reflection**. Do not keep increasing noise or urgency across all six states. During riding, the player needs the next gate; during sparring, the next tell; during tracking, a surface worth examining; during pursuit, an escape route; during inquiry, room to hear and compare accounts. Reflective lines belong after an action has made them relevant.

### Attention rules for implementation

- Give each active beat one dominant question and one immediately useful action. Additional context can remain in reviewable records or optional conversation.
- Make important information persistent or recallable. A short caption disappearing is never permission to remove the player's only account of an objective or decision.
- Let imminent danger interrupt flavor, and let a useful correction survive long enough to be read. Repeated interactions should not flood the same line or conceal a new response.
- Build compositions through actual approach, silhouette, distance, movement and sound. Preserve player camera control and avoid hiding navigation or evidence behind cinematic scenery.
- Use quiet after success, danger and testimony. Quiet is a change in demand, not a mandatory wait or a disabled interface.
- Keep choice consequences local and visible: a person waits, a supply is spent, a report changes, a companion reacts. Do not use rewards to certify disputed history or force every scene into a moral verdict.
- Review attention through comprehension, agency and recovery. Time spent playing is not by itself evidence that a sequence works.

### Direction matrix

Each row names the planned turn and its particular staging rhythm. The JSON cards contain the complete implementation and acceptance direction.

| Sequence | Dramatic turn | Setup and payoff | Attention and recovery |
| --- | --- | --- | --- |
| HOME-001 · Learning the yard | Wandering becomes a first responsibility. | The courtyard threshold establishes Home. | Broad exploration narrows to the waiting courier; no repeated summons. |
| HOME-002 · The sealed message | A delivery becomes a choice about uncertainty. | Seal, limited witness account, trainer receipt. | Hear the gap, choose an approach, finish on one acknowledgment. |
| HOME-003 · First riding gates | Speed gives way to restraint. | Completed gate stitches and a deliberate stop. | One active gate; brief reactions between steering demands. |
| HOME-004 · Guard and counter | Immediate retaliation gives way to timing. | Raised weapon and exposed recovery. | Readable combat rhythm; stillness after the admitted counter. |
| HOME-005 · Tracks beyond Home | Pursuit gives way to observation. | Three different traces resolve into a breathing animal. | Search and inspect, with quiet gaps and an unhurried reveal. |
| HOME-006 · The return-path ambush | A familiar route becomes dangerous. | The opening threshold returns as the escape destination. | Quiet approach, clear warning, urgent retreat, then release. |
| HOME-007 · The household inquiry | Protection becomes a question of accompaniment and account. | The same bend returns as evidence. | Offer, revisit, observe, report; leave uncertainty room to remain. |
| HOME-008 · Four-food delivery | A titled promise meets an ordinary tally. | The departure count returns at handover. | Short contract, free travel, one exchange, market resumes. |
| HOME-009 · Bring the carrier Home | Reaching the gate is not yet bringing someone home. | The carrier’s pace pays off in waiting or regrouping. | Movement and contact checks; breathing room after reunion. |
| HOME-010 · Water for the household | Routine water becomes visible labor. | The same rope and vessels mean more on the second trip. | Teach once, vary the human observation, finish without a speech. |
| HOME-011 · The smith’s commission | Wanting tools becomes paying for skilled time. | Blanks become the completed pair at the same bench. | Commit, leave room for other activity, collect once. |
| HOME-012 · Sukerchakia household service | An order creates an absence and a later account. | The guard’s place at the gate is occupied, empty, then filled. | Need, departure, ordinary activity, received report. |
| HOME-013 · The Bhangi Bazaar Brawl | Public courage meets the friends’ private judgment. | Three conversational rhythms break and reform. | Warmth, challenge, action, a quieter shared return. |
| HOME-014 · Maha’s horsecraft lesson | Spectacle becomes controlled recovery and withdrawal. | Settling the horse recurs across three exercises. | One new demand at a time; reset between exercises. |
| HOME-015 · Missing remounts | Visible horses do not settle the explanation. | The gate becomes part of the witness account. | Route choice, specific evidence, quiet walk before report. |
| HOME-016 · The borrowed rope | One object holds incompatible meanings. | The rope’s worn place receives two different emphases. | Distinct tellings, comparison, one attributed retelling. |
| HOME-017 · A funded instructor | A contract becomes attendance and practical care. | The instructor’s concern returns as a real interruption. | Expose only the current unmet condition; let repaired practice run. |
| CMD-001 · Lahore road patrol | A court order acquires its cost on the road. | The same order returns qualified by a report. | One decision per viewpoint; no unreceived distant discoveries. |
| MAHA-001 · Mahan’s field camp | A narrowing horizon makes unfinished duties intimate. | Ford and ridge reports shape the last handover. | Decision and delayed report; reduced noise around the final instruction. |
| PRO-001 · Sobraon to the oral telling | Defeat becomes a decision about whom to carry. | A bodily burden becomes part of the later telling. | Legible survival first; river danger gives way to substantial quiet. |
| TALE-001 · The Wedding Road | Ceremony is interrupted by a rival claim. | Gift bearers wait while a messenger changes the arrival. | Establish celebration before interruption; settle bearers before report. |
| TALE-002 · The Unequal Victory | Victory’s public account exposes an omitted cost. | An announcement sounds different beside the wounded companion. | One claim, one human interruption, one finite allocation. |
| TALE-003 · A Stranger at the Threshold | Uncertain warning becomes immediate protection. | Outer access contrasts with inner shelter. | Question, compare, warn, escort; no closing proof of guilt. |
| TALE-004 · Desi Remembers the Reins | An extraordinary reputation meets ordinary horse care. | A sweeping boast settles into Desi’s breathing at water. | Brief legend, mostly riding, reflective rest. |
| TALE-005 · What Can Be Carried | Lost standing meets a follower’s need for shelter. | A salvaged bundle becomes an offer. | Political pressure narrows to hospitality; let the follower rest. |
| TALE-006 · The Water of Bahrwal | Repeated labor becomes remembrance of a miracle. | The same rope draws water before and after the blessing. | Plain first draw, attentive welcome, quiet second draw. |
| TALE-007 · The Door to the Young Chief | A doorway makes access into political authority. | The audience door and register preserve a local exclusion. | Immediate claims first; let the closed door carry the pause. |
| TALE-008 · The Whisper After Midnight | An accusation meets a narrower witness account. | Unsigned sheet and official register expose inscription’s power. | Hear allegation once; give testimony equal space; end without a verdict. |
| TALE-009 · Two Names in the Dispatch | An announcement risks carrying an accusation farther. | Two names travel from speech to a sealed packet. | Separate accounts before one transmission choice; no parentage reveal. |
| TALE-010 · The Fortress in the Letter | A large offer meets a limited mandate. | A distant fortress contrasts with a small handoff. | Build the approach, clarify authority, end on receipt alone. |
| TALE-011 · Behind the Lowered Curtain | A closing route makes treatment the remaining choice. | Curtain, visible bearers and the final gate. | Reduce exposition as movement narrows; give detention an unhurried aftermath. |
| TALE-012 · When the Camp Falls Quiet | Authority passes through a duty of care. | The father’s order changes weight across three listeners. | Purposeful work gradually thins; make room for the last message. |
| TALE-013 · Names at the Gate | A future agreement leaves grief unfinished. | An enemy gate becomes a clerk’s reception. | Hear one concern, clarify one promise, avoid a victory celebration. |

### Review the designed effect

For each implemented direction, watch a fresh attempt and a returning attempt. Ask the player what changed, what they chose, what they actually know, and what they expect to do next. Record missed cues, repeated lines, blocked sightlines and involuntary waits. A player taking time to look or think is different from a player unable to identify the next action. Use that distinction before shortening dialogue or adding a marker.

The first childhood check should cover an overshot gate, an early counter, a slow trail search, both retreat approaches and both inquiry routes. Verify that important corrections can be read, immediate danger remains visible, a completed beat gets space, and the player can recover the objective after looking away. These are review targets; a written direction alone does not demonstrate them.

## Implementation receipts

The existing opening and childhood prototype passes have `current_pass` records in HOME-001–007. Their remaining performance and visual work stays open. All 33 `narrative_direction` blocks are planned original direction, with their own acceptance conditions still awaiting implementation and review. The runtime attention pass is limited to shared childhood presentation and HOME-003–007; record its concrete behavior and verification separately from these design intentions.

Before marking a direction complete, record the revision, the player-visible change, its observed acceptance result and any remaining limitation. An inherited prototype, a literary outline and a reviewed playable increment are different evidence of progress. No new sequence count is claimed here.

Coverage snapshot: 2026-10-02; ledger commit `4e85c2a469aae1cb567162b87ccf23eeaaa8d7a3`.
