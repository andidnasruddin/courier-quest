## Fuel System Component
##
## Manages vehicle fuel consumption and refueling.
## Attached to vehicle nodes to track fuel usage over distance.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name FuelSystemComponent extends Node

signal fuel_changed(current_fuel: float, max_fuel: float)
signal fuel_empty()
signal fuel_low(fuel_percent: float)

## Maximum fuel capacity in liters
@export var max_fuel: float = 50.0

## Fuel consumption rate in liters per kilometer
@export var consumption_rate: float = 0.5

## Fuel percentage threshold for "low fuel" warning
@export_range(0.0, 1.0) var low_fuel_threshold: float = 0.25

## Current fuel in liters
var current_fuel: float = 50.0

## Has low fuel warning been triggered this cycle
var _low_fuel_warning_triggered: bool = false

## Total distance traveled (for consumption calculation)
var _total_distance_traveled: float = 0.0

## Previous position for distance calculation
var _previous_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_fuel = max_fuel
	fuel_changed.emit(current_fuel, max_fuel)


## Initialize position tracking
func initialize_position(position: Vector2) -> void:
	_previous_position = position


## Update fuel consumption based on distance traveled
func update_fuel(current_position: Vector2, delta: float) -> void:
	if _previous_position == Vector2.ZERO:
		_previous_position = current_position
		return

	# Calculate distance traveled this frame
	var distance_pixels: float = current_position.distance_to(_previous_position)
	_previous_position = current_position

	# Convert pixels to kilometers (1 km = 10000 pixels)
	var distance_km: float = distance_pixels / 10000.0

	# Calculate fuel consumed
	var fuel_consumed: float = distance_km * consumption_rate

	# Deduct fuel
	consume_fuel(fuel_consumed)


## Consume a specific amount of fuel
func consume_fuel(amount: float) -> void:
	if current_fuel <= 0:
		return

	current_fuel = max(0.0, current_fuel - amount)

	# Check for low fuel warning
	var fuel_percent: float = get_fuel_percent()
	if fuel_percent <= low_fuel_threshold and not _low_fuel_warning_triggered:
		_low_fuel_warning_triggered = true
		fuel_low.emit(fuel_percent)

	# Reset warning if refueled above threshold
	if fuel_percent > low_fuel_threshold:
		_low_fuel_warning_triggered = false

	# Check if empty
	if current_fuel <= 0:
		fuel_empty.emit()

	fuel_changed.emit(current_fuel, max_fuel)


## Add fuel (refueling)
func add_fuel(amount: float) -> void:
	current_fuel = min(max_fuel, current_fuel + amount)
	fuel_changed.emit(current_fuel, max_fuel)


## Refuel to full
func refuel_full() -> void:
	current_fuel = max_fuel
	_low_fuel_warning_triggered = false
	fuel_changed.emit(current_fuel, max_fuel)


## Get current fuel as percentage (0.0 to 1.0)
func get_fuel_percent() -> float:
	return current_fuel / max_fuel


## Check if fuel is empty
func is_empty() -> bool:
	return current_fuel <= 0


## Check if fuel is low
func is_low() -> bool:
	return get_fuel_percent() <= low_fuel_threshold


## Get range remaining in kilometers
func get_range_km() -> float:
	if consumption_rate <= 0:
		return INF
	return current_fuel / consumption_rate


## Get range remaining in pixels
func get_range_pixels() -> float:
	return get_range_km() * 10000.0


## Get save data
func get_save_data() -> Dictionary:
	return {
		"current_fuel": current_fuel,
		"max_fuel": max_fuel
	}


## Load from save data
func load_save_data(data: Dictionary) -> void:
	if data.has("current_fuel"):
		current_fuel = data.current_fuel

	if data.has("max_fuel"):
		max_fuel = data.max_fuel

	fuel_changed.emit(current_fuel, max_fuel)
