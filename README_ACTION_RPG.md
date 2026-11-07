# Isometric Pixel Action RPG — Vertical Slice

This branch starts a new direction for the project: a compact 3D isometric action RPG prototype.

## Current playable-slice scope
- Fixed-angle orthographic isometric camera that follows the hero instantly, with no rotation, zoom or smoothing.
- Low-resolution 3D presentation with nearest-neighbor scaling.
- One enclosed dungeon room with tile floor, stone walls, pillars and warm torches.
- Left-click movement and enemy targeting with automatic close-range attacks; right-click area skill; keyboard dash and optional WASD movement.
- Six pursuing skeleton enemies with contact damage.
- Gold drops that can be collected.
- Health, gold and clear-progress HUD; victory/defeat and restart.

## Controls
- Left mouse on the ground — move to the clicked point
- Left mouse on an enemy — approach and attack automatically
- Right mouse — area attack
- Q or Space — dash (brief invulnerability)
- E — area attack (keyboard alternative)
- WASD — optional direct movement
- Esc — pause/resume
- R — restart after victory or defeat

## Art direction
The first slice uses original low-poly primitive models and a restrained palette to establish scale, lighting, silhouettes and camera readability. It is intentionally a greybox-quality art pass, not final bespoke character or environment art. The low-resolution viewport and nearest filtering create the pixelated presentation.

## Verification
The source is authored for Godot 4.6. A Godot executable is not available in the current editing environment, so scene import, GDScript parsing and interactive playtesting have not been run here. Open the project in Godot 4.6 and run the main scene to verify and tune it.
