extends CanvasLayer

@onready var dialogue_label = $TextureRect/RichTextLabel
@onready var typing_timer = $TypingTimer
@onready var next_button = $TextureRect/TextureButton
@onready var princess_head = $MainCharacter/head  
@onready var princess_body = $MainCharacter/body
@onready var king = $King 
@onready var mysterious_man = $MysteriousMan  
@onready var tutorial_panel = $TutorialPanel

var princess_expressions = {
	"neutral": preload("res://assets/portraits/princess_outfit_1_head_neutral.png"),
	"happy": preload("res://assets/portraits/princess_outfit_1_head_happy.png"),
	"sad": preload("res://assets/portraits/princess_outfit_1_head_sad.png"),
}

var dialogues = [
	{"character": "Narrator", "text": "Once upon a time, in a kingdom far away...", "expression": "neutral", "speakers": []},
	{"character": "King", "text": "My dear daughter, it's time you found yourself a suitable prince to marry.", "expression": "neutral", "speakers": ["King"]},
	{"character": "[name]", "text": "But father, all these princes are so boring! This one only talks about his wealth, that one just boasts about his horses...", "expression": "sad", "speakers": ["Princess"]},
	{"character": "Narrator", "text": "The princess's eyes wandered across the ballroom, when suddenly...", "expression": "neutral", "speakers": []},
	{"character": "[name]", "text": "Who... who is that?", "expression": "sad", "speakers": ["Princess"]},
	{"character": "Mysterious Man", "text": "I'm just a traveler passing through, your highness.", "expression": "neutral", "speakers": ["MysteriousMan"]},
	{"character": "[name]", "text": "You must stay for dinner! I would love to hear about your adventures.", "expression": "happy", "speakers": ["Princess"]},
	{"character": "Mysterious Man", "text": "I have no interest in someone who's lived their whole life behind castle walls. What would you know of real adventure or danger?", "expression": "neutral", "speakers": ["MysteriousMan"]},
	{"character": "[name]", "text": "I... I could learn!", "expression": "sad", "speakers": ["Princess"]},
	{"character": "Mysterious Man", "text": "Perhaps. But words are cheap, your highness.", "expression": "neutral", "speakers": ["MysteriousMan"]},
	{"character": "[name]", "text": "(to herself) I'll show him. I'll become the greatest adventurer this kingdom has ever known!", "expression": "sad", "speakers": ["Princess"]},
	{"character": "King", "text": "You want to enter the dungeons? Ha! Go ahead, my daughter. Perhaps it will cure you of these ridiculous fantasies.", "expression": "neutral", "speakers": ["King"]},
	{"character": "[name]", "text": "Just you wait! I'll conquer the dungeon and prove everyone wrong!", "expression": "happy", "speakers": ["Princess"]}
]

var current_index = 0
var full_text = ""
var displayed_text = ""
var char_index = 0
var is_typing_complete = false
var current_character = ""
var input_cooldown = false
var changing_scene = false
var waiting_for_tutorial_input = false

const CHARACTER_NAME_COLOR = "#ffcc66"  # Gold for character names
const NARRATOR_COLOR = "#ffffff"        # White for narrator
const KEYWORD_COLOR = "#0000FF"         # Blue for keywords

# Keywords to highlight in dialogue
var keywords = ["dungeons", "quest"]

# Character transition speed
const TRANSITION_SPEED = 0.3

func _ready():
	if tutorial_panel:
		tutorial_panel.modulate = Color(1, 1, 1, 0)  # Start fully transparent
	if mysterious_man:
		mysterious_man.modulate = Color(1, 1, 1, 0)  
		
	update_dialogue()
	
