class_name HealthBar
extends Node2D
## Floating health bar shown above an entity. Auto-finds a HealthComponent in
## its parent (or set one explicitly) and tracks it. Reusable on any entity.

@export var health: HealthComponent
@export var bar_size: Vector2 = Vector2(64, 8)
@export var show_text: bool = true

var _fill: ColorRect
var _label: Label

func _ready() -> void:
	if health == null:
		health = _find_health()
	_build()
	if health:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)

func _find_health() -> HealthComponent:
	var root: Node = get_parent()
	if root == null:
		return null
	for c in root.find_children("*", "HealthComponent", true, false):
		return c
	return null

func _build() -> void:
	var origin := -bar_size * 0.5
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.position = origin - Vector2(1, 1)
	bg.size = bar_size + Vector2(2, 2)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_fill = ColorRect.new()
	_fill.color = Color(0.3, 0.85, 0.35, 1)
	_fill.position = origin
	_fill.size = bar_size
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	if show_text:
		_label = Label.new()
		_label.add_theme_font_size_override(&"font_size", 12)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size = Vector2(bar_size.x + 40.0, 16)
		_label.position = Vector2(-(bar_size.x + 40.0) * 0.5, origin.y - 18.0)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)

func _on_health_changed(current: float, maximum: float) -> void:
	var frac := current / maximum if maximum > 0.0 else 0.0
	_fill.size.x = bar_size.x * clampf(frac, 0.0, 1.0)
	_fill.color = Color(0.85, 0.3, 0.3, 1) if frac < 0.3 else Color(0.3, 0.85, 0.35, 1)
	if _label:
		_label.text = "%d / %d" % [ceili(current), ceili(maximum)]
