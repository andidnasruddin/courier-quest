## DreadClock Loop Reset Glitch Effect
##
## Creates a brief visual glitch when time loop resets at 06:00.
## Simulates reality "snapping back" to 18:00.

extends CanvasLayer

# Glitch settings
@export var glitch_duration: float = 0.3  # Total glitch effect duration
@export var screen_shake_strength: float = 8.0
@export var color_aberration_strength: float = 15.0

# UI elements
@onready var glitch_overlay: ColorRect = $GlitchOverlay
@onready var camera_offset: Node2D = $CameraOffset  # Optional camera shake target

# Glitch state
var _glitch_time: float = 0.0
var _is_glitching: bool = false
var _original_camera_pos: Vector2


func _ready() -> void:
	if not DreadClock:
		push_error("DreadClock autoload not found")
		return

	# Hide glitch overlay initially
	if glitch_overlay:
		glitch_overlay.visible = false

	# Connect to loop reset signal
	DreadClock.loop_reset.connect(_on_loop_reset)


func _process(delta: float) -> void:
	if not _is_glitching:
		return

	_glitch_time += delta

	if _glitch_time >= glitch_duration:
		_end_glitch()
		return

	# Calculate glitch intensity (peaks at middle, fades at start/end)
	var t: float = _glitch_time / glitch_duration
	var intensity: float = sin(t * PI)  # 0 -> 1 -> 0

	# Flash effect
	if glitch_overlay:
		glitch_overlay.visible = true
		# Rapid flicker
		var flicker: float = 1.0 if int(_glitch_time * 30.0) % 2 == 0 else 0.0
		glitch_overlay.color.a = intensity * 0.5 * flicker

	# Screen shake (if camera available)
	_apply_screen_shake(intensity)


func _apply_screen_shake(intensity: float) -> void:
	# Get the active camera
	var camera: Camera2D = get_viewport().get_camera_2d()
	if not camera:
		return

	# Apply random offset
	var shake_x: float = randf_range(-screen_shake_strength, screen_shake_strength) * intensity
	var shake_y: float = randf_range(-screen_shake_strength, screen_shake_strength) * intensity
	camera.offset = Vector2(shake_x, shake_y)


func _end_glitch() -> void:
	_is_glitching = false
	_glitch_time = 0.0

	# Hide overlay
	if glitch_overlay:
		glitch_overlay.visible = false

	# Reset camera
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		camera.offset = Vector2.ZERO


func _on_loop_reset() -> void:
	_is_glitching = true
	_glitch_time = 0.0
	print("[DreadClock Glitch] Loop reset glitch triggered!")
