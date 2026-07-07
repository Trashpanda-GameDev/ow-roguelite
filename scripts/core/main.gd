extends Node
## Entry point. Spawns the local players, sets up cameras (shared or split) and
## per-player HUDs, and restarts the level when the whole party is down.

const ABILITY_HUD := preload("res://scripts/ui/ability_hud.gd")

@export var default_spawn: Vector2 = Vector2(400, 700)

@onready var level: Node = $TestLevel
@onready var hud: CanvasLayer = $HUD

var _camera_manager: CameraManager

func _ready() -> void:
	if not RunManager.active:
		RunManager.start_run(&"local")
	GameManager.state = GameManager.State.RUN
	Players.ensure_roster()
	_spawn_players()
	_setup_cameras()
	_setup_player_huds()

func _spawn_players() -> void:
	Players.spawn_all(level, _spawn_points())

func _spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var node := level.get_node_or_null(^"SpawnPoints")
	if node:
		for c in node.get_children():
			if c is Node2D:
				points.append((c as Node2D).global_position)
	if points.is_empty():
		points.append(default_spawn)
	return points

func _setup_cameras() -> void:
	_camera_manager = CameraManager.new()
	add_child(_camera_manager)
	_camera_manager.setup(GameManager.split_screen)

func _setup_player_huds() -> void:
	for i in Players.players.size():
		var ah := HBoxContainer.new()
		ah.set_script(ABILITY_HUD)
		hud.add_child(ah)
		ah.bind_to(Players.players[i])
		ah.place_in(_hud_rect(i))

## Where player i's HUD goes: their split viewport, or a bottom slice in shared.
func _hud_rect(index: int) -> Rect2:
	if GameManager.split_screen and Players.players.size() > 1:
		return _camera_manager.get_view_rect(index)
	var screen := get_viewport().get_visible_rect().size
	var w := screen.x / float(maxi(1, Players.players.size()))
	return Rect2(Vector2(w * index, 0.0), Vector2(w, screen.y))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_1: _swap_p1(&"tracer")
		KEY_2: _swap_p1(&"striker")
		KEY_G: GameManager.friendly_fire = not GameManager.friendly_fire
		KEY_V: _toggle_split()

func _swap_p1(hero_id: StringName) -> void:
	if Players.players.size() > 0 and is_instance_valid(Players.players[0]):
		Players.players[0].swap_to(hero_id)
	else:
		Players.set_hero(0, hero_id)

func _toggle_split() -> void:
	GameManager.split_screen = not GameManager.split_screen
	get_tree().reload_current_scene()
