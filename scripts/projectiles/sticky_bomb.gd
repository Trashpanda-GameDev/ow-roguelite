class_name StickyBomb
extends Projectile
## Lobbed sticky bomb (Tracer's Pulse Bomb). Launches in a slight upward arc,
## falls under gravity, and sticks on contact — to an enemy it hit, or to the
## ground/wall it lands on. Detonates via a fuse timer (reuses `lifetime`),
## spawning the inherited explosion.

@export var launch_up: float = 480.0 ## initial upward speed for the arc
@export var gravity: float = 1400.0

var _stuck: bool = false
var _stuck_to: Node2D = null       ## enemy it clung to (followed if it moves)
var _stick_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Fuse: reuse `lifetime` as the countdown to detonation.
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self): _die())
	hitbox.hit.connect(_on_hit)

func setup(dir: Vector2, speed: float, damage: float, knockback: float, source: Node) -> void:
	# Lob: horizontal throw from the aim direction plus an upward kick.
	velocity = Vector2(dir.x * speed, -launch_up)
	hitbox.damage = damage
	hitbox.knockback = knockback
	hitbox.knockback_dir = dir
	hitbox.source = source
	hitbox.grants_ult_charge = grants_ult_charge
	hitbox.team = team

func _physics_process(delta: float) -> void:
	if _stuck:
		if _stuck_to == null:
			return # stuck to ground/wall — stays put
		if is_instance_valid(_stuck_to):
			global_position = _stuck_to.global_position + _stick_offset
			return
		# The thing we stuck to is gone — drop and resume falling.
		_stuck = false
		_stuck_to = null
		velocity = Vector2.ZERO
	velocity.y += gravity * delta
	var from := global_position
	var to := from + velocity * delta
	# Stick to ground/walls (world layer 1).
	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := space.intersect_ray(params)
	if hit:
		global_position = hit.position
		_stick(null)
	else:
		global_position = to
		rotation = velocity.angle()

func _on_hit(hurtbox: HurtboxComponent) -> void:
	if _stuck:
		return
	_stick(hurtbox.owner as Node2D, hurtbox.health)

func _stick(target: Node2D, hp: HealthComponent = null) -> void:
	_stuck = true
	velocity = Vector2.ZERO
	_stuck_to = target
	if target:
		_stick_offset = global_position - target.global_position
	if hp:
		# If the hit already killed it (e.g. impact damage), drop now; otherwise
		# fall when it dies later.
		if hp.is_dead():
			_drop()
		elif not hp.died.is_connected(_drop):
			hp.died.connect(_drop)

## Un-stick and resume falling under gravity.
func _drop() -> void:
	_stuck = false
	_stuck_to = null
	velocity = Vector2.ZERO
