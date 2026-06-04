extends Node2D
@export var button: TextureButton
@export var tradeButton: TextureButton
@export var notradeButton: TextureButton
@export var winnerLabel: Label
@export var label: Label
@export var playermoneyLabel: Label
@export var enemyLabel: Label
@export var audio: AudioStreamPlayer2D
@export var deal1: AudioStreamOggVorbis
@export var deal2: AudioStreamOggVorbis
@export var deal3: AudioStreamOggVorbis
@export var deal4: AudioStreamOggVorbis
@export var deal5: AudioStreamOggVorbis
@export var deal6: AudioStreamOggVorbis
@export var deal7: AudioStreamOggVorbis
@export var deal8: AudioStreamOggVorbis
@export var deal9: AudioStreamOggVorbis
@export var chips1: AudioStreamOggVorbis
@export var chips2: AudioStreamOggVorbis
@export var chips3: AudioStreamOggVorbis
@export var chips4: AudioStreamOggVorbis
@export var chips5: AudioStreamOggVorbis
@export var chips6: AudioStreamOggVorbis
@export var chips7: AudioStreamOggVorbis
@export var winSound: AudioStreamOggVorbis
@export var loseSound: AudioStreamOggVorbis
@export var moneyLabel: Label
@export var wagerLabel: Label
@export var bumpButton: TextureButton
@export var chipAudio: AudioStreamPlayer2D
@export var winloseAudio: AudioStreamPlayer2D
@export var foldbutton: TextureButton
@export var Button10: TextureButton
@export var Button20: TextureButton
@export var Button50: TextureButton
@export var Button100: TextureButton
@export var ButtonClicker: AudioStreamPlayer2D
@export var enemyMoneyLabel: Label
var z = 0
var chipley = preload("res://chipley.tscn")
var playerbetamt = 10
var playerRaiseAmt = 0
var enemybet = 10
var enemyMoney = 100
var hasSetBet = true
var startHand = true
var lastroundWinner = "n/a"
var card = preload("res://prefabs/card.tscn")
var dealcd = 0.0
var deck = []
var numburned = 0
var river = []
var hole = []
var shop = []
var enemy = []
var enemyHand = "NOTHING!"
var enemyKicker = ""
var stage = 0
var tradesLeft = 0
var audiowheel = [deal1,deal2,deal3,deal4,deal5,deal6,deal7,deal8,deal9]
var playermoney = 100
var updatedplayermoney = false
var checkedHand = false
var folded = false
var wagered = int(0)
var pot = 0
var chipleyWinner= null
# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	button.pressed.connect(deal)
	tradeButton.pressed.connect(trade)
	notradeButton.pressed.connect(tradePass)
	bumpButton.pressed.connect(bump)
	foldbutton.pressed.connect(fold)
	Button10.pressed.connect(playerSetBet)
	Button20.pressed.connect(playerSetBet)
	Button50.pressed.connect(playerSetBet)
	Button100.pressed.connect(playerSetBet)
	var group = ButtonGroup.new()
	Button10.button_group = group
	Button20.button_group = group
	Button50.button_group = group
	Button100.button_group = group

#handles the response time stuff
func _process(delta):
	#spawn enemy chipleys first
	if(hasSetBet == false):
		print("enemy money")
		print(enemyMoney)
		print(wagered)
		moveMoney(enemybet, "em")
		enemyMoneyLabel.text = str(enemyMoney)
		initBet()
		wagerLabel.text = str(wagered)
		hasSetBet = true
	#next check for winner of the battle
	
	if(stage == 0 && updatedplayermoney == false):

		z +=1
		if(chipleyWinner == "player" && folded == false):
			moveMoney(pot, "pot", "pm") 
			
		elif(chipleyWinner == "enemy" || folded == true):
			enemybet=0
			moveMoney(pot,"pot","em")
			wagerLabel.text = str(wagered)
			
		else:

			moveMoney(pot/2, "pot", "em")
			moveMoney(pot, "pot", "pm")
		if(enemyMoney == 0):
			
			enemyMoney = playermoney*2
		updatedplayermoney == true
		chipleyWinner = null
	#update player money and unfold
	if(stage == 1 && updatedplayermoney == false):
		folded = false
		updatedplayermoney = true
	#if no trades, update ui
	if(tradesLeft == 0):
		if(chipleyWinner):
			button.visible = true
		elif(stage == 4):
			button.visible = false
		else:
			button.visible = true
		tradeButton.visible = false
		notradeButton.visible = false
		bumpButton.visible = false
		foldbutton.visible = false
	#if trades visible, update ui
	else:
		tradeButton.visible = true
		notradeButton.visible = true
		bumpButton.visible = true
		button.visible = false
		foldbutton.visible = true
	##check for deal cooldown
	if(dealcd > 0.0):
		dealcd -= 1.0*delta
	else:
		dealcd = 0
	#once out of trades and hands, check all hands
	if(stage == 4 && tradesLeft == 0 && checkedHand == false):
		
		handCheck("enemy")
		handCheck("player")
		
		checkedHand = true
		for child in get_children():
			if(child is Card):
				if(child.facing == "DOWN"):
					child.facing = "UP"
					child.flip()
		
		chipleyFight()
	#change ui based on if the winner is up or not
	if(stage == 4 && tradesLeft == 0):
		winnerLabel.visible = true
		enemyLabel.visible = true
	#change ui
	else:
		winnerLabel.visible = false
		enemyLabel.visible = false
