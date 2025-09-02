extends Control

@onready var player_name_label = $HBoxContainer/DetailsVBox/PlayerName
@onready var player_level_label = $HBoxContainer/DetailsVBox/PlayerLvl
@onready var health_bar = $HBoxContainer/HealthVBox/HealthBar
@onready var health_label = $HBoxContainer/HealthVBox/HealthBar/HealthLabel
@onready var exp_bar  = $HBoxContainer/EXPVBox/EXPBar
@onready var exp_label = $HBoxContainer/EXPVBox/EXPBar/EXPLabel

func _ready():
	update_player_info()

func update_player_info():
	player_name_label.text = Global.player_name
	player_level_label.text = "Level " + str(Global.player_level)
	
	health_bar.max_value = Global.player_max_hp
	health_bar.value = Global.player_current_hp
	health_label.text = str(Global.player_current_hp) + "/" + str(Global.player_max_hp)
	
	exp_bar.max_value = Global.player_experience_to_next_level
	exp_bar.value = Global.player_experience 
	exp_label.text = str(Global.player_experience) + "/" + str(Global.player_experience_to_next_level)

func _process(_delta):
	if health_bar.value != Global.player_current_hp:
		update_player_info()

