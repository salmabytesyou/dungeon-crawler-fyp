extends Control

@onready var load_button = $Panel/VBoxContainer/Load
@onready var return_button = $Panel/VBoxContainer/Return
@onready var animation_player = $Label/AnimationPlayer

var save_load_menu_scene = preload("res://scenes/ui/save_load_menu.tscn")
var save_load_menu = null

func _ready():
	load_button.pressed.connect(_on_load_pressed)
	return_button.pressed.connect(_on_return_pressed)
	
	if animation_player:
		animation_player.play("bob")

func _on_load_pressed():
	show_load_menu()

func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

func show_load_menu():
	save_load_menu = save_load_menu_scene.instantiate()
	
	add_child(save_load_menu)
	
	save_load_menu.is_save_mode = false
	save_load_menu.refresh_save_slots()
	
	save_load_menu.load_selected.connect(_on_load_selected)
	save_load_menu.closed.connect(_on_save_load_menu_closed)
	
	var available_saves = SaveManager.get_available_saves()
	if available_saves.size() == 0:
		var notification = AcceptDialog.new()
		notification.title = "No Saves Found"
		notification.dialog_text = "You don't have any saved games."
		notification.theme = load("res://resources/title_theme.tres") if ResourceLoader.exists("res://resources/title_theme.tres") else null
		add_child(notification)
		notification.popup_centered()
		
		await get_tree().create_timer(0.1).timeout
		if save_load_menu:
			save_load_menu.queue_free()
			save_load_menu = null

func _on_load_selected(slot_number):
	var success = SaveManager.load_game(slot_number)
	
	if success:
		get_tree().change_scene_to_file("res://scenes/town.tscn")
	else:
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "Load Error"
		error_dialog.dialog_text = "Failed to load game. The save file may be corrupted."
		error_dialog.theme = load("res://resources/title_theme.tres") if ResourceLoader.exists("res://resources/title_theme.tres") else null
		add_child(error_dialog)
		error_dialog.popup_centered()

func _on_save_load_menu_closed():
	save_load_menu = null
