class_name PlayerInput
extends Node
## Per-player input source. device == -1 -> keyboard/mouse; device >= 0 -> that
## joypad. Abilities and movement read through this instead of global Input, so
## multiple local players each get their own controls.

@export var device: int = -1

# Digital action state (edge-detected each frame).
var _curr := {}
var _prev := {}

const _ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"jump", &"dash", &"attack_primary", &"attack_secondary",
	&"ability_1", &"ability_2", &"ultimate", &"interact", &"pause",
	&"switch_character",
]

# Keyboard/mouse bindings (physical keycodes).
const _KEYS := {
	&"move_left": KEY_A, &"move_right": KEY_D, &"move_up": KEY_W, &"move_down": KEY_S,
	&"jump": KEY_SPACE, &"dash": KEY_SHIFT,
	&"ability_1": KEY_Q, &"ability_2": KEY_E, &"ultimate": KEY_R,
	&"interact": KEY_F, &"pause": KEY_ESCAPE, &"switch_character": KEY_TAB,
}
const _MOUSE := { &"attack_primary": MOUSE_BUTTON_LEFT, &"attack_secondary": MOUSE_BUTTON_RIGHT }

# Gamepad button bindings (Godot JoyButton indices).
const _PAD_BTN := {
	&"jump": JOY_BUTTON_A, &"dash": JOY_BUTTON_B,
	&"attack_primary": JOY_BUTTON_X, &"attack_secondary": JOY_BUTTON_Y,
	&"ability_1": JOY_BUTTON_LEFT_SHOULDER, &"ability_2": JOY_BUTTON_RIGHT_SHOULDER,
	&"interact": JOY_BUTTON_DPAD_UP, &"pause": JOY_BUTTON_START,
	&"switch_character": JOY_BUTTON_BACK, # Create / Share / View
}
const _STICK_DEADZONE := 0.4

func _ready() -> void:
	# Update input before anything that reads it this physics frame.
	process_physics_priority = -100
	for a in _ACTIONS:
		_curr[a] = false
		_prev[a] = false

func _physics_process(_delta: float) -> void:
	for a in _ACTIONS:
		_prev[a] = _curr[a]
		_curr[a] = _raw_pressed(a)

func is_pressed(action: StringName) -> bool:
	return _curr.get(action, false)

func is_just_pressed(action: StringName) -> bool:
	return _curr.get(action, false) and not _prev.get(action, false)

func is_just_released(action: StringName) -> bool:
	return not _curr.get(action, false) and _prev.get(action, false)

func get_move() -> Vector2:
	var x := (1.0 if is_pressed(&"move_right") else 0.0) - (1.0 if is_pressed(&"move_left") else 0.0)
	var y := (1.0 if is_pressed(&"move_down") else 0.0) - (1.0 if is_pressed(&"move_up") else 0.0)
	return Vector2(x, y)

func _raw_pressed(action: StringName) -> bool:
	if device < 0:
		return _keyboard_pressed(action)
	return _pad_pressed(action)

func _keyboard_pressed(action: StringName) -> bool:
	if _KEYS.has(action) and Input.is_physical_key_pressed(_KEYS[action]):
		return true
	if _MOUSE.has(action) and Input.is_mouse_button_pressed(_MOUSE[action]):
		return true
	return false

func _pad_pressed(action: StringName) -> bool:
	match action:
		&"move_left": return Input.get_joy_axis(device, JOY_AXIS_LEFT_X) < -_STICK_DEADZONE or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
		&"move_right": return Input.get_joy_axis(device, JOY_AXIS_LEFT_X) > _STICK_DEADZONE or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
		&"move_up": return Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) < -_STICK_DEADZONE
		&"move_down": return Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) > _STICK_DEADZONE
		&"ultimate": return Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	if _PAD_BTN.has(action):
		return Input.is_joy_button_pressed(device, _PAD_BTN[action])
	return false
