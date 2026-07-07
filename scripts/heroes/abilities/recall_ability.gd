@tool
class_name RecallAbility
extends Ability
## Rewind the caster's position and health to a few seconds ago.

@export var seconds: float = 3.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("get_history_sample"):
		return false
	var hp: HealthComponent = caster.get_health()
	if hp and hp.is_dead():
		return false # no rewinding out of death
	var sample: Dictionary = caster.get_history_sample(seconds)
	if sample.is_empty():
		return false
	caster.teleport(sample["pos"])
	caster.velocity = Vector2.ZERO
	if hp:
		hp.current_health = minf(hp.max_health, sample["hp"])
		hp.health_changed.emit(hp.current_health, hp.max_health)
	return true
