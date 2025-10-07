extends Resource
class_name POIData

enum Type { SETTLEMENT, GAS_STATION }

@export var poi_name: String = "POI"
@export var poi_type: Type = Type.SETTLEMENT
@export var scene_path: String = ""
@export var min_distance_between: float = 0.0  # pixels
@export var allowed_biomes: PackedStringArray = []
@export var cell_size_pixels: int = 100000
@export_range(0.0,1.0) var spawn_chance: float = 1.0
