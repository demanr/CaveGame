extends TileMap

var depth = 1
var verticalCoverage = 8 #number of blocks a player can jump vertically

var startPos = Vector2()
var health = 4
#when player is hit or decides to forfeit life
var respawn = false

var kills = 0

func _ready():
	resetStats()

func resetStats():
	health = 4
	respawn = false
