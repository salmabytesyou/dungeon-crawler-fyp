extends Control

@onready var menu_container = $MenuPanel/MenuContainer
@onready var menu_panel = $MenuPanel
@onready var dialogue_panel = $DialoguePanel
@onready var dialogue_text = $DialoguePanel/DialogueText
@onready var dim_overlay = $ColorRect

var options = ["Talk to King", "Leave"]
var current_selection = 0
var in_dialogue = false
var input_cooldown = false
var king_talking = false
var buttons = []

func _ready():
	# Hide dialogue at start
	dialogue_panel.visible = false
	menu_panel.visible = true
	if dim_overlay:
		dim_overlay.visible = false
	
	create_menu_buttons()

func _input(event):
	if input_cooldown:
		return
	
	if in_dialogue:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			input_cooldown = true
			close_dialogue()
			get_viewport().set_input_as_handled()
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
	if in_dialogue or input_cooldown:
		return
	current_selection = option_index
	select_option()

func select_option():
	match options[current_selection]:
		"Talk to King":
			king_talking = true
			show_dialogue("Aren't you going out? You said you'd prove yourself in the dungeon.", "King")
		"Leave":
			input_cooldown = true 
			var timer = get_tree().create_timer(0.1)
			await timer.timeout
			if is_inside_tree():
				get_tree().change_scene_to_file("res://scenes/town.tscn")

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
	
	if king_talking:
		show_king()

func close_dialogue():
	dialogue_panel.visible = false
	
	for button in buttons:
		button.disabled = false
		button.focus_mode = Control.FOCUS_ALL
	
	if dim_overlay:
		dim_overlay.visible = false
	
	if king_talking:
		hide_king()
		king_talking = false
	
	in_dialogue = false
	
	update_button_focus()

func show_king():
	var king = get_node_or_null("King")
	if king:
		king.visible = true
		
		king.modulate = Color(1, 1, 1, 0)  
		var tween = create_tween()
		tween.tween_property(king, "modulate", Color(1, 1, 1, 1), 0.3)

func hide_king():
	var king = get_node_or_null("King")
	if king:
		var tween = create_tween()
		tween.tween_property(king, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(func(): king.visible = false)
