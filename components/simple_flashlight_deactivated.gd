## Simple Flashlight Component (Refactored)
##
## Dead-simple cone flashlight using GradientTexture2D.
## No complex procedural generation - just works.

class_name SimpleFlashlight extends PointLight2D

@export_range(30.0, 120.0) var cone_angle: float = 90.0
@export_range(1.0, 10.0) var light_range: float = 5.0
@export var light_color: Color = Color(1.0, 0.95, 0.85, 1.0)
@export_range(0.5, 3.0) var light_energy: float = 1.5

var _cone_texture: GradientTexture2D


func _ready() -> void:
	_create_cone_texture()
	_apply_settings()


func _create_cone_texture() -> void:
	# Create radial gradient
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color.WHITE,           # Center (bright)
		Color(1, 1, 1, 0.8),  # Mid
		Color(1, 1, 1, 0)     # Edge (transparent)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])

	# Create gradient texture
	_cone_texture = GradientTexture2D.new()
	_cone_texture.gradient = gradient
	_cone_texture.fill = GradientTexture2D.FILL_RADIAL

	# Offset the gradient center to create cone effect
	# Moving fill_from down creates upward-pointing cone
	var cone_offset: float = remap(cone_angle, 30.0, 120.0, 0.7, 0.3)
	_cone_texture.fill_from = Vector2(0.5, cone_offset)
	_cone_texture.fill_to = Vector2(0.5, 0.0)

	_cone_texture.width = 512
	_cone_texture.height = 512


func _apply_settings() -> void:
	texture = _cone_texture
	texture_scale = light_range
	color = light_color
	energy = light_energy
	blend_mode = Light2D.BLEND_MODE_ADD
	shadow_enabled = true

	# Point upward by default
	rotation_degrees = -90.0


## Update cone width
func set_cone_angle(new_angle: float) -> void:
	cone_angle = clampf(new_angle, 30.0, 120.0)
	_create_cone_texture()
	texture = _cone_texture


## Update light range
func set_light_range(new_range: float) -> void:
	light_range = clampf(new_range, 1.0, 10.0)
	texture_scale = light_range
