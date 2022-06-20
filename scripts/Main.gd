extends Node2D

var Room = preload("res://scenes/Room.tscn")
var Spawn = preload("res://scenes/Spawn.tscn")
var Player = preload("res://player/Player.tscn")
var font = preload("res://fonts/Basic96.tres")
var Enemy = preload("res://scenes/Enemy.tscn")
var Slime = preload("res://scenes/Slime.tscn")

onready var Map = $TileMap
onready var Map2 = $Platforms

var rng : RandomNumberGenerator = RandomNumberGenerator.new()
#var number : int  = 0

#how big the tiles r
var tile_size = 32
var num_rooms = 16
var min_size = 6
var max_size = 12
# bigger means more horizontal spread
var hspread = 100
var vspread = 0
var cull = 0.4
#for player placement
var startRoomWidth = 0
var startRoomHeight = 0

#for generating paths
var bgIndex = 0

#enemy spawn rate, max of rand number to determine if spawn
var enemySpawnRate = 10

#likelyhood of widder corridors being generated, can be into 1 to 10 with 10 being 100% wier chance, 7 70% etc.
var corridorWidthChance = 5

var path #AStar pathfindin obj
var start_room = null
var end_room = null
var play_mode = false
var player = null

#tilemap items. Order: plain BG, wall BG, floor, ceiling, wall L, wall R, coner BL, corner BR, corner TL, corner TR
# grassy, grassy w/ flower
var tiles = {"CaveInnerBG" : 0, "CaveOuterBG": 9, "CaveOuterAmyth": 15, "CaveOuterLime" : 16, "CaveOuterCyan": 17, "CaveFloor": 5,"CaveCeiling": 6, 
"CaveWallL" : 7, "CaveWallR": 8, "CaveCornerBL": 4, "CaveCornerBR": 12, "CaveCornerTL": 13, "CaveCornerTR": 14,
"GrassyFloor": 10, "GrassyFlowerRFloor": 11, "CavePlatform": 3, "CaveDoor": 1, "CavePlatform1Way": 18}

# tile used for room cutouts
var caveAdditionTile = "CaveWallL"

func _ready():
	rng.randomize()
	$LoadCam.current = true
	randomize()
	make_rooms()
	
func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread,hspread),rand_range(-vspread, vspread))
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w,h) * tile_size)
		$Rooms.add_child(r)
	#wait til physics stops movement
	yield(get_tree().create_timer(1.2), 'timeout')
	#cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x, room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	# generate min stnaidng tree to conect rooms
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
	update()

func _input(event):
	if event.is_action_pressed("generate"): # p key
		if play_mode:
			player.queue_free()
			play_mode = false
		path = null
		start_room = null
		end_room = null
		Map.clear()
		Map2.clear()
		for n in $Rooms.get_children():
			n.queue_free()
		for e in $Enemies.get_children():
			e.queue_free()
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
		player.position = start_room.position + Vector2(startRoomWidth/(2*tile_size), startRoomHeight/(2*tile_size)) # accounts for edge of room
		#player.position.y += 80
		play_mode = true 
	if event.is_action_pressed("return"): # 0 key
		get_tree().change_scene("res://rooms/Spawn.tscn")
		queue_free()

