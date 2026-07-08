@tool
class_name AoeBurstAbility
extends Ability
## Radial burst centered on the caster - damages and knocks back everything in its hitbox.
## Knockback pushes outward from the center (auto direction).

@export var hitbox_scene: PackedScene
@export var damage: float = 40.0
@export var lifetime: float = 0.18
@export var knockback: float = 260.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("get_center_position"):
		return false
	var hitbox := HitboxComponent.from_scene(hitbox_scene, caster, caster.get_center_position())
	if hitbox == null:
		push_warning("AoeBurstAbility '%s' has no hitbox_scene" % display_name)
		return false
	hitbox.damage = damage
	hitbox.knockback = knockback
	hitbox.source = caster
	hitbox.team = caster.get_team()
	hitbox.grants_ult_charge = not is_ultimate
	hitbox.expire_after(lifetime)
	return true
