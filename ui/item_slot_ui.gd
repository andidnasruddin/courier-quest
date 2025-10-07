extends PanelContainer
class_name ItemSlotUI

signal slot_clicked(slot: ItemSlotUI)
signal drag_started(slot: ItemSlotUI, item: InventoryData.InventoryItem)
signal drag_ended(slot: ItemSlotUI)
signal right_clicked(slot: ItemSlotUI)

@export var slot_size: Vector2 = Vector2(64, 64)
@export var show_count: bool = true

var grid_position: Vector2i = Vector2i.ZERO
var item: InventoryData.InventoryItem = null
var is_dragging: bool = false

# Back-reference to the owning inventory UI for drag/drop coordination
var inventory_ui: Node = null

var icon: TextureRect
var count_label: Label
var rotation_indicator: Label

func _ready() -> void:
	custom_minimum_size = slot_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	_setup_ui()
	refresh()
	# Track hover for rotation on hovered slot
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _setup_ui() -> void:
	# Create UI structure
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	add_child(margin)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)
	
	icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon)
	
	count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(count_label)
	
	rotation_indicator = Label.new()
	rotation_indicator.name = "RotationIndicator"
	rotation_indicator.text = "↻"
	rotation_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rotation_indicator.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	rotation_indicator.add_theme_color_override("font_color", Color.YELLOW)
	rotation_indicator.position = Vector2(2, 2)
	rotation_indicator.visible = false
	add_child(rotation_indicator)

func set_item(new_item: InventoryData.InventoryItem) -> void:
	item = new_item
	refresh()

func refresh() -> void:
	remove_theme_stylebox_override("panel")
	if item and item.data:
		var is_anchor := (item.grid_position == grid_position)
		if is_anchor:
			icon.texture = item.data.icon
			icon.visible = true
			if show_count and item.data.stackable and item.data.max_stack > 1:
				count_label.text = str(item.stack_count)
				count_label.visible = true
			else:
				count_label.visible = false
			rotation_indicator.visible = item.is_rotated
			if item.get_grid_size().x > 1 or item.get_grid_size().y > 1:
				add_theme_stylebox_override("panel", _get_anchor_style())
		else:
			# Occupied non-anchor tile: show overlay only
			icon.visible = false
			count_label.visible = false
			rotation_indicator.visible = false
			add_theme_stylebox_override("panel", _get_occupied_style())
	else:
		icon.visible = false
		count_label.visible = false
		rotation_indicator.visible = false

func _get_anchor_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.75, 0.85, 1.0, 0.20)
	style.border_color = Color(0.55, 0.75, 1.0, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style

func _get_occupied_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.75, 0.85, 1.0, 0.15)
	style.border_color = Color(0.55, 0.75, 1.0, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				slot_clicked.emit(self)
				if item:
					is_dragging = true
					drag_started.emit(self, item)
			else:
				if is_dragging:
					is_dragging = false
					drag_ended.emit(self)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			right_clicked.emit(self)

func _on_mouse_entered() -> void:
	if inventory_ui and inventory_ui.has_method("_on_slot_hovered"):
		inventory_ui._on_slot_hovered(self)

func _on_mouse_exited() -> void:
	if inventory_ui and inventory_ui.has_method("_on_slot_unhovered"):
		inventory_ui._on_slot_unhovered(self)

## Built-in drag and drop API
func _get_drag_data(at_position: Vector2) -> Variant:
	if not item:
		return null
	# Inform parent UI about drag start
	if inventory_ui:
		inventory_ui._on_drag_started(self, item)
	# Simple drag preview with the item icon
	if item.data and item.data.icon:
		var preview := TextureRect.new()
		preview.texture = item.data.icon
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_drag_preview(preview)
	return {
		"type": "inventory_item",
		"item": item,
		"from": self
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("type") and data.type == "inventory_item":
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	if inventory_ui and data.has("item"):
		inventory_ui._on_drop_on_slot(self, data.item)
