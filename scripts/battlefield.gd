extends Control

const BLACK := Color("#000000")
const WHITE := Color("#FFFFFF")

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
var status_text := "ВЫБЕРИ КАРТУ В РУКЕ, ЧТОБЫ СЫГРАТЬ ЕЁ"

var top_bar: HBoxContainer
var battlefield: VBoxContainer
var hand_panel: VBoxContainer
var message_label: Label
var player_score_label: Label
var enemy_score_label: Label
var player_cards_row: HBoxContainer
var enemy_cards_row: HBoxContainer
var effects_row: HBoxContainer
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
	hand_panel.custom_minimum_size.y = 72
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
	effects_row = HBoxContainer.new()
	effects_row.alignment = BoxContainer.ALIGNMENT_CENTER
	effects_row.add_theme_constant_override("separation", 8)
	for effect in active_effects:
		effects_row.add_child(_tag(effect))
	if trap_armed:
		effects_row.add_child(_tag("ЛОВУШКА ГОТОВА"))
	if effects_row.get_child_count() == 0:
		effects_row.add_child(_label("НЕТ АКТИВНЫХ ЭФФЕКТОВ", BLACK, 9))
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

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	for data in cards:
		row.add_child(_field_card(data))
	if cards.is_empty():
		row.add_child(_label("ПОЛЕ ПУСТО", WHITE, 9))
	section.add_child(row)
	return section

func _field_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(62, 65)
	_style_panel(panel, WHITE, BLACK)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var glyph := _label("◆", BLACK, 18)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(glyph)
	var title := _label(str(data.name), BLACK, 9)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var power := _label(str(data.power), BLACK, 14)
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(power)
	panel.add_child(box)
	return panel

func _refresh_hand() -> void:
	for child in hand_panel.get_children():
		child.queue_free()
	var header := _label("ТВОЯ РУКА  •  НАЖМИ НА КАРТУ, ЧТОБЫ СЫГРАТЬ", WHITE, 9)
	hand_panel.add_child(header)
	hand_row = HBoxContainer.new()
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 5)
	for i in range(hand_cards.size()):
		var data: Dictionary = hand_cards[i]
		var card := _button("%s\n%s\n%s" % [data.name, data.kind, str(data.power) if data.power > 0 else "ЭФФЕКТ"], 82)
		card.custom_minimum_size.y = 48
		card.add_theme_font_size_override("font_size", 9)
		card.pressed.connect(_play_card.bind(i))
		hand_row.add_child(card)
	if hand_cards.is_empty():
		hand_row.add_child(_label("КАРТ В РУКЕ НЕТ", WHITE, 9))
	hand_panel.add_child(hand_row)

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
	return _label("[ %s ]" % text_value, BLACK, 9)

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
