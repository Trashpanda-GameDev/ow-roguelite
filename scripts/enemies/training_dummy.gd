class_name TrainingDummy
extends CharacterBody2D
## Minimal target for verifying combat. Falls with gravity, collides with the
## world so knockback launches it realistically, then respawns after dying.

@onready var health: HealthComponent = $HealthComponent
@onready var visual: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var hurtbox: HurtboxComponent = $HurtboxComponent

const GROUND_FRICTION := 900.0 ## horizontal decel once grounded

@export var respawn_delay: float = 2.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 1600.0)
var _spawn_pos: Vector2
var _dead: bool = false
var _corpse: RigidBody2D = null

func _ready() -> void:
	_spawn_pos = position
	health.damaged.connect(_on_damaged)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	_on_health_changed(health.current_health, health.max_health)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
	else:
		velocity.y += _gravity * delta
	move_and_slide()

## Take a velocity impulse; gravity and collision handle the rest.
func apply_knockback(impulse: Vector2) -> void:
	if _dead:
		return
	velocity += impulse

func _on_damaged(_amount: float, _source: Node) -> void:
	visual.modulate = Color.RED
	create_tween().tween_property(visual, "modulate", Color.WHITE, 0.15)

func _on_health_changed(current: float, maximum: float) -> void:
	label.text = "%d / %d" % [current, maximum]

func _on_died() -> void:
	_dead = true
	velocity = Vector2.ZERO
	visible = false
	hurtbox.set_deferred("monitoring", false) # can't be hit while dead
	# Death fires from a physics callback; defer the ragdoll spawn.
	_spawn_corpse.call_deferred()
	get_tree().create_timer(respawn_delay).timeout.connect(_respawn)

## Physics corpse that tumbles and stays put until the dummy respawns.
func _spawn_corpse() -> void:
	# ColorRect spans 48 wide x 96 tall with origin at the base; center it.
	var launch := Vector2(randf_range(-140.0, 140.0), -300.0)
	_corpse = Ragdoll.spawn(get_parent(), global_position + Vector2(0, -48), Vector2(48, 96), visual.color, launch)

func _respawn() -> void:
	if not is_instance_valid(self):
		return
	if is_instance_valid(_corpse):
		_corpse.queue_free()
	_corpse = null
	position = _spawn_pos
	velocity = Vector2.ZERO
	health.current_health = health.max_health
	health.health_changed.emit(health.current_health, health.max_health)
	visual.modulate = Color.WHITE
	visible = true
	hurtbox.set_deferred("monitoring", true)
	_dead = false
