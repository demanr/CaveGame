extends TileMap

var depth = 1
var verticalCoverage = 8 #number of blocks a player can jump vertically

var startPos = Vector2()
var health = 2
var baseHealth = 4
#when player is hit or decides to forfeit life
var respawn = false
#where player is sent when they die
var spawn = "res://scenes/Parkour.tscn" #"res://scenes/Spawn.tscn"

#
var playerMode = "cave"

var kills = 0

func _ready():
	resetStats()

func resetStats():
	health = baseHealth
	respawn = false
