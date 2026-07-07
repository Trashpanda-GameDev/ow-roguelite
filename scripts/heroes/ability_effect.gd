class_name AbilityEffect
extends RefCounted
## A per-cast, multi-frame effect that drives an actor's motion. Abilities create
## one and hand it to the actor via play_motion_effect(); the actor ticks it each
## physics frame until tick() returns true. Lets movement-ability logic live with
## the ability instead of on the player.

func on_start(_actor: Node) -> void:
	pass

## Set the actor's motion for this frame. Return true when the effect is done.
func tick(_actor: Node, _delta: float) -> bool:
	return true

func on_end(_actor: Node) -> void:
	pass
