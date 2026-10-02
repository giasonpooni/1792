# Punjab Chiefs playable recollections

This catalogue extends 1792 with six short spatial recollections drawn from the uploaded *Chiefs and Families of Note in the Punjab*, Volume I, 1940 edition, revised through 1 July 1939. It supplies thirty sequential actions and sixty original dialogue choices. Its authority is local to the recollection: an ending records how the player completed this sequence, not a change to campaign chronology, historical identity or the wider faction state.

The content lives in `game/history/punjab_chiefs_catalogue.json`. Source file identity: `file_0000000040f481f5986ef7b122de871c`. The references below use **printed book pages**, not PDF page indices. The source draws on written material, family testimony, bards and priests. Its legends and retrospective allegations remain available for dramatic use. Original dialogue is never presented as a quotation from the source or Shah Muhammad.

## Playable material

| ID | Recollection and role | Physical actions | Choice consequences | Printed source pages |
| --- | --- | --- | --- | --- |
| `delegation` | **The Wedding Road**; fictional Nakai household runner during marriage negotiations | Inspect the gifts; receive the delegate; escort the delegate to the entrance; hear the rival messenger; report to the keeper | Public evidence versus discretion; kinship versus protection; credit; direct report versus negotiation | 283 |
| `alliance` | **The Unequal Victory**; fictional attendant in the remembered 1785 coalition | Hear a captain; gather a wounded companion; escort them to a crossing; petition the herald; allocate dressings | Recognition, assistance across contingents, and supplies produce different closing accounts of the gathering | 283, 287 |
| `revenge` | **A Stranger at the Threshold**; fictional attendant in Dal Singh's household in the book's 1790 revenge account | Question an arrival; consult a witness; warn the steward; gather a dependent; escort them to shelter | Warning, shelter and testimony change the local response; the recorded fatal revenge remains outside the player's sight | 283, 287 |
| `desi` | **Desi Remembers the Reins**; Budha Singh in an ancestral dramatization | Mount Desi; ride to the first marker; ride at least twelve metres before the far marker; dismount at water; speak to the companion | Patience, care and what the companion remembers give the legendary rider a personal relationship with his named mare | 399–400 |
| `exile` | **What Can Be Carried**; fictional attendant among displaced Ramgarhia followers | Hear the elder; choose an offer from supplies; negotiate hospitality; gather a weary follower; escort them to shelter | Limited commitments, reciprocal obligations, the vow of return and the retained treasure story shape the ending | 429 |
| `well` | **The Water of Bahrwal**; fictional attendant following the narrated legend | Draw brackish water; prepare hospitality; follow the charpai episode; hear the blessing at an exterior threshold; draw sweetened water | Sharing the water or carrying the story changes the final emphasis while retaining the miracle itself | 282 |

The Nakai bride Raj Kaur is distinct from Ranjit Singh's mother, Raj Kaur. Budha Singh's mare Desi is named in the source; the playable route is an original adaptation. The Ramgarhia well-treasure episode and the Bahrwal sweet-water miracle are separate traditions and separate locations. In the Bahrwal telling, Hem Raj carries the sleeping Guru Arjun home on a charpai, the water becomes sweet, and a powerful descendant is promised. The catalogue preserves the complete event in narration without requiring a Guru avatar, impersonation or entry into a religious building.

## Catalogue contract and spatial use

Every recollection has a distinct period, player role, source kind and adaptation note. The opening and spoken lines belong to the dramatic presentation. Source metadata belongs to production and reference inspection. The scene geometry is an intentionally compressed stage, approximately fifty metres across, rather than a reconstruction claiming the real distances between historical places.

Each station has a stable ID, label, prop kind and `[x, y, z]` position. All stations are separated by at least four metres, with positions between x = -10 and 10, z = -14 and 8, and y = 0. The intended player start is `[0, 0, 12]`; Desi waits at `[0, 0, 7]`. Clear paths connect the stations. Decorative geometry must preserve these paths.

Beats are ordered and address stations by ID. An interaction is completed through a choice at the active station. Every choice contains an original response and boolean effects. `requires_flags` names prerequisite true flags. The modes are `interact`, `escort` and `ride`; spatial validation remains the runtime's responsibility and must not be inferred from a dialogue choice alone.

Escort choices set `escort_following: true` in **both** branches before an escort beat. The companion is the preceding NPC target. Delegation, alliance, revenge and exile each require the player and companion to reach the active destination; no branch strands a companion through a missing following flag.

Desi's first interaction sets `mounted: true` in both branches. Its next two beats require riding, and the far-marker beat specifies `min_ride_distance: 12.0`. Both watering-place choices set `mounted: false`. Other sequences never set the mounted flag. The catalogue does not create inventory items: gift inspection, provisions and water are represented by station interaction and local flags.

Endings are ordered. Select the first whose complete `requires_flags` list is true; each sequence ends with an empty-requirement fallback. Choices are unique within their sequence. There are 63 distinct boolean flag names across the catalogue and at most eleven within any sequence. Restore/replay should retain the sequence ID, completed choice IDs and resulting local flags while re-establishing the current spatial state through the existing runtime.

## Cinematic direction

The six scenes share recurring forms: a threshold, someone waiting to be accompanied, an object carried, and an account that changes when repeated. Their palettes distinguish the warm wedding court, muted coalition ground, tense shaded household, open horse ground, subdued exile halt and luminous Bahrwal well. The people and places can recur later with changed significance.

The well's miraculous change belongs to the performed legend. The revenge sequence keeps the fatal event offscreen so that the player's agency concerns warning, care and testimony. Desi's ride gives the ancestor and mare an intimate action rather than only an assertion of legendary prowess. Escort choices allow political pressure to be experienced through the pace and presence of another person.

This document describes catalogue content and runtime expectations. Integration and execution results must be recorded by the scene and test implementation; the catalogue alone does not establish campaign integration or finished cinematic production quality.
