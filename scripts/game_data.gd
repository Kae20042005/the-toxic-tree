extends Node

# Status tutor awal
var tutor: bool = true

# Spawn position
var spawn_marker_name: String = ""
var has_spawn_position: bool = false

# Player state
var player_health: int = 100
var player_health_initialized: bool = false
var soul_drain_active: bool = false

# Persistent enemy state
var dead_enemies: Array[String] = []   # list ID enemy yang udah mati

# Gate progression
var venus_kill_count: int = 0
var gate_unlocked: bool = false

func is_enemy_dead(enemy_id: String) -> bool:
	return enemy_id in dead_enemies

func mark_enemy_dead(enemy_id: String):
	if not enemy_id in dead_enemies:
		dead_enemies.append(enemy_id)
		
enum GameState {
	PLAYING,
	DIALOG,
	PAUSED,
	CUTSCENE,
	DEATH_SCREEN,
	MENU
}

var state: GameState = GameState.PLAYING

func can_player_move() -> bool:
	return state == GameState.PLAYING

func can_player_attack() -> bool:
	return state == GameState.PLAYING
