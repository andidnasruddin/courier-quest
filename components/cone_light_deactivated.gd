## Cone Light Component (Final Simple Version)
##
## Creates a proper cone-shaped flashlight using a generated triangular texture.
## No gradients - actual geometric cone shape.

class_name ConeLight extends PointLight2D

@export_range(30.0, 120.0) var cone_angle_degrees: float = 90.0:
	set(value):
		var new_angle := clampf(value, 30.0, 120.0)
		# Don't regenerate on every tiny change during lerp
		cone_angle_degrees = new_angle

@export_range(200.0, 800.0) var cone_length_pixels: float = 400.0:
	set(value):
		cone_length_pixels = clampf(value, 200.0, 800.0)
		if is_node_ready():
			_regenerate_texture()

@export var cone_color: Color = Color(1.0, 0.95, 0.85, 1.0):
	set(value):
		cone_color = value
		color = value

@export_range(0.5, 3.0) var light_energy_value: float = 1.5:
	set(value):
		light_energy_value = value
		energy = value

## Target angle for smooth transitions
var _target_angle: float = 90.0

## Transition duration in seconds
@export var transition_duration: float = 0.12

## Current transition timer
var _transition_timer: float = 0.0

## Is currently transitioning
var _is_transitioning: bool = false

# Texture cache to avoid constant regeneration
var _cached_textures: Dictionary = {}


func _ready() -> void:
	_regenerate_texture()
	_apply_settings()

	# Position offset to place cone apex at player center
	offset = Vector2(0, -16)  # Adjust based on player sprite size


func _regenerate_texture() -> void:
	# Round angle to nearest 10 degrees for caching
	var cache_key: int = int(cone_angle_degrees / 10.0) * 10

	# Check cache first
	if _cached_textures.has(cache_key):
		texture = _cached_textures[cache_key]
		return

	# Reduced texture size for performance (512 is plenty)
	var size: int = 512
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Clear to transparent black
	img.fill(Color(0, 0, 0, 0))

	# Cone apex at center bottom
	var apex_x: int = size / 2
	var apex_y: int = size

	# Calculate cone dimensions
	var half_angle_rad: float = deg_to_rad(cone_angle_degrees / 2.0)
	var length_in_texture: float = cone_length_pixels * (float(size) / 600.0)

	# Top width based on angle
	var top_half_width: float = tan(half_angle_rad) * length_in_texture

	# Draw filled triangle (cone)
	for y in range(size):
		var dist_from_apex: float = float(apex_y - y)

		if dist_from_apex <= 0 or dist_from_apex > length_in_texture:
			continue

		# Width at this Y position
		var width_at_y: float = (dist_from_apex / length_in_texture) * top_half_width

		# Calculate brightness falloff
		var distance_factor: float = 1.0 - (dist_from_apex / length_in_texture)
		distance_factor = clampf(distance_factor, 0.0, 1.0)

		# Fill pixels at this Y level
		var left_x: int = int(apex_x - width_at_y)
		var right_x: int = int(apex_x + width_at_y)

		for x in range(max(0, left_x), min(size, right_x + 1)):
			# Distance from center line
			var center_dist: float = abs(float(x - apex_x)) / width_at_y if width_at_y > 0 else 0.0

			# Edge softness
			var edge_factor: float = 1.0 - smoothstep(0.7, 1.0, center_dist)

			# Combine factors
			var brightness: float = distance_factor * edge_factor
			brightness = clampf(brightness, 0.0, 1.0)

			img.set_pixel(x, y, Color(1, 1, 1, brightness))

	# Create texture and cache it
	var tex := ImageTexture.create_from_image(img)
	_cached_textures[cache_key] = tex
	texture = tex


func _apply_settings() -> void:
	color = cone_color
	energy = light_energy_value
	blend_mode = Light2D.BLEND_MODE_ADD
	shadow_enabled = true

	# Scale based on cone length
	texture_scale = cone_length_pixels / 300.0
	
	# DO NOT set rotation here - parent controls rotation


## Set target angle with smooth transition
func set_target_angle(target: float) -> void:
	_target_angle = clampf(target, 30.0, 120.0)
	
	# Only transition if angle change is significant
	if abs(_target_angle - cone_angle_degrees) > 5.0:
		_is_transitioning = true
		_transition_timer = 0.0


func _process(delta: float) -> void:
	if not _is_transitioning:
		return
	
	_transition_timer += delta
	var progress: float = _transition_timer / transition_duration
	progress = clampf(progress, 0.0, 1.0)
	
	# Ease-in-out curve
	var eased: float = ease(progress, -2.0) if progress < 0.5 else ease(progress, 2.0)
	
	# Interpolate angle
	var old_angle: float = cone_angle_degrees
	var new_angle: float = lerp(cone_angle_degrees, _target_angle, eased)
	cone_angle_degrees = new_angle
	
	# Regenerate texture if angle changed significantly
	if abs(cone_angle_degrees - old_angle) > 5.0:
		_regenerate_texture()
	
	# End transition when close enough
	if progress >= 1.0 or abs(cone_angle_degrees - _target_angle) < 1.0:
		cone_angle_degrees = _target_angle
		_is_transitioning = false
		_regenerate_texture()
