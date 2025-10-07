## Resource definition for vehicle stats and properties
##
## Defines all vehicle characteristics including performance, fuel, and storage.
## Create .tres instances of this for different vehicle types.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name VehicleData extends Resource

## Display name of vehicle
@export var vehicle_name: String = "Vehicle"

## Maximum speed in km/h (converted to pixels/sec in code)
@export var max_speed: float = 80.0

## Acceleration rate (higher = faster acceleration)
@export var acceleration: float = 120.0

## Turn speed multiplier (higher = sharper turns)
@export var turn_speed: float = 2.5

## Fuel tank capacity in liters
@export var fuel_capacity: float = 50.0

## Fuel consumption rate in liters per kilometer
@export var fuel_consumption: float = 0.5

## Storage grid size (columns x rows)
@export var storage_grid_size: Vector2i = Vector2i(12, 8)

## Maximum health/durability
@export var max_health: float = 100.0

## Purchase price in credits
@export var cost: int = 0


## Convert km/h to pixels per second (assuming 1km = 10000 pixels)
func get_max_speed_pixels_per_sec() -> float:
	# 80 km/h = 80000 pixels/hour = 80000/3600 pixels/sec ≈ 222 px/sec
	return (max_speed * 10000.0) / 3600.0


## Calculate fuel consumption for a given distance in pixels
func calculate_fuel_used(distance_pixels: float) -> float:
	var distance_km: float = distance_pixels / 10000.0
	return distance_km * fuel_consumption


## Get storage capacity (total grid cells)
func get_storage_capacity() -> int:
	return storage_grid_size.x * storage_grid_size.y
