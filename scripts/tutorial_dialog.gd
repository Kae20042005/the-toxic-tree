extends CanvasLayer

const DIM_COLOR = Color(0.4, 0.4, 0.4, 1.0)
const ACTIVE_COLOR = Color(1, 1, 1, 1)
const FADE_DURATION = 0.3

@onready var portrait_left = %PortraitLeft
@onready var portrait_right = %PortraitRight
@onready var speaker_label = %SpeakerLabel
@onready var dialog_label = %DialogLabel
@onready var continue_hint = %ContinueHint   # ← tambah ini

var dialog_lines = [
	{"type": "dialog", "speaker": "left", "name": "You", "text": "Where am I? Who are you?"},
	{"type": "dialog", "speaker": "right", "name": "Stranger", "text": "Hello, I'm [b]Drew[/b], just a measly old man who lives in this forgotten village."},
	{"type": "dialog", "speaker": "left", "name": "You", "text": "Hello Drew. I wish I could tell you my name, but I forgot."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Ha! Ha! Ha! I know. The air in this village is toxic — going outside for a while is not good for your health."},
	{"type": "dialog", "speaker": "left", "name": "You", "text": "That's horrible. Is there a way to clear the toxin in the air?"},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Well, it all started when those people opened the cave on the [b]western side[/b] of the village. Turns out there was a toxic tree releasing poison gas to this day. If you can cut the tree down, the air may clear."},
	{"type": "dialog", "speaker": "left", "name": "You", "text": "Okay, maybe I can help you with that."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Ha! Ha! Ha! I knew I could rely on you, youngster. But before you head outside, let me give you some tips."},
	{"type": "wait_movement", "speaker": "right", "name": "Drew", "text": "First, you can move with your [color=#ffd700][b]movement keys[/b][/color]."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Very well. Now to the next step — attacking."},
	{"type": "wait_attack", "speaker": "right", "name": "Drew", "text": "You can attack by [color=#ffd700][b]clicking the left mouse button[/b][/color] toward the direction you want to strike."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Well done! And remember — the toxic air will slowly drain your soul. But fear not."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Every creature you slay will [color=#ffd700][b]restore your health[/b][/color]. Their souls will sustain yours."},
	{"type": "dialog", "speaker": "left", "name": "You", "text": "So I must keep fighting to stay alive..."},
	{"type": "dialog", "speaker": "right", "name": "Drew", "text": "Indeed, youngster. Now listen — the cave is locked behind a magical vine. Defeat the [b]two venus[/b] inside my neighbor's house to break the seal."},
]

var current_index = 0
var current_step_type = ""

var moved_directions = {"up": false, "down": false, "left": false, "right": false}
var attacked_directions = {"front": false, "back": false, "left": false, "right": false}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameData.state = GameData.GameState.DIALOG
	show_line(current_index)
	
	# Animasi blinking continue hint
	animate_continue_hint()

func animate_continue_hint():
	# Loop blinking forever
	var tween = create_tween().set_loops()
	tween.tween_property(continue_hint, "modulate:a", 0.3, 0.8)
	tween.tween_property(continue_hint, "modulate:a", 1.0, 0.8)

func _input(event):
	match current_step_type:
		"dialog":
			if event.is_action_pressed("space"):
				next_line()
		"wait_movement":
			check_movement_input()
		"wait_attack":
			check_attack_input(event)

func _process(_delta):
	if current_step_type == "wait_movement":
		check_movement_input()

func check_movement_input():
	if Input.is_action_pressed("move_up"):
		moved_directions["up"] = true
	if Input.is_action_pressed("move_down"):
		moved_directions["down"] = true
	if Input.is_action_pressed("move_left"):
		moved_directions["left"] = true
	if Input.is_action_pressed("move_right"):
		moved_directions["right"] = true
	
	if moved_directions["up"] and moved_directions["down"] and \
	   moved_directions["left"] and moved_directions["right"]:
		next_line()

func check_attack_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var attack_dir = get_attack_direction()
			attacked_directions[attack_dir] = true
			
			if attacked_directions["front"] and attacked_directions["back"] and \
			   attacked_directions["left"] and attacked_directions["right"]:
				next_line()

func get_attack_direction() -> String:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return "front"
	
	var mouse_pos = player.get_global_mouse_position()
	var diff = mouse_pos - player.global_position
	var angle = rad_to_deg(diff.angle())
	
	if angle >= -45 and angle < 45:
		return "right"
	elif angle >= 45 and angle < 135:
		return "front"
	elif angle >= 135 or angle < -135:
		return "left"
	else:
		return "back"

func show_line(index: int):
	if index >= dialog_lines.size():
		end_dialog()
		return
	
	var line = dialog_lines[index]
	var speaker = line["speaker"]
	current_step_type = line["type"]
	
	speaker_label.text = line["name"]
	dialog_label.text = line["text"]
	
	# Show/hide continue hint berdasarkan tipe step
	match current_step_type:
		"dialog":
			continue_hint.text = "Press [Space] to continue"
			continue_hint.visible = true
			GameData.state = GameData.GameState.DIALOG
		"wait_movement":
			continue_hint.text = "Try moving with W A S D"
			continue_hint.visible = true
			GameData.state = GameData.GameState.PLAYING
		"wait_attack":
			continue_hint.text = "Try attacking in all directions"
			continue_hint.visible = true
			GameData.state = GameData.GameState.PLAYING
	
	if speaker == "left":
		highlight_left()
	elif speaker == "right":
		highlight_right()

func highlight_left():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(portrait_left, "modulate", ACTIVE_COLOR, FADE_DURATION)
	tween.tween_property(portrait_right, "modulate", DIM_COLOR, FADE_DURATION)

func highlight_right():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(portrait_left, "modulate", DIM_COLOR, FADE_DURATION)
	tween.tween_property(portrait_right, "modulate", ACTIVE_COLOR, FADE_DURATION)

func next_line():
	current_index += 1
	show_line(current_index)

func end_dialog():
	GameData.state = GameData.GameState.PLAYING
	queue_free()
