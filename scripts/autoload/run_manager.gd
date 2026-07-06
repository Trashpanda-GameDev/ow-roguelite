extends Node
## Owns state for a single roguelite run: chosen hero, currency, depth,
## and accumulated upgrades. Reset on each new run. Autoloaded as "RunManager".

var active: bool = false
var hero_id: StringName = &""
var currency: int = 0
var depth: int = 0          ## rooms/floors cleared this run
var upgrades: Array = []    ## picked-up modifiers (Resource instances)
var rng := RandomNumberGenerator.new()

func start_run(selected_hero: StringName, seed: int = 0) -> void:
	active = true
	hero_id = selected_hero
	currency = 0
	depth = 0
	upgrades.clear()
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	EventBus.run_started.emit(hero_id)

func end_run(victory: bool) -> void:
	active = false
	EventBus.run_ended.emit(victory)

func add_currency(amount: int) -> void:
	currency = max(0, currency + amount)
	EventBus.currency_changed.emit(currency)

func add_upgrade(upgrade: Resource) -> void:
	upgrades.append(upgrade)

func advance_depth() -> void:
	depth += 1
