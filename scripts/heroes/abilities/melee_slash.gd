@tool
class_name MeleeSlashAbility
extends Ability
## Short-lived melee hitbox in front of the caster, with a flashing graphic.

@export var hitbox_scene: PackedScene
@export var damage: float = 25.0
@export var reach: float = 60.0
@export var lifetime: float = 0.12
@export var knockback: float = 0.0

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if not caster.has_method("get_center_position"):
		return false
	var target_position: Vector2 = caster.get_center_position() + aim_dir * reach
	var hitbox := HitboxComponent.from_scene(hitbox_scene, caster, target_position)
	if hitbox == null:
		push_warning("MeleeSlashAbility '%s' has no hitbox_scene" % display_name)
		return false
	hitbox.damage = damage
	hitbox.knockback = knockback
	hitbox.knockback_dir = aim_dir
	hitbox.source = caster
	hitbox.team = caster.get_team()
	hitbox.grants_ult_charge = not is_ultimate
	hitbox.expire_after(lifetime)
	return true
