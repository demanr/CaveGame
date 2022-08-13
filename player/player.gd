extends KinematicBody2D

#path of bullet
const bulletPath = preload("res://scenes/Bullet.tscn")

const UP = Vector2(0,-1)
const GRAVITY = 18
const MAXFALLSPEED = 300
const MAXSPEED =  300 #100
const JUMPFORCE =  450 #350
const ACCEL =  30 #15

var motion = Vector2()
var facing_right = true
var max_jumps = 20
var jump_count = 0
# is true if player is dead
var hasJustDied = true

#to ensure falling animation only played once
var justFallen = true

func _ready():
	pass


func _physics_process(delta):
	if PlayerVars.health < 1:
		get_tree().change_scene("res://scenes/Spawn.tscn")
		queue_free()
		PlayerVars.resetStats()
	motion.y += GRAVITY
	if motion.y > MAXFALLSPEED:
		motion.y = MAXFALLSPEED
	
	if facing_right:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true
	# limits motion btwn two numbers
	motion.x = clamp(motion.x, -MAXSPEED, MAXSPEED)
	
	if PlayerVars.respawn == true:
		#ensures death animation only plays once
		if hasJustDied:				
			$AnimationPlayer.play("death")
			hasJustDied = false
		if motion.x != 0:
			motion.x = lerp(motion.x, 0, 0.2)
		if Input.is_action_pressed('ui_accept'):
			$AnimationPlayer.play("revive")
				
			
	else:
		if Input.is_action_pressed("right"):
			motion.x += ACCEL
			facing_right = true
			#animation only plays if player is not jumping
			is_on_floor() and $AnimationPlayer.play("walk")
			if Input.is_action_pressed("sprint"):
				motion.x += ACCEL*4
		elif Input.is_action_pressed("left"):
			motion.x -= ACCEL
			facing_right = false
			#anim only plays if player is not jumping
			is_on_floor() and $AnimationPlayer.play("walk")
			if Input.is_action_pressed("sprint"):
				motion.x -= ACCEL*2
		else:
			# slows gradually
			motion.x = lerp(motion.x, 0, 0.2)
			#anim only plays if player is not jumping
			#is_on_floor() and $AnimationPlayer.play("idle") -- idle anim TBA
		if is_on_floor():
			jump_count = 0
			justFallen = true
			
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				print(position)
				motion.y = - JUMPFORCE
			elif jump_count < max_jumps:
				motion.y = -JUMPFORCE  / 1.5
			jump_count += 1
		if 	Input.is_action_just_released("jump"):
			motion.y /= 2
			
		if !is_on_floor():
			if motion.y < 0:
				$AnimationPlayer.play("jump")
			elif $FloorChecker.is_colliding():
				$AnimationPlayer.play("splat")
			elif motion.y > 0:
				if justFallen:
					$AnimationPlayer.play("fall")
					justFallen = false
			
		
		
		#handles shooting
		if Input.is_action_just_pressed("shoot"):
			shoot()
		
		
		#for bullet direction
		$Node2D.look_at(get_global_mouse_position())
	motion = move_and_slide(motion, UP)
func shoot():
	var bullet = bulletPath.instance()
	
	get_parent().add_child(bullet)
	bullet.position = $Node2D/Position2D.global_position
	
	bullet.velocity = get_global_mouse_position() - bullet.position

# camera changes for debug
func _input(event):
	if event.is_action_pressed('scroll-up'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll-down'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.2, 0.2)

func respawn():
	hasJustDied = true
	PlayerVars.respawn = false
