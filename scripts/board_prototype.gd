extends Control

const CARD_SIZE := Vector2(140, 164)
const CARD_VIEW_SCENE := preload("res://scenes/ui/card_view.tscn")
const HAND_HEIGHT := 178.0
const HEADER_HEIGHT := 64.0
const STATUS_HEIGHT := 54.0
const BOARD_MARGIN := 28.0

const BG := Color("#111316")
const BOARD_BG := Color("#202328")
const CARD_BG := Color("#292b30")
const CARD_BORDER := Color("#b89a68")
const INK := Color("#eee2c9")
const MUTED := Color("#aaa18f")
const ACCENT := Color("#d5aa68")
const LINK_COLOR := Color("#e0b978")
const MATERIAL_COLOR := Color("#7894a2")
const TOOL_COLOR := Color("#b18a5c")
const OPERATION_COLOR := Color("#a96f55")
const OBJECT_COLOR := Color("#829078")
const PRODUCT_COLOR := Color("#c4a15d")
const SAVE_PATH := "user://kuznya_save.json"
const IRON_PACK_SIZE := 2
const COAL_PACK_SIZE := 5
const TOOL_BUY_PRICE := 3
const FURNACE_BUY_PRICE := 4
const TOOL_MAX_DURABILITY := 6

# Card definitions are shared; each mode keeps its own placement and graph.
var cards: Array[Dictionary] = []
var production_links: Array[String] = []
var research_links: Array[String] = []
var discoveries: Array[String] = []
var next_card_id := 1

var mode := "production"
var journal_open := false
var market_open := false
var confirm_new_game := false
var money := 5
var trader_stock := {"Железо": 99, "Уголь": 99, "Молот": 99, "Горн": 99}
var trade_drag_source := ""
var trade_drag_title := ""
var trade_drag_position := Vector2.ZERO
var market_anim := 1.0
var market_animating := false
var selected_recipe := "Подкова"
var drag_card_id := -1
var drag_from_hand := false
var drag_offset := Vector2.ZERO
var drag_position := Vector2.ZERO
var connecting_from_id := -1
var connecting_from_port := -1
var action_button_held := false
var execution_message := "Производство: собери схему и нажми «Выполнить»."
var mouse_position := Vector2.ZERO
var font: Font
@onready var market_layer: Control = $MarketLayer
@onready var card_views: Control = $CardViews


func _ready() -> void:
	font = ThemeDB.fallback_font
	market_layer.trade_requested.connect(_on_market_trade_requested)
	market_layer.close_requested.connect(_on_market_close_requested)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_card("Железо", "МАТЕРИАЛ", 3)
	_add_card("Уголь", "МАТЕРИАЛ", 3)
	_add_card("Молот", "ИНСТРУМЕНТ")
	_add_card("Горн", "ОПЕРАЦИЯ")
	for card in cards:
		if str(card.title) in ["Молот", "Горн"]:
			card["durability"] = TOOL_MAX_DURABILITY
			card["max_durability"] = TOOL_MAX_DURABILITY
	_load_game()
	queue_redraw()


func _add_card(title: String, category: String, quantity: int = 1) -> void:
	cards.append({
		"id": next_card_id,
		"title": title,
		"category": category,
		"quantity": quantity,
		"production_place": "hand",
		"production_position": Vector2.ZERO,
		"research_place": "hand",
		"research_position": Vector2.ZERO
	})
	next_card_id += 1


func _place_key() -> String:
	return "production_place" if mode == "production" else "research_place"


func _position_key() -> String:
	return "production_position" if mode == "production" else "research_position"


func _active_links() -> Array[String]:
	return production_links if mode == "production" else research_links


func _set_active_links(value: Array[String]) -> void:
	if mode == "production":
		production_links = value
	else:
		research_links = value


func _process(_delta: float) -> void:
	_sync_card_views()
	_sync_header_captions()
	if market_layer.visible != market_open:
		market_layer.visible = market_open
		if market_open:
			_refresh_market_scene()
	if market_animating:
		queue_redraw()


func _on_market_trade_requested(source: String, title: String, target: String) -> void:
	if source == "merchant" and target == "player":
		_buy_from_trader(title)
	elif source == "player" and target == "merchant":
		_sell_to_trader(title)
	queue_redraw()


func _on_market_close_requested() -> void:
	market_open = false
	market_layer.visible = false
	trade_drag_source = ""
	trade_drag_title = ""
	queue_redraw()


func _refresh_market_scene() -> void:
	market_layer.set_market_data(_player_trade_items(), _merchant_trade_titles(), trader_stock, money)


