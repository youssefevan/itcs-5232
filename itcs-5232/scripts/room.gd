extends Node2D
class_name Room

var room_size = Vector2(192 * 8, 144 * 8)

func _ready():
	var game = get_parent().get_parent()
