# Shah Muhammad — event-driven narrator captions

Shah Muhammad is the project's selected retrospective narrator. Buddh remains the
player's identity. The eight lines in `game/narrative/shah_cues.json` are **original
English game drafts**, not historical quotations, translations or recorded speech.
Punjabi writing and performance remain to be produced. No claim is made that the
poet witnessed the childhood conversations or the fictional road dispute.

The home chapter queues lines for arrival, survival, household responsibility,
accepting the disputed-road assignment, its alternative outcomes, and actual
caravan check-in. A delayed reply's reaction requires hearing the answer, not
merely letting a timer expire. There is no narrator event that reveals an unseen
conspirator or transfers Mahan's private experience into Buddh's knowledge.

`narration_track.gd` accepts only catalogued event identifiers. It has no live
world reference, inventory, state writer, command authority or gameplay clock.
The scene supplies already-committed, player-available events. Captions run once
per event in the current presentation session, pause during dialogue/ambush danger,
and use the existing layout above the ordinary speech caption. No forced cutscene
or additional simulation pause is created by narration.

**N** opens a separate transcript and caption toggle. Only lines actually displayed
enter that transcript. It is not the character's **J** journal or **B** oral supply
account. A line stays for at least eight seconds, with a longer time for more text.
Disabling narration clears pending/current captions and silently marks intervening
events as seen, avoiding a backlog on re-enable.

The queue, transcript and toggle are presentation-session data, not campaign save
fields. Loading or restoring a checkpoint clears later presentation and uses
restored past events as a silent baseline. It does not claim that the player heard
old lines. New events can still play afterwards. Ordinary mounting/dismounting
does not reset narration. The caption toggle persists only in this scene instance.

Tests cover deduplication, malformed IDs, pause timing, toggling, rollback baselines
and absence of world/knowledge mutation. The final game still needs localized
writing, voice direction, recording, sound mixing and broader authored coverage.
The supplied source conversation remains a research lead, not an objective-source
certificate or an instruction to publish private conversation text.
