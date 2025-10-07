extends Node2D

## Minimal test to debug why items aren't being added to inventory

func _ready() -> void:
	print("\n========== SIMPLE ADD TEST ==========")

	# Wait for everything to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var player = $Player
	print("1. Player: ", player)

	var inv = player.get_node("Inventory")
	print("2. Inventory node: ", inv)
	print("3. Inventory.data: ", inv.data)

	if inv.data:
		print("4. Grid size: ", inv.data.grid_width, "x", inv.data.grid_height)
		print("5. Current items: ", inv.data.get_all_items().size())
		print("6. Current weight: ", inv.data.current_weight)

	# Load a simple item
	var medkit = load("res://resources/items/examples/medkit.tres")
	print("7. Loaded medkit: ", medkit)
	print("8. Medkit properties:")
	print("   - item_name: ", medkit.item_name)
	print("   - grid_size: ", medkit.grid_size)
	print("   - weight: ", medkit.weight)
	print("   - stackable: ", medkit.stackable)

	# Create icon
	var icon = _create_icon(Color.RED)
	print("9. Created icon: ", icon)

	medkit.icon = icon
	print("10. Assigned icon to medkit")

	# Try to add
	print("11. Calling inv.add_item(medkit, 1)...")
	var result = inv.add_item(medkit, 1)
	print("12. Result: ", result)

	if inv.data:
		print("13. After add - items: ", inv.data.get_all_items().size())
		print("14. After add - weight: ", inv.data.current_weight)

		# Check grid directly
		var found_items = 0
		for y in inv.data.grid_height:
			for x in inv.data.grid_width:
				if inv.data.grid[y][x] != null:
					found_items += 1
		print("15. Items found in grid: ", found_items)

	print("========== TEST COMPLETE ==========\n")


func _create_icon(color: Color) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
