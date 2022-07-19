extends Area2D


func _ready():
	pass

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if get_overlapping_bodies().size() > 0:
			newLevel()
			
			
func newLevel():
	get_tree().change_scene("res://scenes/Main.tscn")
	queue_free()

func place_door(_posx, _posy):
	position.x = _posx
	position.y = _posy
