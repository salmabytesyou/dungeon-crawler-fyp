extends CanvasLayer

signal dialogue_closed

@onready var panel = $DialoguePanel
@onready var text_label = $DialoguePanel/DialogueText
@onready var next_icon = $DialoguePanel/NextIcon
@onready var animation_player = $AnimationPlayer

var next_scene = ""
var can_dismiss = false

func _ready():
	panel.visible = false
	next_icon.visible = false
	
	add_to_group("dialogue_layer")

func show_dialogue(speaker_name, dialogue_text, target_scene = "", auto_dismiss = false):
	# Reset state
	can_dismiss = false
	next_scene = target_scene
	
	for child in get_children():
		if child is Timer:
			child.stop()
			child.queue_free()
	
	text_label.text = speaker_name + "\n\"" + dialogue_text + "\""
	
	panel.visible = true
	if animation_player and animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")
	else:
		panel.modulate = Color(1, 1, 1, 1)
	
	print("Showing dialogue: auto_dismiss=", auto_dismiss)
	
	if auto_dismiss:
		var timer = Timer.new()
		timer.name = "AutoDismissTimer"
		timer.wait_time = 3.0
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			print("Auto-dismiss timer triggered")
			close_dialogue()
		)
		timer.start()
	else:
		var timer = Timer.new()
		timer.name = "DismissReadyTimer"
		timer.wait_time = 1.0
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			print("Setting can_dismiss to true")
			can_dismiss = true
			if next_icon:
				next_icon.visible = true
		)
		timer.start()
		print("Started dismiss ready timer")

func _input(event):
	if event.is_action_pressed("ui_accept") and panel.visible:
		if can_dismiss:
			print("Closing dialogue due to user input")
			close_dialogue()
		else:
			print("Cannot dismiss dialogue yet - waiting for timer")

func close_dialogue():
	
	if not panel.visible:
		return
	
	if animation_player and animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished
	else:
		panel.modulate = Color(1, 1, 1, 0)
	
	panel.visible = false
	if next_icon:
		next_icon.visible = false
	
	emit_signal("dialogue_closed")
	
	if next_scene != "":
		await get_tree().create_timer(0.1).timeout
		get_tree().change_scene_to_file(next_scene)


func _on_next_icon_pressed():
	if can_dismiss:
		print("Closing dialogue due to user input")
		close_dialogue()
	else:
		print("Cannot dismiss dialogue yet - waiting for timer")
