extends Control

signal move_selected(move_name)

@onready var player_health_bar = $PlayerPanel/PlayerHealthBar
@onready var enemy_health_bar = $EnemyPanel/EnemyHealthBar
@onready var player_health_label = $PlayerPanel/PlayerHealthLabel
@onready var enemy_health_label = $EnemyPanel/EnemyHealthLabel
@onready var turn_indicator = $TurnIndicator
@onready var moves_container = $MovesPanel/MovesContainer
@onready var message_label = $MessagePanel/MessageLabel
@onready var animation_player = $AnimationPlayer

var move_buttons = []
var message_timer = null
var current_selected_move = 0  

func _ready():
	message_label.text = "You're in battle!"
	
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 2.0
	message_timer.connect("timeout", _on_message_timer_timeout)
	add_child(message_timer)
	
	set_process_input(true)

func _on_message_timer_timeout():
	message_label.text = ""
	$MessagePanel.visible = false
	
	if turn_indicator.text == "Your Turn":
		enable_move_buttons()
		if move_buttons.size() > 0:
			_update_selected_move(0)

func _input(event):
	if turn_indicator.text != "Your Turn" or move_buttons.size() == 0 or move_buttons[0].disabled:
		return
		
	if event.is_action_pressed("ui_right"):
		_select_next_move()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_select_previous_move()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_confirm_move_selection()
		get_viewport().set_input_as_handled()

func _select_next_move():
	if move_buttons.size() > 0:
		current_selected_move = (current_selected_move + 1) % move_buttons.size()
		_update_selected_move(current_selected_move)

func _select_previous_move():
	if move_buttons.size() > 0:
		current_selected_move = (current_selected_move - 1 + move_buttons.size()) % move_buttons.size()
		_update_selected_move(current_selected_move)

func _confirm_move_selection():
	if move_buttons.size() > 0 and current_selected_move >= 0 and current_selected_move < move_buttons.size():
		var move_name = move_buttons[current_selected_move].text
		_on_move_button_pressed(move_name)

func _update_selected_move(index):
	# Reset all buttons focus
	for i in range(move_buttons.size()):
		move_buttons[i].release_focus()
		
	if index >= 0 and index < move_buttons.size():
		move_buttons[index].grab_focus()
		current_selected_move = index

func update_health(player_hp, player_max_hp, enemy_hp, enemy_max_hp):
	player_health_bar.max_value = player_max_hp
	player_health_bar.value = round(player_hp)
	player_health_label.text = str(round(player_hp)) + "/" + str(player_max_hp)
	
	var player_name = "Player"
	if Global.player_name != null and Global.player_name.length() > 0:
		player_name = Global.player_name
	$PlayerPanel/PlayerName.text = player_name
	
	enemy_health_bar.max_value = enemy_max_hp
	enemy_health_bar.value = enemy_hp
	enemy_health_label.text = str(enemy_hp) + "/" + str(enemy_max_hp)

func update_turn_indicator(is_player_turn):
	turn_indicator.text = "Your Turn" if is_player_turn else "Enemy Turn"
	
	if is_player_turn and move_buttons.size() > 0:
		_update_selected_move(0)

func update_moves(moves):
	for button in move_buttons:
		button.queue_free()
	
	move_buttons.clear()
	current_selected_move = 0
	
	for move in moves:
		var button = Button.new()
		button.text = move
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.theme = load("res://data/theme/battle_ui_theme.tres")
		button.focus_mode = Control.FOCUS_ALL  
		button.connect("pressed", _on_move_button_pressed.bind(move))
		
		moves_container.add_child(button)
		move_buttons.append(button)
	
	if move_buttons.size() > 0:
		_update_selected_move(0)

func _on_move_button_pressed(move_name):
	emit_signal("move_selected", move_name)
	
	for button in move_buttons:
		button.disabled = true

func enable_move_buttons():
	for button in move_buttons:
		button.disabled = false
	
	if move_buttons.size() > 0:
		_update_selected_move(0)

func play_attack_animation(attacker, target, damage):
	var attacker_name = attacker
	if attacker == "player" and Global.player_name != null and Global.player_name.length() > 0:
		attacker_name = Global.player_name
	
	message_label.text = attacker_name.capitalize() + " attacks for " + str(damage) + " damage!"
	
	var target_panel = $PlayerPanel if target == "player" else $EnemyPanel
	
	var tween = create_tween()
	tween.tween_property(target_panel, "modulate", Color(1, 0, 0, 1), 0.2)
	tween.tween_property(target_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	message_label.text = ""
	
	if turn_indicator.text == "Your Turn":
		enable_move_buttons()

func play_heal_animation(target, amount):
	var target_name = target
	if target == "player" and Global.player_name != null and Global.player_name.length() > 0:
		target_name = Global.player_name
	
	message_label.text = target_name.capitalize() + " healed for " + str(amount) + " HP!"
	
	var target_panel = $PlayerPanel if target == "player" else $EnemyPanel
	
	var tween = create_tween()
	tween.tween_property(target_panel, "modulate", Color(0, 1, 0, 1), 0.2)
	tween.tween_property(target_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	message_label.text = ""
	
	if turn_indicator.text == "Your Turn":
		enable_move_buttons()

func display_message(text):
	if message_timer.is_connected("timeout", _on_message_timer_timeout):
		if message_timer.time_left > 0:
			message_timer.stop()
	
	message_label.text = text
	
	$MessagePanel.visible = true

func set_boss_battle_mode(is_boss):
	if is_boss:
		$EnemyPanel/EnemyName.text = "Slime King"
		$EnemyPanel/EnemyHealthBar.add_theme_color_override("fill_color", Color(0.8, 0.2, 0.2))
	else:
		$EnemyPanel/EnemyName.text = "Enemy"
		$EnemyPanel/EnemyName.remove_theme_color_override("font_color")
		$EnemyPanel/EnemyHealthBar.remove_theme_color_override("fill_color")
