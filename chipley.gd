extends CharacterBody2D
class_name Chipley

var speed = 40
var parent = null
var winner = false
var haswon = false
var timerRange = [0.4, 0.6]
@export var agent: NavigationAgent2D
@export var goal: Node = null
@export var team = ""
@export var health = 5
@export var timer: Timer
@export var deathParticles = CPUParticles2D
@export var hit = CPUParticles2D

@export var hitNoise1: AudioStreamOggVorbis
@export var hitNoise2: AudioStreamOggVorbis
@export var hitNoise3: AudioStreamOggVorbis
@export var hitNoise4: AudioStreamOggVorbis

@export var deathNoise1: AudioStreamOggVorbis
@export var deathNoise2: AudioStreamOggVorbis
@export var deathNoise3: AudioStreamOggVorbis

@export var audio: AudioStreamPlayer2D
var hitNoises
var deathNoises
var lastdist = null
func _init():
	velocity = Vector2(0,0)

func _ready():
	parent = get_parent()
	if(team == "player"):
		agent.set_avoidance_layer_value(1, true)
		agent.set_avoidance_layer_value(2, false)
		agent.set_avoidance_mask_value(1, true)
		agent.set_avoidance_mask_value(2, false)
	else:
		agent.set_avoidance_layer_value(2, true)
		agent.set_avoidance_layer_value(1, false)
		agent.set_avoidance_mask_value(2, true)
		agent.set_avoidance_mask_value(1, false)
	hitNoises = [hitNoise1, hitNoise2, hitNoise3, hitNoise4]
	deathNoises = [deathNoise1, deathNoise2, deathNoise3]

#func _draw():
	#draw_line(to_local(position),  to_local(agent.target_position), Color(0, 1, 0),  2)


	
func _physics_process(_delta: float) -> void:
	queue_redraw()
	if(!agent.is_target_reached() && goal):
		var dir = to_local(agent.get_next_path_position()).normalized()
		var intVel = dir * speed * _delta
		agent.set_velocity(intVel)
		#velocity = dir * speed * _delta
	else:
		velocity = Vector2(0,0)
	deathParticles.position = position
	hit.position = position
	#move_and_slide()


func _on_timer_timeout():
	if(winner && !haswon):
		modulate = Color(100,100,100)
		speed = 50
		timerRange = [0.25, 0.4]
		health = 10
		haswon = true
		await get_tree().create_timer(.05).timeout
		if(team == "player"):
			modulate = Color(1,1,1)
		else:
			modulate = Color(1,0,0)
	if(goal && !is_instance_valid(goal)):
		goal = null
	if(goal && lastdist == null):
		lastdist = position.distance_to(goal.global_position)
	elif(goal):
		var changesincelastcheck = lastdist - position.distance_to(goal.global_position)
		if(position.distance_to(goal.global_position) > 10 && changesincelastcheck < 1):
			goal = null
			lastdist = null
		else:
			lastdist = position.distance_to(goal.global_position)
			
	if(goal == null):
		
		var closest = INF
		for child in parent.get_children():
			if(child is Chipley):
				if(child.team != team):
					var dist = position.distance_to(child.global_position)
					if( dist < closest):
						goal = child
						closest = dist
		
	if(goal && agent.target_position != goal.global_position):
		agent.target_position = goal.global_position
	if(goal && position.distance_to(goal.global_position) < 10):
		var dir = to_local(agent.get_next_path_position()).normalized()
		if(goal.health <= 1):
			var dead = goal
			goal = null
			dead.takeDamage(1, dir, self)
		else:
			goal.takeDamage(1, dir, self)
	var rng = RandomNumberGenerator.new()
	rng.randomize()	
	timer.wait_time = rng.randf_range(timerRange[0], timerRange[1])
	timer.start()

func takeDamage(damage, vector, chip):
	goal = chip
	var default
	if(team == "player"):
		default = Color(1,1,1)
	else:
		default = Color(1,0,0)
	modulate = Color(100,100,100)
	health = health-damage
	if(health <= 0):
		audio.stream = deathNoises.pick_random()
		audio.playing = true
		deathParticles.emitting = true
		await get_tree().create_timer(.2).timeout
		if(team == 'player'):
			parent.enemyMoney += 10
			parent.updateEnemyBet(false)
		else:
			parent.playermoney += 10
			parent.updatePlayerMoney()
			
		parent.pot -=10
		parent.updatePotLabel()
		queue_free()
	else:
		audio.stream = hitNoises.pick_random()
		audio.playing = true
		hit.rotation = vector.angle()
		hit.emitting = true
		await get_tree().create_timer(.02).timeout 
		modulate = default
	


func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity * speed
	move_and_slide()
