# Ashen Delve — Visual Direction

## Visual pillars
1. **Quiet, readable silhouettes** — the hero is pale steel and muted teal; bone wardens are charcoal with ivory rib details and ember eyes.
2. **Cold stone, warm focal points** — slate floors and walls, bronze trim, amber torches and restrained teal magical markers.
3. **Pixel-scale clarity** — render through the existing 640×360 viewport with nearest filtering and integer scaling. Avoid fine noisy texture detail.

## Palette
- Deep background: `#111821`
- Floor slate: `#242b35`, alternating tiles `#303a46` / `#28323d`
- Stone: `#48515b`
- Hero ivory: `#d5d0bd`
- Bone: `#d8d0b8`
- Bronze: `#8c7150`
- Ember: `#ffad58`
- Magic/selection: `#6f9b9b`

## Production rules
- Orthographic isometric camera, fixed angle and scale; camera follows the hero.
- Prefer chunky geometry and high-contrast silhouettes over realistic surface noise.
- Keep enemy eyes, loot and interactive markers visually distinct from background stone.
- Use restrained glow; do not let effects cover combat telegraphs or the player.
- Current geometry is procedural Godot mesh work. It is an original placeholder art pass, not a final hand-painted asset set.

## Current second-stage pass
- Bronze wall caps and pillar bases/capitals.
- Central floor sigil and runic marks.
- More distinct armored hero chest, shoulders, belt and sword guard.
- Bone warden rib details and shoulder joints.
- Ground click marker and enemy selection rings.
- Darker ambient fill to make torchlight and warm accents stand out.

## Verification status
Visual changes were committed to the project source. Godot runtime is not available in the editing environment, so the scene has not been rendered or playtested here.


## Combat feedback pass
- The hero sword now swings on each confirmed melee hit using a short pivot animation.
- Confirmed melee impacts create a brief expanding blade-colored ring.
- The whirlwind ability creates a larger teal expanding ring and smaller impact rings on enemies hit.
- Effects are procedural meshes with short lifetimes; they are not imported sprite or particle assets.
