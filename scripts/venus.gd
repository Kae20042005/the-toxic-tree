extends CharacterBody2D

const SPEED = 70.0
const DETECTION_RANGE = 350.0
const ATTACK_RANGE = 45.0
const ATTACK_DAMAGE = 20
const ATTACK_DELAY = 1.0          # ← frame hit di detik 1.0 (frame 5/5fps)
const ATTACK_ANIM_DURATION = 1.4  # ← total animasi (7 frame / 5 fps)
const ATTACK_COOLDOWN = 1.3
const KNOCKBACK_FORCE = 100.0
const KNOCKBACK_DURATION = 0.2
const MAX_HEALTH = 150
const HEAL_PLAYER_ON_DEATH = 100

enum State { IDLE, CHASE, ATTACK }
var state = State.IDLE
var can_attack = true
var player = null
var enemy_dir = "front"
var is_attacking = false
var is_knocked = false
var is_dead = false
var knockback_velocity = Vector2.ZERO
var health = MAX_HEALTH

@export var enemy_id: String = "" 

@onready var anim = $AnimatedSprite2D
@onready var hitbox_front = $HitboxFront
@onready var hitbox_back = $HitboxBack
@onready var hitbox_left = $HitboxLeft
@onready var hitbox_right = $HitboxRight
@onready var health_bar = $HealthBar

func _ready():
	
	if enemy_id != "" and GameData.is_enemy_dead(enemy_id):
		queue_free()
		return
	
	add_to_group("enemy")
	add_to_group("venus")
	player = get_tree().get_first_node_in_group("player")
	disable_all_hitboxes()
	
	health_bar.max_health = MAX_HEALTH
	health_bar.bar_color = Color.RED
	health_bar.set_health(health)

func _physics_process(delta):
	if is_dead:
		return
	
	if is_knocked:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	
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
		play_anim("idle_" + enemy_dir)
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
	# === FASE 1: Wind up (frame 1-4) ===
	await get_tree().create_timer(ATTACK_DELAY).timeout
	
	if is_dead or player == null:
		can_attack = true
		is_attacking = false
		return
	
	# === FASE 2: Hit aktif (frame 5) ===
	disable_all_hitboxes()
	var active_hitbox: Area2D
	match dir:
		"front": active_hitbox = hitbox_front
		"back":  active_hitbox = hitbox_back
		"left":  active_hitbox = hitbox_left
		"right": active_hitbox = hitbox_right
	
	active_hitbox.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Damage cuma sekali, gak double
	for body in active_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			print("Venus hit player!")
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(ATTACK_DAMAGE, knockback_dir)
	
	# Hitbox aktif sebentar (sekitar 1 frame animasi = 0.2 detik di 5 fps)
	await get_tree().create_timer(0.2).timeout
	disable_all_hitboxes()
	
	# === FASE 3: Recovery (frame 6-7) ===
	# Tunggu animasi selesai sepenuhnya
	var remaining = ATTACK_ANIM_DURATION - ATTACK_DELAY - 0.2
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout
	
	is_attacking = false
	
	# === FASE 4: Cooldown ===
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO):
	if is_dead:
		return
	
	health -= amount
	print("Venus HP: ", health)
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
	
	if player and player.has_method("heal"):
		player.heal(HEAL_PLAYER_ON_DEATH)
	
	# Simpan status mati ke GameData
	if enemy_id != "":
		GameData.mark_enemy_dead(enemy_id)
	
	# Tambah counter venus
	GameData.venus_kill_count += 1
	print("Venus killed: ", GameData.venus_kill_count, "/2")
	
	# Cek apakah cukup buat unlock gate
	if GameData.venus_kill_count >= 2:
		GameData.gate_unlocked = true
		print("🌿 Gate unlocked! 🌿")
	
	print("Venus mati!")
	anim.play("die_" + enemy_dir)
	await anim.animation_finished
	queue_free()
