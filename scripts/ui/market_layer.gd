extends Control

const SLOT_COUNT := 20

@onready var inventory_window: Control = $InventoryWindow
@onready var merchant_window: Control = $MerchantWindow


func set_market_data(player_items: Array, merchant_titles: Array, trader_stock: Dictionary, money: int) -> void:
	_fill_window(inventory_window, player_items, false)
	var merchant_items: Array[Dictionary] = []
	for title in merchant_titles:
		merchant_items.append({"title": str(title), "quantity": int(trader_stock.get(title, 0)), "category": _category_for(str(title))})
	_fill_window(merchant_window, merchant_items, true)
	inventory_window.get_node("Margin/Layout/Footer").text = "МОНЕТЫ: %d" % money
	merchant_window.get_node("Margin/Layout/Footer").text = "Перетащи товар в инвентарь"


func _fill_window(window: Control, items: Array, show_stock: bool) -> void:
	var grid: GridContainer = window.get_node("Margin/Layout/Grid")
	for i in range(SLOT_COUNT):
		var slot: Control = grid.get_child(i)
		var name_label: Label = slot.get_node("Content/Name")
		var icon_label: Label = slot.get_node("Content/Icon/IconLabel")
		var count_label: Label = slot.get_node("Count")
		name_label.text = ""
		icon_label.text = "·"
		count_label.text = ""
		if i >= items.size():
			continue
		var item: Dictionary = items[i]
		var title := str(item.get("title", ""))
		name_label.text = title
		icon_label.text = _symbol_for(title)
		count_label.text = str(item.get("quantity", 0)) if int(item.get("quantity", 0)) > 1 or show_stock else ""


func _symbol_for(title: String) -> String:
	match title:
		"Железо": return "◆"
		"Уголь": return "◈"
		"Молот": return "⚒"
		"Горн": return "♨"
		"Подкова": return "∩"
		"Гвозди": return "⁝"
		"Скоба": return "⌑"
		_: return "·"


func _category_for(title: String) -> String:
	match title:
		"Молот": return "ИНСТРУМЕНТ"
		"Горн": return "ОПЕРАЦИЯ"
		"Подкова", "Гвозди", "Скоба": return "ИЗДЕЛИЕ"
		_: return "МАТЕРИАЛ"
