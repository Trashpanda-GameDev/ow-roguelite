extends VBoxContainer
## Top-center banner: current hero name with a small hint on how to swap.

var _name_lbl: Label
var _hint_lbl: Label

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_size_override(&"font_size", 26)
	add_child(_name_lbl)
	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override(&"font_size", 12)
	_hint_lbl.modulate = Color(1, 1, 1, 0.6)
	_hint_lbl.text = "Press 1 / 2 to swap character"
	add_child(_hint_lbl)

	EventBus.player_spawned.connect(_on_player_spawned)
	var existing := get_tree().get_first_node_in_group(&"player")
	if existing and "hero" in existing and existing.hero:
		_set_hero(existing.hero)

func _on_player_spawned(player: Node) -> void:
	if "hero" in player and player.hero:
		_set_hero(player.hero)

func _set_hero(hero: Hero) -> void:
	_name_lbl.text = hero.display_name
