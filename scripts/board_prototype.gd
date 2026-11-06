extends Control

const CARD_SIZE := Vector2(116, 148)
const HAND_HEIGHT := 178.0
const HEADER_HEIGHT := 64.0
const STATUS_HEIGHT := 30.0
const BOARD_MARGIN := 28.0

const BG := Color("#171b20")
const BOARD_BG := Color("#202830")
const CARD_BG := Color("#d9c9a7")
const CARD_BORDER := Color("#f0e2c3")
const INK := Color("#29251f")
const MUTED := Color("#a9b1b9")
const ACCENT := Color("#d59b54")
const LINK_COLOR := Color("#e1b36f")

var cards: Array[Dictionary] = []
var links: Array[String] = []
var next_card_id := 1

var drag_card_id := -1
var drag_from_hand := false
var drag_offset := Vector2.ZERO
var drag_position := Vector2.ZERO
var connecting_from_id := -1
var execute_button_held := false
var execution_message := "Собери схему и нажми «Выполнить»."
var mouse_position := Vector2.ZERO

var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_test_card("Железо", "МАТЕРИАЛ")
	_add_test_card("Уголь", "МАТЕРИАЛ")
	_add_test_card("Молот", "ИНСТРУМЕНТ")
	_add_test_card("Нагрев", "ОПЕРАЦИЯ")
	_add_test_card("Заготовка", "ОБЪЕКТ")
	queue_redraw()


func _add_test_card(title: String, category: String) -> void:
	cards.append({
		"id": next_card_id,
		"title": title,
		"category": category,
		"place": "hand",
		"position": Vector2.ZERO
	})
	next_card_id += 1


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
			if _execute_button_rect().has_point(mouse_position):
				execute_button_held = true
				accept_event()
				queue_redraw()
				return
			var hit := _card_at(mouse_position)
			if not hit.is_empty():
				drag_card_id = int(hit.id)
				drag_from_hand = hit.place == "hand"
				if drag_from_hand:
					var hand := _hand_cards()
					for i in range(hand.size()):
						if int(hand[i].id) == drag_card_id:
							drag_offset = mouse_position - _hand_card_rect(i, hand.size()).position
							break
				else:
					drag_offset = mouse_position - (Vector2(hit.position) - CARD_SIZE * 0.5)
				drag_position = mouse_position - drag_offset
				accept_event()
		else:
			if execute_button_held:
				if _execute_button_rect().has_point(mouse_position):
					_execute_scheme()
				execute_button_held = false
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
			if not hit.is_empty() and hit.place == "board":
				connecting_from_id = int(hit.id)
				accept_event()
				queue_redraw()
		else:
			if connecting_from_id != -1:
				var target := _card_at(mouse_position, true)
				if not target.is_empty() and target.place == "board":
					_add_link(connecting_from_id, int(target.id))
				connecting_from_id = -1
				accept_event()
				queue_redraw()


func _execute_button_rect() -> Rect2:
	return Rect2(Vector2(size.x - 178.0, 12.0), Vector2(150.0, 40.0))


func _execute_scheme() -> void:
	var board_cards: Array[Dictionary] = []
	var degrees: Dictionary = {}
	for card in cards:
		if card.place == "board":
			board_cards.append(card)
			degrees[int(card.id)] = 0

	if board_cards.size() < 2:
		execution_message = "Нужно разместить на поле хотя бы две карты."
		return

	var valid_links := 0
	for link in links:
		var parts := link.split(":")
		var a_id := int(parts[0])
		var b_id := int(parts[1])
		if degrees.has(a_id) and degrees.has(b_id):
			degrees[a_id] = int(degrees[a_id]) + 1
			degrees[b_id] = int(degrees[b_id]) + 1
			valid_links += 1

	for card_id in degrees:
		if int(degrees[card_id]) == 0:
			execution_message = "Проверь связи: у каждой карты на поле должна быть хотя бы одна связь."
			return

	execution_message = "СХЕМА ПРИНЯТА · %d карт, %d связей. Это проверка структуры — изготовление предмета добавим отдельно." % [board_cards.size(), valid_links]


func _finish_card_drag(release_position: Vector2) -> void:
	var card := _card_by_id(drag_card_id)
	if card.is_empty():
		drag_card_id = -1
		return

	if _hand_rect().has_point(release_position):
		if card.place == "board":
			_remove_links_for_card(drag_card_id)
			card.place = "hand"
			card.position = Vector2.ZERO
	elif _board_rect().has_point(release_position):
		card.place = "board"
		card.position = _clamp_to_board(release_position - drag_offset + CARD_SIZE * 0.5)
	drag_card_id = -1


