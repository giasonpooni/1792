# The Words Between Us

Development pass for **HOME-001 / HOME-002** in the mission ledger.

The opening now leads from exploring the yard to a small responsibility: deciding
how to carry two imperfect accounts to another person. The courier carried a note;
the steward can read it; neither establishes who is on the road now. The player
can ask another question without receiving an omniscient answer.

## Play

Use Begin in the integrated branch and play or skip its opening presentations.
In Home, finish the walking/look prompts, collect the sealed message, hear the
courier and hear the steward. Both original accounts are required, in either order.

Speak to the steward **again with E**. Face him on foot from nearby clear ground.
Choose:

- **Carry the uncertainty to the trainer:** walk to the practice trainer and report.
- **Question the courier first:** walk back to the courier, ask what he actually saw,
  then walk to the practice trainer and give the fuller account.

The second route receives an original clarification: the courier heard hooves but
saw no faces. The trainer receives the account only when the player physically
returns and speaks. The journal remembers the decision, the clarification if heard,
and the delivered report. Repeated telling creates no extra reward or corroboration.

Leaving a conversation is allowed. Riding, sparring and tracking remain available;
this errand does not impose another tutorial lock. An unfinished errand stops being
offered once the return-path attack begins. Its existing memories remain; it does
not silently complete or reveal a culprit after the attack.

## Narrative and presentation

The steward's seal, the courier's turn back toward the question, and the trainer's
lowered practice weapon are original textual stage directions in the conversation.
They are not new character animations. The current world, characters and camera
remain the integrated prototype. The objective display follows the chosen physical
route and returns to the existing lesson after the report.

The local consequence is a different received account and an attributed journal
record. There is no hidden alignment score, additional money, fictional commander
identity, guaranteed safe route, or changed historical outcome. More elaborate
performances and later dramatic callbacks belong to subsequent development passes.

## State and validation

`opening_message` is an optional record in the existing Home snapshot. Unstarted
and older saves need no added field. Its bounded receipts use the existing childhood
tick and project their journal lines from the original authored rules. Full-world
load/checkpoint rollback removes later decisions and reports together.

The scene admits only buttons from its active conversation and rechecks range,
standing contact, facing, physical/model position agreement and collision visibility
when a queued choice executes. A newly inserted obstruction can refuse the action.
The model separately checks prerequisites, order, local range and saved receipts.

Native verification targets:

```sh
godot --headless --fixed-fps 60 --path game --script res://tests/test_message_followup_state.gd
godot --headless --fixed-fps 60 --path game --script res://tests/test_message_followup_scene.gd
```

These are also included in the repository's normal native check runner. Execution
results belong to the development PR; commands alone are not proof of a pass.

Local Godot 4.5.1 qualification for this pass: opening state **216/0**, physical
scene journeys **40/0**, inherited childhood **110/0**, inherited aftermath
**166/0** (passed/failed). The scene journeys cover both routes, paused choices,
an obstruction inserted before a queued choice, persistence and the unchanged
lesson gates. The production offer panel was rendered and inspected at 1280×720.
These are automated checks and a visual fixture, not a human playtest or final art.

The optional NET water and smith manifests now include the new rules dependency
and bind current source bytes. Their source-closure checks pass; this is not a new
external NET execution or a replacement for an earlier production receipt.

All new speech, choices, errands and stage directions are original dramatic fiction
within the existing childhood setting. The historical and legendary source policies
in the mission ledger remain unchanged.
