class_name SlamEffect
extends AbilityEffect
## Rockets the actor straight down, damaging things it passes through, then
## bursts on landing for damage scaled by fall distance.

var _cfg: Dictionary
var _speed: float
var _start_y: float
var _descent_hitbox: HitboxComponent

func _init(cfg: Dictionary) -> void:
	_cfg = cfg
	_speed = cfg.get("slam_speed", 1400.0)

func on_start(actor: Node) -> void:
	_start_y = actor.global_position.y
	var shape := CircleShape2D.new()
	shape.radius = _cfg.get("descent_radius", 42.0)
	# Parented to the actor so it follows the fall.
	_descent_hitbox = HitboxFactory.spawn(actor, actor.global_position, shape, {
		"damage": _cfg.get("descent_damage", 12.0),
		"knockback": 140.0,
		"source": actor,
		"team": actor.get_team(),
		"layer": actor.get_hitbox_layer(),
		"grants_ult_charge": _cfg.get("grants_ult_charge", true),
		"visual_color": Color(0.6, 0.85, 1.0, 0.35),
	})

func tick(actor: Node, _delta: float) -> bool:
	actor.velocity = Vector2(0.0, _speed)
	return actor.is_on_floor()

func on_end(actor: Node) -> void:
	if is_instance_valid(_descent_hitbox):
		_descent_hitbox.queue_free()
	_descent_hitbox = null
	var fall: float = maxf(0.0, actor.global_position.y - _start_y)
	var dmg: float = minf(
		_cfg.get("max_damage", 220.0),
		_cfg.get("base_damage", 20.0) + fall * _cfg.get("damage_per_height", 0.2),
	)
	var shape := CircleShape2D.new()
	shape.radius = _cfg.get("radius", 140.0)
	HitboxFactory.spawn(actor.get_world(), actor.global_position, shape, {
		"damage": dmg,
		"knockback": _cfg.get("knockback", 380.0),
		"source": actor,
		"team": actor.get_team(),
		"layer": actor.get_hitbox_layer(),
		"grants_ult_charge": _cfg.get("grants_ult_charge", true),
		"lifetime": _cfg.get("lifetime", 0.2),
		"visual_color": Color(0.5, 0.8, 1.0, 0.28),
	})
