class_name Ragdoll
extends RefCounted
## Factory for a simple physics "corpse": a RigidBody2D box that tumbles and
## collides with the world. Placeholder death effect for the player and enemies.

## Spawn a corpse under `parent` at `at`, sized `size`, drawn `color`, launched
## with `launch` velocity. Returns the body so the caller can free it later.
static func spawn(parent: Node, at: Vector2, size: Vector2, color: Color, launch: Vector2 = Vector2.ZERO) -> RigidBody2D:
	if parent == null:
		return null
	var corpse := RigidBody2D.new()
	corpse.collision_layer = 0
	corpse.collision_mask = 1 # collide with world only
	corpse.gravity_scale = 1.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	corpse.add_child(shape)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var vis := Polygon2D.new()
	vis.color = color
	vis.polygon = PackedVector2Array([Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	corpse.add_child(vis)
	parent.add_child(corpse)
	corpse.global_position = at
	corpse.linear_velocity = launch
	corpse.angular_velocity = randf_range(-10.0, 10.0)
	return corpse