func find_mst(nodes):
	#Prim's alg
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat til no nodes
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
	Map.clear() #erases all existing tiles
	Map2.clear()
	# fill tilemap with walls then carve empty rooms
	var full_rect = Rect2() # rect enclosin entire map
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size, room.get_node("CollisionShape2D").shape.extents*2)
		
		full_rect = full_rect.merge(r)
		var topleft = Map.world_to_map(full_rect.position)
		var bottomright = Map.world_to_map(full_rect.end)
		
		
		# extra so rooms on border show tileset
		for x in range(topleft.x - tile_size/4, bottomright.x + tile_size/4):
			
			for y in range(topleft.y - tile_size/4, bottomright.y + tile_size/4):
				#First wall iteration set to L Wall
				var randTile = randi() % (PlayerVars.depth * 10)
				# Most likely event
				if randTile < PlayerVars.depth * 9:
					Map.set_cell(x,y, tiles["CaveOuterBG"])
				else:
					Map.set_cell(x,y, tiles["CaveOuterAmyth"])
					
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
		"""
		# carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y,0))
		for conn in path.get_point_connections(p):
			if not conn in corridors: #not already done
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y)) #get point pos returns vector 3
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end)
				corridors.append(p)
		"""
		platforms(room)	
		
		# carve connecting corridor
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y,0))
		for conn in path.get_point_connections(p):
			if not conn in corridors: #not already done
				var start = Map.world_to_map(Vector2((path.get_point_position(p).x), path.get_point_position(p).y)) #get point pos returns vector 3
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end, room)
		corridors.append(p)
		
		for x in range(2, xMax -1):
			xiterations += 1
			yiterations = 0
			for y in range(2, yMax-1): #stops rooms from being carved together
				yiterations += 1
				#Map2.set_cell(ul.x + x,ul.y + y, tiles["CaveInnerBG"])
				#left wall
				if Map.get_cell(ul.x + x,ul.y + y) == tiles["CaveInnerBG"] or Map.get_cell(ul.x + x,ul.y + y) == tiles[caveAdditionTile]: #corridor/platforms, (remove platforms
					Map2.set_cell(ul.x + x,ul.y + y, -1) #removes tile
					continue
					#Map2.set_cell(ul.x + x,ul.y + y, tiles["CaveInnerBG"])
				if xiterations == 1:
					#Top L corner
					if yiterations == 1:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveCornerTL"])
					#Bottom L corner
					elif yiterations == yMax-3:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveCornerBL"])
					else:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveWallL"]) 
				#right wall, last iteration
				elif xiterations == xMax-3:
					#Top R Corner
					if yiterations == 1:
						Map.set_cell(ul.x + x,ul.y + y,tiles["CaveCornerTR"])
					#Bottom R corner
					elif yiterations == yMax-3:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveCornerBR"])
					else:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveWallR"]) 
				else:
					#ceiling
					if yiterations == 1:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveCeiling"])
					# Floor
					elif yiterations == yMax-3:
						Map.set_cell(ul.x + x,ul.y + y, tiles["CaveFloor"])
					else:
						# foreground
						Map.set_cell(ul.x + x,ul.y + y,tiles["CaveInnerBG"])
		#spawn platform
		
				
		var roomBounds = room.size / tile_size
		
		var roomCenter = (room.position/ tile_size).floor()
		for i in range (0, rng.randi_range(2, enemySpawnRate)):
			var posOffset = roomBounds * rng.randf_range(-1,1)
			var e = Slime.instance()
			
			e.make_enemy(room.position + posOffset)
			$Enemies.add_child(e)
	find_start_room()
	find_end_room()
	# middle of start room
	var startRoomCenter = (start_room.position/ tile_size).floor()
	#room door/start platform
	Map2.set_cell(startRoomCenter.x, startRoomCenter.y, tiles["CaveDoor"])
	Map2.set_cell(startRoomCenter.x, startRoomCenter.y + 1, tiles["CavePlatform"])
	
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
		"""
		var currentTopCell =  Map.get_cell(x, x_y.y - y_diff)
		# if enter a room
		if currentTopCell == bgIndex:
			continue
		if currentTopCell== 7: # wall left
			Map.set_cell(x, x_y.y - y_diff, 4) # corner bottom left
		elif currentTopCell == 8: # wall R
			Map.set_cell(x, x_y.y - y_diff, 12) # corner buttom right
		else: 
			Map.set_cell(x, x_y.y - y_diff, floorTile)
		#middle oppen section
		Map.set_cell(x, x_y.y, 11)
		Map.set_cell(x, x_y.y + y_diff, ceilTile) # widens corridor
		"""
		
		
		Map.set_cell(x, x_y.y, tiles["CaveInnerBG"])
		Map.set_cell(x, x_y.y + y_diff, tiles["CaveInnerBG"]) # widens corridor
		# chance to widen corridor even greater
		if widderCorridors:
			Map.set_cell(x, x_y.y - y_diff, tiles["CaveInnerBG"]) # widens corridor
		
	for y in range(pos1.y, pos2.y, y_diff):
		"""
		# if enter a room
		if Map.get_cell(y_x.x,y) == bgIndex:
			continue
		Map.set_cell(y_x.x,y,wallR)
		# middle open section
		Map.set_cell(y_x.x + x_diff,y,0)
		Map.set_cell(y_x.x + x_diff*2,y,wallL)
		"""
		
		
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
		if room.position.x < max_x:
			start_room = room
			max_x = room.position.x

# generates platforms
func platforms(room):
	var s = (room.size/ tile_size).floor()
	var pos = Map.world_to_map(room.position)
	var ul = (room.position/ tile_size).floor() - s # upper left corner, room.pos is center
	var xMax = s.x*2
	var yMax = s.y*2
	
	var platformMaxLength = room.size / 2
	var corner = 0 #false
	var cornerLength = 0
	var cornerHeight = 0
	#cornerLengthAddition
	var addCorner = rng.randi_range(1,3)
	if addCorner < 5:
		#1 is top left, 2 top right, 3 bottom left, 4 bottom right
		corner = rng.randi_range(1,4)
		print(corner)
		cornerLength = rng.randi_range(3, room.size.x/(tile_size*2)-2) #as to not block the entryway
		cornerHeight = rng.randi_range(3, room.size.y/(tile_size*2)-2) #as to not block possible entryway
		print("corridor ", cornerLength)
		print("height", cornerHeight)
	"""
	for x in range(2, xMax -1):
		if corner:
			if x > cornerLength+2:
				print("begone corner")
				corner = 0
			for y in range(2, yMax-1): #stops rooms from being carved together
				print("y", y)
				if y <= cornerHeight+2 and corner != 0:
					print("placing corner")
					Map.set_cell(ul.x + x,ul.y + y, tiles[caveAdditionTile])
	"""
					
	for x in range(2, xMax -1):
		if corner:
			#for left side to not impede right
			if corner == 1 or corner == 3:
				if x > cornerLength+2:
					corner = 0
			for y in range(2, yMax-1): #stops rooms from being carved together
				if corner:
					if corner == 1: #top left
						if y <= cornerHeight+2:
							Map.set_cell(ul.x + x,ul.y + y, tiles[caveAdditionTile])
					elif corner == 2: # top right
						if x >= room.size.x/tile_size + (cornerLength+2):
							if y <= cornerHeight+2:
								Map.set_cell(ul.x + x,ul.y + y, tiles[caveAdditionTile])
					elif corner == 3: #bottom left
						if y > room.size.y/tile_size + (cornerHeight+2):
							Map.set_cell(ul.x + x,ul.y + y, tiles[caveAdditionTile])
					elif corner == 2: # bottom right
						continue
						if x > room.size.x/tile_size + (cornerLength+2):
							if  y >= cornerHeight+2:
								Map.set_cell(ul.x + x,ul.y + y, tiles[caveAdditionTile])

#TO FIX:
# adding corners impedes corridors. move corridors to not spawn on edges















