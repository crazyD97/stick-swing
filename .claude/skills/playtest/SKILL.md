---
name: playtest
description: Play through the game (menu, swinging, pause, game over, continue, settings) and report what is broken, with screenshots. Use after gameplay or UI changes and before any release.
---

# Playtest

1. **Desktop pass (always):** run `tools/build.sh playtest`. It runs the journey test (`tests/integration/`) and saves
   screenshots of every screen to `build/playtest/`. Read each PNG and check:
   - nothing overlaps or is cut off; text is readable; buttons are at least 150 px tall in the 1080-wide layout
   - the game shows the stick figure, rings (the grabbable one highlighted), rope while swinging, coins, lava and HUD;
     the game-over screen shows distance, best and buttons
   - the journey test passed (menu -> play -> swing -> pause -> fall -> continue -> fall -> retry -> best on menu)
2. **Device pass (when a phone or emulator is connected, `adb devices` lists it):** delegate to the `playtester` subagent
   so the screenshots stay out of the main conversation. Tell it what changed recently so it looks there first.
   Install the latest build first with `tools/build.sh phone` if the user has run `/run-on-phone` before;
   otherwise ask before installing.
3. Report a short bug list, most serious first: what you did, what happened, what should have happened, and the
   screenshot path. Say plainly if everything passed. Do not fix anything unless the user asks.
