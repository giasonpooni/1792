# Bazaar attention performance — faces look before they talk

This pass develops **eye-line, head attention and blinking** as direct character craft.

It deliberately does **not** create a perception or relationship system.

## Principle

The game already knows current body positions, dialogue speaker, encounter phase and existing combat receipts. From those facts, presentation can derive a short-lived attention target:

```text
authoritative geometry / receipt
          ↓
transient attention target
          ↓
head + eye presentation
          ↓
discard
```

No new memory, observation, testimony, suspicion score or relationship value is created.

## Staging

- A speaker generally looks toward Buddh.
- A listener looks toward the current speaker.
- During the challenge, Mela and Jiva attend to the lead challenger.
- During fighting, they track an active opponent.
- Active challengers attend to Buddh.
- On the walk home, attention returns toward Buddh/group movement.
- Buddh's presentation head follows the current speaker, nearest active opponent, or friends during decompression.

Supporting figures also receive asynchronous deterministic blinks. Blink timing is visual only and is not saved.

## Bounds

Head yaw/pitch are deliberately small. Eye spots move only a few centimetres on the prototype face. These constraints prevent the presentation layer from producing impossible full-body turns or becoming a substitute for authored animation.

The player and NPC root bodies are never rotated or moved by the attention pass.

## Limits

This prototype can establish that characters stop staring straight ahead. Production quality still needs sculpted faces, eyelids/eyeballs, facial blendshapes, authored gaze holds/aversions, breathing, performed facial animation and human review at conversational distance.

The terminal can regression-check the authority boundary; it should not certify acting quality.
