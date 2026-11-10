---
name: add-character
description: Add a character (stick figure or cartoon) with the standard idle/run/jump/fall/hit/die/win animations, using the studio_core character kit. Use when the user asks for a new hero, enemy, NPC or character look.
argument-hint: "<name> [stick|cartoon] [description of look and feel]"
---

# Add a character

Request: `$ARGUMENTS`

Characters have two parts: a **view** (how it looks: a `CharacterView` subclass) and a **style** resource
(`CharacterStyle` `.tres`: colours, size, speed, jump). Gameplay only calls `view.play(&"run")` and sets `view.facing`.

## Stick figure (default, no art needed)

1. Create `assets/characters/<name>/<name>_style.tres` by copying `assets/characters/hero/hero_style.tres`.
   Set `color`, `accent_color`, `head_fill`, `line_width`, `height`, `head_scale`, `scarf`, `show_face`, and the
   movement numbers (`run_speed`, `jump_velocity`, `gravity`) to match the description.
   Rough feel guide: chunky = line_width 14+, head_scale 1.3; fast = run_speed 650; floaty = gravity 2200.
2. Use it:
   - As the player: set `style` on both the Player root and its `View` node in `game/characters/player.tscn`,
     or make a new player scene `game/characters/<name>.tscn` that instances `player.tscn` with the new style.
   - As an enemy/NPC: create `game/characters/<name>.tscn` with a `CharacterBody2D` or `Area2D` root and a
     `StickFigure` child named `View` using the style. Put behaviour in `game/characters/<name>.gd`.
     In Stick Swing the playable character is `game/swing/swinger.tscn`: set the style on it and its `View`.
3. If a new pose is truly needed, add a case in `StickFigure._target_pose()`. Keep the 7 animation names: never add
   names gameplay must know about.

## Cartoon cutout (sprites per body part)

1. Ask for or find a CC0 parts pack (Kenney "Toon Characters" has separate limbs). Put the images in
   `assets/characters/<name>/` and add a line to `assets/CREDITS.md`.
2. Create `addons/studio_core/characters/cutout_character.gd` (once, if it does not exist): `class_name CutoutCharacter
   extends CharacterView`, with a `Skeleton2D` + `Bone2D` + `Sprite2D` per part and an `AnimationPlayer` child.
   `_on_animation_started(name)` calls `$AnimationPlayer.play(name)`; emit `animation_finished` for `hit`/`die` from
   the AnimationPlayer's `animation_finished`.
3. Build the animations `idle run jump fall hit die win` in `<name>.tscn` (loop all but `hit`/`die`).

## Always

- Add a test in `tests/unit/` that instances the character scene, plays every name in `CharacterView.ANIMATIONS`,
  and checks `current_animation` changes (see `test_stick_figure_plays_every_animation`).
- Look at it: `tools/build.sh shot <scene showing the character> 2 build/char.png` and check the screenshot.
- `tools/build.sh test` and `tools/build.sh lint` pass.
