extends Node

signal battle_started(player, enemy)
signal battle_ended(victor)
signal turn_ended

enum BattleState {INACTIVE, PLAYER_TURN, ENEMY_TURN, ANIMATING}

var current_state = BattleState.INACTIVE
var current_player = null
var current_enemy = null
var battle_ui = null
var dungeon = null

var original_camera_transform = Transform3D()
var original_player_rotation = Vector3()
var battle_camera_node = null

var original_enemy_shaded = false
var enemy_sprite = null

var flee_base_chance = 0.6  # 60% chance to flee initially
var flee_chance_decrease = 0.15  # Decreases by 15% each failed attempt
var current_flee_chance = flee_base_chance

# Player and enemy stats
var player_stats = {
	"hp": 100,
	"max_hp": 100,
	"attack": 25,
	"defense": 15,
	"moves": ["Tackle", "Defend", "Heal", "Flee"]
}

var enemy_stats = {
	"hp": 50,
	"max_hp": 50,
	"attack": 10,
	"defense": 5,
	"moves": ["Slime Attack", "Defend"]
}

func _ready():
	add_to_group("battle_manager")

func _find_sprite3d_in_node(node):
	if node is Sprite3D:
		return node
	
	for child in node.get_children():
		var result = _find_sprite3d_in_node(child)
		if result:
			return result
	
	return null

func start_battle(player, enemy):
	if current_state != BattleState.INACTIVE:
		return
	
	current_flee_chance = flee_base_chance
	
	print("Battle Manager: Starting battle between player and enemy")
	current_player = player
	current_enemy = enemy
	current_state = BattleState.PLAYER_TURN
	
	_unshade_enemy_sprite()
	
	dungeon = get_tree().get_nodes_in_group("dungeon")[0] if get_tree().get_nodes_in_group("dungeon").size() > 0 else null
	
	player_stats = {
		"hp": player.current_hp,
		"max_hp": player.max_hp,
		"attack": player.attack,
		"defense": player.defense,
		"moves": player.moves.duplicate()
	}
	
	enemy_stats = {
		"hp": enemy.current_hp,
		"max_hp": enemy.max_hp,
		"attack": enemy.attack,
		"defense": enemy.defense,
		"moves": enemy.moves.duplicate()
	}
	
	if current_player:
		current_player.in_battle = true
		
	if current_enemy:
		current_enemy.in_battle = true
	
	_setup_battle_ui()
	
	emit_signal("battle_started", player, enemy)
		
	_update_battle_ui()


func end_battle(victor):
	if enemy_sprite and is_instance_valid(enemy_sprite):
		enemy_sprite.shaded = original_enemy_shaded
		print("Restored original shading for enemy sprite")
	
	if current_state == BattleState.INACTIVE:
		return
		
	print("Battle Manager: Ending battle. Victor: ", "Player" if victor == current_player else "Enemy")
	
	if battle_ui:
		if victor == current_player:
			# Boss was defeated
			if current_enemy and current_enemy.enemy_type == "Dungeon Guardian":
				battle_ui.display_message("You defeated the Dungeon Guardian!")
				await get_tree().create_timer(2.0).timeout
				
				var xp_reward = current_enemy.experience_reward
				current_player.gain_experience(xp_reward)
				
				if not "Ultimate Strike" in current_player.moves:
					current_player.moves.append("Ultimate Strike")
					Global.player_moves = current_player.moves.duplicate()
					battle_ui.display_message("Learned new move: Ultimate Strike!")
					await get_tree().create_timer(2.0).timeout
				
				
				if battle_ui and is_instance_valid(battle_ui):
					battle_ui.queue_free()
					battle_ui = null
				
				_restore_camera()
				
				if current_player and is_instance_valid(current_player):
					current_player.current_hp = player_stats.hp
					Global.player_current_hp = player_stats.hp
					current_player.in_battle = false
				
				if current_enemy and is_instance_valid(current_enemy):
					current_enemy.queue_free()
				
				current_state = BattleState.INACTIVE
				current_player = null
				current_enemy = null
				
				emit_signal("battle_ended", victor)
				
				var dungeons = get_tree().get_nodes_in_group("dungeon")
				if dungeons.size() > 0:
					var dungeon = dungeons[0]
					print("Calling _on_boss_defeated function")
					if dungeon.has_method("_on_boss_defeated"):
						dungeon._on_boss_defeated()
				return  
			
			# Regular enemy defeated
			else:
				battle_ui.display_message("You won the battle!")
				await get_tree().create_timer(1.5).timeout
				if current_enemy and is_instance_valid(current_enemy) and current_player and is_instance_valid(current_player):
					var xp_reward = current_enemy.experience_reward
					battle_ui.display_message("You gained " + str(xp_reward) + " XP!")
					await get_tree().create_timer(1.5).timeout
					current_player.gain_experience(xp_reward)
		else:
			battle_ui.display_message("You were defeated!")
			
			player_stats.hp = 0
			battle_ui.update_health(player_stats.hp, player_stats.max_hp, enemy_stats.hp, enemy_stats.max_hp)
			await get_tree().create_timer(2.0).timeout
			
			if battle_ui and is_instance_valid(battle_ui):
				battle_ui.queue_free()
				battle_ui = null
				
			get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
			return  
		
		await get_tree().create_timer(2.0).timeout
	
	_restore_camera()
	
	if current_player and is_instance_valid(current_player):
		current_player.current_hp = player_stats.hp
		Global.player_current_hp = player_stats.hp
		current_player.in_battle = false
		
	if victor == current_player:
		if current_enemy and is_instance_valid(current_enemy):
			current_enemy.queue_free()
	else:
		if current_player:
			_handle_player_defeat()
	
	if battle_ui and is_instance_valid(battle_ui):
		battle_ui.queue_free()
		battle_ui = null
	
	current_state = BattleState.INACTIVE
	current_player = null
	current_enemy = null
	
	emit_signal("battle_ended", victor)

