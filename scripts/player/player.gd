class_name Player
extends CharacterBody2D
## Platformer controller + generic "actor" for abilities. Movement, jump feel,
## and body control live here; skill logic lives in the ability files, which
## drive the player through this actor API (spawn positions, team, motion
## effects, teleport, history). Combat stats & abilities come from a Hero.

@export var hero: Hero ## assign in inspector or via GameManager/RunManager
@export var team: int = 0 ## GameManager.TEAM_PLAYER
@export var respawn_delay: float = 2.5 ## seconds down before respawning

# --- Tunables (fallbacks; overridden by hero stats in _apply_hero) ---
@export_group("Feel")
@export var ground_accel: float = 2600.0
@export var ground_friction: float = 3200.0
@export var air_accel: float = 1800.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10
@export var jump_cut_multiplier: float = 0.45 ## velocity kept on early release
@export var max_fall_speed: float = 1200.0

const HITBOX_LAYER := 1 << 3 # player_hitbox
const MUZZLE_OFFSET := Vector2(0, -16) # center of the top half

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 1600.0)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var abilities: AbilityController = $AbilityController
@onready var input: PlayerInput = $PlayerInput

# Runtime stats (populated from hero)
var move_speed: float
var jump_velocity: float
var air_control: float
var max_air_jumps: int

# State
var _facing: float = 1.0
var _air_jumps_left: int = 0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _active_effect: AbilityEffect = null ## current motion effect (dash, slam, ...)
var _home: Vector2 ## respawn position (initial spawn)
var _corpse: RigidBody2D = null

# Recall history (position/health snapshots) — a generic actor service.
const RECALL_INTERVAL := 0.05
const RECALL_MAX_SECONDS := 5.0
var _recall_samples: Array[Dictionary] = []
var _recall_accum: float = 0.0

func _ready() -> void:
	add_to_group(&"player")
	if health:
		health.died.connect(_on_died)
		health.health_changed.connect(func(c, m): EventBus.player_health_changed.emit(c, m))
	_resolve_hero.call_deferred()

func _resolve_hero() -> void:
	if hero == null and RunManager.active and RunManager.hero_id != &"":
		hero = load("res://resources/heroes/%s.tres" % RunManager.hero_id) as Hero
	if hero == null:
		hero = load("res://resources/heroes/striker.tres") as Hero
	_home = global_position
	_apply_hero()
	EventBus.player_spawned.emit(self)

## Hot-swap this player's hero to the next in the roster's cycle (no reload).
func cycle_hero() -> void:
	var list := Players.HERO_CYCLE
	if list.is_empty():
		return
	var cur: StringName = hero.id if hero else &""
	swap_to(list[(list.find(cur) + 1) % list.size()])

## Hot-swap this player to a specific hero (no reload).
func swap_to(hero_id: StringName) -> void:
	var new_hero := load("res://resources/heroes/%s.tres" % hero_id) as Hero
	if new_hero == null:
		return
	_active_effect = null
	hero = new_hero
	_apply_hero()
	var pidx := int(get_meta(&"player_index", -1))
	if pidx >= 0:
		Players.set_hero(pidx, hero_id)
	EventBus.player_spawned.emit(self) # HUD/banner rebind to the new kit

func _apply_hero() -> void:
	if hero == null:
		move_speed = 320.0
		jump_velocity = 620.0
		air_control = 0.85
		max_air_jumps = 1
		return
	move_speed = hero.move_speed
	jump_velocity = hero.jump_velocity
	air_control = hero.air_control
	max_air_jumps = hero.max_air_jumps
	if health:
		health.max_health = hero.max_health
		health.current_health = hero.max_health
		health.health_changed.emit(health.current_health, health.max_health)
	if sprite and hero.sprite_frames:
		sprite.sprite_frames = hero.sprite_frames
	if abilities:
		abilities.setup(hero, self)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if input.is_just_pressed(&"switch_character"):
		cycle_hero()

	var effect_done := false
	if _active_effect:
		effect_done = _active_effect.tick(self, delta)
	else:
		_process_gravity(delta)
		_process_move(delta)
		_process_jump()

	# Knockback decays and adds on top of intentional motion.
	if _knockback.length() > 1.0:
		velocity += _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 2000.0 * delta)

	move_and_slide()
	if _active_effect and effect_done:
		_active_effect.on_end(self)
		_active_effect = null
	_record_recall_sample(delta)
	_update_animation()

func _record_recall_sample(delta: float) -> void:
	_recall_accum += delta
	if _recall_accum < RECALL_INTERVAL:
		return
	_recall_accum = 0.0
	_recall_samples.append({
		"pos": global_position,
		"hp": health.current_health if health else 0.0,
	})
	var max_samples := int(RECALL_MAX_SECONDS / RECALL_INTERVAL)
	while _recall_samples.size() > max_samples:
		_recall_samples.pop_front()

