class_name Player
extends CharacterBody2D
## Platformer controller with roguelite/action feel: acceleration-based ground
## movement, air control, coyote time, jump buffering, variable jump height,
## multi-jump, and a dash. Combat stats & abilities come from a Hero resource.

@export var hero: Hero ## assign in inspector or via GameManager/RunManager

# --- Tunables (fallbacks; overridden by hero stats in _apply_hero) ---
@export_group("Feel")
@export var ground_accel: float = 2600.0
@export var ground_friction: float = 3200.0
@export var air_accel: float = 1800.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10
@export var jump_cut_multiplier: float = 0.45 ## velocity kept on early release
@export var max_fall_speed: float = 1200.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 1600.0)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var abilities: AbilityController = $AbilityController
@onready var hitbox_pivot: Node2D = $HitboxPivot

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
var _dashing: bool = false
var _dash_timer: float = 0.0
var _dash_speed: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _knockback: Vector2 = Vector2.ZERO

# Ground slam state.
var _slamming: bool = false
var _slam_speed: float = 0.0
var _slam_start_y: float = 0.0
var _slam_config: Dictionary = {}
var _slam_hitbox: HitboxComponent = null

# Recall history (for abilities like Tracer's Recall).
const RECALL_INTERVAL := 0.05
const RECALL_MAX_SECONDS := 5.0
var _recall_samples: Array[Dictionary] = []
var _recall_accum: float = 0.0

func _ready() -> void:
	add_to_group(&"player")
	if health:
		health.died.connect(_on_died)
		health.health_changed.connect(func(c, m): EventBus.player_health_changed.emit(c, m))
	# Defer: _ready runs bottom-up, so Main._ready (which starts the run and sets
	# RunManager.hero_id) hasn't run yet. Deferred calls flush after every _ready.
	_resolve_hero.call_deferred()

func _resolve_hero() -> void:
	if hero == null and RunManager.active and RunManager.hero_id != &"":
		hero = load("res://resources/heroes/%s.tres" % RunManager.hero_id) as Hero
	if hero == null:
		# Fallback so the level is playable when launched standalone (F6).
		hero = load("res://resources/heroes/striker.tres") as Hero
	_apply_hero()
	EventBus.player_spawned.emit(self)

func _apply_hero() -> void:
	if hero == null:
		# sensible defaults so the scene runs standalone
		move_speed = 320.0; 
		jump_velocity = 620.0; 
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

	if _slamming:
		velocity = Vector2(0.0, _slam_speed)
	elif _dashing:
		_process_dash(delta)
	else:
		_process_gravity(delta)
		_process_move(delta)
		_process_jump()

	# Knockback decays and adds on top of intentional motion.
	if _knockback.length() > 1.0:
		velocity += _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 2000.0 * delta)

	move_and_slide()
	if _slamming and is_on_floor():
		_end_slam()
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

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

func _process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, max_fall_speed)
	# Variable jump height: cut upward velocity on early release.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func _process_move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
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

# --- Dash (driven by a DashAbility in the hero's dash slot) ---
func start_dash(dir: Vector2, speed: float, duration: float) -> void:
	_dashing = true
	_dash_timer = duration
	_dash_speed = speed
	_dash_dir = dir.normalized()
	_facing = signf(_dash_dir.x) if _dash_dir.x != 0.0 else _facing

func _process_dash(delta: float) -> void:
	velocity = _dash_dir * _dash_speed
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dashing = false
		velocity *= 0.4 # bleed momentum on exit

