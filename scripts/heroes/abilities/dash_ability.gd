@tool
class_name DashAbility
extends Ability
## Quick horizontal burst in the aim/facing direction, run as a motion effect.

@export var speed: float = 950.0
@export var duration: float = 0.16

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if not caster.has_method("play_motion_effect"):
		return false
	var dir := Vector2(signf(aim_dir.x), 0.0)
	if dir.x == 0.0:
		dir.x = caster.get_facing() if caster.has_method("get_facing") else 1.0
	caster.play_motion_effect(DashEffect.new(dir, speed, duration))
	return true
