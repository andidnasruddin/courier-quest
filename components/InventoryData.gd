extends Resource
class_name InventoryData

## Default Grid Configuration (Player inventory - 8×6)
const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 6
const MAX_WEIGHT: float = 60.0  # kg

## Instance grid dimensions (can be customized)
var grid_width: int = GRID_WIDTH
var grid_height: int = GRID_HEIGHT

## Grid Storage (each cell stores item instance or null)
## Structure: grid[y][x] = InventoryItem instance or null
var grid: Array[Array] = []

## Weight Tracking
var current_weight: float = 0.0

## Signals
signal inventory_changed
signal weight_changed(current: float, max: float)

## Nested class for actual inventory items (instances with stack count + rotation)
class InventoryItem:
	var data: ItemData
	var stack_count: int = 1
	var is_rotated: bool = false  # 90-degree rotation toggle
	var grid_position: Vector2i = Vector2i.ZERO  # top-left anchor in grid

	func _init(item_data: ItemData, count: int = 1) -> void:
		data = item_data
		stack_count = count

	func get_grid_size() -> Vector2i:
		if is_rotated:
			return Vector2i(data.grid_size.y, data.grid_size.x)
		return data.grid_size

	func get_total_weight() -> float:
		return data.weight * stack_count

## Factory method to create inventory with custom size
static func new_with_size(width: int, height: int) -> InventoryData:
	var inv := InventoryData.new()
	inv.grid_width = width
	inv.grid_height = height
	inv._initialize_grid()
	return inv

func _init() -> void:
	# Initialize grid with default size
	_initialize_grid()

func _initialize_grid() -> void:
	grid.clear()
	grid.resize(grid_height)
	for y in range(grid_height):
		grid[y] = []
		grid[y].resize(grid_width)
		for x in range(grid_width):
			grid[y][x] = null

## === CORE INVENTORY METHODS ===

func can_add_item(item_data: ItemData, count: int = 1) -> bool:
	# Check if item can stack with existing
	if item_data.stackable and item_data.max_stack > 1:
		var existing := _find_stackable_item(item_data)
		if existing and existing.stack_count + count <= item_data.max_stack:
			return true
	
	# Check if there's space in grid
	return _find_empty_position(item_data.grid_size) != Vector2i(-1, -1)

func add_item(item_data: ItemData, count: int = 1) -> bool:
	# Try stacking first
	if item_data.stackable and item_data.max_stack > 1:
		var existing := _find_stackable_item(item_data)
		if existing:
			var space_in_stack := item_data.max_stack - existing.stack_count
			var to_stack := mini(count, space_in_stack)
			existing.stack_count += to_stack
			current_weight += item_data.weight * to_stack
			count -= to_stack
			inventory_changed.emit()
			weight_changed.emit(current_weight, MAX_WEIGHT)
			
			if count <= 0:
				return true
	
	# Place new item in grid
	var pos := _find_empty_position(item_data.grid_size)
	if pos == Vector2i(-1, -1):
		return false
	
	var new_item := InventoryItem.new(item_data, count)
	new_item.grid_position = pos
	
	if _place_item_at(new_item, pos):
		current_weight += new_item.get_total_weight()
		inventory_changed.emit()
		weight_changed.emit(current_weight, MAX_WEIGHT)
		return true
	
	return false

func remove_item(item: InventoryItem, count: int = 1) -> bool:
	# Ensure the item belongs to this inventory
	if not _contains_item(item):
		return false
	if item.stack_count < count:
		return false
	
	item.stack_count -= count
	current_weight -= item.data.weight * count
	
	if item.stack_count <= 0:
		_clear_item_from_grid(item)
	
	inventory_changed.emit()
	weight_changed.emit(current_weight, MAX_WEIGHT)
	return true

func get_item_at(grid_pos: Vector2i) -> InventoryItem:
	if not _is_valid_position(grid_pos):
		return null
	return grid[grid_pos.y][grid_pos.x]

func move_item(item: InventoryItem, new_pos: Vector2i) -> bool:
	# Ensure the item belongs to this inventory
	if not _contains_item(item):
		return false
	if not _can_place_at(item, new_pos, item):
		return false
	
	_clear_item_from_grid(item)
	item.grid_position = new_pos
	_place_item_at(item, new_pos)
	inventory_changed.emit()
	return true

func rotate_item(item: InventoryItem) -> bool:
	# Ensure the item belongs to this inventory
	if not _contains_item(item):
		return false
	var old_rotation := item.is_rotated
	item.is_rotated = not item.is_rotated
	
	# Check if rotation is valid at current position
	if not _can_place_at(item, item.grid_position, item):
		# Try to find new valid position
		var new_pos := _find_empty_position(item.get_grid_size())
		if new_pos == Vector2i(-1, -1):
			# Can't rotate, revert
			item.is_rotated = old_rotation
			return false
		
		# Move to new position
		_clear_item_from_grid(item)
		item.grid_position = new_pos
		_place_item_at(item, new_pos)
	else:
		# Rotation valid at current position, just refresh grid
		_clear_item_from_grid(item)
		_place_item_at(item, item.grid_position)
	
	inventory_changed.emit()
	return true

