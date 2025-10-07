extends Resource
class_name ItemData

## Core Properties
@export var item_id: String = ""  # Unique ID for stacking/save
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D  # Icon shown in inventory UI
@export var world_icon: Texture2D  # Icon/sprite shown when dropped in world (if null, uses icon)

## Grid & Stacking
@export var grid_size: Vector2i = Vector2i(1, 1)  # width x height in grid cells
@export var weight: float = 0.5  # kg
@export var stackable: bool = false  # Can this item stack?
@export var max_stack: int = 1  # Maximum stack size (1 = no stacking)

## Classification (used for hotbar restrictions)
@export_enum("Weapon", "Consumable", "Ammo", "Equipment", "Throwable", "Cargo", "Misc") var item_type: String = "Misc"
