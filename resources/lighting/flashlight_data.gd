## Flashlight Data Resource
##
## Defines flashlight properties for player/vehicle lights.
## Create .tres instances to customize different flashlight types.
##
## For cone/spotlight: Leave light_texture null and set use_procedural_cone = true
## OR assign a cone-shaped texture (white cone on black background)
## The texture shape determines the light pattern - this is how Godot 2D creates spotlight effects!

class_name FlashlightData extends Resource

@export_group("Light Shape")
@export var light_texture: Texture2D  # The texture that defines light shape (cone, circle, etc)
@export var use_procedural_cone: bool = true  # Auto-generate cone if no texture assigned
@export_range(30.0, 120.0) var cone_angle: float = 60.0  # Width of cone in degrees (only if procedural)
@export var texture_scale: float = 5.0  # Size/range of light
@export var texture_rotation: float = -90.0  # Rotation offset in degrees (cone points right by default, -90 points up)

@export_group("Light Properties")
@export var light_color: Color = Color(1.0, 0.95, 0.85, 1.0)  # Warm white
@export_range(0.0, 5.0) var energy: float = 1.0
@export var enable_shadows: bool = true

@export_group("Advanced")
@export_range(-1024, 1024) var range_z_min: int = -1024
@export_range(-1024, 1024) var range_z_max: int = 1024
@export var blend_mode: int = 0  # 0 = ADD, 1 = SUB, 2 = MIX


## Generate a procedural cone texture based on cone_angle
func create_cone_texture() -> ImageTexture:
	var size: int = 512
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Cone points upward from center bottom
	var center_x: float = size / 2.0
	var center_y: float = size  # Bottom center

	# Calculate cone width based on angle
	var half_angle_rad: float = deg_to_rad(cone_angle / 2.0)

	for y in range(size):
		for x in range(size):
			var color := Color.BLACK

			# Distance from bottom center
			var dx: float = float(x) - center_x
			var dy: float = float(y) - center_y  # Negative = upward

			# Skip if below center point
			if dy >= 0:
				image.set_pixel(x, y, color)
				continue

			# Calculate angle from center axis (upward)
			var distance_from_center: float = sqrt(dx * dx + dy * dy)
			var angle_from_axis: float = abs(atan2(dx, -dy))  # Angle from vertical

			# Check if inside cone
			if angle_from_axis <= half_angle_rad:
				# Calculate brightness based on distance and angle
				var normalized_dist: float = abs(dy) / float(size)  # 0 at center, 1 at top
				var angle_factor: float = 1.0 - (angle_from_axis / half_angle_rad)  # 1 at center, 0 at edge

				# Combine factors for smooth falloff
				var brightness: float = normalized_dist * angle_factor
				brightness = clampf(brightness * 1.5, 0.0, 1.0)  # Boost brightness

				color = Color(brightness, brightness, brightness, brightness)

			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)
