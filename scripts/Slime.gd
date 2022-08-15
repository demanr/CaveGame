extends KinematicBody2D

var DEATH = preload("res://scenes/SlimeDeath.tscn")

const SPEED = 20

var velocity = Vector2()
export var direction = -1
export var detects_cliffs = true

func _ready():
	if direction == -1:
		$Sprite.flip_h = true
	$FloorChecker.position.x = $CollisionShape2D.shape.get_radius() * direction
	$FloorChecker.enabled = detects_cliffs

func _physics_process(delta):
	
	if is_on_wall() or not $FloorChecker.is_colliding() and detects_cliffs and is_on_floor():
		direction *= -1
		$Sprite.flip_h = not $Sprite.flip_h
		$FloorChecker.position.x = $CollisionShape2D.shape.get_radius() * direction

	
	velocity.y += 10
	
	velocity.x = SPEED * direction
	
	velocity = move_and_slide(velocity, Vector2.UP)
	

# Enemy detects player
func _on_Area2D_body_entered(body):
	# Send to spawn
	if PlayerVars.respawn == true:
		return
	
	else:
		PlayerVars.health -= 1
		PlayerVars.respawn = true
	PlayerVars.kills += 1
	die()


func die():
	#Instance death animation
	var die = DEATH.instance()
	get_parent().add_child(die)
	#moves death instance to current position
	die.global_transform = global_transform
	queue_free()

func make_enemy(_pos):
	position = _pos
	


