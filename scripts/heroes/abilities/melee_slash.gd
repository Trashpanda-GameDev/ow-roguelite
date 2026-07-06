@tool
class_name MeleeSlashAbility
extends Ability
## Sample primary: a short-lived melee hitbox in front of the caster. Expects
## the caster to expose spawn_hitbox(damage, offset, lifetime, aim_dir).

@export var damage: float = 25.0
@export var reach: float = 60.0
@export var lifetime: float = 0.12
@export var knockback: float = 0.0

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if not caster.has_method("spawn_melee_hitbox"):
		push_warning("Caster lacks spawn_melee_hitbox()")
		return false
	caster.spawn_melee_hitbox(damage, aim_dir * reach, lifetime, knockback, aim_dir)
	return true
