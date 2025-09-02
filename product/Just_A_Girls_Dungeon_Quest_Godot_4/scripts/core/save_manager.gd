extends Node

signal save_completed
signal load_completed
signal save_failed
signal load_failed

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".save"
var current_save_slot = 1

func _ready():
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)

func get_save_path(slot_number: int) -> String:
	return SAVE_DIR + "save_" + str(slot_number) + SAVE_FILE_EXTENSION

func get_available_saves() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
				
				var slot_str = file_name.replace("save_", "").replace(SAVE_FILE_EXTENSION, "")
				if slot_str.is_valid_int():
					var slot = slot_str.to_int()
					saves.append({
						"slot": slot,
						"file_name": file_name,
						"date": get_save_date(slot)
					})
			file_name = dir.get_next()
	
	saves.sort_custom(func(a, b): return a["slot"] < b["slot"])
	return saves

func get_save_date(slot_number: int) -> Dictionary:
	var path = get_save_path(slot_number)
	
	if FileAccess.file_exists(path):
		var modified_time = FileAccess.get_modified_time(path)
		
		return Time.get_datetime_dict_from_unix_time(modified_time)
	
	return {}

func has_save_in_slot(slot_number: int) -> bool:
	var path = get_save_path(slot_number)
	return FileAccess.file_exists(path)

func save_game(slot_number: int) -> bool:
	var save_path = get_save_path(slot_number)
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"player_name": Global.player_name,
		"player_stats": {
			"max_hp": Global.player_max_hp,
			"current_hp": Global.player_current_hp,
			"attack": Global.player_attack,
			"defense": Global.player_defense,
			"level": Global.player_level,
			"experience": Global.player_experience,
			"experience_to_next_level": Global.player_experience_to_next_level,
			"moves": Global.player_moves
		}
		# Add more game state info as needed
		# Examples:
		# "current_scene": get_tree().current_scene.filename, 
		# "completed_quests": [...],
		# "inventory_items": [...],
	}
	
	# Save to file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_line(json_string)
		file.close()
		current_save_slot = slot_number
		emit_signal("save_completed")
		return true
	else:
		emit_signal("save_failed")
		print("Failed to save game: ", FileAccess.get_open_error())
		return false

# Load game data from a specified slot
func load_game(slot_number: int) -> bool:
	var save_path = get_save_path(slot_number)
	
	if !FileAccess.file_exists(save_path):
		print("Save file not found: ", save_path)
		emit_signal("load_failed")
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			
			# Apply the loaded data
			Global.player_name = save_data["player_name"]
			Global.player_max_hp = save_data["player_stats"]["max_hp"]
			Global.player_current_hp = save_data["player_stats"]["current_hp"]
			Global.player_attack = save_data["player_stats"]["attack"]
			Global.player_defense = save_data["player_stats"]["defense"]
			Global.player_level = save_data["player_stats"]["level"]
			Global.player_experience = save_data["player_stats"]["experience"]
			Global.player_experience_to_next_level = save_data["player_stats"]["experience_to_next_level"]
			Global.player_moves = save_data["player_stats"]["moves"]
			
			current_save_slot = slot_number
			emit_signal("load_completed")
			return true
		else:
			print("Error parsing save file: ", json.get_error_message())
			emit_signal("load_failed")
			return false
	else:
		print("Failed to open save file: ", FileAccess.get_open_error())
		emit_signal("load_failed")
		return false

# Delete a save file
func delete_save(slot_number: int) -> bool:
	var save_path = get_save_path(slot_number)
	
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			var error = dir.remove(save_path.get_file())
			return error == OK
	
	return false