# --- Ground slam (driven by a GroundSlamAbility) ---
func start_slam(config: Dictionary) -> void:
	if _slamming:
		return
	_slamming = true
	_dashing = false
	_slam_config = config
	_slam_speed = config.get("slam_speed", 1400.0)
	_slam_start_y = global_position.y
	# A hitbox that follows the player down, hitting anything it passes through.
	_slam_hitbox = HitboxComponent.new()
	_slam_hitbox.damage = config.get("descent_damage", 12.0)
	_slam_hitbox.source = self
	_slam_hitbox.knockback = 140.0
	_slam_hitbox.grants_ult_charge = config.get("grants_ult_charge", true)
	_slam_hitbox.collision_layer = 1 << 3 # player_hitbox
	_slam_hitbox.collision_mask = 0
	_slam_hitbox.monitoring = false
	_slam_hitbox.monitorable = true
	var radius: float = config.get("descent_radius", 42.0)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	_slam_hitbox.add_child(shape)
	var vis := Polygon2D.new()
	vis.color = Color(0.6, 0.85, 1.0, 0.35)
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * radius)
	vis.polygon = pts
	_slam_hitbox.add_child(vis)
	hitbox_pivot.add_child(_slam_hitbox)

func _end_slam() -> void:
	_slamming = false
	if is_instance_valid(_slam_hitbox):
		_slam_hitbox.queue_free()
	_slam_hitbox = null
	var fall := maxf(0.0, global_position.y - _slam_start_y)
	var dmg: float = minf(
		_slam_config.get("max_damage", 220.0),
		_slam_config.get("base_damage", 20.0) + fall * _slam_config.get("damage_per_height", 0.2),
	)
	spawn_aoe_hitbox(
		dmg,
		_slam_config.get("radius", 140.0),
		_slam_config.get("lifetime", 0.2),
		_slam_config.get("knockback", 380.0),
		_slam_config.get("grants_ult_charge", true),
	)

# --- Combat hooks (called by abilities) ---
func spawn_melee_hitbox(damage: float, offset: Vector2, lifetime: float, knockback: float = 0.0, knockback_dir: Vector2 = Vector2.ZERO, grants_ult_charge: bool = true) -> void:
	var hb := HitboxComponent.new()
	hb.damage = damage
	hb.source = self
	hb.knockback = knockback
	hb.knockback_dir = knockback_dir
	hb.grants_ult_charge = grants_ult_charge
	hb.collision_layer = 1 << 3 # player_hitbox (layer 4)
	hb.collision_mask = 0       # detection driven by enemy hurtbox's mask
	hb.monitoring = false
	hb.monitorable = true
	var size := Vector2(48, 48)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	hb.add_child(shape)
	# Flashing graphic showing the hit area.
	var vis := Polygon2D.new()
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	vis.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	vis.color = Color(1.0, 1.0, 1.0, 0.7)
	hb.add_child(vis)
	hitbox_pivot.add_child(hb)
	hb.position = offset
	# Fade the flash out over its lifetime.
	var tw := hb.create_tween()
	tw.tween_property(vis, "color:a", 0.0, lifetime).from(0.7)
	var t := get_tree().create_timer(lifetime)
	t.timeout.connect(func(): if is_instance_valid(hb): hb.queue_free())

## Circular hitbox centered on the player — knockback pushes outward radially.
func spawn_aoe_hitbox(damage: float, radius: float, lifetime: float, knockback: float = 0.0, grants_ult_charge: bool = true) -> void:
	var hb := HitboxComponent.new()
	hb.damage = damage
	hb.source = self
	hb.knockback = knockback # knockback_dir left zero -> auto radial from center
	hb.grants_ult_charge = grants_ult_charge
	hb.collision_layer = 1 << 3
	hb.collision_mask = 0
	hb.monitoring = false
	hb.monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	hb.add_child(shape)
	# Debug ring so the burst is visible until VFX exist.
	var ring := Polygon2D.new()
	ring.color = Color(0.5, 0.8, 1.0, 0.28)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	ring.polygon = pts
	hb.add_child(ring)
	add_child(hb) # centered on player
	var t := get_tree().create_timer(lifetime)
	t.timeout.connect(func(): if is_instance_valid(hb): hb.queue_free())

