extends Area2D

var emptyBush = load("res://sprites/redBerrylessBush.png")

export var hasBerries = true

func _ready():
	if !hasBerries: 
		removeBerry()

func _input(event):
	if event.is_action_pressed("interact"):
		if get_overlapping_bodies().size() > 0 and hasBerries:
			getBerry()
		else:
			#Add sound effect
			pass
			
			
func getBerry():
	PlayerVars.berries += 1
	hasBerries = false
	removeBerry()

func place(_pos, berry):
	hasBerries = berry
	position = _pos

func removeBerry():
	$Sprite.texture = emptyBush
	$Light2D.enabled = false
