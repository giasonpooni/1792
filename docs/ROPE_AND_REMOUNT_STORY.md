# What returns, and what travels

This increment brings **HOME-015: Missing Remounts** and **HOME-016: The Borrowed
Rope** into the current Home chapter. It develops two existing sequence cards;
it does not add two missions to the inventory. Both episodes are original
fiction set in the childhood world of *1792: The Lotus Throne*.

The connected idea is **what an account carries beyond its first telling**.
The bazaar friends have already disagreed about the part of an outing worth
remembering. Here Buddh chooses what to pass onward, then discovers that his
own route through a yard can become an account carried by somebody else.
These are thematic connections, not new claims about a historical childhood.

## HOME-016: the ordinary object that will not give a verdict

**Question:** What is owed to a story when two people remember its lesson
differently?

The quartermaster remembers a hand that held on. The trader recounts a story
in which a borrowed rope became a stolen one. A neighbour adds another voice,
but names the trader as its source. The repaired rope invites a closer look
without answering who gave permission. A later recollection changes the
quartermaster's emphasis from the returning to the asking.

The turn comes when collecting more voices ceases to promise a simple answer.
The final action is telling somebody else what Buddh has heard. He can name
the quartermaster as his source or carry both accounts with their disagreement
intact. Neither choice purchases a verdict or a moral reward.

The implemented direction gives received accounts distinct scene titles and
short original framing. The first telling concerns the hand; the trader's
concerns the changed word; the neighbour's concerns the voice that brought it.
That variation makes the source relationship part of the drama. Each local
interaction shows its own received material. The optional remembered-stories
view holds the accumulated account, comparison and next available step.

Asking for further recollection is not receiving it. The existing short delay
uses the Home clock, and the new reply invites Buddh to continue his walk and
return. A paused conversation does not advance that wait. There is no new
countdown or requirement to remain beside the quartermaster. The neighbour's
response provides a quiet payoff to the chosen retelling.

**Review route:** finish the household inquiry and speak to the quartermaster
on foot. Hear his rope story. Hear the trader at the market, then use
**J → Remembered stories** to put the accounts side by side. Inspect the rope
beside the stable. At the neighbour near the well, hear where the story came
from and choose an attributed retelling. For the further recollection, ask
the quartermaster after comparison and inspection, resume the walk, and return
to hear his answer. Compare both retelling choices and try visiting the sites
in another order.

The rope and neighbour currently use simple procedural props. The rope has a
contrasting repair binding and frayed end. Scene framing and local placement
are implemented; distinct hand performances, finished assets, recorded voices
and richer everyday activity remain future staging. No flashback supplies an objective picture of the disputed
borrowing, and no camera takeover is needed to hear a telling.

## HOME-015: the horses are found before the answer is

**Question:** Can the young heir find what happened without treating suspicion
as permission?

Two expected remounts have not reached the household. The same two horses can
be found through different approaches: an introduction at the public gate,
the service gap, or the raised overlook and ramp. Finding them resolves the
physical search while leaving their delay unexplained. The tally must still
be brought home and heard read aloud.

The gate carries the recurring image. On approach it is a boundary and a
choice. On return it becomes part of Buddh's own account: the gatekeeper let
him through, or he entered without asking. The report does not give the
quartermaster knowledge of an unseen messenger. It puts the route admission
in Buddh's words, followed by the retained reading of the tally.

The physical yard includes separate horse and tally locations, a visible
seal and matching cord marks on both mounts. Its screens interrupt sight;
the existing observers also distinguish hearing, seeing and identification.
A report has to pass to the duty runner and physically reach the post. One
reserve then visits the reported location and returns. These are existing
bounded encounter mechanics, not an omniscient alert or an endless pursuit.

The new task presentation follows the actual remaining action: introduction,
horse inspection, sealed tally, or return to the quartermaster. Secondary
explanation recedes during movement. Labels appear near the yard, and the
other household task panels yield while the investigation is active. A short
exchange after the report answers the natural question, “Should I bring them
back?” Finding the horses finishes Buddh's part; the adults' collection is
not simulated and no horses or money are awarded.

