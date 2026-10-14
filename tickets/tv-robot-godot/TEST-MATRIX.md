# Independent parity checks

This is a test plan, not a PASS receipt. Run against the exact combined source/export revision; preserve original source and builder evidence. Engine fixtures may deliberately isolate inputs/state; mark those separately from real browser input and live-site checks.

## Player / input

- Spawn feet at (380,595), grounded; move both directions and release: useful displacement, stops on floor, stays inside room.
- Space from ground: rises then lands; held Space does not repeat airborne jumps.
- S: crouched pose and reduced movement, release restores; left/right Shift each runs. Hold both then release either: remaining Shift still runs; release both: walk restored.
- Resize desktop to narrow/tall view and aim at center/corners: the same logical world remains, pointer aim matches displayed canvas and controls remain accessible.
- Pointer left: fist extends toward aim, transfers momentum to nearby creature; no repeated multi-hit from one punch unless the reference explicitly supports it.
- Pointer right: hook launches and attaches to wall/platform/nearest creature before geometry behind it; release via right click or R preserves momentum. Rope reeling moves bodies but not through obstacles.
- High-speed wall/floor impact: articulated loose body, not a frozen sprite. Input recovers upright control and valid collision position without stuck keys.
- Restart clears hook/punch/ragdoll/motion and restores creature health/population/room. Focus loss releases held movement and prevents accumulated hidden-tab catch-up.

## Creature ecology

- All eight established lineups have the expected enabled species and finite positions/velocities. Restarts restore full health and ant count for popcorn lineups.
- Cake crawls room/platform surfaces, can jump when configured, consumes nearby popcorn; ant count decreases from consumption rather than a display-only number.
- Pancake navigates around platforms, hunts/bites cake, pauses hunting on impact; three meaningful health losses yield limp/dead motion. A destroyed cake releases a hook safely.
- Sushi traverses surfaces as linked rolls. A separated chain gets its own head and can reconnect at free ends without branches/loops. Sustained tension can break a bond; slack/released tension cannot keep breaking bonds.
- Creature/player contact and punch transfer plausible motion without non-finite state or walls/platform penetration.

## Popcorn ability — mandatory parity

- Popcorn-enabled restart creates 45 independently rendered/movable members, not one aggregate body.
- Autonomous selection varies destinations and sampled positions; actual wall, ceiling, floor and platform arrival is exercised, not only planned paths.
- Reach is derived from currently connected members and their link span. Separated distant members cannot grant magical reach.
- Overlong route: attempt progresses up to capacity, visibly falls short, then loose inertia/gravity; no hard-coded demonstration headcount.
- Losing enough members during formation causes collapse; losing one member with ample capacity does not unnecessarily discard the surviving group.
- Real pointer grapple of colony interrupts formation and tows members. Release enters loose motion, forbids instant re-stretch while unsupported, then regroups.
- Single member, no members, consumption during tow and restart during formation remain safe.
- Contact resolution after chain constraints does not put members inside a platform. Count/progress changes may not teleport members to the destination.

## Build / delivery

- Godot import and headless run have no parser/runtime errors. Native engine tests check stateful outcomes; script exit 0 alone is not a parity PASS.
- Export uses installed matching templates, Compatibility and thread_support=false. Record build duration/RSS privately; no cache/log/credential/private path in public export.
- Disposable Chromium on the actual exported files: WebGL rendered scene, real keyboard/pointer input, full game visuals, no script/asset/engine errors. Inspect screenshots for robot/creature fidelity and layout. Software rendering is not target-device FPS evidence.
- Public HTTPS game loads after GitHub Pages build; served artifact equals audited revision and input works live. Preserve all existing game files/cards.
- Deliver separate clickable Godot Play URL plus Git revision; distinguish builder/independent results and any remaining target-device limits.
