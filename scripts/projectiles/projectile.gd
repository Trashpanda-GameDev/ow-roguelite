class_name Projectile
extends Node2D
## Simple moving projectile. Carries a one-shot HitboxComponent that applies
## impact damage; frees itself on hit or after its lifetime. If explosion_radius
## is set, spawns a radial burst hitbox on death (e.g. Pulse Bomb).

@export var lifetime: float = 2.0
@export_group("Explosion")
@export var explosion_radius: float = 0.0
@export var explosion_damage: float = 0.0
@export var explosion_knockback: float = 0.0
@export var explosion_hits_self: bool = false ## explosion also damages the caster

@onready var hitbox: HitboxComponent = $HitboxComponent

var velocity: Vector2 = Vector2.ZERO
var grants_ult_charge: bool = true ## set by the spawner; false for ultimates

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

func _die() -> void:
	if explosion_radius > 0.0:
		_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var host := get_parent()
	if host == null:
		return
	var hb := HitboxComponent.new()
	hb.damage = explosion_damage
	hb.knockback = explosion_knockback
	hb.source = hitbox.source
	hb.can_hit_self = explosion_hits_self
	hb.grants_ult_charge = grants_ult_charge
	hb.collision_layer = 1 << 3 # player_hitbox
	hb.collision_mask = 0
	hb.monitoring = false
	hb.monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	shape.shape = circle
	hb.add_child(shape)
	var ring := Polygon2D.new()
	ring.color = Color(1.0, 0.5, 0.2, 0.4)
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * explosion_radius)
	ring.polygon = pts
	hb.add_child(ring)
	host.add_child(hb)
	hb.global_position = global_position
	get_tree().create_timer(0.25).timeout.connect(func(): if is_instance_valid(hb): hb.queue_free())
