extends KinematicBody2D

var SPLAT = preload("res://scenes/bulletSplat.tscn")

var velocity = Vector2(1,0)

var speed = 200

var flipped = false

func _ready():
	pass

func _physics_process(delta):
	var collision_info = move_and_collide(velocity.normalized() * delta * speed)

	if velocity.normalized().x < 0:
		if !flipped:
			scale.x *= -1
			flipped = true
		
	$AnimationPlayer.play("idle")
	


func _on_Area2D_body_entered(body):
	var splat = SPLAT.instance()
	get_parent().add_child(splat)
	splat.global_transform = global_transform
	
	queue_free()
	
	#this means target is enemy
	if "Slime" in body.get_name():
		body.die()
	
	
