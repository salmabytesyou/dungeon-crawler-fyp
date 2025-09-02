extends Control

@onready var name_input = $MarginContainer/LineEdit

func _ready():
	pass

func _on_button_pressed():
	var player_name = name_input.text
	if player_name != "":
		
		Global.player_name = player_name
		
		get_tree().change_scene_to_file("res://scenes/scene_1.tscn")
	else:
		print("Please enter a name.")
