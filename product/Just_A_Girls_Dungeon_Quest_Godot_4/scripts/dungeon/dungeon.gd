extends Node3D

const Cell = preload("res://scenes/dungeon/cell.tscn")
const Ladder = preload("res://scenes/dungeon/ladder.tscn")
const Tile = preload("res://scenes/dungeon/tile.tscn")

const BattleManager = preload("res://scenes/battle/battle_manager.tscn")
const Enemy = preload("res://scenes/battle/slime.tscn")

@onready var player = $Player
@onready var player_health_ui = null

var cells = []
var accessible_cells = {}
var ladder_cell = Vector2i()
var current_floor = 0
var MAP_SIZE = Vector2(4, 4)
const MAP_SIZE_INCREMENT = Vector2(1, 1)
const MAX_STEPS = 100
const GRID_SIZE = 1
const BOSS_FLOOR = 5

var tiles = []
var tile_cells = {}  # Cells that have tiles
var tile_types = ["damage", "heal", "teleport", "surprise"]

var num_enemies = max(1, floor(current_floor / 2))  # Number of enemies per floor

var enemies = []

# Minimap related variables
var minimap = null
var explored_cells = {}  # Cells that the player has seen

func _ready():
	_setup_ui()
	_setup_battle_manager()
	_generate_new_floor()
		
	_update_minimap()
	
func _input(event):
	if event.is_action_pressed("ui_accept"): 
		var player_cell = Vector2i(
			floor(player.global_transform.origin.x / GRID_SIZE),
			floor(player.global_transform.origin.z / GRID_SIZE)
		)
		
		if player_cell == ladder_cell:
			print("Player used ladder! Going down to next floor")
			_descend_to_next_floor()

func _on_player_moved():
	# Add current cell to explored cells
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	
	explored_cells[player_cell] = true
	
	var vision_radius = 3  # How many cells can be seen
	
	# Explore in a square pattern around the player
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var check_cell = player_cell + Vector2i(x, y)
			
			if accessible_cells.has(check_cell):
				# Calculate Manhattan distance (city block distance)
				var distance = abs(x) + abs(y)
				
				if distance <= vision_radius:
					explored_cells[check_cell] = true
					
	_update_minimap()
	
	print("Player moved - checking for battles first")
	
	var battle_started = false
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.check_for_battle():
				battle_started = true
				break  
	
	if not battle_started:
		for tile in tiles:
			if is_instance_valid(tile):
				if tile.check_player_collision(player_cell):
					if tile_cells.has(player_cell):
						tile_cells.erase(player_cell)
	
	_clean_invalid_enemies()
	
	if not battle_started:
		_move_all_enemies()

func _setup_battle_manager():
	var battle_manager = BattleManager.instantiate()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)
	
	battle_manager.connect("battle_started", _on_battle_started)
	battle_manager.connect("battle_ended", _on_battle_ended)
	
	add_to_group("dungeon")

func _on_battle_started(battle_player, battle_enemy):
	print("Dungeon: Battle started between player and enemy")
	
	if player_health_ui:
		player_health_ui.visible = false
		
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.in_battle = true

func _on_battle_ended(victor):
	print("Dungeon: Battle ended. Victor: ", "Player" if victor == player else "Enemy")
	
	if player_health_ui:
		player_health_ui.visible = true
		player_health_ui.update_player_info()
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.in_battle = false
	
	_clean_invalid_enemies()
	
	_update_minimap()

	
func _clean_invalid_enemies():
	var valid_enemies = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
		else:
			print("Removing invalid enemy reference")
	
	if valid_enemies.size() != enemies.size():
		print("Cleaned enemy list: before=", enemies.size(), " after=", valid_enemies.size())
		enemies = valid_enemies

func _move_all_enemies():
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if not is_instance_valid(enemy):
			continue
			
		if not enemy.is_moving and not enemy.in_battle:
			print("Moving enemy at index ", i)
			enemy.move_towards_player()
		else:
			print("Enemy at index ", i, " is already moving or in battle")
	
	_update_minimap()

func restart_floor():
	print("Restarting current floor after player defeat")
	
	_clear_current_floor()
	
	_generate_new_floor()