func _animate_market_open() -> void:
	market_anim = 0.0
	market_animating = true
	var tween := create_tween()
	tween.tween_property(self, "market_anim", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		market_animating = false
		market_anim = 1.0
		queue_redraw()
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if market_open and trade_drag_source != "":
			trade_drag_position = mouse_position
			accept_event()
			queue_redraw()
		elif market_open:
			accept_event()
			queue_redraw()
		elif drag_card_id != -1:
			drag_position = mouse_position - drag_offset
			accept_event()
			queue_redraw()
		elif connecting_from_id != -1:
			accept_event()
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_position = event.position
		if event.pressed:
			if confirm_new_game:
				if _new_game_confirm_rect().has_point(mouse_position):
					_start_new_game()
				elif _new_game_cancel_rect().has_point(mouse_position):
					confirm_new_game = false
				queue_redraw()
				accept_event()
				return
			if _new_game_button_rect().has_point(mouse_position):
				confirm_new_game = true
				market_open = false
				journal_open = false
				queue_redraw()
				accept_event()
				return
			if _market_button_rect().has_point(mouse_position):
				market_open = not market_open
				journal_open = false
				if market_open:
					_animate_market_open()
				accept_event()
				queue_redraw()
				return
			if market_open:
				trade_drag_source = ""
				trade_drag_title = ""
				trade_drag_position = mouse_position
				if _trade_close_rect().has_point(mouse_position) or not _trade_window_rect().has_point(mouse_position):
					market_open = false
					accept_event()
					queue_redraw()
					return
				if _trade_player_row_at(mouse_position) != "":
					trade_drag_source = "player"
					trade_drag_title = _trade_player_row_at(mouse_position)
				elif _trade_merchant_row_at(mouse_position) != "":
					trade_drag_source = "merchant"
					trade_drag_title = _trade_merchant_row_at(mouse_position)
				trade_drag_position = mouse_position
				accept_event()
				queue_redraw()
				return
			if _production_button_rect().has_point(mouse_position):
				_switch_mode("production")
				accept_event()
				return
			if _research_button_rect().has_point(mouse_position):
				_switch_mode("research")
				accept_event()
				return
			if _recipe_button_rect().has_point(mouse_position):
				_cycle_recipe()
				accept_event()
				queue_redraw()
				return
			if _journal_button_rect().has_point(mouse_position):
				journal_open = not journal_open
				accept_event()
				queue_redraw()
				return
			if _action_button_rect().has_point(mouse_position):
				action_button_held = true
				accept_event()
				queue_redraw()
				return
			var hit := _card_at(mouse_position)
			if not hit.is_empty():
				drag_card_id = int(hit.id)
				drag_from_hand = str(hit[_place_key()]) == "hand"
				if drag_from_hand:
					var hand := _hand_cards()
					for i in range(hand.size()):
						if int(hand[i].id) == drag_card_id:
							drag_offset = mouse_position - _hand_card_rect(i, hand.size()).position
							break
				else:
					drag_offset = mouse_position - (Vector2(hit[_position_key()]) - CARD_SIZE * 0.5)
				drag_position = mouse_position - drag_offset
				accept_event()
		else:
			if market_open:
				if trade_drag_source == "player" and _trade_merchant_panel().has_point(mouse_position):
					_sell_to_trader(trade_drag_title)
				elif trade_drag_source == "merchant" and _trade_player_panel().has_point(mouse_position):
					_buy_from_trader(trade_drag_title)
				trade_drag_source = ""
				trade_drag_title = ""
				accept_event()
				queue_redraw()
				return
			if action_button_held:
				if _action_button_rect().has_point(mouse_position):
					if mode == "production":
						_execute_production()
					else:
						_run_experiment()
				action_button_held = false
				accept_event()
				queue_redraw()
				return
			if drag_card_id != -1:
				_finish_card_drag(mouse_position)
				accept_event()
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_position = event.position
		if event.pressed:
			var source := _port_at(mouse_position, true)
			if not source.is_empty():
				connecting_from_id = int(source.id)
				connecting_from_port = int(source.port_index)
				execution_message = "Выход «%s» выбран. Соедини его с подходящим входом." % str(source.port_label)
				accept_event()
				queue_redraw()
			else:
				execution_message = "Связь начинается с янтарного ВЫХОДА справа на карте."
				accept_event()
				queue_redraw()
		else:
			if connecting_from_id != -1:
				var target := _port_at(mouse_position, false)
				if not target.is_empty() and int(target.id) != connecting_from_id:
					_add_directed_link(connecting_from_id, connecting_from_port, int(target.id), int(target.port_index))
				elif not target.is_empty():
					execution_message = "Нельзя соединить карту саму с собой."
				else:
					execution_message = "Не попал во вход. Отпусти кнопку на зелёном ВХОДЕ слева."
				connecting_from_id = -1
				connecting_from_port = -1
				accept_event()
				queue_redraw()


func _switch_mode(next_mode: String) -> void:
	if mode == next_mode:
		return
	mode = next_mode
	journal_open = false
	execution_message = "Режим производства." if mode == "production" else "Режим исследования: экспериментируй без расхода материалов."
	queue_redraw()


func _market_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 590.0, 12.0), Vector2(112.0, 40.0))


func _production_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 470.0, 12.0), Vector2(112.0, 40.0))


func _research_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 350.0, 12.0), Vector2(112.0, 40.0))


func _recipe_button_rect() -> Rect2:
	return Rect2(Vector2(430.0, 12.0), Vector2(130.0, 40.0))


func _new_game_button_rect() -> Rect2:
	return Rect2(Vector2(570.0, 12.0), Vector2(112.0, 40.0))


func _new_game_dialog_rect() -> Rect2:
	return Rect2(size * 0.5 - Vector2(210.0, 105.0), Vector2(420.0, 210.0))


func _new_game_confirm_rect() -> Rect2:
	return Rect2(_new_game_dialog_rect().position + Vector2(220.0, 150.0), Vector2(170.0, 38.0))


func _new_game_cancel_rect() -> Rect2:
	return Rect2(_new_game_dialog_rect().position + Vector2(30.0, 150.0), Vector2(170.0, 38.0))


func _start_new_game() -> void:
	cards.clear()
	production_links.clear()
	research_links.clear()
	discoveries.clear()
	next_card_id = 1
	money = 5
	trader_stock = {"Железо": 99, "Уголь": 99, "Молот": 99, "Горн": 99, "Подкова": 0, "Гвозди": 0, "Скоба": 0}
	selected_recipe = "Подкова"
	mode = "production"
	market_open = false
	journal_open = false
	trade_drag_source = ""
	trade_drag_title = ""
	drag_card_id = -1
	connecting_from_id = -1
	action_button_held = false
	_add_card("Железо", "МАТЕРИАЛ", 3)
	_add_card("Уголь", "МАТЕРИАЛ", 3)
	_add_card("Молот", "ИНСТРУМЕНТ")
	_add_card("Горн", "ОПЕРАЦИЯ")
	for card in cards:
		if str(card.title) in ["Молот", "Горн"]:
			card["durability"] = TOOL_MAX_DURABILITY
			card["max_durability"] = TOOL_MAX_DURABILITY
	execution_message = "Новая игра началась. В распоряжении 5 монет и стартовое оборудование."
	confirm_new_game = false
	_save_game()
	queue_redraw()


func _cycle_recipe() -> void:
	var recipes := ["Подкова", "Гвозди", "Скоба"]
	var index := recipes.find(selected_recipe)
	selected_recipe = recipes[(index + 1) % recipes.size()]
	execution_message = "Выбран рецепт: %s." % selected_recipe


func _journal_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 230.0, 12.0), Vector2(92.0, 40.0))


func _action_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 128.0, 12.0), Vector2(100.0, 40.0))


func _trade_window_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 362.0, size.y * 0.5 - 247.0, 724.0, 470.0)


func _trade_close_rect() -> Rect2:
	return Rect2(_trade_window_rect().end - Vector2(92.0, 44.0), Vector2(80.0, 30.0))


