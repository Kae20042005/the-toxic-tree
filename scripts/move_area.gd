extends Area2D

@export_file("*.tscn") var next_scene: String
@export var spawn_marker_name: String = "SpawnFromTutor"
@export var stop_drain_on_enter: bool = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		if stop_drain_on_enter and body.has_method("stop_soul_drain"):
			body.stop_soul_drain()
		elif not stop_drain_on_enter and body.has_method("start_soul_drain"):
			body.start_soul_drain()
		
		GameData.spawn_marker_name = spawn_marker_name
		GameData.has_spawn_position = true
		
		get_tree().call_deferred("change_scene_to_file", next_scene)
