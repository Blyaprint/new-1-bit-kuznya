# Isometric Pixel Action RPG — Vertical Slice

This branch starts a new direction for the project: a compact 3D isometric action RPG prototype.

## Current playable-slice scope
- Fixed orthographic isometric camera that follows the player.
- Low-resolution 3D presentation with nearest-neighbor scaling.
- One enclosed dungeon room with tile floor, stone walls, pillars and warm torches.
- WASD movement, mouse-directed melee, a short dash and an area skill.
- Six pursuing skeleton enemies with contact damage.
- Gold drops that can be collected.
- Health, gold and clear-progress HUD; victory/defeat and restart.

## Controls
- WASD — move
- Left mouse — melee attack
- Space — dash (brief invulnerability)
- Q — area attack
- Esc — pause/resume
- R — restart after victory or defeat

## Art direction
The first slice uses original low-poly primitive models and a restrained palette to establish scale, lighting, silhouettes and camera readability. It is intentionally a greybox-quality art pass, not final bespoke character or environment art. The low-resolution viewport and nearest filtering create the pixelated presentation.

## Verification
The source is authored for Godot 4.6. A Godot executable is not available in the current editing environment, so scene import, GDScript parsing and interactive playtesting have not been run here. Open the project in Godot 4.6 and run the main scene to verify and tune it.
