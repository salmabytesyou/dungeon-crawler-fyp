extends Control

@onready var menu_container = $MenuPanel/MenuContainer
@onready var menu_panel = $MenuPanel
@onready var dialogue_panel = $DialoguePanel
@onready var dialogue_text = $DialoguePanel/DialogueText
@onready var confirm_panel = $ConfirmPanel
@onready var dim_overlay = $ColorRect

var options = ["Go to the Castle", "Talk to Mysterious Man", "Go to Dungeon", "Inventory", "Save", "Load", "Quit"]
var current_selection = 0
var in_dialogue = false
var in_confirm = false
var input_cooldown = false
var mysterious_man_talking = false
var buttons = []
var current_confirm_button = 0 

var save_load_menu_scene = preload("res://scenes/ui/save_load_menu.tscn")
var save_load_menu = null
var notification_dialog = null

func _ready():
	dialogue_panel.visible = false
	confirm_panel.visible = false
	menu_panel.visible = true
	if dim_overlay:
		dim_overlay.visible = false
	
	create_menu_buttons()
	
	# Connect to SaveManager signals
	SaveManager.save_completed.connect(_on_save_completed)
	SaveManager.save_failed.connect(_on_save_failed)
	SaveManager.load_completed.connect(_on_load_completed)
	SaveManager.load_failed.connect(_on_load_failed)

