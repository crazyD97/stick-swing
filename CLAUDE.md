# DroidPark: 2D Android game template

Godot **4.7.x**, **GDScript only** (no C#), Compatibility renderer, portrait 1080×1920.
Every new game starts as a copy of this repo and only adds its own gameplay.

## Layout

| Path | What lives there |
| --- | --- |
| `addons/studio_core/` | Shared systems reused by every game. Keep it game-agnostic. A fix here gets copied into older games. |
| `addons/studio_core/core/` | Autoloads: EventBus, SaveManager, AudioManager, Settings, Haptics, TouchInput, SceneRouter, DevTools |
| `addons/studio_core/services/` | Ads, Purchases, Analytics: **stubs** with the final API (real plugins come in Phase 4) |
| `addons/studio_core/characters/` | Character kit: `CharacterView` interface, `StickFigure`, `CharacterStyle` resource |
| `addons/studio_core/components/` | Reusable nodes: `Health`, `ShakeCamera` |
| `addons/studio_core/ui/` | `SafeAreaContainer`, `StarRating`, `StudioUI` helpers |
| `game/` | This game's own code: `levels/`, `characters/`, `objects/`, `ui/` |
| `assets/` | `audio/`, `characters/<name>/<name>_style.tres`, `theme/`, `CREDITS.md` |
| `tests/unit/` | GUT tests, `test_*.gd`, extend `GutTest` |
| `tools/` | `build.ps1` / `build.sh`, `new_game.mjs` (copy + rename template), `version.mjs` (bump version) |
| `tests/integration/` | Journey test that presses real buttons through menu → level → game over |
| `.claude/` | Skills, hooks, the `playtester` agent and settings. `.mcp.json` = godot + mobile MCP servers |
| `addons/gut/` | Third-party test framework. Do not edit. |

## Commands

Use `tools/build.sh <cmd>` (bash) or `.\tools\build.ps1 <cmd>` (PowerShell). `GODOT` env var = Godot binary.

- `test`: re-import, then run all GUT tests headless. **Run after every change.**
- `lint`: gdlint + gdformat check (line length 120). `format` rewrites files.
- `run [res://scene.tscn]`: desktop window at 540×960, mouse acts as touch.
- `shot [scene] [seconds] [out.png]`: run, save a screenshot, quit. Use this to *look* at UI changes.
- `playtest`: journey test + screenshots of every screen in `build/playtest/`.
- `apk`: debug APK. `phone`: APK, install, launch, `build/phone.png` + `build/logcat.txt`. `aab`: signed release.
- `version [bump [--name X.Y.Z]]`: show or bump the version code/name everywhere.

On Windows the Bash tool runs Git Bash, so `tools/build.sh` works there too (with `godot` on PATH).

## Claude tooling

- Skills: `/new-game`, `/add-character`, `/add-level`, `/run-on-phone`, `/playtest`, `/release` (`.claude/skills/`).
- Hooks (`.claude/settings.json`): `.gd` files are auto-formatted and linted after every edit (fix what gdlint reports);
  tests run when you finish if game files changed since the last green run (fix failures, then finish again);
  edits to generated files and anything touching keystores are blocked.
- MCP: `godot` (run the project, read debug output, inspect the project) and `mobile` (screenshots and taps on a
  connected phone/emulator). Never use mobile-mcp's remote/cloud devices.
- Device playtests go to the `playtester` subagent.

DevTools flags (after `--`): `--scene=res://…`, `--shot=SECONDS`, `--shot-path=…`, `--tap-at=1,2.5`
(simulated taps), `--quit=SECONDS`, `--temp-save` (throwaway save), `--reset-save` (wipes the real one).
Example: `godot --path . -- --scene=res://game/levels/level_01.tscn --tap-at=0.5,2.4 --shot=3 --shot-path=build/l1.png`

After adding a new `class_name`, run `godot --headless --path . --import` (the `test` command does it) or other
scripts will fail with "Identifier not declared".

## Code rules

- Static typing everywhere: `var speed: float = 3.0`, typed params and returns, `for x: int in ...`.
- Scenes talk through `EventBus` signals or direct child references, never `get_node("/root/...")` into other scenes.
- Change screens only with `SceneRouter.go_to(path, params)`. Read params from `SceneRouter.params`.
- Screens that need the back button implement `func handle_back() -> bool` (true = handled).
- Persist with `SaveManager.get_value/set_value(section, key)`; never write files directly. Bump
  `SAVE_VERSION` and add a step in `_migrate()` when changing the save layout.
- Sounds: `AudioManager.play_sfx("name")` (register names in `sfx_library`), music via `play_music(path)`.
  Buttons click automatically. Vibrate only through `Haptics`.
- Gameplay input: `TouchInput` signals (`touch_started`, `tapped`, `swiped`) plus an input action for keyboard.
  Never assume a keyboard on device.
- UI: put screen content in a `SafeAreaContainer`; use theme types from `assets/theme/studio_theme.tres`
  (`TitleLabel` for titles). Focus with `StudioUI.focus(control)`, never `grab_focus.call_deferred()`.
- Characters: gameplay only calls `view.play(&"run")` and sets `view.facing`. Animation names are fixed:
  `idle run jump fall hit die win`. New styles extend `CharacterView`. Look and movement live in a `CharacterStyle` `.tres`.
- Ads/purchases/analytics only through `Ads`, `Purchases`, `Analytics`. Interstitials only between levels.
- Hand-written `.tscn` files are fine; keep `[gd_scene format=3]`, use `unique_name_in_owner` + `%Name` for nodes scripts need.
- New level: copy `game/levels/level_02.tscn`, change `level_id` + data, add it to `LevelCatalog.LEVELS`.
  `test_every_catalog_level_loads` checks the wiring.
- New third-party asset: add a line to `assets/CREDITS.md` (source, author, licence). Prefer CC0.

## Mobile rules

- Base resolution 1080×1920, stretch `canvas_items`, aspect `expand`: design for 1080 wide, let height vary.
- Touch targets at least 150 px tall (about 48 dp). Font size at least 40.
- 60 fps on a cheap phone: avoid per-frame allocations and huge `_draw()` calls; draw static things once.
- Renderer stays Compatibility (black screen on some phones otherwise).

## Never

- Edit `.godot/`, `*.import`, `*.uid`, `android/build/`, or `addons/gut/` by hand.
- Touch keystores, `export_credentials.cfg`, or put passwords in any file. Release signing comes from env vars
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`.
- Put real ad unit IDs in the repo before release; use the test IDs in `ads.gd`.
- Skip or delete a failing test to get green.

## Definition of done

`test` passes, `lint` passes, and for anything visible a `shot` screenshot has been checked.
