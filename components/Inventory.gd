extends Node
class_name Inventory

## Signals (forwarded from InventoryData)
signal inventory_changed
signal weight_changed(current: float, max: float)

## Optional custom grid size (set before _ready if needed)
var custom_grid_size: Vector2i = Vector2i.ZERO

## The actual inventory data
var data: InventoryData = null

func _ready() -> void:
	# Initialize inventory data with custom size if specified
	if custom_grid_size.x > 0 and custom_grid_size.y > 0:
		data = InventoryData.new_with_size(custom_grid_size.x, custom_grid_size.y)
	else:
		data = InventoryData.new()

	# Connect InventoryData signals to forward them
	data.inventory_changed.connect(_on_inventory_changed)
	data.weight_changed.connect(_on_weight_changed)


## Initialize with custom grid size (call before _ready)
func init_with_size(grid_size: Vector2i) -> void:
	# Store desired size
	custom_grid_size = grid_size

	# If data already exists (node is ready), reinitialize immediately
	if data != null:
		# Disconnect old signals
		if data.inventory_changed.is_connected(_on_inventory_changed):
			data.inventory_changed.disconnect(_on_inventory_changed)
		if data.weight_changed.is_connected(_on_weight_changed):
			data.weight_changed.disconnect(_on_weight_changed)

		# Create a fresh InventoryData with the requested size
		data = InventoryData.new_with_size(custom_grid_size.x, custom_grid_size.y)

		# Reconnect forwarding signals
		data.inventory_changed.connect(_on_inventory_changed)
		data.weight_changed.connect(_on_weight_changed)

		# Emit initial signals so UIs can rebuild with the new size
		_on_inventory_changed()
		_on_weight_changed(data.current_weight, InventoryData.MAX_WEIGHT)

## === PUBLIC API ===

func add_item(item_data: ItemData, count: int = 1) -> bool:
	return data.add_item(item_data, count)

func remove_item(item: InventoryData.InventoryItem, count: int = 1) -> bool:
	return data.remove_item(item, count)

func get_item_at(grid_pos: Vector2i) -> InventoryData.InventoryItem:
	return data.get_item_at(grid_pos)

func move_item(item: InventoryData.InventoryItem, new_pos: Vector2i) -> bool:
	return data.move_item(item, new_pos)

func rotate_item(item: InventoryData.InventoryItem) -> bool:
	return data.rotate_item(item)

func get_all_items() -> Array[InventoryData.InventoryItem]:
	return data.get_all_items()

## Save the inventory to a serializable dictionary
func get_save_data() -> Dictionary:
	if data == null:
		return {}
	return data.get_save_data()

## Load the inventory from a serialized dictionary
func load_save_data(save: Dictionary) -> void:
	if data == null:
		data = InventoryData.new()
	data.load_save_data(save)
	# Emit updates so any bound UI refreshes
	_on_inventory_changed()
	_on_weight_changed(data.current_weight, InventoryData.MAX_WEIGHT)

## === SIGNAL HANDLERS ===

func _on_inventory_changed() -> void:
	inventory_changed.emit()

func _on_weight_changed(current: float, max_weight: float) -> void:
	weight_changed.emit(current, max_weight)
