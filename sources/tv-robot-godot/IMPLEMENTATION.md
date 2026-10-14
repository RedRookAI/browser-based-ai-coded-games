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
