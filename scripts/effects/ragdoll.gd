class_name Ragdoll
extends RigidBody2D
## Simple physics "corpse": a box that tumbles and collides with the world.
## Placeholder death effect for the player and enemies.

const SCENE_PATH := "res://scenes/effects/corpse.tscn"
static var _scene: PackedScene

var _size: Vector2 = Vector2(32, 32)
var _color: Color = Color.WHITE

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

## Spawn a corpse under `parent` at `at`, sized `size`, drawn `color`, launched
## with `launch` velocity. Returns the body so the caller can free it later.
static func spawn(parent: Node, at: Vector2, size: Vector2, color: Color, launch: Vector2 = Vector2.ZERO) -> Ragdoll:
	if parent == null:
		return null
	if _scene == null:
		_scene = load(SCENE_PATH)
	var corpse: Ragdoll = _scene.instantiate()
	parent.add_child(corpse)
	corpse.global_position = at
	corpse._create(size, color, launch)
	return corpse

func _create(size: Vector2, color: Color, launch: Vector2) -> void:
	_size = size
	_color = color
	var rect := RectangleShape2D.new()
	rect.size = size
	_collision_shape.shape = rect
	linear_velocity = launch
	angular_velocity = randf_range(-10.0, 10.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-_size * 0.5, _size), _color)
