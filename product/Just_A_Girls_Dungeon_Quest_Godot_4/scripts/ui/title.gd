extends Control

var buttons = []
var current_index = 0
var normal_textures = []
var hover_textures = []
@onready var video_player = $MarginContainer/VideoStreamPlayer
@onready var name_input_popup = $NameInputPopup
@onready var name_input = $NameInputPopup/LineEdit
@onready var vbox_container = $VBoxContainer
@onready var last_frame_texture = $MarginContainer/LastFrame

var save_load_menu_scene = preload("res://scenes/ui/save_load_menu.tscn")
var save_load_menu = null

func _ready():
	video_player.connect("finished", _on_video_finished)
	
	video_player.z_index = -1
	
	if last_frame_texture:
		last_frame_texture.visible = false
	
	name_input_popup.visible = false
	
	video_player.play()
	
	await get_tree().process_frame
	
	buttons = [
		$VBoxContainer/NewButton,
		$VBoxContainer/ContinueButton, 
		$VBoxContainer/SettingsButton, 
		$VBoxContainer/QuitButton
	]
	
	for button in buttons:
		if button is TextureButton:
			normal_textures.append(button.texture_normal)
			hover_textures.append(button.texture_hover)
	
	current_index = 0
	update_button_focus()
	
	var available_saves = SaveManager.get_available_saves()
	print("Available saves: ", available_saves.size())
	if available_saves.size() == 0:
		print("No saves found, disabling continue button")
		buttons[1].disabled = true
	else:
		print("Saves found, enabling continue button")
		buttons[1].disabled = false
	
	set_process_input(true)

func _on_video_finished():
	video_player.visible = false
	
	if last_frame_texture:
		last_frame_texture.visible = true
	else:
		video_player.stream_position = video_player.stream.get_length() - 0.1
		video_player.paused = true

func _input(event):
	if save_load_menu and save_load_menu.visible:
		return
		
	if name_input_popup.visible:
		if event.is_action_pressed("enter"):
			_on_name_confirm_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()
	else:
		if event.is_action_pressed("ui_up"):
			move_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			move_selection(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			press_current_button()
			get_viewport().set_input_as_handled()

func move_selection(direction):
	var original_index = current_index
	var tried_all_buttons = false
	
	while true:
		current_index = (current_index + direction) % buttons.size()
		if current_index < 0:
			current_index = buttons.size() - 1
			
		if !buttons[current_index].disabled or current_index == original_index:
			break
			
		if current_index == original_index:
			tried_all_buttons = true
			break
	
	update_button_focus()

func update_button_focus():
	for i in range(buttons.size()):
		if i < normal_textures.size():
			buttons[i].texture_normal = normal_textures[i]
	
	if current_index < hover_textures.size():
		buttons[current_index].texture_normal = hover_textures[current_index]

func press_current_button():
	if buttons[current_index] != null and !buttons[current_index].disabled:
		buttons[current_index].pressed.emit()

func _on_new_pressed():
	vbox_container.visible = false
	
	name_input_popup.visible = true
	name_input.clear()
	name_input.grab_focus()
	
func _on_name_confirm_pressed():
	var player_name = name_input.text
	if player_name != "":
		Global.player_name = player_name
		# Reset player stats
		Global.reset_player_stats()
		name_input_popup.visible = false
		
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/scene_1.tscn")
	else:
		print("Please enter a name.")

func _on_back_button_pressed():
	name_input_popup.visible = false
	
	vbox_container.visible = true
	
	current_index = 0
	update_button_focus()
	
func _on_continue_pressed():
	show_load_menu()

func show_load_menu():
	save_load_menu = save_load_menu_scene.instantiate()
	add_child(save_load_menu)
	
	save_load_menu.is_save_mode = false
	save_load_menu.refresh_save_slots()
	
	save_load_menu.load_selected.connect(_on_load_selected)
	save_load_menu.closed.connect(_on_save_load_menu_closed)

func _on_load_selected(slot_number):
	var success = SaveManager.load_game(slot_number)
	
	if success:
		get_tree().change_scene_to_file("res://scenes/town.tscn")
	else:
		var error_dialog = AcceptDialog.new()
		error_dialog.title = "Load Error"
		error_dialog.dialog_text = "Failed to load game. The save file may be corrupted."
		add_child(error_dialog)
		error_dialog.popup_centered()

func _on_save_load_menu_closed():
	save_load_menu = null

func _on_settings_pressed():
	pass 

func _on_quit_pressed():
	get_tree().quit()


