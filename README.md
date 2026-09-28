# 1792

**Grow from a young heir in the Sukerchakia heartland into a commander and state builder — without leaving the world behind.**

1792 is an early historical open-world game project centered on **Buddh Singh**, the character
known publicly as **Ranjit Singh** after accession in our campaign. The long-term
experience combines horseback travel and personal relationships, close-range exploration and
infiltration, contested local territory, and larger military campaigns. House and clan rivalries,
estate claims, patronage and personal obligations drive the political world, rather than
sorting its people into religious enemy teams.

**This is not a finished game.** The repository contains small Godot prototypes that we can build,
play, test and improve one at a time. There are no finished historical environments or character assets yet.

## Play the childhood opening

The existing **1792 · Buddh Singh · Home territory** menu entry now opens a short
playable childhood chapter on the retained home scene:

**Find your bearings → hear a message you cannot read → ride → guard and counter →
track quarry → survive an ambush on the return path.**

WASD and mouse introduce movement and looking. E acquires the courier's sealed
message, then hears the courier and steward separately. F starts the riding lesson
on the same horse controller as the Lahore prototype. Q guards a telegraphed
practice blow; left-click counters. C enables a quiet approach on the hunting trail.
Those inputs remain usable in the return-path encounter. This is tracking and a
bounded guard/counter/escape prototype, not a complete hunting or melee system.

**Buddh's inner identity, reliance on remembered speech and incomplete knowledge
are central.** The journal retains who said what and when; receiving a report does
not confirm it. A survival outcome does not reveal a mastermind. An optional quiet
reflection beneath the courtyard tree introduces faith as personal grounding,
not a combat or hidden-knowledge bonus. These are authored portrayals.

J/F1 opens the journal and pauses; F5/F9 uses a separate childhood save. F4 disables
or enables the mild peripheral visual framing without changing gameplay state.
The chosen historical account describes eye loss in early childhood, not an
established progressive-blindness schedule. The shader is subjective presentation,
not a medical model or half-screen blackout. Keyboard/mouse is the tested input;
controller mapping is not implemented yet.

The three exercise gates and compressed hunting trail are fictional, as are the
speakers, trainer and anonymous attacker. Three unguarded hits end the attempt;
load a manual save or return to the menu to restart. **Save before the return bend**
until automatic checkpoints are implemented. This chapter does not yet transition
into the Lahore campaign, whose existing systems remain intact.

[Childhood controls and scope](docs/CHILDHOOD.md) ·
[Narrative perspective](docs/NARRATIVE_PERSPECTIVE.md) ·
[Selected historical accounts](docs/HISTORICAL_SOURCES.md) ·
[Inspirational aspects](docs/INSPIRATIONS.md)

## The protagonist's name

**Buddh Singh** is the player-facing name. Before accession, characters address him as
Buddh Singh; afterwards they use **Ranjit Singh**, or **Maharaja Ranjit Singh** in formal
court dialogue. The 1792 home nameplate and the current Lahore HUD use Buddh Singh;
the fictional Lahore envoy uses the post-accession court address. Other characters retain
their own names. This changes presentation, not identity: saved `ranjit_singh` references,
orders, relationships, horses and companions remain bound to the same person.

The timing is an **authored campaign convention**, not a claim that the historical
renaming happened at accession. The name tradition places the change by his father
in childhood. The present Lahore development scenes explicitly use the later address;
there is no accession mission or automatic calendar-driven name change yet.
See [Naming policy](docs/CHARACTER_NAMES.md).

## Run it

Import **`game/project.godot`** into the standard Godot editor and press **F5**.
The reference test target is **Godot 4.5.1**; no Python, Rust or external service is needed to play.

The opening menu offers three development entries:

| Prototype | What is there |
| --- | --- |
| **1792 · Home territory** | A childhood tutorial composed onto the original scene: oral accounts, riding, guard/counter practice, tracking and a return-path ambush. |
| **Lahore · Command story** | A separate, fictional 1801 sandbox: assign a patrol, play its captain or delegate, visit two locations, make a decision and receive a delayed report. |
| **Lahore · Houses and rivals** | Ride the household horse, negotiate an estate petition, muster a small companion patrol, give follow/hold orders, visit the outpost and return together. Six antagonist biographies remain in the codex. |

The Lahore sandboxes do **not** replace the childhood opening or assert that their invented missions
actually happened. Their captain, envoys and compressed geography are placeholders, not reconstructions.
Houses and rivals extends the existing command implementation rather than duplicating its simulation.

## First command story

