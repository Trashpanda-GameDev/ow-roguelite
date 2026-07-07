class_name PlayerInput
extends Node
## Per-player input source. if device is -1 it's keyboard/mouse, if device is >= 0 it's that joypad's index.
## 
## setup() clones the InputMap actions into a private "p{index}_{action}" linked to that player's device,
## so we don't have to manually set up 4 players worth of controls inside the InputMap allowing the use of
## the InputMap while still splitting the controls per player device dynamically

@export var device: int = -1

# Base game actions (must exist in the project InputMap). Cloned per player.
const BASE_ACTIONS: Array[StringName] = [
	# movement
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"jump",
	&"dash",
	# combat
	&"attack_primary",
	&"attack_secondary",
	&"ability_1",
	&"ability_2",
	&"ultimate",
	# other
	&"switch_character",
	&"interact",
]

var _player_index: int = 0
var _actions_built: bool = false

## Assign this player's device + index and build its private actions.
func setup(device_id: int, player_index: int) -> void:
	if _actions_built and player_index != _player_index:
		_erase_actions_for(_player_index) # moving to a new prefix: drop the old one
		_actions_built = false
	device = device_id
	_player_index = player_index
	_build_actions()

# --- Public API (unchanged for callers) ---
func is_pressed(action: StringName) -> bool:
	_ensure_actions_built()
	return Input.is_action_pressed(_scoped_action_name(action))

func is_just_pressed(action: StringName) -> bool:
	_ensure_actions_built()
	return Input.is_action_just_pressed(_scoped_action_name(action))

func is_just_released(action: StringName) -> bool:
	_ensure_actions_built()
	return Input.is_action_just_released(_scoped_action_name(action))

## Analog for pads (deadzone from the InputMap), digital for keyboard.
func get_move() -> Vector2:
	_ensure_actions_built()
	return Input.get_vector(
		_scoped_action_name(&"move_left"),
		_scoped_action_name(&"move_right"),
		_scoped_action_name(&"move_up"),
		_scoped_action_name(&"move_down")
	)

# --- Internal functions (privates) ---

func _exit_tree() -> void:
	if _actions_built:
		_erase_actions_for(_player_index)

## Base action name -> player's private copy ("jump" becomes "p1_jump")
func _scoped_action_name(base_action: StringName) -> StringName:
	return StringName("p%d_%s" % [_player_index, base_action])

func _ensure_actions_built() -> void:
	if not _actions_built:
		_build_actions()

func _build_actions() -> void:
	for base_action in BASE_ACTIONS:
		if not InputMap.has_action(base_action):
			push_warning("PlayerInput: base action '%s' missing from InputMap" % base_action)
			continue
		var scoped_action := _scoped_action_name(base_action)
		if InputMap.has_action(scoped_action):
			InputMap.action_erase_events(scoped_action)
		else:
			InputMap.add_action(scoped_action, InputMap.action_get_deadzone(base_action))
		for base_event in InputMap.action_get_events(base_action):
			if not _event_matches_device(base_event):
				continue
			var scoped_event := base_event.duplicate()
			scoped_event.device = device # joypad events are now only this specific joypad
			InputMap.action_add_event(scoped_action, scoped_event)
	_actions_built = true

## Makes sure the events stay consistent for Keyboard/mouse and joypads.
func _event_matches_device(event: InputEvent) -> bool:
	if device < 0:
		return event is InputEventKey or event is InputEventMouseButton
	return event is InputEventJoypadButton or event is InputEventJoypadMotion

func _erase_actions_for(player_index: int) -> void:
	for base_action in BASE_ACTIONS:
		var scoped_action := StringName("p%d_%s" % [player_index, base_action])
		if InputMap.has_action(scoped_action):
			InputMap.erase_action(scoped_action)
