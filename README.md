# New 1-bit Kuznya

Prototype project for Godot 4.6.

## Playable core in progress

The current prototype combines an engineering board with the first economy loop.

### Workshop and production
- The production and research modes keep separate board layouts and directed links.
- Drag cards from the hand onto the board; drag them back to return them.
- Right-drag from an amber output port to a compatible green input port.
- The first production recipe makes a horseshoe using iron, coal, the furnace and the hammer.
- Each successful horseshoe consumes one iron and one coal. The furnace and hammer remain available.
- Material cards show their current stack quantity.

### Economy and trader
- New game starts with 100 coins, 3 iron and 3 coal.
- Open **ТОРГОВЕЦ** in the header.
- Buy iron for 12 coins or coal for 5 coins.
- Sell all produced horseshoes for 30 coins each.
- The current prices are prototype balance values and will be tuned during playtesting.

### Saving
- Open the trader panel and choose **Сохранить игру** to save the current workshop.
- The game attempts to load the latest save automatically on startup.
- The save contains money, cards and quantities, both board layouts, both sets of links, research discoveries and the next card ID.
- **Загрузить сохранение** restores the latest save.

### Research
- Experiments are immediate and do not consume materials.
- The first guided discovery with iron, furnace and hammer unlocks the forging operation and records it in the journal.

## Controls
- **Left mouse button:** move/place/return cards; switch modes; open the journal and trader.
- **Right mouse button:** drag from an output to a compatible input to create a connection.
- **Выполнить:** run the production recipe.
- **Испытать:** run a research experiment.
- **Торговец:** buy materials, sell all horseshoes, save or load.

## Run
Open this folder in Godot 4.6 and run the project (F6/F5). The main scene is `scenes/board_prototype.tscn`.

## Current limits
- This is an early playable economy slice, not a complete game.
- There is one product and fixed prototype prices; no orders, customers, dynamic market or upgrades yet.
- Save/load is a simple versioned JSON save in the Godot user data directory.
- The prototype has not yet been runtime-tested in Godot as part of this update.
