extends Node
## Owns the local-player roster (device + hero per player) and spawns them.
## Autoloaded as "Players" so the roster survives level reloads. All players are
## on the same team (co-op); friendly fire is GameManager.friendly_fire.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HERO_CYCLE: Array[StringName] = [&"tracer", &"striker"]
const MAX_PLAYERS := 4

# Each config: {device: int (-1 keyboard), hero_id: StringName}
var configs: Array[Dictionary] = []
var players: Array[Node] = []

func ensure_roster() -> void:
	if configs.is_empty():
		build_default_roster()

## Player 1 = keyboard, then one player per connected gamepad.
func build_default_roster() -> void:
	configs.clear()
	configs.append({"device": -1, "hero_id": HERO_CYCLE[0]})
	var pads := Input.get_connected_joypads()
	for i in mini(pads.size(), MAX_PLAYERS - 1):
		configs.append({"device": pads[i], "hero_id": HERO_CYCLE[(i + 1) % HERO_CYCLE.size()]})

func set_hero(index: int, hero_id: StringName) -> void:
	if index >= 0 and index < configs.size():
		configs[index]["hero_id"] = hero_id

func player_count() -> int:
	return configs.size()

## Instantiate all players into `into`, placed at `points` (cycled).
func spawn_all(into: Node, points: Array[Vector2]) -> Array[Node]:
	ensure_roster()
	players.clear()
	for i in configs.size():
		var cfg := configs[i]
		var p := PLAYER_SCENE.instantiate()
		p.hero = load("res://resources/heroes/%s.tres" % cfg["hero_id"]) as Hero
		p.team = GameManager.TEAM_PLAYER
		into.add_child(p)
		if points.size() > 0:
			p.global_position = points[i % points.size()]
		if p.input:
			p.input.setup(cfg["device"], i)
		p.set_meta(&"player_index", i)
		players.append(p)
	return players

func alive_players() -> Array[Node]:
	var out: Array[Node] = []
	for p in players:
		if is_instance_valid(p) and (p as Node2D).visible:
			out.append(p)
	return out
