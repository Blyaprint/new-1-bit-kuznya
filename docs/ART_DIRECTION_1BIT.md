# 1-Bit Kuznya — Art Direction Bible

## Visual pillars
1. **Arcade clarity** — every object reads instantly at 640×360; strong silhouettes, large negative space, no ornamental micro-detail.
2. **Strict 1-bit** — only #000000 and #FFFFFF for authored art. Greys may appear only as deliberate ordered dithering or UI opacity, never gradients, glow, blur, or soft shadows.
3. **Quiet craft / lively motion** — static art is economical and tactile; interaction is communicated by timing, position, scale steps, inversion, and crisp particles.

## Display and pixel rules
- Logical viewport: 640×360, rendered with viewport stretch and integer scaling.
- Startup display: fullscreen (`window/size/mode=3`); fullscreen changes the physical presentation size only. The game canvas and all UI/gameplay coordinates remain 640×360. Integer scaling preserves hard pixels; unused screen area becomes letterbox bars when the display aspect ratio is not an exact integer multiple.
- Nearest filtering for every pixel-art texture; pixel snapping on transforms and vertices.
- All sprite silhouettes align to an integer pixel grid. Use hard edges / shape-rendering="crispEdges"; no antialiasing or vector gradients.
- Texture atlas / source sprite pixel density should be authored for final logical size, not oversized 1920px UI textures.
- 1-bit palette: ink #000000, paper #FFFFFF. Dither patterns use explicit 2×2 / 4×4 / 6×6 binary patterns, not transparency gradients.
- UI uses 1px and 2px borders, square corners, notches, stepped corners, restrained symmetric corner ornaments inspired by engraved card frames, and sparse checker or ordered-dither fields.
- Frame hierarchy: double-line / stepped outer frame for important panels; small corner flourishes on cards and modal panels; buttons stay simpler so they remain readable at 640×360. Avoid dense filigree and tiny decorative text. No wood grain, metallic bevels, realistic material rendering, glow or glossy effects.
- Icons are 16–32px block silhouettes with no more than 2–3 interior cutouts. Each category uses a distinct silhouette, not color.

## Composition
- Top HUD: 54px (15%).
- Workbench: 192px plus 24px status strip (60% combined).
- Hand tray: 90px (25%).
- Cards remain 76×88; hierarchy is category tag → icon silhouette → short title → state/count.
- Keep connectors thin and readable; use square/dashed patterns where useful. Focus and hover invert black/white rather than adding color.

## Motion language
- Gameplay state and animation state remain separate.
- Drag follows pointer directly (no lag); drop/return transitions use short eased tweens (120–180ms).
- Card hover/selection: 1–2px lift or a 1px outline inversion, no elastic bounce.
- Modal open/close: 140–220ms eased slide/fade using binary dither steps; never block input after transition.
- Connection draw: short 100–140ms reveal; successful craft: 2–3 frame flash / compact burst, then settle.
- Use delta-based animation, cancel superseded tweens, and never create a new tween every frame.
- Prefer 60fps interaction; animation must not alter simulation or save data.

## Asset provenance
All replaced SVG files are original project-authored, crisp-edge monochrome vector pixel-art assets. They use no external artwork. Dithering is authored as explicit binary patterns.
