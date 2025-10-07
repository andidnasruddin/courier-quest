extends CanvasLayer
class_name PlayerInventoryUI

signal closed
signal item_dropped(item_data: ItemData, quantity: int)

const SLOT_SIZE := Vector2(64, 64)
const SLOT_SPACING := 4

var inventory: Inventory = null
var slots: Array[ItemSlotUI] = []
var is_open: bool = false

var dragging_item: InventoryData.InventoryItem = null
var dragging_from_slot: ItemSlotUI = null
var dragging_from_inventory: Inventory = null  # Track source inventory

var hotbar_ui: Node = null
var _hovered_slot: ItemSlotUI = null
var other_inventory_ui: Node = null  # Reference to vehicle inventory UI for transfers

@onready var panel: Panel = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/MarginContainer/HBoxContainer/GridPanel/GridContainer
@onready var weight_label: Label = $InventoryPanel/MarginContainer/HBoxContainer/StatsPanel/WeightLabel

func _ready() -> void:
	# Hide by default
	hide()
	is_open = false

func setup(player_inventory: Inventory) -> void:
	inventory = player_inventory
	inventory.inventory_changed.connect(_refresh_grid)
	inventory.weight_changed.connect(_on_weight_changed)
	_setup_grid()
	_refresh_grid()

func set_hotbar(ui: Node) -> void:
	hotbar_ui = ui

func _setup_grid() -> void:
	if not inventory:
		return

	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	slots.clear()

	# Get grid size (use constants for player inventory)
	var grid_width: int = InventoryData.GRID_WIDTH
	var grid_height: int = InventoryData.GRID_HEIGHT

	# Calculate panel size based on grid dimensions
	var grid_pixel_width: float = (SLOT_SIZE.x + SLOT_SPACING) * grid_width - SLOT_SPACING
	var grid_pixel_height: float = (SLOT_SIZE.y + SLOT_SPACING) * grid_height - SLOT_SPACING
	var panel_width: float = grid_pixel_width + 200 + 40  # Grid + stats panel (200px) + margins
	var panel_height: float = grid_pixel_height + 100  # Space for title and margins

	# Resize panel
	if panel:
		panel.offset_left = 20  # 20px from left edge
		panel.offset_right = 20 + panel_width
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
	print("[PLAYER_UI] _refresh_grid() called")
	if not inventory:
		return

	var item_count: int = 0
	# Fill from live grid so multi-tile items mark all occupied cells
	for y in range(InventoryData.GRID_HEIGHT):
		for x in range(InventoryData.GRID_WIDTH):
			var idx := y * InventoryData.GRID_WIDTH + x
			var cell_item := inventory.get_item_at(Vector2i(x, y))
			if cell_item != null:
				item_count += 1
			slots[idx].grid_position = Vector2i(x, y)
			slots[idx].set_item(cell_item)

	print("[PLAYER_UI] Refreshed grid: ", item_count, " occupied cells | Weight: ", inventory.data.current_weight)

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
		var item := inventory.get_item_at(slot.grid_position)
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

func _on_drag_ended(slot: ItemSlotUI) -> void:
	if dragging_item:
		_try_drop_item(slot.grid_position)

func _on_drop_on_slot(target_slot: ItemSlotUI, dropped_item: InventoryData.InventoryItem) -> void:
	# Called by ItemSlotUI when a drop occurs via built-in DnD
	if not dropped_item:
		return
	var target_pos: Vector2i = target_slot.grid_position
	# Delegate to shared drop logic to correctly handle cross-inventory transfers
	_try_drop_item(target_pos)
	# Prevent other layers from also processing this drop
	get_viewport().set_input_as_handled()

func _on_slot_hovered(slot: ItemSlotUI) -> void:
	_hovered_slot = slot

func _on_slot_unhovered(slot: ItemSlotUI) -> void:
	if _hovered_slot == slot:
		_hovered_slot = null

