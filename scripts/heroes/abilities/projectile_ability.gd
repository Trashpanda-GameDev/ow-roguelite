@tool
class_name ProjectileAbility
extends Ability
## Ranged attack: fires `projectile_scene` in the aim direction. Assign the
## projectile scene on the base Ability's `projectile_scene` export.

@export var damage: float = 15.0
@export var speed: float = 950.0
@export var knockback: float = 140.0
@export var spread_degrees: float = 0.0 ## total cone width; each shot is randomized within it

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if projectile_scene == null or not caster.has_method("spawn_projectile"):
		push_warning("ProjectileAbility '%s' missing projectile_scene or spawner" % display_name)
		return false
	var dir := aim_dir
	if spread_degrees > 0.0:
		dir = aim_dir.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees) * 0.5))
	caster.spawn_projectile(projectile_scene, dir, damage, speed, knockback, not is_ultimate)
	return true
