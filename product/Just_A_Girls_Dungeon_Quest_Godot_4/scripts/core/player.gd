extends CharacterBody3D

signal player_moved  

@onready var camera = $Camera3D

const SPEED = 5.0  # Movement speed
const ROTATION_SPEED = 0.3  # Rotation speed
const COOLDOWN_TIME = 0.3  # Cooldown between actions
const GRID_SIZE = 1.0  # Size of a grid cell

var target_position = Vector3.ZERO
var is_moving = false
var is_rotating = false
var accessible_cells = {}
var ladder_cell = Vector2i()
var cooldown_timer = null
var in_battle = false 

# Combat stats
var max_hp = 100
var current_hp = 100
var attack = 25
var defense = 15
var level = 1
var experience = 0
var experience_to_next_level = 100

# Moves/abilities the player can use
var moves = ["Tackle", "Defend", "Heal", "Flee"]

func _ready():
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.wait_time = COOLDOWN_TIME
	cooldown_timer.one_shot = true
	
	if camera:
		camera.global_transform.origin.y = GRID_SIZE * 0.5
		camera.look_at(global_transform.origin, Vector3.UP)
		
	# Initialise from Global stats
	max_hp = Global.player_max_hp
	current_hp = Global.player_current_hp
	attack = Global.player_attack
	defense = Global.player_defense
	level = Global.player_level
	experience = Global.player_experience
	experience_to_next_level = Global.player_experience_to_next_level
	moves = Global.player_moves.duplicate()


func _physics_process(delta):
	if is_moving and not in_battle:  # Don't move during battle
		var move_step = SPEED * delta
		var distance = global_transform.origin.distance_to(target_position)
		
		if distance < move_step:
			global_transform.origin = target_position
			is_moving = false
			emit_signal("player_moved")  # Emit signal when player finishes moving
		else:
			global_transform.origin = global_transform.origin.move_toward(target_position, move_step)

func _input(event):
	if in_battle:
		return  # Don't process movement input during battle
		
	if not (is_moving or is_rotating) and (cooldown_timer == null or cooldown_timer.is_stopped()):
		if event.is_action_pressed("ui_up"):
			move_forward()
		elif event.is_action_pressed("ui_down"):
			move_backward()
		elif event.is_action_pressed("ui_left"):
			rotate_player(deg_to_rad(90))  # Rotate left 90 degrees
		elif event.is_action_pressed("ui_right"):
			rotate_player(deg_to_rad(-90))  # Rotate right 90 degrees
		elif event.is_action_pressed("ui_accept"):
			var current_cell = get_current_cell()
			if current_cell == ladder_cell:
				print("Player is on ladder and pressed spacebar")

func move_forward():
	var forward_direction = -global_transform.basis.z.normalized()
	
	if abs(forward_direction.x) > abs(forward_direction.z):
		forward_direction = Vector3(sign(forward_direction.x), 0, 0)
	else:
		forward_direction = Vector3(0, 0, sign(forward_direction.z))
	
	var target_cell = get_target_cell(forward_direction)
	
	if can_move_to_cell(target_cell):
		target_position = Vector3(
			target_cell.x * GRID_SIZE, 
			global_transform.origin.y, 
			target_cell.y * GRID_SIZE
		)
		is_moving = true
		cooldown_timer.start()
		print("Moving to cell: ", target_cell, " using direction: ", forward_direction)
	else:
		print("Cannot move forward. Target cell: ", target_cell, " is not accessible")

func move_backward():
	var backward_direction = global_transform.basis.z.normalized()
	
	if abs(backward_direction.x) > abs(backward_direction.z):
		backward_direction = Vector3(sign(backward_direction.x), 0, 0)
	else:
		backward_direction = Vector3(0, 0, sign(backward_direction.z))
	
	var target_cell = get_target_cell(backward_direction)
	
	if can_move_to_cell(target_cell):
		target_position = Vector3(
			target_cell.x * GRID_SIZE, 
			global_transform.origin.y, 
			target_cell.y * GRID_SIZE
		)
		is_moving = true
		cooldown_timer.start()
		print("Moving backward to cell: ", target_cell, " using direction: ", backward_direction)
	else:
		print("Cannot move backward. Target cell: ", target_cell, " is not accessible")
		
