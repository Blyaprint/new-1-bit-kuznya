# Isometric Pixel Action RPG — Vertical Slice

This branch starts a new direction for the project: a compact 3D isometric action RPG prototype.

## Current playable-slice scope
- Fixed-angle orthographic isometric camera that follows the hero instantly, with no rotation, zoom or smoothing.
- Low-resolution 3D presentation with nearest-neighbor scaling.
- One enclosed dungeon room with tile floor, stone walls, pillars and warm torches.
- Left-click movement and enemy targeting with automatic close-range attacks; right-click area skill; keyboard dash and optional WASD movement.
- Six pursuing skeleton enemies with contact damage, hit reactions, knockback and delayed defeat animations.
- Gold drops that can be collected.
- Health, gold and clear-progress HUD; victory/defeat and restart.

## Controls
- Left mouse on the ground — move to the clicked point (with a destination marker)
- Left mouse on an enemy — approach and attack automatically (with a target ring)
- Right mouse — area attack
- Melee hits — short sword swing and brief impact ring
- Area attack — expanding teal ring with per-target impact flashes
- Enemy hit reaction — brief squash/punch and knockback
- Enemy defeat — short fall-and-shrink animation before the gold drop appears
- Q or Space — dash (brief invulnerability)
- E — area attack (keyboard alternative)
- WASD — optional direct movement
- Esc — pause/resume
- R — restart after victory or defeat

## Art direction
The visual pass now uses a restrained slate-and-ash palette with warm bronze and ember accents, a central dungeon floor sigil, trimmed pillars and walls, a more readable armored hero silhouette, ribbed bone wardens, and clear click/target rings. The low-resolution viewport and nearest filtering create the pixelated presentation. These are procedural original meshes, not bespoke sprite sheets or hand-painted final assets.

## Verification
The source is authored for Godot 4.6. A Godot executable is not available in the current editing environment, so scene import, GDScript parsing and interactive playtesting have not been run here. Open the project in Godot 4.6 and run the main scene to verify and tune it.
