## Hotbar UI
##
## Quick-access hotbar for items (1-5 keys).
## Items must be assigned from inventory to hotbar slots.

extends CanvasLayer
class_name HotbarUI

const HOTBAR_SLOTS: int = 5
const SLOT_SIZE: Vector2 = Vector2(64, 64)

signal hotbar_slot_activated(slot_index: int)

var inventory: Inventory = null
var hotbar_items: Array[InventoryData.InventoryItem] = []
var slot_uis: Array[ItemSlotUI] = []

@onready var hbox: HBoxContainer = $Panel/MarginContainer/HBoxContainer

func _ready() -> void:
	# Initialize hotbar array
	hotbar_items.resize(HOTBAR_SLOTS)
	for i in range(HOTBAR_SLOTS):
		hotbar_items[i] = null

	_setup_slots()


func setup(player_inventory: Inventory) -> void:
	inventory = player_inventory

func _can_assign_item(item: InventoryData.InventoryItem) -> bool:
	if not item or not item.data:
		return false
	return item.data.item_type == "Weapon" or item.data.item_type == "Consumable"

func _find_slot_by_item_id(item_id: String) -> int:
	for i in range(HOTBAR_SLOTS):
		var it := hotbar_items[i]
		if it and it.data and it.data.item_id == item_id:
			return i
	return -1

func assign_item(item: InventoryData.InventoryItem) -> void:
	if not _can_assign_item(item):
		return
	var id := item.data.item_id
	var existing := _find_slot_by_item_id(id)
	if existing != -1:
		# Update existing slot to latest reference of this item
		hotbar_items[existing] = item
		_refresh_slot(existing)
		return
	# Find first empty slot
	var target := -1
	for i in range(HOTBAR_SLOTS):
		if hotbar_items[i] == null:
			target = i
			break
	if target == -1:
		# No room available
		return
	hotbar_items[target] = item
	_refresh_slot(target)


func _setup_slots() -> void:
	# Clear existing slots
	for child in hbox.get_children():
		child.queue_free()
	slot_uis.clear()

	# Create hotbar slots
	for i in range(HOTBAR_SLOTS):
		var slot := ItemSlotUI.new()
		slot.slot_size = SLOT_SIZE
		slot.grid_position = Vector2i(i, 0)  # Hotbar is single row
		slot.show_count = true
		slot.slot_clicked.connect(_on_hotbar_slot_clicked.bind(i))
		slot.right_clicked.connect(_on_hotbar_slot_right_clicked.bind(i))

		# Add number label
		var number_label := Label.new()
		number_label.text = str(i + 1)
		number_label.position = Vector2(4, 4)
		number_label.add_theme_color_override("font_color", Color.YELLOW)
		number_label.add_theme_color_override("font_outline_color", Color.BLACK)
		number_label.add_theme_constant_override("outline_size", 2)
		slot.add_child(number_label)

		hbox.add_child(slot)
		slot_uis.append(slot)


func _input(event: InputEvent) -> void:
	# Number keys 1-5 activate hotbar slots
	for i in range(HOTBAR_SLOTS):
		var action_name := "hotbar_" + str(i + 1)
		if event.is_action_pressed(action_name):
			activate_slot(i)
			get_viewport().set_input_as_handled()
			return


func assign_item_to_slot(slot_index: int, item: InventoryData.InventoryItem) -> void:
	if slot_index < 0 or slot_index >= HOTBAR_SLOTS:
		return
	if not _can_assign_item(item):
		return
	# Ensure only one slot per item_id
	var id := item.data.item_id
	var existing := _find_slot_by_item_id(id)
	if existing != -1 and existing != slot_index:
		hotbar_items[existing] = null
		_refresh_slot(existing)
	hotbar_items[slot_index] = item
	_refresh_slot(slot_index)


func remove_item_from_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= HOTBAR_SLOTS:
		return

	hotbar_items[slot_index] = null
	_refresh_slot(slot_index)


func _refresh_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slot_uis.size():
		return

	var item := hotbar_items[slot_index]
	slot_uis[slot_index].set_item(item)


func refresh_all_slots() -> void:
	for i in range(HOTBAR_SLOTS):
		_refresh_slot(i)


func activate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= HOTBAR_SLOTS:
		return

	var item := hotbar_items[slot_index]
	if item:
		print("Activated hotbar slot ", slot_index + 1, ": ", item.data.item_name)
		hotbar_slot_activated.emit(slot_index)
		# TODO: Use item (consume, equip, etc.)


func _on_hotbar_slot_clicked(slot: ItemSlotUI, slot_index: int) -> void:
	# Right-click to unassign
	# Left-click to activate
	activate_slot(slot_index)

func _on_hotbar_slot_right_clicked(slot: ItemSlotUI, slot_index: int) -> void:
	remove_item_from_slot(slot_index)
	print("Removed hotbar slot ", slot_index + 1)