func _trade_player_panel() -> Rect2:
	return Rect2(size.x * 0.5 - 350.0, size.y * 0.5 - 205.0, 330.0, 410.0)


func _trade_merchant_panel() -> Rect2:
	return Rect2(size.x * 0.5 + 20.0, size.y * 0.5 - 205.0, 330.0, 410.0)


func _trade_row_rect(panel: Rect2, index: int) -> Rect2:
	var columns := 4
	var slot_size := 62.0
	var gap := 8.0
	return Rect2(panel.position + Vector2(16.0 + (index % columns) * (slot_size + gap), 62.0 + floor(float(index) / columns) * (slot_size + gap)), Vector2(slot_size, slot_size))


func _trade_item_description(title: String) -> String:
	match title:
		"Железо":
			return "Кусок железа для изготовления изделий. Покупка: 2 шт. за 1 монету."
		"Уголь":
			return "Топливо для горна. Покупка: 5 шт. за 1 монету."
		"Молот":
			return "Инструмент для передачи силы заготовке. Прочность: 6 рабочих циклов."
		"Горн":
			return "Нагревает металл. Прочность: 6 рабочих циклов."
		"Подкова":
			return "Готовое изделие. Торговец покупает по 2 монеты за штуку."
		"Гвозди":
			return "Партия из пяти гвоздей. Торговец покупает по 1 монете за партию."
		"Скоба":
			return "Крепёжная скоба. Торговец покупает по 1 монете за две штуки."
		_:
			return "Предмет из мастерской."


func _player_trade_items() -> Array[Dictionary]:
	var grouped: Dictionary = {}
	for card in cards:
		var title := str(card.title)
		if not grouped.has(title):
			grouped[title] = {"title": title, "quantity": 0, "category": str(card.category)}
		grouped[title].quantity += int(card.get("quantity", 1))
	var result: Array[Dictionary] = []
	for title in grouped.keys():
		result.append(grouped[title])
	return result


func _trade_player_row_at(point: Vector2) -> String:
	var items := _player_trade_items()
	for i in range(items.size()):
		if _trade_row_rect(_trade_player_panel(), i).has_point(point):
			return str(items[i].title)
	return ""


func _merchant_trade_titles() -> Array[String]:
	var result: Array[String] = []
	for title in ["Железо", "Уголь", "Молот", "Горн", "Подкова", "Гвозди", "Скоба"]:
		if int(trader_stock.get(title, 0)) > 0:
			result.append(title)
	return result


func _trade_merchant_row_at(point: Vector2) -> String:
	var titles := _merchant_trade_titles()
	for i in range(titles.size()):
		if _trade_row_rect(_trade_merchant_panel(), i).has_point(point):
			return titles[i]
	return ""


func _find_inventory_card(title: String) -> Dictionary:
	for card in cards:
		if str(card.title) == title:
			return card
	return {}


func _buy_from_trader(title: String) -> void:
	var price := 0
	var amount := 1
	var category := "МАТЕРИАЛ"
	match title:
		"Железо":
			price = 1
			amount = IRON_PACK_SIZE
		"Уголь":
			price = 1
			amount = COAL_PACK_SIZE
		"Молот":
			price = TOOL_BUY_PRICE
			category = "ИНСТРУМЕНТ"
		"Горн":
			price = FURNACE_BUY_PRICE
			category = "ОПЕРАЦИЯ"
		"Подкова":
			price = 3
			category = "ИЗДЕЛИЕ"
		"Гвозди":
			price = 2
			amount = 5
			category = "ИЗДЕЛИЕ"
		"Скоба":
			price = 2
			amount = 2
			category = "ИЗДЕЛИЕ"
	if int(trader_stock.get(title, 0)) < amount:
		execution_message = "У торговца закончился этот товар."
		return
	if money < price:
		execution_message = "Не хватает монет для покупки."
		return
	money -= price
	trader_stock[title] = int(trader_stock.get(title, 0)) - amount
	var existing := _find_inventory_card(title)
	if title in ["Молот", "Горн"]:
		_add_card(title, category)
		var new_tool: Dictionary = cards.back()
		new_tool["durability"] = TOOL_MAX_DURABILITY
		new_tool["max_durability"] = TOOL_MAX_DURABILITY
	elif existing.is_empty():
		_add_card(title, category, amount)
	else:
		existing.quantity = int(existing.get("quantity", 1)) + amount
	execution_message = "Куплено: %s ×%d за %d монету(ы)." % [title, amount, price]
	_save_game()
	_refresh_market_scene()


func _sell_to_trader(title: String) -> void:
	var items_to_sell: Array[Dictionary] = []
	var quantity := 0
	for card in cards:
		if str(card.title) != title:
			continue
		if str(card.get("production_place", "hand")) == "board" or str(card.get("research_place", "hand")) == "board":
			execution_message = "Сними предмет с рабочего поля перед продажей."
			return
		items_to_sell.append(card)
		quantity += int(card.get("quantity", 1))
	if items_to_sell.is_empty():
		return
	var payout := 0
	match title:
		"Железо":
			payout = int(floor(float(quantity) / 4.0))
		"Уголь":
			payout = int(floor(float(quantity) / 10.0))
		"Подкова":
			payout = quantity * 2
		"Гвозди":
			payout = int(floor(float(quantity) / 5.0))
		"Скоба":
			payout = int(floor(float(quantity) / 2.0))
		"Молот", "Горн":
			payout = quantity
		_:
			payout = 0
	if payout <= 0:
		execution_message = "Торговец не покупает этот предмет или количество слишком мало."
		return
	for item in items_to_sell:
		cards.erase(item)
	trader_stock[title] = int(trader_stock.get(title, 0)) + quantity
	money += payout
	execution_message = "Продано торговцу: %s ×%d. Получено %d монет." % [title, quantity, payout]
	_save_game()
	_refresh_market_scene()

