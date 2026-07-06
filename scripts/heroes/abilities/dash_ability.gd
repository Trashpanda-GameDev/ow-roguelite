@tool
class_name DashAbility
extends Ability
## Movement ability: a quick horizontal burst in the aim/facing direction.
## Self-contained — carries its own speed and duration. Cooldown comes from
## the base Ability. Plug into a hero's dash slot (or any slot).

@export var speed: float = 950.0
@export var duration: float = 0.16

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if not caster.has_method("start_dash"):
		return false
	var dir := Vector2(signf(aim_dir.x), 0.0)
	if dir.x == 0.0:
		dir.x = caster.get_facing() if caster.has_method("get_facing") else 1.0
	caster.start_dash(dir, speed, duration)
	return true
