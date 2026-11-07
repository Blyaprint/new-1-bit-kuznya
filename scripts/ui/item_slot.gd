extends PanelContainer

var _hover_tween: Tween
var _base_style: StyleBox = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	pivot_offset = custom_minimum_size * 0.5
	_base_style = get_theme_stylebox("panel").duplicate()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_set_highlight(true)


func _on_mouse_exited() -> void:
	_set_highlight(false)


func _set_highlight(active: bool) -> void:
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	var style := _base_style.duplicate() as StyleBoxFlat
	if active:
		style.border_color = Color("#f0c77f")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.bg_color = Color("#29251e")
	else:
		style.border_color = Color("#806b4c")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.bg_color = Color("#1b1d20")
	add_theme_stylebox_override("panel", style)
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.055, 1.055) if active else Vector2.ONE, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
