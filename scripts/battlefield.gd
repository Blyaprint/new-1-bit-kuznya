extends Control

const INK := Color("#000000")
const PAPER := Color("#FFFFFF")

var turn_number := 1
var player_turn := true
var selected_card := -1

var hand_cards := [
	{"name": "СКЕЛЕТ", "power": 4, "kind": "СУЩЕСТВО"},
	{"name": "ПОРЧА", "power": 0, "kind": "ЭФФЕКТ"},
	{"name": "ГОЛЕМ", "power": 7, "kind": "СУЩЕСТВО"},
	{"name": "ЛОВУШКА", "power": 0, "kind": "ЛОВУШКА"},
	{"name": "РЕЛИКВИЯ", "power": 2, "kind": "РЕЛИКВИЯ"}
]

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_top_bar())
	root.add_child(_build_battlefield())
	root.add_child(_build_hand())

func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 36
	bar.add_theme_constant_override("separation", 8)
	_style_panel(bar, INK, PAPER)

	var menu := _make_button("≡", 34)
	menu.pressed.connect(func(): _show_message("МЕНЮ — В РАЗРАБОТКЕ"))
	bar.add_child(menu)

	var journal := _make_button("ЖУРНАЛ", 76)
	journal.pressed.connect(func(): _show_message("ЖУРНАЛ БОЯ — ПОКА ПУСТ"))
	bar.add_child(journal)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var round_label := Label.new()
	round_label.text = "РАУНД I  •  ХОД %d" % turn_number
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_label.add_theme_color_override("font_color", PAPER)
	bar.add_child(round_label)

	var end_turn := _make_button("КОНЕЦ ХОДА →", 118)
	end_turn.pressed.connect(_end_turn)
	bar.add_child(end_turn)
	return bar

func _build_battlefield() -> Control:
	var field := VBoxContainer.new()
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 0)
	_style_panel(field, INK, PAPER)

	field.add_child(_build_opponent_row())
	field.add_child(_build_effect_strip())
	field.add_child(_build_player_row())
	return field

func _build_opponent_row() -> Control:
	return _build_side_row("ПРОТИВНИК", 18, [
		{"name":"СКЕЛЕТ", "power":4},
		{"name":"ВЕДЬМА", "power":3},
		{"name":"СТРАЖ", "power":6}
	], true)

func _build_player_row() -> Control:
	return _build_side_row("ТВОЁ ПОЛЕ", 16, [
		{"name":"РЫЦАРЬ", "power":5},
		{"name":"ДУХ", "power":7}
	], false)

func _build_side_row(title: String, score: int, cards: Array, opponent: bool) -> Control:
	var side := VBoxContainer.new()
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 3)

	var header := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_color_override("font_color", PAPER)
	header.add_child(name_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var score_label := Label.new()
	score_label.text = "ОЧКИ  %02d" % score
	score_label.add_theme_color_override("font_color", PAPER)
	score_label.add_theme_font_size_override("font_size", 16)
	header.add_child(score_label)
	side.add_child(header)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for card_data in cards:
		row.add_child(_make_field_card(card_data.name, card_data.power, opponent))
	side.add_child(row)
	return side

func _build_effect_strip() -> Control:
	var strip := HBoxContainer.new()
	strip.custom_minimum_size.y = 42
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 8)
	_style_panel(strip, PAPER, INK)

	var label := Label.new()
	label.text = "ЭФФЕКТЫ ПОЛЯ"
	label.add_theme_color_override("font_color", INK)
	strip.add_child(label)
	strip.add_child(_make_tag("ПРОКЛЯТИЕ"))
	strip.add_child(_make_tag("ТУМАН"))
	return strip

func _build_hand() -> Control:
	var hand := VBoxContainer.new()
	hand.custom_minimum_size.y = 72
	hand.add_theme_constant_override("separation", 2)
	_style_panel(hand, INK, PAPER)

	var header := Label.new()
	header.text = "ТВОЯ РУКА"
	header.add_theme_color_override("font_color", PAPER)
	header.add_theme_font_size_override("font_size", 10)
	hand.add_child(header)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 6)
	for i in range(hand_cards.size()):
		var data: Dictionary = hand_cards[i]
		var card := _make_hand_card(i, data)
		cards.add_child(card)
	hand.add_child(cards)
	return hand

func _make_field_card(card_name: String, power: int, opponent: bool) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(66, 74)
	card.add_theme_constant_override("separation", 2)
	_style_panel(card, PAPER, INK)

	var emblem := Label.new()
	emblem.text = "◆"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.add_theme_color_override("font_color", INK)
	emblem.add_theme_font_size_override("font_size", 20)
	card.add_child(emblem)

	var name := Label.new()
	name.text = card_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_color", INK)
	name.add_theme_font_size_override("font_size", 9)
	card.add_child(name)

	var value := Label.new()
	value.text = str(power)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_color_override("font_color", INK)
	value.add_theme_font_size_override("font_size", 15)
	card.add_child(value)
	return card

func _make_hand_card(index: int, data: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(78, 48)
	card.text = "%s\n%s  %d" % [data.name, data.kind, data.power]
	card.add_theme_font_size_override("font_size", 9)
	_style_button(card)
	card.pressed.connect(func(): _select_card(index))
	return card

func _make_tag(text_value: String) -> Label:
	var tag := Label.new()
	tag.text = "[ %s ]" % text_value
	tag.add_theme_color_override("font_color", INK)
	tag.add_theme_font_size_override("font_size", 10)
	return tag

func _make_button(text_value: String, width: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.x = width
	button.add_theme_font_size_override("font_size", 10)
	_style_button(button)
	return button

func _style_panel(control: Control, background: Color, foreground: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = foreground
	style.set_border_width_all(1)
	control.add_theme_stylebox_override("panel", style)
	if control is PanelContainer:
		control.add_theme_stylebox_override("panel", style)

func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PAPER
	normal.border_color = PAPER
	normal.set_border_width_all(1)
	var hover := StyleBoxFlat.new()
	hover.bg_color = INK
	hover.border_color = PAPER
	hover.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", PAPER)

func _select_card(index: int) -> void:
	selected_card = index
	var data: Dictionary = hand_cards[index]
	_show_message("%s — %s. СИЛА: %d" % [data.name, data.kind, data.power])

func _end_turn() -> void:
	player_turn = not player_turn
	if player_turn:
		turn_number += 1
	_show_message("ХОД %d: %s" % [turn_number, "ИГРОК" if player_turn else "ПРОТИВНИК"])

func _show_message(message: String) -> void:
	print(message)
