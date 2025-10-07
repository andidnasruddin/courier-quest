## Pickup Prompt UI
##
## Shows nearby ground items in a list format.
## Player can scroll with mouse wheel to select which item to pick up.
## Press F to pick up the selected item.

extends CanvasLayer
class_name PickupPromptUI

signal item_selected(world_item: WorldItem)

const MAX_VISIBLE_ITEMS: int = 5
const ITEM_HEIGHT: int = 32
const SCROLL_SPEED: float = 1.0

var nearby_items: Array[WorldItem] = []
var selected_index: int = 0
var is_visible_prompt: bool = false

@onready var panel: Panel = $Panel
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var instruction_label: Label = $Panel/MarginContainer/VBoxContainer/InstructionLabel


func _ready() -> void:
	hide()
	is_visible_prompt = false

	# Set up panel styling and position
	if panel:
		panel.custom_minimum_size = Vector2(300, 200)
		# Position at bottom-right of screen
		panel.position = Vector2(20, 500)  # Will be adjusted dynamically
		panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
		# Ensure UI does not consume mouse/keyboard events so scrolling works
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var mc: Control = panel.get_node_or_null("MarginContainer") as Control
		if mc:
			mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vb: Control = panel.get_node_or_null("MarginContainer/VBoxContainer") as Control
		if vb:
			vb.mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_nearby_items(items: Array[WorldItem]) -> void:
	# Remember currently selected item (if any)
	var prev_selected: WorldItem = get_selected_item()

	# Rebuild list with valid items only
	var new_list: Array[WorldItem] = []
	for item in items:
		if is_instance_valid(item) and item.item_data != null:
			new_list.append(item)

	nearby_items = new_list

	# Preserve selection if possible
	if prev_selected != null and nearby_items.has(prev_selected):
		selected_index = nearby_items.find(prev_selected)
	else:
		selected_index = clampi(selected_index, 0, max(nearby_items.size() - 1, 0))

	# Update display
	_refresh_display()

	# Show/hide based on item count
	if nearby_items.size() > 0:
		show_prompt()
	else:
		hide_prompt()


func _refresh_display() -> void:
	# Clear existing labels (use free() for immediate deletion)
	for child in items_container.get_children():
		if child != instruction_label:
			child.free()

	if nearby_items.is_empty():
		return

	# Update instruction
	if instruction_label:
		instruction_label.text = "[F] Pick Up | [↑↓/Scroll] Select"

	print("[PICKUP_UI] Refreshing display with ", nearby_items.size(), " items, selected index: ", selected_index)

	# Add item labels
	for i in range(nearby_items.size()):
		var item: WorldItem = nearby_items[i]
		var label: Label = Label.new()

		# Format text
		var item_text: String = item.item_data.item_name
		if item.quantity > 1:
			item_text += " (x%d)" % item.quantity

		# Highlight selected item
		if i == selected_index:
			label.text = "> " + item_text + " <"
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))  # Yellow
			print("[PICKUP_UI] Selected item: ", item_text)
		else:
			label.text = "  " + item_text
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))  # Light gray

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(label)


func show_prompt() -> void:
	show()
	is_visible_prompt = true


func hide_prompt() -> void:
	hide()
	is_visible_prompt = false


func scroll_selection(direction: int) -> void:
	if nearby_items.is_empty():
		print("[PICKUP_UI] Cannot scroll - no items")
		return

	var old_index: int = selected_index
	selected_index += direction

	# Wrap around
	if selected_index < 0:
		selected_index = nearby_items.size() - 1
	elif selected_index >= nearby_items.size():
		selected_index = 0

	print("[PICKUP_UI] Scrolled from index ", old_index, " to ", selected_index)
	_refresh_display()


func get_selected_item() -> WorldItem:
	if selected_index >= 0 and selected_index < nearby_items.size():
		return nearby_items[selected_index]
	return null


func confirm_pickup() -> void:
	var item: WorldItem = get_selected_item()
	if item:
		item_selected.emit(item)
		# Remove from list
		nearby_items.remove_at(selected_index)
		selected_index = clampi(selected_index, 0, nearby_items.size() - 1)
		_refresh_display()

		# Hide if no more items
		if nearby_items.is_empty():
			hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_prompt:
		return

	# Mouse wheel scrolling
	if event is InputEventMouseButton:
		print("[PICKUP_UI] Mouse button event: ", event.button_index, " pressed=", event.pressed)
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				print("[PICKUP_UI] Scrolling UP (mouse wheel)")
				scroll_selection(-1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				print("[PICKUP_UI] Scrolling DOWN (mouse wheel)")
				scroll_selection(1)
				get_viewport().set_input_as_handled()

	# Arrow key scrolling (backup method)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			print("[PICKUP_UI] Scrolling UP (arrow key)")
			scroll_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			print("[PICKUP_UI] Scrolling DOWN (arrow key)")
			scroll_selection(1)
			get_viewport().set_input_as_handled()

	# Confirm pickup with F key
	if event.is_action_pressed("interact"):  # F key
		print("[PICKUP_UI] F key pressed, confirming pickup")
		confirm_pickup()
		get_viewport().set_input_as_handled()

## Also handle input earlier to avoid Controls eating events
func _input(event: InputEvent) -> void:
	if not is_visible_prompt:
		return
	# Mirror logic from _unhandled_input
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_selection(1)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			scroll_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			scroll_selection(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interact"):
			confirm_pickup()
			get_viewport().set_input_as_handled()
