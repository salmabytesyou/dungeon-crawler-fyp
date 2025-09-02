extends Button

signal save_slot_selected(slot_number)

var slot_number: int
var save_exists: bool

@onready var slot_label = $HBoxContainer/SlotLabel
@onready var player_info_label = $HBoxContainer/PlayerInfoLabel
@onready var date_label = $HBoxContainer/DateLabel

func _ready():
	pressed.connect(_on_pressed)

func setup(slot_num, has_save, save_data, is_save_mode):
	slot_number = slot_num
	save_exists = has_save
	
	slot_label.text = "Slot " + str(slot_number)
	
	if save_exists:
		var date_dict = save_data.get("date", {})
		var date_string = ""
		
		if !date_dict.is_empty():
			date_string = "%02d/%02d/%d %02d:%02d" % [
				date_dict.month, 
				date_dict.day, 
				date_dict.year,
				date_dict.hour,
				date_dict.minute
			]
		
		date_label.text = date_string
		
		var save_path = SaveManager.get_save_path(slot_number)
		var file = FileAccess.open(save_path, FileAccess.READ)
		
		if file:
			var json_string = file.get_line()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var loaded_data = json.get_data()
				var player_name = loaded_data.get("player_name", "Unknown")
				var player_level = loaded_data.get("player_stats", {}).get("level", 1)
				
				player_info_label.text = player_name + " (Lv. " + str(player_level) + ")"
			else:
				player_info_label.text = "Corrupted save"
		else:
			player_info_label.text = "Error reading save"
	else:
		if is_save_mode:
			player_info_label.text = "Empty slot"
			date_label.text = ""
		else:
			player_info_label.text = "No save data"
			date_label.text = ""

func _on_pressed():
	emit_signal("save_slot_selected", slot_number)
