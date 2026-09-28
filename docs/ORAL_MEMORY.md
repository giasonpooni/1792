# Oral memory: hear, explore, compare and retell

**Implemented prototype:** one original fictional episode, **The borrowed rope**, inside the existing Home territory entry. It extends the researched Gujranwala chapter, not a separate game or replacement world.

This is a sakhi-inspired **transmission mechanic**, not an authenticated traditional sakhi. The project is exploring how situated listening, reflection and retelling can carry narrative meaning in play. The prototype does not establish that living sakhi traditions are dying or extinct, and does not claim a measured dopamine, retention or educational effect.

## Play

Open `game/project.godot` in Godot 4.5.1 Standard and choose the existing **1792 · Buddh Singh · Home territory** entry. Complete the original childhood encounter and household inquiry. A household allowance is **not** required for this story; the existing allowance, trade, caravan and water tasks remain available.

1. Face the quartermaster and press **E**. Choose **Listen to the quartermaster's rope story**.
2. Walk out through the open front of the courtyard, then west to the market. **E** at the trader offers another account.
3. Inspect the rope peg beside the stable, on its east side. The visible rope establishes wear and repair, not who borrowed it or why.
4. **F7** opens remembered stories. Compare the two received accounts. Nothing is revealed just by opening the panel.
5. Return to the quartermaster and ask for a further recollection. After **300 existing active ticks** (five seconds at 60 Hz), return and choose to listen. Time alone never grants the answer; menus pause the original clock.
6. Speak to the neighbour southeast of the well. Hear their transmitted version, retell the quartermaster's account with its source, or pass on both accounts without erasing their disagreement. The listener's response changes only after receiving your telling.

The order is not mandatory: the rope or neighbour's version can be discovered first. Repeat reading is available through F7/J and adds no evidence or reward. **E** remains a local action; facing, range and actual character-eye collision rays are checked again when a queued action executes. F7/J are memory views, not grants of literacy.

**F5/F9:** `user://1792-oral-memory-v1.json`. This separate slot protects the earlier integrated save. J explicitly imports `1792-gujranwala-v1.json`, replacing the whole current session. Previous childhood imports and original checkpoint rollback remain. Restoring old state discards later accounts, retellings, money and water progress together. No sidecar save or competing clock exists.

## What is implemented

Four received tellings share two **reported** source roots. The quartermaster's first account and later reflection share one root. The trader and neighbour share another because the latter repeats the trader's reported source. These counts do not estimate truth, calibrated independence or confidence. Repetition is a new transmission, not automatic corroboration.

A material trace, explicit comparison, requested-but-unheard recollection, source-bound retelling, and listener memory are part of the same append-only receipt stream. The story has no canonical-truth flag and no XP, money, troop, faction or map reward. Its authored payoff is a changed account, a question that becomes available, and what the next listener can now repeat. The moral interpretation is not reduced to a correctness score.

Shah Muhammad's captions are **original English development narration**, not quotations, translations or historical verse. They observe received-story milestones without writing to Buddh's knowledge. Later inherited allowance/delivery/return cues remain eligible. Loading silently rebinds presentation rather than replaying old narration.

## Implementation and ownership

| File | Responsibility |
| --- | --- |
| `game/narrative/oral_memory/borrowed_rope.v1.json` | Explicitly fictional episode, speakers, variants, source lineages and trace limits |
| `memory_rules.gd` | Bounded admission/replay, source ancestry, local sites and content validation |
| `memory_state.gd` | Optional `oral_memory` in the inherited `_state`, existing saves, discovered-only views and listener projection |
| `memory_chapter.gd` | Existing E/menu/physics dispatch, actual eye rays, F7 memory view and original procedural props |
| `game/narrative/shah_observer.gd` | Read-only retrospective presentation, including later inherited cues |
| `game/childhood/home_launch.gd` | Selects the extended controller on the unchanged original PackedScene |

The existing Godot authority remains the only writer. C++/Rust/Python/Julia architecture is not replaced or replicated: Python checks and CI observe this provider, and any later NET/provider adapter must call this admitted operation boundary. No new external service or per-frame scientific runtime is introduced. The separate political/social-field, bazaar, road and neighbourhood draft branches are **not** silently merged or represented as jointly tested here.

### Save contract

`oral_memory` has exactly `schema`, `model_id`, `content_digest`, `origin_tick`, and `events`. It is absent until the first successful observation/hearing. Original dialogue bytes are bound by their SHA-256; changed content fails closed instead of rewriting old remembered speech. The content cache is per process; restart after authoring changes. A future content migration requires an explicit versioned mapping, not deletion of the digest check.

Each receipt retains an ordinal, existing world tick, operation kind and operation identity, subject, parent receipt, canonical actor ID and local position. Retellings reference previously received telling/comparison receipts. Recall references the actual request. A staged candidate is checked before promotion; invalid commands and invalid loads do not partly mutate the world. The 32-receipt ceiling bounds this first pack; replay publishes no partial projection. Position and timeline consistency is **not** signed-save authenticity or proof that a fabricated save represents actual play. Scene-level visibility is rechecked live; old visibility is not reconstructed from a cryptographic sensor proof.

The player view contains only received tellings, inspected trace, performed comparisons and retellings. `oral_view().receipts` provides the known receipt nodes; retelling edges reference those nodes. The full source catalogue, unused text and developer hashes are not player knowledge. The listener has a separate derived received-telling state, not access to the protagonist's entire memory.

The audit separates model, operation, execution, content evidence and verification identities. Test receipts are synthetic validation observations, not historical evidence, a proof certificate, or evidence of a human playtest.

## Verification

```sh
python tools/check_project.py
python tools/check_reconstruction.py
python tools/check_oral_memory.py
python tools/run_checks.py --godot /path/to/Godot_v4.5.1-stable_linux.x86_64
/path/to/godot --headless --fixed-fps 60 --path game --script res://tests/test_oral_memory.gd
```

`.github/workflows/oral-memory.yml` uses the existing checksum-pinned Godot 4.5.1 reference. It runs every inherited native suite plus new content and native checks, then captures four actual software-rendered views. The existing command-story workflow remains unchanged and separately reruns its inherited rendered fixtures. CI retains the exact source archive, commit/tree, logs, oral receipt digest and screenshots for 14 days. Check the actual workflow results before claiming execution succeeded.

The new journey starts from a labelled **completed-inquiry fixture**, then walks through the real scene using movement input, E, actual button signals and collision. There is no subsequent pose/progress injection. It tests a newly inserted physical occluder against a queued hearing, modal pause, both accounts, material inspection, comparison, delayed recollection, save/load rollback and local retelling. Separate domain fixtures cover tampered order/time/ancestry/content/actor/location, replay, detached views, old saves, duplicates, source-root conservation, and coexistence with water and economy. Render fixtures explicitly use staged presentation poses and are not the input-driven test.

## Deliberate limits

This is one fictional, English-text episode with fixed situated speakers and one local listener. It is not a populated oral culture, localized/recorded performance, source-backed historical corpus, general rumour diffusion network, automatic oral-history generator, calibrated social model, or a complete city. The visible rope is an original procedural prop, not an archaeological reconstruction. Narration and NPC text need editorial and cultural review before release; no living religious authority or historical poet is claimed to have supplied this original text.

The next expansion should add a reviewed source-backed story pack and another concrete transmission route, while retaining the distinction between source account, authored adaptation, simulated event, character belief and player-facing interpretation. Engagement and learning need actual playtests; no biometric data is collected by this slice.
