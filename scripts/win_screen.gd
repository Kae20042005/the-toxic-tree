extends CanvasLayer

@onready var dim_overlay = %DimOverlay
@onready var vbox = %VBoxContainer
@onready var win_label = %WinLabel
@onready var menu_btn = %MainMenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Mulai transparan untuk fade in
	dim_overlay.modulate.a = 0
	vbox.modulate.a = 0
	win_label.scale = Vector2(0.5, 0.5)
	
	# Connect button
	menu_btn.pressed.connect(_on_main_menu)
	
	# Fade in dim overlay
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 1.0, 1.0)
	tween.tween_property(vbox, "modulate:a", 1.0, 1.5).set_delay(0.5)
	
	# Animasi label "YOU WIN" dramatic (scale up dengan bounce)
	tween.tween_property(win_label, "scale", Vector2(1, 1), 0.8) \
		.set_delay(0.8) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	
	# Pause game setelah fade in dimulai
	await get_tree().create_timer(0.3).timeout
	get_tree().paused = true

func _on_main_menu():
	get_tree().paused = false
	
	# Reset GameData biar game baru fresh
	GameData.player_health_initialized = false
	GameData.soul_drain_active = false
	GameData.dead_enemies.clear()
	GameData.venus_kill_count = 0
	GameData.gate_unlocked = false
	GameData.has_spawn_position = false
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
