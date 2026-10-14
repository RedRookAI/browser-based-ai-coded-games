# TV Robot Godot integration contract

Target: Godot 4.7.2, GDScript, Compatibility, non-threaded Web. Logical room is 1000 x 700; floor y=595, ceiling y=60, wall x=18/982. Middle platform Rect2(420,327.5,160,18). Additional platforms are optional, disabled by default. Preserve the active browser game, including 45-ant group-size-dependent stretching, failed reach collapse, cake/pancake/sushi interactions, grapple and robot ragdoll. Portal gun, glitch duplication and frog are disabled in the reference and not new scope.

The primary implementer owns main.gd, creature implementation and robot rendering. The overseer independently audits and tests the combined game. Integration script main.gd owns player physics and world collision. It passes the creature node world geometry rather than duplicating mutable room settings. UI/input/robot rendering are separate from creature implementation.

## creatures.gd — primary implementation

Extends Node2D. Use the module boundary below to keep implementation testable. Coordinate root collection changes and public deployment with the overseer. Keep user-identifying information and machine paths out of public code.

Methods:
- configure(room_rect: Rect2, platform_rects: Array[Rect2]) -> void. room_rect is the playable INNER region Rect2(18,60,964,535). Coordinates are logical world coordinates.
- restart(seed_value: int = -1) -> void. Randomized established creature lineups by default; optional deterministic seed for QA. Populate 45 ants whenever popcorn is in the lineup.
- step(delta: float, player_rect: Rect2, player_velocity: Vector2) -> void. Main calls once per physics tick. Handle creature movement, collisions/food interactions and rendering state; never move the main player directly.
- ray_target(from: Vector2, to: Vector2) -> Dictionary. Return nearest hit as {"id": string, "point": Vector2, "distance": float} or {}. IDs persist through an attached hook until target is removed.
- target_position(id: String) -> Vector2. Return actual attachment/body/group center; invalid target is handled through has_target.
- has_target(id: String) -> bool.
- target_mass(id: String) -> float. Ant colony mass must depend on live members.
- pull_target(id: String, displacement: Vector2, impulse: Vector2, tension: float) -> void. Apply grapple-induced motion with world/platform collisions; colony becomes towed/loose, creature AI pauses while hooked. Clear stale tension when tension=0. Impulse is a VELOCITY change for the selected target, not force divided by delta.
- release_target(id: String) -> void. Resume normal AI; ants retain momentum and return to loose physics then regroup. Sushi bonds may break from sustained real tension, not stale values.
- punch_at(point: Vector2, impulse: Vector2, radius: float = 12.0) -> void. Transfer velocity/physical impulse to targets near the fist.
- debug_state() -> Dictionary. Read-only observable state for QA: lineup array, popcorn_count, popcorn_mode, popcorn_capacity, popcorn_destination (kind or empty), cake_chunks, sushi_groups, pancake_health. Include body positions/finite state if useful.

_draw() renders the food creatures with recognizable authored procedural visuals. No editor-only or external runtime dependencies. No unrequested UI/remote RPC.

## main.gd / robot_visual.gd — primary implementation

Player center has position (x, feet_y - 72.5), rectangle 28 x 145. CharacterBody2D handles world motion. Input: A/D or arrows, Space jump, S crouch, Shift run, left punch, right grapple/release, R release, restart button. Pointer aiming maps through viewport stretch. Maintain fixed physics timing and clear held keys on focus loss. Hook max reach=2500, launch velocity=1250, reel speed=175, min length=65. Hook can hit static room/platform or creature node ray targets. Collision resolution must prevent platform tunneling. Initial player feet=(380,595).

robot_visual.gd extends Node2D, exposes set_pose(velocity: Vector2, grounded: bool, facing: float, crouched: bool, aim: Vector2, punch_phase: float, ragdoll_active: bool, clock: float) and renders the TV-faced robot with articulated metal limbs, wires and mint screen eyes. Local origin = feet. For ragdoll, main can set global transform/rotation and visual bends; actual recovery and collision live in main.

For engine-level acceptance tests, main.gd should provide a read-only debug_state() Dictionary with player_feet (Vector2), player_velocity (Vector2), grounded, ragdoll_active, hook_state, hook_target, and nested creature debug state. This is a callable GDScript method, not a browser RPC or additional player-facing UI. Tests can inspect scene state directly without changing delivered gameplay.
