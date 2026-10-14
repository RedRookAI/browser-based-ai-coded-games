# Godot port audit — 2026-10-14

Audited gameplay/export revision: 0d93e9e. Primary implementer supplied source and Web export; overseer independently examined source and ran native and real exported-browser tests.

## Verified outcomes

- Import and native real-key movement/jump/landing.
- High-velocity actual wall contact produces 16-node articulated ragdoll; key recovery restores enabled collision. Restart during ragdoll no longer falls through the floor.
- 45 connected ants; actual wall arrival, capacity-limited failed attempt and loose tow/release. Controlled food/sushi cases verify population consumption, cake bite, pancake impact death and slack vs sustained bond tension.
- Independently rerun builder engine acceptance: 34 checks pass. Directed ecology suite: 21 checks pass; its unseeded 25-second sushi ceiling assertion failed in one run. Random wandering does not guarantee that deadline. All eight deterministic trajectories and a controlled no-reversal climbing fixture independently reach ceiling y=74; the failed random run is retained and not called a pass. No gameplay change was made to satisfy that test.
- Live-flight moving target evades acquisition; stationary and colony hook fixtures pass. Previously unconditional moving-target lock removed.
- 18 independent real-input Web checks pass: load/WebGL2, movement/jump/landing/crouch, grapple/release/restart, both Shift-key release orders, punch, HUD movement without unintended punch, scaled aim, and no page/engine errors. Reviewed desktop and narrow screenshots.

## Boundaries

Export tested with Chromium and SwiftShader software WebGL, not a claim about target-device FPS. Portrait mode letterboxes and has small touch controls; phone-friendly play is not claimed. Fixtures exercise controlled native states separately from real browser input. Disabled portal/glitch/frog features remain disabled rather than becoming new scope. The existing HTML game remains intact.

All three confirmed audit defects (ragdoll restart collision, HUD punch leakage, moving-target auto-lock) are repaired and independently verified. Public deployment verification is completed below.

## Final delivery

The directed capability test was made reproducible in ec36645 without gameplay or export changes; overseer rerun22/22 passes. Previous unseeded failure is retained above. Public release31c86fc serves the exact audited export; HTML/JS/PCK/WASM hashes match. The same18 real-input checks pass on the public HTTPS page. All five QuickTicket tickets are confirmed within the stated scope and device limitations.

[Play TV Robot — Godot](https://redrookai.github.io/browser-based-ai-coded-games/games/tv-robot-godot/)
