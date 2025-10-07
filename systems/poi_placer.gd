## POI Placer
##
## Deterministic, seed-based POI placement using world-space grids per POI type.
## Each POI type defines a cell size (minimum spacing), spawn chance, and
## allowed biomes. Cells are jittered to produce natural positions.

extends Node
class_name POIPlacer

@export var chunk_manager_path: NodePath
@export var world_generator_path: NodePath
@export var seed: int = 1337
@export var settlement_poi: POIData
@export var gas_station_poi: POIData
@export var world_root_path: NodePath
@export_range(1.0, 50.0, 0.5) var cull_distance_km: float = 12.0

var _last_cull_time: float = 0.0

var _cm: ChunkManager
var _wg: WorldGenerator
var _loaded_pois: Array[Node2D] = []
var _world_root: Node
var _spawned_cells: Dictionary = {} # key -> Node (may be freed later)


func _ready() -> void:
	_cm = get_node_or_null(chunk_manager_path) as ChunkManager
	_wg = get_node_or_null(world_generator_path) as WorldGenerator
	_world_root = get_node_or_null(world_root_path)
	if _cm:
		_cm.chunk_loaded.connect(_on_chunk_loaded)
		_cm.chunk_unloaded.connect(_on_chunk_unloaded)
	set_process(true)


func _on_chunk_loaded(coord: Vector2i, chunk_node: Node2D) -> void:
	var origin: Vector2 = _cm.chunk_to_world(coord)
	var size: Vector2 = Vector2(ChunkManager.CHUNK_SIZE, ChunkManager.CHUNK_SIZE)
	var rect: Rect2 = Rect2(origin, size)

	# Per-type placement
	if settlement_poi:
		_place_for_type(settlement_poi, rect, chunk_node)
	if gas_station_poi:
		_place_for_type(gas_station_poi, rect, chunk_node)


func _on_chunk_unloaded(_coord: Vector2i) -> void:
	# No action needed: child nodes parented under chunk will be freed by ChunkManager
	_cleanup_invalid()
	_perform_cull_if_needed()


func _place_for_type(poi: POIData, rect: Rect2, parent_chunk: Node2D) -> void:
	var cell: int = max(1, poi.cell_size_pixels)
	var min_cell_x := floori(rect.position.x / cell)
	var min_cell_y := floori(rect.position.y / cell)
	var max_cell_x := floori((rect.position.x + rect.size.x - 1.0) / cell)
	var max_cell_y := floori((rect.position.y + rect.size.y - 1.0) / cell)

	for cy in range(min_cell_y, max_cell_y + 1):
		for cx in range(min_cell_x, max_cell_x + 1):
			var cell_origin: Vector2 = Vector2(cx * cell, cy * cell)
			if not _should_spawn_cell(poi, cx, cy):
				continue
			var pos: Vector2 = _jittered_position(cell_origin, cell, cx, cy)
			# Biome filter
			if poi.allowed_biomes.size() > 0 and _wg:
				var biome: BiomeData = _wg.get_biome_at_world(pos)
				if not (biome and poi.allowed_biomes.has(biome.biome_name)):
					continue
			# Deduplicate by cell key per POI type
			var key: String = _cell_key(poi, cx, cy)
			if not _spawned_cells.has(key):
				var node: Node2D = _spawn_poi_instance(poi, pos, parent_chunk)
				if node:
					_spawned_cells[key] = node


func _should_spawn_cell(poi: POIData, cx: int, cy: int) -> bool:
	# Hash-based probability per cell, deterministic by seed and coords
	var h := _hash3i(seed, cx, cy)
	var r := float(h & 0xFFFF) / 65535.0
	return r <= clamp(poi.spawn_chance, 0.0, 1.0)


func _jittered_position(cell_origin: Vector2, cell_size: int, cx: int, cy: int) -> Vector2:
	var hx: int = _hash3i(seed ^ 0x9E3779B1, cx, cy)
	var hy: int = _hash3i(seed ^ 0x85EBCA77, cy, cx)
	var jx: float = float(hx & 0xFFFF) / 65535.0
	var jy: float = float(hy & 0xFFFF) / 65535.0
	var offset: Vector2 = Vector2(jx * (cell_size - 1), jy * (cell_size - 1))
	return cell_origin + offset


