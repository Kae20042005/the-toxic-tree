extends Area2D

@export var heal_amount: int = 25
@export var float_amplitude: float = 5.0    # seberapa naik-turun
@export var float_speed: float = 2.0         # seberapa cepat

@onready var sprite = $Sprite2D
@onready var heal_audio = $AudioStreamPlayer2D

var base_y: float
var time_passed: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	base_y = sprite.position.y

func _process(delta):
	time_passed += delta
	sprite.position.y = base_y + sin(time_passed * float_speed) * float_amplitude
	sprite.rotation += delta * 0.5

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
			
			play_pickup_effect()

func play_pickup_effect():
	monitoring = false
	
	heal_audio.play()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await tween.finished
		
	queue_free()
