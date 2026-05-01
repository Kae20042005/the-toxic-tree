extends CanvasLayer

@onready var dark_overlay = $Control/DarkOverlay
@onready var vbox = $Control/VBoxContainer
@onready var respawn_btn = $Control/VBoxContainer/RespawnButton
@onready var menu_btn = $Control/VBoxContainer/MainMenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # tetap aktif saat pause
	
	# Mulai transparan untuk fade in
	dark_overlay.modulate.a = 0
	vbox.modulate.a = 0
	
	# Connect button
	respawn_btn.pressed.connect(_on_respawn)
	menu_btn.pressed.connect(_on_main_menu)
	
	# Fade in smooth
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dark_overlay, "modulate:a", 1.0, 0.8)
	tween.tween_property(vbox, "modulate:a", 1.0, 1.2).set_delay(0.4)
	
	# Pause game setelah fade in mulai
	await get_tree().create_timer(0.3).timeout
	get_tree().paused = true

func _on_respawn():
	get_tree().paused = false
	
	# Reset GameData
	GameData.player_health_initialized = false
	GameData.soul_drain_active = true
	GameData.dead_enemies.clear()
	GameData.venus_kill_count = 0
	GameData.gate_unlocked = false
	GameData.has_spawn_position = false
	
	get_tree().change_scene_to_file("res://scenes/MainLevel.tscn")

func _on_main_menu():
	get_tree().paused = false
	
	# Reset GameData
	GameData.player_health_initialized = false
	GameData.soul_drain_active = false
	GameData.dead_enemies.clear()
	GameData.venus_kill_count = 0
	GameData.gate_unlocked = false
	GameData.has_spawn_position = false
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
