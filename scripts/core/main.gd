extends Node
## Entry point. For now boots straight into a run with the starter hero.
## Later this becomes: main menu -> hero select -> run.

@export var starter_hero: StringName = &"tracer"

# Debug: press a number key to swap hero and restart the level.
const DEBUG_HEROES := {
	KEY_1: &"tracer",
	KEY_2: &"striker",
}

@export var restart_delay: float = 3.0 ## seconds after death before the level restarts

func _ready() -> void:
	# Keep the current run's hero across scene reloads (debug hero switch).
	if not RunManager.active:
		RunManager.start_run(starter_hero)
	GameManager.state = GameManager.State.RUN
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool) -> void:
	if victory:
		return
	_restart_after_delay()

func _restart_after_delay() -> void:
	await get_tree().create_timer(restart_delay).timeout
	# Restart the run with the same hero, then reload the level.
	RunManager.start_run(RunManager.hero_id)
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if DEBUG_HEROES.has(key):
			RunManager.start_run(DEBUG_HEROES[key])
			get_tree().reload_current_scene()