func _input(event):
	if waiting_for_tutorial_input and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		waiting_for_tutorial_input = false
		
		changing_scene = true
		get_tree().change_scene_to_file("res://scenes/castle.tscn")
	elif (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")) and not input_cooldown and not changing_scene:
		
		input_cooldown = true
		
		if not is_typing_complete:
			skip_typing()
		else:
			advance_dialogue()
			
		if not changing_scene:
			await get_tree().create_timer(0.2).timeout
			input_cooldown = false

func advance_dialogue():
	current_index += 1
	if current_index < dialogues.size():
		update_dialogue()
	else:
		show_tutorial()

func _on_texture_button_pressed():
	if not input_cooldown and not changing_scene:
		input_cooldown = true
		
		if not is_typing_complete:
			skip_typing()
		else:
			advance_dialogue()
			
		if not changing_scene:
			var timer = get_tree().create_timer(0.2)
			timer.timeout.connect(func(): input_cooldown = false)

func update_dialogue():
	current_character = dialogues[current_index]["character"].replace("[name]", Global.player_name)
	full_text = dialogues[current_index]["text"].replace("[name]", Global.player_name)
	displayed_text = ""
	char_index = 0
	is_typing_complete = false
	
	update_character_visibility()
	
	var name_color = CHARACTER_NAME_COLOR if current_character != "Narrator" else NARRATOR_COLOR
	dialogue_label.clear()
	dialogue_label.push_color(Color(name_color))
	dialogue_label.add_text(current_character)
	dialogue_label.pop()
	dialogue_label.newline()
	
	typing_timer.start()

func update_character_visibility():
	var expression = dialogues[current_index]["expression"]
	var active_speakers = dialogues[current_index]["speakers"]
	
	# Princess visibility and expression
	var is_princess_speaking = "Princess" in active_speakers
	
	if princess_head and princess_expressions.has(expression):
		princess_head.texture = princess_expressions[expression]
		if is_princess_speaking:
			fade_in(princess_head)
			fade_in(princess_body)
		else:
			gray_out(princess_head)
			gray_out(princess_body)
	
	# King visibility
	var is_king_speaking = "King" in active_speakers
	if king:
		if is_king_speaking:
			fade_in(king)
		else:
			if current_character != "Narrator":
				gray_out(king)
			else:
				king.modulate = Color(0.7, 0.7, 0.7, 1)
	
	# Mysterious Man visibility
	var is_mysterious_man_speaking = "MysteriousMan" in active_speakers
	if mysterious_man:
		if is_mysterious_man_speaking:
			fade_in(mysterious_man)
			
			if king and king.modulate.a > 0.1:
				fade_out(king)
		else:
			fade_out(mysterious_man)

# Helper function to gray out a sprite
func gray_out(sprite):
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5, 1), TRANSITION_SPEED)

# Helper function to fade in a sprite
func fade_in(sprite):
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), TRANSITION_SPEED)

# Helper function to fade out a sprite
func fade_out(sprite):
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), TRANSITION_SPEED)

func skip_typing():
	typing_timer.stop()
	displayed_text = full_text
	_update_displayed_text()
	is_typing_complete = true

func _on_typing_timer_timeout():
	if char_index < full_text.length():
		displayed_text += full_text[char_index]
		_update_displayed_text()
		char_index += 1
	else:
		typing_timer.stop()
		is_typing_complete = true

func _update_displayed_text():
	dialogue_label.clear()
	
	var name_color = CHARACTER_NAME_COLOR if current_character != "Narrator" else NARRATOR_COLOR
	dialogue_label.push_color(Color(name_color))
	dialogue_label.add_text(current_character)
	dialogue_label.pop()
	dialogue_label.newline()
	
	var text_to_display = displayed_text
	if current_character != "Narrator":
		text_to_display = "\"" + text_to_display + "\""

	var final_text = text_to_display
	for keyword in keywords:
		var keyword_regex = RegEx.new()
		keyword_regex.compile("(?i)" + keyword)
		
		var matches = keyword_regex.search_all(final_text)
		if matches.size() > 0:
			for i in range(matches.size() - 1, -1, -1):
				var match_obj = matches[i]
				var start = match_obj.get_start()
				var end = match_obj.get_end()
				var matched_text = match_obj.get_string()
				
				final_text = final_text.substr(0, start) + "[color=" + KEYWORD_COLOR + "]" + matched_text + "[/color]" + final_text.substr(end)
	
	dialogue_label.append_text(final_text)


func show_tutorial():
	if king:
		fade_out(king)
	if mysterious_man:
		fade_out(mysterious_man)
	if princess_head:
		fade_out(princess_head)
	if princess_body:
		fade_out(princess_body)
	
	var dialogue_panel = $TextureRect
	var tween = create_tween()
	tween.tween_property(dialogue_panel, "modulate", Color(1, 1, 1, 0), 0.5)
	
	await tween.finished
	
	tutorial_panel.modulate = Color(1, 1, 1, 0)
	var panel_tween = create_tween()
	panel_tween.tween_property(tutorial_panel, "modulate", Color(1, 1, 1, 1), 0.5)
	
	waiting_for_tutorial_input = true