func _save_game() -> void:
	var saved_cards: Array[Dictionary] = []
	for card in cards:
		var data: Dictionary = card.duplicate()
		data["production_position"] = [Vector2(card.production_position).x, Vector2(card.production_position).y]
		data["research_position"] = [Vector2(card.research_position).x, Vector2(card.research_position).y]
		saved_cards.append(data)
	var payload := {
		"version": 1,
		"money": money,
		"selected_recipe": selected_recipe,
		"trader_stock": trader_stock,
		"cards": saved_cards,
		"production_links": production_links,
		"research_links": research_links,
		"discoveries": discoveries,
		"next_card_id": next_card_id
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		execution_message = "Не удалось сохранить игру."
		return
	file.store_string(JSON.stringify(payload))


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != 1:
		return
	# One-time migration from the previous trader-less save format:
	# preserve the workshop, but apply the new starting balance.
	if parsed.has("trader_stock"):
		money = maxi(0, int(parsed.get("money", 5)))
		trader_stock = parsed.trader_stock
	else:
		money = 5
	selected_recipe = str(parsed.get("selected_recipe", "Подкова"))
	if not ["Подкова", "Гвозди", "Скоба"].has(selected_recipe):
		selected_recipe = "Подкова"
	cards.clear()
	for raw_card in parsed.get("cards", []):
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = raw_card.duplicate()
		var pp: Array = card.get("production_position", [0.0, 0.0])
		var rp: Array = card.get("research_position", [0.0, 0.0])
		card["production_position"] = Vector2(float(pp[0]), float(pp[1]))
		card["research_position"] = Vector2(float(rp[0]), float(rp[1]))
		card["quantity"] = maxi(1, int(card.get("quantity", 1)))
		if str(card.get("title", "")) in ["Молот", "Горн"]:
			card["max_durability"] = int(card.get("max_durability", TOOL_MAX_DURABILITY))
			card["durability"] = int(card.get("durability", card.max_durability))
		cards.append(card)
	production_links.clear()
	for link in parsed.get("production_links", []):
		production_links.append(str(link))
	research_links.clear()
	for link in parsed.get("research_links", []):
		research_links.append(str(link))
	discoveries.clear()
	for discovery in parsed.get("discoveries", []):
		discoveries.append(str(discovery))
	next_card_id = maxi(1, int(parsed.get("next_card_id", cards.size() + 1)))
	execution_message = "Сохранение загружено."


func _execute_production() -> void:
	var board_cards := _board_cards()
	var by_title: Dictionary = {}
	for card in board_cards:
		by_title[str(card.title)] = card
	if board_cards.size() < 2:
		execution_message = "Размести на поле хотя бы две карты."
		return

	var required := ["Железо", "Уголь", "Молот", "Горн"]
	for title in required:
		if not by_title.has(title):
			execution_message = "Для рецепта «%s» не хватает карты «%s»." % [selected_recipe, title]
			return
	# Typed sockets model the actual workshop process.
	var required_links := [
		"%d:0:%d:0" % [int(by_title["Уголь"].id), int(by_title["Горн"].id)],
		"%d:0:%d:0" % [int(by_title["Горн"].id), int(by_title["Железо"].id)],
		"%d:0:%d:1" % [int(by_title["Молот"].id), int(by_title["Железо"].id)]
	]
	var missing_steps: Array[String] = []
	var step_names := [
		"Уголь подаёт горючее в горн",
		"Горн передаёт температуру железу",
		"Молот передаёт силу железу"
	]
	for i in range(required_links.size()):
		if not production_links.has(required_links[i]):
			missing_steps.append(step_names[i])
	if not missing_steps.is_empty():
		execution_message = "Подкова не готова. Не хватает этапов: %s." % "; ".join(missing_steps)
		return

	if int(by_title["Железо"].get("quantity", 1)) < 1 or int(by_title["Уголь"].get("quantity", 1)) < 1:
		execution_message = "Закончились материалы. Купи железо и уголь у торговца."
		return
	var blank_position: Vector2 = Vector2(by_title["Железо"].production_position)
	for tool_title in ["Молот", "Горн"]:
		var tool: Dictionary = by_title[tool_title]
		tool["max_durability"] = int(tool.get("max_durability", TOOL_MAX_DURABILITY))
		tool["durability"] = int(tool.get("durability", TOOL_MAX_DURABILITY)) - 1
	var broken_tools: Array[int] = []
	for tool_title in ["Молот", "Горн"]:
		var tool: Dictionary = by_title[tool_title]
		if int(tool.durability) <= 0:
			broken_tools.append(int(tool.id))
	var consumed_ids: Array[int] = []
	for material_title in ["Железо", "Уголь"]:
		var material: Dictionary = by_title[material_title]
		material.quantity = int(material.get("quantity", 1)) - 1
		if int(material.quantity) <= 0:
			consumed_ids.append(int(material.id))
	for card in cards.duplicate():
		if consumed_ids.has(int(card.id)) or broken_tools.has(int(card.id)):
			cards.erase(card)
	consumed_ids.append_array(broken_tools)
	production_links = _filter_links_for_ids(production_links, consumed_ids)
	research_links = _filter_links_for_ids(research_links, consumed_ids)
	var product_quantity := 1
	match selected_recipe:
		"Гвозди":
			product_quantity = 5
		"Скоба":
			product_quantity = 2
	_add_card(selected_recipe, "ИЗДЕЛИЕ", product_quantity)
	var result_card: Dictionary = cards.back()
	result_card.production_place = "hand"
	result_card.production_position = Vector2.ZERO
	execution_message = "Изготовлено: %s ×%d. Материалы списаны, инструменты изношены." % [selected_recipe, product_quantity]
	if not broken_tools.is_empty():
		execution_message += " Инструмент сломался — купи замену у торговца."
	_save_game()


func _run_experiment() -> void:
	var board_cards := _board_cards()
	if board_cards.size() < 2:
		execution_message = "Для эксперимента размести хотя бы два элемента."
		return
	if research_links.is_empty() or not _is_one_connected_network(board_cards, research_links):
		execution_message = "Пока нет целостной схемы. Соедини элементы направленными связями."
		return

	var titles: Array[String] = []
	for card in board_cards:
		titles.append(str(card.title))
	var has_iron := titles.has("Железо")
	var has_heat := titles.has("Горн")
	var has_hammer := titles.has("Молот")

	# First guided discovery: an iron + heat + hammer experiment reveals forging.
	if has_iron and has_heat and has_hammer and not discoveries.has("Ковка"):
		discoveries.append("Ковка")
		_add_card("Ковка", "ОПЕРАЦИЯ")
		execution_message = "Открытие: «Ковка». Новая операция добавлена в инвентарь."
		_save_game()
	elif has_iron and has_heat and has_hammer:
		execution_message = "Эксперимент повторён. Ковка уже известна; попробуй другую комбинацию."
	else:
		execution_message = "Результат не получен. Подсказка: проверь, подготовлен ли материал и есть ли подходящий инструмент."


func _is_one_connected_network(board_cards: Array[Dictionary], graph_links: Array[String]) -> bool:
	if board_cards.size() < 2:
		return false
	var adjacency: Dictionary = {}
	for card in board_cards:
		adjacency[int(card.id)] = []
	for link in graph_links:
		var parts := link.split(":")
		if parts.size() != 4:
			continue
		var from_id := int(parts[0])
		var to_id := int(parts[2])
		if adjacency.has(from_id) and adjacency.has(to_id):
			adjacency[from_id].append(to_id)
			adjacency[to_id].append(from_id)
	var visited: Dictionary = {}
	var queue: Array[int] = [int(board_cards[0].id)]
	visited[int(board_cards[0].id)] = true
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for neighbor in adjacency[current]:
			if not visited.has(int(neighbor)):
				visited[int(neighbor)] = true
				queue.append(int(neighbor))
	return visited.size() == board_cards.size()


func _finish_card_drag(release_position: Vector2) -> void:
	var card := _card_by_id(drag_card_id)
	if card.is_empty():
		drag_card_id = -1
		return
	var place_key := _place_key()
	var position_key := _position_key()
	if _hand_rect().has_point(release_position):
		if str(card[place_key]) == "board":
			_remove_links_for_card(_active_links(), drag_card_id)
			card[place_key] = "hand"
			card[position_key] = Vector2.ZERO
	elif _board_rect().has_point(release_position):
		card[place_key] = "board"
		card[position_key] = _clamp_to_board(release_position - drag_offset + CARD_SIZE * 0.5)
	drag_card_id = -1


func _input_ports(card: Dictionary) -> Array[Dictionary]:
	# Железу нужны два независимых воздействия: нагрев и сила.
	match str(card.title):
		"Горн":
			return [{"label": "Топливо", "kind": "fuel"}]
		"Железо":
			return [
				{"label": "Температура", "kind": "temperature"},
				{"label": "Сила", "kind": "force"}
			]
		_:
			return []


func _output_ports(card: Dictionary) -> Array[Dictionary]:
	match str(card.title):
		"Уголь":
			return [{"label": "Горючее", "kind": "fuel"}]
		"Горн":
			return [{"label": "Тепло", "kind": "temperature"}]
		"Молот":
			return [{"label": "Сила", "kind": "force"}]
		"Железо":
			return [{"label": "Результат", "kind": "product"}]
		_:
			return []


func _card_center(card: Dictionary) -> Vector2:
	if int(card.id) == drag_card_id and str(card[_place_key()]) == "board":
		return drag_position + CARD_SIZE * 0.5
	return Vector2(card[_position_key()])


func _port_position(card: Dictionary, is_output: bool, port_index: int) -> Vector2:
	var center := _card_center(card)
	var ports := _output_ports(card) if is_output else _input_ports(card)
	var y_offset := (float(port_index) - float(ports.size() - 1) * 0.5) * 38.0
	return center + Vector2(CARD_SIZE.x * 0.5 if is_output else -CARD_SIZE.x * 0.5, y_offset)


func _port_at(point: Vector2, is_output: bool) -> Dictionary:
	var board_cards := _board_cards()
	board_cards.reverse()
	for card in board_cards:
		if int(card.id) == drag_card_id:
			continue
		var ports := _output_ports(card) if is_output else _input_ports(card)
		for i in range(ports.size()):
			if point.distance_to(_port_position(card, is_output, i)) <= 16.0:
				return {"id": card.id, "title": card.title, "port_index": i, "port_label": str(ports[i].label)}
	return {}


func _card_at(point: Vector2, board_only := false) -> Dictionary:
	var place_key := _place_key()
	var position_key := _position_key()
	var board_cards := cards.duplicate()
	board_cards.reverse()
	for card in board_cards:
		if str(card[place_key]) != "board":
			continue
		if board_only and int(card.id) == drag_card_id:
			continue
		var rect := Rect2(Vector2(card[position_key]) - CARD_SIZE * 0.5, CARD_SIZE)
		if rect.has_point(point):
			return card
	if board_only:
		return {}
	var hand := _hand_cards()
	for i in range(hand.size() - 1, -1, -1):
		if _hand_card_rect(i, hand.size()).has_point(point):
			return hand[i]
	return {}


func _board_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if str(card[_place_key()]) == "board":
			result.append(card)
	return result


func _hand_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if str(card[_place_key()]) == "hand":
			result.append(card)
	return result


func _hand_card_rect(index: int, count: int) -> Rect2:
	var usable_width := maxf(240.0, size.x - 80.0)
	var step := minf(124.0, usable_width / maxf(1.0, float(count)))
	var total_width := CARD_SIZE.x + step * maxf(0, count - 1)
	var start_x := (size.x - total_width) * 0.5
	var x := start_x + step * index
	var y := size.y - HAND_HEIGHT + 22.0 + absf(float(index) - float(count - 1) * 0.5) * 5.0
	return Rect2(Vector2(x, y), CARD_SIZE)


func _board_rect() -> Rect2:
	return Rect2(BOARD_MARGIN, HEADER_HEIGHT, size.x - BOARD_MARGIN * 2.0, size.y - HAND_HEIGHT - HEADER_HEIGHT - STATUS_HEIGHT)


func _hand_rect() -> Rect2:
	return Rect2(0.0, size.y - HAND_HEIGHT, size.x, HAND_HEIGHT)


func _clamp_to_board(point: Vector2) -> Vector2:
	var area := _board_rect()
	return Vector2(
		clampf(point.x, area.position.x + CARD_SIZE.x * 0.5, area.end.x - CARD_SIZE.x * 0.5),
		clampf(point.y, area.position.y + CARD_SIZE.y * 0.5, area.end.y - CARD_SIZE.y * 0.5)
	)


func _card_by_id(card_id: int) -> Dictionary:
	for card in cards:
		if int(card.id) == card_id:
			return card
	return {}


func _add_directed_link(from_id: int, from_port: int, to_id: int, to_port: int) -> void:
	if from_id == to_id:
		return
	var from_card := _card_by_id(from_id)
	var to_card := _card_by_id(to_id)
	if from_card.is_empty() or to_card.is_empty():
		return
	var outputs := _output_ports(from_card)
	var inputs := _input_ports(to_card)
	if from_port < 0 or from_port >= outputs.size() or to_port < 0 or to_port >= inputs.size():
		return
	var output_data: Dictionary = outputs[from_port]
	var input_data: Dictionary = inputs[to_port]
	if str(output_data.kind) != str(input_data.kind):
		execution_message = "Несовместимые сигналы: «%s» не подходит ко входу «%s»." % [output_data.label, input_data.label]
		return
	var key := "%d:%d:%d:%d" % [from_id, from_port, to_id, to_port]
	var current := _active_links()
	if not current.has(key):
		current.append(key)
		_set_active_links(current)
		execution_message = _connection_description(str(from_card.title), str(to_card.title), str(output_data.kind))


func _connection_description(source: String, target: String, kind: String) -> String:
	match kind:
		"fuel":
			return "Уголь подаёт горючее в горн."
		"temperature":
			return "Горн передаёт тепло железу."
		"force":
			return "Молот передаёт силу железу."
		_:
			return "%s передаёт результат карте «%s»." % [source, target]


func _remove_links_for_card(graph_links: Array[String], card_id: int) -> void:
	var kept := _filter_links_for_ids(graph_links, [card_id])
	if mode == "production":
		production_links = kept
	else:
		research_links = kept


func _filter_links_for_ids(graph_links: Array[String], ids: Array) -> Array[String]:
	var kept: Array[String] = []
	for link in graph_links:
		var parts := link.split(":")
		if parts.size() == 4 and not ids.has(int(parts[0])) and not ids.has(int(parts[2])):
			kept.append(link)
	return kept


func _sync_card_views() -> void:
	if not is_instance_valid(card_views):
		return
	var visible_ids: Array[int] = []
	for card in cards:
		var card_id := int(card.id)
		visible_ids.append(card_id)
		var view_name := "Card_%d" % card_id
		var view := card_views.get_node_or_null(view_name) as Control
		if view == null:
			view = CARD_VIEW_SCENE.instantiate() as Control
			view.name = view_name
			card_views.add_child(view)
		var on_board := str(card.get(_place_key(), "hand")) == "board"
		var target := Vector2(card.get(_position_key(), Vector2.ZERO)) - CARD_SIZE * 0.5 if on_board else Vector2.ZERO
		if not on_board:
			var hand := _hand_cards()
			for i in range(hand.size()):
				if int(hand[i].id) == card_id:
					target = _hand_card_rect(i, hand.size()).position
					break
		if card_id == drag_card_id:
			target = drag_position
			view.z_index = 50
		else:
			view.z_index = 2
		view.position = target
		view.size = CARD_SIZE
		view.call("set_card_data", card, on_board)
	for child in card_views.get_children():
		if child is Control and str(child.name).begins_with("Card_"):
			var id_text := str(child.name).trim_prefix("Card_")
			if not visible_ids.has(int(id_text)):
				child.queue_free()


func _sync_header_captions() -> void:
	$BoardTitle.text = "ПРОИЗВОДСТВО" if mode == "production" else "ИССЛЕДОВАНИЕ"
	$BoardSubtitle.text = "СОБИРАЙ РАБОЧУЮ ТЕХНОЛОГИЮ · МАТЕРИАЛЫ РАСХОДУЮТСЯ" if mode == "production" else "ПРОВЕРЯЙ ГИПОТЕЗЫ · ЭКСПЕРИМЕНТЫ БЕСПЛАТНЫ"
	$StatusMessage.text = execution_message
	$HandTitle.text = "РУКА МАСТЕРА"
	var total_items := 0
	for hand_card in _hand_cards():
		total_items += int(hand_card.get("quantity", 1))
	$HandCount.text = "%d ПРЕДМЕТОВ · ПЕРЕТАЩИ НА СТОЛ" % total_items
	$Instruction.text = "ПЕРЕТАЩИ КАРТУ НА ПОЛЕ  ·  ПКМ: ПОТЯНИ ОТ ВЫХОДА КО ВХОДУ  ·  ВНИЗУ: РУКА"
	$HeaderButtons/RecipeButton.call("set_caption", "РЕЦЕПТ: %s" % selected_recipe.to_upper())
	$HeaderButtons/NewGameButton.call("set_caption", "НОВАЯ ИГРА")
	$HeaderButtons/MarketButton.call("set_caption", "ТОРГОВЕЦ")
	$HeaderButtons/ProductionButton.call("set_caption", "ПРОИЗВОДСТВО")
	$HeaderButtons/ResearchButton.call("set_caption", "ИССЛЕДОВАНИЕ")
	$HeaderButtons/JournalButton.call("set_caption", "ЖУРНАЛ")
	$HeaderButtons/ActionButton.call("set_caption", "ВЫПОЛНИТЬ" if mode == "production" else "ИСПЫТАТЬ")


func _draw() -> void:
	# The board, HUD, hand tray and status strip are scene textures.
	_draw_header_button(_recipe_button_rect(), "РЕЦЕПТ: %s" % selected_recipe.to_upper(), true)
	_draw_header_button(_new_game_button_rect(), "НОВАЯ ИГРА", false)
	_draw_header_button(_market_button_rect(), "ТОРГОВЕЦ", market_open)
	_draw_header_button(_production_button_rect(), "ПРОИЗВОДСТВО", mode == "production")
	_draw_header_button(_research_button_rect(), "ИССЛЕДОВАНИЕ", mode == "research")
	_draw_header_button(_journal_button_rect(), "ЖУРНАЛ", journal_open)
	_draw_header_button(_action_button_rect(), "ВЫПОЛНИТЬ" if mode == "production" else "ИСПЫТАТЬ", true)


	_draw_graph_legend()
	_draw_links()
	for card in _board_cards():
		if int(card.id) != drag_card_id:
			_draw_card(card, Vector2(card[_position_key()]) - CARD_SIZE * 0.5, true)


	_draw_hand()
	if drag_card_id != -1:
		var dragged := _card_by_id(drag_card_id)
		if not dragged.is_empty():
			_draw_card(dragged, drag_position, str(dragged[_place_key()]) == "board")
	if connecting_from_id != -1:
		var source := _card_by_id(connecting_from_id)
		if not source.is_empty():
			draw_line(_port_position(source, true, connecting_from_port), mouse_position, ACCENT, 4.0, true)
			draw_circle(mouse_position, 7.0, ACCENT)
	if journal_open:
		_draw_journal()
	if market_open:
		_draw_market()
	if confirm_new_game:
		_draw_new_game_confirmation()


func _draw_new_game_confirmation() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.72))
	var panel := _new_game_dialog_rect()
	draw_rect(panel, Color("#171b15"))
	draw_rect(panel, Color("#d0a15e"), false, 2.0)
	draw_string(font, panel.position + Vector2(28, 42), "НАЧАТЬ НОВУЮ ИГРУ?", HORIZONTAL_ALIGNMENT_LEFT, 360, 18, ACCENT)
	draw_multiline_string(font, panel.position + Vector2(28, 78), "Текущий прогресс, деньги, предметы и оборудование будут сброшены. Начальный набор: 5 монет, железо, уголь, молот и горн.", HORIZONTAL_ALIGNMENT_LEFT, 360, 12, 0, CARD_BORDER)
	_draw_header_button(_new_game_cancel_rect(), "ОТМЕНА", false)
	_draw_header_button(_new_game_confirm_rect(), "НАЧАТЬ ЗАНОВО", true)