#spawns initial chipleys
func initBet():
	
	var time = .04
	if((wagered / 10) > 25):
		time = 1/(wagered/10)
	for i in range(wagered / 10 ):
		newChipley("enemy") 
		await get_tree().create_timer(time).timeout 
#let players set bets
func playerSetBet():
	var audioRoulette = [chips2,chips3,chips4,chips5,chips6,chips7]
	audioRoulette.shuffle()
	ButtonClicker.stream = audioRoulette[0]
	ButtonClicker.play()
	if(Button10.button_pressed):
		playerbetamt = 10
	elif(Button20.button_pressed):
		playerbetamt = 20
	elif(Button50.button_pressed):
		playerbetamt = 50
	elif(Button100.button_pressed):
		playerbetamt = 100


func tradePass():
	
		
	if(tradesLeft != 0):
		tradesLeft = 0
		
		moveMoney(wagered,"empm")
		enemyMoneyLabel.text = str(enemyMoney)
		var time = .04
		if((wagered / 10) > 25):
			time = 1/(wagered/10)
		#spawn chipleys
		for i in range((wagered) / 20):
			newChipley("player")
			await get_tree().create_timer(time).timeout 
		for i in range((wagered - enemybet) / 20):
			newChipley("enemy")
			await get_tree().create_timer(time).timeout 
		print("moneytopot")
		moveMoney(wagered, "w")
		wagered = 0
		wagerLabel.text = str(wagered)
	tradesLeft = 0
	handCheck("enemy")
	handCheck("player")
		
func fold():
	lastroundWinner = "enemy"
	folded = true
	stage = 4
	tradesLeft = 0
	moveMoney(wagered, 'w')
	updatedplayermoney = false
func newChipley(player):
	var audioRoulette = [chips2,chips3,chips4,chips5,chips6,chips7]
	audioRoulette.shuffle()
	chipAudio.stream = audioRoulette[0]
	chipAudio.play()
	var newchip = chipley.instantiate()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var my_random_numberY
	if(player == "enemy"):
		my_random_numberY = rng.randi_range(50, 100)
		newchip.modulate = Color(1,0,0)
		newchip.team = "enemy"
	else:
		my_random_numberY = rng.randi_range(350, 400)
		newchip.team = "player"
	var my_random_numberX = rng.randi_range(750, 850)
	var vec2 = Vector2(my_random_numberX, my_random_numberY)
	newchip.global_position = vec2
	add_child(newchip)
func chipleyFight():
	for child in get_children():
		if(child is Chipley):
			if(lastroundWinner == child.team):
				child.winner = true
			child.timer.start()

	#var playerChipleys = []
	#var enemyChipleys = []
	#var rng = RandomNumberGenerator.new()
	#rng.randomize()
	#for child in get_children():
		#
		#if(child is Chipley):
			#if(child.team == "enemy"):
				#enemyChipleys.push_front(child)
				#enemyChipleys.shuffle()
			#else:
				#playerChipleys.push_front(child)
				#playerChipleys.shuffle()
				#
	#for i in range(playerChipleys.size()):
		#if(enemyChipleys.size() < 1):
			#break 
		#if(playerChipleys[i].goal == null):
			#playerChipleys[i].goal = enemyChipleys[0]
			#enemyChipleys.shuffle()
	#for i in range(enemyChipleys.size()):
		#if(playerChipleys.size() < 1):
			#break 
		#if(enemyChipleys[i].goal == null):
			#enemyChipleys[i].goal = playerChipleys[0]
			#playerChipleys.shuffle()
