# TV Robot Godot implementation

Editable Godot 4.7.2 project; Compatibility renderer and non-threaded Web export. The existing HTML game is preserved. This is a first-pass port under active parity verification, not a completed release.

Input actions: `move_left`, `move_right`, `jump`, `crouch`, `run`, `punch`, `grapple`, `release_hook`, `restart_run`.

The player uses CharacterBody2D world collision. Articulated ragdoll uses positional constraints; creature and connected-ant rules use explicit solvers to retain reference gameplay. `debug_state()` is read-only. The Web build additionally exposes a read-only `window.__tv_robot_state` snapshot for browser-input assertions; it cannot modify game state.

Initial import and 180-frame headless scene run passed without script errors. This does not establish all behavior parity or a browser playtest. Detailed engine/browser checks and overseer audit remain pending.

Follow-up validation: 34 builder engine assertions passed, including ragdoll-restart collision restoration, two-way contact response and no upright phantom during ragdoll. The initial exported build passed nine real-input browser/loading/resize checks using software WebGL. A new export is required after the contact fixes; independent audit remains pending.

Contract addition for two-way contact: `player_contact_response()` returns copied `displacement` and `velocity_change` vectors after `step`. Main owns applying them using CharacterBody2D collision. An empty player rectangle skips upright contact while ragdolled; `collide_loose_nodes(points)` applies per-node articulated contacts instead. It does not directly mutate the main player.

## Build

From the project directory:

```
godot --headless --path . --editor --import
godot --headless --path . --export-release Web /absolute/export/index.html
```

Keep all exported files together. Export, import caches and test output are not source deliverables. Source files and `.uid` references are intended to be shared through Git.

## Builder milestone results

34 engine acceptance assertions and 22 directed colony/ecology assertions passed on the latest gameplay source. These include actual floor/ceiling/platform ant arrivals, disconnected-member capacity, mid-stretch loss, loose regrouping, sushi room climbing/reunion and a bounded cake jump. Nine real-input/loading/resize assertions passed on the latest Web export using Chromium with software WebGL. Desktop and narrow screenshots were inspected; target-device performance and human acceptance are not established. Independent overseer audit remains required before ticket confirmation.

A clean Web export is shared on the implementation branch under `games/tv-robot-godot/`. The existing published HTML game and collection are unchanged.

Independent audit follow-up: gameplay mouse presses now use unhandled input so HUD clicks do not punch/fire. Hook flight checks live swept segments each tick; a target selected by aim that moves out of the projectile path is not automatically acquired. Regression fixtures cover moving-target evasion, stationary/colony acquisition and HUD versus world pointer input. Portrait mode preserves geometry/aim but letterboxes and has small touch controls; phone-friendly play is not claimed.

Audit record: an unseeded rerun of the 25-second sushi ceiling check failed to observe arrival. Random wandering and reversals do not guarantee that deadline in the reference game. That failed run remains a failure, not a pass. The capability assertion now uses a documented seed-1 trajectory; it checks that climbing works under that reproducible input, not that all random trajectories reach the ceiling in 25 seconds. The colony/ecology test RNG is also initialized deterministically. Gameplay randomness is unchanged.

## Grapple report follow-up — 2026-10-14

The reported nonworking grapple remains unresolved: the implementation inspection and controlled traces did not reproduce it. Gameplay source at `ec36645` matches the published gameplay source inspected for this investigation. No gameplay changes or rebuilt export were made.

- Native traces exercised ceiling, both walls and floor; firing, attachment and winch displacement occurred. A diagonal swing can hit a wall and enter the existing impact-ragdoll/release path.
- The existing hook-flight fixture passed evading-target rejection, stationary-target acquisition and popcorn acquisition/towing.
- The expanded exported-browser fixture passed 18 checks in Chromium 154 using software WebGL, with no captured engine/browser errors. New coverage asserts ceiling acquisition, actual player lift, right-click release with retained momentum, upward coasting, refiring and R release. It reads snapshots and uses real browser input, not gameplay mutation.
- An initial release-velocity assertion sampled after a browser automation round trip and failed its -40 cutoff (observed -25). The revised fixture observes the actual release transition inside the page and asserts upward velocity plus continued upward displacement; it passed. This fixes sampling of the short coast, not gameplay.

Next diagnostic input: affected game link, device/browser and input method, and whether the failure is firing, attachment, pulling, or release. Desktop traces do not establish behavior on the affected device. Do not mark the original report resolved from these passes alone.