func _draw_workshop_background() -> void:
	pass


func _draw_graph_legend() -> void:
	var x := size.x - 420.0
	var y := HEADER_HEIGHT + 20.0
	draw_circle(Vector2(x, y), 5.0, ACCENT)
	draw_string(font, Vector2(x + 10, y + 4), "ВЫХОД", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)
	draw_circle(Vector2(x + 92, y), 5.0, Color("#82b8a0"))
	draw_string(font, Vector2(x + 102, y + 4), "ВХОД", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)
	draw_line(Vector2(x + 166, y), Vector2(x + 194, y), LINK_COLOR, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 194, y), Vector2(x + 186, y - 4), Vector2(x + 186, y + 4)]), LINK_COLOR)
	draw_string(font, Vector2(x + 202, y + 4), "НАПРАВЛЕНИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)


func _draw_header_button(_rect: Rect2, _label: String, _active: bool) -> void:
	pass


func _draw_header_icon(rect: Rect2, label: String, tint: Color) -> void:
	var c := rect.position + rect.size * 0.5
	draw_circle(c, 10, Color("#11100e"))
	draw_arc(c, 9, 0.0, TAU, 32, tint, 1.2)
	if label.begins_with("РЕЦЕПТ"):
		draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), tint, 2.0)
		draw_line(c + Vector2(5, -5), c + Vector2(-5, 5), tint, 2.0)
		draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), tint, 1.5)
	elif label == "НОВАЯ ИГРА":
		draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), tint, 2.0)
		draw_line(c + Vector2(0, -6), c + Vector2(0, 6), tint, 2.0)
	elif label == "ТОРГОВЕЦ":
		draw_line(c + Vector2(-6, -4), c + Vector2(6, -4), tint, 2.0)
		draw_line(c + Vector2(-4, -4), c + Vector2(-4, 6), tint, 2.0)
		draw_line(c + Vector2(4, -4), c + Vector2(4, 6), tint, 2.0)
		draw_line(c + Vector2(-7, 6), c + Vector2(7, 6), tint, 2.0)
	elif label == "ПРОИЗВОДСТВО":
		draw_line(c + Vector2(-6, -5), c + Vector2(6, -5), tint, 2.0)
		draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), tint, 2.0)
		draw_line(c + Vector2(-6, 5), c + Vector2(6, 5), tint, 2.0)
	elif label == "ИССЛЕДОВАНИЕ":
		draw_circle(c, 4, tint, false, 1.8)
		draw_line(c + Vector2(3, 3), c + Vector2(7, 7), tint, 2.0)
	elif label == "ЖУРНАЛ":
		draw_rect(Rect2(c + Vector2(-5, -6), Vector2(10, 12)), tint, false, 1.5)
		draw_line(c + Vector2(-3, -2), c + Vector2(3, -2), tint, 1.0)
		draw_line(c + Vector2(-3, 2), c + Vector2(3, 2), tint, 1.0)
	else:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -5), c + Vector2(7, 0), c + Vector2(-6, 5)]), tint)


