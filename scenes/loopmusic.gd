extends AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.

func _process(delta):
	if(playing == false):
		self.play()
