# Ashen Delve — Full Game Production Brief

## Product target
A compact, premium-feeling, single-player isometric action RPG for Windows PC, authored in Godot 4.6. The game is an original dark-fantasy property; it does not copy Diablo characters, locations, UI, music, text, or assets.

**Target scope:** a focused 2–3 hour first playthrough, one complete story with a definite ending, designed for mouse-first play and keyboard skill shortcuts. This is a realistic small-indie scope, not a live-service game.

## Player fantasy and core loop
The player is a lone delver descending into the Ashen Depths to silence an ancient forge-heart. Combat is readable, weighty and quick: click to move or target, close in, strike, reposition with a dash, and spend area skills when surrounded. Enemies telegraph pressure; kills provide experience and occasional equipment; each cleared encounter opens the route deeper.

## Camera, controls and presentation (locked)
- Fixed-angle orthographic isometric camera, centered on the hero; no orbit, zoom, rotation or camera smoothing.
- Left click ground: move. Left click enemy: pursue and auto-attack.
- Right click: primary area skill. Q/Space: dash. E: secondary skill. WASD remains optional.
- Low-resolution 640×360 presentation with integer scaling and nearest filtering.
- Restrained slate/ash palette, bronze hardware, ember lights and teal skill accents.
- All final assets must be original or have documented licenses. Procedural meshes are acceptable for blockout, not automatically considered final art.

## Full-game content target

### Structure
1. **The Cinder Gate (prologue / hub):** tutorial, first equipment choice, NPC dialogue, access to the descent.
2. **The Fallen Cloister (Act I):** ruined halls, bone wardens, ash hounds, first elite encounter, boss: The Bell Keeper.
3. **The Glass Warrens (Act II):** crystal caverns, ranged sentries, burrowers, environmental hazards, boss: The Shard Matriarch.
4. **The Heart Foundry (Act III):** forge machinery, mixed enemy squads, elite guards, final boss: The Unkindled Heart.
5. **Epilogue:** ending scene, final stats, continue/new run option.

Each act should contain several connected combat spaces, a short traversal or discovery beat, an elite encounter and a boss arena. Reuse visual kits intelligently but vary room layouts, enemy mixes and encounter objectives.

### Player progression
- Three simple attributes: Vigor (survivability), Force (melee damage), Focus (skill power/cooldown).
- Experience and level-ups with a small, readable choice between two upgrades.
- Equipment slots: weapon, armor, charm. Items have a small number of understandable affixes.
- A finite set of original abilities: basic melee, dash, whirlwind, ranged/utility skill, defensive skill and one ultimate. Abilities must have distinct roles, costs/cooldowns and clear feedback.
- No crafting system in the initial release scope.

### Enemy roster
- Bone Warden: basic melee pursuer.
- Ash Hound: fast flanker.
- Cinder Adept: ranged pressure with clear telegraph.
- Glass Burrower: ambush / area denial.
- Forge Guard: armored elite that requires repositioning.
- Act bosses: Bell Keeper, Shard Matriarch and Unkindled Heart, each with distinct phases and readable telegraphs.

### Essential systems
- Title screen, settings, pause menu, credits and quit.
- New game, continue, autosave at safe transitions and manual save at hub/checkpoints.
- Inventory/equipment and character progression screens.
- Quest/objective tracking and readable boss health display.
- Audio buses and separate master/music/SFX volume controls; mute options.
- Resolution/window mode, fullscreen, VSync and remappable key bindings where supported.
- Accessibility: scalable UI, high-contrast telegraphs, reduced screen shake/flashes, pause and clear control remapping.
- Victory/defeat, checkpoint retry and a complete ending.
- Credits and third-party asset/license acknowledgements.

## Quality gates
A release candidate is not complete until:
1. The project imports and launches in the pinned Godot version.
2. Every act can be completed from a fresh save; all bosses can be defeated.
3. Save/load survives application restart and handles missing/corrupt save data safely.
4. Menus, pause, settings, controls, audio and resolution changes work.
5. No progression blockers, softlocks, persistent error spam or missing required assets remain.
6. Desktop export is built and launched from the packaged artifact, not just from the editor.
7. Performance is measured on a stated Windows PC baseline.
8. A human playtest checks onboarding, difficulty, readability and completion.
9. Asset provenance, credits, store description, screenshots, capsule art and age/content disclosures are prepared.

## Delivery truth
The current repository is an early playable prototype with one procedural room. The full content above is the production target, not a claim that those features already exist. A Steam-ready claim requires an actual packaged build and completed release gates. Steam store publication, account setup, fees and legal agreements are separate owner-controlled actions and will not be performed without explicit authorization.
