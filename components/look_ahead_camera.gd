## LookAheadCamera - Racing-style camera with 8-quadrant system
##
## Integrated from OLD_CODE. Provides smooth vehicle following with lookahead,
## speed-based zoom, and direction-aware positioning.

extends Camera2D

@export var target: Node2D
@export_range(0.05, 1.0, 0.05) var lookahead_time := 0.35   # seconds to predict ahead
@export var max_lookahead := Vector2(220, 120)              # pixel clamp for look-ahead
@export var enable_x := true
@export var enable_y := true                                 # Enable for top-down driving
@export var smoothing_speed := 10.0                          # higher = snappier
@export var start_on_target := true

# Base screen positions when velocity is near zero
@export var vehicle_horizontal_position := 0.5               # 0=left, 1=right, 0.5=center
@export var vehicle_vertical_position := 0.5                 # 0=top, 1=bottom, 0.5=center

# === NEW: 8-Quadrant Camera Positioning ===
@export_group("8-Quadrant Camera System")
@export var use_quadrant_system := true                      # Use 8-direction quadrant system
@export var quadrant_velocity_threshold := 200.0              # Speed needed to activate quadrant bias

# Define camera bias for each of the 8 directions (horizontal, vertical)
# Format: Vector2(horizontal_bias, vertical_bias) where 0=left/top, 1=right/bottom, 0.5=center
@export var bias_north := Vector2(0.5, 0.7)                  # Moving up/north - show more below
@export var bias_northeast := Vector2(0.35, 0.65)            # Moving up-right - show more left-below
@export var bias_east := Vector2(0.35, 0.5)                  # Moving right - show more left
@export var bias_southeast := Vector2(0.35, 0.35)            # Moving down-right - show more left-above
@export var bias_south := Vector2(0.5, 0.3)                  # Moving down - show more above
@export var bias_southwest := Vector2(0.65, 0.35)            # Moving down-left - show more right-above
@export var bias_west := Vector2(0.65, 0.5)                  # Moving left - show more right
@export var bias_northwest := Vector2(0.65, 0.65)            # Moving up-left - show more right-below

@export var bias_change_speed := 6.0                         # smoothing for bias switching

# Reverse handling
@export_group("Reverse Handling")
@export var reverse_lookahead_multiplier := 0.3              # Reduce lookahead when reversing
@export var reverse_smoothing_multiplier := 1.5              # Smoother camera when reversing

# Racing camera smoothness
@export_group("Racing Camera Smoothness")
@export var velocity_smoothing := 8.0                        # How fast camera reacts to direction changes (lower = smoother turns)
@export var turn_smoothing_multiplier := 0.6                 # Additional smoothing during sharp turns (0-1, lower = smoother)

# Speed-based zoom
@export_group("Speed-Based Zoom")
@export var enable_speed_zoom := true                        # Enable dynamic zoom based on speed
@export var min_zoom := Vector2(1.0, 1.0)                    # Zoom when stopped
@export var max_zoom := Vector2(0.7, 0.7)                    # Zoom when at max speed (lower = more zoomed out)
@export var zoom_speed_threshold := 50.0                     # Speed at which zoom starts changing
@export var zoom_smoothing := 3.0                            # How fast zoom changes (lower = smoother)

var _prev_pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _smoothed_vel := Vector2.ZERO                            # Smoothed velocity for smoother camera
var _vertical_bias := 0.5
var _horizontal_bias := 0.5
var _current_zoom := Vector2(1.0, 1.0)                       # Current zoom level

func _ready() -> void:
	if target:
		_prev_pos = target.global_position
		if start_on_target:
			# Initialize bias and camera position
			_vertical_bias = vehicle_vertical_position
			_horizontal_bias = vehicle_horizontal_position
			_current_zoom = min_zoom
			zoom = _current_zoom
			global_position = _calculate_camera_position(target.global_position, _horizontal_bias, _vertical_bias)

