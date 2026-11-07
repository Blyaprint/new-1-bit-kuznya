extends Control
@onready var caption: Label = $Caption
@export var button_text := ""
func _ready() -> void:
	caption.text = button_text
func set_caption(value: String) -> void:
	caption.text = value
