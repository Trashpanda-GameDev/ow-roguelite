@tool
class_name MeleeSlashAbility
extends Ability
## Short-lived melee hitbox in front of the caster, with a flashing graphic.

@export var damage: float = 25.0
@export var reach: float = 60.0
@export var lifetime: float = 0.12
@export var knockback: float = 0.0

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if not caster.has_method("get_center_position"):
		return false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	HitboxFactory.spawn(caster, caster.get_center_position() + aim_dir * reach, shape, {
		"damage": damage,
		"knockback": knockback,
		"knockback_dir": aim_dir,
		"source": caster,
		"team": caster.get_team(),
		"layer": caster.get_hitbox_layer(),
		"grants_ult_charge": not is_ultimate,
		"lifetime": lifetime,
		"visual_color": Color(1, 1, 1, 0.7),
		"flash": true,
	})
	return true
