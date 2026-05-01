extends Node2D  # script di TutorialLevel atau cutscene scene

@onready var anim_player = $AnimationPlayer
@onready var player = $Player

func _ready():
	player.play()
	await get_tree().process_frame
	anim_player.play("intro_walk")
	await anim_player.animation_finished
	show_win_screen()

func show_win_screen():
	var win_screen = preload("res://scenes/WinScreen.tscn").instantiate()
	add_child(win_screen)
