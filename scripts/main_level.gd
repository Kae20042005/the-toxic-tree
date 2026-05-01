extends Node2D

func _ready():
	var cam = get_tree().get_first_node_in_group("camera")
	if cam:
		# Reset jadi unlimited
		cam.limit_left = -1280
		cam.limit_top = -160
		cam.limit_right = 2080
		cam.limit_bottom = 1520