func bump():
	if(tradesLeft != 0 && playermoney > wagered):
		var audioRoulette = [chips2,chips3,chips4,chips5,chips6,chips7]
		audioRoulette.shuffle()
		chipAudio.stream = audioRoulette[0]
		chipAudio.play()
		audioRoulette.pop_front()
		##player should only be able to raise up to the enemies remaining money 
		#if(playerbetamt >= enemyMoney+enemybet):
			#print("player bet over max")
			#playerbetamt = enemyMoney-enemybet
		if(playerbetamt > playermoney):
			playerbetamt = playermoney
		playerRaiseAmt += playerbetamt
		print(str('player has raised: ',playerRaiseAmt))
		moveMoney(playerRaiseAmt, 'pm')

		wagerLabel.text = str(wagered)
func deal():
	if(tradesLeft > 0):
		return
	if(stage == 4):
		stage = 0
		river = []
		hole = []
		shop = []
		deck = []
		enemy = []
	
	if(stage == 0):
		river = []
		hole = []
		shop = []
		deck = []
		enemy = []
	numburned = 0
	if(dealcd != 0):
		return
		
	dealcd = 0.15
	if(stage == 0):
		checkedHand = false
		for child in get_children():
			if child is Card:
				child.queue_free()
			if child is Chipley:
				child.queue_free()
	

	var suits = ["Diamond", "Club", "Spade", "Heart"]
	var nums = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14"]
	var stages = [0, 4, 2, 2, 2]
	
	if(stage == 0):
		for i in range(7):
			if(i>3):
				i= i-3

			var suit = suits[i]
			for f in range(14):

				var fcard = [suit, nums[f]]
				deck.append(fcard)
				
		for i in range(7):
			deck.shuffle()
	
	await dealCard(stages[stage],"river")
	
	if(stage == 0):
		await dealCard(2,"hole")
		await dealCard(2, "enemy")
		await dealCard(3,"shop")
	
	handCheck("enemy", true)
	stage+=1
	tradesLeft=1
	handCheck("player");	
	playerRaiseAmt = 0
func trade():
	
	if(tradesLeft < 1):
		return
	else:
		tradesLeft-=1
	var selectedShop
	var selectednum = 0
	var delindexhole
	var delindexchild
	var childCard
	var holeCard
	for child in get_children():
		if(child is Card):
			if(child.selected && selectednum < 2):
				selectednum+=1
				match child.pool:
					"hole":
						delindexhole = child.index
						holeCard = child
						
					"shop":
						delindexchild = child.index
						childCard = child
					
	if(selectednum != 2):
		tradesLeft=1
		
		return "done"

	if(enemyMoney <= 0):
		wagered = 0
		return
	if(playermoney <= 0):
		wagered = 0
		return
	if(wagered < 10):
		moveMoney(10, 'em')
		moveMoney(10, 'pm')
		print("increased wager to 20")
	moveMoney(wagered, "empm")
	enemyMoneyLabel.text = str(enemyMoney)
	for i in range(wagered / 20):
			newChipley("player")
			await get_tree().create_timer(.04).timeout 
	for i in range((wagered - enemybet) / 20):
			newChipley("enemy")
			await get_tree().create_timer(.04).timeout 
	moveMoney(wagered, "w")
	wagerLabel.text = str(wagered)
	var newCard = card.instantiate()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var my_random_numberY = rng.randi_range(-10, 10)
	var my_random_numberX = rng.randi_range(-10, 10)
	var offset = 1.0
	var bigoffset = 300
	var vec2 = Vector2( bigoffset + float((1*offset) + my_random_numberX), 375 + my_random_numberY)
	newCard.global_position = vec2
	newCard.suit = childCard.suit
	newCard.number = childCard.number
	newCard.facing = "UP"
	newCard.pool = "hole"
	newCard.index = delindexhole
	newCard.selected = false
	add_child(newCard)

	hole.pop_at(hole.find({"suit": holeCard.suit, "number": holeCard.number}))
	shop.pop_at(shop.find({"suit": newCard.suit, "number": newCard.number}))

	hole.append({"suit": newCard.suit, "number": newCard.number})
	dealCard(1, "shop")
	childCard.queue_free()
	holeCard.queue_free()
	handCheck("player")
	return
