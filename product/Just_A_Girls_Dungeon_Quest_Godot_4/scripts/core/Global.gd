extends Node

const GRID_SIZE = 1
var player_name = ""

var player_max_hp = 100
var player_current_hp = 100
var player_attack = 25
var player_defense = 15
var player_level = 1
var player_experience = 0
var player_experience_to_next_level = 100

# Player moves/abilities
var player_moves = ["Tackle","Defend", "Heal", "Flee"]

func reset_player_stats():
	player_max_hp = 100
	player_current_hp = 100
	player_attack = 25
	player_defense = 15
	player_level = 1
	player_experience = 0
	player_experience_to_next_level = 100
	player_moves = ["Tackle","Defend", "Heal", "Flee"]
