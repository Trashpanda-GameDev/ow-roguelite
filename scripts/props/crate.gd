class_name Crate
extends RigidBody2D
## A physics prop: falls, stacks, and gets shoved by the player, attacks, and
## explosions. When moving fast enough it becomes a damaging hazard, so a crate
## punched into an enemy hurts it (damage scales with speed).

const MIN_SPEED := 320.0        ## below this the crate is harmless
const DAMAGE_PER_SPEED := 0.05  ## damage = speed * this (capped)
const MAX_DAMAGE := 60.0
const KNOCKBACK_FACTOR := 0.35

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox.source = self
	hitbox.grants_ult_charge = false # crate hits don't build ult charge
	hitbox.monitorable = false

func apply_knockback(impulse: Vector2) -> void:
	apply_central_impulse(impulse)

func _physics_process(_delta: float) -> void:
	var speed := linear_velocity.length()
	var dangerous := speed >= MIN_SPEED
	if dangerous:
		hitbox.damage = minf(MAX_DAMAGE, speed * DAMAGE_PER_SPEED)
		hitbox.knockback = speed * KNOCKBACK_FACTOR
		hitbox.knockback_dir = linear_velocity.normalized()
	# Toggling monitorable re-triggers detection, so a crate that speeds up
	# while touching an enemy still lands the hit.
	if hitbox.monitorable != dangerous:
		hitbox.monitorable = dangerous
