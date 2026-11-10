---
name: playtest
description: Play through the game (menu, play, pause, game over, level select, settings) and report what is broken, with screenshots. Use after gameplay or UI changes and before any release.
---

# Playtest

1. **Desktop pass (always):** run `tools/build.sh playtest`. It runs the journey test (`tests/integration/`) and saves
   screenshots of every screen to `build/playtest/`. Read each PNG and check:
   - nothing overlaps or is cut off; text is readable; buttons are at least 150 px tall in the 1080-wide layout
   - the level shows the character, ground, coins and HUD; the game-over screen shows score and buttons
   - the journey test passed (menu -> play -> pause -> die -> continue -> win -> next level -> progress survives restart)
2. **Device pass (when a phone or emulator is connected, `adb devices` lists it):** delegate to the `playtester` subagent
   so the screenshots stay out of the main conversation. Tell it what changed recently so it looks there first.
   Install the latest build first with `tools/build.sh phone` if the user has run `/run-on-phone` before;
   otherwise ask before installing.
3. Report a short bug list, most serious first: what you did, what happened, what should have happened, and the
   screenshot path. Say plainly if everything passed. Do not fix anything unless the user asks.
