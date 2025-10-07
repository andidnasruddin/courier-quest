extends Node2D

## Test scene for cross-inventory transfers (Player <-> Vehicle)
## Spawns player with test items and empty vehicle nearby

func _ready() -> void:
	# Wait for scene to be fully ready - multiple frames to ensure all nodes are initialized
	await get_tree().process_frame
	await get_tree().process_frame

	print("╔════════════════════════════════════════════════╗")
	print("║   INVENTORY TRANSFER TEST - DEBUG MODE        ║")
	print("╚════════════════════════════════════════════════╝")
	print("")

	# Find player and vehicle
	var player: Node = get_node_or_null("Player")
	if not player:
		player = find_child("Player", true, false)
	var vehicle: Node = get_node_or_null("DeliveryVan")
	if not vehicle:
		vehicle = find_child("DeliveryVan", true, false)

	if not player:
		print("❌ ERROR: Could not find Player node!")
		return

	if not vehicle:
		print("❌ ERROR: Could not find DeliveryVan node!")
		return

	print("✅ Player found at:", player.get_path())
	print("✅ Vehicle found at:", vehicle.get_path())

	# Check player inventory
	if not player.has_node("Inventory"):
		print("❌ ERROR: Player doesn't have Inventory node!")
		return

	var player_inv: Inventory = player.get_node("Inventory")
	if not player_inv:
		print("❌ ERROR: Could not access player inventory!")
		return

	# Wait for inventory data to be initialized
	if not player_inv.data:
		print("⏳ Waiting for inventory data to initialize...")
		await get_tree().process_frame

	if not player_inv.data:
		print("❌ ERROR: Player inventory data not initialized!")
		return

	print("✅ Player inventory found!")
	print("   - Grid size: ", player_inv.data.grid_width, "x", player_inv.data.grid_height)

	# Check vehicle inventory (vehicle uses InventoryComponent node name)
	var vehicle_inv_path: String = "InventoryComponent"
	if not vehicle.has_node(vehicle_inv_path):
		# Fallback: older name
		if vehicle.has_node("Inventory"):
			vehicle_inv_path = "Inventory"
		else:
			print("❌ ERROR: Vehicle doesn't have InventoryComponent/Inventory node!")
			print("   Vehicle's children:")
			for child in vehicle.get_children():
				print("   - ", child.name, " (", child.get_class(), ")")
			return

	var vehicle_inv: Inventory = vehicle.get_node(vehicle_inv_path)
	if not vehicle_inv:
		print("❌ ERROR: Could not access vehicle inventory!")
		return

	# Wait for vehicle inventory data to be initialized
	if not vehicle_inv.data:
		print("⏳ Waiting for vehicle inventory data to initialize...")
		await get_tree().process_frame

	if not vehicle_inv.data:
		print("❌ ERROR: Vehicle inventory data not initialized!")
		return

	print("✅ Vehicle inventory found (node: ", vehicle_inv_path, ")!")
	print("   - Grid size: ", vehicle_inv.data.grid_width, "x", vehicle_inv.data.grid_height)

	# Connect debug signals for transfer observation
	if player_inv and player_inv.data:
		player_inv.data.inventory_changed.connect(func():
			print("[Player] inventory_changed → items=", player_inv.get_all_items().size(),
				" weight=", player_inv.data.current_weight, "/", InventoryData.MAX_WEIGHT)
		)
		player_inv.data.weight_changed.connect(func(cur: float, maxw: float):
			print("[Player] weight_changed → ", cur, "/", maxw)
		)
	if vehicle_inv and vehicle_inv.data:
		vehicle_inv.data.inventory_changed.connect(func():
			print("[Vehicle] inventory_changed → items=", vehicle_inv.get_all_items().size(),
				" weight=", vehicle_inv.data.current_weight, "/", InventoryData.MAX_WEIGHT)
		)
		vehicle_inv.data.weight_changed.connect(func(cur: float, maxw: float):
			print("[Vehicle] weight_changed → ", cur, "/", maxw)
		)

	# Generate placeholder icons
	print("\n=== Generating Placeholder Icons ===")
	_generate_placeholder_icons()

	# Load test items
	print("\n=== Loading Items ===")

	var package_small: ItemData = load("res://resources/items/examples/package_small.tres")
	if package_small:
		print("✅ Loaded package_small.tres")
	else:
		print("❌ Could not load package_small.tres")

	var package_medium: ItemData = load("res://resources/items/examples/package_medium.tres")
	if package_medium:
		print("✅ Loaded package_medium.tres")
	else:
		print("❌ Could not load package_medium.tres")

	var package_large: ItemData = load("res://resources/items/examples/package_large_crate.tres")
	if package_large:
		print("✅ Loaded package_large_crate.tres")
	else:
		print("❌ Could not load package_large_crate.tres")

	var medkit: ItemData = load("res://resources/items/examples/medkit.tres")
	if medkit:
		print("✅ Loaded medkit.tres")
	else:
		print("❌ Could not load medkit.tres")

	var water: ItemData = load("res://resources/items/examples/water_bottle.tres")
	if water:
		print("✅ Loaded water_bottle.tres")
	else:
		print("❌ Could not load water_bottle.tres")

	print("\n=== Adding Items ===")

	# Add items with generated icons (same pattern as test_inventory.gd)
	if package_small:
		package_small.icon = _create_placeholder_icon(Color(0.8, 0.6, 0.4))
		if player_inv.add_item(package_small, 1):
			print("✅ Added Small Package")
		else:
			print("❌ Failed to add Small Package")

	if package_medium:
		package_medium.icon = _create_placeholder_icon(Color(0.7, 0.5, 0.3))
		if player_inv.add_item(package_medium, 1):
			print("✅ Added Medium Package")
		else:
			print("❌ Failed to add Medium Package")

	if package_large:
		package_large.icon = _create_placeholder_icon(Color(0.6, 0.4, 0.2))
		if player_inv.add_item(package_large, 1):
			print("✅ Added Large Crate")
		else:
			print("❌ Failed to add Large Crate")

	if medkit:
		medkit.icon = _create_placeholder_icon(Color(0.8, 0.2, 0.2))
		if player_inv.add_item(medkit, 2):
			print("✅ Added 2 medkits")
		else:
			print("❌ Failed to add medkits")

	if water:
		water.icon = _create_placeholder_icon(Color(0.2, 0.5, 0.8))
		if player_inv.add_item(water, 3):
			print("✅ Added 3 water bottles")
		else:
			print("❌ Failed to add water bottles")

	print("\n=== Initial Inventory Stats ===")
	print("Player Inventory:")
	print("  - Items: ", player_inv.get_all_items().size())
	print("  - Weight: ", player_inv.data.current_weight, " / ", InventoryData.MAX_WEIGHT, " kg")
	print("  - Grid: ", player_inv.data.grid_width, "x", player_inv.data.grid_height)
	for it in player_inv.get_all_items():
		if it and it.data:
			var size := it.get_grid_size()
			print("    • ", it.data.item_name, " x", it.stack_count, " @", it.grid_position, " size=", size, " rotated=", it.is_rotated)

	print("\nVehicle Inventory:")
	print("  - Items: ", vehicle_inv.get_all_items().size())
	print("  - Weight: ", vehicle_inv.data.current_weight, " / ", InventoryData.MAX_WEIGHT, " kg")
	print("  - Grid: ", vehicle_inv.data.grid_width, "x", vehicle_inv.data.grid_height)
	for itv in vehicle_inv.get_all_items():
		if itv and itv.data:
			var vsize := itv.get_grid_size()
			print("    • ", itv.data.item_name, " x", itv.stack_count, " @", itv.grid_position, " size=", vsize, " rotated=", itv.is_rotated)

	print("\n╔════════════════════════════════════════════════╗")
	print("║  TEST READY - Press F near van to start      ║")
	print("║  Watch console for debug logs during transfer ║")
	print("╚════════════════════════════════════════════════╝")
	print("")


func _generate_placeholder_icons() -> void:
	print("Generating colored placeholder icons...")


func _create_placeholder_icon(color: Color, label: String = "", size: int = 64) -> ImageTexture:
	"""Create a colored placeholder icon with optional label text"""
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)

	# Add darker border
	var border_color := Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0)
	for x in size:
		img.set_pixel(x, 0, border_color)
		img.set_pixel(x, size - 1, border_color)
	for y in size:
		img.set_pixel(0, y, border_color)
		img.set_pixel(size - 1, y, border_color)

	# Add inner highlight
	var highlight_color := Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0)
	for x in range(2, size - 2):
		img.set_pixel(x, 2, highlight_color)
	for y in range(2, size - 2):
		img.set_pixel(2, y, highlight_color)

	return ImageTexture.create_from_image(img)
