extends Control

const BLACK := Color("#000000")
const WHITE := Color("#FFFFFF")

 
class DropZone extends HBoxContainer:
	var controller: Control
	var zone_id := ""

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return controller != null and bool(controller.call("_can_accept_drop", zone_id, data))

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		if controller == null:
			return
		var target_index := -1
		if zone_id == "hand":
			for child in get_children():
				if child is CardFace and at_position.x < child.position.x + child.size.x * 0.5:
					target_index = child.card_index
					break
		controller.call("_handle_drop", zone_id, data, target_index)


class CardFace extends Control:
	const INK := Color("#000000")
	const PAPER := Color("#FFFFFF")
	var controller: Control
	var card_index := -1
	var card_data: Dictionary = {}
	var drop_zone: DropZone
	var compact := false
	var preview_mode := false
	var hovered := false

	func configure(data: Dictionary, owner: Control, index: int, zone: DropZone, small := false) -> void:
		card_data = data
		controller = owner
		card_index = index
		drop_zone = zone
		compact = small
		mouse_filter = Control.MOUSE_FILTER_IGNORE if small else Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(62, 72) if small else Vector2(92, 112)
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		queue_redraw()

	func _on_mouse_entered() -> void:
		hovered = true
		queue_redraw()

	func _on_mouse_exited() -> void:
		hovered = false
		queue_redraw()

	func _draw() -> void:
		var lift := -3.0 if hovered and not preview_mode else 0.0
		if compact:
			draw_rect(Rect2(Vector2(2, 3), size - Vector2(4, 4)), INK)
			draw_rect(Rect2(Vector2(1, 1), size - Vector2(4, 4)), PAPER)
			draw_rect(Rect2(Vector2(1, 1), size - Vector2(4, 4)), INK, false, 2)
			draw_string(ThemeDB.fallback_font, Vector2(5, 17), str(card_data.get("name", "КАРТА")).substr(0, 9), HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 8, INK)
			_draw_symbol(Rect2(9, 23, size.x - 18, 28), str(card_data.get("effect", "creature")))
			draw_rect(Rect2(size.x - 22, size.y - 23, 18, 18), INK)
			draw_string(ThemeDB.fallback_font, Vector2(size.x - 19, size.y - 10), str(card_data.get("power", 0)), HORIZONTAL_ALIGNMENT_CENTER, 14, 10, PAPER)
			return
		draw_rect(Rect2(Vector2(5, 6), size - Vector2(8, 8)), INK)
		draw_rect(Rect2(Vector2(1, lift + 1), size - Vector2(8, 8)), PAPER)
		draw_rect(Rect2(Vector2(1, lift + 1), size - Vector2(8, 8)), INK, false, 3 if preview_mode else 2)
		draw_rect(Rect2(Vector2(5, lift + 5), size - Vector2(16, 16)), INK, false, 1)
		draw_rect(Rect2(Vector2(7, lift + 7), Vector2(size.x - 20, 18)), INK)
		draw_string(ThemeDB.fallback_font, Vector2(10, lift + 20), str(card_data.get("name", "КАРТА")).substr(0, 13), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 9, PAPER)
		var art_rect := Rect2(Vector2(8, lift + 29), Vector2(size.x - 22, 49))
		draw_rect(art_rect, PAPER)
		draw_rect(art_rect, INK, false, 2)
		_draw_symbol(Rect2(art_rect.position + Vector2(8, 5), art_rect.size - Vector2(16, 10)), str(card_data.get("effect", "creature")))
		draw_string(ThemeDB.fallback_font, Vector2(10, lift + 91), str(card_data.get("kind", "КАРТА")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 7, INK)
		draw_rect(Rect2(size.x - 29, lift + size.y - 29, 23, 23), INK)
		draw_rect(Rect2(size.x - 27, lift + size.y - 27, 19, 19), PAPER, false, 1)
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 25, lift + size.y - 11), str(card_data.get("power", 0)), HORIZONTAL_ALIGNMENT_CENTER, 15, 11, INK)
		if hovered and not preview_mode:
			draw_rect(Rect2(Vector2(0, lift), size - Vector2(7, 7)), INK, false, 1)

	func _draw_symbol(area: Rect2, effect: String) -> void:
		var cx := area.position.x + area.size.x * 0.5
		var cy := area.position.y + area.size.y * 0.5
		match effect:
			"curse":
				draw_arc(Vector2(cx, cy), minf(area.size.x, area.size.y) * 0.34, 0.0, TAU * 0.86, 18, INK, 2.0)
				draw_line(Vector2(cx - 7, cy + 5), Vector2(cx + 8, cy - 7), INK, 2.0)
				draw_circle(Vector2(cx + 8, cy - 7), 3.0, INK)
			"trap":
				draw_line(Vector2(area.position.x + 5, area.end.y - 5), Vector2(cx, area.position.y + 4), INK, 3.0)
				draw_line(Vector2(cx, area.position.y + 4), Vector2(area.end.x - 5, area.end.y - 5), INK, 3.0)
				draw_rect(Rect2(cx - 3, cy - 3, 6, 6), INK)
			"relic":
				draw_rect(Rect2(cx - 8, cy - 10, 16, 20), INK)
				draw_rect(Rect2(cx - 4, cy - 6, 8, 12), PAPER)
				draw_rect(Rect2(cx - 2, cy - 4, 4, 8), INK)
			_:
				draw_circle(Vector2(cx, cy - 7), 7, INK)
				draw_rect(Rect2(cx - 10, cy + 1, 20, 16), INK)
				draw_rect(Rect2(cx - 4, cy + 4, 8, 8), PAPER)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if controller == null or compact:
			return null
		var preview := CardFace.new()
		preview.card_data = card_data.duplicate(true)
		preview.preview_mode = true
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.custom_minimum_size = Vector2(124, 158)
		preview.size = Vector2(124, 158)
		preview.queue_redraw()
		set_drag_preview(preview)
		return controller.call("_build_drag_payload", card_index)

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return drop_zone != null and drop_zone._can_drop_data(Vector2.ZERO, data)

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if drop_zone != null and controller != null:
			controller.call("_handle_drop", drop_zone.zone_id, data, card_index)

