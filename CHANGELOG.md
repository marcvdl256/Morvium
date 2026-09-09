# Changelog

## [0.1.1] - Prototype validation

### Fixed
- Corrected Left/Right arrow key bindings in the Godot InputMap.
- Replaced abbreviated InputMap event serialization with canonical Godot 4 event data.
- Added an explicit `ZombieData` cast when duplicating per-zombie stat resources.
- Prevented endless-wave progression from stalling when the final enemy dies while a wave is still spawning.
- Corrected `load_steps` metadata in the main and building scenes.
- Added the missing Godot `.gitignore`.
- Corrected the assets README filename.
- Moved the Godot project contents to the repository root so `project.godot` is directly importable.

### Validation
- Checked autoload paths, scene/resource paths, class names, InputMap actions, main scene configuration, HUD node references and prototype feature wiring.

## [0.1.0] - Prototype scaffold

### Added
- Initial Godot 4 project
- Player movement
- Modular building grid
- Basic block data resource
- Gold economy
- Zombie data resource
- Basic zombie AI
- Building damage
- Endless wave manager
- HUD
- Debug controls
- Git ignore rules
- Architecture documentation
