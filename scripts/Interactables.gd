extends TileMap

var doorArea = preload("res://scenes/Door.tscn")

func _ready():
	if PlayerVars.playMode:
		var doors = get_used_cells_by_id(1)
	
		print(doors)
		print(map_to_world(doors[0]))

		print(get_cell_autotile_coord(doors[0][0], doors[0][1]))
		
		for door in doors:
			pass
	

