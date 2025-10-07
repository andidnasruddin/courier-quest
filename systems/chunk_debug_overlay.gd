## Chunk Debug Overlay
##
## Renders outlines for loaded chunks and camera/view bounds to help tune
## streaming parameters. Attach in test scenes; it listens to ChunkManager.

extends Node2D
class_name ChunkDebugOverlay

@export var chunk_manager_path: NodePath
@export var enabled: bool = true
@export var show_camera_bounds: bool = true
@export var show_load_keep_bounds: bool = true
@export var show_chunk_labels: bool = true
@export var toggle_keycode: int = KEY_P
@export var poi_placer_path: NodePath
@export var show_poi_cells: bool = true
@export var show_poi_accepts: bool = true
@export var show_poi_biome_rejects: bool = true

var _cm: ChunkManager
var _poi: POIPlacer
var _wg: WorldGenerator
var _loaded: Dictionary = {} # Vector2i -> true


func _ready() -> void:
	if chunk_manager_path != NodePath(""):
		_cm = get_node_or_null(chunk_manager_path) as ChunkManager
	if _cm:
		_cm.chunk_loaded.connect(_on_chunk_loaded)
		_cm.chunk_unloaded.connect(_on_chunk_unloaded)
		# Seed with any already-loaded chunks
		for cc in _cm._loaded_chunks.keys():
			_loaded[cc] = true
		queue_redraw()
	if poi_placer_path != NodePath(""):
		_poi = get_node_or_null(poi_placer_path) as POIPlacer
		if _poi and _poi.world_generator_path != NodePath(""):
			_wg = _poi.get_node_or_null(_poi.world_generator_path) as WorldGenerator


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ek := event as InputEventKey
		if ek.pressed and not ek.echo and ek.keycode == toggle_keycode:
			enabled = not enabled
			queue_redraw()


func _on_chunk_loaded(coord: Vector2i, _node: Node2D) -> void:
	_loaded[coord] = true
	queue_redraw()


func _on_chunk_unloaded(coord: Vector2i) -> void:
	_loaded.erase(coord)
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return

	var size := Vector2(ChunkManager.CHUNK_SIZE, ChunkManager.CHUNK_SIZE)
	var outline_color := Color(0.2, 0.7, 1.0, 0.9)
	var fill_color := Color(0.2, 0.7, 1.0, 0.08)

	# Draw each loaded chunk (filled + outline)
	for cc in _loaded.keys():
		var origin := _cm.chunk_to_world(cc)
		draw_rect(Rect2(origin, size), fill_color, true)
		draw_rect(Rect2(origin, size), outline_color, false, 2.0)
		if show_chunk_labels:
			var font := ThemeDB.fallback_font
			var font_size := ThemeDB.fallback_font_size
			if font:
				draw_string(font, origin + Vector2(6, 18), "(%d,%d)" % [cc.x, cc.y], HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1,1,1,0.9))

	if show_camera_bounds:
		_draw_camera_bounds()

	if show_load_keep_bounds:
		_draw_load_keep_bounds()

	if show_poi_cells:
		_draw_poi_cells()


func _get_cam_and_rect() -> Dictionary:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return {}
	var vp := get_viewport_rect().size
	var center := cam.get_screen_center_position()
	var half := Vector2(vp.x * 0.5 * cam.zoom.x, vp.y * 0.5 * cam.zoom.y)
	return {
		"cam": cam,
		"min": center - half,
		"max": center + half
	}


func _draw_camera_bounds() -> void:
	var info := _get_cam_and_rect()
	if info.is_empty():
		return
	var minw: Vector2 = info.min
	var maxw: Vector2 = info.max
	var rect := Rect2(minw, maxw - minw)
	draw_rect(rect, Color(0,1,0,0.0), false, 2.0) # visible rect outline in green


