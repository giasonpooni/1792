# 1792

**Build outward from home.**

A historical open-world game in development, following **Buddh Singh** from the
Sukerchakia home territory toward command and state-building. Travel, personal
relationships, incomplete information and competing household obligations matter
before large armies or empire management.

The player knows himself as Buddh. In the authored later campaign, other
characters address him as **Ranjit Singh**, formally **Maharaja Ranjit Singh**.
The timing of that public-name switch is a narrative convention, not a finding
that the historical childhood renaming occurred at accession. Internal
`ranjit_singh` references remain stable. [Naming policy](CHARACTER_NAMES.md).

**Early playable greybox, not a finished historical reconstruction.** There are
no production character models, finished cities, full combat system, or complete
childhood-to-Lahore campaign.

## Start playing

Import **`game/project.godot`** into standard **Godot 4.5.1** and press **F5**.
No Python, .NET, Bevy, NET service or scientific provider is required to play.

| Menu entry | Current gameplay |
| --- | --- |
| **1792 · Buddh Singh · Home territory** | Childhood training, oral accounts, an ambush, a protection agreement and inquiry, then a small Gujranwala supply/production loop. |
| **Lahore · Command story** | Separate fictional 1801 sandbox: assign a patrol, play or delegate its captain, investigate and receive a delayed report. |
| **Lahore · Houses and rivals** | The same command loop with a house dispute, a rideable horse, visible companions, follow/hold orders and physical return. |

The Lahore scenes are development sandboxes, not chronological shortcuts that
complete the childhood story. Their captain, envoy, missions and geography are
fictional placeholders.

## The home chapter

**Learn the yard → hear a letter read aloud → ride → guard and counter →
track quarry → survive the return-path ambush → investigate → report home.**

The tutorial teaches movement through ordinary childhood activities. Tracking
currently means examining traces, approaching quietly and observing stationary
quarry—not projectile hunting or harvesting.

After the attack, hear the courier and steward, then approach Raj Kaur. Accept
a household guard and bring him to the bend and back, or undertake the inquiry
alone and accept a strained household relationship. The trace does not identify
a culprit. Neither choice establishes that a named household organized the attack.

Checkpoints before the ambush and before the aftermath allow retrying an attempt.
**R** restores the last checkpoint, including its earlier memories and decisions.
Later information is not merged into an earlier attempt.

[Childhood walkthrough](CHILDHOOD.md) ·
[Aftermath and checkpoints](AFTERMATH.md) ·
[Perspective](NARRATIVE_PERSPECTIVE.md)

## Gujranwala: earn, provision, build and meet obligations

After completing the household inquiry, speak to the quartermaster near the
middle of the yard. He releases a **limited household operating allowance**, not
unrestricted imperial funds. Your personal purse and household coffers remain
separate balances.

Carry four food portions to the west-side market, then escort a physical
returning carrier to the home store. Leave through the courtyard's open front
and take the western lane. Stay within nine metres of the carrier: it stops
when you leave it behind and never teleports to catch up.

Use the market to buy supplies or a personal satchel. At home, hire workers or
garrison guards, commission a mill, storehouse or palisade, and attend the
household meeting. **B** presents the quartermaster's oral accounts and forecast.

| Choice | Coupled consequence |
| --- | --- |
| Hire workers | More labor, but additional food and wages every supply watch. |
| Hire guards | Visible garrison posts and provisioned readiness, but recurring upkeep. They are not combat escorts. |
| Start construction | Coins, timber and tools are committed; workers build **instead of** processing grain. |
| Build a mill | Higher processing rate, still limited by grain, labor and storage. |
| Build storage | More capacity, after materials and labor-work are supplied. |
| Run short of food or wages | Production/construction can stop and guard readiness falls. |
| Run short of fodder | The existing horse loses its faster gaits until a later provisioned watch. |
| Miss the meeting | A one-time household-standing penalty. |
| Buy a satchel | Personal funds are spent; the delivery earns a small handling premium, not duplicated cargo. |

A supply watch is **7,200 existing physics ticks / 120 seconds of play**, not a
historical day. Resting at home advances the same clock and settles the same
obligations; resting is blocked while the return caravan is active.

Prices, recipes, capacities, social deltas and wages are **authored game units**.
The two finite contracts pay once. There is no infinite mission-money loop.
The palisade changes the visible structure; siege defense is not simulated yet.

The home landscape is a seeded **56 × 56 metre compressed test container**:
retained tutorial/escort lanes, shallow field relief, a market and production
yard, with farmland scenery beyond the boundary. It is not surveyed Gujranwala,
a historical Misl border or streamed Punjab. Current group navigation remains
a bounded flat-lane profile.

[Home territory and economic rules](GUJRANWALA.md) ·
[Coupled campaign direction](COUPLED_CAMPAIGN.md)

## Controls and saves

| Control | Action |
| --- | --- |
| WASD / Shift / mouse | Walk, run and look |
| F | Mount / dismount near the horse |
| W / A / D while mounted | Forward / steer |
| Shift / Ctrl while mounted | Canter / walk |
| S / Space while mounted | Brake |
| E | Speak, inspect or interact |
| Q / left click in childhood | Guard / counter |
| C in childhood | Quiet approach |
| B in home territory | Oral supply accounts |
| G | Household guard or patrol follow/hold, where available |
| J / F1 | Childhood journal / pause |
| H in Houses and rivals | Antagonist codex |
| F4 in childhood | Optional peripheral framing |
| F5 / F9 | Save / load current profile |
| R in childhood | Restore checkpoint |

