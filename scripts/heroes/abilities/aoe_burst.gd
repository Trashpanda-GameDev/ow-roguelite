@tool
class_name AoeBurstAbility
extends Ability
## Radial burst centered on the caster — damages and knocks back everything in
## a circle. Used for slams and ultimates. Knockback pushes outward from center.

@export var damage: float = 40.0
@export var radius: float = 120.0
@export var lifetime: float = 0.18
@export var knockback: float = 260.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("spawn_aoe_hitbox"):
		push_warning("Caster lacks spawn_aoe_hitbox()")
		return false
	caster.spawn_aoe_hitbox(damage, radius, lifetime, knockback, not is_ultimate)
	return true