func _generate_poi_id(poi: POIData, world_pos: Vector2) -> String:
	# Generate unique ID based on POI type and world position
	# Use cell coordinates to ensure deterministic naming
	var cell_size: int = max(1, poi.cell_size_pixels)
	var cx: int = floori(world_pos.x / cell_size)
	var cy: int = floori(world_pos.y / cell_size)

	# Generate random number from cell coords for variation
	var hash_val: int = _hash3i(seed, cx, cy)
	var poi_number: int = (hash_val % 9000) + 1000  # Range: 1000-9999

	# Create readable name based on POI type
	var poi_type_name: String = "Unknown"
	match poi.poi_type:
		POIData.Type.SETTLEMENT:
			poi_type_name = "Settlement"
		POIData.Type.GAS_STATION:
			poi_type_name = "GasStation"
		_:
			poi_type_name = "POI"

	return "%s_%d" % [poi_type_name, poi_number]


func _spawn_poi_instance(poi: POIData, world_pos: Vector2, parent_chunk: Node2D) -> Node2D:
	if poi.scene_path == "":
		return null
	var packed: Resource = load(poi.scene_path)
	if not (packed and packed is PackedScene):
		return null
	var n: Node = (packed as PackedScene).instantiate()
	if n is Node2D:
		(n as Node2D).global_position = world_pos

		# Generate unique name based on POI type and position
		var poi_id: String = _generate_poi_id(poi, world_pos)
		n.name = poi_id

		_loaded_pois.append(n)
		# Remove from list when it leaves the tree (chunk unload)
		n.tree_exited.connect(_on_poi_tree_exited.bind(n))
		# Parent under world root if provided, else under chunk
		if _world_root:
			_world_root.add_child(n)
		else:
			parent_chunk.add_child(n)
		return n
	return null


func _on_poi_tree_exited(node: Node) -> void:
	if node is Node2D:
		_loaded_pois.erase(node as Node2D)


func _cleanup_invalid() -> void:
	# Remove freed references if any
	var cleaned: Array[Node2D] = []
	for n in _loaded_pois:
		if is_instance_valid(n):
			cleaned.append(n)
	_loaded_pois = cleaned
	# Clean cell keys whose nodes are gone (no casting on potentially freed objects)
	var to_remove: Array[String] = []
	for k in _spawned_cells.keys():
		var node_val = _spawned_cells[k]
		if node_val == null or not is_instance_valid(node_val):
			to_remove.append(k)
	for k in to_remove:
		_spawned_cells.erase(k)


func get_loaded_pois() -> Array[Node2D]:
	_cleanup_invalid()
	return _loaded_pois


func _cell_key(poi: POIData, cx: int, cy: int) -> String:
	var t := int(poi.poi_type)
	return "%d:%d:%d" % [t, cx, cy]


static func _hash3i(a: int, b: int, c: int) -> int:
	# 32-bit style integer mix, stable across platforms in GDScript
	var x: int = a * 73856093
	var y: int = b * 19349663
	var z: int = c * 83492791
	var h: int = x ^ y ^ z
	h ^= (h >> 13)
	h *= 1274126177
	h ^= (h >> 16)
	return abs(h)


func _process(_delta: float) -> void:
	_perform_cull_if_needed()



func _perform_cull_if_needed() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_cull_time < 1.0:
		return
	_last_cull_time = now
	# Determine origin from active camera center
	var cam: Camera2D = get_viewport().get_camera_2d()
	var origin: Vector2 = cam.get_screen_center_position() if cam else Vector2.ZERO
	var max_dist_px: float = cull_distance_km * 10000.0
	var survivors: Array[Node2D] = []
	for n in _loaded_pois:
		if n and is_instance_valid(n):
			if origin.distance_to(n.global_position) > max_dist_px:
				n.queue_free()
			else:
				survivors.append(n)
	_loaded_pois = survivors
