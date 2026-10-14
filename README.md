# Browser Based AI Coded Games

A growing collection of browser games made with AI coding tools.

Open the GitHub Pages site to browse and play the games. No installation is required.

## Games

- [Star Courier](games/star-courier/): collect eight crystals, avoid drones, and reach the portal.

## Adding a game

Put each game's playable files in its own folder under `games/`, with an `index.html` entry point. Add its card and relative play link to the collection's root `index.html`.

GitHub Pages publishes the `main` branch from the repository root. Keep private data, credentials, and development-only files outside this public repository.

## TV Robot

[Play TV Robot](https://redrookai.github.io/browser-based-ai-coded-games/games/tv-robot/)

Controls: A/D or arrow keys to walk, Space to jump, S to crouch, Shift to run, left click to punch, right click to grapple/release, R to release. Restart resets the room. The canvas scales a fixed logical room when resized.

2026-10-14 maintenance: fixed frame-rate slowdown, simultaneous Shift handling, resize consistency, stale sushi rope tension, and cake grapple/platform collision. Checked in a disposable Chromium browser with software rendering; device-specific performance and physical touch remain untested.
