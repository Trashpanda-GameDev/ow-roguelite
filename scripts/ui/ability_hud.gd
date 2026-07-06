extends HBoxContainer
## Bottom-right cooldown HUD: one tile per equipped ability showing the button
## to press, the ability name, and its cooldown / charges / ammo / ult charge.

const ACTION_BY_SLOT := {
	Ability.Slot.PRIMARY: &"attack_primary",
	Ability.Slot.SECONDARY: &"attack_secondary",
	Ability.Slot.DASH: &"dash",
	Ability.Slot.ABILITY_1: &"ability_1",
	Ability.Slot.ABILITY_2: &"ability_2",
	Ability.Slot.ULTIMATE: &"ultimate",
}
# Display order (left to right).
const ORDER := [
	Ability.Slot.PRIMARY, Ability.Slot.SECONDARY, Ability.Slot.DASH,
	Ability.Slot.ABILITY_1, Ability.Slot.ABILITY_2, Ability.Slot.ULTIMATE,
]

var _hero: Hero
var _controller: AbilityController
var _tiles := {} # slot -> {fill, button, status}
var _use_gamepad: bool = false

func _ready() -> void:
	add_theme_constant_override(&"separation", 8)
	_use_gamepad = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(func(_d, _c): _refresh_bindings())
	EventBus.player_spawned.connect(_on_player_spawned)
	var existing := get_tree().get_first_node_in_group(&"player")
	if existing:
		_bind(existing)

func _input(event: InputEvent) -> void:
	var was := _use_gamepad
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_use_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_use_gamepad = false
	if was != _use_gamepad:
		_refresh_bindings()

func _on_player_spawned(player: Node) -> void:
	_bind(player)

func _bind(player: Node) -> void:
	_hero = player.hero if "hero" in player else null
	_controller = player.abilities if "abilities" in player else null
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_tiles.clear()
	if _hero == null:
		return
	for slot in ORDER:
		var ability: Ability = _hero.get_ability(slot)
		if ability == null:
			continue
		_tiles[slot] = _make_tile(ability.display_name)
	_refresh_bindings()

func _make_tile(ability_name: String) -> Dictionary:
	var root := Control.new()
	root.custom_minimum_size = Vector2(92, 76)
	add_child(root)

	var back := ColorRect.new()
	back.color = Color(0.12, 0.13, 0.18, 0.85)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)
	var fill := ColorRect.new()
	fill.color = Color(0.3, 0.55, 0.9, 0.75)
	fill.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vb)

	var button := Label.new()
	button.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override(&"font_size", 16)
	vb.add_child(button)
	var name_lbl := Label.new()
	name_lbl.text = ability_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override(&"font_size", 11)
	name_lbl.modulate = Color(1, 1, 1, 0.7)
	vb.add_child(name_lbl)
	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override(&"font_size", 12)
	vb.add_child(status)

	return {"fill": fill, "button": button, "status": status}

## Update the button-name labels for the current input device.
func _refresh_bindings() -> void:
	for slot in _tiles:
		var binding := InputGlyphs.binding_text(ACTION_BY_SLOT[slot], _use_gamepad)
		(_tiles[slot]["button"] as Label).text = binding if binding != "" else "-"

func _process(_delta: float) -> void:
	if _controller == null or _hero == null:
		return
	for slot in _tiles:
		_update_tile(slot)

func _update_tile(slot: Ability.Slot) -> void:
	var ability: Ability = _hero.get_ability(slot)
	var tile: Dictionary = _tiles[slot]
	var ready_ratio := 1.0 # 1 = fully usable
	var status := "Ready"
	var color := Color(0.3, 0.55, 0.9, 0.75)

	if ability.is_ultimate:
		ready_ratio = _controller.ult_charge_fraction()
		status = "ULT" if ready_ratio >= 1.0 else "%d%%" % int(ready_ratio * 100.0)
		color = Color(0.95, 0.75, 0.2, 0.8)
	elif ability.max_charges > 0:
		var charges := _controller.charges_count(slot)
		status = "%d/%d" % [charges, ability.max_charges]
		ready_ratio = 1.0 if charges >= ability.max_charges else _controller.charge_recharge_fraction(slot)
		color = Color(0.4, 0.8, 0.95, 0.8)
	elif ability.max_ammo > 0:
		var reload := _controller.reload_fraction(slot)
		if reload > 0.0:
			ready_ratio = 1.0 - reload
			status = "reload"
			color = Color(0.9, 0.4, 0.2, 0.8)
		else:
			ready_ratio = 1.0
			status = "%d/%d" % [_controller.ammo_count(slot), ability.max_ammo]
	else:
		var cd := _controller.cooldown_fraction(slot)
		ready_ratio = 1.0 - cd
		status = "Ready" if cd <= 0.0 else "%.1f" % _controller.cooldown_remaining(slot)

	var fill: ColorRect = tile["fill"]
	fill.color = color
	fill.anchor_top = 1.0 - clampf(ready_ratio, 0.0, 1.0)
	(tile["status"] as Label).text = status
