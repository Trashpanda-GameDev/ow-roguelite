@tool
class_name GroundSlamAbility
extends Ability
## Aerial slam: the caster rockets straight down, damaging things it passes
## through, and on landing bursts for AoE damage that scales with fall distance.

@export var slam_speed: float = 1500.0
@export_group("Descent")
@export var descent_damage: float = 12.0
@export var descent_radius: float = 42.0
@export_group("Landing")
@export var base_damage: float = 20.0
@export var damage_per_height: float = 0.2 ## added per pixel fallen
@export var max_damage: float = 220.0
@export var radius: float = 140.0
@export var lifetime: float = 0.2
@export var knockback: float = 380.0

## Only usable in the air — the whole point is to slam down.
func can_activate(caster: Node) -> bool:
	return caster.has_method("is_on_floor") and not caster.is_on_floor()

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("start_slam"):
		return false
	caster.start_slam({
		"slam_speed": slam_speed,
		"descent_damage": descent_damage,
		"descent_radius": descent_radius,
		"base_damage": base_damage,
		"damage_per_height": damage_per_height,
		"max_damage": max_damage,
		"radius": radius,
		"lifetime": lifetime,
		"knockback": knockback,
		"grants_ult_charge": not is_ultimate,
	})
	return true
