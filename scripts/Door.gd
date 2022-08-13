extends Area2D


func _ready():
	pass

func _input(event):
	if event.is_action_pressed("enterDoor"):
		if get_overlapping_bodies().size() > 0:
			newLevel()
			
			
func newLevel():
	get_tree().change_scene("res://scenes/Main.tscn")
	queue_free()

func place_door(_pos):
	position = _pos
