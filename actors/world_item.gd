## WorldItem
##
## Represents a physical item dropped in the world.
## Players can interact with it to pick it up.

extends Area2D
class_name WorldItem

signal picked_up(item_data: ItemData, quantity: int)

@export var item_data: ItemData = null
@export var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	# Add to interactable group
	add_to_group("interactable")
	add_to_group("world_items")

	# Set collision layers - must be on layer 2 for InteractionComponent to detect
	collision_layer = 2  # Interactable layer
	collision_mask = 0   # Doesn't collide with anything

	# Update visuals
	_update_visuals()

func _update_visuals() -> void:
	if not item_data:
		return

	# Set sprite from ItemData (use world_icon if available, otherwise use inventory icon)
	if sprite:
		var texture: Texture2D = item_data.world_icon if item_data.world_icon else item_data.icon
		if texture:
			sprite.texture = texture
		else:
			# No texture, use colored placeholder
			sprite.modulate = Color(0.8, 0.8, 0.2)  # Yellow tint

	# Set label
	if label:
		if quantity > 1:
			label.text = "%s (x%d)" % [item_data.item_name, quantity]
		else:
			label.text = item_data.item_name

func get_interaction_type() -> String:
	return "world_item"

func get_item_data() -> ItemData:
	return item_data

func get_quantity() -> int:
	return quantity

func pickup() -> void:
	picked_up.emit(item_data, quantity)
	queue_free()

## Factory method to create a WorldItem from ItemData
static func create_at_position(data: ItemData, qty: int, pos: Vector2) -> WorldItem:
	var scene: PackedScene = load("res://actors/world_item.tscn")
	if not scene:
		push_error("[WorldItem] Failed to load world_item.tscn")
		return null

	var item: WorldItem = scene.instantiate()
	item.item_data = data
	item.quantity = qty
	item.global_position = pos
	return item
