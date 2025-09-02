extends Node3D

signal tile_activated(tile_type)

@onready var sprite_3d = $Sprite3D
@export var tile_type = "unknown"  # "damage", "heal", "teleport", etc.

var is_activated = false
var current_cell = Vector2i()

func _ready():
	add_to_group("tiles")

func set_cell(cell: Vector2i):
	current_cell = cell
	global_transform.origin = Vector3(cell.x, 0.05, cell.y)
	
func check_player_collision(player_cell: Vector2i) -> bool:
	if is_activated:
		return false
		
	if player_cell == current_cell:
		activate()
		return true
		
	return false
	
func activate():
	if is_activated:
		return
		
	is_activated = true
	print("Tile activated: " + tile_type + " at cell: ", current_cell)
	
	# Emit signal for the dungeon to handle the tile effect
	emit_signal("tile_activated", tile_type)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)
