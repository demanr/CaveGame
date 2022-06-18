extends KinematicBody2D

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


func _ready():
	#position.y -= 750
	pass # Replace with function body.


func _physics_process(delta):
	motion.y += GRAVITY
	if motion.y > MAXFALLSPEED:
		motion.y = MAXFALLSPEED
	
	if facing_right:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true
	# limits motion btwn two numbers
	motion.x = clamp(motion.x, -MAXSPEED, MAXSPEED)
	
	if Input.is_action_pressed("right"):
		motion.x += ACCEL
		facing_right = true
		$AnimationPlayer.play("walk")
		if Input.is_action_pressed("sprint"):
			motion.x += ACCEL*4
	elif Input.is_action_pressed("left"):
		motion.x -= ACCEL
		facing_right = false
		$AnimationPlayer.play("walk")
		if Input.is_action_pressed("sprint"):
			motion.x -= ACCEL*2
	else:
		# slows gradually
		motion.x = lerp(motion.x, 0, 0.2)
		$AnimationPlayer.play("idle")
	if is_on_floor():
		jump_count = 0
		
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			motion.y = - JUMPFORCE
		elif jump_count < max_jumps:
			motion.y = -JUMPFORCE  / 1.5
		jump_count += 1
	if 	Input.is_action_just_released("jump"):
		motion.y /= 2
		
	if !is_on_floor():
		if motion.y < 0:
			$AnimationPlayer.play("jump")
		elif motion.y > 0:
			$AnimationPlayer.play("fall")
	motion = move_and_slide(motion, UP)
	
# camera changes REMOVE LATER
func _input(event):
	if event.is_action_pressed('scroll-up'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll-down'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.2, 0.2)