func _card_at(point: Vector2, board_only := false) -> Dictionary:
	var board_cards := cards.duplicate()
	board_cards.reverse()
	for card in board_cards:
		if card.place != "board":
			continue
		if board_only and card.id == drag_card_id:
			continue
		var rect := Rect2(Vector2(card.position) - CARD_SIZE * 0.5, CARD_SIZE)
		if rect.has_point(point):
			return card

	if board_only:
		return {}
	var hand_cards := _hand_cards()
	for i in range(hand_cards.size() - 1, -1, -1):
		var rect := _hand_card_rect(i, hand_cards.size())
		if rect.has_point(point):
			return hand_cards[i]
	return {}


func _hand_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if card.place == "hand":
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


func _add_link(a: int, b: int) -> void:
	if a == b:
		return
	var low := mini(a, b)
	var high := maxi(a, b)
	var key := "%d:%d" % [low, high]
	if not links.has(key):
		links.append(key)


func _remove_links_for_card(card_id: int) -> void:
	var kept: Array[String] = []
	for link in links:
		var parts := link.split(":")
		if int(parts[0]) != card_id and int(parts[1]) != card_id:
			kept.append(link)
	links = kept


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	draw_rect(Rect2(0, 0, size.x, HEADER_HEIGHT), Color("#111519"))
	draw_string(font, Vector2(28, 39), "КУЗНЯ  /  ИНЖЕНЕРНОЕ ПОЛЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CARD_BORDER)
	var button_rect := _execute_button_rect()
	var button_color := ACCENT if execute_button_held else Color("#8c6338")
	draw_rect(button_rect, button_color)
	draw_rect(button_rect, CARD_BORDER, false, 1.0)
	draw_string(font, button_rect.position + Vector2(19, 26), "ВЫПОЛНИТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)

	var board := _board_rect()
	draw_rect(board, BOARD_BG)
	draw_rect(board, Color("#35414b"), false, 1.0)
	draw_string(font, Vector2(board.position.x + 18, board.position.y + 25), "ПОЛЕ  ·  перетаскивай карты сюда", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)

	_draw_links()
	for card in cards:
		if card.place == "board" and int(card.id) != drag_card_id:
			_draw_card(card, Vector2(card.position) - CARD_SIZE * 0.5)

	draw_rect(Rect2(0.0, size.y - HAND_HEIGHT - STATUS_HEIGHT, size.x, STATUS_HEIGHT), Color("#151a1f"))
	draw_string(font, Vector2(28, size.y - HAND_HEIGHT - 10), execution_message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 56, 11, ACCENT if execution_message.begins_with("СХЕМА ПРИНЯТА") else MUTED)

	_draw_hand()
	if drag_card_id != -1:
		var dragged := _card_by_id(drag_card_id)
		if not dragged.is_empty():
			_draw_card(dragged, drag_position)

	if connecting_from_id != -1:
		var source := _card_by_id(connecting_from_id)
		if not source.is_empty():
			draw_line(Vector2(source.position), mouse_position, ACCENT, 3.0, true)
			draw_circle(mouse_position, 5.0, ACCENT)

	draw_string(font, Vector2(28, size.y - 12), "ЛКМ — переместить  ·  ПКМ от карты к карте — соединить  ·  вернуть карту в нижнюю зону — в руку", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, MUTED)


func _draw_links() -> void:
	for link in links:
		var parts := link.split(":")
		var a := _card_by_id(int(parts[0]))
		var b := _card_by_id(int(parts[1]))
		if a.is_empty() or b.is_empty():
			continue
		if a.place != "board" or b.place != "board":
			continue
		draw_line(Vector2(a.position), Vector2(b.position), LINK_COLOR, 3.0, true)
		draw_circle((Vector2(a.position) + Vector2(b.position)) * 0.5, 4.0, LINK_COLOR)


func _draw_hand() -> void:
	draw_rect(_hand_rect(), Color("#111519"))
	draw_line(Vector2(0, size.y - HAND_HEIGHT), Vector2(size.x, size.y - HAND_HEIGHT), Color("#3b4650"), 1.0)
	draw_string(font, Vector2(28, size.y - HAND_HEIGHT + 22), "РУКА  ·  %d карт" % _hand_cards().size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MUTED)

	var hand := _hand_cards()
	for i in range(hand.size()):
		if int(hand[i].id) == drag_card_id:
			continue
		var rect := _hand_card_rect(i, hand.size())
		_draw_card(hand[i], rect.position)


func _draw_card(card: Dictionary, top_left: Vector2) -> void:
	var rect := Rect2(top_left, CARD_SIZE)
	draw_rect(rect, CARD_BG)
	draw_rect(rect, CARD_BORDER, false, 2.0)
	draw_rect(Rect2(top_left + Vector2(8, 8), CARD_SIZE - Vector2(16, 34)), Color("#c8b58e"), false, 1.0)
	draw_string(font, top_left + Vector2(12, 27), str(card.title), HORIZONTAL_ALIGNMENT_LEFT, CARD_SIZE.x - 24, 15, INK)
	draw_string(font, top_left + Vector2(12, CARD_SIZE.y - 14), str(card.category), HORIZONTAL_ALIGNMENT_LEFT, CARD_SIZE.x - 24, 9, Color("#675b49"))
