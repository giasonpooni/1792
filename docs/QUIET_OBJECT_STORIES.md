# Small things worth stopping for

Three optional, original object scenes live in the existing Home territory. They extend the reference-driven direct-craft pass, not NET, the world map, or an industrial workflow.

## Play

After the household inquiry, walk to the low stands near the back verandah. Face an object on foot and press **V** when its local hint appears. **E** retains all existing conversations and tasks. Inspection uses the original paused panel. Leave, load, or open another panel and the inspection copy returns to its starting pose. No equipment is taken.

**Saffron in the fold** sits at `(-10, 0.14, 9)`. The outside of a cloth has faded; the reverse retains its colour. An uneven repair changes thread halfway across. Turn it over or notice the smaller repairs. The palette echoes the user's portrait reference; this is not a historical garment or a new costume unlock.

**The hole that was not used** sits at `(-6, 0.14, 9)`. A patched harness cheekpiece has stretched older holes and one clean unused hole. The rough patch faces outward; the animal-facing side is smoother. Inspecting it suggests the care and adjustment behind an ordinary piece of equipment without attributing it to a documented person.

**A pan with two endings** sits at `(-21.8, 0.14, -14.7)`, beside the market approach. Its polished handle and old patch do not agree with a tale of gold. Invite Mela and Jiva through the existing market conversation, bring both close, face the pan and press V. Mela tells a short fable about an unnamed ruler and a poor woman's pan; Jiva supplies another ending about repair and supper. The player can hear both without choosing which is historically true.

These are original optional micro-scenes, **not three completed biographical missions**. The fable is inspired by the motif supplied by the user, but names no ruler and predicts no event in the protagonist's future. Neither branch records a verified miracle, monetary gift, character-memory fact, or future historical knowledge. The later biographical episode remains separate.

## Reference into craft

The supplied mature portrait directs the adult silhouette and material language: layered warm cloth, ivory contrast, exposed facial character, restrained ornament and worn surfaces. Childhood retains its current age-appropriate appearance. A full mature beard or imperial presentation has not been pasted onto the child. See `PROTAGONIST_REFERENCE_DIRECTION.md`.

The cloth is a two-sided curved mesh, with a deliberately irregular seam, reverse colour and loose edge threads; it is not a texture-only placeholder for the detail. The cheekpiece has a raised patch and small fitting. The pan has a separate underside patch. Turning the object changes the actual visual orientation while the player stays where they stood.

## Boundaries and tests

Only nearby, same-floor, faced and unobstructed objects can open. The selected action checks access again. The pan's two voiced-in-text tellings additionally require both physical companions in contact; there is no disembodied remote speaker. A new obstruction or absent friend invalidates a queued choice.

Three declared static envelopes occupy the visible stands. Existing colliders, capsule sizes, controller, navigation rules, and save formats are unchanged. The inherited navigation rebuild includes the added surfaces. Free movement around the stands is tested in an actual input-driven journey; this is not a claim about every campaign route.

Object rotations and the active page are temporary inspection state. The existing clock pauses, inventory remains untouched, and no reward can be farmed. Once the player returns, the object is where it was found. The `opened_ids` list is only a bounded test observation and never enters saves or selects later story content.

```sh
python tools/run_bazaar_direction.py --godot /path/to/godot
# After the successful object journey, render those observed choices:
xvfb-run -a /path/to/godot --path game --rendering-method gl_compatibility \
  --audio-driver Dummy --script res://tests/render_quiet_objects.gd
```

The new journey has one completed-inquiry setup and then uses movement, V and actual menu callbacks. Wrong-floor, late-obstruction and absent-friend cases are explicitly separate adversarial fixtures. Render close-ups replay the retained choice with an inspection camera: they are not concept images or evidence of a new playthrough. No voice recordings, eye/face likeness reconstruction, final cloth simulation or physical-GPU performance claim is made.

## Direct-craft questions

Do players notice the repair before the explanatory text? Does the reverse colour make the cloth feel kept rather than decorated? Do the two pan stories make Mela and Jiva more distinct? Can players leave without feeling they skipped a mandatory collectible? Automated checks cannot answer those questions; human playtests remain unperformed.
