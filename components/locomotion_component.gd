## Locomotion Component
##
## Handles player movement including walking, sprinting, and weight-based speed modifiers.
## Attach to CharacterBody2D for movement functionality.
##
## @tutorial: docs/PHASE_1_CORE_DELIVERY_LOOP.md

class_name LocomotionComponent extends Node

signal speed_changed(new_speed: float)

## Base walking speed in pixels per second
@export var walk_speed: float = 100.0

## Sprint speed multiplier (1.75 = 75% faster)
@export var sprint_multiplier: float = 1.75

## Maximum weight capacity in kilograms before over-encumbered
@export var max_weight_capacity: float = 60.0

## Reference to the CharacterBody2D this component controls
@export var body: CharacterBody2D

## Current weight being carried (set by inventory component)
var current_weight: float = 0.0

## Is player currently sprinting
var is_sprinting: bool = false

## Current effective speed (after weight modifiers)
var current_speed: float = 100.0

# Private movement state
var _movement_input: Vector2 = Vector2.ZERO
var _is_movement_disabled: bool = false


func _ready() -> void:
	if not body:
		body = get_parent() as CharacterBody2D
		if not body:
			push_error("LocomotionComponent requires a CharacterBody2D parent or explicit body reference")

	_update_current_speed()


func _physics_process(delta: float) -> void:
	if _is_movement_disabled:
		return

	_handle_input()
	_apply_movement()


## Handle movement and sprint input
func _handle_input() -> void:
	# Get input direction
	_movement_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Check sprint input
	is_sprinting = Input.is_action_pressed("sprint") and _movement_input.length() > 0.1


## Apply movement to the character body
func _apply_movement() -> void:
	if not body:
		return

	# Calculate target velocity
	var target_speed: float = current_speed
	if is_sprinting and not is_over_encumbered():
		target_speed *= sprint_multiplier

	var target_velocity: Vector2 = _movement_input.normalized() * target_speed

	# Apply velocity
	body.velocity = target_velocity
	body.move_and_slide()


## Update current speed based on weight
func _update_current_speed() -> void:
	var weight_percent: float = current_weight / max_weight_capacity
	var speed_modifier: float = 1.0

	# Weight affects speed in brackets
	if weight_percent >= 1.0:
		speed_modifier = 0.25  # 60kg+: 25% speed
	elif weight_percent >= 0.67:
		speed_modifier = 0.50  # 40-60kg: 50% speed
	elif weight_percent >= 0.33:
		speed_modifier = 0.75  # 20-40kg: 75% speed
	else:
		speed_modifier = 1.0  # 0-20kg: 100% speed

	current_speed = walk_speed * speed_modifier
	speed_changed.emit(current_speed)


## Set current weight being carried
func set_weight(weight: float) -> void:
	current_weight = max(0.0, weight)
	_update_current_speed()


## Check if player is over-encumbered
func is_over_encumbered() -> bool:
	return current_weight > max_weight_capacity


## Get weight as percentage of capacity
func get_weight_percent() -> float:
	return current_weight / max_weight_capacity


## Disable movement (used when in vehicle, UI, etc.)
func set_movement_enabled(enabled: bool) -> void:
	_is_movement_disabled = not enabled
	if _is_movement_disabled:
		if body:
			body.velocity = Vector2.ZERO


## Get current movement direction (-1 to 1 on each axis)
func get_movement_direction() -> Vector2:
	return _movement_input


## Get current velocity
func get_velocity() -> Vector2:
	if body:
		return body.velocity
	return Vector2.ZERO


## Get effective speed (including sprint and weight modifiers)
func get_effective_speed() -> float:
	var speed: float = current_speed
	if is_sprinting and not is_over_encumbered():
		speed *= sprint_multiplier
	return speed