var turn_number := 1
var player_turn := true
var player_score := 16
var enemy_score := 18
var player_cards: Array[Dictionary] = [
	{"name":"РЫЦАРЬ", "power":5, "kind":"СУЩЕСТВО"},
	{"name":"ДУХ", "power":7, "kind":"СУЩЕСТВО"}
]
var enemy_cards: Array[Dictionary] = [
	{"name":"СКЕЛЕТ", "power":4, "kind":"СУЩЕСТВО"},
	{"name":"ВЕДЬМА", "power":3, "kind":"СУЩЕСТВО"},
	{"name":"СТРАЖ", "power":6, "kind":"СУЩЕСТВО"}
]
var hand_cards: Array[Dictionary] = [
	{"name":"СКЕЛЕТ", "power":4, "kind":"СУЩЕСТВО", "effect":"creature"},
	{"name":"ПОРЧА", "power":0, "kind":"ЭФФЕКТ", "effect":"curse"},
	{"name":"ГОЛЕМ", "power":7, "kind":"СУЩЕСТВО", "effect":"creature"},
	{"name":"ЛОВУШКА", "power":0, "kind":"ЛОВУШКА", "effect":"trap"},
	{"name":"РЕЛИКВИЯ", "power":2, "kind":"РЕЛИКВИЯ", "effect":"relic"}
]
var enemy_deck: Array[Dictionary] = [
	{"name":"ГОБЛИН", "power":3, "kind":"СУЩЕСТВО", "effect":"creature"},
	{"name":"ПАУК", "power":4, "kind":"СУЩЕСТВО", "effect":"creature"},
	{"name":"ПРОКЛЯТИЕ", "power":0, "kind":"ЭФФЕКТ", "effect":"curse"}
]
var active_effects: Array[String] = ["ТУМАН"]
var trap_armed := false
var status_text := "ПЕРЕТАЩИ КАРТУ ИЗ РУКИ В НУЖНУЮ ЗОНУ"

