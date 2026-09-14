# One Arcade - Project Constitution

## Vision
2D arcade fighter inspired by One Championship (Muay Thai / kickboxing) and Skullgirls / Shadow Fight. Browser/WebGL first, then Mobile. Fast, readable, comic-book action.

## Architecture
- Engine: Godot 4, Compatibility renderer (WebGL 2).
- Language: GDScript only.
- Setup: Code-driven node construction; scenes stored as `.tscn` for the arena, fighter rig, and AnimationPlayer.
- Root: `Node2D` arena with `Camera2D` framing.
- Fighter: `CharacterBody2D` with segmented `ColorRect`/polygon limbs parented under pivot `Node2D`s.
- Combat: `Area2D` Hitboxes (fists, shins) and Hurtboxes (head, torso, legs).

## Aesthetic
Comic-book arcade flat-shading:
- High-contrast silhouette limbs.
- Bold, simple color blocks with crisp black outlines via stacked shapes or future shader pass.

## Commands
Read `GODOT_BIN` from `.env` (fallback: `godot` in PATH).
- Launch: `$GODOT_BIN --path .`
- Headless check: `$GODOT_BIN --headless --path . --quit`

## Documentation
- Roadmap & task tracking: see `PLAN.md`