func _update_minimap():
	if minimap:
		# Get enemy positions
		var enemy_positions = []
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy_positions.append(enemy.current_cell)
		
		# Get tile positions
		var tile_positions = []
		for tile in tiles:
			if is_instance_valid(tile):
				tile_positions.append(tile.current_cell)
		
		minimap.update_map(
			Vector2i(floor(player.global_transform.origin.x / GRID_SIZE), floor(player.global_transform.origin.z / GRID_SIZE)),
			explored_cells,
			accessible_cells,  
			ladder_cell,
			enemy_positions,
			tile_positions,
			current_floor
		)

func _setup_ui():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UI"
	add_child(canvas_layer)
	
	var container = MarginContainer.new()
	container.name = "MinimapContainer"
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.size_flags_horizontal = Control.SIZE_SHRINK_END
	container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 10)
	
	canvas_layer.add_child(container)
	
	var minimap_scene = preload("res://scenes/dungeon/minimap.tscn").instantiate()
	minimap_scene.name = "Minimap"
	container.add_child(minimap_scene)
	
	self.minimap = minimap_scene
	
	var player_health_scene = preload("res://scenes/ui/player_health_ui.tscn").instantiate()
	player_health_scene.name = "PlayerHealthUI"
	canvas_layer.add_child(player_health_scene)
	
	self.player_health_ui = player_health_scene

func _generate_new_floor():
	_clear_current_floor()
	
	explored_cells.clear()
	
	current_ladder = null
	
	MAP_SIZE = Vector2(4, 4) + (MAP_SIZE_INCREMENT * current_floor)
	
	var random_map = _generate_random_map()
	_create_dungeon(random_map)
	
	if current_floor != BOSS_FLOOR:
		_spawn_ladder()
	
	if current_floor == 0:
		_spawn_player_at_dungeon_start(random_map)
	else:
		_spawn_player_at_random_cell()
	
	if player:
		player.accessible_cells = accessible_cells
		player.ladder_cell = ladder_cell
		
		if player.is_connected("player_moved", _on_player_moved):
			player.disconnect("player_moved", _on_player_moved)
		
		player.connect("player_moved", _on_player_moved)
	
	if current_floor == BOSS_FLOOR:
		_spawn_boss()
		_spawn_tiles()
	elif current_floor == 0:
		_spawn_tiles()  
	else:
		_spawn_enemies()
		_spawn_tiles()
	
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	explored_cells[player_cell] = true

	_update_minimap()
	
	print("Generated floor ", current_floor, " with size ", MAP_SIZE)

func _clear_current_floor():
	for cell in cells:
		if is_instance_valid(cell):
			cell.queue_free()
	
	if current_ladder != null:
		current_ladder.queue_free()
		current_ladder = null
	
	# Clear all enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	
	cells.clear()
	accessible_cells.clear()

func _descend_to_next_floor():
	current_floor += 1
	
	_cleanup_all_ladders()
	
	_generate_new_floor()
	
func _cleanup_all_ladders():
	var ladders = get_tree().get_nodes_in_group("ladders")
	for ladder in ladders:
		ladder.queue_free()
		
	for child in get_children():
		if child == player:
			continue
			
		if "ladder" in child.name.to_lower():
			child.queue_free()
			
		if child is Node3D and child.position.y < 0.1:
			if current_ladder == null: 
				current_ladder = null 

func _generate_random_map() -> Array:
	var map = []
	for y in range(MAP_SIZE.y):
		var row = []
		for x in range(MAP_SIZE.x):
			row.append(0)
		map.append(row)
	
	var gen_position = Vector2(floor(MAP_SIZE.x / 2), floor(MAP_SIZE.y / 2))
	map[gen_position.y][gen_position.x] = 1
	accessible_cells[Vector2i(gen_position.x, gen_position.y)] = true

	for i in range(MAX_STEPS):
		var direction = randi() % 4
		match direction:
			0: gen_position.y -= 1  # North
			1: gen_position.y += 1  # South
			2: gen_position.x -= 1  # West
			3: gen_position.x += 1  # East
		
		gen_position.x = clamp(gen_position.x, 0, MAP_SIZE.x - 1)
		gen_position.y = clamp(gen_position.y, 0, MAP_SIZE.y - 1)
		
		map[gen_position.y][gen_position.x] = 1
		accessible_cells[Vector2i(gen_position.x, gen_position.y)] = true
	
	return map

