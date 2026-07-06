class_name HealthComponent
extends Node
## Reusable HP container. Attach to any entity; other components/hitboxes
## call take_damage()/heal() on it.

signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 100.0
@export var invulnerable: bool = false

var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, source: Node = null, grants_ult_charge: bool = true) -> void:
	if invulnerable or is_dead():
		return
	amount = maxf(0.0, amount)
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)
	EventBus.damage_dealt.emit(owner, amount, source, grants_ult_charge)
	if current_health <= 0.0:
		died.emit()
		EventBus.entity_died.emit(owner)

func heal(amount: float) -> void:
	if is_dead():
		return
	current_health = minf(max_health, current_health + maxf(0.0, amount))
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func set_max_health(value: float, keep_ratio: bool = true) -> void:
	var ratio := current_health / max_health if max_health > 0.0 else 1.0
	max_health = maxf(1.0, value)
	current_health = max_health * ratio if keep_ratio else minf(current_health, max_health)
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0.0

func fraction() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0