func _draw_links() -> void:
	for link in _active_links():
		var parts := link.split(":")
		if parts.size() != 4:
			continue
		var a := _card_by_id(int(parts[0]))
		var b := _card_by_id(int(parts[2]))
		if a.is_empty() or b.is_empty():
			continue
		if str(a[_place_key()]) != "board" or str(b[_place_key()]) != "board":
			continue
		var from_edge := _port_position(a, true, int(parts[1]))
		var to_edge := _port_position(b, false, int(parts[3]))
		var direction := (to_edge - from_edge).normalized()
		if direction == Vector2.ZERO:
			continue
		draw_line(from_edge, to_edge, LINK_COLOR, 3.0, true)
		draw_circle(from_edge, 5.0, ACCENT)
		draw_circle(to_edge, 5.0, Color("#82b8a0"))
		var side := Vector2(-direction.y, direction.x)
		var tip := to_edge - direction * 3.0
		draw_colored_polygon(PackedVector2Array([tip, tip - direction * 12.0 + side * 6.0, tip - direction * 12.0 - side * 6.0]), LINK_COLOR)


func _card_edge_point(center: Vector2, direction: Vector2) -> Vector2:
	var half := CARD_SIZE * 0.5
	var scale_x := half.x / maxf(0.001, absf(direction.x))
	var scale_y := half.y / maxf(0.001, absf(direction.y))
	var distance := minf(scale_x, scale_y)
	return center + direction * distance