func _create_dungeon(random_map: Array):
	var used_tiles = []

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			if random_map[y][x] == 1:
				var cell = Cell.instantiate()
				add_child(cell)
				cells.append(cell)
				cell.global_transform.origin = Vector3(x * GRID_SIZE, 0, y * GRID_SIZE)
				used_tiles.append(Vector2i(x, y))
	
	for cell in cells:
		if cell.has_method("update_faces"):
			cell.update_faces(used_tiles)

func _spawn_player_at_dungeon_start(random_map: Array):
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			if random_map[y][x] == 1:
				player.global_transform.origin = Vector3(x * GRID_SIZE, GRID_SIZE / 2, y * GRID_SIZE)
				
				var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
				for dir in directions:
					var check_cell = Vector2i(x, y) + dir
					if accessible_cells.has(check_cell):
						# Face toward an open cell
						var angle = 0
						if dir.x == 1:  # East
							angle = -90
						elif dir.x == -1:  # West
							angle = 90
						elif dir.y == 1:  # South
							angle = 180
						# North is 0 (default)
						
						player.rotation = Vector3(0, deg_to_rad(angle), 0)
						return
				
				return

func _spawn_player_at_random_cell():
	var possible_cells = accessible_cells.keys()
	
	if possible_cells.size() > 0:
		var spawn_cell = possible_cells[randi() % possible_cells.size()]
		
		var attempts = 0
		while spawn_cell == ladder_cell and attempts < 10:
			spawn_cell = possible_cells[randi() % possible_cells.size()]
			attempts += 1
		
		player.global_transform.origin = Vector3(
			spawn_cell.x * GRID_SIZE,
			GRID_SIZE / 2,
			spawn_cell.y * GRID_SIZE
		)
		
		var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
		for dir in directions:
			var check_cell = spawn_cell + dir
			if accessible_cells.has(check_cell):
				# Face toward an open cell
				var angle = 0
				if dir.x == 1:  # East
					angle = -90
				elif dir.x == -1:  # West
					angle = 90
				elif dir.y == 1:  # South
					angle = 180
				# North is 0 (default)
				
				player.rotation = Vector3(0, deg_to_rad(angle), 0)
				break
		
		print("Player spawned at cell: ", spawn_cell)

func _spawn_enemies():
	enemies.clear()  
	
	var possible_cells = accessible_cells.keys()
	var num_enemies_to_spawn = num_enemies + floor(current_floor / 2)
	
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	
	print("Spawning ", num_enemies_to_spawn, " enemies...")
	
	for i in range(num_enemies_to_spawn):
		if possible_cells.size() <= 1:
			print("Not enough cells to spawn enemy")
			break
			
		var enemy_cell = possible_cells[randi() % possible_cells.size()]
		
		var attempts = 0
		while (enemy_cell == player_cell or enemy_cell == ladder_cell or _is_cell_occupied(enemy_cell)) and attempts < 10:
			enemy_cell = possible_cells[randi() % possible_cells.size()]
			attempts += 1
			
		if attempts >= 10:
			print("Couldn't find valid cell for enemy after 10 attempts")
			continue
			
		var enemy = Enemy.instantiate()
		add_child(enemy)
		enemy.set_cell(enemy_cell)
		enemy.accessible_cells = accessible_cells
		enemy.player = player
		enemies.append(enemy)
		
		print("Enemy ", i, " spawned at cell: ", enemy_cell)
	
	print("Total enemies spawned: ", enemies.size())

func _spawn_tiles():
	# Clear existing tiles
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	
	tiles.clear()
	tile_cells.clear()
	
	var num_tiles = max(0, floor(current_floor / 2))
	var possible_cells = accessible_cells.keys()
	
	print("Spawning ", num_tiles, " tiles...")
	
	for i in range(num_tiles):
		if possible_cells.size() <= 1:
			print("Not enough cells to spawn tile")
			break
			
		var tile_cell = possible_cells[randi() % possible_cells.size()]
		
		var attempts = 0
		while (_is_cell_occupied(tile_cell) or tile_cell == ladder_cell or tile_cells.has(tile_cell) or tile_cell == Vector2i(
			floor(player.global_transform.origin.x / GRID_SIZE),
			floor(player.global_transform.origin.z / GRID_SIZE)
		)) and attempts < 10:
			tile_cell = possible_cells[randi() % possible_cells.size()]
			attempts += 1
			
		if attempts >= 10:
			print("Couldn't find valid cell for tile after 10 attempts")
			continue
			
		var tile = Tile.instantiate()
		add_child(tile)
		
		# Set a random tile type
		var random_type = tile_types[randi() % tile_types.size()]
		tile.tile_type = random_type
		
		tile.set_cell(tile_cell)
		tile.connect("tile_activated", _on_tile_activated)
		
		tiles.append(tile)
		tile_cells[tile_cell] = true
		
		print("Tile (", random_type, ") spawned at cell: ", tile_cell)
	
	print("Total tiles spawned: ", tiles.size())

