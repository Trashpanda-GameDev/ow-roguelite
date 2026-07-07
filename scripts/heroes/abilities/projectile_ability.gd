@tool
class_name ProjectileAbility
extends Ability
## Ranged attack: fires `projectile_scene` in the aim direction, with optional
## spread. All spawn logic lives here; the caster only provides muzzle/team.

@export var damage: float = 15.0
@export var speed: float = 950.0
@export var knockback: float = 140.0
@export var spread_degrees: float = 0.0 ## total cone width; each shot randomized within it

func activate(caster: Node, aim_dir: Vector2) -> bool:
	if projectile_scene == null or not caster.has_method("get_muzzle_position"):
		push_warning("ProjectileAbility '%s' missing projectile_scene or actor API" % display_name)
		return false
	var dir := aim_dir
	if spread_degrees > 0.0:
		dir = aim_dir.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees) * 0.5))
	var proj := projectile_scene.instantiate()
	if "grants_ult_charge" in proj:
		proj.grants_ult_charge = not is_ultimate
	if "team" in proj:
		proj.team = caster.get_team()
	caster.get_world().add_child(proj)
	if proj is Node2D:
		(proj as Node2D).global_position = caster.get_muzzle_position()
	if proj.has_method("setup"):
		proj.setup(dir, speed, damage, knockback, caster)
	return true