## Instantiate a projectile in the level, moving in `dir`.
func spawn_projectile(scene: PackedScene, dir: Vector2, damage: float, speed: float, knockback: float = 0.0, grants_ult_charge: bool = true) -> void:
	if scene == null:
		return
	var proj := scene.instantiate()
	if "grants_ult_charge" in proj:
		proj.grants_ult_charge = grants_ult_charge
	# Add to the level so it lives independently of the player.
	var host: Node = get_parent() if get_parent() else self
	host.add_child(proj)
	if proj is Node2D:
		# Fire from the center of the player's top half, not the full center.
		(proj as Node2D).global_position = hitbox_pivot.global_position + Vector2(0, -16)
	if proj.has_method("setup"):
		proj.setup(dir, speed, damage, knockback, self)

func apply_knockback(impulse: Vector2) -> void:
	_knockback += impulse

## Instant horizontal teleport in the movement (or facing) direction, stopped
## short of walls. Used by Tracer's Blink.
func blink(distance: float) -> void:
	var dx := Input.get_axis("move_left", "move_right")
	var dir_x := signf(dx) if dx != 0.0 else _facing
	_facing = dir_x
	var from := global_position
	var to := from + Vector2(dir_x * distance, 0.0)
	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(from, to, collision_mask, [get_rid()])
	var hit := space.intersect_ray(params)
	if hit:
		global_position = (hit.position as Vector2) - Vector2(dir_x * 20.0, 0.0)
	else:
		global_position = to

## Rewind position and health to `seconds` ago. Used by Tracer's Recall.
func recall(seconds: float) -> void:
	if health and health.is_dead():
		return # no rewinding out of death
	if _recall_samples.is_empty():
		return
	var steps := int(seconds / RECALL_INTERVAL)
	var idx := maxi(0, _recall_samples.size() - 1 - steps)
	var sample := _recall_samples[idx]
	global_position = sample["pos"]
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	if health:
		health.current_health = minf(health.max_health, sample["hp"])
		health.health_changed.emit(health.current_health, health.max_health)

func get_facing() -> float:
	return _facing

## Direction abilities aim in: the held stick direction snapped to 8 directions
## (horizontal, vertical, diagonals), falling back to facing when neutral.
func get_aim_dir() -> Vector2:
	var aim := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	if aim.length() > 0.4:
		return Vector2.RIGHT.rotated(snappedf(aim.angle(), PI / 4.0))
	return Vector2(_facing, 0.0)

func _update_animation() -> void:
	# Placeholder facing marker: mirror across the body origin when facing left.
	var marker := get_node_or_null("FacingMarker")
	if marker is Node2D:
		(marker as Node2D).scale.x = _facing

	if sprite == null or sprite.sprite_frames == null:
		return
	sprite.flip_h = _facing < 0.0
	var anim := "idle"
	if _dashing:
		anim = "dash"
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 10.0:
		anim = "run"
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _on_died() -> void:
	EventBus.entity_died.emit(self)
	# Death is triggered from a physics collision callback; adding a RigidBody2D
	# to the space mid-flush fails, so defer the ragdoll + teardown.
	_die.call_deferred()

func _die() -> void:
	_spawn_ragdoll()
	_disable()
	if RunManager.active:
		RunManager.end_run(false)

## Placeholder death: spawn a physics-driven "corpse" that tumbles and collides
## with the world, carrying the player's last velocity plus a spin.
func _spawn_ragdoll() -> void:
	var host := get_parent()
	if host == null:
		return
	var corpse := Ragdoll.spawn(host, global_position, Vector2(36, 64), Color(0.4, 0.75, 1, 1), velocity + Vector2(_knockback.x, -320.0))
	# Hand the camera to the corpse so the death cam follows the ragdoll
	# (Camera2D ignores parent rotation by default, so it won't spin).
	var cam := get_node_or_null("Camera2D")
	if cam and corpse:
		cam.reparent(corpse, true)

## Turn the controlled player off: hide it, stop input/physics, disable hitboxes.
func _disable() -> void:
	_slamming = false
	if is_instance_valid(_slam_hitbox):
		_slam_hitbox.queue_free()
		_slam_hitbox = null
	set_physics_process(false)
	set_process(false)
	if abilities:
		abilities.set_process(false)
	var body_shape := get_node_or_null("CollisionShape2D")
	if body_shape:
		body_shape.set_deferred("disabled", true)
	var hurtbox := get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	hide()
