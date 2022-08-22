extends Area2D

var KILLEDPLAYER = preload("res://scenes/SpikeDeath.tscn")

func _ready():
	pass

# Spike detects player
func _on_Spike1_body_entered(body):
	if PlayerVars.health > 0:
		#send to spawn
		PlayerVars.health = -1
		PlayerVars.respawn = true
		killedPlayer()

func killedPlayer():
	#Instance death animation
	var death = KILLEDPLAYER.instance()
	get_parent().add_child(death)
	#moves death instance to current position
	death.global_transform = global_transform
	queue_free()
