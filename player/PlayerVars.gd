extends TileMap

var depth = 1
var verticalCoverage = 4 #number of blocks a player can jump vertically

var startPos = Vector2()
var health = 1
#when player is hit or decides to forfeit life
var respawn = false


var kills = 0

func _ready():
	resetStats()

func resetStats():
	health = 1
	respawn = false
