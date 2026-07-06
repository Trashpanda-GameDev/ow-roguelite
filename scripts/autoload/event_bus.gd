extends Node
## Global signal hub. Decouples systems: emitters and listeners never need
## direct references to each other. Autoloaded as "EventBus".

# --- Combat ---
signal damage_dealt(target: Node, amount: float, source: Node, grants_ult_charge: bool)
signal entity_died(entity: Node)
signal player_health_changed(current: float, max: float)
signal player_ultimate_charged(ready: bool)
signal ability_used(slot: StringName, cooldown: float)
signal ammo_changed(slot: StringName, current: int, max: int)
signal reload_started(slot: StringName, duration: float)
signal charges_changed(slot: StringName, current: int, max: int)

# --- Run / progression ---
signal run_started(hero_id: StringName)
signal run_ended(victory: bool)
signal room_entered(room: Node)
signal room_cleared(room: Node)
signal currency_changed(amount: int)
signal reward_offered(choices: Array)

# --- Meta / flow ---
signal player_spawned(player: Node) ## fired once the player's hero is applied
signal hero_selected(hero_id: StringName)
signal game_paused(paused: bool)
signal scene_transition_requested(scene_path: String)
