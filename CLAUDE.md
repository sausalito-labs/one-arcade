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
Read `GODOT_BIN` from `.env` (fallback: `godot` in PATH, then `/root/.local/bin/godot`).
- Launch: `$GODOT_BIN --path .`
- Headless check: `$GODOT_BIN --headless --path . --quit`
- Build HTML5 demo: `./scripts/build_demo.sh`
- Build & serve HTML5 demo: `./scripts/serve_demo.sh`
- Serve existing build only: `./scripts/serve_demo.sh --serve`

Copy `.env.example` to `.env` to configure `GODOT_BIN`, `DEMO_HOST`, `DEMO_PORT`, and `BUILD_DIR`.

## HTML5 Demo Notes
- Export preset is `Web` in `export_presets.cfg`.
- The export uses the threaded template so it needs a secure context
  (HTTPS) for SharedArrayBuffer. Serve it behind Tailscale Funnel, which
  terminates a valid HTTPS cert — the local server stays plain HTTP on
  127.0.0.1. See `tailscale funnel --help` for path/port setup.
- Godot export templates must be installed. On this VPS they live under `~/.local/share/godot/export_templates/`. If the folder is named `4.3-stable`, Godot looks for `4.3.stable`; symlink if needed.

## Documentation
- Roadmap & task tracking: see `PLAN.md`
