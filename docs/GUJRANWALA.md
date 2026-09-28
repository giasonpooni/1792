# Gujranwala home territory and supply loop

## What this increment actually adds

The existing childhood entry now uses `territory/gujranwala_chapter.gd`, a subclass
of the retained home director, with a `gujranwala_state.gd` subclass of the same
aftermath authority. No second active world, clock, resource account, or menu demo.

The opening lessons, ambush and protection inquiry must finish first. Afterwards,
visit the quartermaster at `(3, 0.14, 5)` and accept a **limited household operating
allowance**. This does not make the child an emperor or give him every royal coffer.
There is no chronological leap, accession or father-story bypass.

The current terrain is a compressed **56 × 56 metre test container**, NOT the
city of Gujranwala at geographical scale. It retains the original courtyard,
training and hunting anchors, adds a market outside the west wall, a production
yard, seeded shallow field relief, roads, drainage scenery and an agricultural
horizon. No large-map streaming or historical river alignment is implemented.
The fixed outer walls are test boundaries, not claimed Misl borders.

## Play

E at the quartermaster: hear the allowance, take four food portions to market,
hire workers or garrison guards, commission construction, attend a timed household
meeting, settle arrears, or rest to the next supply watch.

Walk through the courtyard's open front, turn west along the lane, and reach
the market at `(-24, 0.14, -15)`. E delivers the cargo and makes a return-caravan
assignment available. Bring that physical caravan to the home quartermaster.
It stops if the escort is more than nine metres away. No teleport catch-up.
The current caravan is one dismounted carrier, not a finished wagon simulation,
and the journey has no hostile encounter yet.

Market E also buys food, fodder, grain, timber, tools, or a personal satchel.
B displays the quartermaster's oral accounting, and pauses simulation. The
readable interface is not a claim that Buddh reads. F5/F9 save/load this whole
profile. J/F1 retains the old journal and checkpoint functions.

## Actual couplings

Each supply watch is **7,200 existing physics ticks (120 seconds at 60 Hz)**.
This deliberately accelerated accounting cadence is not a calendar day and
not a second clock. The old scenario calendar is unchanged.

- Human food requirement: protagonist + workers + garrison.
- Wage requirement: workers + twice the garrison.
- Horse fodder requirement: two portions for the already present household horse.
- Unpaid wages become arrears. Short food or wages halts construction/production.
- Provisioned, paid guards contribute to garrison readiness. They are visible
  stationary posts, not additional free escort soldiers or implemented battle AI.
- Unmet horse fodder at the last watch caps that horse at a walk until a subsequent
  provisioned watch. Buying feed alone does not instantly claim it has been consumed.
- One worker-pool either constructs the queued project or converts grain into
  food. Extra workers improve rate but add food and wage obligations.
- A mill doubles the declared grain-processing rate. Input grain and storage
  space still limit production; no inputs means no output.
- A storehouse increases capacity from 48 to 80 aggregate game storage units.
- A palisade uses 36 coins, six timber, one tool and six labor-work units.
  Its visible extension does not establish a simulated siege-defense advantage yet.
- A meeting opens at watch 2 and must be attended before watch 5. Missing it lowers
  the local household-standing counter once. This is a fictional household meeting,
  not an authenticated reconstruction of a particular Misl council.

Purse and household treasury are distinct balances within the SAME ledger. Hires,
bulk supply and works draw the allowance. A personal satchel costs personal coins.
Contributing ten personal coins to coffers is explicit; private withdrawal is not
implemented. Prices, packages, recipes, quantities and social deltas are authored
balancing units, not historical rupees, observed wages or physical mass balances.

Two finite contracts pay once. Delivered food leaves the source store before
departure; the returning caravan adds its retained cargo only at check-in and
only when storage can accommodate it. The satchel earns a declared handling
premium on the delivery, not duplicate cargo.

## Determinism, data and identity

`misl_rules.gd` owns pure economic transitions. `gujranwala_state.gd` submits events
after location/role checks and only commits successful candidate transitions.
The optional `misl` record contains the versioned cell/seed, activation tick,
bounded receipt history, derived ledger and physical merchant pose.
It is contained in the same inherited `_state`.

Save validation replays the ledger and checks watch alignment and action order;
tampering with a balance alone does not produce a valid save. This is consistency,
not save authentication or a complete anti-cheat system. Recorded location claims
are not cryptographically proven. No provider-selected code is executed on load.

The seed and generator version identify the authored asset; the manifest retains
a same-runtime vertex digest. FastNoiseLite / engine revision remain part of
reproduction. No cross-platform bitwise generator equivalence is claimed.

Legacy childhood/aftermath saves import without creating an allowance or events.
Older checkpoints intentionally replace the entire later state, including any
subsequent income and learning. Saves have a separate `1792-gujranwala-v1.json` slot.
Duplicate-key hardened JSON and Windows atomic replacement remain unqualified.

At 256 economic receipts this bounded scenario stops further economic play and
requests a new run. No unbounded campaign/persistent economy is claimed.

## Geometry and execution boundary

The local field mesh uses 961 vertices / 1,800 triangles and a collision mesh.
Authored lesson, caravan and escort lanes remain flat. Existing AStar collision
sampling remains a flat-route profile; this is not a general sloped-terrain or
agent-specific navmesh implementation. The player can traverse the shallow
field relief, while prototype test walls retain the original finite envelope.
Backdrop trees, fields and drainage are visual only.

The existing horse and patrol agent gain optional speed caps with their original
defaults. All previous workloads keep their settings. Current Godot owns movement
and collisions. No C# geometry library, private scientific source, NET runtime,
Bevy runtime, GPU solver, shader pack or external data service is added.

## Remaining systems

Raids, enemy caravan combat, full trading markets, bought/remountable reserve horses,
doctors, mounted garrisons, medical treatment, ammunition/reload/repair mechanics,
field artillery, spies, adult court households, succession and aged-character
delegation remain future systems. See `COUPLED_CAMPAIGN.md`. This increment does
not silently simulate these through an undifferentiated “resources” counter.
