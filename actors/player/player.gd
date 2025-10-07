## Player Controller
##
## Main player character with inventory integration.

extends CharacterBody2D
class_name Player

signal entered_vehicle(vehicle: Node)
signal exited_vehicle()

## Components
@onready var locomotion: LocomotionComponent = $LocomotionComponent
@onready var inventory: Inventory = $Inventory
@onready var interaction: InteractionComponent = $InteractionComponent
@onready var camera: Camera2D = $Camera2D

## UI References (loaded dynamically)
var inventory_ui: PlayerInventoryUI = null
var hotbar_ui: HotbarUI = null
var contract_hud: ContractHUD = null
var pickup_prompt_ui: PickupPromptUI = null

## Visual rotation speed
@export var rotation_speed: float = 10.0

## Camera lead settings
@export var camera_lead_enabled: bool = true
@export var sprint_lead_percent: float = 0.20  # 20% of viewport
@export var camera_lead_speed: float = 3.0

## Is player currently in a vehicle
var is_in_vehicle: bool = false
var controls_enabled: bool = true

## Reference to current vehicle
var current_vehicle: Node = null



func _ready() -> void:
	# Connect component signals
	if interaction:
		interaction.interactable_found.connect(_on_interactable_found)
		interaction.interaction_triggered.connect(_on_interaction_triggered)
	
	# Setup UI
	_setup_ui()


func _setup_ui() -> void:
	# Load and instance inventory UI
	var inventory_scene = load("res://ui/player_inventory_ui.tscn")

	if inventory_scene:
		inventory_ui = inventory_scene.instantiate()
		add_child(inventory_ui)
		inventory_ui.setup(inventory)
		inventory_ui.closed.connect(_on_inventory_closed)
		inventory_ui.item_dropped.connect(_on_item_dropped)

	# Load and instance hotbar UI
	var hotbar_scene = load("res://ui/hotbar_ui.tscn")

	if hotbar_scene:
		hotbar_ui = hotbar_scene.instantiate()
		add_child(hotbar_ui)
		hotbar_ui.setup(inventory)
		hotbar_ui.hotbar_slot_activated.connect(_on_hotbar_activated)
		# Link inventory UI to hotbar for assignments
		if inventory_ui:
			inventory_ui.set_hotbar(hotbar_ui)

	# Load and instance contract HUD
	var chud_scene: PackedScene = load("res://ui/contract_hud.tscn") as PackedScene
	if chud_scene:
		contract_hud = chud_scene.instantiate() as ContractHUD
		add_child(contract_hud)
		contract_hud.setup(self)

	# Load and instance pickup prompt UI
	var pickup_scene: PackedScene = load("res://ui/pickup_prompt_ui.tscn") as PackedScene
	if pickup_scene:
		pickup_prompt_ui = pickup_scene.instantiate() as PickupPromptUI
		add_child(pickup_prompt_ui)
		pickup_prompt_ui.item_selected.connect(_on_world_item_picked_up)

	

func _process(delta: float) -> void:
	# Always allow contract completion checks
	var cm: Node = get_node_or_null("/root/ContractManager")
	if cm and cm.has_method("try_complete"):
		cm.try_complete(self)

	# Update nearby items for pickup prompt
	if not is_in_vehicle:
		_update_nearby_items()

	if is_in_vehicle or not controls_enabled:
		return

	_update_rotation(delta)
	
	if not is_in_vehicle and camera_lead_enabled:
		_update_camera_lead(delta)


