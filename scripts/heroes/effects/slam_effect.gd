class_name SlamEffect
extends AbilityEffect
## Rockets the actor straight down, damaging things it passes through, then
## bursts on landing for damage scaled by fall distance.

var descent_hitbox_scene: PackedScene
var burst_hitbox_scene: PackedScene
var slam_speed: float = 1500.0
var descent_damage: float = 12.0
var descent_knockback: float = 140.0
var base_damage: float = 20.0
var damage_per_height: float = 0.2
var max_damage: float = 220.0
var lifetime: float = 0.2
var knockback: float = 380.0
var grants_ult_charge: bool = true

var _start_y: float
var _descent_hitbox: HitboxComponent

func on_start(actor: Node) -> void:
	_start_y = actor.global_position.y
	_descent_hitbox = HitboxComponent.from_scene(descent_hitbox_scene, actor, actor.global_position)
	if _descent_hitbox:
		_descent_hitbox.damage = descent_damage
		_descent_hitbox.knockback = descent_knockback
		_descent_hitbox.source = actor
		_descent_hitbox.team = actor.get_team()
		_descent_hitbox.grants_ult_charge = grants_ult_charge

func tick(actor: Node, _delta: float) -> bool:
	actor.velocity = Vector2(0.0, slam_speed)
	return actor.is_on_floor()

func on_end(actor: Node) -> void:
	if is_instance_valid(_descent_hitbox):
		_descent_hitbox.queue_free()
	_descent_hitbox = null
	var fall: float = maxf(0.0, actor.global_position.y - _start_y)
	var damage: float = minf(max_damage, base_damage + fall * damage_per_height)
	var burst := HitboxComponent.from_scene(burst_hitbox_scene, actor.get_world(), actor.global_position)
	if burst == null:
		return
	burst.damage = damage
	burst.knockback = knockback
	burst.source = actor
	burst.team = actor.get_team()
	burst.grants_ult_charge = grants_ult_charge
	burst.expire_after(lifetime)
