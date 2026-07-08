class_name Projectile
extends Node2D
## Simple moving projectile. Carries a one-shot HitboxComponent that applies
## impact damage; frees itself on hit or after its lifetime. If explosion_hitbox_scene
## is set, spawns it on death (e.g. Pulse Bomb).

@export var lifetime: float = 2.0
@export_group("Explosion")
@export var explosion_hitbox_scene: PackedScene ## assign a hitbox scene to explode
@export var explosion_damage: float = 0.0
@export var explosion_knockback: float = 0.0
@export var explosion_hits_self: bool = false ## explosion also damages the caster

@onready var hitbox: HitboxComponent = $HitboxComponent

var velocity: Vector2 = Vector2.ZERO
var grants_ult_charge: bool = true ## set by the spawner; false for ultimates
var team: int = -1 ## set by the spawner; carried onto the hitbox + explosion

func _ready() -> void:
	hitbox.hit.connect(func(_hurtbox): _die())
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self): _die())

func _physics_process(delta: float) -> void:
	position += velocity * delta

## Called by the spawner right after instantiation.
func setup(dir: Vector2, speed: float, damage: float, knockback: float, source: Node) -> void:
	velocity = dir * speed
	rotation = dir.angle()
	hitbox.damage = damage
	hitbox.knockback = knockback
	hitbox.knockback_dir = dir
	hitbox.source = source
	hitbox.grants_ult_charge = grants_ult_charge
	hitbox.team = team

func _die() -> void:
	if explosion_hitbox_scene:
		_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var host := get_parent()
	if host == null:
		return
	var explosion := HitboxComponent.from_scene(explosion_hitbox_scene, host, global_position)
	if explosion == null:
		return
	explosion.damage = explosion_damage
	explosion.knockback = explosion_knockback
	explosion.source = hitbox.source
	explosion.team = team
	explosion.can_hit_self = explosion_hits_self
	explosion.grants_ult_charge = grants_ult_charge
	explosion.expire_after(0.25)