func _input(event: InputEvent) -> void:
	# Inventory toggle
	if event.is_action_pressed("inventory_toggle"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return


func _toggle_inventory() -> void:
	if inventory_ui:
		if inventory_ui.is_open:
			inventory_ui.close()
		else:
			inventory_ui.open()
			controls_enabled = false


func _on_inventory_closed() -> void:
	controls_enabled = true


func _on_hotbar_activated(slot_index: int) -> void:
	# Handle hotbar item usage (consume, equip, etc.)
	print("Player activated hotbar slot: ", slot_index)


func _open_vehicle_inventory(vehicle_inv: Inventory, vehicle_name: String) -> void:
	# Create or get vehicle inventory UI
	var vehicle_ui: VehicleInventoryUI = get_node_or_null("VehicleInventoryUI") as VehicleInventoryUI
	if not vehicle_ui:
		var scene: PackedScene = load("res://ui/vehicle_inventory_ui.tscn") as PackedScene
		if scene:
			vehicle_ui = scene.instantiate() as VehicleInventoryUI
			vehicle_ui.name = "VehicleInventoryUI"
			add_child(vehicle_ui)
			vehicle_ui.closed.connect(_on_vehicle_inventory_closed)

	# Open both player and vehicle inventories side-by-side
	if vehicle_ui and inventory_ui:
		vehicle_ui.setup(vehicle_inv, vehicle_name)

		# Link the two UIs for cross-inventory transfers
		vehicle_ui.other_inventory_ui = inventory_ui
		inventory_ui.other_inventory_ui = vehicle_ui

		vehicle_ui.open()
		inventory_ui.open()
		controls_enabled = false


func _on_vehicle_inventory_closed() -> void:
	# Close both inventories when vehicle inventory closes
	if inventory_ui:
		inventory_ui.close()
	controls_enabled = true


## Rotate player sprite toward mouse cursor
func _update_rotation(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = (mouse_pos - global_position).normalized()
	
	if direction.length() > 0.1:
		var target_rotation: float = direction.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		
		

## Update camera lead behavior
func _update_camera_lead(delta: float) -> void:
	if not camera or not locomotion:
		return
	
	var target_offset: Vector2 = Vector2.ZERO
	
	if locomotion.is_sprinting and velocity.length() > 10.0:
		# Calculate lead direction (toward cursor)
		var mouse_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (mouse_pos - global_position).normalized()
		
		# Lead distance based on viewport size
		var viewport_size: Vector2 = get_viewport_rect().size
		var lead_distance: float = viewport_size.length() * sprint_lead_percent
		
		target_offset = direction * lead_distance
	
	# Smooth camera offset transition
	camera.offset = camera.offset.lerp(target_offset, camera_lead_speed * delta)


## Enter a vehicle
func enter_vehicle(vehicle: Node) -> void:
	is_in_vehicle = true
	current_vehicle = vehicle
	
	# Disable movement
	if locomotion:
		locomotion.set_movement_enabled(false)
	
	# Disable player camera
	if camera:
		camera.enabled = false
	
	# Hide player sprite
	hide()
	
	# Tell vehicle it has a driver
	if vehicle.has_method("enter_vehicle"):
		vehicle.enter_vehicle(self)
	
	entered_vehicle.emit(vehicle)


## Exit current vehicle
func exit_vehicle() -> void:
	if not is_in_vehicle:
		return
	
	# Get exit position from vehicle
	var exit_pos: Vector2
	if current_vehicle and current_vehicle.has_method("get_exit_position"):
		exit_pos = current_vehicle.get_exit_position()
	elif current_vehicle and current_vehicle.has_node("EnterExitArea2D"):
		var exit_marker: Node2D = current_vehicle.get_node("EnterExitArea2D")
		exit_pos = exit_marker.global_position
	else:
		exit_pos = current_vehicle.global_position + Vector2(80, 0) if current_vehicle else global_position
	
	# Position player at exit point
	global_position = exit_pos
	
	# Clear vehicle state
	is_in_vehicle = false
	current_vehicle = null
	
	# Show player sprite
	show()
	
	# Re-enable player camera
	if camera:
		camera.enabled = true
		camera.make_current()
	
	# Re-enable movement
	if locomotion:
		locomotion.set_movement_enabled(true)
	
	exited_vehicle.emit()


func _on_interactable_found(interactable: Node) -> void:
	pass


func _on_interaction_triggered(interactable: Node) -> void:
	if not interactable:
		return
	
	# Handle different interactable types
	if interactable.has_method("get_interaction_type"):
		var interaction_type: String = interactable.get_interaction_type()
		
		match interaction_type:
			"vehicle":
				if not is_in_vehicle:
					var vehicle: Node = null
					if interactable.has_method("get_vehicle"):
						vehicle = interactable.get_vehicle()
					else:
						vehicle = interactable

					if vehicle:
						enter_vehicle(vehicle)

			"vehicle_inventory":
				# Open vehicle inventory UI
				var vehicle: Node = null
				if interactable.has_method("get_vehicle"):
					vehicle = interactable.get_vehicle()

				if vehicle and vehicle.has_node("InventoryComponent"):
					var vehicle_inv: Inventory = vehicle.get_node("InventoryComponent")
					_open_vehicle_inventory(vehicle_inv, vehicle.name)

			"contract_board":
				# Open contract board UI
				var settlement: Node2D = null
				if interactable.has_method("get_settlement"):
					settlement = interactable.get_settlement()
				if settlement:
					# Create UI if needed
					var ui: ContractBoardUI = get_node_or_null("ContractBoardUI") as ContractBoardUI
					if not ui:
						var scene: PackedScene = load("res://ui/contract_board_ui.tscn") as PackedScene
						if scene:
							ui = scene.instantiate() as ContractBoardUI
							ui.name = "ContractBoardUI"
							add_child(ui)
					if not ui:
						return
					# Build base contract template using default cargo (package)
					var cargo_res: ItemData = load("res://resources/items/examples/delivery_package.tres") as ItemData
					var base_contract: ContractData = ContractData.new()
					base_contract.contract_name = "Standard Delivery"
					base_contract.cargo_item = cargo_res
					base_contract.cargo_quantity = 1
					base_contract.payment_per_km = 12.0
					base_contract.distance_range = Vector2(50000, 150000)
					base_contract.time_limit_minutes = 20.0
					# Generate offers and open UI
					var offers: Array[Dictionary] = ContractManager.generate_offers(settlement, base_contract)
					ui.open(settlement, offers, self)


## Handle item drop from inventory
func _on_item_dropped(item_data: ItemData, quantity: int) -> void:
	print("[PLAYER] Dropping ", item_data.item_name, " (x", quantity, ")")

	# Spawn WorldItem at player position with small offset
	var drop_offset: Vector2 = Vector2(60, 0).rotated(rotation)
	var world_item: WorldItem = WorldItem.create_at_position(item_data, quantity, global_position + drop_offset)

	if world_item:
		get_parent().add_child(world_item)
		print("[PLAYER] Spawned WorldItem at ", world_item.global_position)
	else:
		push_error("[PLAYER] Failed to spawn WorldItem")


## Handle world item pickup
func _on_world_item_picked_up(world_item: WorldItem) -> void:
	if not world_item or not is_instance_valid(world_item):
		return

	var item_data: ItemData = world_item.get_item_data()
	var quantity: int = world_item.get_quantity()

	# Try to add to inventory
	if inventory.add_item(item_data, quantity):
		print("[PLAYER] Picked up ", item_data.item_name, " (x", quantity, ")")
		world_item.pickup()  # This will queue_free the world item
		_update_nearby_items()  # Refresh pickup prompt
	else:
		print("[PLAYER] Inventory full, cannot pick up ", item_data.item_name)


## Update nearby items for pickup prompt
func _update_nearby_items() -> void:
	if not pickup_prompt_ui:
		return

	# Find all WorldItems in interaction range
	var nearby: Array[WorldItem] = []
	if interaction:
		var interactables: Array[Node] = interaction.get_nearby_interactables()
		for node in interactables:
			if node is WorldItem:
				nearby.append(node as WorldItem)
				print("[PLAYER] Found nearby WorldItem: ", node.item_data.item_name if node.item_data else "NULL")

	if nearby.size() > 0:
		print("[PLAYER] Updating pickup prompt with ", nearby.size(), " items")
	pickup_prompt_ui.update_nearby_items(nearby)


