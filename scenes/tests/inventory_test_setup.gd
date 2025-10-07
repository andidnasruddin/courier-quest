## Inventory Test Setup
##
## Adds test items to player inventory for demonstration purposes.
## Also generates placeholder icons for items.

extends Node

@export var player: Player
@export var medkit: ItemData
@export var ammo_box: ItemData
@export var water_bottle: ItemData
@export var delivery_package: ItemData


func _ready() -> void:
	# Wait one frame for player to initialize
	await get_tree().process_frame
	
	if not player or not player.inventory:
		push_error("InventoryTestSetup: Player or inventory component not found!")
		return
	
	# Generate placeholder icons if missing
	_setup_placeholder_icons()
	
	# Add test items
	if medkit:
		player.inventory.add_item(medkit, 1)
		print("Added medkit to inventory")
	
	if ammo_box:
		player.inventory.add_item(ammo_box, 2)
		print("Added 2 ammo boxes to inventory")
	
	if water_bottle:
		player.inventory.add_item(water_bottle, 3)
		print("Added 3 water bottles to inventory")
	
	if delivery_package:
		player.inventory.add_item(delivery_package, 1)
		print("Added delivery package to inventory")
	
	print("Test inventory setup complete!")


## Setup placeholder icons for items that don't have them
func _setup_placeholder_icons() -> void:
	if medkit and not medkit.icon:
		medkit.icon = _create_placeholder_icon(Color(0.8, 0.2, 0.2, 1.0), 64)
	
	if ammo_box and not ammo_box.icon:
		ammo_box.icon = _create_placeholder_icon(Color(0.7, 0.6, 0.3, 1.0), 64)
	
	if water_bottle and not water_bottle.icon:
		water_bottle.icon = _create_placeholder_icon(Color(0.2, 0.5, 0.8, 1.0), 64)
	
	if delivery_package and not delivery_package.icon:
		delivery_package.icon = _create_placeholder_icon(Color(0.6, 0.4, 0.2, 1.0), 64)


## Generate a colored square placeholder icon
func _create_placeholder_icon(color: Color, size: int = 64) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# Add border for visibility
	var border_color := Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 1.0)
	for x in size:
		img.set_pixel(x, 0, border_color)
		img.set_pixel(x, size - 1, border_color)
	for y in size:
		img.set_pixel(0, y, border_color)
		img.set_pixel(size - 1, y, border_color)
	
	return ImageTexture.create_from_image(img)
