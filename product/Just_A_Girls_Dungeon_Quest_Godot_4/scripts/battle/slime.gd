extends Node3D

const GRID_SIZE = 1.0

var target_position = Vector3.ZERO
var is_moving = false
var move_speed = 5.0
var current_cell = Vector2i()
var accessible_cells = {}
var player = null
var in_battle = false

# Combat stats
var enemy_type = "Slime"
var level = 1
var max_hp = 50
var current_hp = 50
var attack = 10
var defense = 5
var experience_reward = 50

# Moves the enemy can use
var moves = ["Slime Attack", "Defend"]

func _ready():
	add_to_group("enemies")
	print("Enemy ready at cell: ", current_cell)
	
	# Initialize enemy stats
	current_hp = max_hp

func _process(_delta):
	# Always check for battle when not moving
	if not is_moving and not in_battle:
		check_for_battle()
	
func _physics_process(delta):
	if is_moving and not in_battle:  # Don't move during battle
		var move_step = move_speed * delta
		var distance = global_transform.origin.distance_to(target_position)
		
		if distance < move_step:
			global_transform.origin = target_position
			is_moving = false
			print("Enemy stopped moving at cell: ", current_cell)
			check_for_battle()
		else:
			global_transform.origin = global_transform.origin.move_toward(target_position, move_step)

func set_cell(cell: Vector2i):
	current_cell = cell
	global_transform.origin = Vector3(cell.x * GRID_SIZE, 0.1, cell.y * GRID_SIZE)
	print("Enemy set to cell: ", current_cell)

func move_towards_player():
	if player == null or accessible_cells.size() == 0 or in_battle:
		return
		
	# Always check for battle before moving
	if check_for_battle():
		return
		
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
	
	print("Enemy at cell: ", current_cell, " Player at cell: ", player_cell)
	
	# Get possible moves (adjacent accessible cells)
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
		print("Enemy has no possible moves")
		return
	
	# Choose the move that gets closest to player
	var best_move = current_cell
	var best_distance = 999999
	
	for move in possible_moves:
		var distance = abs(move.x - player_cell.x) + abs(move.y - player_cell.y)
		if distance < best_distance:
			best_distance = distance
			best_move = move
	
	# Move to the best cell
	if best_move != current_cell:
		print("Enemy moving from ", current_cell, " to ", best_move)
		current_cell = best_move
		target_position = Vector3(best_move.x * GRID_SIZE, 0.1, best_move.y * GRID_SIZE)
		is_moving = true
	else:
		print("Enemy staying at current cell")

func check_for_battle() -> bool:
	if player == null or in_battle:
		return false
		
	var player_cell = Vector2i(
		floor(player.global_transform.origin.x / GRID_SIZE),
		floor(player.global_transform.origin.z / GRID_SIZE)
	)
		
	if current_cell == player_cell:
		print("BATTLE STARTED with enemy at cell: ", current_cell)
		start_battle()
		return true
	
	return false

func start_battle():
	in_battle = true
	
	# Get the battle manager
	var battle_managers = get_tree().get_nodes_in_group("battle_manager")
	if battle_managers.size() > 0:
		var battle_manager = battle_managers[0]
		battle_manager.start_battle(player, self)
	else:
		print("ERROR: No battle manager found in the scene!")
		# Fallback to old behavior if no battle manager
		var timer = Timer.new()
		timer.wait_time = 0.1
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		timer.connect("timeout", _on_battle_timeout)

# --- Combat related functions ---

func take_damage(amount):
	current_hp = max(0, current_hp - amount)
	print("Enemy took ", amount, " damage! HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		_on_defeated()
		
	return current_hp

func _on_defeated():
	print("Enemy has been defeated!")
	# The battle manager will handle removal and rewards

func _on_battle_timeout():
	print("Enemy defeated and removed from cell: ", current_cell)
	queue_free()

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