**Review route:** finish the inquiry, hear the household allowance, and settle
any active cargo, outing or other conflicting responsibility. Accept the
remount inquiry from the quartermaster. For the introduced route, speak to
the western market handler and present his introduction at the yard's east
gate. Examine both horses and take their sealed tally, then return and give
the account. Compare this with entry through the service gap and the overlook.
For a separate local-knowledge check, approach the duty post before and after
an actual witness report arrives. Try returning with only one required
observation and resume the unfinished search.

The yard remains an authored compressed prototype within the current district.
It is not a surveyed historical private yard. The walking routes, observers,
props and local report are playable staging; finished architecture, expressive
keepers, tether behaviour, horse idle performances and final sound remain
production work. The player retains ordinary camera and movement control.

## One Home, retained sources

The opening now inherits the remount chapter, which inherits oral memory,
which inherits the current riding and workshop Home chain. The two optional
substates share that world's clock, economy, bodies and manual-save path.
Manual loading uses the active model type so riding skills, workshop state,
received stories and the remount investigation can coexist. The original early
checkpoints retain their existing boundaries: restoring one removes both later
story domains, together with other progress made after that checkpoint. A remount investigation
reserves the relevant household activity until its report; an optional rope
conversation does not create a competing mission clock.

Local choices are tied to the conversation that offered them. Execution
rechecks the relevant physical contact, and restoration validates the received
records and encounter agents before accepting the candidate world. The
integration replaces neither the current district fabric nor the whole Home
controller with the older draft branch.

`borrowed_rope.v1.json` is retained byte for byte from its source draft. Its
digest binds the saved transmission records. Original scene framing lives in
`memory_direction.gd`; it does not rewrite received testimony. The remount
testimony and observation text likewise remain separate from the new
`remount_direction.gd` presentation. Retelling preserves source ancestry;
hearing an echo does not create another independent witness.

These explicit fictional episodes do not establish that either incident
occurred. The wider game's attributed legends and contested stories remain
available under their existing treatment. This increment adds no historical
family accusation and removes no myth because its citation is unresolved.

## Qualification and next review

Local Godot 4.5.1 qualification:

| Check | Passed / failed | Scope |
| --- | --- | --- |
| Oral memory current Home | 149 / 0 | Full input/collision route through hearing, inspection, comparison, recollection, save/load and both retellings. |
| Remounts | 201 / 0 | Three completed physical approaches; actual witness, messenger and reserve journeys; local report and aftermath. |
| Rope/remount integration | 157 / 0 | Explicit composition fixtures: queued contact/occlusion, pause, one HUD, saves, earlier checkpoint rollback, content rejection and retained riding practice. |
| Beginning guidance | 480 / 0 | Current Home guidance, mounted and household transitions. |
| Riding training | 106 / 0 | Actual complete three-skill lesson and practice through the expanded Home controller. |
| Bazaar story | 160 / 0 | Existing three outcome journeys and optional friend exchanges in the expanded district. |

That is **1,253 targeted passing native checks**. Nine structural and six oral
source checks also pass; the ledger, workflow syntax and preservation of all 33
planned narrative-direction blocks were checked. The full repository suite was
not rerun. The inherited bazaar test still emits an ObjectDB shutdown warning,
with no script errors.

The integration check produced 22 native captures; the separate remount
renderer produced eight. Desktop and actual 800×450 layouts were inspected.
The remount renderer uses declared poses and one explicit overview camera;
its captures are not claimed as a recorded player-camera journey. Source IDs
remain in saved records while remembered-story headings use readable speaker
names. A display-only refresh passed 101 overlapping checks and refreshed six of those
22 views after that polish; these checks are not added to the total above.
Automated qualification does not establish first-time human comprehension.

The human review should ask:

- Can a first-time player distinguish the quartermaster's memory from the
  trader's reported story, without consulting the technical source fields?
- Does the neighbour feel like a person receiving a story, and does the chosen
  retelling produce the response the player expected?
- Can the player find the rope, leave during recollection and return without
  interpreting the wait as a broken interaction?
- Do the three yard approaches suggest different social choices before entry?
- After finding the horses, does the player understand why the tally still
  matters and where its contents were learned?
- Can the player recover the current task after an interruption, and does the
  quiet walk home leave room for the discovery to register?

These questions guide pacing and clarity; no measured improvement in attention,
engagement or comprehension is claimed. **HOME-017: A Funded Instructor** stays
in integration preparation. Its economy composition, shared-session exclusions
and secondary character view need qualification before its interruption and
resumption story is developed in this Home chain.
