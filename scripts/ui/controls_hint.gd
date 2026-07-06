extends Label
## Top-left list of the non-ability controls (movement / system). Ability
## buttons live on the cooldown HUD (bottom-right) instead. Rebuilds when the
## active input device changes.

# Rows to display: [label, action]. "Move" is special-cased to merge L/R.
const ROWS := [
	["Move", &"move_left"], # special-cased
	["Jump", &"jump"],
	["Interact", &"interact"],
	["Pause", &"pause"],
]

var _use_gamepad: bool = false

func _ready() -> void:
	_use_gamepad = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(func(_d, _c): _rebuild())
	_rebuild()

func _input(event: InputEvent) -> void:
	var was := _use_gamepad
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_use_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_use_gamepad = false
	if was != _use_gamepad:
		_rebuild()

func _rebuild() -> void:
	var parts: PackedStringArray = []
	for row in ROWS:
		var binding := _binding_text(row[1])
		if binding != "":
			parts.append("%s: %s" % [row[0], binding])
	var lines: PackedStringArray = []
	for i in range(0, parts.size(), 2):
		var line := parts[i]
		if i + 1 < parts.size():
			line += "     " + parts[i + 1]
		lines.append(line)
	text = "\n".join(lines)

func _binding_text(action: StringName) -> String:
	if action == &"move_left":
		if _use_gamepad:
			return "Left Stick"
		var l := InputGlyphs.binding_text(&"move_left", false)
		var r := InputGlyphs.binding_text(&"move_right", false)
		return "%s / %s" % [l, r] if l != "" and r != "" else l + r
	return InputGlyphs.binding_text(action, _use_gamepad)
