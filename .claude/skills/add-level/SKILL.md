---
name: add-level
description: Create a new level scene for the current game and register it in level select. Use when the user asks for a new level, stage or world.
argument-hint: "[name] [difficulty or description]"
---

# Add a level

Request: `$ARGUMENTS`

The sample game's levels are data: a `.tscn` whose root uses `res://game/levels/level.gd`. (If this game has replaced
the runner with its own `Level` script, follow the same steps with that script's exported data.)

1. Pick the next id: look at `LevelCatalog.LEVELS` in `game/levels/level_catalog.gd`. Ids are `level_NN`, zero-padded.
2. Copy the last level's `.tscn` to `game/levels/level_NN.tscn` and change:
   - root node name `LevelNN`, `level_id = "level_NN"`
   - `level_length`: about 5000 + 1000 per difficulty step
   - `obstacles`: `PackedVector2Array(x, height, ...)`. Keep at least **500 px** between boxes (a jump covers about
     470 px at default speed) and heights between 90 and 190 (a jump clears about 300 px).
   - `coins`: `PackedVector2Array(x, height_above_ground, ...)`. Arcs over boxes (`x-170,200  x,300  x+170,200`) reward
     jumping; ground coins at height 60 between boxes.
   - optional `sky_color`, `ground_color`, `dirt_color` so each level looks different.
3. Append `{"id": "level_NN", "name": "<Short Name>", "scene": "res://game/levels/level_NN.tscn"}` to `LEVELS`.
4. Verify:
   ```bash
   tools/build.sh test     # test_every_catalog_level_loads checks the wiring
   tools/build.sh shot res://game/levels/level_NN.tscn 3 build/level_NN.png
   ```
   Look at the screenshot (pass `--tap-at=0.5` via `godot --path . -- --scene=... --tap-at=0.5 --shot=3 ...` to see it running).
   Make sure the level is beatable: walk through the obstacle list and check the spacing and height rules above.
5. Report the new id, name, length, number of boxes and coins.
