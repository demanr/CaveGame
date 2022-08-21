extends Node2D


func _ready():
	pass
	
func _process(delta):
	
	if PlayerVars.health < 1:
		$DeathCam.current = true
	else:
		$DeathCam.position = $player.position
