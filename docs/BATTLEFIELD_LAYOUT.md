# Battlefield UI — first prototype

## Logical canvas
- 640×360 px.
- Top command strip: 36 px (10%).
- Battlefield: 252 px (70%).
- Player hand: 72 px (20%).

## Battlefield hierarchy
1. Opponent row at the top: opponent label, score, up to five cards.
2. Shared effect lane in the middle: global effects and status markers.
3. Player row below: player cards and score.
4. Hand at the bottom: five sample cards in a horizontal row.

## First-pass interaction
- Selecting a hand card prints its name, type and strength to the Godot output.
- End Turn toggles the active side and increments the turn counter when control returns to the player.
- Menu and Journal buttons currently show placeholder messages in the output.
- The displayed cards and scores are static layout samples, not the final rules implementation.

## Visual constraints
- Strict two-color output: black (#000000) and white (#FFFFFF).
- Nearest-neighbor pixel rendering; no smoothing or gradients.
- The current screen uses native Godot controls as layout wireframes. They are not final art assets.
- Final card illustrations, icons, card frames and decorative pieces must be drawn manually as separate raster assets in a pixel editor. Do not replace those assets with generated geometry or code-drawn art.

## Acceptance checklist
- [ ] Opens at a 640×360 logical resolution.
- [ ] Top / battlefield / hand regions respect 10% / 70% / 20%.
- [ ] Opponent and player rows are visually distinct.
- [ ] Both scores are visible without scrolling.
- [ ] The hand fits within the lower strip.
- [ ] All final art is manually authored and readable at native size.
- [ ] Run and inspect in Godot 4.6; not yet verified in this environment.
