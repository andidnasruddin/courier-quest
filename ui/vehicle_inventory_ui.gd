## Vehicle Inventory UI
##
## Grid-based inventory UI for vehicles with drag-and-drop support.
## Grid size is determined dynamically from the vehicle's InventoryData.

extends CanvasLayer
class_name VehicleInventoryUI

signal closed

const SLOT_SIZE := Vector2(64, 64)
const SLOT_SPACING := 4

var inventory: Inventory = null
var slots: Array[ItemSlotUI] = []
var is_open: bool = false

var dragging_item: InventoryData.InventoryItem = null
var dragging_from_slot: ItemSlotUI = null
var dragging_from_inventory: Inventory = null  # Track source inventory

var other_inventory_ui: Node = null  # Reference to player inventory UI for transfers

@onready var panel: Panel = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/MarginContainer/VBoxContainer/GridPanel/GridContainer
@onready var weight_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/StatsPanel/WeightLabel
@onready var title_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/TitleLabel


func _ready() -> void:
	# Hide by default
	hide()
	is_open = false


func setup(vehicle_inventory: Inventory, vehicle_name: String = "Vehicle") -> void:
	inventory = vehicle_inventory
	inventory.inventory_changed.connect(_refresh_grid)
	inventory.weight_changed.connect(_on_weight_changed)

	# Set title
	if title_label:
		title_label.text = "%s Storage" % vehicle_name

	_setup_grid()
	_refresh_grid()


func _setup_grid() -> void:
	if not inventory or not inventory.data:
		return

	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	slots.clear()

	# Get grid size from inventory data
	var grid_width: int = inventory.data.grid_width
	var grid_height: int = inventory.data.grid_height

	# Calculate panel size based on grid dimensions
	var grid_pixel_width: float = (SLOT_SIZE.x + SLOT_SPACING) * grid_width - SLOT_SPACING
	var grid_pixel_height: float = (SLOT_SIZE.y + SLOT_SPACING) * grid_height - SLOT_SPACING
	var panel_width: float = grid_pixel_width + 80  # 40px margin on each side
	var panel_height: float = grid_pixel_height + 140  # Space for title, stats, margins

	# Resize panel
	if panel:
		panel.offset_left = -panel_width - 20  # 20px from right edge
		panel.offset_right = -20
		panel.offset_top = -panel_height / 2
		panel.offset_bottom = panel_height / 2

	# Create grid slots
	grid_container.columns = grid_width
	grid_container.add_theme_constant_override("h_separation", SLOT_SPACING)
	grid_container.add_theme_constant_override("v_separation", SLOT_SPACING)

	for y in range(grid_height):
		for x in range(grid_width):
			var slot := ItemSlotUI.new()
			slot.slot_size = SLOT_SIZE
			slot.grid_position = Vector2i(x, y)
			slot.show_count = true
			slot.inventory_ui = self

			slot.slot_clicked.connect(_on_slot_clicked)
			slot.drag_started.connect(_on_drag_started)
			slot.drag_ended.connect(_on_drag_ended)
			slot.right_clicked.connect(_on_slot_right_clicked)

			grid_container.add_child(slot)
			slots.append(slot)


func _refresh_grid() -> void:
	print("[VEHICLE_UI] _refresh_grid() called")
	if not inventory or not inventory.data:
		return

	var grid_width: int = inventory.data.grid_width
	var grid_height: int = inventory.data.grid_height

	var item_count: int = 0
	# Fill from live grid
	for y in range(grid_height):
		for x in range(grid_width):
			var idx: int = y * grid_width + x
			var cell_item: InventoryData.InventoryItem = inventory.get_item_at(Vector2i(x, y))
			if cell_item != null:
				item_count += 1
			slots[idx].grid_position = Vector2i(x, y)
			slots[idx].set_item(cell_item)

	print("[VEHICLE_UI] Refreshed grid: ", item_count, " occupied cells | Weight: ", inventory.data.current_weight)

	# Update weight display
	_on_weight_changed(inventory.data.current_weight, InventoryData.MAX_WEIGHT)


func _on_weight_changed(current: float, max_weight: float) -> void:
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current, max_weight]


func _on_slot_clicked(slot: ItemSlotUI) -> void:
	# If we're dragging, try to drop
	if dragging_item:
		_try_drop_item(slot.grid_position)
	else:
		# Pick up item from slot
		var item: InventoryData.InventoryItem = inventory.get_item_at(slot.grid_position)
		if item:
			dragging_item = item
			dragging_from_slot = slot
			dragging_from_inventory = inventory  # Set source inventory

			# Notify other inventory UI about the drag
			if other_inventory_ui and other_inventory_ui.has_method("_on_external_drag_started"):
				other_inventory_ui._on_external_drag_started(item, inventory)


func _on_drag_started(slot: ItemSlotUI, item: InventoryData.InventoryItem) -> void:
	dragging_item = item
	dragging_from_slot = slot
	dragging_from_inventory = inventory

	# Notify other inventory UI about the drag
	if other_inventory_ui and other_inventory_ui.has_method("_on_external_drag_started"):
		other_inventory_ui._on_external_drag_started(item, inventory)


func _on_drag_ended() -> void:
	dragging_item = null
	dragging_from_slot = null
	dragging_from_inventory = null


