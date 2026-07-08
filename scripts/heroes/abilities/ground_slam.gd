@tool
class_name GroundSlamAbility
extends Ability
## Aerial slam: rockets the caster down (damaging things it passes through) and
## bursts on landing for AoE damage that scales with fall distance. Runs as a 
## SlamEffect.

@export var descent_hitbox_scene: PackedScene ## follows the caster down
@export var burst_hitbox_scene: PackedScene ## spawned on landing
@export var slam_speed: float = 1500.0
@export_group("Descent")
@export var descent_damage: float = 12.0
@export_group("Landing")
@export var base_damage: float = 20.0
@export var damage_per_height: float = 0.2 ## added per pixel fallen
@export var max_damage: float = 220.0
@export var lifetime: float = 0.2
@export var knockback: float = 380.0

## Only usable in the air — the whole point is to slam down.
func can_activate(caster: Node) -> bool:
	return caster.has_method("is_on_floor") and not caster.is_on_floor()

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("play_motion_effect"):
		return false
	var effect := SlamEffect.new()
	effect.descent_hitbox_scene = descent_hitbox_scene
	effect.burst_hitbox_scene = burst_hitbox_scene
	effect.slam_speed = slam_speed
	effect.descent_damage = descent_damage
	effect.base_damage = base_damage
	effect.damage_per_height = damage_per_height
	effect.max_damage = max_damage
	effect.lifetime = lifetime
	effect.knockback = knockback
	effect.grants_ult_charge = not is_ultimate
	caster.play_motion_effect(effect)
	return true
