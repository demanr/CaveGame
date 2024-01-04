extends Node2D

var Room = preload("res://scenes/Room.tscn")
var Spawn = preload("res://scenes/Spawn.tscn")
var Player = preload("res://player/Player.tscn")
var font = preload("res://fonts/Basic96.tres")
var Enemy = preload("res://scenes/Enemy.tscn")
var Slime = preload("res://scenes/Slime.tscn")
var Door = preload("res://scenes/Door.tscn")
var BerryBush = preload("res://scenes/BerryBush.tscn")

onready var Map = $TileMap
onready var Map2 = $Platforms

onready var MapBgDecor = $BgDecor
onready var MapDecor = $Decor
onready var MapVines = $Vines
onready var MapWall = $"Wall Additions"
onready var MapInteract = $Interactables

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

var tile_size = 16
#how many rooms to originally spawn
var num_rooms = 10
var min_size = 4
var max_size = 8
# bigger number means more spread in that direction
var hspread = 200
var vspread = 0
# percent of rooms to remove in 0-1 decimal
var cull = 0.5
#for player placement
var startRoomWidth = 0
var startRoomHeight = 0

#for generating paths
var bgIndex = 0

# out of 100, likelyhood of spawning
var enemySpawnRate = 10
var berryBushSpawnRate = 10
#likel
var berrylessbushSpawnRate = 5

#likelyhood of widder corridors being generated, 1-10
var corridorWidthChance = 5
# higher number means less chance of platforms spawning
var platformSpawnRate = 9

var path #AStar pathfindin obj
var start_room = null
var end_room = null
var player = null

var play_mode = false

#tilemap dict
var tiles = {"CaveInnerBG" : 0, "CavePlatform": 8, "CavePlatform1Way": 23, "CaveDoor": 1, "CaveOuterBG": 6, "GroundDecor": 7,
"CaveOuter1": 2, "CaveOuter2" : 3, "CaveOuter3": 4, "CaveOuter4" :5, 
"Vines1": 9, "Vines2": 10, "Vines3": 11, "Vines4": 12, "VinesEnd1": 13, "VinesEnd2": 14,
"HoleDecor1": 15, "HoleDecor2": 16, "HoleDecor3": 17, "HoleDecor4": 18, "HoleDecor5": 19, "HoleDecor6": 20, "HoleDecor7": 21, "HoleDecor8": 22}

#tiles that make up outer layer
var outerTiles = [tiles["CaveOuter1"], tiles["CaveOuter2"], tiles["CaveOuter3"], tiles["CaveOuter4"]]

var enemySpawnTiles = [tiles["CaveOuter1"], tiles["CaveOuter2"], tiles["CaveOuter3"], tiles["CaveOuter4"], tiles["CavePlatform1Way"] ]

# tile used for room cutouts
var caveAdditionTile = "CaveOuter"
var randomAdditionTile = 1

func _ready():
	rng.randomize()
	$CanvasLayer/LoadCam.current = true
	randomize()
	fullGenerate()
	#make_rooms()
	
func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread,hspread),rand_range(-vspread, vspread))
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w,h) * tile_size)
		$Rooms.add_child(r)
	#waits until physics bodies settle
	yield(get_tree().create_timer(1.4), 'timeout')
	#cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x, room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	# generate min standing tree to connect rooms
	path = find_mst(room_positions)
			
			
func _draw():
	if start_room:
		draw_string(font, start_room.position-Vector2(125,0), "start")
	if end_room:
		draw_string(font, end_room.position-Vector2(125,0), "end")
	if play_mode:
		return
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size*2), Color(128, 0, 32), false)
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x,cp.y), Color(1,1,0), 10, true)
				
func _process(delta):
	get_node("CanvasLayer/VBoxContainer/Health").text = "STAM: " + str(PlayerVars.health)
	get_node("CanvasLayer/VBoxContainer/Berries").text = "BERRIES: " + str(PlayerVars.berries)
	update()

func _input(event):
	if event.is_action_pressed("generate"): # p key
		$CanvasLayer/LoadCam.current = true
		if play_mode:
			player.queue_free()
			play_mode = false
		path = null
		start_room = null
		end_room = null
		clearMaps()
		for n in $Rooms.get_children():
			n.queue_free()
		for e in $Enemies.get_children():
			e.queue_free()
		for d in $Doors.get_children():
			d.queue_free()
		for b in $Bushes.get_children():
			b.bqueue_free()
		path = null
		make_rooms()
		

	if event.is_action_pressed("ui_focus_next"):
		make_map()
	if event.is_action_pressed("ui_cancel"):
		for room in $Rooms.get_children():
			room.get_node("CollisionShape2D").set_deferred("disabled", true)
		yield(get_tree(), 'idle_frame') #ensures player has proper spawn
		player = Player.instance()
		add_child(player)
		PlayerVars.startPos = start_room.position + Vector2(startRoomWidth/(2*tile_size), startRoomHeight/(2*tile_size)) # accounts for edge of room
		player.position = PlayerVars.startPos 
		play_mode = true 
		
		
	if event.is_action_pressed("return"): # 0 key
		PlayerVars.health = 0
		queue_free()

