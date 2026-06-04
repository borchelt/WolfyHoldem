extends CollisionShape2D
@export var bg: Sprite2D

func _mouse_enter():
	var rect = Rect2(160,112,32,48)
	bg.texture.region = rect
	
func _mouse_exit():
	var rect = Rect2(64,112,32,48)
	bg.texture.region = rect