func _process(delta: float) -> void:
	if not target:
		return

	var tp := target.global_position
	_vel = (tp - _prev_pos) / max(delta, 0.000001)
	_prev_pos = tp

	# Smooth velocity for less jumpy camera during turns
	var vel_smooth_factor := 1.0 - exp(-velocity_smoothing * delta)
	_smoothed_vel = _smoothed_vel.lerp(_vel, vel_smooth_factor)

	# Check if the target is a vehicle and if it's reversing
	var is_reversing := false
	var target_rotation := 0.0
	var target_speed := 0.0
	
	if target.has_method("get") and target.get("is_reversing") != null:
		is_reversing = target.is_reversing
	if target is Node2D:
		target_rotation = target.rotation
	
	# Get vehicle speed if available
	if target.has_method("get") and target.get("velocity") != null:
		var vehicle_velocity = target.get("velocity")
		if vehicle_velocity is Vector2:
			target_speed = vehicle_velocity.length()

	# Speed-based zoom
	if enable_speed_zoom:
		# Calculate target zoom based on speed
		var speed_factor := 0.0
		if target_speed > zoom_speed_threshold:
			speed_factor = clamp((target_speed - zoom_speed_threshold) / 200.0, 0.0, 1.0)
		
		var target_zoom := min_zoom.lerp(max_zoom, speed_factor)
		
		# Smooth zoom transition
		var zoom_factor := 1.0 - exp(-zoom_smoothing * delta)
		_current_zoom = _current_zoom.lerp(target_zoom, zoom_factor)
		zoom = _current_zoom

	# Adjust lookahead and smoothing based on reverse state
	var actual_lookahead_time := lookahead_time
	var actual_smoothing_speed := smoothing_speed
	
	if is_reversing:
		# Reduce lookahead and increase smoothing when reversing
		actual_lookahead_time *= reverse_lookahead_multiplier
		actual_smoothing_speed /= reverse_smoothing_multiplier

	# Use smoothed velocity for lookahead
	var look := _smoothed_vel * actual_lookahead_time
	if not enable_x: look.x = 0.0
	if not enable_y: look.y = 0.0
	look.x = clamp(look.x, -max_lookahead.x, max_lookahead.x)
	look.y = clamp(look.y, -max_lookahead.y, max_lookahead.y)

	var target_with_lookahead := tp + look

	# Detect sharp turns and apply extra smoothing
	var is_turning_sharply := false
	if _smoothed_vel.length() > 10.0 and _vel.length() > 10.0:
		# Calculate angle difference between smoothed and actual velocity
		var angle_diff: float = abs(_smoothed_vel.angle_to(_vel))
		is_turning_sharply = angle_diff > 0.5  # ~28 degrees
	
	# Apply extra smoothing during sharp turns
	if is_turning_sharply:
		actual_smoothing_speed *= turn_smoothing_multiplier

	# === NEW: 8-Quadrant Camera Bias System ===
	var desired_horizontal_bias := vehicle_horizontal_position
	var desired_vertical_bias := vehicle_vertical_position
	
	if use_quadrant_system:
		# Use smoothed velocity for bias calculation to prevent jumpy transitions
		var vel_for_bias := _smoothed_vel if _smoothed_vel.length() > quadrant_velocity_threshold else Vector2.ZERO
		
		if is_reversing:
			# When reversing, use the OPPOSITE of the facing direction
			var facing_direction := Vector2.RIGHT.rotated(target_rotation)
			vel_for_bias = -facing_direction * _smoothed_vel.length()
		
		if vel_for_bias.length() > quadrant_velocity_threshold:
			# Calculate the angle of movement (0 = right/east, 90 = down/south, etc.)
			var movement_angle: float = vel_for_bias.angle()
			
			# Determine which of the 8 quadrants we're in
			# Godot angles: 0 = East, PI/2 = South, PI = West, -PI/2 = North
			var quadrant_bias := _get_quadrant_bias(movement_angle)
			desired_horizontal_bias = quadrant_bias.x
			desired_vertical_bias = quadrant_bias.y

	# Smooth bias transitions
	var bt := 1.0 - exp(-bias_change_speed * delta)
	_vertical_bias = lerp(_vertical_bias, desired_vertical_bias, bt)
	_horizontal_bias = lerp(_horizontal_bias, desired_horizontal_bias, bt)

	# Calculate camera position to place target where we want it on screen
	var desired := _calculate_camera_position(target_with_lookahead, _horizontal_bias, _vertical_bias)

	# Critical: exponential smoothing (frame-rate independent)
	var t := 1.0 - exp(-actual_smoothing_speed * delta)
	global_position = global_position.lerp(desired, t)

# Determine camera bias based on movement angle (8 directions)
func _get_quadrant_bias(angle: float) -> Vector2:
	# Normalize angle to 0-2PI range
	var normalized_angle := fposmod(angle, TAU)
	
	# Define 8 directions with 45-degree segments
	# Each direction gets a 45-degree slice (PI/4 radians)
	var segment := PI / 4.0  # 45 degrees
	
	# East: -22.5° to 22.5° (wraps around 0)
	if normalized_angle < segment * 0.5 or normalized_angle >= segment * 7.5:
		return bias_east
	
	# Southeast: 22.5° to 67.5°
	elif normalized_angle >= segment * 0.5 and normalized_angle < segment * 1.5:
		return bias_southeast
	
	# South: 67.5° to 112.5°
	elif normalized_angle >= segment * 1.5 and normalized_angle < segment * 2.5:
		return bias_south
	
	# Southwest: 112.5° to 157.5°
	elif normalized_angle >= segment * 2.5 and normalized_angle < segment * 3.5:
		return bias_southwest
	
	# West: 157.5° to 202.5°
	elif normalized_angle >= segment * 3.5 and normalized_angle < segment * 4.5:
		return bias_west
	
	# Northwest: 202.5° to 247.5°
	elif normalized_angle >= segment * 4.5 and normalized_angle < segment * 5.5:
		return bias_northwest
	
	# North: 247.5° to 292.5°
	elif normalized_angle >= segment * 5.5 and normalized_angle < segment * 6.5:
		return bias_north
	
	# Northeast: 292.5° to 337.5°
	else:  # normalized_angle >= segment * 6.5 and normalized_angle < segment * 7.5
		return bias_northeast

# Calculate camera position so target appears at desired screen position
func _calculate_camera_position(target_pos: Vector2, horizontal_pos: float, vertical_pos: float) -> Vector2:
	# Get viewport size to determine screen positioning
	var viewport_size = get_viewport().size
	
	# We want the target to appear at our desired position on screen
	# Calculate the offset needed to achieve this
	var desired_target_screen_pos = Vector2(
		viewport_size.x * horizontal_pos,  # Horizontal position based on computed bias
		viewport_size.y * vertical_pos     # Vertical position based on computed bias
	)
	
	# The camera centers at screen position (viewport_size.x/2, viewport_size.y/2)
	var center_screen_pos = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
	
	# Calculate the offset in screen coordinates
	var screen_offset = desired_target_screen_pos - center_screen_pos
	
	# Convert screen offset to world offset (considering zoom)
	var zoom_factor = _current_zoom.x  # Use current zoom for accurate positioning
	var world_offset = Vector2(
		screen_offset.x / zoom_factor,
		screen_offset.y / zoom_factor
	)
	
	# The camera should be positioned so that when it centers, the target appears at desired location
	# Camera position = Target position - offset to move target to desired screen location
	return target_pos - world_offset
