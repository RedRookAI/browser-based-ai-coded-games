# TV Robot Godot implementation

Editable Godot 4.7.2 project; Compatibility renderer and non-threaded Web export. The existing HTML game is preserved. This is a first-pass port under active parity verification, not a completed release.

Input actions: `move_left`, `move_right`, `jump`, `crouch`, `run`, `punch`, `grapple`, `release_hook`, `restart_run`.

The player uses CharacterBody2D world collision. Articulated ragdoll uses positional constraints; creature and connected-ant rules use explicit solvers to retain reference gameplay. `debug_state()` is read-only. The Web build additionally exposes a read-only `window.__tv_robot_state` snapshot for browser-input assertions; it cannot modify game state.

Initial import and 180-frame headless scene run passed without script errors. This does not establish all behavior parity or a browser playtest. Detailed engine/browser checks and overseer audit remain pending.

## Build

From the project directory:

```
godot --headless --path . --editor --import
godot --headless --path . --export-release Web /absolute/export/index.html
```

Keep all exported files together. Export, import caches and test output are not source deliverables. Source files and `.uid` references are intended to be shared through Git.
