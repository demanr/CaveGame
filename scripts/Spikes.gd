extends StaticBody2D


func _ready():
	pass


func _on_Area2D_body_entered(body):
	#reset player pos to door pos
	get_tree().change_scene("res://scenes/Spawn.tscn")
	queue_free()
