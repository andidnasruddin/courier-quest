## World Generator
##
## Listens to ChunkManager for load/unload events and paints chunks based on
## biome noise. Provides simple biome selection (Wasteland vs Radioactive) for MVP.

extends Node
class_name WorldGenerator

signal biome_painted(chunk_coord: Vector2i, biome: BiomeData)

@export var chunk_manager_path: NodePath
@export var seed: int = 1337
@export var biome_wasteland: BiomeData
@export var biome_radioactive: BiomeData
@export_range(0.000001, 0.01, 0.000001) var biome_noise_frequency: float = 0.004
@export_range(0.0, 1.0, 0.01) var biome_threshold: float = 0.6

var _chunk_manager: ChunkManager
var _noise: FastNoiseLite


func _ready() -> void:
	if chunk_manager_path != NodePath(""):
		_chunk_manager = get_node_or_null(chunk_manager_path) as ChunkManager
	if _chunk_manager:
		_chunk_manager.chunk_loaded.connect(_on_chunk_loaded)
		_chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)

	_noise = FastNoiseLite.new()
	_noise.seed = seed
	_noise.frequency = biome_noise_frequency
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


func _on_chunk_loaded(chunk_coord: Vector2i, chunk_node: Node2D) -> void:
	var biome := _select_biome(chunk_coord)
	_paint_chunk(chunk_node, biome)
	biome_painted.emit(chunk_coord, biome)


func _on_chunk_unloaded(_chunk_coord: Vector2i) -> void:
	# Nothing yet; if pooling, clear decorations here
	pass


func _select_biome(chunk_coord: Vector2i) -> BiomeData:
	# Use noise at the center of the chunk
	var world_center := Vector2(
		(chunk_coord.x + 0.5) * ChunkManager.CHUNK_SIZE,
		(chunk_coord.y + 0.5) * ChunkManager.CHUNK_SIZE
	)
	var n := _noise.get_noise_2d(world_center.x, world_center.y) # -1..1
	# Map to 0..1 and threshold per exported property
	var t := (n + 1.0) * 0.5
	if t <= biome_threshold:
		return biome_wasteland
	return biome_radioactive


func get_biome_at_world(world_pos: Vector2) -> BiomeData:
	if not _noise:
		return biome_wasteland
	var n := _noise.get_noise_2d(world_pos.x, world_pos.y)
	var t := (n + 1.0) * 0.5
	if t <= biome_threshold:
		return biome_wasteland
	return biome_radioactive


func _paint_chunk(chunk_node: Node2D, biome: BiomeData) -> void:
	if not chunk_node or not biome:
		return
	# Expect first child Polygon2D per ChunkManager implementation
	for child in chunk_node.get_children():
		if child is Polygon2D:
			var poly := child as Polygon2D
			poly.color = biome.ground_color
			return
