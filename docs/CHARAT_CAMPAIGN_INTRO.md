# Charat Singh family opening

Choosing **1792 · Buddh Singh · Home territory** opens an authored early-childhood recollection: Maha Singh sits with a very young Buddh/Ranjit Singh and tells him about his father, Charat Singh. The existing playable Home follows after the story is completed or skipped. The opening does not select an exact conversation year or child age.

This is a procedural seated scene with readable original dialogue, closer father–child framing, restrained gestures and attention, and short camera/page transitions. It has no recorded voice performance or full cinematic animation. The figures are presentation proxies, not authenticated likenesses. The dialogue is not a historical quotation or evidence that this conversation occurred.

The scene reuses the courtyard's credited material treatment on 54 explicitly grouped presentation meshes: plaster, timber, woven mats and costume cloth. Skin and facial details retain plain materials. The observable material projection records the reused resource paths and source/license metadata without adding geometry or collision.

## Story and sources

The ten pages cover Charat's relationship to the child; Desan Kaur and the Gujranwala household; Chenab/Sialkot in 1761; Gujranwala's relief in 1761; Kup and the Vadda Ghalughara in 1762; Kasur in 1763; Sirhind in 1764; the Sutlej fighting in 1765; Jhelum/Rohtas in 1767; and the Jammu gunburst, loss and Desan's stewardship during Maha's minority.

The [research ledger](../data/history/charat_campaign_intro_sources.v1.json) retains source URLs, printed-page locators, disagreements, and the SHA-256 and byte counts of all four supplied reference uploads. It separates admitted campaign summaries from 25 candidate details. The exact two-horse/four-matchlock feat attributed to Maha remains part of the separate riding-training story; this opening does not transfer it to Charat.

The earlier Sarbuland capture/ransom and the later Jhelum/Rohtas campaign are distinct episodes. The opening avoids joining them. It leaves Charat's conflicting birth/death years unresolved, does not choose between Desan's mother/stepmother descriptions, and avoids exact casualty totals. Kasur's taking and plunder are stated directly. The Sutlej page retains repeated attacks and withdrawal without asserting a clean victory or a categorical final defeat. Located collective Sialkot actions and a retrospective Rohtas captive anecdote remain research candidates; their supplied cinematic choreography and speeches are not authenticated.

## Controls and return

| Control | Action |
| --- | --- |
| Next / Right / Enter / Space | Advance a page; the final page offers Continue to Home |
| Previous / Left | Return to an earlier page |
| Skip / Escape | End the opening and begin the playable Home |

The story owns an isolated SubViewport and World3D. The original Home remains in-tree with its model, art, collision bodies, poses and clocks retained. Its processing, drawing, CanvasLayer visibility and audio are parked, then restored. Completing or skipping the opening changes only the local presentation marker; no save schema, capability, inventory, journal knowledge or historical authority is granted. The stable trainer's completed riding lesson still owns all three riding unlocks. The later fixed-ending father retrospective remains separate.

`HomeLaunch.enter()` enables the production opening. `HomeLaunch.make_world()` constructs an inert Home for tools and existing fixtures. Late entry, overlapping riding visits, incomplete completion and changed retained authority are refused. A rejected return restores the story buttons so the visit can be retried. Removing Home releases the session; unexpectedly removing only the session restores the surviving Home's rendering, audio and input ownership without granting progress.

## Native verification

`test_charat_campaign_intro.gd` checks identities, page order, dialogue fit, navigation, completion/skip and retry behavior. `test_childhood_intro_session.gd` exercises the production launch, retained Home identity and authority, separate world, frozen bodies/clocks, mixed visibility and audio flags, real pointer routing at different window sizes, return guards and teardown. Existing riding, save, childhood, workshop, art and fixed-interlude suites remain in the full check runner.

`render_charat_campaign_intro.gd` produces four 1280×720 engine images: father and child, Kup recollection, family closing and returned Home. Story frames use the actual production story camera and UI after the ordinary transition settles. The Home frame uses the production camera after ordinary physics ticks let its SpringArm settle. The manifest records the exact unchanged authority at the return boundary separately from those resumed Home ticks, PNG and RGBA hashes, page and dialogue identifiers, actor identifiers, camera/gesture metadata, renderer and device. These automated frames are not a human playtest. CI retains them alongside the six riding-training images, eleven early-lesson frames and fourteen full opening-route frames described in [the beginning sequence](BEGINNING_SEQUENCE.md).