func clearMaps():
	Map.clear()
	Map2.clear()
	MapBgDecor.clear()
	MapDecor.clear()
	MapWall.clear()
	MapVines.clear()
	MapInteract.clear()
	
	
#repeat code, allows for all generation at once
func fullGenerate():
	if play_mode:
		player.queue_free()
		play_mode = false
	path = null
	start_room = null
	end_room = null
	clearMaps()
	for n in $Rooms.get_children():
		n.queue_free()
	for e in $Enemies.get_children():
		e.queue_free()
	for d in $Doors.get_children():
		d.queue_free()
	for b in $Bushes.get_children():
		b.queue_free()
	path = null
	make_rooms()
	yield(get_tree().create_timer(1.5), 'timeout')
	make_map()
	yield(get_tree(), 'idle_frame') #ensures player has proper spawn
	for room in $Rooms.get_children():
		room.get_node("CollisionShape2D").set_deferred("disabled", true)
	yield(get_tree(), 'idle_frame') #ensures player has proper spawn
	player = Player.instance()
	add_child(player)
	PlayerVars.startPos = start_room.position + Vector2(startRoomWidth/(2*tile_size), startRoomHeight/(2*tile_size)) # accounts for edge of room
	player.position = PlayerVars.startPos 
	play_mode = true 
	
func find_mst(nodes):
	#Prim's alg
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat until no nodes
	while nodes:
		var min_dist = INF # min distance
		var min_p = null # pos of the node
		var p = null # current pos
		#loop thru pts in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path

func make_map():
	# makes tilesmap from generated rooms and path
	clearMaps()
	# fill tilemap with walls then carve empty rooms
	var full_rect = Rect2() # rect enclosin entire map
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size, room.get_node("CollisionShape2D").shape.extents*2)
		
		full_rect = full_rect.merge(r)
		var topleft = Map.world_to_map(full_rect.position)
		var bottomright = Map.world_to_map(full_rect.end)
		
		
		# extra 10 tiles so rooms on border show tileset
		for x in range(topleft.x - 10, bottomright.x + 10):
			for y in range(topleft.y - 10, bottomright.y + 10):
				#First wall iteration set to L Wall
				var randTile = randi() % 4 + 1
				# Most likely event

				Map.set_cell(x,y, tiles[("CaveOuter" + str(randTile))])

		
	# carve the rooms
	var corridors = [] # one corridor per connection
	for room in $Rooms.get_children():
		var s = (room.size/ tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position/ tile_size).floor() - s # upper left corner, room.pos is center
		var xiterations = 0
		var yiterations = 0
		var xMax = s.x*2
		var yMax = s.y*2

		platforms(room)	
		
		# carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y,0))
		for conn in path.get_point_connections(p):
			if not conn in corridors: #not already done
				var start = Map.world_to_map(Vector2((path.get_point_position(p).x), path.get_point_position(p).y)) #get point pos returns vector 3
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end, room)
		#spawns room corners
		corners(room)
		corridors.append(p)
		
		
		
		var spawnHole = 0
		var spawnVine = 0
		
		for x in range(2, xMax -1):
			xiterations += 1
			yiterations = 0
			spawnVine = rng.randi_range(0,max_size-2)
			
			for y in range(2, yMax-1): #stops rooms from being carved together
				#removes ground hang if present
				MapDecor.set_cell(ul.x + x,ul.y + y, -1)
				
				yiterations += 1
				#Adding background hole decor
				spawnHole = rng.randi_range(0,10)
				if spawnHole > 5:
					MapBgDecor.set_cell(ul.x + x,ul.y + y, tiles["HoleDecor" + str(spawnHole - 5)])
				
				Map.set_cell(ul.x + x,ul.y + y, tiles["CaveInnerBG"])
				
				#if wall addition do not place vine
				if MapWall.get_cell(ul.x + x,ul.y + y) != -1:
					spawnVine -= 1
					continue
				
				if y == 2 and Map.get_cell(ul.x + x,ul.y + y - 1) == tiles["CaveInnerBG"]:
					#ensures no vines if inner BG above top tile
					spawnVine = 0
					
				#Vine Decoration
				if spawnVine <= 0:
					continue
					
				elif spawnVine == 1:
					spawnVine = 0
					MapVines.set_cell(ul.x + x,ul.y + y, tiles["VinesEnd" + str(rng.randi_range(1,2))])
				else:
					spawnVine -= 1
					MapVines.set_cell(ul.x + x,ul.y + y, tiles["Vines" + str(rng.randi_range(1,4))])
					
	var interactableRNG = 0
	var posOffset = 0
	var enemyPos = 0
	var enemyInstance = 0
	
	
	
	
	find_start_room()
	find_end_room()
	
	#spawn interactables	
	for tile in Map2.get_used_cells_by_id(tiles["CavePlatform1Way"]):
		#stops interactables from spawning in start room
		if Map.map_to_world(tile).x < start_room.position.x + startRoomWidth:
			if Map.map_to_world(tile).y < start_room.position.y + startRoomHeight and  Map.map_to_world(tile).y > start_room.position.y - startRoomHeight:
				continue
		#ensures space above to place enemy
		if Map.get_cell(tile.x, tile.y-1) == tiles["CaveInnerBG"] and MapWall.get_cell(tile.x, tile.y-1) == -1:
			interactableRNG = rng.randi_range(0, 100)
			#spawn slime
			
			if interactableRNG < enemySpawnRate:
				enemyPos = Map2.map_to_world(tile) - Vector2(0,8)
				enemyInstance = Slime.instance()
				enemyInstance.make_enemy(enemyPos)
				$Enemies.add_child(enemyInstance)
			#spawn enemy 2
			elif interactableRNG < enemySpawnRate + berryBushSpawnRate:
				placeBerryBush(tile, true)
			elif interactableRNG < enemySpawnRate + berryBushSpawnRate + berrylessbushSpawnRate:
				placeBerryBush(tile, false)
			
	
	createExit()

	#add grass/ground decor
	for tile in Map.get_used_cells_by_id(tiles["CaveInnerBG"]):
		if Map.get_cell(tile.x, tile.y+1) in outerTiles:
			if MapWall.get_cell(tile.x, tile.y) == -1:
				MapDecor.set_cell(tile.x,tile.y+1, tiles["GroundDecor"])
				continue
				
		if MapWall.get_cell(tile.x, tile.y+1) in outerTiles:
			if MapWall.get_cell(tile.x, tile.y) in outerTiles:
				continue
			else:
				MapDecor.set_cell(tile.x,tile.y+1, tiles["GroundDecor"])
			

