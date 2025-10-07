## Ground Inventory UI
##
## Shows nearby ground items in a grid-like display.
## Items can be picked up by dragging into player inventory.

extends CanvasLayer
class_name GroundInventoryUI

signal closed

const SLOT_SIZE := Vector2(64, 64)
const SLOT_SPACING := 4
const MAX_DISPLAYED_ITEMS := 20  # Maximum items to show at once

var nearby_items: Array[WorldItem] = []
var slots: Array[ItemSlotUI] = []
var is_open: bool = false

var dragging_world_item: WorldItem = null
var dragging_from_slot: ItemSlotUI = null

var other_inventory_ui: Node = null  # Reference to player inventory UI for transfers

@onready var panel: Panel = $InventoryPanel
@onready var grid_container: GridContainer = $InventoryPanel/MarginContainer/VBoxContainer/GridPanel/GridContainer
@onready var title_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/TitleLabel


func _ready() -> void:
	hide()
	is_open = false


func setup(items: Array[WorldItem], player_inv_ui: Node) -> void:
	nearby_items = items
	other_inventory_ui = player_inv_ui
	_setup_grid()
	_refresh_grid()


func _setup_grid() -> void:
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	slots.clear()

	# Fixed grid size for ground items (4 columns × 5 rows = 20 slots)
	var grid_width: int = 4
	var grid_height: int = 5

	# Calculate panel size
	var grid_pixel_width: float = (SLOT_SIZE.x + SLOT_SPACING) * grid_width - SLOT_SPACING
	var grid_pixel_height: float = (SLOT_SIZE.y + SLOT_SPACING) * grid_height - SLOT_SPACING
	var panel_width: float = grid_pixel_width + 40  # Grid + margins
	var panel_height: float = grid_pixel_height + 100  # Space for title and margins

	# Position panel on right side
	if panel:
		var vp_width: float = get_viewport().get_visible_rect().size.x
		panel.offset_left = vp_width - panel_width - 20
		panel.offset_right = vp_width - 20
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
			slot.mouse_entered.connect(func() -> void: _on_slot_hovered(slot))

			grid_container.add_child(slot)
			slots.append(slot)


func _refresh_grid() -> void:
	if slots.is_empty():
		return

	print("[GROUND_UI] _refresh_grid() called with ", nearby_items.size(), " nearby items")

	# Clear all slots first
	for slot in slots:
		slot.set_item(null)

	# Fill slots with nearby items (one item per slot, limit to MAX_DISPLAYED_ITEMS)
	var item_index: int = 0
	for world_item in nearby_items:
		if item_index >= MAX_DISPLAYED_ITEMS or item_index >= slots.size():
			break
		if not is_instance_valid(world_item) or world_item.item_data == null:
			continue

		# Create a fake InventoryItem for display purposes
		var display_item := InventoryData.InventoryItem.new(world_item.item_data, world_item.quantity)
		display_item.grid_position = Vector2i(item_index % 4, item_index / 4)

		slots[item_index].set_item(display_item)
		item_index += 1


func _on_slot_clicked(slot: ItemSlotUI, button_index: int) -> void:
	if button_index == MOUSE_BUTTON_LEFT:
		# Left click to pick up (start drag)
		pass
	elif button_index == MOUSE_BUTTON_RIGHT:
		# Right click not supported for ground items
		pass


func _on_drag_started(slot: ItemSlotUI, item: InventoryData.InventoryItem) -> void:
	# Find corresponding WorldItem
	var slot_index: int = slots.find(slot)
	if slot_index < 0 or slot_index >= nearby_items.size():
		return

	dragging_world_item = nearby_items[slot_index]
	dragging_from_slot = slot

	print("[GROUND_UI] Started dragging world item: ", item.data.item_name)


func _on_slot_hovered(slot: ItemSlotUI) -> void:
	pass


func open() -> void:
	show()
	is_open = true


func close() -> void:
	hide()
	is_open = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not is_open:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_TAB:
			close()
			get_viewport().set_input_as_handled()
