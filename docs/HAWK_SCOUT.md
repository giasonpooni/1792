# Hawk scout v1

The Home chapter now has a bounded **third-person hawk scouting prototype**. It is a gameplay perception tool, not a second player, a second clock, or a historical claim that Buddh/Ranjit Singh used a trained hawk as an aerial reconnaissance system.

## Controls

| Input | Hawk operation |
| --- | --- |
| **X** | Release the hawk / return to Buddh |
| **WASD** | Fly relative to the hawk heading |
| **Shift** | Faster flight |
| **Space / Ctrl** | Climb / descend |
| **Mouse** | Turn the hawk and pitch the chase camera |
| **E / left click** | Tag the best hostile currently inside the hawk view with clear line of sight |
| **Esc** | Return to Buddh |

The Home chapter refuses release while mounted, during the immediate ambush/caught state, during the active bazaar confrontation, while carrying the workshop load, or while drawing/carrying water.

## Physical envelope

The first implementation is deliberately local:

- maximum horizontal radius from the release point: **52 m**;
- altitude envelope: **5–24 m above the release point**;
- normal flight: **11 m/s**;
- fast flight: **17 m/s**;
- passive glide: **3.2 m/s**;
- vertical rate: **7 m/s**;
- aerial tag range: **42 m**;
- tag view threshold: dot product **0.72**;
- tag lifetime: **1,800 existing chapter ticks / 30 seconds at 60 Hz**.

Flight is clamped to that envelope and checks collision along each movement segment. It does not stream a larger Punjab map or imply that the current compressed Gujranwala cell is geographically complete.

## Observation semantics

A tag is admitted only when:

1. the target is registered as scoutable and currently visible;
2. the target falls inside the hawk camera's bounded view cone and range;
3. the hawk has direct physics line of sight to the target.

The initial Home integration provides two **fictional distant scout contacts** behind the household sightline and also registers the existing **Unknown Assailant**. The distant contacts are deterministic projections of the existing chapter tick; they add no second clock or persistent enemy ledger. Future hostile actors may join the **hawk_scout_hostile** group and provide **hawk_scout_id**, **hawk_scout_label**, and optional **hawk_scout_height** metadata without modifying the flight controller.

A successful tag stores the target identity, last observed world position, observation tick, and expiry tick.

The marker stays at the **last observed position**. It does not follow an enemy through walls after contact is lost. Re-observation can refresh the marker.

This is intentionally different from omniscient wall tracking: the hawk extends the protagonist's observation surface, while the game still distinguishes observation from continuing truth.

## Authority boundary

While scouting:

- Buddh's authoritative body remains where it was;
- player-body input is disabled and restored on return;
- the existing chapter clock continues;
- the hawk does not write campaign state, money, relationships, inventory, journal entries, or mission receipts;
- aerial tags are transient runtime observations and are **not saved**;
- applying/restoring campaign state clears transient tags, so checkpoint/load cannot carry future reconnaissance backward;
- returning restores the original player camera.

The runtime metadata declares **classification = authored-gameplay-scouting**, **historical_claim = false**, **save_authority = false**, and **observation_semantics = transient-last-seen**. This keeps the sensor/execution identity separate from the campaign state authority.

## Current visual status

The bird is an original procedural proxy assembled from simple Godot meshes. It exists to qualify camera, flight, line-of-sight, input isolation, tagging, and return behavior. It is not production hawk anatomy or animation.

The next art step can replace only the bird presentation while preserving the same runtime interface and observation rules.

## Verification

The native **game/tests/test_hawk_scout.gd** suite checks radius and altitude bounds, front-vs-rear view admission, bounded last-seen lifetime, attachment to the current composed Home chapter, player-input/camera handoff, campaign-state isolation, clear-line-of-sight tagging, no live tracking after target movement, occlusion refusal, clock-based expiry, and restoration of the original player camera and input.

Run it through the retained full suite with:

    python tools/run_checks.py --godot /path/to/godot
