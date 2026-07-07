class_name HitboxComponent
extends Area2D
## Deals damage on overlap with a HurtboxComponent. Used by melee swings,
## projectiles, and ability effects. Set its collision mask to the layers
## of hurtboxes it should hit.

signal hit(hurtbox: HurtboxComponent)

@export var damage: float = 10.0
@export var knockback: float = 0.0
@export var knockback_up: float = 0.35 ## extra upward pop as a fraction of knockback
@export var one_shot: bool = false ## disable after first hit (projectiles)
@export var can_hit_self: bool = false ## true = also damages its own source (e.g. an AoE that hurts the caster)

var source: Node ## the entity that owns/fired this hitbox
var team: int = -1 ## source's team; -1 = neutral (hits everyone)
var knockback_dir: Vector2 = Vector2.ZERO ## preferred push direction; auto if zero
var grants_ult_charge: bool = true ## whether hits build the source's ultimate charge

func on_hit(hurtbox: HurtboxComponent) -> void:
	hit.emit(hurtbox)
	if knockback > 0.0 and hurtbox.owner is Node2D:
		var target := hurtbox.owner as Node2D
		# Use the caller-supplied direction; otherwise push away from the hitbox.
		var dir := knockback_dir
		if dir == Vector2.ZERO:
			dir = (target.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		# Add a slight upward pop so hits feel punchier.
		var impulse := dir * knockback
		impulse.y -= knockback * knockback_up
		if target.has_method("apply_knockback"):
			target.apply_knockback(impulse)
	if one_shot:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