var top_bar: HBoxContainer
var battlefield: VBoxContainer
var hand_panel: VBoxContainer
var message_label: Label
var player_score_label: Label
var enemy_score_label: Label
var player_cards_row: HBoxContainer
var enemy_cards_row: HBoxContainer
var effects_row: DropZone
var hand_row: HBoxContainer
var turn_label: Label
var end_turn_button: Button
var dialog: AcceptDialog

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_screen()
	_refresh()

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size.y = 36
	top_bar.add_theme_constant_override("separation", 6)
	_style_container(top_bar, BLACK, WHITE)
	root.add_child(top_bar)

	battlefield = VBoxContainer.new()
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.add_theme_constant_override("separation", 0)
	_style_container(battlefield, BLACK, WHITE)
	root.add_child(battlefield)

	hand_panel = VBoxContainer.new()
	hand_panel.custom_minimum_size.y = 122
	hand_panel.add_theme_constant_override("separation", 1)
	_style_container(hand_panel, BLACK, WHITE)
	root.add_child(hand_panel)

	dialog = AcceptDialog.new()
	dialog.title = "ПОДЗЕМЕЛЬЕ"
	add_child(dialog)

func _refresh() -> void:
	_refresh_top()
	_refresh_battlefield()
	_refresh_hand()

func _refresh_top() -> void:
	for child in top_bar.get_children():
		child.queue_free()
	var menu := _button("≡", 32)
	menu.pressed.connect(func(): _open_dialog("МЕНЮ\n\nПродолжить игру или выйти в главное меню."))
	top_bar.add_child(menu)
	var journal := _button("ЖУРНАЛ", 68)
	journal.pressed.connect(func(): _open_dialog("ЖУРНАЛ БОЯ\n\n%s" % status_text))
	top_bar.add_child(journal)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	turn_label = Label.new()
	turn_label.text = "ХОД %d  •  %s" % [turn_number, "ТВОЙ" if player_turn else "ВРАГА"]
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.add_theme_color_override("font_color", WHITE)
	top_bar.add_child(turn_label)
	end_turn_button = _button("КОНЕЦ ХОДА →", 112)
	end_turn_button.disabled = not player_turn
	end_turn_button.pressed.connect(_end_turn)
	top_bar.add_child(end_turn_button)

func _refresh_battlefield() -> void:
	for child in battlefield.get_children():
		child.queue_free()

	var enemy_section := _make_side_section("ПРОТИВНИК", enemy_score, enemy_cards, true)
	battlefield.add_child(enemy_section)

	var middle := VBoxContainer.new()
	middle.custom_minimum_size.y = 54
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 3)
	_style_container(middle, WHITE, BLACK)
	var effect_title := _label("ЭФФЕКТЫ ПОЛЯ", BLACK, 9)
	effect_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(effect_title)
	effects_row = DropZone.new()
	effects_row.controller = self
	effects_row.zone_id = "effects"
	effects_row.alignment = BoxContainer.ALIGNMENT_CENTER
	effects_row.add_theme_constant_override("separation", 8)
	effects_row.custom_minimum_size.y = 24
	for effect in active_effects:
		effects_row.add_child(_tag(effect))
	if trap_armed:
		effects_row.add_child(_tag("ЛОВУШКА ГОТОВА"))
	if effects_row.get_child_count() == 0:
		var empty_effects := _label("ПЕРЕТАЩИ СЮДА КАРТУ ЭФФЕКТА", BLACK, 9)
		empty_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effects_row.add_child(empty_effects)
	middle.add_child(effects_row)
	message_label = _label(status_text, BLACK, 9)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(message_label)
	battlefield.add_child(middle)

	var player_section := _make_side_section("ТВОЁ ПОЛЕ", player_score, player_cards, false)
	battlefield.add_child(player_section)

