extends TileMap

var depth = 1
var verticalCoverage = 4 #number of blocks a player can jump vertically

var startPos = Vector2()
var health = 10
#when player is hit or decides to forfeit life
var respawn = false

func _ready():
	pass
