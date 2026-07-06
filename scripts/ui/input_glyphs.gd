class_name InputGlyphs
extends RefCounted
## Shared helper to turn an input action into a human-readable button name for
## the current device (keyboard/mouse or the connected gamepad, PS vs Xbox).

const PS_BUTTONS := {
	0: "Cross", 1: "Circle", 2: "Square", 3: "Triangle",
	4: "Create", 5: "PS", 6: "Options", 7: "L3", 8: "R3",
	9: "L1", 10: "R1", 11: "D-Pad Up", 12: "D-Pad Down",
	13: "D-Pad Left", 14: "D-Pad Right",
}
const XBOX_BUTTONS := {
	0: "A", 1: "B", 2: "X", 3: "Y",
	4: "View", 5: "Guide", 6: "Menu", 7: "LS", 8: "RS",
	9: "LB", 10: "RB", 11: "D-Pad Up", 12: "D-Pad Down",
	13: "D-Pad Left", 14: "D-Pad Right",
}

## Best binding for `action` on the current device ("" if none).
static func binding_text(action: StringName, use_gamepad: bool) -> String:
	for event in InputMap.action_get_events(action):
		if _matches_device(event, use_gamepad):
			return event_text(event, use_gamepad)
	return ""

static func _matches_device(event: InputEvent, use_gamepad: bool) -> bool:
	if use_gamepad:
		return event is InputEventJoypadButton or event is InputEventJoypadMotion
	return event is InputEventKey or event is InputEventMouseButton

static func event_text(event: InputEvent, use_gamepad: bool) -> String:
	if event is InputEventKey:
		var k := event as InputEventKey
		return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode))
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			_: return "Mouse %d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		return _button_map().get((event as InputEventJoypadButton).button_index, "Button %d" % (event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		return _axis_text(event as InputEventJoypadMotion)
	return ""

static func _axis_text(motion: InputEventJoypadMotion) -> String:
	var ps := is_playstation()
	match motion.axis:
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return "Left Stick"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: return "Right Stick"
		JOY_AXIS_TRIGGER_LEFT: return "L2" if ps else "LT"
		JOY_AXIS_TRIGGER_RIGHT: return "R2" if ps else "RT"
		_: return "Axis %d" % motion.axis

static func _button_map() -> Dictionary:
	return PS_BUTTONS if is_playstation() else XBOX_BUTTONS

static func is_playstation() -> bool:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return true # default to PS labels for this project
	var joy_name := Input.get_joy_name(pads[0]).to_lower()
	for tag in ["sony", "playstation", "dualsense", "dualshock", "ps5", "ps4", "ps3"]:
		if joy_name.contains(tag):
			return true
	return false