func _unshade_enemy_sprite():
	if current_enemy:
		enemy_sprite = _find_sprite3d_in_node(current_enemy)
		
		if enemy_sprite:
			original_enemy_shaded = enemy_sprite.shaded
			enemy_sprite.shaded = false
			print("Turned off shading for enemy sprite")

func _setup_battle_ui():
	
	var battle_ui_scene = preload("res://scenes/battle/battle_ui.tscn")
	battle_ui = battle_ui_scene.instantiate()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "BattleUILayer"
	canvas_layer.add_child(battle_ui)
	get_tree().root.add_child(canvas_layer)
	
	_setup_battle_camera()
	
	battle_ui.connect("move_selected", _on_move_selected)

	if current_enemy and current_enemy.enemy_type == "Dungeon Guardian":
		battle_ui.set_boss_battle_mode(true)

func _update_battle_ui():
	if battle_ui:
		battle_ui.update_health(player_stats.hp, player_stats.max_hp, enemy_stats.hp, enemy_stats.max_hp)
		battle_ui.update_turn_indicator(current_state == BattleState.PLAYER_TURN)
		battle_ui.update_moves(player_stats.moves)

func _on_move_selected(move_name):
	if current_state != BattleState.PLAYER_TURN:
		return
		
	print("Battle Manager: Player used ", move_name)
	current_state = BattleState.ANIMATING
	
	match move_name:
		"Tackle":
			_player_attack(15)
			await get_tree().create_timer(1.0).timeout
		"Defend":
			player_stats.defense += 5
			
			if battle_ui:
				battle_ui.display_message("You defended!")
				await get_tree().create_timer(1.5).timeout
				battle_ui.display_message("Your defense rose!")
			await get_tree().create_timer(1.0).timeout
			
		"Heal":
			var min_heal = ceil(player_stats.max_hp * 0.1)
			var max_heal = ceil(player_stats.max_hp * 0.5)
			var heal_amount = randi_range(min_heal, max_heal)
			_player_heal(heal_amount)
			if battle_ui:
				battle_ui.display_message("You healed " + str(heal_amount) + " health!")
			await get_tree().create_timer(1.0).timeout
			
		"Flee":
			_attempt_flee()
			return  
		"Firebolt":
			_player_attack(25)
		"Earthquake":
			_player_attack(35)
		"Ultimate Strike":
			_player_attack(50)
		_:
			_player_attack(player_stats.attack)
	
	if enemy_stats.hp <= 0:
		battle_ui.display_message("Enemy defeated!")
		get_tree().create_timer(1.0).timeout.connect(func(): end_battle(current_player))
	else:
		if current_state != BattleState.INACTIVE:
			current_state = BattleState.ENEMY_TURN
			_update_battle_ui()
			_enemy_turn()

func _player_attack(damage, priority = false):
	var actual_damage = max(1, damage - enemy_stats.defense / 2)
	enemy_stats.hp = max(0, enemy_stats.hp - actual_damage)
	
	if battle_ui:
		battle_ui.update_health(player_stats.hp, player_stats.max_hp, enemy_stats.hp, enemy_stats.max_hp)
		battle_ui.play_attack_animation("player", "enemy", actual_damage)
	
	emit_signal("turn_ended")

func _player_heal(amount):
	var heal_amount = min(amount, player_stats.max_hp - player_stats.hp)
	player_stats.hp += heal_amount
	
	if battle_ui:
		battle_ui.play_heal_animation("player", heal_amount)
	
	emit_signal("turn_ended")

