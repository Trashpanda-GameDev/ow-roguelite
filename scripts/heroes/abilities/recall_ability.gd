@tool
class_name RecallAbility
extends Ability
## Tracer's Recall: rewind the caster's position and health to a few seconds ago.

@export var seconds: float = 3.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("recall"):
		return false
	caster.recall(seconds)
	return true
