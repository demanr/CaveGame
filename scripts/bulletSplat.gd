extends Node2D

var splatVersion = 1

var v1 = load("res://sprites/slimeSplatV1.png")
var v2 = load("res://sprites/slimeSplatV2.png")
var v3 = load("res://sprites/slimeSplatV3.png")
var v4 = load("res://sprites/slimeSplatV4.png")

var splats = [v1,v2,v3,v4]

func _ready():
	splatVersion = rand_range(0,3)
	$Sprite.texture = splats[splatVersion]
	$Sprite/AnimationPlayer.play("start")

