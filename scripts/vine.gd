extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Cek apakah gate udah unlock
	if GameData.gate_unlocked:
		# Vine fade out
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
		
		# Disable collision langsung supaya player bisa lewat
		collision.set_deferred("disabled", true)