func _input(event):
	if save_load_menu and save_load_menu.visible:
		return
	
	if input_cooldown:
		return
	
	if in_confirm:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			input_cooldown = true
			get_viewport().set_input_as_handled()
			
			if current_confirm_button == 1:  # Yes selected
				get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
			else:  # No selected
				close_confirm()
				var timer = get_tree().create_timer(0.3)
				await timer.timeout
				input_cooldown = false
		elif event.is_action_pressed("ui_cancel"):
			input_cooldown = true
			close_confirm()
			get_viewport().set_input_as_handled()
			var timer = get_tree().create_timer(0.3)
			await timer.timeout
			input_cooldown = false
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			# Toggle between Yes and No
			current_confirm_button = 1 - current_confirm_button  # Toggle between 0 and 1
			update_confirm_button_focus()
			get_viewport().set_input_as_handled()
		return
		
	if in_dialogue:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			input_cooldown = true
			get_viewport().set_input_as_handled()
			
			if options[current_selection] == "Go to Dungeon":
				close_dialogue()
				get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")
				return 
			else:
				close_dialogue()
				var timer = get_tree().create_timer(0.3)
				await timer.timeout
				input_cooldown = false
		return
	
	if event.is_action_pressed("ui_up"):
		current_selection = max(0, current_selection - 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		current_selection = min(options.size() - 1, current_selection + 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		input_cooldown = true
		select_option()
		get_viewport().set_input_as_handled()
		var timer = get_tree().create_timer(0.2)
		await timer.timeout
		input_cooldown = false


func create_menu_buttons():
	for child in menu_container.get_children():
		child.queue_free()
	
	buttons.clear()
	
	for i in range(options.size()):
		var button = Button.new()
		button.text = options[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		
		button.pressed.connect(_on_button_pressed.bind(i))
		
		menu_container.add_child(button)
		buttons.append(button)
	
	update_button_focus()

func update_button_focus():
	for i in range(buttons.size()):
		buttons[i].remove_theme_stylebox_override("normal")
		buttons[i].release_focus()
	
	if current_selection >= 0 and current_selection < buttons.size():
		buttons[current_selection].grab_focus()

func _on_button_pressed(option_index):
	if in_dialogue or in_confirm or input_cooldown:
		return
	current_selection = option_index
	select_option()

func select_option():
	match options[current_selection]:
		"Go to the Castle":
			input_cooldown = true 
			var timer = get_tree().create_timer(0.1)
			await timer.timeout
			if is_inside_tree():
				get_tree().change_scene_to_file("res://scenes/castle.tscn")
		"Talk to Mysterious Man":
			mysterious_man_talking = true
			show_dialogue("Still here, Princess? I thought you'd be deep in the dungeon by now, proving your worth.", "Mysterious Man")
		"Go to Dungeon":
			show_dialogue("Who does that guy think he is? I can do anything, watch me conquer this dungeon!", Global.player_name)
		"Inventory":
			show_dialogue("This feature is not available yet.")
		"Save":
			show_save_menu()
		"Load":
			show_load_menu()
		"Quit":
			show_confirm()

func show_dialogue(text, character_name = ""):
	in_dialogue = true
	
	for button in buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	
	if dim_overlay:
		dim_overlay.visible = true
	
	dialogue_text.clear()
	
	if character_name != "":
		dialogue_text.push_color(Color("#f25e93"))  
		dialogue_text.add_text(character_name)
		dialogue_text.pop()
		dialogue_text.newline()
		
		dialogue_text.add_text("\"" + text + "\"")
	else:
		dialogue_text.add_text(text)
	
	dialogue_panel.visible = true
	
	if mysterious_man_talking:
		show_mysterious_man()

func close_dialogue():
	dialogue_panel.visible = false
	
	for button in buttons:
		button.disabled = false
		button.focus_mode = Control.FOCUS_ALL
	
	if dim_overlay:
		dim_overlay.visible = false
	
	if mysterious_man_talking:
		hide_mysterious_man()
		mysterious_man_talking = false
	
	in_dialogue = false
	
	update_button_focus()

func show_confirm():
	confirm_panel.visible = true
	in_confirm = true
	current_confirm_button = 0  
	
	for button in buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	
	if dim_overlay:
		dim_overlay.visible = true
		
	var yes_button = confirm_panel.get_node_or_null("YesButton")
	var no_button = confirm_panel.get_node_or_null("NoButton")
	
	if yes_button:
		if not yes_button.is_connected("pressed", _on_yes_button_pressed):
			yes_button.pressed.connect(_on_yes_button_pressed)
			
	if no_button:
		if not no_button.is_connected("pressed", _on_no_button_pressed):
			no_button.pressed.connect(_on_no_button_pressed)
		
	update_confirm_button_focus()

func _on_yes_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title.tscn")
	
func _on_no_button_pressed():
	close_confirm()
	
func update_confirm_button_focus():
	var yes_button = confirm_panel.get_node_or_null("YesButton")
	var no_button = confirm_panel.get_node_or_null("NoButton")
	
	if yes_button and no_button:
		yes_button.remove_theme_stylebox_override("normal")
		no_button.remove_theme_stylebox_override("normal")
		
		if current_confirm_button == 1:  # Yes
			yes_button.grab_focus()

		else:  # No
			no_button.grab_focus()


func close_confirm():
	confirm_panel.visible = false
	in_confirm = false
	
	for button in buttons:
		button.disabled = false
		button.focus_mode = Control.FOCUS_ALL
	
	if dim_overlay:
		dim_overlay.visible = false
	
	update_button_focus()


func show_mysterious_man():
	var man = get_node_or_null("MysteriousMan")
	if man:
		man.visible = true
		
		man.modulate = Color(1, 1, 1, 0)  
		var tween = create_tween()
		tween.tween_property(man, "modulate", Color(1, 1, 1, 1), 0.3)

func hide_mysterious_man():
	var man = get_node_or_null("MysteriousMan")
	if man:
		var tween = create_tween()
		tween.tween_property(man, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(func(): man.visible = false)
		

func show_save_menu():
	for button in buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	
	if dim_overlay:
		dim_overlay.visible = true
		
	save_load_menu = save_load_menu_scene.instantiate()
		
	save_load_menu.anchor_right = 1.0
	save_load_menu.anchor_bottom = 1.0
	save_load_menu.position = Vector2.ZERO
	save_load_menu.size = get_viewport_rect().size
	
	add_child(save_load_menu)
	
	save_load_menu.is_save_mode = true
	save_load_menu.refresh_save_slots()
	
	save_load_menu.save_selected.connect(_on_save_selected)
	save_load_menu.closed.connect(_on_save_load_menu_closed)

func show_load_menu():
	for button in buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	
	if dim_overlay:
		dim_overlay.visible = true
	
	save_load_menu = save_load_menu_scene.instantiate()
	
	save_load_menu.anchor_right = 1.0
	save_load_menu.anchor_bottom = 1.0
	save_load_menu.position = Vector2.ZERO
	save_load_menu.size = get_viewport_rect().size
	
	add_child(save_load_menu)
	
	# Set to load mode
	save_load_menu.is_save_mode = false
	save_load_menu.refresh_save_slots()
	
	save_load_menu.load_selected.connect(_on_load_selected)
	save_load_menu.closed.connect(_on_save_load_menu_closed)

func _on_save_selected(slot_number):
	var success = SaveManager.save_game(slot_number)
	if !success:
		print("Failed to save game to slot: ", slot_number)

func _on_load_selected(slot_number):
	var success = SaveManager.load_game(slot_number)
	if success:
		get_tree().reload_current_scene()
	else:
		print("Failed to load game from slot: ", slot_number)

func _on_save_load_menu_closed():
	save_load_menu = null
	
	for button in buttons:
		button.disabled = false
		button.focus_mode = Control.FOCUS_ALL
	
	if dim_overlay:
		dim_overlay.visible = false
	
	# Restore focus
	update_button_focus()

func _on_save_completed():
	show_notification("Game saved successfully!")

func _on_save_failed():
	show_notification("Failed to save game.")

func _on_load_completed():
	show_notification("Game loaded successfully!")

func _on_load_failed():
	show_notification("Failed to load game.")

func show_notification(message):
	if notification_dialog != null:
		notification_dialog.queue_free()
	
	notification_dialog = AcceptDialog.new()
	notification_dialog.title = "Notification"
	notification_dialog.dialog_text = message
	add_child(notification_dialog)
	notification_dialog.popup_centered()
	
	# Auto-close after 2 seconds
	var timer = get_tree().create_timer(2.0)
	timer.connect("timeout", func(): 
		if notification_dialog != null:
			notification_dialog.queue_free()
			notification_dialog = null
	)
