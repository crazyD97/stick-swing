# Roadmap

Phases 1–3 build the studio once. Phases 4–5 repeat for every game.

## 1. Machine ready (on your PC)

- [x] Install Git, Node.js, JDK 17, Android Studio, Python and Claude Code; put Godot 4.7.1 on PATH ([SETUP.md](SETUP.md))
- [x] Install SDK packages, create the API 36 emulator, enable USB debugging on your phone
- [x] `tools/build.ps1 phone` opens the template on your phone

## 2. Template core

- [x] Project defaults: Compatibility renderer, 1080×1920 portrait, `canvas_items` + `expand`, touch from mouse
- [x] `studio_core`: SceneRouter, SaveManager, AudioManager, Settings, TouchInput, Haptics, EventBus, DevTools
- [x] Screens: splash, menu, settings, level select, pause, game over, credits
- [x] Stick-figure character kit and a sample runner with two levels
- [x] GUT tests for saving, settings, scene changes, gameplay rules and the character kit
- [x] Android export presets (debug APK, release AAB with target SDK 36) and build scripts
- [x] Verified on a real phone

## 3. Claude wiring

- [x] `CLAUDE.md`
- [x] `.mcp.json` with godot-mcp and mobile-mcp
- [x] Skills: `/new-game`, `/add-character`, `/add-level`, `/run-on-phone`, `/playtest`, `/release`
- [x] Hooks: lint after `.gd` edits, tests when Claude stops, block keystore and `.godot/` edits
- [x] Playtester subagent
- [x] `tools/new_game.mjs` (rename package, app name, orientation, icon) and `tools/version.mjs`
- [x] Journey test (`tests/integration/`) and `playtest` build command
- [ ] On your PC: `/mcp` shows both servers connected
- [ ] On your PC: `/new-game` then `/run-on-phone` puts a renamed game on the phone with no manual steps

## 4. Game #1

- [ ] Pick one small mechanic
- [ ] Swap the Ads/Purchases/Analytics stubs for the real plugins (AdMob, Play Billing, Firebase) with test IDs
- [ ] Play Console account, release keystore, store listing, internal testing upload

## 5. Publish and reuse

- [ ] 14-day closed test with 15–20 testers, then production
- [ ] Fold fixes back into `studio_core`; package the Claude tooling as a plugin
