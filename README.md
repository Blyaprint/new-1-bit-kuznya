# New 1-bit Kuznya

Prototype project for Godot 4.6.

## Current slice: hand and engineering board

- Five unique test cards begin in the hand.
- Left-drag a card from the hand to the board to place it.
- Left-drag a board card to move it.
- Drag a board card into the bottom hand zone to return it.
- Right-drag from one board card to another to create an undirected connection.
- Connections can branch: a card may connect to multiple other cards.
- Returning a card to the hand removes all of its connections.
- Cards cannot be duplicated or manually deleted in this prototype.

## Controls

- **Left mouse button:** move/place/return cards.
- **Right mouse button:** drag from one board card to another to connect them.

This is an intentionally isolated interaction prototype. It does not yet include inventory, crafting rules, resources, production, or save/load.

## Run

Open this folder in Godot 4.6 and run the project (F6/F5). The main scene is `scenes/board_prototype.tscn`.


## First scheme execution check

- Place at least two cards on the engineering board.
- Every card on the board must have at least one connection.
- Press **Выполнить** in the top-right corner to validate the current graph.
- A successful check reports the number of board cards and connections.
- This is structural validation only: it does not consume cards or create a crafted item yet.
