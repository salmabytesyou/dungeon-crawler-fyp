extends Node3D

const GRID_SIZE = 1.0

var target_position = Vector3.ZERO
var is_moving = false
var move_speed = 4.0  # Slightly slower than regular enemies
var current_cell = Vector2i()
var accessible_cells = {}
var player = null
var in_battle = false

var enemy_type = "Dungeon Guardian"
var level = 10
var max_hp = 200
var current_hp = 200
var attack = 15
var defense = 5
var experience_reward = 100

var moves = ["Guardian Slam", "Crushing Blow", "Stone Armor"]

func _ready():
	add_to_group("enemies")
	print("Boss ready at cell: ", current_cell)
	
	scale = Vector3(2, 2, 2)
	
	var sprite = find_child("Sprite3D")
	if sprite:
		sprite.modulate = Color(0.8, 0.3, 0.3)  # Reddish tint for the boss

func _process(_delta):
	if not is_moving and not in_battle:
		check_for_battle()
	
func _physics_process(delta):
	if is_moving and not in_battle:  
		var move_step = move_speed * delta
		var distance = global_transform.origin.distance_to(target_position)
		
		if distance < move_step:
			global_transform.origin = target_position
			is_moving = false
			print("Boss stopped moving at cell: ", current_cell)
			check_for_battle()
		else:
			global_transform.origin = global_transform.origin.move_toward(target_position, move_step)

func set_cell(cell: Vector2i):
	current_cell = cell
	global_transform.origin = Vector3(cell.x * GRID_SIZE, 0.1, cell.y * GRID_SIZE)
	print("Boss set to cell: ", current_cell)

func move_towards_player():
	if player == null or accessible_cells.size() == 0 or in_battle:
		return
		
	if check_for_battle():
		return
		
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	
	print("Boss at cell: ", current_cell, " Player at cell: ", player_cell)
	
	var possible_moves = []
	var directions = [
		Vector2i(1, 0),   # Right
		Vector2i(-1, 0),  # Left
		Vector2i(0, 1),   # Down
		Vector2i(0, -1)   # Up
	]
	
	for dir in directions:
		var target_cell = current_cell + dir
		if accessible_cells.has(target_cell):
			possible_moves.append(target_cell)
	
	if possible_moves.size() == 0:
		print("Boss has no possible moves")
		return
	
	var best_move = current_cell
	var best_distance = 999999
	
	for move in possible_moves:
		var distance = abs(move.x - player_cell.x) + abs(move.y - player_cell.y)
		if distance < best_distance:
			best_distance = distance
			best_move = move
	
	# Move to the best cell
	if best_move != current_cell:
		print("Boss moving from ", current_cell, " to ", best_move)
		current_cell = best_move
		target_position = Vector3(best_move.x * GRID_SIZE, 0.1, best_move.y * GRID_SIZE)
		is_moving = true
	else:
		print("Boss staying at current cell")

func check_for_battle() -> bool:
	if player == null or in_battle:
		return false
		
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
		
	if current_cell == player_cell:
		print("BOSS BATTLE STARTED at cell: ", current_cell)
		start_battle()
		return true
	
	return false


func start_battle():
	in_battle = true
	
	var battle_managers = get_tree().get_nodes_in_group("battle_manager")
	if battle_managers.size() > 0:
		var battle_manager = battle_managers[0]
		battle_manager.start_battle(player, self)
	else:
		print("ERROR: No battle manager found in the scene!")

# --- Combat related functions ---

func take_damage(amount):
	current_hp = max(0, current_hp - amount)
	print("Boss took ", amount, " damage! HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		_on_defeated()
		
	return current_hp

func _on_defeated():
	print("Boss has been defeated!")

func get_stats():
	return {
		"type": enemy_type,
		"level": level,
		"hp": current_hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"moves": moves,
		"xp_reward": experience_reward
	}
