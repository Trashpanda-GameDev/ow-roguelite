@tool
class_name BlinkAbility
extends Ability
## Near-instant horizontal teleport in the movement/facing direction, stopped
## short of walls. All logic lives here using the caster's generic API.

@export var distance: float = 200.0

func activate(caster: Node, _aim_dir: Vector2) -> bool:
	if not caster.has_method("teleport"):
		return false
	var body := caster as Node2D
	var mv: Vector2 = caster.get_move_input()
	var dir_x: float = signf(mv.x) if mv.x != 0.0 else caster.get_facing()
	var from: Vector2 = body.global_position
	var to := from + Vector2(dir_x * distance, 0.0)
	var space: PhysicsDirectSpaceState2D = body.get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(from, to, caster.collision_mask, [body.get_rid()])
	var hit: Dictionary = space.intersect_ray(params)
	var dest: Vector2 = ((hit.position as Vector2) - Vector2(dir_x * 20.0, 0.0)) if hit else to
	caster.set_facing(dir_x)
	caster.teleport(dest)
	return true
