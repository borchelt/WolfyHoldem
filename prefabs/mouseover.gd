extends Control

@export var bg: Sprite2D
@export var master: Card
@export var rb: RigidBody2D
var moving = false
var mouseOn = false
var offset
func _on_mouse_entered():
	if(master.pool != "river"):
		mouseOn = true
		if(master.facing == "UP"):
			var rect = Rect2(160,112,32,48)
			bg.texture.region = rect
		else:
			var rect = Rect2(96,112,32,48)
			bg.texture.region = rect



func _on_mouse_exited():
	if(master.pool != "river"):
		mouseOn = false
		if(master.selected == false): 
			if(master.facing == "UP"):
				var rect = Rect2(64,112,32,48)
				bg.texture.region = rect
			else:
				var rect = Rect2(0,112,32,48)
				bg.texture.region = rect
	
func _input(event):
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			moving = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mouseOn:
				
			if master.selected:
				moving = true
				master.selected = false
				var rect = Rect2(64,112,32,48)
				bg.texture.region = rect
			else:
				var cards = master.get_parent().get_children()
				for card in cards:
					if card is Card && card != master && card.pool == master.pool:
						card.selected = false
						
						if(card.facing == "UP"):
							var rect = Rect2(64,112,32,48)
							card.bg.texture.region = rect
						else:
							var rect = Rect2(0,112,32,48)
							card.bg.texture.region = rect
				print(master.index)
				moving = true
				master.selected = true
			