func _draw_load_keep_bounds() -> void:
	if not _cm:
		return
	var info := _get_cam_and_rect()
	if info.is_empty():
		return
	var minw: Vector2 = info.min
	var maxw: Vector2 = info.max
	var min_cc: Vector2i = _cm.world_to_chunk(minw)
	var max_cc: Vector2i = _cm.world_to_chunk(maxw)

	var load_min := Vector2i(min_cc.x - _cm.preload_margin_chunks, min_cc.y - _cm.preload_margin_chunks)
	var load_max := Vector2i(max_cc.x + _cm.preload_margin_chunks, max_cc.y + _cm.preload_margin_chunks)
	var keep_min := Vector2i(min_cc.x - _cm.unload_margin_chunks, min_cc.y - _cm.unload_margin_chunks)
	var keep_max := Vector2i(max_cc.x + _cm.unload_margin_chunks, max_cc.y + _cm.unload_margin_chunks)

	# Draw load bounds in cyan, keep bounds in orange
	var load_rect := Rect2(_cm.chunk_to_world(load_min), Vector2(ChunkManager.CHUNK_SIZE * float(load_max.x - load_min.x + 1), ChunkManager.CHUNK_SIZE * float(load_max.y - load_min.y + 1)))
	var keep_rect := Rect2(_cm.chunk_to_world(keep_min), Vector2(ChunkManager.CHUNK_SIZE * float(keep_max.x - keep_min.x + 1), ChunkManager.CHUNK_SIZE * float(keep_max.y - keep_min.y + 1)))

	draw_rect(load_rect, Color(0.1, 0.9, 1.0, 0.0), false, 2.0)
	draw_rect(keep_rect, Color(1.0, 0.6, 0.1, 0.0), false, 2.0)


func _draw_poi_cells() -> void:
	if not _poi:
		return
	var info := _get_cam_and_rect()
	if info.is_empty():
		return
	var minw: Vector2 = info.min
	var maxw: Vector2 = info.max
	var rect := Rect2(minw, maxw - minw)

	# Draw for each configured POI type
	var types: Array = []
	if _poi.settlement_poi:
		types.append(_poi.settlement_poi)
	if _poi.gas_station_poi:
		types.append(_poi.gas_station_poi)

	for poi in types:
		var cell: int = max(1, poi.cell_size_pixels)
		var min_cx := floori(rect.position.x / cell)
		var min_cy := floori(rect.position.y / cell)
		var max_cx := floori((rect.position.x + rect.size.x - 1.0) / cell)
		var max_cy := floori((rect.position.y + rect.size.y - 1.0) / cell)

		for cy in range(min_cy, max_cy + 1):
			for cx in range(min_cx, max_cx + 1):
				var cell_origin := Vector2(cx * cell, cy * cell)
				var cell_rect := Rect2(cell_origin, Vector2(cell, cell))
				# Outline the cell grid
				draw_rect(cell_rect, Color(0.7, 0.7, 0.7, 0.1), false, 1.0)
				if show_poi_accepts:
					var accepted := _poi__should_spawn_cell(poi, cx, cy)
					if accepted:
						# Mark jittered position and biome outcome
						var pos := _poi__jittered_position(poi, cell_origin, cell, cx, cy)
						var allowed := true
						if poi.allowed_biomes.size() > 0 and _wg:
							var biome := _wg.get_biome_at_world(pos)
							allowed = biome and poi.allowed_biomes.has(biome.biome_name)
						if allowed:
							draw_circle(pos, 5.0, Color(0.2, 1.0, 0.2, 0.95))
							draw_rect(cell_rect, Color(0.2, 1.0, 0.2, 0.10), true)
						elif show_poi_biome_rejects:
							draw_circle(pos, 5.0, Color(1.0, 0.4, 0.2, 0.95))
							draw_rect(cell_rect, Color(1.0, 0.4, 0.2, 0.08), true)


func _poi__should_spawn_cell(poi: POIData, cx: int, cy: int) -> bool:
	var h := _hash3i(_poi.seed, cx, cy)
	var r := float(h & 0xFFFF) / 65535.0
	return r <= clamp(poi.spawn_chance, 0.0, 1.0)


func _poi__jittered_position(poi: POIData, cell_origin: Vector2, cell_size: int, cx: int, cy: int) -> Vector2:
	var hx := _hash3i(_poi.seed ^ 0x9E3779, cx, cy)
	var hy := _hash3i(_poi.seed ^ 0x85EBCA, cy, cx)
	var jx := float(hx & 0xFFFF) / 65535.0
	var jy := float(hy & 0xFFFF) / 65535.0
	return cell_origin + Vector2(jx * (cell_size - 1), jy * (cell_size - 1))


static func _hash3i(a: int, b: int, c: int) -> int:
	var x: int = a * 73856093
	var y: int = b * 19349663
	var z: int = c * 83492791
	var h: int = x ^ y ^ z
	h ^= (h >> 13)
	h *= 1274126177
	h ^= (h >> 16)
	return abs(h)