func _draw_hand() -> void:
	pass


func _draw_card(_card: Dictionary, _top_left: Vector2, _on_board := false) -> void:
	# Cards are rendered by reusable CardView scene instances.
	pass


func _category_color(category: String) -> Color:
	match category:
		"МАТЕРИАЛ":
			return MATERIAL_COLOR
		"ИНСТРУМЕНТ":
			return TOOL_COLOR
		"ОПЕРАЦИЯ":
			return OPERATION_COLOR
		"ОБЪЕКТ":
			return OBJECT_COLOR
		"ИЗДЕЛИЕ":
			return PRODUCT_COLOR
		_:
			return Color("#888888")


func _category_label(category: String) -> String:
	match category:
		"МАТЕРИАЛ":
			return "МАТЕРИАЛ"
		"ИНСТРУМЕНТ":
			return "ИНСТРУМЕНТ"
		"ОПЕРАЦИЯ":
			return "ОПЕРАЦИЯ"
		"ОБЪЕКТ":
			return "ЗАГОТОВКА"
		"ИЗДЕЛИЕ":
			return "ГОТОВОЕ ИЗДЕЛИЕ"
		_:
			return category


func _draw_card_emblem(category: String, center: Vector2, color: Color) -> void:
	match category:
		"МАТЕРИАЛ":
			draw_circle(center, 21.0, Color("#b8c8c1"))
			draw_circle(center, 16.0, color)
			draw_line(center + Vector2(-10, 5), center + Vector2(7, -8), Color("#d9e0d5"), 3.0)
			draw_line(center + Vector2(-5, 12), center + Vector2(12, -1), Color("#d9e0d5"), 2.0)
		"ИНСТРУМЕНТ":
			draw_circle(center, 22.0, Color("#d5c19d"))
			draw_rect(Rect2(center + Vector2(-5, -16), Vector2(10, 32)), color)
			draw_rect(Rect2(center + Vector2(-15, -17), Vector2(30, 9)), Color("#584633"))
			draw_line(center + Vector2(-10, 12), center + Vector2(10, -12), Color("#f2dfb8"), 3.0)
		"ОПЕРАЦИЯ":
			draw_circle(center, 22.0, Color("#e3c5a2"))
			draw_circle(center, 15.0, color)
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				draw_line(center + Vector2(cos(angle), sin(angle)) * 15.0, center + Vector2(cos(angle), sin(angle)) * 21.0, color, 4.0)
			draw_circle(center, 5.0, Color("#f4e6c9"))
		"ОБЪЕКТ":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-22, -14), center + Vector2(16, -18), center + Vector2(23, 12), center + Vector2(-14, 19)]), color)
			draw_line(center + Vector2(-14, 4), center + Vector2(13, -5), Color("#e5e0c9"), 3.0)
		"ИЗДЕЛИЕ":
			draw_circle(center, 23.0, Color("#e6d4a6"))
			draw_circle(center, 17.0, color)
			draw_arc(center, 12.0, 0.2, TAU - 0.2, 28, Color("#fff0bd"), 4.0)


