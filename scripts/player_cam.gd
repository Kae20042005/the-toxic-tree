extends Camera2D

var target: Node2D = null
var locked: bool = false

func _ready():
	# Pakai built-in smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	
	target = get_tree().get_first_node_in_group("player")
	
	# Snap langsung ke player + reset smoothing
	if target:
		# Tunggu 1 frame supaya posisi player udah pasti benar
		await get_tree().process_frame
		global_position = target.global_position
		reset_smoothing()   # ← penting! bypass smoothing sekali

func _physics_process(delta):
	if locked:
		return
	
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		return
	
	global_position = target.global_position

func lock_camera():
	locked = true
