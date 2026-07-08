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

@export_group("Debug Visual")
@export var visual_color: Color = Color(1, 1, 1, 0) ## 0 on alpha means no visual by default
@export var visual_flash: bool = false ## fade out the debug visual

var source: Node ## the entity that owns/fired this hitbox
var team: int = -1 ## source's team; -1 = neutral (hits everyone)
var knockback_dir: Vector2 = Vector2.ZERO ## preferred push direction; auto if zero
var grants_ult_charge: bool = true ## whether hits build the source's ultimate charge

@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

## Creates an hitbox scene on the parent node
static func from_scene(scene: PackedScene, parent: Node, target_position: Vector2) -> HitboxComponent:
	if scene == null or parent == null:
		return null
	var hitbox: HitboxComponent = scene.instantiate()
	parent.add_child(hitbox)
	hitbox.global_position = target_position
	return hitbox

## `queue_free` after `seconds`. Fades the debug visual over that time.
func expire_after(seconds: float) -> void:
	if seconds <= 0.0:
		return
	get_tree().create_timer(seconds).timeout.connect(queue_free)
	if visual_flash and visual_color.a > 0.0:
		create_tween().tween_property(self, "self_modulate:a", 0.0, seconds)

func on_hit(hurtbox: HurtboxComponent) -> void:
	hit.emit(hurtbox)
	if knockback > 0.0 and hurtbox.owner is Node2D:
		var target := hurtbox.owner as Node2D
		# Use the caller-supplied direction; otherwise push away from the hitbox.
		var direction := knockback_dir
		if direction == Vector2.ZERO:
			direction = (target.global_position - global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		# Add a slight upward pop so hits feel punchier.
		var impulse := direction * knockback
		impulse.y -= knockback * knockback_up
		if target.has_method("apply_knockback"):
			target.apply_knockback(impulse)
	if one_shot:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

func _draw() -> void:
	if visual_color.a <= 0.0 or _collision_shape == null or _collision_shape.shape == null:
		return
	var shape := _collision_shape.shape
	var center := _collision_shape.position
	if shape is CircleShape2D:
		draw_circle(center, (shape as CircleShape2D).radius, visual_color)
	elif shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		draw_rect(Rect2(center - size * 0.5, size), visual_color)
