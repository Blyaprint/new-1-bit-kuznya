extends Control

const SLOT_COUNT := 20

signal trade_requested(source: String, title: String, target: String)
signal close_requested

var drag_source := ""
var drag_title := ""

@onready var inventory_window: Control = $InventoryWindow
@onready var merchant_window: Control = $MerchantWindow


func _ready() -> void:
	_set_mouse_passthrough(self)
	$Backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MerchantWindow/Margin/Layout/CloseButton.pressed.connect(func() -> void:
		close_requested.emit()
	)


func _set_mouse_passthrough(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_set_mouse_passthrough(child)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point := get_global_mouse_position()
		if event.pressed:
			drag_source = ""
			drag_title = ""
			var player_title := _title_at(inventory_window, point)
			var merchant_title := _title_at(merchant_window, point)
			if player_title != "":
				drag_source = "player"
				drag_title = player_title
			elif merchant_title != "":
				drag_source = "merchant"
				drag_title = merchant_title
			accept_event()
		else:
			if drag_source != "":
				var target := ""
				if drag_source == "player" and merchant_window.get_global_rect().has_point(point):
					target = "merchant"
				elif drag_source == "merchant" and inventory_window.get_global_rect().has_point(point):
					target = "player"
				if target != "":
					trade_requested.emit(drag_source, drag_title, target)
			drag_source = ""
			drag_title = ""
			accept_event()
	elif event is InputEventMouseMotion and drag_source != "":
		accept_event()


func _title_at(window: Control, point: Vector2) -> String:
	var grid: GridContainer = window.get_node("Margin/Layout/Grid")
	for slot in grid.get_children():
		if slot is Control and slot.get_global_rect().has_point(point):
			var title := str(slot.get_node("Content/Name").text)
			if title != "":
				return title
	return ""


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
