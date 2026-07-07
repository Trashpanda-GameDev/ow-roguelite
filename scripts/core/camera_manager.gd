class_name CameraManager
extends Node
## Handles cameras for local multiplayer. Two modes:
##  - Shared: one Camera2D that frames (and zooms to fit) all living players.
##  - Split:  a SubViewport per player, tiled on screen, each following a player.
## Call setup(split) after players are spawned. get_view_rect(i) returns the
## screen region for player i (for placing per-player HUDs).

@export var margin: Vector2 = Vector2(360, 260) ## padding around players (shared)
@export var min_zoom: float = 0.35
@export var max_zoom: float = 1.2
@export var smooth: float = 8.0
@export var split_zoom: float = 1.0

var _shared_cam: Camera2D
var _split_layer: CanvasLayer
var _views: Array = [] # split: [{cam, svc, player, rect}]

func setup(split: bool) -> void:
	_clear()
	if split and Players.players.size() > 1:
		_setup_split()
	else:
		_setup_shared()

func _clear() -> void:
	if _shared_cam:
		_shared_cam.queue_free()
		_shared_cam = null
	if _split_layer:
		_split_layer.queue_free()
		_split_layer = null
	_views.clear()

# --- Shared ---
func _setup_shared() -> void:
	_shared_cam = Camera2D.new()
	add_child(_shared_cam)
	_shared_cam.make_current()
	var pts := _alive_points()
	if not pts.is_empty():
		_shared_cam.global_position = pts[0]

func _alive_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in Players.alive_players():
		out.append((p as Node2D).global_position)
	return out

# --- Split ---
func _setup_split() -> void:
	_split_layer = CanvasLayer.new()
	add_child(_split_layer)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_split_layer.add_child(bg)

	var players := Players.players
	var rects := _grid_rects(players.size())
	var world := get_viewport().world_2d
	for i in players.size():
		var svc := SubViewportContainer.new()
		svc.stretch = true
		svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sv := SubViewport.new()
		sv.world_2d = world
		sv.handle_input_locally = false
		var cam := Camera2D.new()
		cam.zoom = Vector2(split_zoom, split_zoom)
		sv.add_child(cam)
		svc.add_child(sv)
		_split_layer.add_child(svc)
		cam.make_current()
		_views.append({"cam": cam, "svc": svc, "player": players[i], "rect": rects[i]})
	_layout_split()

func _grid_rects(n: int) -> Array[Rect2]:
	if n <= 1:
		return [Rect2(0, 0, 1, 1)]
	if n == 2:
		return [Rect2(0, 0, 0.5, 1), Rect2(0.5, 0, 0.5, 1)]
	# 3-4 players: quadrants
	var quads: Array[Rect2] = [
		Rect2(0, 0, 0.5, 0.5), Rect2(0.5, 0, 0.5, 0.5),
		Rect2(0, 0.5, 0.5, 0.5), Rect2(0.5, 0.5, 0.5, 0.5),
	]
	return quads.slice(0, n)

func _layout_split() -> void:
	var screen := get_viewport().get_visible_rect().size
	for v in _views:
		var r: Rect2 = v["rect"]
		v["svc"].position = r.position * screen
		v["svc"].size = r.size * screen

func _process(delta: float) -> void:
	if _shared_cam:
		_update_shared(delta)
	elif not _views.is_empty():
		_layout_split()
		_update_split(delta)

func _update_shared(delta: float) -> void:
	var pts := _alive_points()
	if pts.is_empty():
		return
	var min_p := pts[0]
	var max_p := pts[0]
	for p in pts:
		min_p.x = minf(min_p.x, p.x); min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x); max_p.y = maxf(max_p.y, p.y)
	var center := (min_p + max_p) * 0.5
	var span := (max_p - min_p) + margin * 2.0
	var vp := get_viewport().get_visible_rect().size
	var z := minf(vp.x / maxf(span.x, 1.0), vp.y / maxf(span.y, 1.0))
	z = clampf(z, min_zoom, max_zoom)
	var t := 1.0 - exp(-smooth * delta)
	_shared_cam.global_position = _shared_cam.global_position.lerp(center, t)
	_shared_cam.zoom = _shared_cam.zoom.lerp(Vector2(z, z), t)

func _update_split(delta: float) -> void:
	var t := 1.0 - exp(-smooth * delta)
	for v in _views:
		if is_instance_valid(v["player"]):
			var cam: Camera2D = v["cam"]
			cam.global_position = cam.global_position.lerp((v["player"] as Node2D).global_position, t)

## Screen-space rect (pixels) of player i's view — for HUD placement.
func get_view_rect(index: int) -> Rect2:
	var screen := get_viewport().get_visible_rect().size
	if _views.is_empty():
		return Rect2(Vector2.ZERO, screen)
	var r: Rect2 = _views[index % _views.size()]["rect"]
	return Rect2(r.position * screen, r.size * screen)
