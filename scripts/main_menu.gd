extends Node2D

func _ready():
	$CanvasLayer/Control/VBoxContainer/StartButton.pressed.connect(_on_start)
	$CanvasLayer/Control/VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/TutorialLevel.tscn")

func _on_quit():
	get_tree().quit()