func _on_tile_activated(tile_type):
	print("Tile effect triggered: ", tile_type)
	
	match tile_type:
		"damage":
			# Deal random damage (max 20% of player's health)
			var max_damage = ceil(player.max_hp * 0.2)
			var damage = randi_range(1, max_damage)
			
			# damage doesn't take player below 1 HP
			if player.current_hp - damage < 1:
				damage = player.current_hp - 1
				
			# Don't apply damage if player only has 1 HP left
			if player.current_hp > 1:
				player.take_damage(damage)
				show_princess_dialogue("Ouch! I took " + str(damage) + " damage from that trap!", "", true)
			else:
				show_princess_dialogue("That was close! The trap didn't activate.", "", true)
			
		"heal":
			# Heal random amount (max 10% of player's health)
			var max_heal = ceil(player.max_hp * 0.1)
			var heal_amount = randi_range(1, max_heal)
			player.heal(heal_amount)
			
			show_princess_dialogue("This tile healed me for " + str(heal_amount) + " HP!", "", true)
			
		"teleport":
			_teleport_player()
			
		"surprise":			
			show_princess_dialogue("The tile I stepped on did nothing.", "", true)

func _teleport_player():
	if player.in_battle:
		return
	
	show_princess_dialogue("What's happening?!", "", true)
	
	player.set_process_input(false)
	
	var camera = player.get_node("Camera3D") if player.has_node("Camera3D") else null
	if not camera:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(camera, "rotation_degrees", Vector3(0, 360, 0), 1.0).from(Vector3.ZERO)
	
	tween.tween_property(camera, "rotation_degrees", Vector3(0, 720, 0), 0.7).from(Vector3(0, 360, 0))
	
	tween.tween_callback(func():
		camera.rotation_degrees = Vector3.ZERO
		
		var possible_cells = accessible_cells.keys()
		var current_player_cell = Vector2i(
			floor(player.global_transform.origin.x / GRID_SIZE),
			floor(player.global_transform.origin.z / GRID_SIZE)
		)
		
		var valid_cells = []
		for cell in possible_cells:
			if cell != current_player_cell and cell != ladder_cell and not _is_cell_occupied(cell):
				valid_cells.append(cell)
		
		if valid_cells.size() > 0:
			var target_cell = valid_cells[randi() % valid_cells.size()]
			
			player.global_transform.origin = Vector3(
				target_cell.x * GRID_SIZE,
				GRID_SIZE / 2,
				target_cell.y * GRID_SIZE
			)
			
			explored_cells[target_cell] = true
			_update_minimap()
			
			var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
			for dir in directions:
				var check_cell = target_cell + dir
				if accessible_cells.has(check_cell):
					# Face toward an open cell
					var angle = 0
					if dir.x == 1:  # East
						angle = -90
					elif dir.x == -1:  # West
						angle = 90
					elif dir.y == 1:  # South
						angle = 180
					# North is 0 (default)
					
					player.rotation = Vector3(0, deg_to_rad(angle), 0)
					break
			
			show_princess_dialogue("I've been teleported to another part of the dungeon!", "", true)
		else:
			show_princess_dialogue("The teleportation failed!", "", true)
		
		player.set_process_input(true)
	)

func _is_cell_occupied(cell: Vector2i) -> bool:
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_cell == cell:
			return true
	return false

var current_ladder = null

