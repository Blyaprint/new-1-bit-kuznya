extends Control

const CARD_SIZE := Vector2(140, 164)
const HAND_HEIGHT := 178.0
const HEADER_HEIGHT := 64.0
const STATUS_HEIGHT := 54.0
const BOARD_MARGIN := 28.0

const BG := Color("#171713")
const BOARD_BG := Color("#242923")
const CARD_BG := Color("#e5d8bd")
const CARD_BORDER := Color("#f5e9d2")
const INK := Color("#29251f")
const MUTED := Color("#b5b7a8")
const ACCENT := Color("#e2a653")
const LINK_COLOR := Color("#f0bd70")
const MATERIAL_COLOR := Color("#6e9aaf")
const TOOL_COLOR := Color("#c58b52")
const OPERATION_COLOR := Color("#d47b55")
const OBJECT_COLOR := Color("#8a9b72")
const PRODUCT_COLOR := Color("#d2b45d")

# Card definitions are shared; each mode keeps its own placement and graph.
var cards: Array[Dictionary] = []
var production_links: Array[String] = []
var research_links: Array[String] = []
var discoveries: Array[String] = []
var next_card_id := 1

var mode := "production"
var journal_open := false
var drag_card_id := -1
var drag_from_hand := false
var drag_offset := Vector2.ZERO
var drag_position := Vector2.ZERO
var connecting_from_id := -1
var action_button_held := false
var execution_message := "Производство: собери схему и нажми «Выполнить»."
var mouse_position := Vector2.ZERO
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_card("Железо", "МАТЕРИАЛ")
	_add_card("Уголь", "МАТЕРИАЛ")
	_add_card("Молот", "ИНСТРУМЕНТ")
	_add_card("Нагрев", "ОПЕРАЦИЯ")
	_add_card("Заготовка", "ОБЪЕКТ")
	queue_redraw()


func _add_card(title: String, category: String) -> void:
	cards.append({
		"id": next_card_id,
		"title": title,
		"category": category,
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
	if drag_card_id != -1 or connecting_from_id != -1:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		if drag_card_id != -1:
			drag_position = mouse_position - drag_offset
			accept_event()
			queue_redraw()
		elif connecting_from_id != -1:
			accept_event()
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_position = event.position
		if event.pressed:
			if _production_button_rect().has_point(mouse_position):
				_switch_mode("production")
				accept_event()
				return
			if _research_button_rect().has_point(mouse_position):
				_switch_mode("research")
				accept_event()
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
			var hit := _card_at(mouse_position, true)
			if not hit.is_empty() and str(hit[_place_key()]) == "board":
				connecting_from_id = int(hit.id)
				accept_event()
				queue_redraw()
		else:
			if connecting_from_id != -1:
				var target := _card_at(mouse_position, true)
				if not target.is_empty() and str(target[_place_key()]) == "board":
					_add_directed_link(connecting_from_id, int(target.id))
				connecting_from_id = -1
				accept_event()
				queue_redraw()


func _switch_mode(next_mode: String) -> void:
	if mode == next_mode:
		return
	mode = next_mode
	journal_open = false
	execution_message = "Режим производства." if mode == "production" else "Режим исследования: экспериментируй без расхода материалов."
	queue_redraw()


func _production_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 470.0, 12.0), Vector2(112.0, 40.0))


func _research_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 350.0, 12.0), Vector2(112.0, 40.0))


func _journal_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 230.0, 12.0), Vector2(92.0, 40.0))


func _action_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 128.0, 12.0), Vector2(100.0, 40.0))


func _execute_production() -> void:
	var board_cards := _board_cards()
	var by_title: Dictionary = {}
	for card in board_cards:
		by_title[str(card.title)] = card
	if board_cards.size() < 2:
		execution_message = "Размести на поле хотя бы две карты."
		return

	var required := ["Железо", "Уголь", "Молот", "Нагрев", "Заготовка"]
	for title in required:
		if not by_title.has(title):
			execution_message = "Для подковы не хватает карты «%s»." % title
			return
	if not _is_one_connected_network(board_cards, production_links):
		execution_message = "Схема должна быть одной непрерывной сетью. Соедини все элементы."
		return
	if production_links.is_empty():
		execution_message = "Добавь направленные связи между входами и операциями."
		return

	var blank_position: Vector2 = Vector2(by_title["Заготовка"].production_position)
	var consumed_ids := [
		int(by_title["Железо"].id),
		int(by_title["Уголь"].id),
		int(by_title["Заготовка"].id)
	]
	for card in cards.duplicate():
		if consumed_ids.has(int(card.id)):
			cards.erase(card)
	production_links = _filter_links_for_ids(production_links, consumed_ids)
	research_links = _filter_links_for_ids(research_links, consumed_ids)
	_add_card("Подкова", "ИЗДЕЛИЕ")
	var result_card: Dictionary = cards.back()
	result_card.production_place = "board"
	result_card.production_position = blank_position
	execution_message = "Подкова изготовлена. Железо, уголь и заготовка израсходованы; молот и нагрев сохранены."


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
	var has_heat := titles.has("Нагрев")
	var has_hammer := titles.has("Молот")

	# First guided discovery: an iron + heat + hammer experiment reveals forging.
	if has_iron and has_heat and has_hammer and not discoveries.has("Ковка"):
		discoveries.append("Ковка")
		_add_card("Ковка", "ОПЕРАЦИЯ")
		execution_message = "Открытие: «Ковка». Новая операция добавлена в инвентарь."
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
		if parts.size() != 2:
			continue
		var from_id := int(parts[0])
		var to_id := int(parts[1])
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
	var step := minf(104.0, usable_width / maxf(1.0, float(count)))
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


