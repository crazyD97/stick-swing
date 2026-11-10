---
name: new-game
description: Start a new game from the DroidPark template - copy it (or rename this checkout), set app name, Android package id, orientation and icon. Use when the user wants to begin a new game project.
disable-model-invocation: true
argument-hint: "\"Game Name\" [--landscape] [--dir ../folder | --in-place]"
---

# Start a new game

Arguments from the user: `$ARGUMENTS`

1. Work out the inputs. Ask only for what is missing and cannot be defaulted:
   - **Name** (required), e.g. "Stick Run".
   - **Package id**: default `com.droidpark.<name lowercased, no spaces>`. It can never change after the first
     Play Store upload, so confirm it with the user in one line.
   - **Where**: `--dir ../<kebab-name>` next to this folder by default. Use `--in-place` only when this checkout
     is already the new game's repo (created with GitHub's "Use this template") and still named DroidPark.
   - **Orientation**: portrait unless the user says landscape.
   - **Icon**: optional `--icon path.svg|png`; otherwise the default icon is recoloured per game.
2. Run:
   ```bash
   node tools/new_game.mjs --name "<Name>" --package <id> --dir <path> [--orientation landscape] [--icon <file>]
   ```
3. In the new folder, verify:
   ```bash
   tools/build.sh test
   tools/build.sh shot res://game/ui/main_menu.tscn 1.5 build/menu.png
   ```
   Look at `build/menu.png`: the title must show the new name. For landscape, check the menu still fits and
   tell the user which screens need a landscape layout pass.
4. Tell the user: the folder path, package id, that it is a fresh git repo, and the next step: open the new folder
   in Claude Code (so its own `CLAUDE.md`, skills and hooks apply), then `/run-on-phone`.
   If they want it on GitHub, they create an empty repo and run `git remote add origin <url> && git push -u origin main`.

Do not change gameplay here. The sample runner stays until the user describes their own mechanic.
