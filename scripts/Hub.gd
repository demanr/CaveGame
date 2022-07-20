extends Node2D


func _ready():
	$HubCam.current = true
	pass

func _process(delta):
	if Input.is_action_pressed("ui_focus_next"):
		get_tree().change_scene("res://rooms/Main.tscn")
		queue_free()
	
