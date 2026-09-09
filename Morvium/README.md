# Morvium

**Morvium** is a prototype 2D side-view survival / building / tower-defense game built with **Godot 4** and **GDScript**.

The player expands a modular defensive structure block-by-block while surviving increasingly difficult zombie waves.

## Prototype v0.1

Current scaffold includes:

- 2D player movement
- Grid-based modular building
- Configurable 64×64 building grid
- Gold economy
- Basic building health/damage
- Basic zombie movement and building attacks
- Endless wave scaling
- Debug spawn/kill controls
- Simple HUD
- Placeholder graphics drawn directly by Godot

The placeholder art is intentionally separate from the gameplay architecture so it can later be replaced with the final Morvium art direction.

## Controls

| Input | Action |
|---|---|
| A / Left | Move left |
| D / Right | Move right |
| B | Toggle build mode |
| Left mouse | Place basic block |
| Esc / Right mouse | Exit build mode |
| E | Interact (reserved) |
| F1 | Debug: spawn zombie |
| F2 | Debug: kill one zombie |
| F3 | Debug: toggle grid |

## Open in Godot

1. Install Godot 4.x.
2. Clone or download this repository.
3. Open Godot Project Manager.
4. Click **Import**.
5. Select `project.godot`.
6. Run the project with **F6/F5**.

## Project structure

```text
res://
├── assets/
├── autoload/
├── docs/
├── resources/
├── scenes/
└── scripts/
```

See `docs/ARCHITECTURE.md` for the current code architecture.

## Core loop

Zombie waves → gold → build modules → stronger defense → harder waves → repeat.

## Roadmap

### v0.1
- Core grid building
- Economy
- Basic zombie
- Endless waves
- Placeholder player

### v0.2
- Reliable targeting and attack feedback
- Repair interaction
- Better build validation
- Game over / restart loop

### v0.3
- First weapon module
- Projectile system
- Player ranged weapon prototype

### v0.4
- Multiple module types
- Upgrade system
- First resource building / mine

### Later
- Final 2D character rig and animations
- Multiple zombies
- Background parallax
- Progression / prestige
- Sound and music
- Save system
