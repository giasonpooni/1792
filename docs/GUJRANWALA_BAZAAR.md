# Gujranwala: the store and the bazaar

## Playable scope

Continue in **1792 · Buddh Singh · Home territory**. Finish the inquiry and receive
the existing allowance. At the western market, E → Hear provisions buyer → Hear
this watch's offer. Walk into the household store (the chamber at the back-right
of the courtyard), face its packing station and press E. Pack four existing food
portions, carry them to the market, and settle for six **household** coins. Or
return the lot to the store. The default packing choice preserves the next food
reserve. When it cannot, an explicit second choice accepts the shortfall risk.
The next-watch reserve uses current workers and guards; later recruitment, an
extra watch or another dispatch can still exhaust it.

The sack is visible while carried. Walking and running are capped at 3 local
metres/second; the original cautious pace remains lower. Mounting is refused
until the lot is sold or returned. Menus pause the existing clock. No second
clock, ledger, inventory owner or game entry is introduced.

Unpacked offers expire when the existing supply watch changes. Packed terms are
honoured across a watch, so the player is not punished with a vanished offer in
transit. The buyer purchases at most one lot per settlement watch and has a
finite initial purse of 96 coins (sixteen lots), never replenished by this slice.
The buyer's received food and payment balance are retained. This is a bounded
repeatable trade opportunity, not an unbounded simulated town economy.

## Coupled choices

Packing removes actual food from home stock. Carried food does not feed workers
or guards during upkeep; that can stop construction or leave a garrison unready.
Returning it can change the next watch's outcome. Grain processing and the mill
still need labor, raw inputs, wages and storage. Selling opens storage but risks
food reserves. Payment enters the existing household treasury, never Buddh's
private purse. Buying four food costs eight coins, selling returns six: a
buy/resell transaction is not free income. Production can create a trade margin
only by consuming the original inputs and work watches.

There is one provisions carrier: the earlier delivery's cargo and the new packed
lot cannot coexist. Escorting the original caravan while carrying is allowed;
the speed cap and distance requirement still apply. Return requires four free
store units and never silently discards cargo on refusal.

## Research boundary

The existing selected **biased Latif 1891** account supports the household's
military/storage function. The newly consulted **Gazetteer of the Gujranwala
District 1883-4** describes local produce markets (printed pp.60-61), varying
measures (p.62), and Gujranwala's collection of food grains from surrounding
villages alongside pottery and metalware (pp.83-84).

That is a late colonial comparison, not a survey of childhood Gujranwala. The
preface describes a compilation using older reports; the town passages include
railway and municipal institutions. None are projected into 1792. We read
metadata and selected Archive OCR passages, not all original page images or the
numeric tables. Damaged OCR is not used to convert weights or calibrate prices.
The source record and its feature link are in the existing
`game/territory/settlement/gujranwala_research.json`, readable under O.

The store, buyer, scale prop, packing bench, quantities, demand, money and pace
are authored. Food portions are not kilograms, coins are not modern INR, and a
supply watch is not a historical day. This does not enlarge the 56 × 56 metre
home cell or claim a reconstructed 1792 street plan. No source image, modern
asset or private conversation text is shipped.

## Engineering

The existing `misl` substate gains an optional `trade` record with profile
`bazaar-provisions.v1`. Absent in old saves until an offer is actually heard.
`misl_rules.apply_transaction` dispatches original operations or the new pure
bazaar transition; `replay_full` reconstructs both from the SAME ordered economic
receipts. Live operations stage both records and commit them together. Validation
checks their exact replayed shapes/values, watch alignment, buyer identity,
receipt budget and incompatible mounted/cargo states before replacement.
No generated acknowledgement is proof of physical travel or authenticated
anti-cheat: scene proximity/facing/occlusion and input-driven tests provide the
separate runtime checks. The original 256-receipt scenario limit still applies.

`bazaar_state.gd` extends the road authority; `bazaar_chapter.gd` extends the road
scene. One inherited active world, one player and one original physics executor.
The player's optional `travel_speed_limit` defaults to infinity; prior movement
is unchanged without a caller cap. Props add no collision and are not inventory.
The inherited store walls, door and roof supply the real collision geometry.

F5/F9 use `user://1792-bazaar-v1.json`. J/F1 explicitly imports the preceding
narrator/road save; all older import options remain. Load restores cargo and the
original world together; checkpoints discard later offers, money and memories.
The narrator remains a separate presentation transcript. Hearing terms gives
attributed speech, not literacy. The stable protagonist, antagonists, faith,
Mahan endpoint and Lahore stories are unchanged.

## Qualification

`test_bazaar.gd` adds domain and malformed-save fixtures, finite buyer conservation,
reserve-sensitive staffing/construction branches and two real input-driven routes
from an explicitly completed-inquiry setup. After launch those routes use no
pose/progress injection. Both include mid-route save/load and actual sprint-cap
checks. `render_bazaar.gd` is a separate set of clearly labelled visual fixtures,
not a human playthrough. Every inherited suite remains enabled in `run_checks`.
Read the PR's exact revision/results rather than treating this document as a pass.

No new combat, water task, town expansion, final art, controller profile, regional
streaming or multi-language runtime is claimed. Concurrent water/neighbourhood/
remount and Mahan branches remain separate; no automatic merges occur.
