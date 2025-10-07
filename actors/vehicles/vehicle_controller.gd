## Vehicle Controller
##
## Handles realistic top-down vehicle physics including acceleration, braking,
## steering, drift, and fuel consumption. Works with VehicleData resources.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name VehicleController extends CharacterBody2D

signal driver_entered(driver: Node)
signal driver_exited(driver: Node)
signal vehicle_stopped()
signal vehicle_moving()

## Vehicle data resource (stats, fuel capacity, etc.)
@export var vehicle_data: VehicleData

## Wheelbase (distance between front and rear axles in pixels)
## Affects turning radius - longer wheelbase = wider turns
@export var wheelbase: float = 64.0

## Reference to fuel system component
@onready var fuel_system: FuelSystemComponent = $FuelSystemComponent

## Reference to vehicle inventory
@onready var inventory: Inventory = $InventoryComponent

## Reference to camera (LookAheadCamera)
@onready var camera: Camera2D = $LookAheadCamera

## Reference to enter/exit position marker
@onready var enter_exit_marker: Node2D = $EnterExitArea2D


## Is someone currently driving
var is_being_driven: bool = false

## Reference to current driver (Player node)
var driver: Node = null

## Is vehicle reversing
var is_reversing: bool = false


# Physics variables
var _acceleration_input: float = 0.0
var _steering_input: float = 0.0
var _current_speed: float = 0.0
var _max_speed_pixels: float = 222.0  # Default, overridden by vehicle_data


func _ready() -> void:
	# Load vehicle data stats
	if vehicle_data:
		_max_speed_pixels = vehicle_data.get_max_speed_pixels_per_sec()

		# Configure fuel system
		if fuel_system:
			fuel_system.max_fuel = vehicle_data.fuel_capacity
			fuel_system.consumption_rate = vehicle_data.fuel_consumption
			fuel_system.refuel_full()
			fuel_system.initialize_position(global_position)

		# Configure inventory with vehicle's storage grid size
		if inventory:
			inventory.init_with_size(vehicle_data.storage_grid_size)

	# Configure camera
	if camera:
		camera.target = self
		camera.enabled = false  # Disabled until player enters

	# Configure enter/exit area
	if enter_exit_marker and enter_exit_marker is Area2D:
		enter_exit_marker.add_to_group("interactable")

	# Start as immovable (player can't push parked vehicles)
	collision_layer = 1  # Only on world layer (not interactable - the area is)
	collision_mask = 1   # Only collide with world


func _physics_process(delta: float) -> void:
	if not is_being_driven:
		# Parked vehicles don't move - freeze in place
		velocity = Vector2.ZERO
		return

	# Check fuel
	if fuel_system and fuel_system.is_empty():
		# Can't move without fuel
		velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)
		move_and_slide()
		return

	_handle_input()
	_apply_physics(delta)
	_update_fuel(delta)


## Handle driving input
func _handle_input() -> void:
	# Acceleration/braking input
	_acceleration_input = 0.0
	if Input.is_action_pressed("move_up"):
		_acceleration_input = 1.0
	elif Input.is_action_pressed("move_down"):
		_acceleration_input = -1.0

	# Steering input
	_steering_input = 0.0
	if Input.is_action_pressed("move_left"):
		_steering_input = -1.0
	elif Input.is_action_pressed("move_right"):
		_steering_input = 1.0

	# Exit vehicle
	if Input.is_action_just_pressed("interact"):
		exit_vehicle()


