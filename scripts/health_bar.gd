extends Node2D

@export var max_health: int = 100
@export var bar_color: Color = Color.GREEN

@onready var bar_bg = $BarBg
@onready var bar_damage = $BarDamage
@onready var bar_health = $BarHealth

var current_health: int
var max_width: float = 40.0

func _ready():
	current_health = max_health
	bar_health.color = bar_color
	update_bar_instant()

func set_health(new_health: int):
	new_health = clamp(new_health, 0, max_health)
	current_health = new_health
	
	# Bar hijau/merah langsung berubah
	var target_width = max_width * (float(current_health) / max_health)
	bar_health.size.x = target_width
	
	# Bar kuning menyusul perlahan (efek delay damage)
	var tween = create_tween()
	tween.tween_interval(0.3)  # delay 0.3 detik dulu
	tween.tween_property(bar_damage, "size:x", target_width, 0.4)

func update_bar_instant():
	var w = max_width * (float(current_health) / max_health)
	bar_health.size.x = w
	bar_damage.size.x = w
