@tool
class_name AoeBurstAbility
extends Ability
## Radial burst centered on the caster — damages and knocks back everything in
## a circle. Knockback pushes outward from the center (auto direction).

@export var damage: float = 40.0
@export var radius: float = 120.0
@export var lifetime: float = 0.18
@export var knockback: float = 260.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("get_center_position"):
		return false
	var shape := CircleShape2D.new()
	shape.radius = radius
	HitboxFactory.spawn(caster, caster.get_center_position(), shape, {
		"damage": damage,
		"knockback": knockback,
		"source": caster,
		"team": caster.get_team(),
		"layer": caster.get_hitbox_layer(),
		"grants_ult_charge": not is_ultimate,
		"lifetime": lifetime,
		"visual_color": Color(0.5, 0.8, 1.0, 0.28),
	})
	return true
