class_name DashEffect
extends AbilityEffect
## Fixed-direction burst for a set duration, then bleeds momentum.

var _dir: Vector2
var _speed: float
var _time_left: float

func _init(dir: Vector2, speed: float, duration: float) -> void:
	_dir = dir.normalized()
	_speed = speed
	_time_left = duration

func on_start(actor: Node) -> void:
	if _dir.x != 0.0 and actor.has_method("set_facing"):
		actor.set_facing(_dir.x)

func tick(actor: Node, delta: float) -> bool:
	actor.velocity = _dir * _speed
	_time_left -= delta
	if _time_left <= 0.0:
		actor.velocity *= 0.4
		return true
	return false