func _on_drop_on_slot(target_slot: ItemSlotUI, dropped_item: InventoryData.InventoryItem) -> void:
	# Called by ItemSlotUI when a drop occurs via built-in DnD
	if not dropped_item:
		return
	var target_pos: Vector2i = target_slot.grid_position
	_try_drop_item(target_pos)
	# Prevent other layers from also handling this drop
	get_viewport().set_input_as_handled()


func _on_slot_right_clicked(slot: ItemSlotUI) -> void:
	# Vehicle inventory doesn't use hotbar, so right-click does nothing
	pass


func _try_drop_item(target_pos: Vector2i) -> void:
	if not dragging_item:
		return

	# Check if dragging from another inventory (cross-inventory transfer)
	if dragging_from_inventory and dragging_from_inventory != inventory:
		# Transfer from other inventory to this one
		if _transfer_item_between_inventories(dragging_from_inventory, inventory, dragging_item, target_pos):
			print("Transferred item between inventories")
		else:
			print("Could not transfer item")
	else:
		# Moving within same inventory
		if inventory.move_item(dragging_item, target_pos):
			print("Moved item to ", target_pos)
		else:
			print("Could not move item to ", target_pos)

	# Clear drag state
	dragging_item = null
	dragging_from_slot = null
	dragging_from_inventory = null

	# Notify other inventory UI
	if other_inventory_ui and other_inventory_ui.has_method("_on_external_drag_ended"):
		other_inventory_ui._on_external_drag_ended()

	# Manual refresh removed - signals should trigger automatic refresh via inventory_changed connection
	# Ensure input is marked handled to reduce cross-layer click-through
	get_viewport().set_input_as_handled()


## Called by other inventory UI when they start dragging
func _on_external_drag_started(item: InventoryData.InventoryItem, source_inventory: Inventory) -> void:
	dragging_item = item
	dragging_from_inventory = source_inventory
	dragging_from_slot = null  # Not from our slots


## Called by other inventory UI when they end dragging
func _on_external_drag_ended() -> void:
	dragging_item = null
	dragging_from_inventory = null
	dragging_from_slot = null


func _transfer_item_between_inventories(source_inv: Inventory, target_inv: Inventory, item: InventoryData.InventoryItem, target_pos: Vector2i) -> bool:
	print("[VEHICLE_UI] === TRANSFER START ===")
	print("[VEHICLE_UI] Item: ", item.data.item_name, " | From: ", "Vehicle" if source_inv == inventory else "Player", " → To: ", "Vehicle" if target_inv == inventory else "Player")
	print("[VEHICLE_UI] Source weight before: ", source_inv.data.current_weight)
	print("[VEHICLE_UI] Target weight before: ", target_inv.data.current_weight)

	# Save item data before removal (must do this first while item is valid)
	var item_data: ItemData = item.data
	var stack_count: int = item.stack_count
	var was_rotated: bool = item.is_rotated
	var item_weight: float = item.get_total_weight()
	var original_pos: Vector2i = item.grid_position

	print("[VEHICLE_UI] Item weight: ", item_weight, " | Original pos: ", original_pos, " | Target pos: ", target_pos)

	# Check if target inventory can fit the item at position
	# Create temporary item to test placement (don't modify original yet)
	var test_item := InventoryData.InventoryItem.new(item_data, stack_count)
	test_item.is_rotated = was_rotated
	if not target_inv.data._can_place_at(test_item, target_pos, null):
		print("[VEHICLE_UI] ❌ Cannot place at target position")
		return false

	print("[VEHICLE_UI] ✓ Target position valid, proceeding with transfer")

	# Remove from source inventory completely
	print("[VEHICLE_UI] Clearing item from source grid...")
	source_inv.data._clear_item_from_grid(item)
	source_inv.data.current_weight -= item_weight
	print("[VEHICLE_UI] Source weight after clear: ", source_inv.data.current_weight)

	# Create new item in target at specified position
	var new_item := InventoryData.InventoryItem.new(item_data, stack_count)
	new_item.is_rotated = was_rotated
	new_item.grid_position = target_pos

	print("[VEHICLE_UI] Placing new item in target grid...")
	if target_inv.data._place_item_at(new_item, target_pos):
		target_inv.data.current_weight += new_item.get_total_weight()
		print("[VEHICLE_UI] Target weight after place: ", target_inv.data.current_weight)
		print("[VEHICLE_UI] Emitting signals...")
		source_inv.data.inventory_changed.emit()
		target_inv.data.inventory_changed.emit()
		source_inv.data.weight_changed.emit(source_inv.data.current_weight, InventoryData.MAX_WEIGHT)
		target_inv.data.weight_changed.emit(target_inv.data.current_weight, InventoryData.MAX_WEIGHT)
		print("[VEHICLE_UI] ✓ Transfer complete successfully")
		return true
	else:
		print("[VEHICLE_UI] ❌ Failed to place in target, rolling back...")
		# Failed to place in target, restore to source
		source_inv.data._place_item_at(item, original_pos)
		source_inv.data.current_weight += item_weight
		print("[VEHICLE_UI] Rollback complete")
		return false


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	# Handle item rotation while dragging
	if event.is_action_pressed("rotate_item") and dragging_item:
		inventory.rotate_item(dragging_item)
		_refresh_grid()
		get_viewport().set_input_as_handled()
		return

	# Close on Escape
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	is_open = true
	_refresh_grid()


func close() -> void:
	hide()
	is_open = false
	dragging_item = null
	dragging_from_slot = null
	closed.emit()
