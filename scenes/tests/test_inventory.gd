extends Node2D

func _ready():
	# Wait for scene to be fully ready
	await get_tree().process_frame
	
	print("=== Inventory Test Starting ===")
	
	# Find player
	var player = get_node_or_null("Player")
	if not player:
		player = find_child("Player", true, false)
	
	if not player:
		print("❌ ERROR: Could not find Player node!")
		return
	
	print("✅ Player found at:", player.get_path())
	
	# Check if player has inventory
	if not player.has_node("Inventory"):
		print("❌ ERROR: Player doesn't have Inventory node!")
		print("   Player's children:")
		for child in player.get_children():
			print("   - ", child.name, " (", child.get_class(), ")")
		return
	
	var inv: Inventory = player.get_node("Inventory")
	if not inv:
		print("❌ ERROR: Could not access inventory!")
		return
	
	print("✅ Inventory found!")
	
	# Generate placeholder icons for items
	print("\n=== Generating Placeholder Icons ===")
	_generate_placeholder_icons()
	
	# Load example items
	print("\n=== Loading Items ===")
	
	var medkit = load("res://resources/items/examples/medkit.tres")
	if medkit:
		print("✅ Loaded medkit.tres")
	else:
		print("❌ Could not load medkit.tres")
	
	var ammo = load("res://resources/items/examples/ammo_box.tres")
	if ammo:
		print("✅ Loaded ammo_box.tres")
	else:
		print("❌ Could not load ammo_box.tres")
	
	var water = load("res://resources/items/examples/water_bottle.tres")
	if water:
		print("✅ Loaded water_bottle.tres")
	else:
		print("❌ Could not load water_bottle.tres")
	
	var package = load("res://resources/items/examples/delivery_package.tres")
	if package:
		print("✅ Loaded delivery_package.tres")
	else:
		print("❌ Could not load delivery_package.tres")
	
	print("\n=== Adding Items ===")
	
	# Add items with generated icons
	if medkit:
		medkit.icon = _create_placeholder_icon(Color(0.8, 0.2, 0.2))
		if inv.add_item(medkit, 1):
			print("✅ Added medkit")
		else:
			print("❌ Failed to add medkit")
	
	if ammo:
		ammo.icon = _create_placeholder_icon(Color(0.7, 0.6, 0.3))
		if inv.add_item(ammo, 2):
			print("✅ Added 2 ammo boxes")
		else:
			print("❌ Failed to add ammo")
	
	if water:
		water.icon = _create_placeholder_icon(Color(0.2, 0.5, 0.8))
		if inv.add_item(water, 3):
			print("✅ Added 3 water bottles")
		else:
			print("❌ Failed to add water")
	
	if package:
		package.icon = _create_placeholder_icon(Color(0.6, 0.4, 0.2))
		if inv.add_item(package, 1):
			print("✅ Added delivery package")
		else:
			print("❌ Failed to add package")
	
	print("\n=== Inventory Stats ===")
	print("Current weight: ", inv.data.current_weight, " / ", InventoryData.MAX_WEIGHT, " kg")
	print("Items in inventory: ", inv.get_all_items().size())
	
	print("\n✨ Press TAB to open inventory!")

func _generate_placeholder_icons() -> void:
	print("Generating colored placeholder icons...")

func _create_placeholder_icon(color: Color, size: int = 64) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# Add border
	var border_color := Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 1.0)
	for x in size:
		img.set_pixel(x, 0, border_color)
		img.set_pixel(x, size - 1, border_color)
	for y in size:
		img.set_pixel(0, y, border_color)
		img.set_pixel(size - 1, y, border_color)
	
	return ImageTexture.create_from_image(img)