Walk to the courtyard table and press **E**. Assign the four-rider patrol, interact with the table again,
and choose **Play as the captain**. Follow the road to the village, press E to gather information,
then continue to the outpost. Organize a patrol or withdraw. The result changes local security and
the captain's relationship with Lahore, and a delayed report returns to Buddh Singh.

You can also delegate the same order or take control partway through. Switching does not reset
its allocation, progress, character positions or world clock. A completed story cannot repeatedly award resources.

## Ride the first route

Choose **Lahore · Houses and rivals**. There is one household horse beside the hitching rail
on the right of the courtyard. Walk close and press **F** to mount. Ride through the open end
of the courtyard and follow the dirt road to the village and outpost, or turn around and ride home.

**W** moves forward, **A/D** steer the horse, **Shift** requests a canter, and **Ctrl** requests
a walk. **S** or **Space** brakes; releasing W also slows to a stop. The mouse orbits independently.
Stop on clear ground and press **F** to dismount. A wall, blocked landing or airborne horse prevents
dismounting. The horse has acceleration, speed-dependent turning and world collision; it does not strafe.

Both Buddh Singh and the player-controlled captain can use the same horse. **The horse stays where it
is left.** Dismount before handing control to the captain or back to Buddh Singh. Delegated patrols still
travel on foot; the horse does not follow them, appear at their destination, or create extra riders.
At the village/outpost, dismount and use **E** for the original encounters and house consequences.
Without mustering, the original abstract patrol still returns the viewpoint on resolution.
A **mustered physical patrol** instead keeps you as captain for the return journey; check everyone in
at the courtyard before the report is delivered.

**F5/F9** save/load horse position, facing, speed and rider together with the current patrol and house
decisions and mustered companions. This version uses a separate companion-patrol save slot.
**F1** offers explicit imports of earlier riding, house-conflict and command-story saves; it never
invents already-deployed companions or overwrites those older slots.
The horse and rider are procedural blockout shapes, with a simple leg swing—not finished models or animation.
See [Riding](docs/RIDING.md) for rules, checks and the next gaps.

## Lead a small patrol

In **Houses and rivals**, assign a package at the command table, then press **G** and choose
**Muster allocated companions** before departure. Scouts provide the captain plus one trooper;
the four-person patrol provides the captain plus three. Mustering consumes no additional riders,
coins or supplies. The companions are currently **dismounted soldiers**, not mounted cavalry.

Take the captain's viewpoint. **G** opens **Follow / regroup** and **Hold position**. Troopers
walk around static obstacles and remain where you leave them on Hold. Regroup within 30 metres;
there is no teleport catch-up when the captain canters away on the household horse. You can also
delegate: the captain and companions then move physically along the same road.

Visit the village, then the outpost. Securing it requires the captain and **at least two troopers
physically present**, plus a commission that allows securing the road. Choosing an outcome commits
the field decision, but **does not yet settle the mission or release its resources**. Return with
all companions to the courtyard, walk around the command table, dismount if riding, press **E**,
and choose **Check patrol in**. The report is compiled at check-in and delivered four game minutes
later; only then are the original riders released. Delegation can complete this return too.

The outpost decision is still a menu encounter, not combat. The physical patrol uses the same
house/territory consequence rules as the older abstract patrol. Neither annexes land. Earlier
saves retain the earlier loop; muster is opt-in before departure, not a fourth demo or a new game.
See [Companion patrol](docs/COMPANIONS.md) for save, movement and scope details.

## Houses, rivals and biographies

In **Houses and rivals**, press **H** for the antagonist codex, or access it through the command
table. Raj Kaur, Sada Kaur, Mehtab Kaur, Datar Kaur, Moran and Jind Kaur are NPCs, not selectable
protagonists. Each profile has an authored objective, source note and chapter presence. An antagonist
can be a useful patron or ally while opposing a particular decision; not every profile starts hostile.

Only **Sada Kaur's fictional estate petition** has an interactive conflict in this first slice.
At the table, hear the envoy and choose a commission. Recognizing a local revenue claim enables
a cooperative patrol. Asserting Lahore's authority creates rivalry and military presence without
settling local legitimacy. Deferring permits observation and withdrawal, not securing the road.
Buddh Singh can reconcile the disputed commission before the captain resolves it.

The same manual/delegated patrol rules apply. Political results reach the journal with the existing
messenger report, not before. Neither military presence nor an agreement automatically annexes land.
The codex intentionally includes earlier/later story profiles; this is a development roster, not six
finished character campaigns. See [Houses and rivals](docs/HOUSE_CONFLICT.md) for scope and contracts.

