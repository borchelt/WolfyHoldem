extends Area2D
class_name Card
@export var suit: String
@export var number: String
@export var facing: String
@export var pool: String
@export var index: int
@export var selected: bool
@export var bg: Sprite2D

func flip():
	print("Flipping")
	bg.flip()