## Apply vehicle physics (Ackermann steering: realistic car handling)
func _apply_physics(delta: float) -> void:
	if not vehicle_data:
		return

	# Get stats from vehicle data
	var acceleration: float = vehicle_data.acceleration
	var turn_speed: float = vehicle_data.turn_speed
	var max_speed: float = _max_speed_pixels

	# Calculate target speed based on input
	var target_speed: float = _acceleration_input * max_speed

	# Check if reversing
	is_reversing = _acceleration_input < 0

	# Accelerate toward target speed
	_current_speed = move_toward(_current_speed, target_speed, acceleration * delta)

	# Apply friction when not accelerating
	if abs(_acceleration_input) < 0.1:
		_current_speed = move_toward(_current_speed, 0.0, acceleration * 0.5 * delta)

	# Ackermann steering geometry (realistic car physics)
	if abs(_current_speed) > 10.0 and abs(_steering_input) > 0.01:
		# Calculate maximum steering angle (reduced at higher speeds)
		var speed_factor: float = 1.0 - (abs(_current_speed) / max_speed) * 0.5
		var max_steer_angle: float = deg_to_rad(35.0) * speed_factor  # Max 35 degrees at low speed
		
		# Current steering angle based on input
		var steer_angle: float = _steering_input * max_steer_angle
		
		# When reversing, invert steering (rear becomes front)
		if is_reversing:
			steer_angle = -steer_angle
		
		# Calculate turning radius using Ackermann geometry
		# R = wheelbase / tan(steer_angle)
		var turning_radius: float
		if abs(steer_angle) > 0.001:
			turning_radius = wheelbase / tan(steer_angle)
		else:
			turning_radius = 999999.0  # Essentially straight
		
		# Calculate angular velocity (omega = velocity / radius)
		var angular_velocity: float = _current_speed / turning_radius
		
		# Apply rotation
		rotation += angular_velocity * delta
	
	# Calculate forward direction and move
	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	velocity = forward * _current_speed

	# Move vehicle
	move_and_slide()


## Update fuel consumption
func _update_fuel(delta: float) -> void:
	if fuel_system and abs(_current_speed) > 1.0:
		fuel_system.update_fuel(global_position, delta)




## Enter vehicle (called by player)
func enter_vehicle(new_driver: Node) -> void:
	if is_being_driven:
		return  # Already occupied

	is_being_driven = true
	driver = new_driver

	# Enable camera
	if camera:
		camera.enabled = true
		camera.make_current()

	driver_entered.emit(driver)


## Exit vehicle
func exit_vehicle() -> void:
	if not is_being_driven:
		return

	var exiting_driver: Node = driver
	
	# Disable camera first
	if camera:
		camera.enabled = false

	# Stop vehicle gradually
	_acceleration_input = 0.0
	_steering_input = 0.0
	
	# Clear driver state
	is_being_driven = false
	driver = null

	# Tell the driver to exit (this will reposition them and re-enable their camera)
	if exiting_driver and exiting_driver.has_method("exit_vehicle"):
		exiting_driver.exit_vehicle()
	
	driver_exited.emit(exiting_driver)


## Get the exit position for the player
func get_exit_position() -> Vector2:
	if enter_exit_marker:
		return enter_exit_marker.global_position
	# Fallback to offset from vehicle
	return global_position + Vector2(80, 0)


## Get parent vehicle from enter/exit area
func get_vehicle() -> VehicleController:
	return self


## Get interaction type (for interaction component)
func get_interaction_type() -> String:
	return "vehicle"


## Interact method (called when player presses F nearby)
func interact() -> void:
	# This method intentionally does nothing - entering is handled by player
	pass


## Get current speed in km/h
func get_speed_kmh() -> float:
	# pixels/sec → km/h
	# 1 km = 10000 pixels
	# 1 hour = 3600 seconds
	return (abs(_current_speed) / 10000.0) * 3600.0


## Get current speed in pixels/sec
func get_speed() -> float:
	return abs(_current_speed)


## Check if vehicle is stopped
func is_stopped() -> bool:
	return abs(_current_speed) < 1.0


## Refuel vehicle
func refuel(amount: float) -> void:
	if fuel_system:
		fuel_system.add_fuel(amount)


## Refuel to full
func refuel_full() -> void:
	if fuel_system:
		fuel_system.refuel_full()


## Get save data
func get_save_data() -> Dictionary:
	return {
		"position": {
			"x": global_position.x,
			"y": global_position.y
		},
		"rotation": rotation,
		"fuel": fuel_system.get_save_data() if fuel_system else {},
		"inventory": inventory.get_save_data() if inventory else {}
	}


## Load from save data
func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)

	if data.has("rotation"):
		rotation = data.rotation

	if data.has("fuel") and fuel_system:
		fuel_system.load_save_data(data.fuel)

	if data.has("inventory") and inventory:
		inventory.load_save_data(data.inventory)
