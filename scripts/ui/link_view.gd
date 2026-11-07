extends Node2D
@onready var line: Line2D = $Line
@onready var from_marker: Sprite2D = $FromMarker
@onready var to_marker: Sprite2D = $ToMarker
func set_points(from_point: Vector2, to_point: Vector2) -> void:
	line.points = PackedVector2Array([from_point, to_point])
	from_marker.position = from_point
	to_marker.position = to_point
