extends CharacterBody2D

const SPEED = 200.0
const ATTACK_DAMAGE = 15
const KNOCKBACK_FORCE = 250.0
const KNOCKBACK_DURATION = 0.2

# Soul drain settings
const DRAIN_INTERVAL = 1
const DRAIN_AMOUNT = 2
const REGEN_PER_KILL = 20
const MAX_HEALTH = 100

var char_dir = "front"
var is_attacking = false
var is_knocked = false
var is_dead = false
var knockback_velocity = Vector2.ZERO
var health = MAX_HEALTH
var soul_drain_active: bool = false

@onready var anim = $AnimatedSprite2D
@onready var hitbox_front = $HitboxFront
@onready var hitbox_back = $HitboxBack
@onready var hitbox_left = $HitboxLeft
@onready var hitbox_right = $HitboxRight
@onready var health_bar = $HealthBar

var drain_timer: Timer

func _ready():
	add_to_group("player")
	disable_all_hitboxes()
	
	# Load state dari GameData (kalau pernah ada)
	if GameData.player_health_initialized:
		health = GameData.player_health
		soul_drain_active = GameData.soul_drain_active
	else:
		# First spawn — init default
		health = MAX_HEALTH
		GameData.player_health = MAX_HEALTH
		GameData.player_health_initialized = true
	
	health_bar.max_health = MAX_HEALTH
	health_bar.bar_color = Color.GREEN
	health_bar.set_health(health)
	
	# Setup drain timer
	drain_timer = Timer.new()
	drain_timer.wait_time = DRAIN_INTERVAL
	drain_timer.timeout.connect(_on_drain_tick)
	add_child(drain_timer)
	drain_timer.start()
	
	# Tunggu scene siap, lalu spawn di posisi marker
	await get_tree().process_frame
	
	if GameData.has_spawn_position:
		var marker = get_tree().current_scene.find_child(GameData.spawn_marker_name, true, false)
		if marker:
			global_position = marker.global_position
		GameData.has_spawn_position = false

func _physics_process(delta):
	if not GameData.can_player_move():
		velocity = Vector2.ZERO
		move_and_slide()
		return	
	
	if is_dead:
		return
	
	if is_knocked:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return
	
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
		if direction.y > 0:
			char_dir = "front"
		elif direction.y < 0:
			char_dir = "back"
		elif direction.x > 0:
			char_dir = "right"
		elif direction.x < 0:
			char_dir = "left"
		play_anim("walk_" + char_dir)
	else:
		velocity = Vector2.ZERO
		play_anim("idle_" + char_dir)

	move_and_slide()

func _input(event):
	if is_dead:
		return
		
	if GameData.state != GameData.GameState.PLAYING:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_attacking and not is_knocked:
				var attack_dir = get_attack_direction()
				perform_attack(attack_dir)

func get_attack_direction() -> String:
	var mouse_pos = get_global_mouse_position()
	var diff = mouse_pos - global_position
	var angle = rad_to_deg(diff.angle())
	if angle >= -45 and angle < 45:
		return "right"
	elif angle >= 45 and angle < 135:
		return "front"
	elif angle >= 135 or angle < -135:
		return "left"
	else:
		return "back"

func perform_attack(attack_dir: String):
	is_attacking = true
	char_dir = attack_dir
	play_anim("attack_" + attack_dir)
	
	#await get_tree().create_timer(0.2).timeout
	
	var active_hitbox: Area2D
	match attack_dir:
		"front": active_hitbox = hitbox_front
		"back":  active_hitbox = hitbox_back
		"left":  active_hitbox = hitbox_left
		"right": active_hitbox = hitbox_right
	
	active_hitbox.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	for body in active_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			print("Player hit: ", body.name)
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(ATTACK_DAMAGE, knockback_dir)
	
	active_hitbox.monitoring = false
	
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO):
	if is_dead:
		return
	
	health -= amount
	GameData.player_health = health   # ← simpan
	print("Player HP: ", health)
	
	health_bar.set_health(health)
	
	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)
	
	flash_red()
	
	if health <= 0:
		die()

# === SOUL DRAIN SYSTEM ===

func _on_drain_tick():
	if is_dead:
		return
	if not soul_drain_active:
		return
	
	health -= DRAIN_AMOUNT
	GameData.player_health = health   # ← simpan
	print("Soul drained. HP: ", health)
	health_bar.set_health(health)
	
	if health <= 0:
		die()

func heal(amount: int):
	if is_dead:
		return
	
	health += amount
	health = min(health, MAX_HEALTH)
	GameData.player_health = health   # ← simpan
	print("Healed. HP: ", health)
	health_bar.set_health(health)

func start_soul_drain():
	soul_drain_active = true
	GameData.soul_drain_active = true   # ← simpan
	print("Soul drain started!")

func stop_soul_drain():
	soul_drain_active = false
	GameData.soul_drain_active = false   # ← simpan
	print("Soul drain stopped!")

# === END SOUL DRAIN ===

func apply_knockback(direction: Vector2):
	is_knocked = true
	knockback_velocity = direction.normalized() * KNOCKBACK_FORCE
	await get_tree().create_timer(KNOCKBACK_DURATION).timeout
	is_knocked = false

func flash_red():
	anim.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color.WHITE

func play_anim(anim_name: String):
	if anim.animation != anim_name or not anim.is_playing():
		anim.play(anim_name)
		await anim.animation_finished

func disable_all_hitboxes():
	hitbox_front.monitoring = false
	hitbox_back.monitoring = false
	hitbox_left.monitoring = false
	hitbox_right.monitoring = false

func die():
	is_dead = true
	velocity = Vector2.ZERO
	
	if drain_timer:
		drain_timer.stop()
	
	disable_all_hitboxes()
	$CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false
	
	# Stop kamera follow biar diem di mayat player
	var camera = get_tree().current_scene.find_child("Camera2D", true, false)
	if camera and camera.has_method("lock_camera"):
		camera.lock_camera()
	
	# Play animasi mati
	anim.play("die_" + char_dir)
	await anim.animation_finished
	
	print("Player mati!")
	
	# Show death screen (jangan queue_free!)
	show_death_screen()

func show_death_screen():
	var death_screen = preload("res://scenes/DeathScreen.tscn").instantiate()
	get_tree().current_scene.add_child(death_screen)