func _spawn_ladder():
	_cleanup_all_ladders()
	
	var possible_cells = accessible_cells.keys()
	
	if possible_cells.size() > 0:
		var player_cell = Vector2i(
			floor(player.global_transform.origin.x / GRID_SIZE),
			floor(player.global_transform.origin.z / GRID_SIZE)
		)
		
		ladder_cell = possible_cells[randi() % possible_cells.size()]
		
		# Make sure ladder doesn't spawn at player's position
		var attempts = 0
		while ladder_cell == player_cell and attempts < 10:
			ladder_cell = possible_cells[randi() % possible_cells.size()]
			attempts += 1
			
		var ladder = Ladder.instantiate()
		ladder.name = "Ladder_Floor_" + str(current_floor)
		add_child(ladder)
		current_ladder = ladder
		
		ladder.global_transform.origin = Vector3(
			ladder_cell.x * GRID_SIZE,
			0,
			ladder_cell.y * GRID_SIZE
		)
		
		print("Ladder spawned at cell: ", ladder_cell, " on floor ", current_floor)

func _spawn_boss():
	print("Spawning boss on floor " + str(current_floor))
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	
	var possible_cells = accessible_cells.keys()
	var boss_cell = possible_cells[randi() % possible_cells.size()]
	
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	
	var attempts = 0
	while boss_cell == player_cell and attempts < 10:
		boss_cell = possible_cells[randi() % possible_cells.size()]
		attempts += 1
	
	var boss = Enemy.instantiate()
	add_child(boss)
	
	boss.global_transform.origin = Vector3(boss_cell.x * GRID_SIZE, 0.1, boss_cell.y * GRID_SIZE)
	boss.current_cell = boss_cell  
	
	boss.enemy_type = "Dungeon Guardian" 
	boss.max_hp = 200
	boss.current_hp = 200
	boss.attack = 15
	boss.defense = 5
	boss.experience_reward = 100
	boss.moves = ["Guardian Slam", "Crushing Blow", "Stone Armor"]
	boss.scale = Vector3(2, 2, 2)  
	
	var sprite = boss.find_child("Sprite3D")
	if sprite:
		sprite.modulate = Color(0.8, 0.3, 0.3) 
	
	boss.accessible_cells = accessible_cells
	boss.player = player
	enemies.append(boss)
	
	print("Boss spawned at cell: ", boss_cell)
	
	show_princess_dialogue("I better be careful, it seems like there's a boss on this floor.", "", true)


func _on_boss_defeated():
	if player:
		player.set_process_input(false)
	
	var dialogue = show_princess_dialogue(
		"I did it! I defeated the Dungeon Guardian! I can't wait to tell everyone back in town!", 
		"res://scenes/scene_2.tscn", 
		false 
	)
	
	var fallback_timer = Timer.new()
	fallback_timer.wait_time = 10.0 
	fallback_timer.one_shot = true
	add_child(fallback_timer)
	
	fallback_timer.timeout.connect(func():
		print("FALLBACK: Dialogue didn't close properly, forcing scene change")
		
		var dialogue_layers = get_tree().get_nodes_in_group("dialogue_layer")
		for layer in dialogue_layers:
			layer.queue_free()
		
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file("res://scenes/scene_2.tscn")
	)
	
	fallback_timer.start()
	
	if dialogue and dialogue.has_signal("dialogue_closed"):
		dialogue.connect("dialogue_closed", func():
			print("Dialogue closed properly, cancelling fallback timer")
			fallback_timer.stop()
			fallback_timer.queue_free()
		)
	
func show_princess_dialogue(text, next_scene = "", auto_dismiss = false):
	var existing_dialogue = get_tree().get_nodes_in_group("dialogue_layer")
	if existing_dialogue.size() > 0:
		existing_dialogue[0].show_dialogue(Global.player_name, text, next_scene, auto_dismiss)
		return existing_dialogue[0]
	
	var dialogue_scene = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	get_tree().root.add_child(dialogue_scene)
	
	dialogue_scene.show_dialogue(Global.player_name, text, next_scene, auto_dismiss)
	
	return dialogue_scene

func debug_cell_info(position: Vector3):
	var cell_pos = Vector2i(floor(position.x / GRID_SIZE), floor(position.z / GRID_SIZE))
	print("Debug cell position: ", cell_pos, " is accessible: ", accessible_cells.has(cell_pos))
	print("Ladder is at cell: ", ladder_cell)
	print("Current floor: ", current_floor, " with size ", MAP_SIZE)
	print("Number of enemies: ", enemies.size())