func carve_path(pos1, pos2, room):
	# carve path btwn pts
	
	var x_diff = sign (pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	# chose either x then y or y then x
	var x_y = pos1
	var y_x = pos2
	var widderCorridors = false
	
	#for vertical platforms
	var yIterations = 0
	
	# ID of tilemap
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	
	if rng.randi_range(0, 10) <=  corridorWidthChance:
		widderCorridors = true
		
	# increase range to account for doorway clearing
	for x in range (pos1.x , pos2.x ,x_diff):
		
		Map.set_cell(x, x_y.y, tiles["CaveInnerBG"])
		Map.set_cell(x, x_y.y + y_diff, tiles["CaveInnerBG"]) # widens corridor
		
		# chance to widen corridor even greater
		if widderCorridors:
			Map.set_cell(x, x_y.y - y_diff, tiles["CaveInnerBG"]) # widens corridor
			
	for y in range(pos1.y, pos2.y, y_diff):

		Map.set_cell(y_x.x ,y,tiles["CaveInnerBG"])
		Map.set_cell(y_x.x + x_diff,y,tiles["CaveInnerBG"])
		if widderCorridors:
			Map.set_cell(y_x.x - x_diff,y,tiles["CaveInnerBG"]) # widens corridor
		
		# if false widderCorridors is 0 else its 1, so range is -1,1 if wider and 0,1 i not
		yIterations += 1
		if yIterations % PlayerVars.verticalCoverage == 0:
			Map2.set_cell(y_x.x + x_diff*(rng.randi_range(0 - int(widderCorridors),1)),y , tiles["CavePlatform1Way"])
		elif yIterations % PlayerVars.verticalCoverage == (PlayerVars.verticalCoverage/2):
			Map2.set_cell(y_x.x + x_diff*(rng.randi_range(0- int(widderCorridors),1)),y , tiles["CavePlatform1Way"])
			
		
func find_start_room():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x
	startRoomWidth = start_room.size.x
	startRoomHeight = start_room.size.y
	
	
func find_end_room():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x

# generates platforms
func platforms(room):
	var s = (room.size/ tile_size).floor()
	var pos = Map.world_to_map(room.position)
	var ul = (room.position/ tile_size).floor() - s # upper left corner, room.pos is center
	var xMax = s.x*2 #prevents spawning in border
	var yMax = s.y*2
	
	var spawnPlatform = 0
	# level to spawn extended platforms
	var yLevel = 0 
	
	#depending on platform length, decides how many left to spaawn
	var remainingSpawn = 0
	
	xMax -= 2 #prevents from spawning on border
	
	yLevel = 0
	spawnPlatform = 0
	remainingSpawn = 0
	var minYLev = -1
	var platformPlaced = 0
	
	for y in range(yMax - 3, 4 + minYLev, -1):
		for x in range(4 , xMax): # +2 ,-2 to prevent rooms spawning in border
			#ensures space between tiles
			if Map2.get_cell(ul.x + x, ul.y + y+1) == tiles["CavePlatform1Way"]:
				continue
			if remainingSpawn:
				remainingSpawn -= 1
				Map2.set_cell(ul.x + x, ul.y + y, tiles["CavePlatform1Way"])

			else:
				spawnPlatform = rng.randi_range(0,10)
				if spawnPlatform > platformSpawnRate:
					platformPlaced += 1
					remainingSpawn = rng.randi_range(0, 5)
					Map2.set_cell(ul.x + x, ul.y + y, tiles["CavePlatform1Way"])	


func corners(room):
	var s = (room.size/ tile_size).floor()
	var pos = Map.world_to_map(room.position)
	var ul = (room.position/ tile_size).floor() - s # upper left corner, room.pos is center
	var xMax = s.x*2 #prevents spawning in border
	var yMax = s.y*2
	
	var platformMaxLength = room.size / 2
	var corner = 0 #false
	var cornerLength = 0
	var cornerHeight = 0
	#cornerLengthAddition
	var addCorner = rng.randi_range(1,10)
	while addCorner > 5:
		addCorner -= 1
		#1 is top left, 2 top right, 3 bottom left, 4 bottom right
		corner = rng.randi_range(1,4)
		cornerLength = rng.randi_range(1, room.size.x/(tile_size*2)-2) #as to not block the entryway
		cornerHeight = rng.randi_range(1, room.size.y/(tile_size*2)-2) #as to not block possible entryway
					
		for x in range(2, xMax -1):
			if corner:
				#for left side to not impede right
				if corner == 1 or corner == 3:
					if x > cornerLength+2:
						corner = 0
				for y in range(2, yMax-1): #stops corners from being carved together
					#do not carve
					if Map.get_cell(ul.x + x,ul.y + y) == tiles["CaveInnerBG"]:
						continue
					if corner:
						if corner == 1: #top left
							if y <= cornerHeight+2:
								cornerTilePlace(x,y,ul)
								
						elif corner == 2: # top right
							if x >= room.size.x/tile_size + (cornerLength+2):
								if y <= cornerHeight+2:
									cornerTilePlace(x,y,ul)
						elif corner == 3: #bottom left
							if y > room.size.y/tile_size + (cornerHeight+2):
								cornerTilePlace(x,y,ul)
						elif corner == 4: # bottom right
							if x >= room.size.x/tile_size + (cornerLength+2):
								if  y > room.size.y/tile_size + (cornerHeight+2):
									cornerTilePlace(x,y,ul)
						

func cornerTilePlace(x, y, ul):
	randomAdditionTile = rng.randi_range(1,4)
	MapWall.set_cell(ul.x + x,ul.y + y, tiles[(caveAdditionTile + str(randomAdditionTile))])
	Map2.set_cell(ul.x + x,ul.y + y, -1) # removes platforms if present

func createExit():
	var endRoomCenter = (end_room.position/ tile_size).floor()
	#room door/start platform
	var exitDoor = Door.instance()
	# fix exact position
	var exitDoorPosition = Map.world_to_map(end_room.position )
	#removes platform if above door
	MapInteract.set_cell(endRoomCenter.x, endRoomCenter.y, tiles["CaveDoor"])
	Map2.set_cell(endRoomCenter.x, endRoomCenter.y + 1, tiles["CavePlatform1Way"])
	Map2.set_cell(endRoomCenter.x, endRoomCenter.y, -1)
	
	var doorTiles = MapInteract.get_used_cells_by_id(tiles["CaveDoor"])
	# add vector to fix position offset
	exitDoor.place(MapInteract.map_to_world(doorTiles[0] + Vector2(0,1)))
	
	$Doors.add_child(exitDoor)

func placeBerryBush(_tile, berry):
	var berryBush = BerryBush.instance()
	var berrybushPosition = MapInteract.map_to_world(_tile)
	
	berryBush.place((berrybushPosition),berry)
	
	$Bushes.add_child(berryBush)

func spawnEnemies(room, xSpawnMax, ySpawnMax, ul):
	var roomBounds = room.size / tile_size

	for i in range (0, rng.randi_range(2, enemySpawnRate)):
		var posOffset = Vector2(rng.randi_range(0, xSpawnMax-1),
						rng.randi_range(0, ySpawnMax-1))
		var enemyPos = room.position + ul + posOffset
		var e = Slime.instance()
		
		e.make_enemy(enemyPos)
		$Enemies.add_child(e)