func _attempt_flee():
	# Don't allow fleeing from bosses
	if current_enemy and current_enemy.enemy_type == "Dungeon Guardian":
		if battle_ui:
			battle_ui.display_message("Cannot flee from this enemy!")
			await get_tree().create_timer(1.0).timeout
			
			battle_ui.display_message("You must stand and fight!")
			await get_tree().create_timer(1.0).timeout
			
			current_state = BattleState.PLAYER_TURN
			_update_battle_ui()
		return
	
	var flee_roll = randf()
	print("Flee attempt: Chance=" + str(current_flee_chance*100) + "%, Roll=" + str(flee_roll*100) + "%")
	
	if flee_roll < current_flee_chance:
		# Successful flee
		if battle_ui:
			battle_ui.display_message("Got away safely!")
			await get_tree().create_timer(1.0).timeout
			
			# End battle but without giving XP
			_restore_camera()
			
			if current_player and is_instance_valid(current_player):
				current_player.current_hp = player_stats.hp
				Global.player_current_hp = player_stats.hp
				current_player.in_battle = false
				
			if current_enemy and is_instance_valid(current_enemy):
				current_enemy.queue_free()
			
			if battle_ui and is_instance_valid(battle_ui):
				battle_ui.queue_free()
				battle_ui = null
			
			current_state = BattleState.INACTIVE
			current_player = null
			current_enemy = null
			
			# Reset flee chance for future battles
			current_flee_chance = flee_base_chance
			
			emit_signal("battle_ended", current_player)
	else:
		# Failed flee attempt
		if battle_ui:
			battle_ui.display_message("Couldn't get away!")
			await get_tree().create_timer(1.0).timeout
		
		# Decrease the chance for next attempt
		current_flee_chance = max(0.1, current_flee_chance - flee_chance_decrease)
		
		# Skip to enemy turn after failed flee
		current_state = BattleState.ENEMY_TURN
		_update_battle_ui()
		_enemy_turn()


func _enemy_turn():
	await get_tree().create_timer(1.0).timeout
	
	if current_state != BattleState.ENEMY_TURN:
		return
		
	current_state = BattleState.ANIMATING
	
	var available_moves = enemy_stats.moves
	var selected_move = available_moves[randi() % available_moves.size()]
	
	print("Battle Manager: Enemy used ", selected_move)
	
	match selected_move:
		"Slime Attack":
			_enemy_attack(enemy_stats.attack)
		"Defend":
			enemy_stats.defense += 5
			
			if battle_ui:
				battle_ui.display_message("Enemy defended!")
				await get_tree().create_timer(1.0).timeout
				battle_ui.display_message("Enemy's defense rose!")
				
			await get_tree().create_timer(1.0).timeout
		# Add boss-specific moves here
		"Guardian Slam":
			_enemy_attack(enemy_stats.attack * 1.2)  # 20% more damage
			if battle_ui:
				battle_ui.display_message("Guardian slams with massive force!")
		"Crushing Blow":
			_enemy_attack(enemy_stats.attack * 1.5)  # 50% more damage
			if battle_ui:
				battle_ui.display_message("A devastating blow!")
		"Stone Armor":
			enemy_stats.defense += 4
			if battle_ui:
				battle_ui.display_message("Guardian's skin hardens like stone!")
				await get_tree().create_timer(1.0).timeout
				battle_ui.display_message("Defense sharply increased!")
			await get_tree().create_timer(1.0).timeout
		_:
			_enemy_attack(enemy_stats.attack)
	
	if player_stats.hp <= 0:
		end_battle(current_enemy)
	else:
		current_state = BattleState.PLAYER_TURN
		_update_battle_ui()
	
	emit_signal("turn_ended")

func _enemy_attack(damage):
	var actual_damage = max(1, damage - player_stats.defense / 2)
	player_stats.hp = max(0, player_stats.hp - actual_damage)
	
	Global.player_current_hp = player_stats.hp
	
	if battle_ui:
		battle_ui.update_health(player_stats.hp, player_stats.max_hp, enemy_stats.hp, enemy_stats.max_hp)
		battle_ui.play_attack_animation("enemy", "player", actual_damage)
	
	await get_tree().create_timer(1.0).timeout

func _handle_player_defeat():
	print("Player was defeated!")
	
	pass

func _setup_battle_camera():
	if current_player and current_player.has_node("Camera3D"):
		battle_camera_node = current_player.get_node("Camera3D")
		
		original_camera_transform = battle_camera_node.global_transform
		original_player_rotation = current_player.rotation
		
		var midpoint = (current_player.global_transform.origin + current_enemy.global_transform.origin) / 2
		
		var new_camera_pos = midpoint + Vector3(0, 1, 0) + Vector3(0, 0, 1)
		
		var look_dir = midpoint - new_camera_pos
		var target_basis = Basis.looking_at(look_dir, Vector3.UP)
		
		var target_transform = Transform3D(target_basis, new_camera_pos)
		
		var euler_angles = target_transform.basis.get_euler()
		euler_angles.x -= deg_to_rad(3)  
		target_transform.basis = Basis.from_euler(euler_angles)
		
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(battle_camera_node, "global_transform", target_transform, 0.5)
		
		
func _restore_camera():
	if battle_camera_node and current_player:
		current_player.rotation = original_player_rotation
		
		battle_camera_node.global_transform = original_camera_transform
		
		var current_rotation = battle_camera_node.rotation_degrees
		battle_camera_node.rotation_degrees = Vector3(0, current_rotation.y, 0)
				
		battle_camera_node = null