func rotate_player(angle):
	is_rotating = true
	cooldown_timer.start()
	
	var tween = get_tree().create_tween()
	var end_rot = rotation + Vector3(0, angle, 0)
	tween.tween_property(self, "rotation", end_rot, ROTATION_SPEED)
	tween.tween_callback(func(): is_rotating = false)

func get_current_cell() -> Vector2i:
	return Vector2i(
		floor(global_transform.origin.x / GRID_SIZE),
		floor(global_transform.origin.z / GRID_SIZE)
	)

func get_target_cell(direction: Vector3) -> Vector2i:
	var current_cell = get_current_cell()
	
	if direction.x != 0:
		return Vector2i(current_cell.x + sign(direction.x), current_cell.y)
	else:
		return Vector2i(current_cell.x, current_cell.y + sign(direction.z))

func can_move_to_cell(cell: Vector2i) -> bool:
	var can_move = accessible_cells.has(cell)
	print("Checking if can move to cell: ", cell, " Result: ", can_move)
	return can_move

# --- Combat related functions ---

func take_damage(amount):
	current_hp = max(0, current_hp - amount)
	Global.player_current_hp = current_hp  
	print("Player took ", amount, " damage! HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		_on_defeated()
		
	return current_hp

func heal(amount):
	var heal_amount = min(amount, max_hp - current_hp)
	current_hp += heal_amount
	Global.player_current_hp = current_hp  
	print("Player healed for ", heal_amount, "! HP: ", current_hp, "/", max_hp)
	
	return heal_amount

func _on_defeated():
	print("Player has been defeated!")

func gain_experience(amount):
	experience += amount
	Global.player_experience = experience  
	print("Gained ", amount, " experience! Total: ", experience, "/", experience_to_next_level)
	
	_show_floating_text("+" + str(amount) + " XP", Color(0.5, 1, 0.5))
	
	if experience >= experience_to_next_level:
		level_up()

func _show_floating_text(text, color = Color.WHITE):
   
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10 
	get_tree().root.add_child(canvas)
	
	canvas.add_child(label)
	
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_3d()
		if camera:
			var player_pos = global_transform.origin
			var screen_pos = camera.unproject_position(player_pos + Vector3(0, 1.5, 0))
			label.position = screen_pos - Vector2(label.size.x / 2, label.size.y)
	
	var tween = create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0, 50), 1.0)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(canvas.queue_free)

func level_up():
	level += 1
	Global.player_level = level  
	
	experience -= experience_to_next_level
	Global.player_experience = experience  
	
	experience_to_next_level = int(experience_to_next_level * 1.5)
	Global.player_experience_to_next_level = experience_to_next_level 
	
	max_hp += 10
	Global.player_max_hp = max_hp 
	
	current_hp = max_hp
	Global.player_current_hp = current_hp  
	
	attack += 5
	Global.player_attack = attack  
	
	defense += 5
	Global.player_defense = defense  
	
	print("LEVEL UP! Now level ", level)
	print("HP increased to ", max_hp)
	print("Attack increased to ", attack)
	print("Defense increased to ", defense)
	
	if level == 3 and not "Firebolt" in moves:
		moves.append("Firebolt")
		Global.player_moves = moves.duplicate()  
		print("Learned new move: Firebolt!")
	elif level == 5 and not "Earthquake" in moves:
		moves.append("Earthquake")
		Global.player_moves = moves.duplicate()  
		print("Learned new move: Earthquake!")

func debug_position():
	var current_cell = get_current_cell()
	print("Player position: ", global_transform.origin)
	print("Current cell: ", current_cell)
	print("Forward direction: ", -global_transform.basis.z.normalized())
	print("Standing on ladder: ", current_cell == ladder_cell)
	
	var dungeon = get_node("/root/Dungeon")
	if dungeon:
		dungeon.debug_cell_info(global_transform.origin)