func _make_side_section(title: String, score: int, cards: Array[Dictionary], opponent: bool) -> Control:
	var section := VBoxContainer.new()
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 2)
	var header := HBoxContainer.new()
	var name_label := _label(title, WHITE, 10)
	header.add_child(name_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var score_label := _label("ОЧКИ  %02d" % score, WHITE, 15)
	header.add_child(score_label)
	section.add_child(header)

	var row: HBoxContainer
	if opponent:
		row = HBoxContainer.new()
	else:
		var player_drop_zone := DropZone.new()
		player_drop_zone.controller = self
		player_drop_zone.zone_id = "player_field"
		row = player_drop_zone
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	for data in cards:
		row.add_child(_field_card(data))
	if cards.is_empty():
		var empty_field := _label("ПЕРЕТАЩИ СЮДА СУЩЕСТВО" if not opponent else "ПОЛЕ ПУСТО", WHITE, 9)
		empty_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(empty_field)
	section.add_child(row)
	return section

func _field_card(data: Dictionary) -> Control:
	var face := CardFace.new()
	face.card_data = data
	face.compact = true
	face.custom_minimum_size = Vector2(62, 72)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return face

func _refresh_hand() -> void:
	for child in hand_panel.get_children():
		child.queue_free()
	var header := _label("ТВОЯ РУКА  •  ПЕРЕТАЩИ КАРТУ НА ПОЛЕ ИЛИ В ЗОНУ ЭФФЕКТОВ", WHITE, 9)
	hand_panel.add_child(header)
	var hand_drop_zone := DropZone.new()
	hand_drop_zone.controller = self
	hand_drop_zone.zone_id = "hand"
	hand_row = hand_drop_zone
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", -13)
	hand_row.custom_minimum_size.y = 112
	for i in range(hand_cards.size()):
		var face := CardFace.new()
		face.configure(hand_cards[i], self, i, hand_drop_zone)
		face.tooltip_text = "Зажми и перетащи карту"
		face.pivot_offset = Vector2(46, 106)
		if hand_cards.size() > 1:
			face.rotation_degrees = lerpf(-4.0, 4.0, float(i) / float(hand_cards.size() - 1))
		face.z_index = i
		hand_row.add_child(face)
	if hand_cards.is_empty():
		var no_cards := _label("КАРТ В РУКЕ НЕТ", WHITE, 9)
		no_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_row.add_child(no_cards)
	hand_panel.add_child(hand_row)

func _build_drag_payload(index: int) -> Dictionary:
	return {"type": "hand_card", "index": index}

func _can_accept_drop(zone_id: String, payload: Variant) -> bool:
	if not player_turn or not (payload is Dictionary):
		return false
	if str(payload.get("type", "")) != "hand_card":
		return false
	var index := int(payload.get("index", -1))
	if index < 0 or index >= hand_cards.size():
		return false
	if zone_id == "hand":
		return true
	var data: Dictionary = hand_cards[index]
	var effect := str(data.get("effect", ""))
	if zone_id == "player_field":
		return effect == "creature" and player_cards.size() < 5
	if zone_id == "effects":
		return effect in ["curse", "trap", "relic"]
	return false

func _handle_drop(zone_id: String, payload: Variant, target_index: int = -1) -> void:
	if not _can_accept_drop(zone_id, payload):
		status_text = "ЭТУ КАРТУ НЕЛЬЗЯ СЮДА ПОЛОЖИТЬ"
		_refresh()
		return
	var source_index := int(payload.get("index", -1))
	if zone_id == "hand":
		if target_index < 0:
			target_index = hand_cards.size() - 1
		var moved: Dictionary = hand_cards.pop_at(source_index)
		if source_index < target_index:
			target_index -= 1
		hand_cards.insert(clampi(target_index, 0, hand_cards.size()), moved)
		status_text = "ПОРЯДОК КАРТ В РУКЕ ИЗМЕНЁН"
		_refresh()
		return
	_play_card(source_index)

func _play_card(index: int) -> void:
	if not player_turn or index < 0 or index >= hand_cards.size():
		return
	var data: Dictionary = hand_cards[index]
	match str(data.effect):
		"creature":
			if player_cards.size() >= 5:
				status_text = "НА ТВОЁМ ПОЛЕ УЖЕ 5 КАРТ"
				_refresh()
				return
			player_cards.append(data)
			player_score += int(data.power)
			status_text = "%s ВЫХОДИТ НА ПОЛЕ: +%d ОЧКОВ" % [data.name, data.power]
		"curse":
			enemy_score = max(0, enemy_score - 3)
			active_effects.append("ПОРЧА")
			status_text = "ПОРЧА! ПРОТИВНИК ТЕРЯЕТ 3 ОЧКА"
		"trap":
			trap_armed = true
			status_text = "ЛОВУШКА УСТАНОВЛЕНА: СЛЕДУЮЩАЯ КАРТА ВРАГА ОСЛАБНЕТ"
		"relic":
			player_score += int(data.power)
			active_effects.append("РЕЛИКВИЯ")
			status_text = "РЕЛИКВИЯ ДАЁТ ТЕБЕ +%d ОЧКА" % data.power
	hand_cards.remove_at(index)
	_refresh()

func _end_turn() -> void:
	if not player_turn:
		return
	player_turn = false
	status_text = "ПРОТИВНИК РАЗЫГРЫВАЕТ КАРТУ..."
	_refresh()
	await get_tree().create_timer(0.35).timeout
	_enemy_play()
	player_turn = true
	turn_number += 1
	if hand_cards.size() < 5:
		hand_cards.append({"name":"НАЁМНИК", "power":3, "kind":"СУЩЕСТВО", "effect":"creature"})
	status_text = "ТВОЙ ХОД. ПРОТИВНИК НАБРАЛ %d ОЧКОВ" % enemy_score
	_refresh()
	_check_round_end()

func _enemy_play() -> void:
	if enemy_deck.is_empty():
		status_text = "ПРОТИВНИК ПАСУЕТ"
		return
	var data: Dictionary = enemy_deck.pop_front()
	if trap_armed:
		data = data.duplicate()
		data.power = max(1, int(data.power) - 2)
		trap_armed = false
	if data.effect == "curse":
		player_score = max(0, player_score - 2)
		active_effects.append("ВРАЖЕСКАЯ ПОРЧА")
		status_text = "ПРОТИВНИК НАКЛАДЫВАЕТ ПОРЧУ: -2 ОЧКА"
	else:
		if enemy_cards.size() < 5:
			enemy_cards.append(data)
			enemy_score += int(data.power)
		status_text = "ПРОТИВНИК ВЫКЛАДЫВАЕТ %s: +%d ОЧКА" % [data.name, data.power]

func _check_round_end() -> void:
	if hand_cards.is_empty() and enemy_deck.is_empty():
		var result := "НИЧЬЯ"
		if player_score > enemy_score:
			result = "ТЫ ВЫИГРАЛ РАУНД!"
		elif enemy_score > player_score:
			result = "ПРОТИВНИК ВЫИГРАЛ РАУНД"
		_open_dialog("%s\n\nТВОИ ОЧКИ: %d\nОЧКИ ВРАГА: %d" % [result, player_score, enemy_score])

func _open_dialog(text_value: String) -> void:
	dialog.dialog_text = text_value
	dialog.popup_centered()

func _button(text_value: String, width: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.x = width
	button.add_theme_font_size_override("font_size", 10)
	var normal := StyleBoxFlat.new()
	normal.bg_color = WHITE
	normal.border_color = WHITE
	normal.set_border_width_all(1)
	var hover := StyleBoxFlat.new()
	hover.bg_color = BLACK
	hover.border_color = WHITE
	hover.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", BLACK)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_color_override("font_pressed_color", WHITE)
	button.add_theme_color_override("font_disabled_color", BLACK)
	return button

func _label(text_value: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

func _tag(text_value: String) -> Label:
	var tag := _label("[ %s ]" % text_value, BLACK, 9)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tag

func _style_container(control: Control, background: Color, border: Color) -> void:
	if control is PanelContainer:
		_style_panel(control, background, border)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = background
		style.border_color = border
		style.set_border_width_all(1)
		control.add_theme_stylebox_override("panel", style)
		control.add_theme_color_override("font_color", border)

func _style_panel(control: Control, background: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	control.add_theme_stylebox_override("panel", style)