func _tick_timers(delta: float) -> void:
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_jumps_left = max_air_jumps
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if input.is_just_pressed(&"jump"):
		_jump_buffer_timer = jump_buffer_time

func _process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)
	# Variable jump height: cut upward velocity on early release.
	if input.is_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func _process_move(delta: float) -> void:
	var dir := input.get_move().x
	if dir != 0.0:
		_facing = signf(dir)
		var accel := ground_accel if is_on_floor() else air_accel * air_control
		velocity.x = move_toward(velocity.x, dir * move_speed, accel * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)

func _process_jump() -> void:
	if _jump_buffer_timer <= 0.0:
		return
	if _coyote_timer > 0.0:
		_do_jump()
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		_do_jump()

func _do_jump() -> void:
	velocity.y = -jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0

# --- Actor API (used by abilities/effects) ---
func get_facing() -> float:
	return _facing

func set_facing(dir_x: float) -> void:
	if dir_x != 0.0:
		_facing = signf(dir_x)

func get_team() -> int:
	return team

func get_hitbox_layer() -> int:
	return HITBOX_LAYER

func get_world() -> Node:
	return get_parent() if get_parent() else self

func get_center_position() -> Vector2:
	return global_position

func get_muzzle_position() -> Vector2:
	return global_position + MUZZLE_OFFSET

func get_move_input() -> Vector2:
	return input.get_move()

func get_health() -> HealthComponent:
	return health

func teleport(pos: Vector2) -> void:
	global_position = pos

func apply_knockback(impulse: Vector2) -> void:
	_knockback += impulse

## Run a motion effect (dash, slam, ...) — ticked each physics frame until done.
func play_motion_effect(effect: AbilityEffect) -> void:
	if _active_effect:
		_active_effect.on_end(self)
	_active_effect = effect
	if _active_effect:
		_active_effect.on_start(self)

## Position/health snapshot from ~`seconds` ago (empty if no history).
func get_history_sample(seconds: float) -> Dictionary:
	if _recall_samples.is_empty():
		return {}
	var steps := int(seconds / RECALL_INTERVAL)
	var idx := maxi(0, _recall_samples.size() - 1 - steps)
	return _recall_samples[idx]

## Aim direction snapped to 8 directions from the stick; facing when neutral.
func get_aim_dir() -> Vector2:
	var aim := input.get_move()
	if aim.length() > 0.4:
		return Vector2.RIGHT.rotated(snappedf(aim.angle(), PI / 4.0))
	return Vector2(_facing, 0.0)

func _update_animation() -> void:
	var marker := get_node_or_null("FacingMarker")
	if marker is Node2D:
		(marker as Node2D).scale.x = _facing
	if sprite == null or sprite.sprite_frames == null:
		return
	sprite.flip_h = _facing < 0.0
	var anim := "idle"
	if _active_effect:
		anim = "dash"
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 10.0:
		anim = "run"
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _on_died() -> void:
	EventBus.entity_died.emit(self)
	# Death fires from a physics collision callback; defer the ragdoll + teardown.
	_die.call_deferred()

func _die() -> void:
	_spawn_ragdoll()
	_disable()
	get_tree().create_timer(respawn_delay).timeout.connect(_respawn)

func _respawn() -> void:
	if not is_instance_valid(self):
		return
	if is_instance_valid(_corpse):
		_corpse.queue_free()
	_corpse = null
	global_position = _home
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	_active_effect = null
	if health:
		health.current_health = health.max_health
		health.health_changed.emit(health.current_health, health.max_health)
	if abilities:
		abilities.setup(hero, self)
		abilities.set_physics_process(true)
	if input:
		input.set_physics_process(true)
	var body_shape := get_node_or_null("CollisionShape2D")
	if body_shape:
		body_shape.set_deferred("disabled", false)
	var hurtbox := get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
	set_physics_process(true)
	set_process(true)
	show()
	EventBus.player_spawned.emit(self)

func _spawn_ragdoll() -> void:
	var host := get_parent()
	if host == null:
		return
	_corpse = Ragdoll.spawn(host, global_position, Vector2(36, 64), Color(0.4, 0.75, 1, 1), velocity + Vector2(_knockback.x, -320.0))

func _disable() -> void:
	if _active_effect:
		_active_effect.on_end(self)
		_active_effect = null
	set_physics_process(false)
	set_process(false)
	if abilities:
		abilities.set_physics_process(false)
	if input:
		input.set_physics_process(false)
	var body_shape := get_node_or_null("CollisionShape2D")
	if body_shape:
		body_shape.set_deferred("disabled", true)
	var hurtbox := get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	hide()
