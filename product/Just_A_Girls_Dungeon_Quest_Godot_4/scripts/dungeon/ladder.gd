extends Node3D

@onready var sprite_3d = $Sprite3D
var is_player_on_ladder = false
var pulse_tween = null

func _ready():
	add_to_group("ladders")
	
	if sprite_3d:
		sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
		sprite_3d.position.y = 0.5

func _process(_delta):
	var player = get_node("/root/Dungeon/Player")
	if player:
		var player_cell = Vector2i(
			floor(player.global_transform.origin.x / 1.0), 
			floor(player.global_transform.origin.z / 1.0)
		)
		
		var ladder_cell = Vector2i(
			floor(global_transform.origin.x / 1.0),
			floor(global_transform.origin.z / 1.0)
		)
		
		var player_on_ladder = player_cell == ladder_cell
		
		if player_on_ladder and not is_player_on_ladder:
			start_highlight_effect()
			is_player_on_ladder = true
		
		elif not player_on_ladder and is_player_on_ladder:
			stop_highlight_effect()
			is_player_on_ladder = false

func start_highlight_effect():
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween().set_loops()
	var start_scale = sprite_3d.scale
	
	# Pulse effect
	pulse_tween.tween_property(sprite_3d, "scale", start_scale * 1.2, 0.5)
	pulse_tween.tween_property(sprite_3d, "scale", start_scale, 0.5)
	
	if sprite_3d.material_override:
		sprite_3d.material_override.albedo_color = Color(1.5, 1.5, 1.5)  # Bright white highlight

func stop_highlight_effect():
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	
	sprite_3d.scale = Vector3(1, 1, 1)
	
	if sprite_3d.material_override:
		sprite_3d.material_override.albedo_color = Color(1, 1, 1)  
