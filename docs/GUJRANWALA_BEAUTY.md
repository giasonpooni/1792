# Gujranwala beauty study — depth, color, shade and lived material

This increment improves the existing compressed Home scene as **direct art craft**. It does not add geography, collision, rooms, quests or historical authority.

The design problem is not “more props.” It is making the same verified space feel layered, beautiful and inhabited at walking distance.

## What is added

The reversible beauty layer adds:

- eight shallow painted spandrels across the long veranda;
- six jali-like screen studies kept flush to existing side-wall faces;
- four perimeter planting tubs with restrained broadleaf studies;
- five hanging textile drops beneath the veranda;
- four warm threshold lights that remain dark in daylight and stay deliberately low in golden hour/evening;
- eight small stone accents around the existing household well;
- six low roofline finials to break the long silhouette.

All additions are presentation meshes/lights only. There are no new CollisionShape3D or StaticBody3D nodes.

## Art direction

The reference corpus supports a visual grammar, not literal reconstruction:

**lime plaster + faded warm pigment + deep green/indigo cloth + old timber + worn stone + planted shade + warm evening thresholds**

The scene should gain beauty through:

1. **depth** — screens, textiles, plants and repeated openings create near/mid/far layers;
2. **material contrast** — plaster, timber, stone, cloth and leaves should read differently at a glance;
3. **controlled color** — pigment appears in shallow architectural fields and cloth, not as universal saturation;
4. **shade** — occupation and visual richness stay strongest at edges and thresholds;
5. **irregularity** — existing memory anchors, repairs and threshold habits remain more important than decorative uniformity;
6. **light progression** — daylight remains architectural; golden hour adds warmth; evening reveals small threshold pools rather than turning the courtyard into a festival.

## Historical boundary

The painted bands, screen studies, planting arrangement, textiles, lamps, well accents and finials are **original authoring studies** informed by the provenance-tiered corpus.

They do not establish:

- exact 1792 Gujranwala colors;
- exact jali patterns;
- exact planting species;
- documented household lamps;
- surveyed well masonry;
- measured roofline ornament.

Period-nearer evidence may later replace individual motifs without changing the gameplay state or spatial envelope.

## Relationship to Hand-worked Lives

The beauty layer must not wash out the small authored irregularities already established:

- mismatched repairs;
- polished thresholds;
- replacement wood;
- drain repairs;
- tether wear;
- measuring marks;
- plaster patches;
- habitual shaded work;
- empty waiting places.

The rule is:

```text
beauty increases
without
erasing material memory
```

## Lighting

The layer follows the existing F7 art-study presets rather than creating historical time.

- **daylight:** threshold lights off;
- **golden hour:** very low warm light for depth only;
- **evening:** bounded warm pools at four thresholds.

The game clock, sun state, save data and calendar remain untouched.

## Qualification

Run:

```sh
python tools/run_checks.py --godot /path/to/godot
```

The dedicated suite checks the exact bounded inventory, absence of collision/static physics, reversible art switch, clock-driven cloth motion, bounded preset lighting, and unchanged campaign state/journal/player body.

Passing establishes a functioning reversible art layer. It does not establish historical truth, final beauty, hardware performance or human artistic approval.

The next aesthetic pass should be visual review of actual captures at walking height, followed by more careful façade silhouette, ground-edge breakup, plant form and night-value tuning rather than simply increasing object count.
