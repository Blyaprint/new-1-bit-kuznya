# New 1-bit Kuznya

Prototype project for Godot 4.6.

## Current foundation: production and research

The project now has one engineering workspace with two modes. Each mode keeps its own card placement and directed graph, so switching modes does not overwrite the other mode's current layout.

### Shared inventory / hand

- Five initial cards: Железо, Уголь, Молот, Нагрев, Заготовка.
- Newly discovered operations are added directly to the hand/inventory.
- A card can be placed independently in the production and research layouts.
- Left-drag a card from the hand to the board to place it.
- Left-drag a board card to move it.
- Drag a board card into the bottom hand zone to return it.
- Returning a card removes its connections in the active mode.

### Directed engineering graph

- Right-drag from one board card to another to create a directed connection.
- The arrow indicates flow from the source card's output to the target card's input.
- Connection endpoints show output/input ports.
- Branches and merges are supported by the graph structure.
- The current graph integrity check verifies that all placed nodes belong to one connected network.

### Production mode

- The first recipe remains Katrina's horseshoe.
- Required cards: Железо, Уголь, Молот, Нагрев, Заготовка.
- The current prototype checks for all five cards, a connected network, and at least one directed connection.
- On success, Железо, Уголь and Заготовка are consumed; Молот and Нагрев remain; Подкова appears on the board.
- Production consumes materials. The current horseshoe check is still a prototype recipe check; it does not yet validate a specific operation sequence or calculate item quality.

### Research mode

- Uses the same engineering workspace, but has a separate layout and separate directed connections from production.
- Experiments are immediate and do not consume materials.
- Before running an experiment, directed links show the proposed flow and the status line gives preliminary feedback.
- A successful first guided experiment with Железо, Нагрев and Молот on one connected board discovers Ковка.
- The discovered operation is added to the shared hand/inventory and the discovery is recorded in the journal.
- An unsuccessful experiment leaves the layout intact and gives a small hint.
- The journal records discoveries; saving full reusable blueprints is not implemented yet.

## Controls

- **Left mouse button:** move/place/return cards; switch modes and open the journal.
- **Right mouse button:** drag from a source card to a target card to create a directed link.
- **Выполнить:** run the current production recipe check.
- **Эксперимент:** run the current research experiment.
- **Журнал:** view discovered operations.

## Run

Open this folder in Godot 4.6 and run the project (F6/F5). The main scene is `scenes/board_prototype.tscn`.

## Known prototype limits

- Mode layouts are kept separately during the running session; persistent save/load is not implemented.
- Research discovery currently contains one guided example, not a general material/operation simulation.
- Input/output ports are represented visually by link endpoints; typed port compatibility rules are a later step.
- Research discoveries are journaled, but full blueprint save/load and the remaining four craft tasks are not implemented yet.


## Visual readability pass

- The board now uses a restrained forge-workshop palette with a subtle grid and clearer separation between header, work area, status and hand.
- Card categories have distinct color bands and silhouettes: blue-grey materials, ochre tools, rust operations, sage blanks/objects and brass finished products.
- Board nodes visibly distinguish input (green) and output (amber) ports; directed links have arrows and a legend.
- The two workspace modes now have clear subtitles describing their different purpose and resource rules.
- Cards show whether they are in the hand or placed as a node, and the hand has a clearer inventory label.
- These are drawn vector placeholders for readability, not final production art.
