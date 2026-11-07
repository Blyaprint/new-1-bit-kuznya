# Art Direction — 1-bit Dungeon Card RPG

## Visual pillars
1. **Old-school fantasy RPG** — compact silhouettes, dungeon stonework, monsters, relics and hand-drawn-feeling pixel details.
2. **Strict 1-bit image language** — exactly two displayed colors throughout the game.
3. **Readable card table** — high contrast, restrained ornament, clear numbers and silhouettes at 640×360.

## Palette
- Ink: `#111111`
- Paper: `#F2F2F2`

No third color. No grayscale, antialiasing, gradients, alpha shading or soft shadows. Use patterns, pixel clusters and negative space to suggest material and depth.

## Pixel-art production
- Draw each sprite/icon/frame as a separate image asset.
- Work on a fixed pixel grid; avoid fractional positioning.
- Nearest-neighbor scaling only.
- Keep silhouettes readable at final in-game size, not only in a zoomed editor.
- Card illustrations should use a consistent border, title area, score area and effect/icon area.
- UI ornaments must not compete with score values or card text.

## Screen composition
At 640×360:
- Top strip: 36 px target (10%).
- Battlefield: 252 px target (70%).
- Player hand: 72 px target (20%).

The layout is a starting grid. Exact card dimensions, margins and row spacing are to be settled in the screen mockup before implementation.

## Asset workflow
1. Draw original art manually in a pixel editor.
2. Keep editable source files in the art source directory.
3. Export lossless PNG assets.
4. Record asset name, source file, export path and status in the asset register.
5. Inspect every asset at native game scale with nearest-neighbor filtering.

No programmatic drawing of final art assets. Code may later place and animate imported assets, but it must not replace the manual art process.
