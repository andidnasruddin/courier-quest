@tool
extends EditorScript

## Generates a cone texture for the DreadConeRefactored Light2D component.
## This creates a gradient cone texture that works well with Godot's Light2D system.

func _run() -> void:
	_generate_cone_texture()

func _generate_cone_texture() -> void:
	var size := 512
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Create cone gradient
	for y in range(size):
		for x in range(size):
			# Calculate position relative to center
			var dx := x - size / 2
			var dy := y - size / 2
			
			# Calculate distance and angle from center
			var distance := sqrt(dx * dx + dy * dy)
			var angle := atan2(dy, dx)
			
			# Normalize to 0-1 range
			var normalized_distance := distance / (size / 2)
			var normalized_angle := (angle + PI) / (2 * PI)
			
			# Create cone shape (pointing upward)
			var cone_angle := PI / 3  # 60 degrees
			var cone_direction := -PI / 2  # Pointing up
			
			# Calculate angle difference
			var angle_diff := abs(angle - cone_direction)
			if angle_diff > PI:
				angle_diff = 2 * PI - angle_diff
			
			# Determine if pixel is in cone
			var in_cone := angle_diff <= cone_angle / 2
			
			# Calculate intensity based on distance and cone shape
			var intensity := 0.0
			if in_cone:
				# Gradient from center to edge
				intensity = 1.0 - normalized_distance
				intensity = max(0.0, intensity)
				
				# Add soft edge to cone
				var edge_fade := 1.0 - (angle_diff / (cone_angle / 2))
				intensity *= edge_fade
			
			# Set pixel color
			var color := Color(intensity, intensity, intensity, intensity)
			image.set_pixel(x, y, color)
	
	# Save texture
	var texture := ImageTexture.create_from_image(image)
	ResourceSaver.save(texture, "res://assets/lighting/dread_cone_texture.png")
	print("Dread cone texture saved to res://assets/lighting/dread_cone_texture.png")