## === HELPER METHODS ===

func _find_stackable_item(item_data: ItemData) -> InventoryItem:
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: InventoryItem = grid[y][x]
			if cell and cell.data.item_id == item_data.item_id and cell.stack_count < item_data.max_stack:
				return cell
	return null

func _find_empty_position(size: Vector2i) -> Vector2i:
	for y in range(grid_height - size.y + 1):
		for x in range(grid_width - size.x + 1):
			if _can_place_at_position(Vector2i(x, y), size):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _can_place_at(item: InventoryItem, pos: Vector2i, ignore_item: InventoryItem = null) -> bool:
	var size := item.get_grid_size()

	# Check bounds
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + size.x > grid_width or pos.y + size.y > grid_height:
		return false

	# Check all cells
	for dy in range(size.y):
		for dx in range(size.x):
			var cell_item: InventoryItem = grid[pos.y + dy][pos.x + dx]
			if cell_item != null and cell_item != ignore_item:
				return false

	return true

func _can_place_at_position(pos: Vector2i, size: Vector2i) -> bool:
	if pos.x + size.x > grid_width or pos.y + size.y > grid_height:
		return false

	for dy in range(size.y):
		for dx in range(size.x):
			if grid[pos.y + dy][pos.x + dx] != null:
				return false

	return true

func _place_item_at(item: InventoryItem, pos: Vector2i) -> bool:
	var size := item.get_grid_size()
	
	# Fill all cells with reference to item
	for dy in range(size.y):
		for dx in range(size.x):
			grid[pos.y + dy][pos.x + dx] = item
	
	return true

func _clear_item_from_grid(item: InventoryItem) -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x] == item:
				grid[y][x] = null

func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

## === UTILITY ===

func get_all_items() -> Array[InventoryItem]:
	var items: Array[InventoryItem] = []
	var seen := {}

	for y in range(grid_height):
		for x in range(grid_width):
			var item: InventoryItem = grid[y][x]
			if item and not seen.has(item):
				items.append(item)
				seen[item] = true

	return items

func clear_all() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			grid[y][x] = null

	current_weight = 0.0
	inventory_changed.emit()
	weight_changed.emit(0.0, MAX_WEIGHT)

## Check if an InventoryItem reference exists within this grid
func _contains_item(item: InventoryItem) -> bool:
	for y in range(grid_height):
		for x in range(grid_width):
			if grid[y][x] == item:
				return true
	return false

## === SAVE / LOAD ===

## Build a serializable dictionary of inventory state
func get_save_data() -> Dictionary:
	var items: Array[Dictionary] = []
	for item in get_all_items():
		if item == null:
			continue
		var res_path: String = ""
		if item.data and item.data.resource_path != null:
			res_path = str(item.data.resource_path)
		items.append({
			"resource_path": res_path,
			"item_id": item.data.item_id if item.data else "",
			"stack_count": item.stack_count,
			"is_rotated": item.is_rotated,
			"grid_x": item.grid_position.x,
			"grid_y": item.grid_position.y
		})

	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"items": items,
		"current_weight": current_weight
	}

## Restore inventory from a serialized dictionary
func load_save_data(save: Dictionary) -> void:
	# Reset to specified grid size if present
	if save.has("grid_width") and save.has("grid_height"):
		grid_width = int(save.grid_width)
		grid_height = int(save.grid_height)
	_initialize_grid()

	current_weight = 0.0

	if not save.has("items"):
		inventory_changed.emit()
		weight_changed.emit(current_weight, MAX_WEIGHT)
		return

	var items: Array = save.items
	for entry in items:
		if entry == null:
			continue
		var res_path: String = str(entry.get("resource_path", ""))
		var item_res: ItemData = null
		if res_path != "":
			var loaded: Resource = load(res_path)
			if loaded is ItemData:
				item_res = loaded as ItemData
		# If not found by path, we cannot reconstruct reliably – skip
		if item_res == null:
			continue

		var inv_item := InventoryItem.new(item_res, int(entry.get("stack_count", 1)))
		inv_item.is_rotated = bool(entry.get("is_rotated", false))
		var gx: int = int(entry.get("grid_x", 0))
		var gy: int = int(entry.get("grid_y", 0))
		inv_item.grid_position = Vector2i(gx, gy)

		# Place if valid; if not valid at saved pos, try any fit
		if _can_place_at(inv_item, inv_item.grid_position):
			_place_item_at(inv_item, inv_item.grid_position)
		else:
			var new_pos := _find_empty_position(inv_item.get_grid_size())
			if new_pos != Vector2i(-1, -1):
				inv_item.grid_position = new_pos
				_place_item_at(inv_item, new_pos)
			# If still cannot place, skip silently

		current_weight += inv_item.get_total_weight()

	# Notify listeners
	inventory_changed.emit()
	weight_changed.emit(current_weight, MAX_WEIGHT)
