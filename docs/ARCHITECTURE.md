# Morvium Architecture

## Goal

The prototype is intentionally split into small systems so game art and future gameplay features can be replaced or extended without rewriting the entire project.

## Autoloads

### GameManager
Tracks global prototype state such as build mode and debug mode.

### EconomyManager
Owns the player's gold total and emits `gold_changed`.

## Building system

### BuildingData
A reusable Resource containing module values such as cost, max health and grid size.

### BuildingModule
Base class for placeable structures. Handles health, repair and destruction.

### BuildingManager
Owns the grid. It converts between world/grid coordinates, validates placement and registers occupied cells.

Prototype support rule:
- Ground-row cells may be placed freely.
- Higher cells require a block directly underneath.

This rule can later be replaced by a more advanced structural system.

## Zombie system

### ZombieData
Reusable stats resource.

### BasicZombie
Finds the nearest building module, walks toward it and attacks when in range.

More enemy classes can reuse or extend this design later.

## Wave system

### WaveManager
Spawns waves indefinitely.

Current prototype:
- enemy count = base count + wave number
- health multiplier = `1 + (wave - 1) × 0.08`
- a wave completes only after spawning has finished and the tracked alive-enemy count reaches zero
- `wave_transition_pending` prevents duplicate next-wave timers

Each zombie receives a duplicated `ZombieData` resource before wave-specific health scaling is applied, so the shared `.tres` file remains unchanged.

The values are deliberately simple and should be balance-tuned later.

## UI

HUD listens to signals from game systems. UI does not directly change economy or wave state.

## Art

Prototype visuals are drawn with `_draw()` or simple nodes.

Final art can later replace those placeholders with:
- Sprite2D
- AnimatedSprite2D
- AnimationPlayer / AnimationTree
- 2D skeletal rig assets

without changing the high-level gameplay architecture.
