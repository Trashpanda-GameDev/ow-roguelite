@tool
class_name BlinkAbility
extends Ability
## Tracer's Blink: a near-instant horizontal teleport in the movement/facing
## direction, stopped short by walls. Snappier than a dash.

@export var distance: float = 200.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("blink"):
		return false
	caster.blink(distance)
	return true
