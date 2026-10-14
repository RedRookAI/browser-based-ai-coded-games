# TV Robot Godot port — QuickTicket plan

Outcome: a faithful playable Godot version of the CURRENT active TV Robot sandbox, delivered separately from the existing JavaScript game. This is not a movement-only demo.

Primary implementer builds player, creatures, integration and export. Overseer plans, audits and independently tests; defects return to the primary implementer. Use separate Git branches, and do not overlap edits to the same game files. Public content uses generic names; keep personal identities and private build evidence out of Git.

## Dependency order

1. [QT-001: toolchain and contract](QT-001.md) — confirmed; unlocks implementation, not proof of game parity.
2. [QT-002: robot/room/grapple/ragdoll](QT-002.md) — actionable.
3. [QT-003: creature ecology and stretching](QT-003.md) — actionable independently against shared contract.
4. [QT-004: integrate/export](QT-004.md) — needs both gameplay slices.
5. [QT-005: independent audit/live delivery](QT-005.md) — needs exact integrated export.

## Acceptance and scope

Preserve current room, TV-faced robot, controls, aim, punch, grapple/release physics, hard-impact ragdoll/recovery, restart, randomized cake/pancake/sushi/popcorn ecology, and 45-ant stretching/collapse/regrouping behavior. Maintain the five earlier bug fixes. Disabled portal/glitch/frog systems are not new feature scope. Original visuals should remain recognizable; exact pixel identity between renderers is not assumed.

Logical geometry and cross-module API: [MODULE-CONTRACT.md](../../sources/tv-robot-godot/MODULE-CONTRACT.md). Engine-level state inspection and real exported-browser play checks complement one another. Browser asset downloads, parser success and source reviews do not independently prove gameplay. Target-device performance remains a separate limit.

## Research / checked 2026-10-14

The user specifically requests a Godot port; reuse this maintained native engine rather than add a custom engine or framework. Installed Godot 4.7.2 and Web non-threaded templates verified. Current official docs identify single-threaded Web as the preferred compatible route, with GDScript/Compatibility and WebGL2. Native Godot character collision and physical bodies/joints cover standard player/ragdoll interactions; the existing game's route/capacity rules are the behavioral prior art. No novel simulation algorithm or research-dependent design requires a separate literature review at this stage.

- [Godot Web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) — reports Godot 4.7.
- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) — native movement/collision.
- [Official maintained Godot demos](https://github.com/godotengine/godot-demo-projects) — primary native engine examples; adapt only what fits the active game.

Key tradeoff: a port can be playable while losing emergent creature/rope behavior; therefore integration and parity checks are required, not just export qualification. More detailed implementation choices stay with the primary implementer within the shared acceptance contract.

Planning complete; gameplay implementation authorized. First actions: primary implementer builds QT-002/QT-003 on a feature branch; overseer independently prepares parity checks and audits milestones. Confirm each ticket only on observed acceptance evidence.

Independent checks: [TEST-MATRIX.md](TEST-MATRIX.md). This matrix is planned coverage, not completed testing.