func _on_slot_right_clicked(slot: ItemSlotUI) -> void:
	if not hotbar_ui:
		return
	var item := inventory.get_item_at(slot.grid_position)
	if not item or not item.data:
		return
	# Only allow certain types
	if not hotbar_ui._can_assign_item(item):
		print("Item not assignable to hotbar: ", item.data.item_name)
		return
	# Assign respecting uniqueness and available room
	hotbar_ui.assign_item(item)
	print("Assigned ", item.data.item_name, " to hotbar")

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
	print("[PLAYER_UI] === TRANSFER START ===")
	print("[PLAYER_UI] Item: ", item.data.item_name, " | From: ", "Vehicle" if source_inv != inventory else "Player", " → To: ", "Vehicle" if target_inv != inventory else "Player")
	print("[PLAYER_UI] Source weight before: ", source_inv.data.current_weight)
	print("[PLAYER_UI] Target weight before: ", target_inv.data.current_weight)

	# Save item data before removal (must do this first while item is valid)
	var item_data: ItemData = item.data
	var stack_count: int = item.stack_count
	var was_rotated: bool = item.is_rotated
	var item_weight: float = item.get_total_weight()
	var original_pos: Vector2i = item.grid_position

	print("[PLAYER_UI] Item weight: ", item_weight, " | Original pos: ", original_pos, " | Target pos: ", target_pos)

	# Check if target inventory can fit the item at position
	# Create temporary item to test placement (don't modify original yet)
	var test_item := InventoryData.InventoryItem.new(item_data, stack_count)
	test_item.is_rotated = was_rotated
	if not target_inv.data._can_place_at(test_item, target_pos, null):
		print("[PLAYER_UI] ❌ Cannot place at target position")
		return false

	print("[PLAYER_UI] ✓ Target position valid, proceeding with transfer")

	# Remove from source inventory completely
	print("[PLAYER_UI] Clearing item from source grid...")
	source_inv.data._clear_item_from_grid(item)
	source_inv.data.current_weight -= item_weight
	print("[PLAYER_UI] Source weight after clear: ", source_inv.data.current_weight)

	# Create new item in target at specified position
	var new_item := InventoryData.InventoryItem.new(item_data, stack_count)
	new_item.is_rotated = was_rotated
	new_item.grid_position = target_pos

	print("[PLAYER_UI] Placing new item in target grid...")
	if target_inv.data._place_item_at(new_item, target_pos):
		target_inv.data.current_weight += new_item.get_total_weight()
		print("[PLAYER_UI] Target weight after place: ", target_inv.data.current_weight)
		print("[PLAYER_UI] Emitting signals...")
		source_inv.data.inventory_changed.emit()
		target_inv.data.inventory_changed.emit()
		source_inv.data.weight_changed.emit(source_inv.data.current_weight, InventoryData.MAX_WEIGHT)
		target_inv.data.weight_changed.emit(target_inv.data.current_weight, InventoryData.MAX_WEIGHT)
		print("[PLAYER_UI] ✓ Transfer complete successfully")
		return true
	else:
		print("[PLAYER_UI] ❌ Failed to place in target, rolling back...")
		# Failed to place in target, restore to source
		source_inv.data._place_item_at(item, original_pos)
		source_inv.data.current_weight += item_weight
		print("[PLAYER_UI] Rollback complete")
		return false

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	
	if event.is_action_pressed("inventory_toggle"):
		close()
		get_viewport().set_input_as_handled()
	
	# Rotate item with R
	if event.is_action_pressed("reload"):
		var rotated := false
		if dragging_item:
			rotated = inventory.rotate_item(dragging_item)
		elif _hovered_slot:
			var it := inventory.get_item_at(_hovered_slot.grid_position)
			if it:
				rotated = inventory.rotate_item(it)
		if rotated:
			print("Rotated item")
			get_viewport().set_input_as_handled()

	# Drop item with D key
	if event.is_action_pressed("drop_item"):
		var item_to_drop: InventoryData.InventoryItem = null
		if dragging_item:
			item_to_drop = dragging_item
		elif _hovered_slot:
			item_to_drop = inventory.get_item_at(_hovered_slot.grid_position)

		if item_to_drop:
			_drop_item(item_to_drop)
			get_viewport().set_input_as_handled()

func _drop_item(item: InventoryData.InventoryItem) -> void:
	if not item or not inventory:
		return

	# Save item data
	var item_data: ItemData = item.data
	var quantity: int = item.stack_count

	# Remove from inventory
	if inventory.remove_item(item, quantity):
		print("[PLAYER_UI] Dropped ", item_data.item_name, " (x", quantity, ")")
		item_dropped.emit(item_data, quantity)

		# Clear drag state if we were dragging this item
		if dragging_item == item:
			dragging_item = null
			dragging_from_slot = null
			dragging_from_inventory = null
	else:
		push_warning("[PLAYER_UI] Failed to drop item: ", item_data.item_name)


func open() -> void:
	show()
	is_open = true
	_refresh_grid()

func close() -> void:
	hide()
	is_open = false

	# Clear drag state
	dragging_item = null
	dragging_from_slot = null

	closed.emit()
