extends CharacterBody2D

const SPEED = 80.0
const DETECTION_RANGE = 400.0
const ATTACK_RANGE = 40.0
const ATTACK_DAMAGE = 10
const ATTACK_DELAY = 0.5
const ATTACK_COOLDOWN = 1.5
const KNOCKBACK_FORCE = 200.0
const KNOCKBACK_DURATION = 0.2
const MAX_HEALTH = 50

enum State { IDLE, CHASE, ATTACK }
var state = State.IDLE
var can_attack = true
var player = null
var enemy_dir = "front"
var is_attacking = false
var is_knocked = false
var knockback_velocity = Vector2.ZERO
var health = MAX_HEALTH
var is_dead = false

@onready var anim = $AnimatedSprite2D
@onready var hitbox_front = $HitboxFront
@onready var hitbox_back = $HitboxBack
@onready var hitbox_left = $HitboxLeft
@onready var hitbox_right = $HitboxRight
@onready var health_bar = $HealthBar

func _ready():
	add_to_group("enemy")   # ← penting biar player bisa deteksi
	player = get_tree().get_first_node_in_group("player")
	disable_all_hitboxes()
	
	hitbox_front.body_entered.connect(_on_hit)
	hitbox_back.body_entered.connect(_on_hit)
	hitbox_left.body_entered.connect(_on_hit)
	hitbox_right.body_entered.connect(_on_hit)
	
	health_bar.max_health = MAX_HEALTH
	health_bar.bar_color = Color.RED
	health_bar.set_health(health)

func _physics_process(delta):
	
	if is_dead:
		return
	# Knockback override
	if is_knocked:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
			
	if Input.is_action_just_pressed("ui_select"):  # Spasi
		print("=== ORC DEBUG ===")
		print("Orc pos: ", global_position)
		print("Orc collision layer: ", collision_layer)
		print("Orc collision mask: ", collision_mask)
		print("CollisionShape2D: ", $CollisionShape2D)
		if $CollisionShape2D:
			print("  disabled: ", $CollisionShape2D.disabled)
			print("  shape: ", $CollisionShape2D.shape)
	
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= ATTACK_RANGE:
		state = State.ATTACK
	elif dist <= DETECTION_RANGE:
		state = State.CHASE
	else:
		state = State.IDLE
	
	match state:
		State.IDLE: do_idle()
		State.CHASE: do_chase()
		State.ATTACK: do_attack()
	
	move_and_slide()

func do_idle():
	velocity = Vector2.ZERO
	play_anim("idle_" + enemy_dir)

func do_chase():
	var dist = global_position.distance_to(player.global_position)
	if dist <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	update_dir(direction)
	play_anim("walk_" + enemy_dir)

func do_attack():
	if not can_attack:
		return
	
	velocity = Vector2.ZERO
	enemy_dir = get_dir_to_player()
	play_anim("attack_" + enemy_dir)
	
	can_attack = false
	is_attacking = true
	perform_attack(enemy_dir)

func update_dir(direction: Vector2):
	if abs(direction.y) >= abs(direction.x):
		enemy_dir = "front" if direction.y > 0 else "back"
	else:
		enemy_dir = "right" if direction.x > 0 else "left"

func get_dir_to_player() -> String:
	var diff = player.global_position - global_position
	var angle = rad_to_deg(diff.angle())
	if angle >= -45 and angle < 45:
		return "right"
	elif angle >= 45 and angle < 135:
		return "front"
	elif angle >= 135 or angle < -135:
		return "left"
	else:
		return "back"

func perform_attack(dir: String):
	await get_tree().create_timer(ATTACK_DELAY).timeout
	
	if player == null:
		can_attack = true
		is_attacking = false
		return
	
	disable_all_hitboxes()
	var active_hitbox: Area2D
	match dir:
		"front": active_hitbox = hitbox_front
		"back":  active_hitbox = hitbox_back
		"left":  active_hitbox = hitbox_left
		"right": active_hitbox = hitbox_right
	
	active_hitbox.monitoring = true
	await get_tree().physics_frame
	
	# Cek manual overlap (lebih reliable dari signal)
	for body in active_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			print("Orc hit player!")
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(ATTACK_DAMAGE, knockback_dir)
	
	await get_tree().create_timer(0.2).timeout
	disable_all_hitboxes()
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func _on_hit(body):
	if body.is_in_group("player"):
		var knockback_dir = (body.global_position - global_position).normalized()
		body.take_damage(ATTACK_DAMAGE, knockback_dir)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO):
	health -= amount
	print("Orc HP: ", health)
	
	health_bar.set_health(health)
	
	if knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir)
	
	flash_red()
	
	if health <= 0:
		die()

func apply_knockback(direction: Vector2):
	is_knocked = true
	knockback_velocity = direction.normalized() * KNOCKBACK_FORCE
	await get_tree().create_timer(KNOCKBACK_DURATION).timeout
	is_knocked = false

func flash_red():
	anim.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color.WHITE

func disable_all_hitboxes():
	hitbox_front.monitoring = false
	hitbox_back.monitoring = false
	hitbox_left.monitoring = false
	hitbox_right.monitoring = false

func play_anim(anim_name: String):
	if anim.animation != anim_name or not anim.is_playing():
		anim.play(anim_name)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	
	disable_all_hitboxes()
	$CollisionShape2D.set_deferred("disabled", true)
	health_bar.visible = false
	
	# Heal player
	if player and player.has_method("heal"):
		player.heal(20)
	
	anim.play("die_" + enemy_dir)
	await anim.animation_finished
	queue_free()