| Control | Action |
| --- | --- |
| WASD / Shift | Walk / run |
| Mouse | Orbit the third-person camera |
| F | Mount / dismount in Houses and rivals |
| E | Interact or open the captain's field menu |
| G | Muster and companion orders in Houses and rivals |
| H | Antagonist codex in the Houses and rivals entry |
| F5 / F9 | Save / load the current sandbox (separate save slots for each entry) |
| F1 | Return-menu controls |
| Escape / click world | Release / recapture the mouse |

Decision menus pause the sandbox. The first slices have a simple delegated policy, not general commander AI.
The Lahore encounter is still a choice interface; **its combat, mounted companions and autonomous faction plots are not implemented yet**. The childhood entry has a separate bounded practice/escape encounter, not a general combat system.
See [Command stories](docs/COMMAND_STORIES.md) for the original walkthrough, persistence rules and limitations.

## Where the game is going

The main story starts from a small familiar home territory. Travel, local knowledge, companions,
relationships and contested roads should matter before large armies or administration enter play.
Greater power adds responsibilities without removing the ability to walk or ride through the world.

Later, Lahore becomes a command hub. Buddh Singh remains the main character, while smaller playable
stories follow subordinate commanders. Their decisions affect the same campaign world instead
of becoming disconnected missions. Documented commanders and expeditions will be added after
their dates, command relationships and sources have been checked. The proposed Tahal Singh
Chhachhi line is not yet substituted for the fictional captain.

The design references are the embodied world of *Red Dead*, personal traversal and infiltration
from *Assassin's Creed*, local territorial struggle from *Saints Row 2*, and campaign command
from *Shogun: Total War*. These are inspirations, not implemented feature claims or affiliations.

## Keep the technology behind the game

**Godot** owns gameplay and the current world state. **Blender** is the intended asset-authoring
pipeline. **Bevy** is reserved for simulation workloads that justify a separate runtime.
**Notations Engineering Terminal (NET)** can later provide external experiments, inspection,
replay tooling and validation. None of those future integrations is required to start these prototypes.

The command slice extends the existing `world-state.v1` record with a `command-story.v1` profile.
The house slice adds a versioned `house-conflict.v1` substate to that same authority; the original
command code and world schema remain unchanged. Orders, controlled characters, antagonist NPCs,
groups, source notes and reports have separate identities. Manual and delegated execution share
consequence rules. The optional `riding.v1` record belongs to the same campaign state; Godot physics
submits mounted poses through that authority. The optional `companions.v1` profile holds allocated trooper IDs, positions, orders and return progress
inside that same state. House, clan, misl and religious institution are not synonyms.

## Develop and test

```sh
python tools/check_project.py
python tools/run_checks.py --godot /path/to/godot
```

The structural checks run without Godot. Runtime checks require the engine and must not be
reported as passed when it is absent. The runner executes the original command suite, the house/reporting
suite, riding rules, companion round-trip physics, character-name checks and the childhood input-driven tutorial/encounter suite. CI also captures software-rendered screenshots. Inspect actual CI results;
[the earlier evidence note](docs/VALIDATION.md) covers the original command slice, not an automatic
pass for new code. New results are recorded against their tested commit in the pull request.

```text
 game/          Godot project, gameplay, sandbox data and engine tests
 data/          Original historical-start fixture
 schemas/       Existing interchange contract
 docs/          Design, historical method and implementation notes
 tools/         Structural and engine test runners
```

## History and scope

**Syad Muhammad Latif's _History of the Panjab_ (1891)** is the selected **biased
narrative account**, not an omniscient or “unbiased” authority. Selected OCR passages
and metadata were consulted for childhood illness, education and the hunting-return
ambush. Other nominated court, Punjabi literary, colonial and modern scholarly
accounts remain a reading programme with explicit consultation limits; see
[Historical sources](docs/HISTORICAL_SOURCES.md). The game's inner dialogue is original.


Separate documented history, attributed historical accounts, reconstruction, gameplay abstraction
and invented connective material. Antagonist characterization is the game's authored portrayal,
not certification of every allegation about a historical person's private motives. The supplied Raj
Kaur account remains referenced in her biography; no death scene is implemented in this slice.
The prototype's quantities and outcomes are game rules, not measured historical facts.
See [Historical method](docs/HISTORICAL_METHOD.md) and [Game design](docs/GAME_DESIGN.md).

**Build outward from home.** Make one small journey and its consequences work before building all Punjab.