func _add_directed_link(from_id: int, to_id: int) -> void:
	if from_id == to_id:
		return
	var key := "%d:%d" % [from_id, to_id]
	var current := _active_links()
	if not current.has(key):
		current.append(key)
		_set_active_links(current)
		var from_card := _card_by_id(from_id)
		var to_card := _card_by_id(to_id)
		execution_message = "Предварительная реакция: %s → %s. Проверь схему экспериментом." % [str(from_card.title), str(to_card.title)]


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
		if parts.size() == 2 and not ids.has(int(parts[0])) and not ids.has(int(parts[1])):
			kept.append(link)
	return kept


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	_draw_workshop_background()
	draw_rect(Rect2(0, 0, size.x, HEADER_HEIGHT), Color("#11140f"))
	draw_line(Vector2(0, HEADER_HEIGHT), Vector2(size.x, HEADER_HEIGHT), Color("#55452f"), 2.0)
	draw_string(font, Vector2(28, 29), "КУЗНЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, CARD_BORDER)
	draw_string(font, Vector2(28, 49), "ИНЖЕНЕРНАЯ МАСТЕРСКАЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)
	_draw_header_button(_production_button_rect(), "ПРОИЗВОДСТВО", mode == "production")
	_draw_header_button(_research_button_rect(), "ИССЛЕДОВАНИЕ", mode == "research")
	_draw_header_button(_journal_button_rect(), "ЖУРНАЛ", journal_open)
	_draw_header_button(_action_button_rect(), "ВЫПОЛНИТЬ" if mode == "production" else "ИСПЫТАТЬ", true)

	var board := _board_rect()
	draw_rect(board, BOARD_BG)
	draw_rect(board, Color("#65705c"), false, 2.0)
	var mode_title := "ПРОИЗВОДСТВО" if mode == "production" else "ИССЛЕДОВАНИЕ"
	var mode_subtitle := "СОБИРАЙ РАБОЧУЮ ТЕХНОЛОГИЮ · МАТЕРИАЛЫ РАСХОДУЮТСЯ" if mode == "production" else "ПРОВЕРЯЙ ГИПОТЕЗЫ · ЭКСПЕРИМЕНТЫ БЕСПЛАТНЫ"
	draw_string(font, Vector2(board.position.x + 18, board.position.y + 24), mode_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CARD_BORDER)
	draw_string(font, Vector2(board.position.x + 18, board.position.y + 43), mode_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)
	_draw_graph_legend()
	_draw_links()
	for card in _board_cards():
		if int(card.id) != drag_card_id:
			_draw_card(card, Vector2(card[_position_key()]) - CARD_SIZE * 0.5, true)

	draw_rect(Rect2(0.0, size.y - HAND_HEIGHT - STATUS_HEIGHT, size.x, STATUS_HEIGHT), Color("#1d211b"))
	draw_line(Vector2(0, size.y - HAND_HEIGHT - STATUS_HEIGHT), Vector2(size.x, size.y - HAND_HEIGHT - STATUS_HEIGHT), Color("#675638"), 1.0)
	draw_circle(Vector2(27, size.y - HAND_HEIGHT - 27), 5.0, ACCENT)
	draw_string(font, Vector2(42, size.y - HAND_HEIGHT - 23), execution_message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 64, 11, CARD_BORDER)
	_draw_hand()
	if drag_card_id != -1:
		var dragged := _card_by_id(drag_card_id)
		if not dragged.is_empty():
			_draw_card(dragged, drag_position, str(dragged[_place_key()]) == "board")
	if connecting_from_id != -1:
		var source := _card_by_id(connecting_from_id)
		if not source.is_empty():
			draw_line(Vector2(source[_position_key()]), mouse_position, ACCENT, 4.0, true)
			draw_circle(mouse_position, 7.0, ACCENT)
	if journal_open:
		_draw_journal()
	draw_string(font, Vector2(28, size.y - 9), "ПЕРЕТАЩИ КАРТУ НА ПОЛЕ  ·  ПКМ: ПОТЯНИ ОТ ВЫХОДА КО ВХОДУ  ·  ВНИЗУ: РУКА", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)


func _draw_workshop_background() -> void:
	for x in range(0, int(size.x), 48):
		for y in range(int(HEADER_HEIGHT), int(size.y - HAND_HEIGHT - STATUS_HEIGHT), 48):
			draw_circle(Vector2(x + 24, y + 24), 1.0, Color("#394238"))


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


func _draw_header_button(rect: Rect2, label: String, active: bool) -> void:
	var fill := ACCENT if active else Color("#303941")
	draw_rect(rect, fill)
	draw_rect(rect, CARD_BORDER if active else Color("#56616b"), false, 1.0)
	draw_string(font, rect.position + Vector2(8, 25), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 10, INK if active else CARD_BORDER)


func _draw_links() -> void:
	for link in _active_links():
		var parts := link.split(":")
		if parts.size() != 2:
			continue
		var a := _card_by_id(int(parts[0]))
		var b := _card_by_id(int(parts[1]))
		if a.is_empty() or b.is_empty():
			continue
		if str(a[_place_key()]) != "board" or str(b[_place_key()]) != "board":
			continue
		var from_center := Vector2(a[_position_key()])
		var to_center := Vector2(b[_position_key()])
		var direction := (to_center - from_center).normalized()
		if direction == Vector2.ZERO:
			continue
		var from_edge := _card_edge_point(from_center, direction)
		var to_edge := _card_edge_point(to_center, -direction)
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
	var hand_area := _hand_rect()
	draw_rect(hand_area, Color("#11140f"))
	draw_rect(Rect2(0, hand_area.position.y, size.x, 3.0), Color("#8b7044"))
	draw_string(font, Vector2(28, size.y - HAND_HEIGHT + 22), "РУКА / ИНВЕНТАРЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CARD_BORDER)
	draw_string(font, Vector2(28, size.y - HAND_HEIGHT + 39), "%d КАРТ · ПЕРЕТАЩИ НА РАБОЧЕЕ ПОЛЕ" % _hand_cards().size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)
	var hand := _hand_cards()
	for i in range(hand.size()):
		if int(hand[i].id) == drag_card_id:
			continue
		_draw_card(hand[i], _hand_card_rect(i, hand.size()).position, false)


func _draw_card(card: Dictionary, top_left: Vector2, on_board := false) -> void:
	var rect := Rect2(top_left, CARD_SIZE)
	var role_color := _category_color(str(card.category))
	# Drop shadow and paper body.
	draw_rect(Rect2(top_left + Vector2(4, 5), CARD_SIZE), Color("#090b08"))
	draw_rect(rect, CARD_BG)
	draw_rect(rect, Color("#302b21"), false, 2.0)
	draw_rect(Rect2(top_left, Vector2(CARD_SIZE.x, 34)), role_color)
	draw_string(font, top_left + Vector2(10, 22), _category_label(str(card.category)), HORIZONTAL_ALIGNMENT_LEFT, CARD_SIZE.x - 20, 9, Color("#171914"))
	_draw_card_emblem(str(card.category), top_left + Vector2(CARD_SIZE.x * 0.5, 83), role_color)
	draw_string(font, top_left + Vector2(8, 125), str(card.title), HORIZONTAL_ALIGNMENT_CENTER, CARD_SIZE.x - 16, 14, INK)
	draw_line(top_left + Vector2(10, 135), top_left + Vector2(CARD_SIZE.x - 10, 135), Color("#a99a7d"), 1.0)
	draw_string(font, top_left + Vector2(8, 153), "УЗЕЛ СХЕМЫ" if on_board else "В ИНВЕНТАРЕ", HORIZONTAL_ALIGNMENT_CENTER, CARD_SIZE.x - 16, 8, Color("#675b49"))
	if on_board:
		# Explicit, color-coded connection ports make direction readable.
		draw_circle(Vector2(top_left.x, top_left.y + CARD_SIZE.y * 0.5), 6.0, Color("#82b8a0"))
		draw_circle(Vector2(top_left.x + CARD_SIZE.x, top_left.y + CARD_SIZE.y * 0.5), 6.0, ACCENT)
		draw_string(font, top_left + Vector2(3, 76), "ВХ", HORIZONTAL_ALIGNMENT_LEFT, 20, 7, Color("#34483f"))
		draw_string(font, top_left + Vector2(CARD_SIZE.x - 22, 76), "ВЫХ", HORIZONTAL_ALIGNMENT_RIGHT, 20, 7, Color("#594126"))


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
