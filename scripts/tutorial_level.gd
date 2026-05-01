extends Node2D

@onready var exit_door = $ExitDoor   # sesuaikan nama node Area2D-mu

func _ready():
	# Disable area selama tutorial belum selesai
	if GameData.tutor:
		exit_door.monitoring = false
		
		# Spawn dialog tutorial
		var dialog = preload("res://scenes/TutorialDialog.tscn").instantiate()
		add_child(dialog)
		
		# Tunggu dialog selesai (queue_free)
		await dialog.tree_exited
		
		# Tutorial selesai → enable area
		GameData.tutor = false
		exit_door.monitoring = true
	else:
		# Tutorial sudah pernah complete, langsung enable
		exit_door.monitoring = true