Menus pause both motion and the scenario clock. The peripheral option changes
presentation, not knowledge or health. It is not a medical visual-field model,
and no progressive eye-loss or alcohol mechanic is attached to the child.

The new home profile uses **`user://1792-gujranwala-v1.json`** and a separate
checkpoint sidecar. Old childhood/aftermath saves can be read by the new loader
without inventing an allowance or completed contracts. Older checkpoints replace
the whole later session, including economic progress.

Lahore profiles retain their separate slots and import controls. Invalid loads
are staged and rejected before replacing the running session. Windows save
replacement and hardened duplicate-key parsing remain unqualified.

## Lahore patrols and house conflict

At the command table, choose a scouting or patrol allocation, then play the
captain or delegate. Switching preserves the same order, resources and positions.

In **Houses and rivals**, Sada Kaur's fictional estate petition determines whether
the patrol recognizes a local claim, asserts disputed authority or observes only.
Protection of a road does not automatically annex its villages.

Press **G** after assigning a package to muster companions before departure.
The allocation includes the captain: scouts add one visible trooper; the larger
patrol adds three. They travel on foot. Follow/regroup and Hold do not teleport
them behind a cantering horse.

Securing the outpost requires the captain and at least two troopers present, as
well as an appropriate commission. Return with everyone and check in on foot.
Resources remain reserved until check-in and the delayed report releases the
original riders once. Without mustering, the earlier abstract patrol remains.

[Commands](COMMAND_STORIES.md) · [House dispute](HOUSE_CONFLICT.md) ·
[Riding](RIDING.md) · [Companions](COMPANIONS.md)

## People, perspective and the fixed past

Raj Kaur, Sada Kaur, Mehtab Kaur, Datar Kaur, Moran and Jind Kaur are **NPC
antagonist biographies**, not alternative protagonists. Antagonist means competing
objectives; a useful ally or patron need not become a permanently hostile enemy.
Their source notes and chapter presence remain explicit. Only the existing
Raj Kaur aftermath and Sada Kaur petition have interactive conflicts so far.

The political frame is **houses, clans, estates, patronage, promises and command**,
not religious enemy teams. A surname is not a universal allegiance.
Personal faith and remembered speech are part of Buddh's perspective. Obtaining
a letter does not reveal its contents; hearing two versions does not prove either.

Before the eventual Lahore campaign, the planned Mahan retrospective has a fixed
ending: **Mahan dies; Buddh succeeds; the story revisits Buddh's beginning and
returns to the suspended present**. The sequencing/preservation contract is
implemented. Father missions, reprise scenes, the 1797–1798 world and its actual
scene router are **not yet playable**. No retrospective loot or private knowledge
is transferred into Buddh's present. [Interlude contract](MAHAN_INTERLUDE.md).

## Architecture and scope

Godot owns the current active world and gameplay. Blender is the intended asset
authoring environment. Bevy and Notations Engineering Terminal remain optional
future simulation/development integrations, not required dependencies.

The optional home-economy record extends the existing `world-state.v1` childhood
authority; it does not create a competing save, clock or treasury. Its ordered
receipts reproduce the numerical ledger. Actor IDs, horse ownership, reports,
observations and execution state remain distinct. Legacy gameplay defaults remain
unchanged when the new economy is inactive.

The long-term campaign connects earned income, raids, contracted service,
equipment, ammunition, repairs, food, fodder, transport, infrastructure, meetings,
intelligence and adult court/health/delegation systems. Those are development
targets, not capabilities implied by this prototype.

Our design muses include *Prince of Persia*, *Red Dead*, *Saints Row 2*,
*Elder Scrolls*, *GTA*, *Victoria 2*, *Assassin's Creed*, *The Witcher*, *Far Cry*,
*Splinter Cell* and *Shogun/Total War*. They are aspect-level inspirations, not
affiliations or borrowed proprietary assets. [Design references](INSPIRATIONS.md).

## Develop and verify

```sh
python tools/check_project.py
python tools/run_checks.py --godot /path/to/godot
```

The runner executes every inherited suite plus the home-territory checks.
CI also retains source snapshots, logs and software-rendered captures.
A successful numerical or scene test is not human playtesting, a physical-GPU
benchmark, or proof that the historical model is accurate.

```text
game/       Godot gameplay, scenario state, procedural cell, assets and tests
data/       Original historical-start fixture
schemas/    Retained interchange contract
docs/       Walkthroughs, narrative/source policy and engineering boundaries
tools/      Structural and engine checks
```

Latif's *History of the Panjab* (1891) is the selected **biased narrative account**.
Documented history, attributed accounts, reconstruction, gameplay abstraction and
fictional connective material remain distinct. Authoring an antagonist does not
verify every allegation about a real person's private motives.

[Historical sources](HISTORICAL_SOURCES.md) ·
[Historical method](HISTORICAL_METHOD.md) ·
[Game design](GAME_DESIGN.md)

**Make one small journey and its obligations work before building all Punjab.**
