extends Control

@export var map_size = Vector2(200, 200) # Size of the minimap in pixels
@export var cell_size = Vector2(10, 10)    # Size of each cell in the minimap
@export var entity_scale = 0.6           # Scale factor for entities
@export var vision_radius = 2            # How many cells the player can see
@export var wall_thickness = 2.0         # Thickness of wall lines

# Colors for minimap elements
@export var cell_color = Color(0.5, 0.5, 0.5, 1.0)
@export var player_color = Color(1.0, 0.0, 0.0, 1.0)
@export var ladder_color = Color(0.0, 1.0, 0.0, 1.0)
@export var tile_color = Color(1.0, 0.8, 0.0, 1.0)
@export var enemy_color = Color(1.0, 0.3, 0.7, 1.0)
@export var wall_color = Color(0.2, 0.2, 0.2, 1.0)
@export var text_color = Color(1.0, 0.3, 0.3, 1.0)

@export var background_texture: Texture2D

var background_texture_rect: NinePatchRect
var drawing_surface: Control

var explored_cells = {} 
var accessible_cells = {} 
var player_cell = Vector2i(0, 0)
var ladder_cell = Vector2i(0, 0)
var enemy_cells = []     
var tile_cells = [] 
var map_offset = Vector2(0, 0)  # Offset to center the map
var current_floor = 0

var font

func _ready():
	custom_minimum_size = Vector2(map_size.x +20, map_size.y + 20)  # Extra height for text
	
	background_texture_rect = $MinimapBackground
	if not background_texture_rect:
		background_texture_rect = NinePatchRect.new()
		background_texture_rect.name = "MinimapBackground"
		add_child(background_texture_rect)
	
	background_texture_rect.size = map_size
	
	if background_texture:
		background_texture_rect.texture = background_texture
	
	drawing_surface = Control.new()
	drawing_surface.name = "DrawingSurface"
	drawing_surface.size = map_size
	add_child(drawing_surface)
	
	drawing_surface.connect("draw", _draw_minimap)
	
	font = ThemeDB.fallback_font

func _draw():
	drawing_surface.queue_redraw()

func _draw_minimap():
	var player_cell_vec2 = Vector2(player_cell.x, player_cell.y)
	map_offset = map_size / 2 - player_cell_vec2 * cell_size
	
	for cell in explored_cells.keys():
			var cell_vec2 = Vector2(cell.x, cell.y)
			var pos = cell_vec2 * cell_size + map_offset
			drawing_surface.draw_rect(Rect2(pos, cell_size), cell_color)
	
	for cell in explored_cells.keys():
		if explored_cells[cell]:
			var cell_vec2 = Vector2(cell.x, cell.y)
			var pos = cell_vec2 * cell_size + map_offset
			_draw_walls_for_cell(cell, pos)
	
	if explored_cells.get(ladder_cell, false):
		var ladder_cell_vec2 = Vector2(ladder_cell.x, ladder_cell.y)
		var ladder_pos = ladder_cell_vec2 * cell_size + map_offset
		_draw_entity(ladder_pos, ladder_color)
	
	for tile_cell in tile_cells:
		if explored_cells.get(tile_cell, false):
			var tile_cell_vec2 = Vector2(tile_cell.x, tile_cell.y)
			var pos = tile_cell_vec2 * cell_size + map_offset
			_draw_entity(pos, tile_color)
	
	for enemy_cell in enemy_cells:
		if explored_cells.get(enemy_cell, false) and is_cell_visible(enemy_cell):
			var enemy_cell_vec2 = Vector2(enemy_cell.x, enemy_cell.y)
			var pos = enemy_cell_vec2 * cell_size + map_offset
			_draw_entity(pos, enemy_color)
	
	var player_pos = player_cell_vec2 * cell_size + map_offset
	_draw_entity(player_pos, player_color)
	
	var floor_text = "Ground Floor" if current_floor == 0 else "Floor B" + str(current_floor)
	var font_size = 14
	var text_width = font.get_string_size(floor_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	
	var text_pos = Vector2((map_size.x / 2 - text_width / 2) + 10, map_size.y + 15)
	drawing_surface.draw_string(font, text_pos, floor_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func _draw_entity(pos, color):
	var margin = cell_size * (1.0 - entity_scale) / 2.0
	var entity_size = cell_size * entity_scale
	var entity_pos = pos + margin
	
	drawing_surface.draw_rect(Rect2(entity_pos, entity_size), color)

func _draw_walls_for_cell(cell, pos):
	if not accessible_cells.has(cell) or not explored_cells.get(cell, false):
		return
		
	# Top wall (North)
	var north_cell = cell + Vector2i(0, -1)
	if not accessible_cells.has(north_cell):
		drawing_surface.draw_line(pos, pos + Vector2(cell_size.x, 0), wall_color, wall_thickness)
	
	# Right wall (East)
	var east_cell = cell + Vector2i(1, 0)
	if not accessible_cells.has(east_cell):
		drawing_surface.draw_line(pos + Vector2(cell_size.x, 0), pos + cell_size, wall_color, wall_thickness)
	
	# Bottom wall (South)
	var south_cell = cell + Vector2i(0, 1)
	if not accessible_cells.has(south_cell):
		drawing_surface.draw_line(pos + Vector2(0, cell_size.y), pos + cell_size, wall_color, wall_thickness)
	
	# Left wall (West)
	var west_cell = cell + Vector2i(-1, 0)
	if not accessible_cells.has(west_cell):
		drawing_surface.draw_line(pos, pos + Vector2(0, cell_size.y), wall_color, wall_thickness)

# Check if a cell is currently visible to the player
func is_cell_visible(cell):
	var distance = abs(cell.x - player_cell.x) + abs(cell.y - player_cell.y)
	return distance <= vision_radius

func update_map(p_cell, explored, accessible, l_cell, enemies, tiles=[], floor_num=0):
	player_cell = p_cell
	explored_cells = explored
	accessible_cells = accessible
	ladder_cell = l_cell
	enemy_cells = enemies
	tile_cells = tiles
	
	if typeof(floor_num) == TYPE_INT:
		current_floor = floor_num
	
	queue_redraw()
