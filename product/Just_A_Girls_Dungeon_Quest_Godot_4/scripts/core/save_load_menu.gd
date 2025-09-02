extends Control

signal save_selected(slot_number)
signal load_selected(slot_number)
signal closed

@export var is_save_mode: bool = true
@export var max_save_slots: int = 3

@onready var save_slots_container = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SaveSlotsContainer
@onready var title_label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var empty_saves_label = $Panel/MarginContainer/VBoxContainer/EmptySavesLabel
@onready var back_button = $Panel/MarginContainer/VBoxContainer/BackButton

var slots = []
var selected_slot = -1
var slot_button_scene = preload("res://scenes/ui/save_slot_button.tscn")

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	title_label.text = "Save Game" if is_save_mode else "Load Game"
	
	refresh_save_slots()

func refresh_save_slots():
	# Clear existing slots
	for child in save_slots_container.get_children():
		child.queue_free()
	
	slots.clear()
	
	var available_saves = SaveManager.get_available_saves()
	
	# Create empty slot buttons if needed
	if is_save_mode:
		for i in range(1, max_save_slots + 1):
			var save_exists = false
			var save_data = {}
			
			for save in available_saves:
				if save.slot == i:
					save_exists = true
					save_data = save
					break
			
			_create_slot_button(i, save_exists, save_data)
	else:
		# Only show existing saves in load mode
		if available_saves.size() > 0:
			for save in available_saves:
				_create_slot_button(save.slot, true, save)
		
	empty_saves_label.visible = save_slots_container.get_child_count() == 0

func _create_slot_button(slot_number, save_exists, save_data):
	var slot_button = slot_button_scene.instantiate()
	save_slots_container.add_child(slot_button)
	
	slot_button.setup(slot_number, save_exists, save_data, is_save_mode)
	
	slot_button.save_slot_selected.connect(_on_save_slot_selected)
	slots.append(slot_button)
	
	return slot_button

func _on_save_slot_selected(slot_number):
	selected_slot = slot_number
	
	if is_save_mode:
		if SaveManager.has_save_in_slot(slot_number):
			
			var dialog = ConfirmationDialog.new()
			dialog.title = "Overwrite Save"
			dialog.dialog_text = "Are you sure you want to overwrite this save?"
			
			var theme = preload("res://data/theme/title_theme.tres")
			dialog.theme = theme
			
			dialog.confirmed.connect(func(): _confirm_save(slot_number))
			add_child(dialog)
			dialog.popup_centered()
		else:
			_confirm_save(slot_number)
	else:
		emit_signal("load_selected", slot_number)

func _confirm_save(slot_number):
	emit_signal("save_selected", slot_number)

func _on_back_button_pressed():
	emit_signal("closed")
	queue_free()

func set_save_mode(save_mode):
	is_save_mode = save_mode
	if title_label:
		title_label.text = "Save Game" if is_save_mode else "Load Game"
	refresh_save_slots()