func handCheck(player, doBet = false):
	var allCards = []
	allCards.append_array(river)

	if(player == "player"):
		allCards.append_array(hole)
	else:
		allCards.append_array(enemy)

	#count all suits
	
	var spades = 0
	var clubs = 0
	var hearts= 0
	var diamonds = 0
	var numbers = []
	for card in allCards:
		numbers.append({N=int(card.number), S=card.suit})

	numbers.sort()
	var hand = "NOTHING!"
	
	#check for straight
	var lastnum = null
	var straightcount = 1
	var highestSC = 1
	var numPairs = 0
	var numThrees = 0
	var numFours = 0
	var kicker 
	var patterns = {
		bestPair = -1,
		bestTwoPair=-1,
		bestThree=-1,
		bestStraight=-1,
		bestFlush=-1,
		bestHouse=-1,
		bestFour=-1,
		bestSFlush=-1
	}
	#check for pairs and threes and fours
	
	var pairHand = []
	for i in range(numbers.size()):
		pairHand.append(numbers[i].N)
	pairHand.sort()
	kicker = pairHand[pairHand.size()-1]
	for i in range(pairHand.size()):
		var numOfCard = pairHand.count(pairHand[i])
		if(numOfCard == 4):
			if(pairHand[i] > patterns.bestFour):
				patterns.bestFour = pairHand[i]
		elif(numOfCard == 3):
			numThrees +=1
			if(pairHand[i] > patterns.bestThree):
				patterns.bestThree = pairHand[i]
			if(numPairs >= 2):
				patterns.bestHouse = pairHand[i]
			if(numThrees >= 6):
				patterns.bestHouse = patterns.bestThree
		elif(numOfCard == 2):
			numPairs +=1
			if(pairHand[i] > patterns.bestPair):
				patterns.bestPair = pairHand[i]
			if(numPairs > 2):
				patterns.bestTwoPair = patterns.bestPair
			if(numThrees >= 3):
				patterns.bestHouse = patterns.bestThree
	#check for flushes 
	for i in range(numbers.size()):
		match numbers[i].S:
			"Spade": spades+=1
			"Diamond": diamonds+=1
			"Club": clubs+=1
			"Heart": hearts +=1
	#find the highest number card of that suit
	if(spades >=5):
		for i in range(numbers.size()):
			if(numbers[i].S == "Spade"):
				if(numbers[i].N > patterns.bestFlush):
					patterns.bestFlush = numbers[i].N
	elif(diamonds >=5):
		for i in range(numbers.size()):
			if(numbers[i].S == "Diamond"):
				if(numbers[i].N > patterns.bestFlush):
					patterns.bestFlush = numbers[i].N
	elif(clubs >=5):
		for i in range(numbers.size()):
			if(numbers[i].S == "Club"):
				if(numbers[i].N > patterns.bestFlush):
					patterns.bestFlush = numbers[i].N
	elif(hearts >=5):
		for i in range(numbers.size()):
			if(numbers[i].S == "Heart"):
				if(numbers[i].N > patterns.bestFlush):
					patterns.bestFlush = numbers[i].N
	
	#check for straights
	var straightHand = []
	for i in range(numbers.size()):
		if(numbers[i].N == 14):
			straightHand.append(14)
			straightHand.insert(0,1)
		else:
			straightHand.append(numbers[i].N)
	straightHand.sort()
	var numsize = straightHand.size()
	var index = 0
	#destruct all duplicate card numbers
	while(index <= numsize-1):
		if(lastnum == null):
			lastnum = straightHand[index]
		elif(straightHand[index] == lastnum):
			straightHand.erase(lastnum)
			numsize = straightHand.size()
		else:
			lastnum = straightHand[index]
		index += 1
	#now split it into runs
	var runs = []
	var run = []
	for i in range(straightHand.size()):
		if(i == 0):
			lastnum = straightHand[i]
			run.append(lastnum)
			continue
		else:
			if(straightHand[i] == lastnum+1):
				run.append(straightHand[i])
				lastnum = straightHand[i]
			else:
				lastnum = straightHand[i]
				runs.append(run)
				run = [lastnum]
	runs.append(run)
	#for each run, delete if it's less than 5
	var straights = []
	for i in range(runs.size()):
		if(runs[i].size() >= 5):
			straights.append(runs[i])
	if(straights.size() > 0):
		patterns.bestStraight = straights[straights.size()-1][straights[straights.size()-1].size()-1]
	
	#TODO: add straight flush
	
	playermoney = int(playermoney)
	
	
	if(player=="enemy"):
		enemyHand = patterns;
		enemyKicker = kicker
	
	
	var winner = ""
	var playerHand = 0
	if(player == "enemy"):
		var rng = RandomNumberGenerator.new()
		if(enemyHand.bestSFlush > -1):
			hand = "Straight FLUSH!!!!"
			enemybet = playermoney
		elif(enemyHand.bestFour > -1):
			hand = "Four of a kind B|"
			enemybet = playermoney
		elif(enemyHand.bestHouse > -1):
			hand = "Full House!"
			var weights = [0.3,0.3,0.3,0.5,0.5,0.75,0.8,0.8,0.8,0.8,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
		elif(enemyHand.bestFlush > -1):
			hand = "Flish"
			var weights = [0.3,0.3,0.3,0.5,0.5,0.75,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
		elif(enemyHand.bestStraight > -1):
			hand = "Straight"
			var weights = [0.3,0.3,0.3,0.3,0.3,0.3,0.3,0.5,0.5,0.75,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
		elif(enemyHand.bestThree > -1):
			hand = "Three of a kind!"
			var weights = [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.3,0.3,0.3,0.5,0.5,0.75,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
		elif(enemyHand.bestTwoPair > -1):
			var weights = [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.3,0.3,0.3,0.5,0.5,0.75,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
			hand = "Two Pair"
		elif(enemyHand.bestPair > -1):
			var weights = [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.3,0.3,0.3,0.5,0.5,0.75,0.8,1]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
			hand = "Pair!"
		else:
			
			var weights = [0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.3,0.3,0.3]
			enemybet = floor((playermoney)*weights[rng.randi_range(0,weights.size()-1)] / 10.0) * 10
			hand = "nothing!"
		print(hand)
		print(enemybet)
		if(enemybet < 10):
			print("enemy tried 0")
			var newweights = [10, 0]
			enemybet = newweights[rng.randi_range(0,1)]
		if(playermoney == 0):
			enemybet = 0
		if(enemybet>enemyMoney):
				enemybet = enemyMoney
	var kickercheck = true
	if(doBet):
		hasSetBet = false
	if(player == "player"):
		if(patterns.bestSFlush > -1):
			hand = "Straight FLISH!!!!"
			playerHand = 1000 + patterns.bestSFlush
		elif(patterns.bestFour > -1):
			hand = "Four of a kind B|"
			playerHand = 900 + patterns.bestFour
		elif(patterns.bestHouse > -1):
			hand = "Full House!"
			playerHand = 800 + patterns.bestHouse + patterns.bestPair
		elif(patterns.bestFlush > -1):
			hand = "Flish"
			playerHand = 700 + patterns.bestFlush
		elif(patterns.bestStraight > -1):
			hand = "Straight"
			playerHand = 600 + patterns.bestStraight
		elif(patterns.bestThree > -1):
			hand = "Three of a kind!"
			playerHand = 500 + patterns.bestThree
		elif(patterns.bestTwoPair > -1):
			hand = "Two Pair"
			playerHand = 400 + patterns.bestTwoPair
		elif(patterns.bestPair > -1):
			hand = "Pair!"
			playerHand = 300 + patterns.bestPair
		else:
			hand = "nothing!"
		
		if(playerHand >= 600):
			kickercheck = false
		if(enemyHand.bestSFlush > -1):
			playerHand = playerHand - ( 1000 + enemyHand.bestSFlush)
			
		elif(enemyHand.bestFour > -1):
			playerHand = playerHand - ( 900 + enemyHand.bestFour)
			
		elif(enemyHand.bestHouse > -1):
			playerHand = playerHand - ( 800 + enemyHand.bestHouse + enemyHand.bestPair)
			
		elif(enemyHand.bestFlush > -1):
			playerHand = playerHand - ( 700 + enemyHand.bestFlush)
			
		elif(enemyHand.bestStraight > -1):
			playerHand = playerHand - ( 600 + enemyHand.bestStraight)
			
		elif(enemyHand.bestThree > -1):
			playerHand = playerHand - ( 500 + enemyHand.bestThree)
			
		elif(enemyHand.bestTwoPair > -1):
			playerHand = playerHand - (400 + enemyHand.bestTwoPair)
			
		elif(enemyHand.bestPair > -1):
			playerHand = playerHand - (300 + enemyHand.bestPair)
			
	#find best player hand
	if(playerHand > 0):
		winner = "Player"
		if(stage == 4 && tradesLeft == 0  && player == "player"):
			lastroundWinner = "player"

	elif (playerHand < 0):
		
		winner = "Enemy"
		if(stage == 4 && tradesLeft == 0 && player == "player"):
			lastroundWinner = "enemy"

	else:
		lastroundWinner = "house"
		var mult = .9
		if(enemyKicker > kicker && kickercheck):
			winner = "Enemy"
			mult = .5
		elif(kicker > enemyKicker && kickercheck):
			winner = "Player"
			mult = 2
		else:
			winner = "The House"
		if(stage == 4 && tradesLeft == 0 && player == "player"):
			if(winner == "Player"):
				lastroundWinner = "player"
			else:
				lastroundWinner = "Enemy"
				
			
	if(folded == true):
		winner = "Enemy"
	updateLabel(hand, player, winner)
	
func updateLabel(hand = null, player = null,winner = null, team = null):
	if(!hand && !player && !winner && team != "player"):
		var audioRoulette = [chips2,chips3,chips4,chips5,chips6,chips7]
		audioRoulette.shuffle()
		chipAudio.stream = audioRoulette[0]
		chipAudio.play()
	var money = str(playermoney)
	while(money.length() < 6):
		money = str("0",money)
	money = str(money)

	var regex = RegEx.new()

	regex.compile("\\d+")
	wagerLabel.text = str(wagered)
	if(hand):
		label.text = hand
	winloseAudio.pitch_scale = 1
	if(stage == 4 && tradesLeft == 0):
		if(winner == "Player"):
			match hand:
				"Two Pair":
					winloseAudio.pitch_scale = 1.1
				"Three of a kind!":
					winloseAudio.pitch_scale = 1.2
				"Straight":
					winloseAudio.pitch_scale = 1.5
				"Flish":
					winloseAudio.pitch_scale = 2
				"Full House!":
					winloseAudio.pitch_scale = 2.5
				"Four of a kind B|":
					winloseAudio.pitch_scale = 3
				"Straight FLISH!!!!":
					winloseAudio.pitch_scale = 4
				
			winloseAudio.stream = winSound
			winloseAudio.play()
		elif(winner == "Enemy"):
			winloseAudio.stream = loseSound
			winloseAudio.play()
		winnerLabel.text = str(winner, " is Winning")
	elif(player == "enemy"):
		return
	var oldMoneyText = moneyLabel.text
	var moneyText = str(pot)
	while(moneyText.length() < 5):
		moneyText= str("0",moneyText)
	
	var safeMoneyText = moneyText
	
	if(stage == 1 && tradesLeft > 0):
		for i in range(moneyText.length()):
					if(moneyText[moneyText.length()-1-i] != oldMoneyText[moneyText.length()-1-i]):
						for p in range(4):
							var random = randi() % 10
							moneyText[moneyText.length()-1-i] = str(random)
							moneyLabel.text = moneyText
							await get_tree().create_timer(.02).timeout 
						
							chipAudio.play()
						moneyText[moneyText.length()-1-i] = safeMoneyText[moneyText.length()-1-i]
						moneyLabel.text = moneyText
						await get_tree().create_timer(.04).timeout 
						chipAudio.stop()
		if(player == "enemy"):
			enemyLabel.text = str(hand)
		else:
			
			var oldmoney = regex.search(playermoneyLabel.text).get_string()
			if(oldmoney):
				
				var oldestmoney = oldmoney
				
				playermoneyLabel.text = str("$: ", oldestmoney)
				#if(playermoney >= 100):
					#audioRoulette.shuffle()
					#chipAudio.stream = audioRoulette[0]
					#chipAudio.play()
				for i in range(oldestmoney.length()):
					if(	oldestmoney[oldestmoney.length()-1-i] != money[oldestmoney.length()-1-i]):
						for p in range(4):
							var random = randi() % 10
							oldestmoney[oldestmoney.length()-1-i] = str(random)
							playermoneyLabel.text = str("$: ", oldestmoney)
							await get_tree().create_timer(.02).timeout 
							
						oldestmoney[oldestmoney.length()-1-i] = money[oldestmoney.length()-1-i]
						playermoneyLabel.text = str("$: ", oldestmoney)
						await get_tree().create_timer(.04).timeout 
			else:
				playermoneyLabel.text = str("$: ",money)
		regex.compile("\\d+")
	else:
		if(player == "enemy"):
			enemyLabel.text = str(hand)
		else:
			
			var oldmoney = regex.search(playermoneyLabel.text).get_string()
			if(oldmoney):
				
				var oldestmoney = oldmoney
				
				playermoneyLabel.text = str("$: ", oldestmoney)
				#if(playermoney >= 100):
					#audioRoulette.shuffle()
					#chipAudio.stream = audioRoulette[0]
					#chipAudio.play()
				for i in range(oldestmoney.length()):
					if(	oldestmoney[oldestmoney.length()-1-i] != money[oldestmoney.length()-1-i]):
						for p in range(4):
							var random = randi() % 10
							oldestmoney[oldestmoney.length()-1-i] = str(random)
							playermoneyLabel.text = str("$: ", oldestmoney)
							await get_tree().create_timer(.02).timeout 
							
						oldestmoney[oldestmoney.length()-1-i] = money[oldestmoney.length()-1-i]
						playermoneyLabel.text = str("$: ", oldestmoney)
						await get_tree().create_timer(.04).timeout 
			else:
				playermoneyLabel.text = str("$: ",money)
			for i in range(moneyText.length()):
					if(moneyText[moneyText.length()-1-i] != oldMoneyText[moneyText.length()-1-i]):
						for p in range(4):
							var random = randi() % 10
							moneyText[moneyText.length()-1-i] = str(random)
							moneyLabel.text = moneyText
							
						moneyText[moneyText.length()-1-i] = safeMoneyText[moneyText.length()-1-i]
						moneyLabel.text = moneyText
						await get_tree().create_timer(.04).timeout 
						chipAudio.stop()
		regex.compile("\\d+")
func dealCard(num, pool, index: int = -1) -> String:
	
	if(num == 0):
		return "done"
	var indexedDeal = false

	audiowheel = [deal1,deal2,deal3,deal4,deal5,deal6,deal7,deal8,deal9]
	for i in range(num):
		var ind = i
		if(index != -1):
			ind = index
		
		await get_tree().create_timer(.01).timeout 
		match pool:
			"river":
				updatedplayermoney = false
				audiowheel.shuffle()
				audio.stream = audiowheel[0]
				audio.play()
				audiowheel.pop_front()
				
				#burn cards
				if(i == 0 || i == 4 ||i == 6 ):
					numburned+=1
					deck.pop_front()
					continue
				var g = ind-numburned
				
				var newCard = card.instantiate()
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				var my_random_numberY = rng.randi_range(-10, 10)
				var my_random_numberX = rng.randi_range(-10, 10)
				var offset = 10
				var bigoffset = 150
				var vec2 = Vector2( (bigoffset + float((g*offset) + my_random_numberX))+((stage+1)*50), 210 + my_random_numberY)
				newCard.global_position = vec2
				newCard.suit = deck[0][0]
				newCard.number = deck[0][1]
				newCard.facing = "UP"
				newCard.pool = "river"
				newCard.index = g
				newCard.selected = false
				add_child(newCard)
				river.append({"suit": deck[0][0], "number": deck[0][1]})
				deck.pop_front()
			
				
			"hole":
				audiowheel.shuffle()
				audio.stream = audiowheel[0]
				audio.play()
				audiowheel.pop_front()
				var newCard = card.instantiate()
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				var my_random_numberY = rng.randi_range(-10, 10)
				var my_random_numberX = rng.randi_range(-10, 10)
				var offset = 1.0
				var bigoffset = 280
				var vec2 = Vector2( bigoffset + float((ind*offset) + my_random_numberX), 375 + my_random_numberY)
				newCard.global_position = vec2
				newCard.suit = deck[0][0]
				newCard.number = deck[0][1]
				newCard.facing = "UP"
				newCard.pool = "hole"
				newCard.index = ind
				newCard.selected = false
				add_child(newCard)
				hole.append({"suit": deck[0][0], "number": deck[0][1]})
				deck.pop_front()
			"shop":
				audiowheel.shuffle()
				audio.stream = audiowheel[0]
				audio.play()
				audiowheel.pop_front()
				
				var newCard = card.instantiate()
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				var my_random_numberY = rng.randi_range(-10, 10)
				var my_random_numberX = rng.randi_range(-10, 10)
				var offset = 1.0
				var bigoffset = 500
				var vec2 = Vector2( bigoffset + my_random_numberX, 240 + float((ind*offset) + my_random_numberY))
				newCard.global_position = vec2
				newCard.rotation = deg_to_rad(90.0)
				newCard.suit = deck[0][0]
				newCard.number = deck[0][1]
				newCard.facing = "DOWN"
				newCard.pool = "shop"
				newCard.index = ind
				newCard.selected = false
				add_child(newCard)
				shop.append({"suit": deck[0][0], "number": deck[0][1]})
				deck.pop_front()
			"enemy":
				audiowheel.shuffle()
				audio.stream = audiowheel[0]
				audio.play()
				audiowheel.pop_front()
				var newCard = card.instantiate()
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				var my_random_numberY = rng.randi_range(-10, 10)
				var my_random_numberX = rng.randi_range(-10, 10)
				var offset = 1.0
				var bigoffset = 280
				var vec2 = Vector2( bigoffset + float((ind*offset) + my_random_numberX), 75 + my_random_numberY)
				newCard.global_position = vec2
				newCard.suit = deck[0][0]
				newCard.number = deck[0][1]
				newCard.facing = "DOWN"
				newCard.pool = "enemy"
				newCard.index = ind
				newCard.selected = false
				add_child(newCard)
				enemy.append({"suit": deck[0][0], "number": deck[0][1]})
				deck.pop_front()
	
	return "done"


	
#ways to move money: 
	#1: enemy bets initially, movemoney from enemymoney to wagered - done
	#2: player matches enemy, movemoney from playermoney to wagered, then from wagered to pot
	#3: player raises, movemoney from playermoney to wagered, get the difference between wagered and enemybet
		#add difference from enemymoney to wagered
		#note: player cannot increase the wager by more than enemy has 
	#4: player folds, move money from wagered to enemymoney
	#bug: on init, constantly updates money until start
	#bug: player matching doesnt spawn chipleys anymore
	#bug: enemy spawns one  too many chipleys
	#bug: wagered not moved to pot at the end of the round if player trades
	#bug: wagered is too high
func moveMoney(amount, from, to = null):
	#possible combinations
	#from wagered to pot - only happens when trade or tradepass or fold
	
	#from enemymoney to wagered - happens on initial bet and if player raises
	#from playermoney to wagered - happens on bump and if player calls 
	#from pot to enemyMoney
	#from pot to playermoney
	
	if(from == "w"):
		print("moving money from wagered to pot")
		wagered = wagered - amount
		pot = pot+amount
	if(from == "em"):
		print("moving money from em to wagered")
		enemyMoney = enemyMoney-amount
		wagered = wagered+amount
	if(from == "pm"):
		print("moving money from pm to wagered")
		playermoney = playermoney-amount
		wagered = wagered+amount
	if(from == "pot"):
		if(to == null):
			push_error("pot must have a to value")
		elif(to=="pm"):
			print("moving money from pot to pm")
			pot = pot-amount
			playermoney = playermoney+amount
		elif(to=="em"):
			print("moving money from pot to em")
			pot = pot-amount
			enemyMoney = enemyMoney+amount
	if(from == "empm"):
		
		#wagered = 10 from enemybet
		#enemyMoney = 90 from init bet 
		#player trades
		#playermoney goes to 90
		#enemy money does not change 
		#wagered should now be at 20 
		
		#player loses money equal to amount wagered
		var pdif = enemybet
		
		print(str("enemy bets: ", enemybet))
		var dif = playerRaiseAmt-enemybet
		
		print("dif: ", dif)
		if(dif < 0 ):
			dif = 0
		enemyMoney = enemyMoney-(dif)
		if(playerRaiseAmt == 0):	
			print("playerRaise is 0")
			playermoney = playermoney-(enemybet)
			wagered = wagered + enemybet
			print(str("wagered: ", wagered))
		
		#enemy loses money equal to amount raised by player 
		print(wagered)
		
		
		print(str("player bets: ", playerRaiseAmt))
		wagered = wagered + dif
		print(str("total wagered ", wagered))
		
	enemyMoneyLabel.text = str(enemyMoney)
	wagerLabel.text = str(wagered)
	updateLabel()
	return from
func _on_timer_timeout():
	if(stage == 4):
		var playerCount = 0 
		var enemyCount = 0 
		for child in get_children():
			if(child is Chipley):
				if(child.team == "player"):
					playerCount += 1
				else:
					enemyCount += 1
		if(playerCount == 0):
			chipleyWinner = "enemy"
		elif(enemyCount == 0):
			chipleyWinner = "player"
			
		
