# Service equipment study

Copyright (c) 2026 Cartesian Graphics. All rights reserved.

Open **Equipment study · sword, scabbard, shield and helmet** from the existing
main menu. The upper slider draws and resheathes the two swords; the lower slider
turns the display. Keyboard arrows, Home and End work on focused sliders. R resets
the view; F1 returns to the menu. The menu scrolls on shorter windows so existing
entries remain reachable.

The same modules attach a sheathed sidearm, round shield and domed helmet to the
existing Home gate guard. This is a procedural art prototype. It adds a readable
equipment silhouette to the existing figure, not a combatant or inventory system.

## Geometry and attachment

The blade, crossguard, grip and pommel share one rigid `Sword` root. The dark
scabbard has its own root, cover, throat, two suspension bands/rings and toe fitting.
It remains attached while the sword moves. The service and fitted studies share
blade geometry; their fittings use different surfaces. Decoration supplies no
damage or rank multiplier.

The blade follows a circular centreline with authored radius 1.12 m and angle
0.78 radians: an arc length of 0.8736 m. Extraction rotates the sword about that
circle's centre, preserving the centreline of the portion still inside the sheath.
The slider is a reversible pose parameter. `SHEATHED`, `DRAWING` and `DRAWN` name
inspection poses, not saved actions, timing, hand IK or physically solved contact.
Full-width blade/sheath clearances and manufacturing feasibility are not qualified
by this centreline test.

The shield has a dished front/back shell, rim, four bosses and separate back grips.
The helmet has a rigid dome, rim and finial. Mail and its deformation are deferred;
there is no cloth substitute pretending to simulate mail.

All dimensions are authored working values, not measurements extracted from the
photographs. Physical mass, balance, inertia, cutting behaviour and historical
attribution remain uncalibrated. The two reference images are identified by content
hash in [the intake record](../data/art/service_equipment.v1.json). Their pixels,
inscriptions and detailed ornament are not distributed with the game.

## Existing authority

The guard's three equipment attachments add no passage record. The current gate
contract remains **seven records**, including the two sparse crossing figures.
Equipment supplies no collision, navigation, knowledge, access permission,
reputation, combat decision, campaign receipt, clock or save field.

Mesh AABB corners transformed into world space are checked against the existing
1.9 m half-width passage and ground plane. This qualifies the authored static
attachments; it does not qualify dynamic riders, crowd avoidance or weapon contact.

The same change repairs the earlier cart/pack invariant: `sample()` no longer
rotates either resting object. Full transforms, non-identity rotation/scale and
rewound ticks are checked. Cloth retains the existing motion channel.

## Execution and review

`tools/run_checks.py` includes `test_service_equipment.gd` and the strengthened
gate suite. The Home-art workflow retains four actual engine views: sheathed,
partially drawn, drawn, and equipment on the live Home guard. The capture checks
different scene pixels across the draw poses and unchanged campaign/player state
while inspecting Home. Source commit/tree and image hashes accompany the captures.

The renderer proves execution, not final art acceptance. Procedural silhouettes,
simple surfaces and the blockout guard still require artist and human play review.
The shield and sword remain distinct components for later attachment to an actual
character rig without replacing the game's state or movement authority.
