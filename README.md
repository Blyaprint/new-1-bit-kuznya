# New 1-bit Kuznya

Prototype project for Godot 4.6.

## Playable workshop loop

- Production and research keep separate board layouts and directed links.
- Drag cards from the hand onto the board; drag them back to return them.
- Right-drag from an amber output port to a compatible green input port.
- Choose a recipe in the top bar: **Подкова**, **Гвозди** or **Скоба**.
- The current recipes share the first iron-working process: coal fuels the furnace, the furnace heats iron, and the hammer applies force.
- Each production action consumes one iron and one coal. The hammer and furnace each lose one durability point.
- Tools have 6 durability points. A red vertical wear bar grows upward as durability is lost; a broken tool disappears and must be replaced.

## Trader and economy

- A fresh game starts with **5 coins**, 3 iron, 3 coal, one hammer and one furnace.
- Open **ТОРГОВЕЦ** for a separate two-column trade window with square, Diablo-inspired inventory slots.
- Hover over a slot to see an item description and drag an item to see its icon attached to the cursor.
- Drag an item from your inventory to the trader's side to sell it.
- Drag an item from the trader's side to your inventory to buy it.
- Trader sells 2 iron for 1 coin and 5 coal for 1 coin.
- A replacement hammer costs 3 coins; a replacement furnace costs 4 coins.
- The trader buys materials back at lower prices: 1 coin per 4 iron or 10 coal; 1 horseshoe sells for 2 coins, 5 nails for 1 coin, 2 brackets for 1 coin, and a used tool for 1 coin. The trader can later resell acquired goods at a markup.
- Prices are prototype balance values and will be tuned during playtesting.

## Saving

- Purchases, sales, production and discoveries are saved automatically.
- Open the trader and use **ЗАКРЫТЬ** to return to the workshop.
- Save data includes money, inventory quantities, tool durability, trader stock, selected recipe, board layouts, links, discoveries and the next card ID.
- Existing pre-trader saves keep their workshop and inventory but migrate once to the new 5-coin starting balance.

## Research

- Experiments are immediate and do not consume materials.
- The first guided discovery with iron, furnace and hammer unlocks the forging operation and records it in the journal.

## Controls

- **Left mouse button:** move/place/return cards; switch modes; choose recipe; open the journal and trader.
- **Right mouse button:** drag from an output to a compatible input to create a connection.
- **ВЫПОЛНИТЬ:** run the selected production recipe.
- **ИСПЫТАТЬ:** run a research experiment.
- **ТОРГОВЕЦ:** open the two-sided trade window.

## Run

Open this folder in Godot 4.6 and run the project (F6/F5). The main scene is `scenes/board_prototype.tscn`.

## Current limits

- This is an early playable economy slice, not a complete game.
- Recipes currently share the same iron-working graph; distinct process chains will be added later.
- There are no orders, customers, dynamic prices or workshop upgrades yet.
- Save/load is a versioned JSON save in the Godot user data directory.
- Runtime validation is still required in Godot after this update.
