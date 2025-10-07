## Chunk Manager
##
## Loads/unloads world chunks around the player. Emits signals when chunks
## are created or removed so other systems (WorldGenerator, POIs) can populate
## and clean up. Chebyshev distance is used for square load grids.

extends Node2D
class_name ChunkManager

signal chunk_loaded(chunk_coord: Vector2i, chunk_node: Node2D)
signal chunk_unloaded(chunk_coord: Vector2i)

const CHUNK_SIZE: int = 1024   # Def: 512
const LOAD_RADIUS: int = 3      # Fallback radius (player-centered)
const UNLOAD_RADIUS: int = 4    # Fallback unload radius

@export var player_path: NodePath
@export var track_active_camera: bool = true
@export var camera_path: NodePath
@export var preload_margin_chunks: int = 1
@export var unload_margin_chunks: int = 2

var _player: Node2D = null
var _loaded_chunks: Dictionary = {}            # Vector2i -> Node2D
var _chunk_pool: Array[Node2D] = []            # Optional pooling of chunk nodes
var _camera: Camera2D = null


func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path) as Node2D
	if camera_path != NodePath(""):
		_camera = get_node_or_null(camera_path) as Camera2D


func _process(_delta: float) -> void:
	if track_active_camera:
		_update_by_camera()
	else:
		if not _player:
			return
		_update_visible_chunks(_player.global_position)


func _get_active_camera() -> Camera2D:
	if _camera:
		return _camera
	return get_viewport().get_camera_2d()


func _update_by_camera() -> void:
	var cam := _get_active_camera()
	if not cam:
		if _player:
			_update_visible_chunks(_player.global_position)
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = cam.get_screen_center_position()
	var half_size: Vector2 = Vector2(vp_size.x * 0.5 * cam.zoom.x, vp_size.y * 0.5 * cam.zoom.y)
	var min_world: Vector2 = center - half_size
	var max_world: Vector2 = center + half_size

	var min_chunk: Vector2i = world_to_chunk(min_world)
	var max_chunk: Vector2i = world_to_chunk(max_world)

	var load_min := Vector2i(min_chunk.x - preload_margin_chunks, min_chunk.y - preload_margin_chunks)
	var load_max := Vector2i(max_chunk.x + preload_margin_chunks, max_chunk.y + preload_margin_chunks)
	var keep_min := Vector2i(min_chunk.x - unload_margin_chunks, min_chunk.y - unload_margin_chunks)
	var keep_max := Vector2i(max_chunk.x + unload_margin_chunks, max_chunk.y + unload_margin_chunks)

	var desired_load := _build_chunk_set(load_min, load_max)
	var desired_keep := _build_chunk_set(keep_min, keep_max)

	_apply_chunk_sets(desired_load, desired_keep)


func _build_chunk_set(min_cc: Vector2i, max_cc: Vector2i) -> Dictionary:
	var set: Dictionary = {}
	for y in range(min_cc.y, max_cc.y + 1):
		for x in range(min_cc.x, max_cc.x + 1):
			set[Vector2i(x, y)] = true
	return set


func _apply_chunk_sets(desired_load: Dictionary, desired_keep: Dictionary) -> void:
	# Load missing
	for coord in desired_load.keys():
		if not _loaded_chunks.has(coord):
			var node: Node2D = _obtain_chunk_node()
			node.name = "Chunk_%d_%d" % [coord.x, coord.y]
			node.position = chunk_to_world(coord)
			add_child(node)
			_loaded_chunks[coord] = node
			chunk_loaded.emit(coord, node)

	# Unload those not in keep set
	var to_remove: Array[Vector2i] = []
	for existing_coord in _loaded_chunks.keys():
		if not desired_keep.has(existing_coord):
			to_remove.append(existing_coord)

	for rc in to_remove:
		var chunk: Node2D = _loaded_chunks[rc] as Node2D
		_loaded_chunks.erase(rc)
		chunk_unloaded.emit(rc)
		_release_chunk_node(chunk)



func _update_visible_chunks(center_world_pos: Vector2) -> void:
	var center_coord: Vector2i = world_to_chunk(center_world_pos)

	# Determine desired set
	var desired: Dictionary = {}
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var cc := Vector2i(center_coord.x + dx, center_coord.y + dy)
			desired[cc] = true

	# Load missing chunks
	for coord in desired.keys():
		if not _loaded_chunks.has(coord):
			var node: Node2D = _obtain_chunk_node()
			node.name = "Chunk_%d_%d" % [coord.x, coord.y]
			node.position = chunk_to_world(coord)
			add_child(node)
			_loaded_chunks[coord] = node
			chunk_loaded.emit(coord, node)

	# Unload chunks beyond UNLOAD_RADIUS
	var to_remove: Array[Vector2i] = []
	for existing_coord in _loaded_chunks.keys():
		var dx: int = abs(existing_coord.x - center_coord.x)
		var dy: int = abs(existing_coord.y - center_coord.y)
		if max(dx, dy) > UNLOAD_RADIUS:
			to_remove.append(existing_coord)

	for rc in to_remove:
		var chunk: Node2D = _loaded_chunks[rc] as Node2D
		_loaded_chunks.erase(rc)
		chunk_unloaded.emit(rc)
		_release_chunk_node(chunk)


func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CHUNK_SIZE), floori(world_pos.y / CHUNK_SIZE))


func chunk_to_world(chunk_coord: Vector2i) -> Vector2:
	return Vector2(chunk_coord.x * CHUNK_SIZE, chunk_coord.y * CHUNK_SIZE)


func _obtain_chunk_node() -> Node2D:
	if _chunk_pool.size() > 0:
		return _chunk_pool.pop_back()
	# Minimal visual placeholder; WorldGenerator can skin it further
	var n := Node2D.new()
	# Add a child Polygon2D to visualize chunk (responds to 2D lighting)
	var poly := Polygon2D.new()
	poly.color = Color(0.15, 0.15, 0.15, 1.0) # Default dark; biome paints it
	# Ensure the polygon uses a material that participates in 2D lighting
	poly.material = CanvasItemMaterial.new()
	# Create square polygon for the chunk
	poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(CHUNK_SIZE, 0),
		Vector2(CHUNK_SIZE, CHUNK_SIZE),
		Vector2(0, CHUNK_SIZE)
	])
	n.add_child(poly)
	return n


func _release_chunk_node(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	node.queue_free() # Pooling disabled for now; can switch to hide + push to pool


func set_player(player: Node2D) -> void:
	_player = player
