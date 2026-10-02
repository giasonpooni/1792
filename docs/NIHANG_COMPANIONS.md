# Childhood Nihang companions

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

This branch adds a small authored outdoor camp to the existing playable Home.
The camp elder and two riders are fictional childhood acquaintances. Their names
in code identify roles, not newly authenticated historical people. They retain
their familiar forms of address as Ranjit's public title changes.

## Play

Open `game/project.godot` in Godot 4.5.1 Standard and choose Home territory.
Complete the first household riding gate. The original household lessons and
intro remain available. Visit the northeast camp, beside the existing practice
ground (local elder position 19, 0.14, -18). These are compressed game coordinates,
not a historical map location.

1. Dismount, face the elder and press **E**. Greet the elder and familiar riders.
2. Approach the veteran's horse to the east, on foot. **E** opens the tack and
   horse-care conversation. This teaches through dialogue; it awards no combat
   stat or advanced riding skill.
3. Return to the elder and invite the veteran alone or both riders. The first
   household riding gate is required. Concurrent cargo or another outing blocks
   acceptance. Each rider remains attached to the camp, outside household payroll.
4. Mount the original household horse with **F**. Ride with the escort to the
   north practice marker (3, 0.14, -25). Press **E** while mounted when everyone
   is nearby; the veteran must be within unobstructed calling distance.
5. Return to camp, stop, dismount and wait for the escort to park. Speak to the
   elder to finish. Everyone must physically return. The undertaking can also be
   ended unfinished at camp with everyone present.

This first outing is finite and available once per run. The camp remains after
completion. There is no gold, troop, skill or loyalty-point farming. Earlier
saves can restore the whole prior run. Follow the HUD's ordinary lesson prompts
to continue the existing childhood sequence after the outing.

## Relationships and identity

`ranjit_singh` remains the sole protagonist identity. `character_names.gd` adds
a relationship-aware address function; it does not change ordinary public
address or the existing chronology policy. The established camp elder uses
**Buddh**, the veteran uses **Little rider**, and the companion uses **Buddh**.
The English moniker and all dialogue are original authoring, not historical
quotations or verified Punjabi speech. Only those established relationships use
the exception. A newly encountered Nihang does not inherit intimacy by affiliation.

The resolver preserves the exception before and after accession, including formal
contexts. The playable encounter currently occurs in Home's childhood period;
there is no new adult scene or chronological jump in this increment.

## State and execution

The optional `nihang_camp` extension lives on the existing Home state. It holds
received event records, a derived agreement phase, selected actor IDs, and two
current mount poses. The same `childhood.tick` drives it. Old saves supply no
invented acquaintance, escort or testimony. F5/F9 and the existing checkpoint
store preserve the extension; restoring an earlier run discards later agreements.

Both mounted companions use the existing `horse.gd` motor, collision and observed
motion. The existing navigator gains optional hull-clearance dimensions with
unchanged defaults for walking actors. The scene submits one group motion sample
per advancing Home tick. No follow teleport, extra horse inventory, independent
clock or second treasury is created. Companion bodies avoid static obstacles;
as with existing friendly projections, they do not resolve mutual crowd collision.

Dialogue is rechecked against the actual body position, ground and line of sight
at execution. Turnaround requires the selected riders; check-in requires every
invited rider, on the ground and stopped at camp. Historical evidence, gameplay
operation, native execution and test verification remain distinct. Event replay
checks internal consistency; it is not save authentication or proof that arbitrary
user-supplied event records describe a physically executed route.

## Evidence and scope

The user's approved design establishes childhood familiarity and this mentorship
relationship as authored reconstruction. A particular Gujranwala Nihang camp,
its placement, instructors and conversations have not been historically verified.
No gurdwara is invented or opened for entry. The existing view-only religious-site
policy is unchanged. The outdoor figures and props are original procedural studies,
not final researched dress or architecture.

Background consulted on 2 October 2026:

- [Encyclopaedia of Sikhism: Army of Maharaja Ranjit Singh](https://eos.learnpunjabi.org/ARMY%20OF%20MAHARAJA%20RANJIT%20SINGH.html): describes the later Akali formation's autonomy and Ranjit's use of personal influence. This informs negotiated accompaniment; it does not establish childhood instruction.
- [Encyclopaedia of Sikhism: Phula Singh Akali](https://eos.learnpunjabi.org/PHULA%20SINGH%20AKALI%20(1761-1823).html): its chronology places his move to Amritsar in 1800. This branch does not make him a childhood Gujranwala mentor.

Mercenaries, specific outlaw bands and local kinship contingents remain additional
recruitment paths for subsequent work. Their occupation, affiliation, kinship,
obligations and conduct must remain separate attributes. Thuggee-associated content
requires specific period/geographic evidence; it is not implemented as a generic
religious assassin class. No whole clan is acquired by hiring one leader.

## Verify

`test_nihang_camp.gd` covers refused/duplicate invitations, first-gate eligibility,
relationship address across accession, unrelated speakers, malformed and future
events, selected-roster movement, save/load, whole-world rollback and checkpoint
compatibility. Its native journey starts from one explicitly declared first-gate
fixture, then uses walking/riding inputs, E/F, actual buttons and F5/F9. It also
adds a wall after opening a conversation to test stale-menu refusal.

```sh
godot --headless --fixed-fps 60 --path game --script res://tests/test_nihang_camp.gd
python tools/run_checks.py --godot /path/to/godot
```

Set `NIHANG_CAPTURE_OUTPUT` to an existing directory and run the same journey in
a graphics-capable Godot session to retain an executed homecoming screenshot and
whole-world snapshot. Test slots are separate from the player's save. Native
renderer verification does not establish finished art or human playtest quality.
