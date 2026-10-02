# Gujranwala depth and patina pass v1

This increment extends the visual quality of the already-playable Gujranwala Home territory
without adding gameplay authority.

The first beauty pass improved the immediate courtyard. This second pass is about **depth**:
the scene should read as one inhabited fragment of a larger settlement rather than an isolated
decorated box.

## Added

- 20 low wall-top parapet rhythm segments on the existing perimeter;
- 4 small pavilion/chhatri-like **silhouette studies** above or behind the perimeter wall;
- 8 selective wall-patina patches;
- 4 high household cloth pieces and two visual lines;
- 8 distant foliage masses;
- 4 distant opening panels that remain dark by day and gain warm emission in the existing
  golden-hour/evening F7 presets.

These are presentation studies. No named palace, sacred structure or measured historic
building is asserted.

## Composition goals

### Break the box

The compressed Home territory necessarily has enclosing walls. The new roofline rhythm gives
the eye something beyond the wall plane:

```text
near courtyard detail
    ↓
wall / parapet rhythm
    ↓
small pavilion silhouette
    ↓
distant foliage
    ↓
sky
```

That creates depth without creating another traversable district.

### Selective patina

A uniform dirt layer reads procedural. Patina is deliberately sparse and asymmetric:

- one low wall area reads darker/older;
- another patch sits higher;
- patch size and position vary;
- no rule says every wall must receive identical aging.

The intent is to suggest maintenance, moisture, hand-work and repainting over time.

### Household softness

High cloth pieces break hard masonry lines and add very small tick-driven motion. They remain
above ordinary body height and are not interactive.

### Distant evening warmth

The distant pavilion openings stay dark in daylight. Golden hour and evening introduce warm
emission only; they do not create new lights, occupants or rooms.

## F7 ownership

This layer belongs to the same reversible authored-courtyard presentation system as the first
beauty pass:

- greybox/earlier-art comparison removes it;
- authored refinement restores it;
- daylight/golden-hour/evening presets drive the distant openings;
- hanging cloth and foliage sample the existing chapter tick;
- there is no second timer and no shader TIME.

## Physical and state boundary

The layer adds no:

- CollisionShape3D;
- StaticBody3D;
- NavigationRegion;
- gameplay water;
- economy;
- inventory;
- journal;
- knowledge;
- receipts;
- clock;
- save state.

The perimeter wall and existing qualified courtyard collision remain authoritative.

## Historical boundary

The visual corpus supports roofline rhythm, pavilion silhouettes, screened/ornamented depth,
aged plaster and planted skyline interruption. This pass uses those ideas as art direction.

It does **not** establish:

- exact 1792 Gujranwala skyline;
- exact chhatri/pavilion placement;
- exact historic plaster deterioration;
- exact household laundry practice;
- exact species or planting.

Period-nearer evidence remains necessary before final reconstruction claims.

## Why this remains direct craft

A generator can produce parapet, patina and roofline variants. Direct art direction decides:

- which wall remains quiet;
- where skyline interruption is useful;
- which patch is left uneven;
- how much warm light is enough;
- where soft cloth breaks the composition.

That is the kind of beauty decision the control plane should preserve, not originate.
