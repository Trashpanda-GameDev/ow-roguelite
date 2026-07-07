class_name HitboxFactory
extends RefCounted
## Builds HitboxComponents from a config dict so abilities/effects stay concise.
## Handles collision setup, an optional visual, and lifetime auto-free.

## cfg keys (all optional except where noted):
##   damage, knockback, knockback_dir, source, team, layer, mask,
##   can_hit_self, grants_ult_charge, one_shot, monitoring, monitorable,
##   lifetime (0 = permanent), visual_color (Color), flash (bool = fade out)
static func spawn(parent: Node, at: Vector2, shape: Shape2D, cfg: Dictionary) -> HitboxComponent:
	if parent == null:
		return null
	var hb := HitboxComponent.new()
	hb.damage = cfg.get("damage", 0.0)
	hb.knockback = cfg.get("knockback", 0.0)
	hb.knockback_dir = cfg.get("knockback_dir", Vector2.ZERO)
	hb.source = cfg.get("source", null)
	hb.team = cfg.get("team", -1)
	hb.can_hit_self = cfg.get("can_hit_self", false)
	hb.grants_ult_charge = cfg.get("grants_ult_charge", true)
	hb.one_shot = cfg.get("one_shot", false)
	hb.collision_layer = cfg.get("layer", 1 << 3) # player_hitbox
	hb.collision_mask = cfg.get("mask", 0)
	hb.monitoring = cfg.get("monitoring", false)
	hb.monitorable = cfg.get("monitorable", true)

	var cs := CollisionShape2D.new()
	cs.shape = shape
	hb.add_child(cs)

	parent.add_child(hb)
	hb.global_position = at

	# After parenting so create_tween() has a valid tree.
	if cfg.has("visual_color"):
		_add_visual(hb, shape, cfg.get("visual_color"), cfg.get("flash", false), cfg.get("lifetime", 0.0))

	var life: float = cfg.get("lifetime", 0.0)
	if life > 0.0:
		hb.get_tree().create_timer(life).timeout.connect(func(): if is_instance_valid(hb): hb.queue_free())
	return hb

static func _add_visual(hb: HitboxComponent, shape: Shape2D, color: Color, flash: bool, lifetime: float) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	if shape is RectangleShape2D:
		var h := (shape as RectangleShape2D).size * 0.5
		poly.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		var pts := PackedVector2Array()
		for i in 24:
			pts.append(Vector2(cos(TAU * i / 24.0), sin(TAU * i / 24.0)) * r)
		poly.polygon = pts
	hb.add_child(poly)
	if flash and lifetime > 0.0:
		hb.create_tween().tween_property(poly, "color:a", 0.0, lifetime).from(color.a)
