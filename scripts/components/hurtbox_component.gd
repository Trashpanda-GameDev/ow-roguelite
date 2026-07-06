class_name HurtboxComponent
extends Area2D
## Receives hits. Pair with a HealthComponent. A HitboxComponent overlapping
## this area applies its damage. Set collision layer to the owner's
## "*_hitbox" receiving layer and enable monitoring.

@export var health: HealthComponent

func _ready() -> void:
	if health == null:
		health = _find_health()
	area_entered.connect(_on_area_entered)

## Fallback: locate a HealthComponent in the same entity if not set in the editor.
func _find_health() -> HealthComponent:
	var root: Node = owner if owner else get_parent()
	if root == null:
		return null
	for c in root.find_children("*", "HealthComponent", true, false):
		return c
	return null

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		var hitbox := area as HitboxComponent
		if hitbox.source == owner and not hitbox.can_hit_self:
			return # ignore self-damage unless the hitbox explicitly allows it
		if health:
			health.take_damage(hitbox.damage, hitbox.source, hitbox.grants_ult_charge)
		hitbox.on_hit(self)
