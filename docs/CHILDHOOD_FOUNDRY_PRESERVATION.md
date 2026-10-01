# Childhood slice as a Foundry preservation workload

The existing controllable childhood courtyard, terrain, NPCs, camera, oral
accounts, horse course, sparring, tracking, return attack and save/reload are now
captured by `game/foundry/childhood_slice.gd`. The entrypoint inherits the actual
input-driven journey from `test_childhood.gd`; it does not call its domain pose
fixtures. Production captures 13 named milestones and supplies native snapshots,
received memories and a read-only player perspective projection.

The matching NET recipe is `net foundry childhood`. It runs this game-owned code
on the existing production controller, with a locked source/asset/data inventory,
pinned engine, isolated project and an independent installed acceptance gate.
The game owns its state and movement. NET retains execution/results and evaluates
its declared predicates; it does not supply a second game-state reducer.

`childhood/perspective_view.gd` derives a finite working impression from received
memories only. The journal displays the impression in ordinary character prose.
The weights use authored likelihoods for two hypotheses (`trail_clear`,
`riders_nearby`), with explicitly assumed conditional independence. Their report
ages are retained without decay. They are gameplay tuning, not authenticated
historical probabilities or causal evidence. No culprit identity is inferred.
The derived view adds no save fields or persistent simulation authority.

The existing chronology, source-informed architecture, supplied art assets and
historical manifests remain in place. The locked manifests carry exclusions,
uncertain dates and deferred structures. No exact 1792 geography, full historical
authentication, human art approval or human playability approval follows from
passing a software gate.

The save/reload check caught Godot JSON serialization changes of roughly 1e-17 in
numeric fields. The gate now declares a 1e-12 absolute numeric bound. Identifiers,
received memories and other non-numeric state fields must still match exactly.
The checkpoint rollback is explicit rather than treated as ordinary time flow.

Local qualification uses Godot 4.5.1:
- existing full childhood suite: 110 assertions;
- new perspective boundary suite: 8 assertions;
- Foundry input journey: 50 assertions / 13 observations;
- NET acceptance: 16 independently recomputed predicates.

These are software results. Human hours and accepted playable output per human
hour remain unmeasured. Review this bounded slice before expanding geography or
production packages.
