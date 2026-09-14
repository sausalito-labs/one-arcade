# 2D Arcade Fighter Transition Plan

## Architecture Target
- Root: `Node2D` (Main Arena)
- Fighter Base: `CharacterBody2D` with `Skeleton2D` / `AnimationPlayer`
- Collision & Striking: `Area2D` for Hurtboxes (head, torso, legs) and Hitboxes (fists, shins)
- Camera: `Camera2D` dynamically centering and zooming between fighters

## Active Tasks
- [x] Task 1: Create clean 2D arena scene with floor collision (`StaticBody2D`)
- [x] Task 2: Build base 2D fighter scene with placeholder geometric limbs
- [x] Task 3: Implement 2D locomotion (A/D movement; S crouch & Space/W jump deferred)
- [x] Task 4: Implement jab strike state machine with attack priority
- [x] Task 5: Add dynamic framing `Camera2D`
- [x] Task 6: Add HTML5 demo export and local server (`scripts/build_demo.sh`, `scripts/serve_demo.sh`)

## Next Milestones
- [ ] Hitbox / hurtbox collision response (damage, hit reaction, pushback)
- [ ] Placeholder health bars / arcade UI overlays
- [ ] Combo input buffering (Jab -> Cross)
- [ ] Crouch and jump states (deferred from initial harness)
