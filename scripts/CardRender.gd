extends Sprite2D
@export var SuitSprite: Sprite2D
@export var NumberSprite: Sprite2D
@export var master: Area2D
@export var bg: Sprite2D


var SuitSpriteMap  = {
	"Diamond": {"X": .5, "Y": 48},
	"Heart": {"X": 17.75, "Y": 48},
	"Club": {"X": 35 , "Y": 48},
	"Spade": {"X": 50, "Y": 48}
}

var SpriteNumberMap = {
	"1": {
		"Red": {"X": 67 , "Y": 48},
		"Black": {"X": 161 , "Y": 48}
			},
	"2": {
		"Red": {"X": 81 , "Y": 48},
		"Black": {"X":175 , "Y":48 }
			},
	"3": {
		"Red": {"X": 98, "Y": 48},
		"Black": {"X": 192 , "Y": 48 }
			},
	"4": {
		"Red": {"X": 67 , "Y": 64},
		"Black": {"X": 161 , "Y": 64}
			},
	"5": {
		"Red": {"X": 81 , "Y": 64},
		"Black": {"X":175 , "Y":64 }
			},
	"6": {
		"Red": {"X": 98, "Y": 64},
		"Black": {"X": 192 , "Y": 64 }
			},
	"11": {
		"Red": {"X": 3 , "Y": 64},
		"Black": {"X": 3 , "Y": 80}
			},
	"12": {
		"Red": {"X": 18 , "Y": 64},
		"Black": {"X":18 , "Y":80 }
			},
	"13": {
		"Red": {"X": 34, "Y": 64},
		"Black": {"X": 34 , "Y": 80 }
			},
	"14": {
		"Red": {"X": 193, "Y": 145},
		"Black": {"X": 208 , "Y": 145 }
			},
	"7": {
		"Red": {"X": 67 , "Y": 80},
		"Black": {"X": 161 , "Y": 80}
			},
	"8": {
		"Red": {"X": 81 , "Y": 80},
		"Black": {"X":175 , "Y":80 }
			},
	"9": {
		"Red": {"X": 98, "Y": 80},
		"Black": {"X": 192 , "Y": 80 }
			},
	"10": {
		"Red": {"X": 178, "Y": 160},
		"Black": {"X": 193 , "Y": 160 }
			},

}
# Called when the node enters the scene tree for the first time.
func _ready():
	
		var suit = master.suit
		var number = master.number
		var facing = master.facing
		if(facing == "DOWN"):
			SuitSprite.hide()
			NumberSprite.hide()
			bg.texture.region = Rect2(0,112,32,48)
			
		var suitX = SuitSpriteMap[suit].X
		var suitY = SuitSpriteMap[suit].Y
		SuitSprite.texture.region = Rect2(suitX, suitY, 13, 13)
		
		var suitColor = "Black" if(suit == "Club" || suit == "Spade") else "Red"
		
		
		var numberX = SpriteNumberMap[number][suitColor].X
		var numberY = SpriteNumberMap[number][suitColor].Y
		NumberSprite.texture.region = Rect2(numberX, numberY, 15, 15)
		

func flip():
		print("flipping")
		var suit = master.suit
		var number = master.number
		var facing = master.facing
		if(facing == "DOWN"):
			SuitSprite.hide()
			NumberSprite.hide()
			bg.texture.region = Rect2(0,112,32,48)
		else:
			SuitSprite.show()
			NumberSprite.show()
			bg.texture.region = Rect2(64,112,32,48)
		var suitX = SuitSpriteMap[suit].X
		var suitY = SuitSpriteMap[suit].Y
		SuitSprite.texture.region = Rect2(suitX, suitY, 13, 13)
		
		var suitColor = "Black" if(suit == "Club" || suit == "Spade") else "Red"
		
		
		var numberX = SpriteNumberMap[number][suitColor].X
		var numberY = SpriteNumberMap[number][suitColor].Y
		NumberSprite.texture.region = Rect2(numberX, numberY, 15, 15)
		

