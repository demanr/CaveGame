extends KinematicBody2D

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
	# Saend to spawn
	print(body)
	if PlayerVars.health < 1:
		get_tree().change_scene("res://scenes/Spawn.tscn")
		queue_free()
	else:
		PlayerVars.health -= 1
		PlayerVars.respawn = true
		print(PlayerVars.health)


func make_enemy(_pos):
	position = _pos
	

	
