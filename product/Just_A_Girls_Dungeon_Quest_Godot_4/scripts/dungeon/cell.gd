extends Node3D

@onready var topFace = $Top
@onready var northFace = $North
@onready var eastFace = $East
@onready var southFace = $South
@onready var westFace = $West
@onready var bottomFace = $Bottom

func update_faces(cell_list: Array) -> void:
	var my_grid_position = Vector2i(floor(global_transform.origin.x / Global.GRID_SIZE), floor(global_transform.origin.z / Global.GRID_SIZE))
	
	if cell_list.has(my_grid_position + Vector2i.RIGHT):
		eastFace.visible = false
	if cell_list.has(my_grid_position + Vector2i.LEFT):
		westFace.visible = false
	if cell_list.has(my_grid_position + Vector2i.DOWN):
		southFace.visible = false
	if cell_list.has(my_grid_position + Vector2i.UP):
		northFace.visible = false