func _trade_sale_hint(title: String, quantity: int) -> String:
	match title:
		"Железо":
			return "Продажа: %d мон. за 4 шт." % int(floor(float(quantity) / 4.0))
		"Уголь":
			return "Продажа: %d мон. за 10 шт." % int(floor(float(quantity) / 10.0))
		"Подкова":
			return "Продажа: %d мон." % (quantity * 2)
		"Гвозди":
			return "Продажа: %d мон. за 5 шт." % int(floor(float(quantity) / 5.0))
		"Скоба":
			return "Продажа: %d мон. за 2 шт." % int(floor(float(quantity) / 2.0))
		"Молот", "Горн":
			return "Продажа: 1 монета"
		_:
			return "Торговец не покупает"


func _draw_market() -> void:
	# The market is composed from reusable Control scenes in MarketLayer.tscn.
	pass


func _trade_category_for_title(title: String) -> String:
	match title:
		"Молот":
			return "ИНСТРУМЕНТ"
		"Горн":
			return "ОПЕРАЦИЯ"
		"Подкова", "Гвозди", "Скоба":
			return "ИЗДЕЛИЕ"
		_:
			return "МАТЕРИАЛ"


func _draw_rpg_window(rect: Rect2, heading: String, subtitle: String) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color("#050608", 0.8))
	draw_rect(rect, Color("#171a1e"))
	draw_rect(rect, Color("#9c8054"), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size - Vector2(8, 8)), Color("#292b2f"), false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(rect.size.x - 14, 43)), Color("#38332d"))
	draw_line(rect.position + Vector2(10, 49), rect.position + Vector2(rect.size.x - 10, 49), Color("#9c8054"), 1.0)
	draw_string(font, rect.position + Vector2(17, 26), heading, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 34, 14, Color("#f0dfbd"))
	draw_string(font, rect.position + Vector2(17, 42), subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 34, 8, Color("#b9aa90"))


func _draw_inventory_slot(rect: Rect2, hovered: bool) -> void:
	var edge := Color("#d4b47d") if hovered else Color("#655b4b")
	draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color("#08090b", 0.75))
	draw_rect(rect, Color("#17191d"))
	draw_rect(rect, edge, false, 1.5 if hovered else 1.0)
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), Color("#25272b"))
	draw_line(rect.position + Vector2(5, 5), rect.position + Vector2(rect.size.x - 5, 5), Color("#ffffff", 0.07), 1.0)


func _draw_item_medallion(slot: Rect2, category: String, item_color: Color) -> void:
	var center := slot.position + Vector2(31, 29)
	draw_circle(center, 23.0, Color("#111316"))
	draw_arc(center, 22.0, 0.0, TAU, 36, Color("#8c7654"), 1.5)
	_draw_card_emblem(category, center, item_color)


func _draw_journal() -> void:
	var panel := Rect2(size.x - 330.0, 72.0, 300.0, 220.0)
	draw_rect(panel, Color("#171b15"))
	draw_rect(panel, Color("#d0a15e"), false, 2.0)
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 38)), Color("#4a3a27"))
	draw_string(font, panel.position + Vector2(16, 25), "ЖУРНАЛ ОТКРЫТИЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CARD_BORDER)
	if discoveries.is_empty():
		draw_string(font, panel.position + Vector2(16, 66), "Пока нет открытий.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)
	else:
		for i in range(discoveries.size()):
			draw_circle(panel.position + Vector2(22, 59 + i * 24), 4.0, OPERATION_COLOR)
			draw_string(font, panel.position + Vector2(36, 63 + i * 24), discoveries[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CARD_BORDER)
