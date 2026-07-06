extends Node
## Top-level game state & scene flow. Autoloaded as "GameManager".

enum State { BOOT, MENU, RUN, PAUSED, GAME_OVER }

var state: State = State.BOOT
var _paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.scene_transition_requested.connect(_on_scene_transition_requested)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and (state == State.RUN or state == State.PAUSED):
		toggle_pause()

func toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	state = State.PAUSED if _paused else State.RUN
	EventBus.game_paused.emit(_paused)

func change_scene(scene_path: String) -> void:
	# Deferred so callers mid-signal don't free themselves prematurely.
	get_tree().change_scene_to_file.call_deferred(scene_path)

func _on_scene_transition_requested(scene_path: String) -> void:
	change_scene(scene_path)
